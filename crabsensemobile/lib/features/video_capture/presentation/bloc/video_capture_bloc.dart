import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/services/camera_permission_service.dart';
import '../../../../shared/services/storage_service.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/usecases/capture_video_usecase.dart';
import 'video_capture_event.dart';
import 'video_capture_state.dart';

/// Business Logic Component for video capture, compression, and upload.
///
/// Manages the full lifecycle:
///   permission → preview → storage check → recording → compression
///   → upload (or queue)
///
/// State flow:
/// - VideoCaptureInitial
/// - CameraPermissionChecking
/// - CameraPermissionGranted / Denied / PermanentlyDenied
/// - VideoCaptureReady
/// - StorageInsufficient        (recording blocked — not enough disk space)
/// - StorageWarningOfflineQueue (recording allowed but queue >80 % full)
/// - VideoRecording (ticking every second)
/// - VideoRecordingStopping
/// - VideoCompressing (progress 0–1)
/// - VideoUploading  (progress 0–1, with retry count)
/// - VideoUploaded   (success)
/// - VideoQueued     (offline: queued for later sync)
/// - VideoUploadFailed (all retries exhausted; user can retry)
/// - VideoCaptureError  (unrecoverable capture error)
///
/// Requirements: 5.1-5.10, 5.4, 5.5, 5.6, 5.9, 5.10, 6.10, 22.7
class VideoCaptureBloc extends Bloc<VideoCaptureEvent, VideoCaptureState> {
  VideoCaptureBloc({
    required this._captureVideoUseCase,
    required this._videoRepository,
    required this._capturedBy,
    required this._storageService,
  }) : super(const VideoCaptureInitial()) {
    on<CameraPermissionRequested>(_onCameraPermissionRequested);
    on<VideoCaptureInitialized>(_onVideoCaptureInitialized);
    on<StorageCheckRequested>(_onStorageCheckRequested);
    on<VideoRecordingStarted>(_onVideoRecordingStarted);
    on<VideoRecordingTicked>(_onVideoRecordingTicked);
    on<VideoRecordingAutoStopped>(_onVideoRecordingAutoStopped);
    on<VideoRecordingManualStopped>(_onVideoRecordingManualStopped);
    on<CameraFacingToggled>(_onCameraFacingToggled);
    on<VideoCaptureReset>(_onVideoCaptureReset);
    on<VideoCompressionStarted>(_onVideoCompressionStarted);
    on<VideoCompressionProgressed>(_onVideoCompressionProgressed);
    on<VideoUploadProgressed>(_onVideoUploadProgressed);
    on<VideoUploadRetryRequested>(_onVideoUploadRetryRequested);
  }

  final CaptureVideoUseCase _captureVideoUseCase;
  final VideoRepository _videoRepository;
  final String _capturedBy;
  final StorageService _storageService;

  /// Periodic 1-second timer running while a recording is active.
  Timer? _recordingTimer;

  /// Camera controller passed in by the screen widget so the BLoC can
  /// call [startVideoRecording] and [stopVideoRecording].
  CameraController? cameraController;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onCameraPermissionRequested(
    CameraPermissionRequested event,
    Emitter<VideoCaptureState> emit,
  ) async {
    emit(const CameraPermissionChecking());

    final context = event.context;
    if (context == null || !context.mounted) {
      emit(const CameraPermissionDenied());
      return;
    }

    final result = await CameraPermissionService.request(context);

    switch (result) {
      case PermissionResult.granted:
      case PermissionResult.restricted:
        emit(const CameraPermissionGranted());
      case PermissionResult.permanentlyDenied:
        emit(const CameraPermissionPermanentlyDenied());
      case PermissionResult.denied:
        emit(const CameraPermissionDenied());
    }
  }

  Future<void> _onVideoCaptureInitialized(
    VideoCaptureInitialized event,
    Emitter<VideoCaptureState> emit,
  ) async {
    emit(const VideoCaptureReady(isFrontCamera: false));
  }

  /// Checks device and offline-queue storage before allowing recording.
  ///
  /// 1. If available bytes < [StorageService.minRequiredBytes] → emit
  ///    [StorageInsufficient] and block recording.
  /// 2. If offline queue > 80 % of capacity → emit
  ///    [StorageWarningOfflineQueue]; recording is allowed after user
  ///    acknowledges the warning (UI dispatches [VideoRecordingStarted]).
  /// 3. Otherwise → dispatch [VideoRecordingStarted] directly.
  ///
  /// If the storage check itself throws, we fail-open: recording proceeds.
  ///
  /// Requirements: 5.9
  Future<void> _onStorageCheckRequested(
    StorageCheckRequested event,
    Emitter<VideoCaptureState> emit,
  ) async {
    try {
      final available = await _storageService.getAvailableStorageBytes();

      if (available < StorageService.minRequiredBytes) {
        emit(
          StorageInsufficient(
            availableBytes: available,
            requiredBytes: StorageService.minRequiredBytes,
          ),
        );
        return;
      }

      final usedBytes = await _storageService.getTotalVideoStorageUsedBytes();
      const totalBytes = StorageService.offlineStorageCapacityBytes;
      final usageRatio = usedBytes / totalBytes;

      if (usageRatio >= StorageService.offlineStorageWarningThreshold) {
        emit(
          StorageWarningOfflineQueue(
            usedBytes: usedBytes,
            totalBytes: totalBytes,
            boxId: event.boxId,
          ),
        );
        return;
      }
    } on Exception catch (e) {
      // Fail-open: log and proceed to recording.
      // Error details are not logged to avoid leaking sensitive paths.
      addError(e);
    }

    // Storage is fine — proceed with recording.
    add(VideoRecordingStarted(boxId: event.boxId));
  }

