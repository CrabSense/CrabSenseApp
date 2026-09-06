import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum BoxStatus {
  normal,
  watch,
  molting,
  alert,
  deceased,
  empty,
}

extension BoxStatusX on BoxStatus {
  String get label => switch (this) {
        BoxStatus.normal => 'Bình thường',
        BoxStatus.watch => 'Cần theo dõi',
        BoxStatus.molting => 'Lột xác',
        BoxStatus.alert => 'Cảnh báo',
        BoxStatus.deceased => 'Sự cố',
        BoxStatus.empty => 'Hộp trống',
      };

  String get shortLabel => switch (this) {
        BoxStatus.normal => 'BÌNH THƯỜNG',
        BoxStatus.watch => 'THEO DÕI',
        BoxStatus.molting => 'LỘT XÁC',
        BoxStatus.alert => 'CẢNH BÁO',
        BoxStatus.deceased => 'SỰ CỐ',
        BoxStatus.empty => 'TRỐNG',
      };

  Color get color => switch (this) {
        BoxStatus.normal => DashboardColors.healthy,
        BoxStatus.watch => DashboardColors.monitoring,
        BoxStatus.molting => const Color(0xFFA78BFA),
        BoxStatus.alert => const Color(0xFFFF6B8A),
        BoxStatus.deceased => const Color(0xFF94A3B8),
        BoxStatus.empty => const Color(0xFF64748B),
      };

  String get emoji => switch (this) {
        BoxStatus.normal => '🟢',
        BoxStatus.watch => '🟡',
        BoxStatus.molting => '🟠',
        BoxStatus.alert => '🔴',
        BoxStatus.deceased => '⚫',
        BoxStatus.empty => '⚪',
      };
}
