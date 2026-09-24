import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/camera_device.dart';
import '../../../models/production_models.dart';
import '../../../services/camera_device_service.dart';
import '../../../services/crab_profile_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../../utils/camera_connect_test.dart';
import '../../../utils/camera_stream_url_helper.dart';
import '../../camera/camera_jpeg_fetch.dart';
import '../../camera/camera_stream_player.dart';
import '../../crab/crab_overview_cards.dart';
import '../../shared/mgmt_ui.dart';

enum BoxAiDetectionStatus { normal, monitoring, warning, recovered, noCrab }

enum BoxAiRealtime { analyzing, pausedNoCamera, pausedAiDown }

class BoxAiDetection {
  const BoxAiDetection({
    required this.id,
    required this.at,
    required this.type,
    required this.typeLabel,
    required this.status,
    this.confidence,
    this.activityScore,
    this.note,
    this.imageUrl,
    this.videoUrl,
    this.cameraId,
    this.cameraCode,
    this.boxId,
    this.crabId,
    this.crabTag,
  });

  final String id;
  final DateTime at;
  final String type;
  final String typeLabel;
  final BoxAiDetectionStatus status;
  final int? confidence;
  final int? activityScore;
  final String? note;
  final String? imageUrl;
  final String? videoUrl;
  final String? cameraId;
  final String? cameraCode;
  final String? boxId;
  final String? crabId;
  final String? crabTag;
}

class BoxCameraAITab extends StatefulWidget {
  const BoxCameraAITab({
    super.key,
    required this.box,
    required this.cameraService,
    required this.profileService,
    required this.areaCode,
    required this.rowLabel,
    this.crabCode,
    this.onManageCamera,
    this.onOpenAlerts,
    this.onOpenAllHistory,
  });

  final BoxRecord box;
  final CameraDeviceService cameraService;
  final CrabProfileService profileService;
  final String areaCode;
  final String rowLabel;
  final String? crabCode;
  final VoidCallback? onManageCamera;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenAllHistory;

  @override
  State<BoxCameraAITab> createState() => _BoxCameraAITabState();
}

class _BoxCameraAITabState extends State<BoxCameraAITab> {
  final _historyKey = GlobalKey();
  List<BoxAiDetection> _events = const [];
  var _aiLoading = true;
  var _aiServiceOnline = true;
  String? _aiError;
  var _reconnecting = false;
  String? _reconnectError;
  var _reconnectOk = false;
  int? _measuredLatencyMs;
  var _playerEpoch = 0;

  CameraDeviceService get _cams => widget.cameraService;

  @override
  void initState() {
    super.initState();
    _cams.addListener(_onCam);
    _loadAi();
  }

