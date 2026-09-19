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
        BoxStatus.watch => 'Có vấn đề',
        BoxStatus.molting => 'Lột xác',
        BoxStatus.alert => 'Có vấn đề',
        BoxStatus.deceased => 'Hộp trống',
        BoxStatus.empty => 'Hộp trống',
      };

  String get shortLabel => switch (this) {
        BoxStatus.normal => 'BÌNH THƯỜNG',
        BoxStatus.watch => 'CÓ VẤN ĐỀ',
        BoxStatus.molting => 'LỘT XÁC',
        BoxStatus.alert => 'CÓ VẤN ĐỀ',
        BoxStatus.deceased => 'TRỐNG',
        BoxStatus.empty => 'TRỐNG',
      };

  /// 4 trạng thái bản đồ: xanh bình thường, vàng có vấn đề, tím lột, xám trống.
  Color get color => switch (this) {
        BoxStatus.normal => DashboardColors.healthy,
        BoxStatus.watch => DashboardColors.monitoring,
        BoxStatus.molting => DashboardColors.moltPurple,
        BoxStatus.alert => DashboardColors.monitoring,
        BoxStatus.deceased => const Color(0xFF64748B),
        BoxStatus.empty => const Color(0xFF64748B),
      };

  String get emoji => switch (this) {
        BoxStatus.normal => '🟢',
        BoxStatus.watch => '🟡',
        BoxStatus.molting => '🟣',
        BoxStatus.alert => '🟡',
        BoxStatus.deceased => '⚪',
        BoxStatus.empty => '⚪',
      };

  String get iconAsset => switch (this) {
        BoxStatus.empty || BoxStatus.deceased =>
          'assets/icon_tab/icon-box-empty.png',
        BoxStatus.alert || BoxStatus.watch =>
          'assets/icon_tab/icon-carb-warning.png',
        BoxStatus.molting => 'assets/icon_tab/icon-crab-lt.png',
        BoxStatus.normal => 'assets/icon_tab/iocn-crab-normal.png',
      };
}
