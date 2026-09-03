import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum RowStatusFilter { all, active, maintenance, disabled }

extension RowStatusFilterX on RowStatusFilter {
  String get apiValue => switch (this) {
        RowStatusFilter.all => '',
        RowStatusFilter.active => 'active',
        RowStatusFilter.maintenance => 'maintenance',
        RowStatusFilter.disabled => 'disabled',
      };

  String get label => switch (this) {
        RowStatusFilter.all => 'Tất cả trạng thái',
        RowStatusFilter.active => 'Hoạt động',
        RowStatusFilter.maintenance => 'Bảo trì',
        RowStatusFilter.disabled => 'Ngưng dùng',
      };
}

class RowStatusUi {
  static String label(String status) => switch (status) {
        'maintenance' => 'BẢO TRÌ',
        'disabled' => 'NGƯNG DÙNG',
        _ => 'HOẠT ĐỘNG',
      };

  static Color color(String status) => switch (status) {
        'maintenance' => DashboardColors.oceanBlue,
        'disabled' => DashboardColors.textMuted,
        _ => DashboardColors.seaGreen,
      };
}