  @override
  void didUpdateWidget(covariant BoxCameraAITab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.box.id != widget.box.id) {
      _loadAi();
    }
  }

  @override
  void dispose() {
    _cams.removeListener(_onCam);
    super.dispose();
  }

  void _onCam() {
    if (mounted) setState(() {});
  }

  Future<void> _reloadCamera() => _cams.loadCamerasByBox(widget.box.id);

  Future<void> _loadAi() async {
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final raw = await widget.profileService.fetchAiDetections(boxId: widget.box.id, take: 12);
      final events = raw.map(_parseDetection).whereType<BoxAiDetection>().toList()
        ..sort((a, b) => b.at.compareTo(a.at));
      if (!mounted) return;
      setState(() {
        _events = events;
        _aiServiceOnline = true;
        _aiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiServiceOnline = false;
        _aiError = '$e';
        _aiLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_reloadCamera(), _loadAi()]);
    if (mounted) setState(() => _playerEpoch++);
  }

  Future<void> _reconnect(CameraDevice cam) async {
    setState(() {
      _reconnecting = true;
      _reconnectError = null;
      _reconnectOk = false;
    });
    final result = await runCameraConnectTest(
      streamUrl: cam.streamUrl,
      ipAddress: cam.ipAddress ?? cam.snapshotUrl,
    );
    await _reloadCamera();
    if (!mounted) return;
    if (result.success) {
      final ok = result.tests.where((t) => t.ok).toList();
      setState(() {
        _reconnecting = false;
        _reconnectOk = true;
        _measuredLatencyMs = ok.isEmpty ? null : ok.first.ms;
        _playerEpoch++;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera đã kết nối lại.', style: bvText(color: Colors.white)),
          backgroundColor: DashboardColors.brand,
        ),
      );
    } else {
      final fail = result.tests.where((t) => !t.ok).toList();
      setState(() {
        _reconnecting = false;
        _reconnectOk = false;
        _measuredLatencyMs = null;
        _reconnectError = (result.error ?? '').trim().isNotEmpty
            ? result.error
            : (fail.isEmpty ? 'Camera không phản hồi.' : fail.first.detail);
      });
    }
  }

  Future<void> _captureStill(CameraDevice cam) async {
    final url = CameraStreamUrlHelper.snapshotFallback(
      streamUrl: cam.streamUrl,
      ipAddress: cam.ipAddress ?? cam.snapshotUrl,
    );
    if (url == null || url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa có ảnh chụp từ camera.', style: bvText(color: Colors.white))),
      );
      return;
    }
    final bytes = await fetchJpegUrl(url);
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không chụp được ảnh từ camera.', style: bvText(color: Colors.white))),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Ảnh chụp — ${cam.cameraCode}', style: bvText(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white70)),
                  ],
                ),
              ),
              Flexible(child: InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain))),
            ],
          ),
        ),
      ),
    );
  }

  void _fullscreen(CameraDevice cam) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: const Color(0xFF12332D),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(cam.cameraCode, style: bvText(color: Colors.white, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white70)),
                  ],
                ),
              ),
              Expanded(child: _livePlayer(cam)),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BoxAiDetection e) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AIDetectionDetailDrawer(
            event: e,
            boxCode: widget.box.boxCode,
            crabCode: widget.crabCode ?? widget.box.crabTag,
            onOpenImage: e.imageUrl == null ? null : () => _lightbox(e),
            onOpenVideo: e.videoUrl == null ? null : () => _openVideo(e.videoUrl!),
            onClose: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  void _lightbox(BoxAiDetection e) {
    final url = e.imageUrl;
    if (url == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(e.typeLabel, style: bvText(color: Colors.white, fontWeight: FontWeight.w700))),
                    if (e.videoUrl != null)
                      TextButton.icon(
                        onPressed: () => _openVideo(e.videoUrl!),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        label: Text('Xem video', style: bvText(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white70)),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Không tải được ảnh.', style: bvText(color: Colors.white70)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVideo(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF12332D),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 560),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                child: Row(
                  children: [
                    Expanded(child: Text('Video phát hiện', style: bvText(color: Colors.white, fontWeight: FontWeight.w700))),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white70)),
                  ],
                ),
              ),
              Expanded(
                child: CameraStreamPlayer(
                  streamUrl: url,
                  snapshotOnly: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollHistory() {
    final ctx = _historyKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 280), alignment: 0.05);
  }

  @override
  Widget build(BuildContext context) {
    final loading = _cams.loading && _cams.cameras.isEmpty;
    if (loading) return const _CameraTabSkeleton();
    if (_cams.error != null && _cams.cameras.isEmpty) {
      return OverviewCard(
        icon: Icons.videocam_off_outlined,
        title: 'Camera AI',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Không thể tải thông tin camera.', style: bvText(fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
            const SizedBox(height: 6),
            Text(_cams.error!, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
            const SizedBox(height: 10),
            MgmtPrimaryButton(icon: Icons.refresh_rounded, label: 'Thử lại', height: 38, onTap: _reloadCamera),
          ],
        ),
      );
    }

    final cam = _linkedCamera();
    if (cam == null) {
      return MgmtEmptyState(
        icon: Icons.videocam_outlined,
        title: 'Chưa có camera được liên kết',
        message: '${widget.box.boxCode} hiện chưa có camera AI.',
        action: MgmtPrimaryButton(
          icon: Icons.add_rounded,
          label: 'Liên kết camera',
          height: 38,
          onTap: widget.onManageCamera,
        ),
      );
    }

    final live = cam.isOnline && _hasStream(cam);
    final last = _events.isEmpty ? null : _events.first;
    final realtime = !_aiServiceOnline
        ? BoxAiRealtime.pausedAiDown
        : live
            ? BoxAiRealtime.analyzing
            : BoxAiRealtime.pausedNoCamera;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final desktop = w >= 1100;
        final tablet = w >= 760;
        final player = CameraMainPlayer(
          camera: cam,
          live: live,
          reconnecting: _reconnecting,
          reconnectError: _reconnectError,
          reconnectOk: _reconnectOk,
          playerEpoch: _playerEpoch,
          onReconnect: () => _reconnect(cam),
          onManage: widget.onManageCamera,
          onHistory: _scrollHistory,
          onFullscreen: live ? () => _fullscreen(cam) : null,
          onCapture: live ? () => _captureStill(cam) : null,
          onRefresh: _refreshAll,
          overlay: live && realtime == BoxAiRealtime.analyzing ? last : null,
        );
        final info = CameraInfoCard(
          camera: cam,
          boxCode: widget.box.boxCode,
          areaCode: widget.areaCode,
          rowLabel: widget.rowLabel,
        );
        final conn = CameraConnectionStatus(
          camera: cam,
          live: live,
          aiOnline: _aiServiceOnline,
          latencyMs: live ? _measuredLatencyMs : null,
        );
        final tracking = AITrackingCard(
          realtime: realtime,
          last: last,
          cameraCode: cam.cameraCode,
          warningCount: _events.where((e) => e.status == BoxAiDetectionStatus.warning).length,
          onOpenWarning: last == null
              ? null
              : () {
                  _openDetail(last);
                  if (last.status == BoxAiDetectionStatus.warning) widget.onOpenAlerts?.call();
                },
        );
        final latest = LatestAIDetectionCard(
          event: last,
          loading: _aiLoading,
          cameraCode: cam.cameraCode,
          onDetail: last == null ? null : () => _openDetail(last),
          onThumb: last?.imageUrl == null ? null : () => _lightbox(last!),
        );
        final history = AIDetectionHistory(
          key: _historyKey,
          events: _events,
          loading: _aiLoading,
          error: _aiError,
          compact: !desktop && !tablet,
          onRetry: _loadAi,
          onOpenAll: widget.onOpenAllHistory,
          onRow: _openDetail,
          onThumb: _lightbox,
        );

        if (desktop) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 50, child: player),
                  const SizedBox(width: 12),
                  Expanded(flex: 24, child: info),
                  const SizedBox(width: 12),
                  Expanded(flex: 26, child: conn),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 28, child: tracking),
                  const SizedBox(width: 12),
                  Expanded(flex: 28, child: latest),
                  const SizedBox(width: 12),
                  Expanded(flex: 44, child: history),
                ],
              ),
            ],
          );
        }
        if (tablet) {
          return Column(
            children: [
              player,
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 12),
                  Expanded(child: conn),
                ],
              ),
              const SizedBox(height: 12),
              tracking,
              const SizedBox(height: 12),
              latest,
              const SizedBox(height: 12),
              history,
            ],
          );
        }
        return Column(
          children: [
            player,
            const SizedBox(height: 12),
            info,
            const SizedBox(height: 12),
            conn,
            const SizedBox(height: 12),
            tracking,
            const SizedBox(height: 12),
            latest,
            const SizedBox(height: 12),
            history,
          ],
        );
      },
    );
  }

  CameraDevice? _linkedCamera() {
    for (final cam in _cams.cameras) {
      final code = cam.cameraCode.trim().toLowerCase();
      if (code.isEmpty || code == 'none' || code == 'media-preview') continue;
      if (cam.status.toLowerCase() == 'preview' && cam.id == cam.boxId) continue;
      return cam;
    }
    return null;
  }

  bool _hasStream(CameraDevice cam) {
    final url = (cam.streamUrl ?? '').trim();
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.contains('stream.crabsense.local')) return false;
    return lower.startsWith('rtsp://') ||
        lower.startsWith('rtsps://') ||
        lower.startsWith('http://') ||
        lower.startsWith('https://');
  }

  Widget _livePlayer(CameraDevice cam) {
    final raw = cam.streamUrl!.trim();
    final candidates = CameraStreamUrlHelper.hasMjpegEndpoint(raw)
        ? [raw]
        : CameraStreamUrlHelper.streamCandidates(streamUrl: cam.streamUrl, ipAddress: cam.ipAddress ?? cam.snapshotUrl);
    if (candidates.isEmpty) {
      return Center(child: Text('Không có luồng hình ảnh.', style: bvText(color: Colors.white70)));
    }
    return CameraStreamPlayer(
      key: ValueKey('box-ai-${cam.id}-$raw-$_playerEpoch'),
      streamUrl: candidates.first,
      ipAddress: CameraStreamUrlHelper.streamHost(streamUrl: cam.streamUrl, ipAddress: cam.ipAddress) ?? cam.ipAddress,
      snapshotFallbackUrl: CameraStreamUrlHelper.snapshotFallback(streamUrl: cam.streamUrl, ipAddress: cam.ipAddress ?? cam.snapshotUrl),
      streamUrlCandidates: candidates.length > 1 ? candidates.sublist(1) : null,
    );
  }
}

