import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/permissions/camera_permission_denied_widget.dart';
import '../bloc/bloc.dart';
import '../widgets/recording_guidelines_overlay.dart';
import '../widgets/recording_timer_display.dart';

/// Full-screen video capture screen.
///
/// Provides a live camera preview with recording guidelines, a timer
/// display during recording, and start/stop controls.
///
/// Permission flow (Requirements: 24.1-24.9):
/// 1. On init, dispatch [CameraPermissionRequested] with context.
/// 2. Show loading indicator while permission check is in progress.
/// 3. On [CameraPermissionGranted]: initialise [CameraController].
/// 4. On [CameraPermissionDenied]: show [CameraPermissionDeniedWidget].
/// 5. On [CameraPermissionPermanentlyDenied]: show
///    [CameraPermissionDeniedWidget] with isPermanentlyDenied=true.
///
/// Recording flow (Requirements: 5.1-5.10):
/// - [VideoCaptureReady]: show guidelines overlay + record button.
/// - [VideoRecording]: show timer display + stop button (pulsing).
/// - [VideoRecordingStopping]: show progress indicator.
/// - [VideoCaptureComplete]: pop back with the video path result.
/// - [VideoCaptureError]: show SnackBar with message + retry action.
///
/// Requirements: 5.1-5.10, 24.1-24.9
class VideoCaptureScreen extends StatefulWidget {
  const VideoCaptureScreen({required this.boxId, super.key});

  /// Identifier of the crab box being recorded.
  final String boxId;

