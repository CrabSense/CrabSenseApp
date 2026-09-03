import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum DeviceStatus {
  online,
  maintenance,
  offline,
}

extension DeviceStatusX on DeviceStatus {
  String get label => switch (this) {
        DeviceStatus.online => 'Đang hoạt động',
        DeviceStatus.maintenance => 'Cần bảo trì',
        DeviceStatus.offline => 'Không kết nối',
      };

  Color get color => switch (this) {
        DeviceStatus.online => DashboardColors.cyan,
        DeviceStatus.maintenance => DashboardColors.molting,
        DeviceStatus.offline => DashboardColors.dead,
      };
}