class CameraMainPlayer extends StatelessWidget {
  const CameraMainPlayer({
    super.key,
    required this.camera,
    required this.live,
    required this.reconnecting,
    required this.playerEpoch,
    this.reconnectError,
    this.reconnectOk = false,
    this.onReconnect,
    this.onManage,
    this.onHistory,
    this.onFullscreen,
    this.onCapture,
    this.onRefresh,
    this.overlay,
  });

  final CameraDevice camera;
  final bool live;
  final bool reconnecting;
  final int playerEpoch;
  final String? reconnectError;
  final bool reconnectOk;
  final VoidCallback? onReconnect;
  final VoidCallback? onManage;
  final VoidCallback? onHistory;
  final VoidCallback? onFullscreen;
  final VoidCallback? onCapture;
  final VoidCallback? onRefresh;
  final BoxAiDetection? overlay;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.videocam_outlined,
      title: camera.cameraCode,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MgmtStatusBadge(
            label: live ? 'Trực tuyến' : 'Mất kết nối',
            color: live ? DashboardColors.brand : const Color(0xFFEF4444),
          ),
          if (onFullscreen != null) ...[
            const SizedBox(width: 8),
            MgmtOutlineButton(
              icon: Icons.fullscreen_rounded,
              label: 'Toàn màn hình',
              height: 32,
              onTap: onFullscreen,
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: live ? _online() : CameraOfflineState(camera: camera),
            ),
          ),
          if (!live && _lastSnapshot != null) ...[
            const SizedBox(height: 8),
            _LastFrameNote(url: _lastSnapshot!, at: camera.lastSeenAt),
          ],
          const SizedBox(height: 10),
          if (live)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MgmtOutlineButton(icon: Icons.fullscreen_rounded, label: 'Toàn màn hình', onTap: onFullscreen),
                MgmtOutlineButton(icon: Icons.photo_camera_outlined, label: 'Chụp ảnh', onTap: onCapture),
                MgmtOutlineButton(icon: Icons.refresh_rounded, label: 'Làm mới', onTap: onRefresh),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (reconnecting)
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: DashboardColors.brand, borderRadius: BorderRadius.circular(11)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        const SizedBox(width: 8),
                        Text('Đang kết nối...', style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  )
                else
                  MgmtPrimaryButton(
                    icon: Icons.refresh_rounded,
                    label: reconnectError == null ? 'Thử kết nối lại' : 'Thử lại',
                    height: 38,
                    onTap: onReconnect,
                  ),
                MgmtOutlineButton(icon: Icons.settings_outlined, label: 'Quản lý camera', onTap: onManage),
                MgmtOutlineButton(icon: Icons.history_rounded, label: 'Xem lịch sử', onTap: onHistory),
              ],
            ),
          if (reconnectError != null && !live) ...[
            const SizedBox(height: 10),
            _PaleBanner(
              color: const Color(0xFFEF4444),
              icon: Icons.warning_amber_rounded,
              text: 'Không thể kết nối camera. $reconnectError',
            ),
          ],
          if (reconnectOk && live) ...[
            const SizedBox(height: 10),
            const _PaleBanner(
              color: DashboardColors.brand,
              icon: Icons.check_circle_outline,
              text: 'Camera đã kết nối lại.',
            ),
          ],
        ],
      ),
    );
  }

  String? get _lastSnapshot {
    final snap = (camera.snapshotUrl ?? camera.ipAddress ?? '').trim();
    if (snap.isEmpty) return null;
    final l = snap.toLowerCase();
    if (l.startsWith('http://') || l.startsWith('https://')) return snap;
    return null;
  }

  Widget _online() {
    final raw = camera.streamUrl!.trim();
    final candidates = CameraStreamUrlHelper.hasMjpegEndpoint(raw)
        ? [raw]
        : CameraStreamUrlHelper.streamCandidates(streamUrl: camera.streamUrl, ipAddress: camera.ipAddress ?? camera.snapshotUrl);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF12332D)),
        if (candidates.isNotEmpty)
          CameraStreamPlayer(
            key: ValueKey('box-ai-main-${camera.id}-$raw-$playerEpoch'),
            streamUrl: candidates.first,
            ipAddress: CameraStreamUrlHelper.streamHost(streamUrl: camera.streamUrl, ipAddress: camera.ipAddress) ?? camera.ipAddress,
            snapshotFallbackUrl: CameraStreamUrlHelper.snapshotFallback(
              streamUrl: camera.streamUrl,
              ipAddress: camera.ipAddress ?? camera.snapshotUrl,
            ),
            streamUrlCandidates: candidates.length > 1 ? candidates.sublist(1) : null,
          )
        else
          Center(child: Text('Không có luồng hình ảnh.', style: bvText(color: Colors.white70))),
        Positioned(
          left: 12,
          top: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(camera.cameraCode, style: bvText(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(fmtDateTimeSec(DateTime.now()), style: bvText(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(999)),
            child: Text('● LIVE', style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        if (overlay != null && overlay!.status != BoxAiDetectionStatus.noCrab)
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                overlay!.confidence == null
                    ? 'Crab detected'
                    : 'Crab detected  ${overlay!.confidence}%',
                style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class CameraOfflineState extends StatelessWidget {
  const CameraOfflineState({super.key, required this.camera});

  final CameraDevice camera;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, size: 42, color: Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              Text('Camera mất kết nối', style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                'Không nhận được luồng hình ảnh\ntừ ${camera.cameraCode}.',
                textAlign: TextAlign.center,
                style: bvText(fontSize: 12.5, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 14),
              _meta('Lần kết nối cuối', fmtDateTimeSec(camera.lastSeenAt)),
              _meta('Đã mất kết nối', offlineFor(camera.lastSeenAt)),
              _meta('Nguyên nhân', offlineReason(camera)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$k:  ', style: bvText(fontSize: 12, color: const Color(0xFF94A3B8))),
            TextSpan(text: v, style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class CameraInfoCard extends StatelessWidget {
  const CameraInfoCard({
    super.key,
    required this.camera,
    required this.boxCode,
    required this.areaCode,
    required this.rowLabel,
  });

  final CameraDevice camera;
  final String boxCode;
  final String areaCode;
  final String rowLabel;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Mã camera', camera.cameraCode),
      if (boxCode.isNotEmpty) ('Liên kết hộp', boxCode),
      if (areaCode.isNotEmpty) ('Khu vực', areaCode),
      if (rowLabel.isNotEmpty) ('Dãy', rowLabel),
      if (_cameraType(camera) != null) ('Loại camera', _cameraType(camera)!),
      if (_power(camera) != null) ('Nguồn cấp', _power(camera)!),
    ];
    return OverviewCard(
      icon: Icons.info_outline_rounded,
      title: 'Thông tin camera',
      child: Column(
        children: [
          for (final r in rows) _kv(r.$1, r.$2),
        ],
      ),
    );
  }

  String? _cameraType(CameraDevice cam) {
    final url = (cam.streamUrl ?? '').toLowerCase();
    if (url.startsWith('rtsp://') || url.startsWith('rtsps://')) return 'IP Camera (RTSP)';
    if (url.startsWith('http://') || url.startsWith('https://')) return 'IP Camera (HTTP)';
    return null;
  }

  String? _power(CameraDevice cam) {
    final m = (cam.message ?? '').toLowerCase();
    if (m.contains('poe')) return 'PoE';
    if (m.contains('220')) return '220V';
    return null;
  }
}

class CameraConnectionStatus extends StatelessWidget {
  const CameraConnectionStatus({
    super.key,
    required this.camera,
    required this.live,
    required this.aiOnline,
    this.latencyMs,
  });

  final CameraDevice camera;
  final bool live;
  final bool aiOnline;
  final int? latencyMs;

  @override
  Widget build(BuildContext context) {
    final staleMin = _offlineMinutes(camera.lastSeenAt);
    return OverviewCard(
      icon: Icons.wifi_tethering_rounded,
      title: 'Trạng thái kết nối',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusRow('Camera', live ? 'Online' : 'Mất kết nối', live ? DashboardColors.brand : const Color(0xFFEF4444)),
          _statusRow('AI Service', aiOnline ? 'Online' : 'Mất kết nối', aiOnline ? DashboardColors.brand : const Color(0xFFEF4444)),
          _statusRow(
            'Stream',
            live ? 'Bình thường' : 'Không có dữ liệu',
            live ? DashboardColors.brand : const Color(0xFF94A3B8),
          ),
          _kv(live ? 'Frame cuối' : 'Lần nhận frame', fmtDateTimeSec(camera.lastSeenAt)),
          _kv('Độ trễ', latencyMs == null ? '—' : '$latencyMs ms'),
          _kv('Chất lượng tín hiệu', '—'),
          if (!live && staleMin != null && staleMin >= 5) ...[
            const SizedBox(height: 8),
            _PaleBanner(
              color: const Color(0xFFEF4444),
              icon: Icons.warning_amber_rounded,
              text: 'Đã $staleMin phút chưa nhận được dữ liệu hình ảnh từ camera.',
            ),
          ],
        ],
      ),
    );
  }
}

class AITrackingCard extends StatelessWidget {
  const AITrackingCard({
    super.key,
    required this.realtime,
    required this.cameraCode,
    required this.warningCount,
    this.last,
    this.onOpenWarning,
  });

  final BoxAiRealtime realtime;
  final BoxAiDetection? last;
  final String cameraCode;
  final int warningCount;
  final VoidCallback? onOpenWarning;

  @override
  Widget build(BuildContext context) {
    final analyzing = realtime == BoxAiRealtime.analyzing;
    return OverviewCard(
      icon: Icons.visibility_outlined,
      title: 'AI theo dõi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusRow(
            'Trạng thái AI',
            analyzing ? 'Đang phân tích' : 'Tạm dừng',
            analyzing ? DashboardColors.brand : const Color(0xFFF5B700),
          ),
          if (realtime == BoxAiRealtime.pausedAiDown) ...[
            const SizedBox(height: 8),
            Text('AI hiện không khả dụng.', style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Không có phân tích realtime nên không thể kết luận bất thường.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          ] else if (realtime == BoxAiRealtime.pausedNoCamera) ...[
            const SizedBox(height: 8),
            Text(
              'Camera đang mất kết nối nên AI tạm dừng phân tích realtime.\nDữ liệu hiển thị là lần phân tích cuối cùng.',
              style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
            ),
            const SizedBox(height: 10),
            _lastRows(asCurrent: false),
          ] else ...[
            const SizedBox(height: 8),
            if (last == null)
              Text('Chưa có kết quả phân tích.', style: bvText(color: DashboardColors.textMuted))
            else if (last!.status == BoxAiDetectionStatus.warning) ...[
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF5B700)),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Phát hiện hành vi bất thường', style: bvText(fontWeight: FontWeight.w800))),
                ],
              ),
              const SizedBox(height: 4),
              Text(last!.note ?? last!.typeLabel, style: bvText(fontSize: 12.5)),
              _lastRows(asCurrent: true),
              OverviewLinkButton(label: 'Xem chi tiết', onTap: onOpenWarning),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: DashboardColors.brand),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Không phát hiện bất thường', style: bvText(fontWeight: FontWeight.w800))),
                ],
              ),
              const SizedBox(height: 4),
              Text(last!.note ?? 'Cua hoạt động bình thường.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              _lastRows(asCurrent: true),
            ],
          ],
        ],
      ),
    );
  }

  Widget _lastRows({required bool asCurrent}) {
    final e = last;
    return Column(
      children: [
        _kv('Phát hiện cua', e == null ? '—' : (e.status == BoxAiDetectionStatus.noCrab ? '—' : 'Có')),
        _kv('Mức vận động', _activityText(e)),
        _kv('Hành vi gần nhất', e?.typeLabel ?? '—'),
        _kv('Bất thường', '$warningCount'),
        if (e?.confidence != null && asCurrent) _kv('Confidence', '${e!.confidence}%'),
        _kv('Phân tích cuối', fmtDateTimeSec(e?.at)),
        _kv('Nguồn', cameraCode),
      ],
    );
  }
}

