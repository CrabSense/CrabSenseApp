import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum AreaStatusFilter { all, active, maintenance, disabled }

extension AreaStatusFilterX on AreaStatusFilter {
  String get apiValue => switch (this) {
        AreaStatusFilter.all => '',
        AreaStatusFilter.active => 'active',
        AreaStatusFilter.maintenance => 'maintenance',
        AreaStatusFilter.disabled => 'disabled',
      };

  String get label => switch (this) {
        AreaStatusFilter.all => 'Tất cả',
        AreaStatusFilter.active => 'Hoạt động',
        AreaStatusFilter.maintenance => 'Bảo trì',
        AreaStatusFilter.disabled => 'Ngưng sử dụng',
      };
}

class AreaStatusUi {
  static String label(String status) => switch (status) {
        'maintenance' => 'Bảo trì',
        'disabled' => 'Ngưng sử dụng',
        _ => 'Hoạt động',
      };

  static Color color(String status) => switch (status) {
        'maintenance' => DashboardColors.oceanBlue,
        'disabled' => DashboardColors.textMuted,
        _ => DashboardColors.seaGreen,
      };

  static IconData icon(String status) => switch (status) {
        'maintenance' => Icons.build_circle_outlined,
        'disabled' => Icons.block,
        _ => Icons.check_circle_outline,
      };
}
