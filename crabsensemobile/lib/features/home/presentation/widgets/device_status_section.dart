import 'package:flutter/material.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

class DeviceStatusSection extends StatelessWidget {
  const DeviceStatusSection({super.key, required this.devices,
    required this.onViewDevicesPressed});
  final DeviceSummary devices;
  final VoidCallback onViewDevicesPressed;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      HomeSectionHeader(icon: Icons.developer_board_rounded,
        title: 'THIẾT BỊ CẤP KHU', actionLabel: 'Xem thiết bị',
        onAction: onViewDevicesPressed),
      const SizedBox(height: 12),
      Card(child: ListTile(
        leading: const Icon(Icons.router_rounded),
        title: Text(devices.totalCount == 0 ? 'Chưa có thiết bị đăng ký' :
          devices.percentage == null ? 'Chưa xác minh kết nối' :
          '${devices.onlineCount}/${devices.totalCount} thiết bị online'),
        subtitle: const Text('Không suy ra trạng thái bơm, van hoặc camera từ kết nối controller.'),
      )),
    ],
  );
}