class LatestAIDetectionCard extends StatelessWidget {
  const LatestAIDetectionCard({
    super.key,
    required this.cameraCode,
    required this.loading,
    this.event,
    this.onDetail,
    this.onThumb,
  });

  final BoxAiDetection? event;
  final bool loading;
  final String cameraCode;
  final VoidCallback? onDetail;
  final VoidCallback? onThumb;

  @override
  Widget build(BuildContext context) {
    if (loading && event == null) {
      return OverviewCard(
        icon: Icons.radar_outlined,
        title: 'Phát hiện gần nhất',
        child: Container(height: 120, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12))),
      );
    }
    final e = event;
    if (e == null) {
      return OverviewCard(
        icon: Icons.radar_outlined,
        title: 'Phát hiện gần nhất',
        child: Text('Chưa có phát hiện AI cho hộp này.', style: bvText(color: DashboardColors.textMuted)),
      );
    }
    final ok = e.status == BoxAiDetectionStatus.normal || e.status == BoxAiDetectionStatus.recovered;
    return OverviewCard(
      icon: Icons.radar_outlined,
      title: 'Phát hiện gần nhất',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fmtDateTimeVn(e.at), style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded, size: 16, color: ok ? DashboardColors.brand : const Color(0xFFF5B700)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ok ? 'Không phát hiện bất thường' : e.typeLabel,
                  style: bvText(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(e.note ?? e.typeLabel, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 6),
          Text('Nguồn: $cameraCode', style: bvText(fontSize: 12, fontWeight: FontWeight.w700)),
          if (e.imageUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onThumb,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    e.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: DashboardColors.lightMint,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ),
            ),
          ],
          OverviewLinkButton(label: 'Xem chi tiết', onTap: onDetail),
        ],
      ),
    );
  }
}

