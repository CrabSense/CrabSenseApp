import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/camera_device.dart';
import '../../services/camera_device_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

/// Camera theo hộp (API `GET /api/boxes/{boxId}/camera`).
class CrabBoxCamerasTab extends StatefulWidget {
  const CrabBoxCamerasTab({
    super.key,
    required this.boxId,
    required this.cameraService,
    this.gatewayId,
  });

  final String boxId;
  final CameraDeviceService cameraService;
  final String? gatewayId;

  @override
  State<CrabBoxCamerasTab> createState() => _CrabBoxCamerasTabState();
}

class _CrabBoxCamerasTabState extends State<CrabBoxCamerasTab> {
  @override
  void initState() {
    super.initState();
    widget.cameraService.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    widget.cameraService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await widget.cameraService.loadCamerasByBox(widget.boxId);
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.cameraService;
    final cameras = svc.cameras.where((c) => c.boxId == widget.boxId).toList();

    if (svc.loading && cameras.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (svc.error != null && cameras.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(svc.error!, style: GoogleFonts.notoSans(color: DashboardColors.risk)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (cameras.isEmpty) {
      return Center(
        child: Text(
          'Chưa có camera gắn hộp này',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: cameras.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CameraTile(camera: cameras[i]),
    );
  }
}

class _CameraTile extends StatelessWidget {
  const _CameraTile({required this.camera});

  final CameraDevice camera;

  @override
  Widget build(BuildContext context) {
    final online = camera.status == 'online';
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 90,
            decoration: BoxDecoration(
              color: DashboardColors.darkNavy,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Icon(
              Icons.videocam_outlined,
              color: online ? DashboardColors.cyan : DashboardColors.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  camera.name,
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                Text(
                  camera.cameraCode,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.cyan,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  online ? 'Online' : 'Offline',
                  style: GoogleFonts.notoSans(
                    color: online ? DashboardColors.healthy : DashboardColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (camera.streamUrl != null && camera.streamUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      camera.streamUrl!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
