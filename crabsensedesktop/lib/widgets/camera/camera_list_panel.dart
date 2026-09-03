import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/camera_device.dart';
import '../../services/camera_device_service.dart';
import '../../theme/dashboard_theme.dart';
import 'camera_connect_test_dialog.dart';
import 'camera_form_dialog.dart';

class CameraListPanel extends StatefulWidget {
  const CameraListPanel({
    super.key,
    required this.service,
    required this.gatewayId,
    this.boxIds,
  });

  final CameraDeviceService service;

  /// ID các hộp trên dãy đang chọn; `null` = chưa chọn dãy.
  final List<String>? boxIds;
  final String gatewayId;

  @override
  State<CameraListPanel> createState() => _CameraListPanelState();
}

class _CameraListPanelState extends State<CameraListPanel> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.service.selectGateway(widget.gatewayId);
    if (widget.boxIds != null) {
      _loadCameras();
    }
  }

  @override
  void didUpdateWidget(CameraListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameBoxIds(oldWidget.boxIds, widget.boxIds) ||
        oldWidget.gatewayId != widget.gatewayId) {
      widget.service.selectGateway(widget.gatewayId);
      _loadCameras();
    }
  }

  bool _sameBoxIds(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  Future<void> _loadCameras() async {
    final ids = widget.boxIds;
    if (ids == null) return;
    await widget.service.loadCamerasForBoxes(
      ids,
      gatewayId: widget.gatewayId,
    );
  }

  String? get _defaultBoxIdForNew {
    final ids = widget.boxIds;
    if (ids == null || ids.isEmpty) return null;
    if (ids.length == 1) return ids.first;
    return null;
  }

  Future<void> _addCamera() async {
    final result = await showCameraFormDialog(
      context,
      widget.service,
      gatewayId: widget.gatewayId,
      defaultBoxId: _defaultBoxIdForNew,
    );
    if (result == true && mounted) {
      await _loadCameras();
    }
  }

  Future<void> _editCamera(CameraDevice camera) async {
    final result = await showCameraFormDialog(
      context,
      widget.service,
      gatewayId: widget.gatewayId,
      existing: camera,
    );
    if (result == true && mounted) {
      await _loadCameras();
    }
  }

  Future<void> _deleteCamera(CameraDevice camera) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa camera?'),
        content: Text('Bạn có chắc muốn xóa camera ${camera.cameraCode}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.risk,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await widget.service.deleteCamera(camera.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã xóa camera' : 'Không thể xóa camera'),
          ),
        );
        if (success) await _loadCameras();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;

    if (widget.boxIds == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_outlined, size: 48, color: DashboardColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Chọn khu và dãy để xem camera',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (widget.boxIds!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_outlined, size: 48, color: DashboardColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Chưa có hộp trên dãy này',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (svc.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (svc.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: DashboardColors.risk),
            const SizedBox(height: 12),
            Text(
              svc.error!,
              style: GoogleFonts.notoSans(color: DashboardColors.risk),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadCameras,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final cameras = svc.cameras;

    if (cameras.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 48, color: DashboardColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Chưa có camera nào',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm camera để giám sát hộp nuôi',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _addCamera,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm camera'),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.cyan,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Text(
                '${cameras.length} camera',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _addCamera,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm camera'),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.cyan,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: cameras.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final camera = cameras[i];
              final statusColor = camera.isOnline
                  ? DashboardColors.seaGreen
                  : DashboardColors.textMuted;
              final statusIcon = camera.isOnline
                  ? Icons.fiber_manual_record
                  : Icons.fiber_manual_record_outlined;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DashboardColors.darkNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: DashboardColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.videocam,
                        color: DashboardColors.cyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                camera.cameraCode,
                                style: GoogleFonts.notoSans(
                                  color: DashboardColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '— ${camera.name}',
                                style: GoogleFonts.notoSans(
                                  color: DashboardColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (camera.ipAddress != null)
                            Row(
                              children: [
                                Icon(Icons.wifi, size: 12, color: DashboardColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  camera.ipAddress!,
                                  style: GoogleFonts.robotoMono(
                                    color: DashboardColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                camera.isOnline ? 'Hoạt động' : 'Ngoại tuyến',
                                style: GoogleFonts.notoSans(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CameraConnectTestIconButton(
                      streamUrl: camera.streamUrl,
                      ipAddress: camera.ipAddress,
                      cameraLabel: '${camera.cameraCode} — ${camera.name}',
                    ),
                    IconButton(
                      onPressed: () => _editCamera(camera),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Chỉnh sửa',
                    ),
                    IconButton(
                      onPressed: () => _deleteCamera(camera),
                      icon: Icon(Icons.delete_outline, color: DashboardColors.risk),
                      tooltip: 'Xóa',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
