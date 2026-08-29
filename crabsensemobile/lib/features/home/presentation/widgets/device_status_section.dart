import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

class DeviceStatusSection extends StatelessWidget {
  final DeviceSummary devices;
  final VoidCallback onViewDevicesPressed;

  const DeviceStatusSection({
    super.key,
    required this.devices,
    required this.onViewDevicesPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          icon: Icons.developer_board_rounded,
          title: 'TRẠNG THÁI THIẾT BỊ IOT',
          actionLabel: 'Xem thiết bị',
          onAction: onViewDevicesPressed,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDeviceTile(
              context,
              title: 'Cổng ESP32',
              status: '${devices.esp32Online}/${devices.esp32Total} Online',
              icon: Icons.router_rounded,
              accent: kHomeBlue,
              isGood: devices.esp32Online == devices.esp32Total,
            ),
            const SizedBox(width: 10),
            _buildDeviceTile(
              context,
              title: 'Camera AI',
              status: '${devices.cameraOnline}/${devices.cameraTotal} Online',
              icon: Icons.videocam_rounded,
              accent: kHomePurple,
              isGood: devices.cameraOnline == devices.cameraTotal,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildDeviceTile(
              context,
              title: 'Máy Bơm Nước',
              status: '${devices.pumpRunning}/${devices.pumpTotal} Running',
              icon: Icons.air_rounded,
              accent: kHomeCyan,
              isGood: true,
            ),
            const SizedBox(width: 10),
            _buildDeviceTile(
              context,
              title: 'Van Tự Động',
              status: '${devices.valveReady}/${devices.valveTotal} Ready',
              icon: Icons.tune_rounded,
              accent: kHomeOrange,
              isGood: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceTile(
    BuildContext context, {
    required String title,
    required String status,
    required IconData icon,
    required Color accent,
    required bool isGood,
  }) {
    final statusColor = isGood ? kHomeGreen : CrabSenseColors.warning;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kHomeSurface, kHomeBg, kHomeBg],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: kHomeBorderBlue.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: kHomeBlue.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kHomeTextMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.7),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