class AIDetectionHistory extends StatelessWidget {
  const AIDetectionHistory({
    super.key,
    required this.events,
    required this.loading,
    required this.compact,
    this.error,
    this.onRetry,
    this.onOpenAll,
    this.onRow,
    this.onThumb,
  });

  final List<BoxAiDetection> events;
  final bool loading;
  final bool compact;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenAll;
  final ValueChanged<BoxAiDetection>? onRow;
  final ValueChanged<BoxAiDetection>? onThumb;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.history_rounded,
      title: 'Lịch sử phát hiện AI',
      trailing: OverviewLinkButton(label: 'Xem tất cả', onTap: onOpenAll),
      child: Column(
        children: [
          if (loading && events.isEmpty)
            Column(children: [for (var i = 0; i < 4; i++) const _SkelRow()])
          else if (error != null && events.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Không tải được lịch sử phát hiện.', style: bvText(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                MgmtOutlineButton(icon: Icons.refresh_rounded, label: 'Thử lại', onTap: onRetry),
              ],
            )
          else if (events.isEmpty)
            Text('Chưa có lịch sử phát hiện AI.', style: bvText(color: DashboardColors.textMuted))
          else if (compact)
            Column(
              children: [
                for (final e in events.take(8))
                  InkWell(
                    onTap: onRow == null ? null : () => onRow!(e),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          _thumb(e),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fmtDateTimeVn(e.at), style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                                Text(e.typeLabel, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          _resultBadge(e),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          else
            Column(
              children: [
                _header(),
                const SizedBox(height: 6),
                for (final e in events.take(8))
                  InkWell(
                    onTap: onRow == null ? null : () => onRow!(e),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(flex: 28, child: Text(fmtDateTimeVn(e.at), style: bvText(fontSize: 12, color: DashboardColors.textMuted))),
                          Expanded(flex: 36, child: Text(e.typeLabel, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600))),
                          Expanded(flex: 22, child: Align(alignment: Alignment.centerLeft, child: _resultBadge(e))),
                          SizedBox(width: 52, child: Align(alignment: Alignment.centerRight, child: _thumb(e))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _header() {
    Widget h(String t, int flex) => Expanded(
          flex: flex,
          child: Text(t, style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted)),
        );
    return Row(
      children: [
        h('THỜI GIAN', 28),
        h('PHÁT HIỆN', 36),
        h('KẾT QUẢ', 22),
        const SizedBox(width: 52, child: Align(alignment: Alignment.centerRight, child: Text('HÌNH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF66847C))))),
      ],
    );
  }

  Widget _thumb(BoxAiDetection e) {
    final url = e.imageUrl;
    return GestureDetector(
      onTap: url == null || onThumb == null ? null : () => onThumb!(e),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 32,
          child: url == null
              ? ColoredBox(color: DashboardColors.lightMint, child: Icon(Icons.image_outlined, size: 16, color: DashboardColors.textMuted))
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: DashboardColors.lightMint, child: Icon(Icons.image_outlined, size: 16, color: DashboardColors.textMuted)),
                ),
        ),
      ),
    );
  }
}

class AIDetectionDetailDrawer extends StatelessWidget {
  const AIDetectionDetailDrawer({
    super.key,
    required this.event,
    required this.boxCode,
    this.crabCode,
    this.onOpenImage,
    this.onOpenVideo,
    this.onClose,
  });

  final BoxAiDetection event;
  final String boxCode;
  final String? crabCode;
  final VoidCallback? onOpenImage;
  final VoidCallback? onOpenVideo;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_outlined, size: 18, color: DashboardColors.brand),
              const SizedBox(width: 8),
              Expanded(child: Text('Chi tiết phát hiện AI', style: bvText(fontSize: 16, fontWeight: FontWeight.w800))),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          _kv('Thời gian', fmtDateTimeSec(event.at)),
          if ((event.cameraCode ?? '').isNotEmpty) _kv('Camera', event.cameraCode!),
          _kv('BOX', boxCode),
          if ((crabCode ?? event.crabTag ?? '').isNotEmpty) _kv('Cua', crabCode ?? event.crabTag!),
          _kv('Loại phát hiện', event.typeLabel),
          _kv('Activity score', event.activityScore == null ? '—' : '${event.activityScore} / 100'),
          _kv('Confidence', event.confidence == null ? '—' : '${event.confidence}%'),
          _kv('Ghi chú', (event.note ?? '').trim().isEmpty ? '—' : event.note!),
          if (event.imageUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onOpenImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(event.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          ],
          if (event.videoUrl != null) ...[
            const SizedBox(height: 10),
            MgmtOutlineButton(icon: Icons.play_arrow_rounded, label: 'Xem video', onTap: onOpenVideo),
          ],
        ],
      ),
    );
  }
}

class _LastFrameNote extends StatelessWidget {
  const _LastFrameNote({required this.url, this.at});
  final String url;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ảnh cuối cùng nhận được', style: bvText(fontSize: 12, fontWeight: FontWeight.w800, color: DashboardColors.textMuted)),
        Text(fmtDateTimeSec(at), style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: DashboardColors.lightMint,
                alignment: Alignment.center,
                child: Text('Không tải được ảnh cuối.', style: bvText(color: DashboardColors.textMuted)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaleBanner extends StatelessWidget {
  const _PaleBanner({required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary))),
        ],
      ),
    );
  }
}