  Future<void> _onVideoRecordingStarted(
    VideoRecordingStarted event,
    Emitter<VideoCaptureState> emit,
  ) async {
    if (event.boxId.trim().isEmpty) {
      emit(
        const VideoCaptureError(
          message: 'Box ID is required to start recording.',
          code: 'MISSING_BOX_ID',
        ),
      );
      return;
    }

    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) {
      emit(
        const VideoCaptureError(
          message: 'Camera is not ready. Please try again.',
          code: 'CAMERA_NOT_READY',
        ),
      );
      return;
    }

    try {
      await controller.startVideoRecording();
    } on Exception catch (e) {
      emit(
        VideoCaptureError(
          message: 'Failed to start recording: ${e.toString()}',
          code: 'RECORDING_START_FAILED',
        ),
      );
      return;
    }

    final isFront = _currentIsFrontCamera();

    emit(
      VideoRecording(
        boxId: event.boxId,
        elapsedSeconds: 0,
        maxSeconds: Video.maxDurationSeconds,
        isFrontCamera: isFront,
      ),
    );

    _startTimer(event.boxId);
  }

  Future<void> _onVideoRecordingTicked(
    VideoRecordingTicked event,
    Emitter<VideoCaptureState> emit,
  ) async {
    final currentState = state;
    if (currentState is! VideoRecording) return;

    if (event.elapsedSeconds >= Video.maxDurationSeconds) {
      add(const VideoRecordingAutoStopped());
      return;
    }

    emit(
      VideoRecording(
        boxId: currentState.boxId,
        elapsedSeconds: event.elapsedSeconds,
        maxSeconds: currentState.maxSeconds,
        isFrontCamera: currentState.isFrontCamera,
      ),
    );
  }

  Future<void> _onVideoRecordingAutoStopped(
    VideoRecordingAutoStopped event,
    Emitter<VideoCaptureState> emit,
  ) async {
    await _stopAndSave(emit);
  }

  Future<void> _onVideoRecordingManualStopped(
    VideoRecordingManualStopped event,
    Emitter<VideoCaptureState> emit,
  ) async {
    await _stopAndSave(emit);
  }

  Future<void> _onCameraFacingToggled(
    CameraFacingToggled event,
    Emitter<VideoCaptureState> emit,
  ) async {
    final isFront = _currentIsFrontCamera();
    emit(VideoCaptureReady(isFrontCamera: !isFront));
  }

  Future<void> _onVideoCaptureReset(
    VideoCaptureReset event,
    Emitter<VideoCaptureState> emit,
  ) async {
    _cancelTimer();
    emit(VideoCaptureReady(isFrontCamera: _currentIsFrontCamera()));
  }

  /// Handles [VideoCompressionStarted] — runs compression then
  /// triggers upload or offline-queue.
  ///
  /// Requirements: 5.4, 5.5, 5.6, 22.7
  Future<void> _onVideoCompressionStarted(
    VideoCompressionStarted event,
    Emitter<VideoCaptureState> emit,
  ) async {
    emit(VideoCompressing(progress: 0, boxId: event.boxId));

    final result = await _videoRepository.compressAndUploadVideo(
      event.videoId,
      event.videoPath,
      event.boxId,
      event.capturedBy,
      event.durationSeconds,
      onCompressionProgress: (p) {
        add(VideoCompressionProgressed(progress: p));
      },
      onUploadProgress: (p) {
        add(VideoUploadProgressed(progress: p));
      },
    );

    result.fold(
      (failure) {
        // Distinguish between network failure (queued) and hard error.
        if (failure is NetworkFailure) {
          emit(VideoQueued(boxId: event.boxId, videoId: event.videoId));
        } else {
          emit(
            VideoUploadFailed(
              message: failure.message,
              code: failure.code,
              videoId: event.videoId,
              compressedPath: event.videoPath,
              boxId: event.boxId,
              capturedBy: event.capturedBy,
              durationSeconds: event.durationSeconds,
            ),
          );
        }
      },
      (video) {
        if (video.status == VideoStatus.uploaded) {
          emit(VideoUploaded(boxId: video.boxId, videoId: video.id));
        } else {
          // Status is pending — queued offline.
          emit(VideoQueued(boxId: video.boxId, videoId: video.id));
        }
      },
    );
  }

  Future<void> _onVideoCompressionProgressed(
    VideoCompressionProgressed event,
    Emitter<VideoCaptureState> emit,
  ) async {
    final currentState = state;
    if (currentState is VideoCompressing) {
      emit(VideoCompressing(progress: event.progress, boxId: currentState.boxId));
    }
  }

  Future<void> _onVideoUploadProgressed(
    VideoUploadProgressed event,
    Emitter<VideoCaptureState> emit,
  ) async {
    final currentState = state;
    if (currentState is VideoUploading) {
      emit(
        VideoUploading(
          progress: event.progress,
          boxId: currentState.boxId,
          videoId: currentState.videoId,
          currentAttempt: currentState.currentAttempt,
          maxAttempts: currentState.maxAttempts,
        ),
      );
    } else if (currentState is VideoCompressing) {
      // Transition from compressing → uploading on first progress tick.
      // The boxId carries over; we don't have the videoId here so we
      // keep a sentinel — the screen treats any VideoUploading state
      // the same regardless of videoId value at this point.
      emit(VideoUploading(progress: event.progress, boxId: currentState.boxId, videoId: ''));
    }
  }

  /// Handles [VideoUploadRetryRequested] — re-runs upload for a failed video.
  ///
  /// Requirements: 5.5, 6.10
  Future<void> _onVideoUploadRetryRequested(
    VideoUploadRetryRequested event,
    Emitter<VideoCaptureState> emit,
  ) async {
    emit(VideoUploading(progress: 0, boxId: event.boxId, videoId: event.videoId));

    final result = await _videoRepository.compressAndUploadVideo(
      event.videoId,
      event.compressedPath,
      event.boxId,
      event.capturedBy,
      event.durationSeconds,
      onUploadProgress: (p) {
        add(VideoUploadProgressed(progress: p));
      },
    );

    result.fold(
      (failure) {
        if (failure is NetworkFailure) {
          emit(VideoQueued(boxId: event.boxId, videoId: event.videoId));
        } else {
          emit(
            VideoUploadFailed(
              message: failure.message,
              code: failure.code,
              videoId: event.videoId,
              compressedPath: event.compressedPath,
              boxId: event.boxId,
              capturedBy: event.capturedBy,
              durationSeconds: event.durationSeconds,
            ),
          );
        }
      },
      (video) {
        if (video.status == VideoStatus.uploaded) {
          emit(VideoUploaded(boxId: video.boxId, videoId: video.id));
        } else {
          emit(VideoQueued(boxId: video.boxId, videoId: video.id));
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Stops the recording, saves the file locally via [CaptureVideoUseCase],
  /// and emits [VideoCaptureComplete] which triggers compression.
  Future<void> _stopAndSave(Emitter<VideoCaptureState> emit) async {
    _cancelTimer();

    final currentState = state;
    if (currentState is! VideoRecording) return;

    final boxId = currentState.boxId;
    final elapsed = currentState.elapsedSeconds;

    emit(const VideoRecordingStopping());

    final controller = cameraController;
    if (controller == null) {
      emit(
        const VideoCaptureError(
          message: 'Camera controller unavailable.',
          code: 'CAMERA_UNAVAILABLE',
        ),
      );
      return;
    }

    XFile? videoFile;
    try {
      videoFile = await controller.stopVideoRecording();
    } on Exception catch (e) {
      emit(
        VideoCaptureError(
          message: 'Failed to stop recording: ${e.toString()}',
          code: 'RECORDING_STOP_FAILED',
        ),
      );
      return;
    }

    // Clamp duration to the valid range (min 5s, max 10s).
    final duration = elapsed.clamp(Video.minDurationSeconds, Video.maxDurationSeconds);

    final result = await _captureVideoUseCase(
      CaptureVideoParams(
        boxId: boxId,
        capturedBy: _capturedBy,
        localPath: videoFile.path,
        durationSeconds: duration,
      ),
    );

    result.fold(
      (failure) => emit(VideoCaptureError(message: failure.message, code: failure.code)),
      (video) {
        // Recording saved — immediately kick off compression + upload.
        emit(
          VideoCaptureComplete(
            videoPath: video.localPath,
            durationSeconds: video.durationSeconds,
            boxId: video.boxId,
          ),
        );
        // Dispatch compression event (async, non-blocking for the emitter).
        add(
          VideoCompressionStarted(
            videoId: video.id,
            videoPath: video.localPath,
            boxId: video.boxId,
            capturedBy: _capturedBy,
            durationSeconds: video.durationSeconds,
          ),
        );
      },
    );
  }

  void _startTimer(String boxId) {
    _cancelTimer();
    var elapsed = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed += 1;
      add(VideoRecordingTicked(elapsedSeconds: elapsed));
    });
  }

  void _cancelTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  bool _currentIsFrontCamera() {
    final s = state;
    if (s is VideoCaptureReady) return s.isFrontCamera;
    if (s is VideoRecording) return s.isFrontCamera;
    return false;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