  @override
  State<VideoCaptureScreen> createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends State<VideoCaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Request camera permission after first frame so context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VideoCaptureBloc>().add(CameraPermissionRequested(context: context));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (appState == AppLifecycleState.inactive) {
      _disposeController();
    } else if (appState == AppLifecycleState.resumed) {
      _initCameraController(useFront: _isFrontCamera());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Camera lifecycle
  // ---------------------------------------------------------------------------

  bool _isFrontCamera() {
    final s = context.read<VideoCaptureBloc>().state;
    if (s is VideoCaptureReady) return s.isFrontCamera;
    if (s is VideoRecording) return s.isFrontCamera;
    return false;
  }

  Future<void> _initCameraController({bool useFront = false}) async {
    try {
      _cameras = await availableCameras();
    } catch (_) {
      if (mounted) {
        context.read<VideoCaptureBloc>().add(const VideoCaptureReset());
      }
      return;
    }

    if (_cameras.isEmpty) return;

    final description = _pickCamera(useFront: useFront);

    await _disposeController();

    final controller = CameraController(description, ResolutionPreset.high, enableAudio: false);

    _controller = controller;

    try {
      await controller.initialize();
    } catch (_) {
      return;
    }

    if (!mounted) return;

    // Give the controller reference to the BLoC so it can call
    // startVideoRecording / stopVideoRecording.
    context.read<VideoCaptureBloc>().cameraController = controller;

    setState(() {});
    context.read<VideoCaptureBloc>().add(const VideoCaptureInitialized());
  }

  CameraDescription _pickCamera({required bool useFront}) {
    final facing = useFront ? CameraLensDirection.front : CameraLensDirection.back;
    return _cameras.firstWhere((c) => c.lensDirection == facing, orElse: () => _cameras.first);
  }

  Future<void> _disposeController() async {
    final old = _controller;
    _controller = null;
    try {
      await old?.dispose();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // State side-effects
  // ---------------------------------------------------------------------------

  void _onStateChange(BuildContext ctx, VideoCaptureState state) {
    if (state is CameraPermissionGranted) {
      unawaited(_initCameraController());
    } else if (state is VideoCaptureComplete) {
      // Keep screen open while compress/upload + AI analyze run.
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Đã ghi xong — đang tải lên & phân tích AI…'),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (state is VideoUploaded) {
      ctx.pushReplacement(
        RoutePaths.aiResults(state.videoId),
        extra: {'boxId': state.boxId},
      );
    } else if (state is VideoQueued) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Offline — video đã xếp hàng đồng bộ.'),
        ),
      );
      Navigator.of(ctx).pop();
    } else if (state is VideoCaptureError) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(state.message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              if (mounted) {
                context.read<VideoCaptureBloc>().add(const VideoCaptureReset());
              }
            },
          ),
        ),
      );
    } else if (state is StorageInsufficient) {
      _showStorageInsufficientDialog(ctx, state);
    } else if (state is StorageWarningOfflineQueue) {
      _showStorageWarningDialog(ctx, state);
    } else if (state is VideoCaptureReady && _controller != null) {
      // Camera facing may have changed — reinitialise if needed.
      final currentFront = _controller!.description.lensDirection == CameraLensDirection.front;
      if (currentFront != state.isFrontCamera) {
        unawaited(_initCameraController(useFront: state.isFrontCamera));
      }
    }
  }

  /// Shows a non-dismissible error dialog when storage is insufficient.
  ///
  /// Requirements: 5.9
  void _showStorageInsufficientDialog(BuildContext ctx, StorageInsufficient state) {
    final availableMb = (state.availableBytes / (1024 * 1024)).toStringAsFixed(0);
    final requiredMb = (state.requiredBytes / (1024 * 1024)).toStringAsFixed(0);

    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Insufficient Storage'),
        content: Text(
          'Not enough storage to record a video.\n\n'
          'Available: $availableMb MB\n'
          'Required: $requiredMb MB\n\n'
          'Please free up space and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                context.read<VideoCaptureBloc>().add(const VideoCaptureReset());
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows a warning dialog when the offline queue is over 80 % full.
  ///
  /// The user may continue recording or cancel. If they continue,
  /// [VideoRecordingStarted] is dispatched.
  ///
  /// Requirements: 5.9
  void _showStorageWarningDialog(BuildContext ctx, StorageWarningOfflineQueue state) {
    final usedMb = (state.usedBytes / (1024 * 1024)).toStringAsFixed(0);
    final totalMb = (state.totalBytes / (1024 * 1024)).toStringAsFixed(0);

    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Offline Queue Almost Full'),
        content: Text(
          'Your offline video queue is over 80% full '
          '($usedMb MB / $totalMb MB).\n\n'
          'Consider syncing your videos before recording more.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                context.read<VideoCaptureBloc>().add(VideoRecordingStarted(boxId: state.boxId));
              }
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Callbacks
  // ---------------------------------------------------------------------------

  void _retryPermission() {
    if (mounted) {
      context.read<VideoCaptureBloc>().add(CameraPermissionRequested(context: context));
    }
  }

  void _startRecording() {
    context.read<VideoCaptureBloc>().add(StorageCheckRequested(boxId: widget.boxId));
  }

  void _stopRecording() {
    context.read<VideoCaptureBloc>().add(const VideoRecordingManualStopped());
  }

  void _toggleCamera() {
    context.read<VideoCaptureBloc>().add(const CameraFacingToggled());
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) => BlocListener<VideoCaptureBloc, VideoCaptureState>(
    listener: _onStateChange,
    child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: BlocBuilder<VideoCaptureBloc, VideoCaptureState>(builder: _buildBody),
    ),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    title: const Text('Capture Video'),
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: BackButton(onPressed: () => Navigator.of(context).pop()),
  );

  Widget _buildBody(BuildContext context, VideoCaptureState state) {
    // Loading while checking permission.
    if (state is VideoCaptureInitial ||
        state is CameraPermissionChecking ||
        state is CameraPermissionGranted) {
      return const Center(child: CircularProgressIndicator(color: CrabSenseColors.primary));
    }

    // Denied — show permission guidance widget.
    if (state is CameraPermissionDenied) {
      return CameraPermissionDeniedWidget(
        onRetry: _retryPermission,
        onCancel: () => Navigator.of(context).pop(),
      );
    }

    // Permanently denied — show settings guidance.
    if (state is CameraPermissionPermanentlyDenied) {
      return CameraPermissionDeniedWidget(
        isPermanentlyDenied: true,
        onCancel: () => Navigator.of(context).pop(),
      );
    }

    // Stopping — spinner only, no controls.
    if (state is VideoRecordingStopping) {
      return const Center(child: CircularProgressIndicator(color: CrabSenseColors.primary));
    }

    // Compressing — show progress indicator with percentage
    if (state is VideoCompressing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: CrabSenseColors.primary),
            const SizedBox(height: 16),
            Text(
              'Compressing... ${(state.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Uploading — show progress indicator with percentage and retry attempt
    if (state is VideoUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: CrabSenseColors.primary),
            const SizedBox(height: 16),
            Text(
              'Uploading... ${(state.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (state.currentAttempt > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Attempt ${state.currentAttempt} of ${state.maxAttempts}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
          ],
        ),
      );
    }

    // Uploaded — show success message (user will see this briefly before pop)
    if (state is VideoUploaded) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text(
              'Video uploaded successfully',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Queued — show info message (offline, will sync later)
    if (state is VideoQueued) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Video saved offline - will upload when connected',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
    }

    // Upload failed — show error with retry button
    if (state is VideoUploadFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      context.read<VideoCaptureBloc>().add(
                        VideoUploadRetryRequested(
                          videoId: state.videoId,
                          compressedPath: state.compressedPath,
                          boxId: state.boxId,
                          capturedBy: state.capturedBy,
                          durationSeconds: state.durationSeconds,
                        ),
                      );
                    },
                    child: const Text('Retry Upload'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Camera states — show preview + overlay controls.
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: CrabSenseColors.primary));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview.
        CameraPreview(controller),

        // Guidelines overlay (only when ready, not recording).
        if (state is VideoCaptureReady) const RecordingGuidelinesOverlay(),

        // Timer display (only during recording).
        if (state is VideoRecording)
          RecordingTimerDisplay(elapsedSeconds: state.elapsedSeconds, maxSeconds: state.maxSeconds),

        // Bottom controls row.
        _buildBottomControls(state),
      ],
    );
  }

  Widget _buildBottomControls(VideoCaptureState state) => Positioned(
    bottom: 48,
    left: 0,
    right: 0,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state is VideoCaptureReady) ...[
          // Camera flip button.
          _CameraFlipButton(onToggle: _toggleCamera),
          const SizedBox(width: 32),
          // Record button.
          _RecordButton(onPressed: _startRecording),
          // Spacer to balance the flip button.
          const SizedBox(width: 72),
        ] else if (state is VideoRecording) ...[
          // Stop button (pulsing).
          _StopButton(onPressed: _stopRecording),
        ],
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Record button
// ---------------------------------------------------------------------------

/// Large red circular record button.
class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CrabSenseColors.error,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: CrabSenseColors.error.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.circle, color: Colors.white, size: 36),
    ),
  );
}

// ---------------------------------------------------------------------------
// Stop button (pulsing)
// ---------------------------------------------------------------------------

/// Pulsing stop button shown during active recording.
class _StopButton extends StatefulWidget {
  const _StopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_StopButton> createState() => _StopButtonState();
}

class _StopButtonState extends State<_StopButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CrabSenseColors.error,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: CrabSenseColors.error.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.stop_rounded, color: Colors.white, size: 36),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Camera flip button
// ---------------------------------------------------------------------------

/// Small circular button for switching between front and rear cameras.
class _CameraFlipButton extends StatelessWidget {
  const _CameraFlipButton({required this.onToggle});

  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
    child: IconButton(
      iconSize: 28,
      icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
      tooltip: 'Switch camera',
      onPressed: onToggle,
    ),
  );
}