class _CameraTabSkeleton extends StatelessWidget {
  const _CameraTabSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box([double h = 160]) => Container(
          height: h,
          decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(14)),
        );
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 50, child: box(280)),
            const SizedBox(width: 12),
            Expanded(flex: 24, child: box(280)),
            const SizedBox(width: 12),
            Expanded(flex: 26, child: box(280)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 28, child: box(180)),
            const SizedBox(width: 12),
            Expanded(flex: 28, child: box(180)),
            const SizedBox(width: 12),
            Expanded(
              flex: 44,
              child: Column(children: [for (var i = 0; i < 4; i++) const _SkelRow()]),
            ),
          ],
        ),
      ],
    );
  }
}

class _SkelRow extends StatelessWidget {
  const _SkelRow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(height: 36, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(8))),
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 128, child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
        Expanded(child: Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700))),
      ],
    ),
  );
}

Widget _statusRow(String k, String v, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 128, child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(child: Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800, color: color))),
      ],
    ),
  );
}

Widget _resultBadge(BoxAiDetection e) {
  final (label, color) = switch (e.status) {
    BoxAiDetectionStatus.normal => ('Bình thường', DashboardColors.brand),
    BoxAiDetectionStatus.monitoring => ('Theo dõi', const Color(0xFFF5B700)),
    BoxAiDetectionStatus.warning => e.confidence == null ? ('Cảnh báo', const Color(0xFFEF4444)) : ('${e.confidence}%', const Color(0xFFF5B700)),
    BoxAiDetectionStatus.recovered => ('Đã khôi phục', const Color(0xFF2495E8)),
    BoxAiDetectionStatus.noCrab => ('Không phát hiện cua', const Color(0xFF94A3B8)),
  };
  return MgmtStatusBadge(label: label, color: color);
}

