import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

/// Trạng thái lứa nuôi mock (CrabBatch / Lứa nuôi).
enum BatchStatus {
  raising,
  readyHarvest,
  harvested,
  incident,
  ended,
}

extension BatchStatusX on BatchStatus {
  String get label => switch (this) {
        BatchStatus.raising => 'Đang nuôi',
        BatchStatus.readyHarvest => 'Sắp thu hoạch',
        BatchStatus.harvested => 'Đã thu hoạch',
        BatchStatus.incident => 'Sự cố',
        BatchStatus.ended => 'Đã kết thúc',
      };

  Color get color => switch (this) {
        BatchStatus.raising => DashboardColors.seaGreen,
        BatchStatus.readyHarvest => DashboardColors.oceanBlue,
        BatchStatus.harvested => DashboardColors.cyan,
        BatchStatus.incident => DashboardColors.risk,
        BatchStatus.ended => DashboardColors.textMuted,
      };
}

/// Bộ lọc trạng thái đợt nuôi production (API).
enum BatchStatusFilter { all, active, harvested, failed }

extension BatchStatusFilterX on BatchStatusFilter {
  String get apiValue => switch (this) {
        BatchStatusFilter.all => '',
        BatchStatusFilter.active => 'active',
        BatchStatusFilter.harvested => 'harvested',
        BatchStatusFilter.failed => 'failed',
      };

  String get label => switch (this) {
        BatchStatusFilter.all => 'Tất cả',
        BatchStatusFilter.active => 'Đang nuôi',
        BatchStatusFilter.harvested => 'Đã thu hoạch',
        BatchStatusFilter.failed => 'Thất bại',
      };
}

class FarmingBatchStatusUi {
  static String label(String status) => switch (status) {
        'harvested' => 'Đã thu hoạch',
        'failed' => 'Thất bại',
        _ => 'Đang nuôi',
      };

  static Color color(String status) => switch (status) {
        'harvested' => DashboardColors.oceanBlue,
        'failed' => DashboardColors.risk,
        _ => DashboardColors.seaGreen,
      };

  static double survivalRate(int current, int initial) {
    if (initial <= 0) return 0;
    return (current / initial * 100).clamp(0, 100);
  }
}
