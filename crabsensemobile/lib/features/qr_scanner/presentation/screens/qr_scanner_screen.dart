import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/selected_farm_provider.dart';
import '../../../box_management/presentation/providers/boxes_provider.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../bloc/bloc.dart';
import '../widgets/permission_view.dart';
import '../widgets/qr_scanner_view.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/quick_result_sheet.dart';
import '../widgets/scan_qr_header.dart';
import '../widgets/scan_skeleton.dart';

/// Material 3 Scan QR tab — fullscreen camera + quick-result overlay.
class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  late MobileScannerController _controller;
  final ImagePicker _picker = ImagePicker();
  bool _syncingTorch = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ScannerBloc>().add(
            CameraPermissionRequested(context: context),
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ensureTorchMatches(bool wantOn) async {
    if (_syncingTorch) return;
    final current = _controller.value.torchState == TorchState.on;
    if (current == wantOn) return;
    _syncingTorch = true;
    try {
      await _controller.toggleTorch();
    } catch (_) {
      // Device may not support torch.
    } finally {
      _syncingTorch = false;
    }
  }

  Future<void> _switchFacing() async {
    try {
      await _controller.switchCamera();
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    final bloc = context.read<ScannerBloc>();
    final state = bloc.state;
    if (state is! ScannerActive &&
        !(state is QuickResultReady && state.continuousScan)) {
      return;
    }
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    bloc.add(QRCodeDetected(rawValue: raw));
  }

  Future<void> _openAlbum() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    try {
      final capture = await _controller.analyzeImage(file.path);
      final barcodes = capture?.barcodes ?? const [];
      final raw = barcodes.isEmpty ? null : barcodes.first.rawValue;
      if (raw == null || raw.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy mã QR trong ảnh.')),
        );
        return;
      }
      context.read<ScannerBloc>().add(QRCodeDetected(rawValue: raw));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đọc được QR từ ảnh.')),
      );
    }
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: kHomeBlue.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kHomeCyan.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: kHomeCyan.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'HƯỚNG DẪN QUÉT QR',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: kHomeBlueLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Đưa mã QR trên hộp vào giữa khung.\n'
              '2. Giữ ổn định trong đủ sáng.\n'
              '3. Dùng Album để quét từ ảnh có sẵn.\n'
              '4. Quét liên tục giữ camera mở sau mỗi lần quét.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(ScanQuickAction action, QuickResultReady state) {
    final boxId = state.result.boxId;
    final farmId = state.result.farmId;
    final bloc = context.read<ScannerBloc>();

    switch (action) {
      case ScanQuickAction.details:
        context.push(RoutePaths.boxDetails(boxId));
      case ScanQuickAction.aiDetection:
        unawaited(_openAiDetection(boxId));
      case ScanQuickAction.videoAi:
        context.push(RoutePaths.boxVideo(boxId));
      case ScanQuickAction.water:
        if (farmId.isNotEmpty) {
          context.push(RoutePaths.waterQualityForFarm(farmId));
        } else {
          context.push(RoutePaths.waterQuality);
        }
      case ScanQuickAction.harvest:
        context.push(RoutePaths.harvestForBox(boxId, farmId: farmId));
      case ScanQuickAction.cameraLive:
        context.push(RoutePaths.boxCamera(boxId));
      case ScanQuickAction.note:
        context.push(RoutePaths.operationsForBox(boxId));
      case ScanQuickAction.createTask:
        context.push(RoutePaths.operationsForBox(boxId));
      case ScanQuickAction.scanAgain:
        bloc.add(const ScannerReset());
    }
  }

  /// Open latest AI detection for box, or fall back to video capture.
  Future<void> _openAiDetection(String boxId) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đang tải phân tích AI…'),
        duration: Duration(seconds: 1),
      ),
    );

    final result = await sl<ApiClient>().safeGet<Map<String, dynamic>>(
      ApiConstants.aiDetections,
      queryParameters: {'boxId': boxId},
    );

    if (!mounted) return;

    if (result.failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
      context.push(RoutePaths.boxVideo(boxId));
      return;
    }

    final body = result.data.data;
    List list = const [];
    if (body != null) {
      final nested = body['data'];
      if (nested is List) {
        list = nested;
      }
    }

    String? mediaId;
    for (final raw in list) {
      if (raw is! Map) continue;
      final mid = (raw['mediaId'] ?? raw['MediaId'] ?? raw['videoId'])?.toString();
      if (mid != null && mid.isNotEmpty) {
        mediaId = mid;
        break;
      }
    }

    if (mediaId != null) {
      context.push(
        RoutePaths.aiResults(mediaId),
        extra: {'boxId': boxId},
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Chưa có AI detection — quay video để phân tích.'),
      ),
    );
    context.push(RoutePaths.boxVideo(boxId));
  }

  void _onFailure(BoxFetchFailure state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: kHomeBlue.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.55),
                ),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Colors.redAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              state.message.isNotEmpty
                  ? state.message
                  : 'QR không thuộc hệ thống CrabSense.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5BA0FF), kHomeBlue, Color(0xFF1A5FD0)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kHomeBlue.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<ScannerBloc>().add(const ScannerReset());
                    },
                    child: const Center(
                      child: Text(
                        'Quét lại',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _farmLabel(ScannerState state) {
    final shared = ref.watch(selectedFarmProvider);
    if (shared.name.isNotEmpty) return shared.name;
    final boxes = ref.watch(boxesStateProvider).valueOrNull;
    final selected = boxes?.selectedFarmName;
    if (selected != null && selected.isNotEmpty) return selected;
    return state.flags.farmLabel;
  }

  Widget _resultPanel(QuickResultReady state, {required bool embedded}) {
    return QuickResultSheet(
      embedded: embedded,
      result: state.result,
      history: state.history,
      onAction: (a) => _handleAction(a, state),
      onViewAnalysis: () =>
          context.push(RoutePaths.boxInspect(state.result.boxId)),
      onRescanHistory: (e) => context.read<ScannerBloc>().add(
            RescanFromHistory(rawValue: e.rawValue),
          ),
      onSync: () =>
          context.read<ScannerBloc>().add(const SyncWhenOnlineRequested()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTabletLandscape =
        MediaQuery.sizeOf(context).shortestSide >= 600 &&
            MediaQuery.orientationOf(context) == Orientation.landscape;

    return BlocConsumer<ScannerBloc, ScannerState>(
      listenWhen: (prev, next) =>
          prev.runtimeType != next.runtimeType ||
          next.isFlashlightOn != prev.isFlashlightOn ||
          (next is QuickResultReady && prev is! QuickResultReady),
      listener: (context, state) async {
        unawaited(_ensureTorchMatches(state.isFlashlightOn));

        if (state is ScannerPermissionGranted) {
          context.read<ScannerBloc>().add(const ScannerStarted());
        }
        if (state is QuickResultReady) {
          await HapticFeedback.mediumImpact();
        }
        if (state is BoxFetchFailure) {
          _onFailure(state);
        }
        if (state is ScannerError) {
          _onFailure(
            BoxFetchFailure(message: state.message, code: state.code),
          );
        }
        if (state is ScanQueuedOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Dữ liệu ngoại tuyến — đã lưu để đồng bộ.',
              ),
              action: SnackBarAction(
                label: 'Đồng bộ',
                onPressed: () => context
                    .read<ScannerBloc>()
                    .add(const SyncWhenOnlineRequested()),
              ),
            ),
          );
          context.read<ScannerBloc>().add(const ScannerReset());
        }
      },
      builder: (context, state) {
        if (state is ScannerPermissionDenied ||
            state is ScannerPermissionPermanentlyDenied) {
          return PermissionView(
            isPermanentlyDenied: state is ScannerPermissionPermanentlyDenied,
            onRetry: () => context.read<ScannerBloc>().add(
                  CameraPermissionRequested(context: context),
                ),
            onCancel: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RoutePaths.dashboard);
              }
            },
          );
        }

        if (state is ScannerPermissionChecking || state is ScannerInitial) {
          return const ColoredBox(
            color: kHomeNavyDeep,
            child: Center(child: ScanSkeleton()),
          );
        }

        final camera = Stack(
          fit: StackFit.expand,
          children: [
            QRScannerView(
              controller: _controller,
              onDetect: _onDetect,
              isSuccess: state is QuickResultReady,
              isProcessing:
                  state is ScannerProcessing || state is BoxFetchInProgress,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ScanQRHeader(
                farmLabel: _farmLabel(state),
                isTorchOn: state.isFlashlightOn,
                continuousScan: state.continuousScan,
                onToggleTorch: () => context
                    .read<ScannerBloc>()
                    .add(const FlashlightToggled()),
                onToggleFacing: () {
                  context
                      .read<ScannerBloc>()
                      .add(const CameraFacingToggled());
                  unawaited(_switchFacing());
                },
                onOpenAlbum: _openAlbum,
                onHelp: _showHelp,
                onToggleContinuous: () => context
                    .read<ScannerBloc>()
                    .add(const ContinuousScanModeToggled()),
              ),
            ),
            if (!isTabletLandscape && state is BoxFetchInProgress)
              const Align(
                alignment: Alignment.bottomCenter,
                child: ScanSkeleton(),
              ),
            if (!isTabletLandscape && state is QuickResultReady)
              Align(
                alignment: Alignment.bottomCenter,
                child: _resultPanel(state, embedded: false),
              ),
          ],
        );

        if (isTabletLandscape) {
          return ColoredBox(
            color: kHomeNavyDeep,
            child: Row(
              children: [
                Expanded(flex: 55, child: camera),
                Expanded(
                  flex: 45,
                  child: state is QuickResultReady
                      ? _resultPanel(state, embedded: true)
                      : state is BoxFetchInProgress
                          ? const ColoredBox(
                              color: kHomeNavy,
                              child: ScanSkeleton(),
                            )
                          : ColoredBox(
                              color: kHomeNavy,
                              child: Center(
                                child: Text(
                                  'Quét QR để xem thông tin hộp',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          );
        }

        return ColoredBox(color: kHomeNavyDeep, child: camera);
      },
    );
  }
}