BoxAiDetection? _parseDetection(Map<String, dynamic> j) {
  final at = DateTime.tryParse((j['detectedAt'] ?? j['DetectedAt'] ?? '').toString());
  if (at == null) return null;
  final type = (j['detectionType'] ?? j['DetectionType'] ?? j['type'] ?? j['Type'] ?? '').toString();
  final t = type.toLowerCase();
  String? str(List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null && '$v'.isNotEmpty && '$v' != 'null') return '$v';
    }
    return null;
  }

  final img = str(['imagePath', 'ImagePath', 'imageUrl', 'ImageUrl']);
  final imgOk = img != null && (img.startsWith('http://') || img.startsWith('https://'));
  final video = str(['videoUrl', 'VideoUrl', 'clipUrl', 'ClipUrl']);
  final videoOk = video != null && (video.startsWith('http://') || video.startsWith('https://'));
  final confRaw = j['confidence'] ?? j['Confidence'];
  double? conf = confRaw is num ? confRaw.toDouble() : double.tryParse('$confRaw');
  if (conf != null && conf <= 1) conf = conf * 100;

  String? note;
  int? score;
  final rj = (j['resultJson'] ?? j['ResultJson'])?.toString();
  if (rj != null && rj.trim().isNotEmpty) {
    try {
      final map = jsonDecode(rj);
      if (map is Map) {
        note = map['note']?.toString() ?? map['Note']?.toString();
        final s = map['activityScore'] ?? map['ActivityScore'] ?? map['activity'];
        if (s is num) score = s.round();
        if (s is String) score = int.tryParse(s);
      }
    } catch (_) {
      final m = RegExp(r'"note"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(rj);
      note = m?.group(1)?.replaceAll(r'\"', '"');
    }
  }
  final scoreRaw = j['activityScore'] ?? j['ActivityScore'];
  if (score == null && scoreRaw is num) score = scoreRaw.round();

  final statusRaw = (j['status'] ?? j['Status'] ?? '').toString().toUpperCase();
  final status = _statusOf(t, statusRaw);
  return BoxAiDetection(
    id: (j['id'] ?? j['Id'] ?? '').toString(),
    at: at.isUtc ? at.toLocal() : at,
    type: t,
    typeLabel: _typeLabel(t, note),
    status: status,
    confidence: conf?.round(),
    activityScore: score,
    note: (note ?? '').trim().isEmpty ? null : note,
    imageUrl: imgOk ? img : null,
    videoUrl: videoOk ? video : null,
    cameraId: str(['deviceId', 'DeviceId', 'cameraId', 'CameraId']),
    cameraCode: str(['deviceCode', 'DeviceCode', 'cameraCode', 'CameraCode']),
    boxId: str(['boxId', 'BoxId']),
    crabId: str(['crabId', 'CrabId']),
    crabTag: str(['crabTag', 'CrabTag']),
  );
}

BoxAiDetectionStatus _statusOf(String type, String statusRaw) {
  switch (statusRaw) {
    case 'NORMAL':
      return BoxAiDetectionStatus.normal;
    case 'MONITORING':
      return BoxAiDetectionStatus.monitoring;
    case 'WARNING':
      return BoxAiDetectionStatus.warning;
    case 'RECOVERED':
      return BoxAiDetectionStatus.recovered;
    case 'NO_CRAB':
      return BoxAiDetectionStatus.noCrab;
  }
  if (type.contains('empty') || type.contains('no_crab') || type.contains('nocrab')) return BoxAiDetectionStatus.noCrab;
  if (type.contains('recover')) return BoxAiDetectionStatus.recovered;
  if (type.contains('abnormal') ||
      type.contains('anomal') ||
      type.contains('dead') ||
      type.contains('mortal') ||
      type.contains('quarantine') ||
      type.contains('water') ||
      type.contains('escape')) {
    return BoxAiDetectionStatus.warning;
  }
  if (type.contains('watch') || type.contains('monitor') || type.contains('low') || type.contains('giảm')) {
    return BoxAiDetectionStatus.monitoring;
  }
  return BoxAiDetectionStatus.normal;
}

String _typeLabel(String type, String? note) {
  if ((note ?? '').trim().isNotEmpty) return note!.trim();
  if (type.contains('molt')) return 'Phát hiện cua lột xác';
  if (type.contains('soft')) return 'Cua vỏ mềm sau lột';
  if (type.contains('empty')) return 'Không phát hiện cua';
  if (type.contains('quarantine')) return 'Hộp cách ly — nguy cơ bệnh';
  if (type.contains('water')) return 'Cảnh báo chất lượng nước';
  if (type.contains('abnormal') || type.contains('anomal')) return 'Cua di chuyển bất thường';
  if (type.contains('dead') || type.contains('mortal')) return 'Nghi cua chết';
  if (type.contains('feed')) return 'Phát hiện hoạt động ăn';
  if (type.contains('occupancy') || type.contains('normal') || type.contains('health')) return 'Cua hoạt động bình thường';
  if (type.contains('recover')) return 'Không phát hiện cua — đã khôi phục';
  if (type.contains('low') || type.contains('giảm')) return 'Vận động giảm';
  return type.isEmpty ? 'Phát hiện AI' : type;
}

String _activityText(BoxAiDetection? e) {
  final s = e?.activityScore;
  if (s == null) return '—';
  return '$s / 100 · ${_activityBand(s)}';
}

String _activityBand(int score, {int low = 30, int high = 70}) {
  if (score <= low) return 'Thấp';
  if (score <= high) return 'Bình thường';
  return 'Cao';
}

String fmtDateTimeSec(DateTime? dt) {
  if (dt == null) return '—';
  final l = dt.isUtc ? dt.toLocal() : dt;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}

String offlineFor(DateTime? at) {
  if (at == null) return '—';
  final local = at.isUtc ? at.toLocal() : at;
  final d = DateTime.now().difference(local);
  if (d.isNegative) return '—';
  if (d.inMinutes < 1) return '${d.inSeconds} giây';
  if (d.inHours < 1) return '${d.inMinutes} phút';
  if (d.inHours < 24) return '${d.inHours} giờ ${d.inMinutes % 60} phút';
  return '${d.inDays} ngày';
}

int? _offlineMinutes(DateTime? at) {
  if (at == null) return null;
  final local = at.isUtc ? at.toLocal() : at;
  final d = DateTime.now().difference(local);
  if (d.isNegative) return null;
  return d.inMinutes;
}

String offlineReason(CameraDevice cam) {
  final raw = (cam.message ?? '').trim();
  if (raw.isEmpty) return 'Chưa xác định';
  final s = raw.toLowerCase();
  if (s.contains('timeout')) return 'RTSP stream timeout';
  if (s.contains('preview') || s.contains('media gần nhất')) return raw;
  return raw;
}
