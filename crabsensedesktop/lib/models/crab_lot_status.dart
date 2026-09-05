import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum CrabLotWorkflowStatus {
  pending,
  allocating,
  completed,
  cancelled,
}

enum CrabLotDateRange { all, last7, last30, thisMonth }

extension CrabLotWorkflowStatusX on CrabLotWorkflowStatus {
  String get api => switch (this) {
        CrabLotWorkflowStatus.pending => 'Pending',
        CrabLotWorkflowStatus.allocating => 'Allocating',
        CrabLotWorkflowStatus.completed => 'Completed',
        CrabLotWorkflowStatus.cancelled => 'Cancelled',
      };

  String get label => switch (this) {
        CrabLotWorkflowStatus.pending => 'Chờ xử lý',
        CrabLotWorkflowStatus.allocating => 'Đang phân hộp',
        CrabLotWorkflowStatus.completed => 'Đã hoàn tất',
        CrabLotWorkflowStatus.cancelled => 'Đã hủy',
      };

  Color get color => switch (this) {
        CrabLotWorkflowStatus.pending => DashboardColors.monitoring,
        CrabLotWorkflowStatus.allocating => DashboardColors.oceanBlue,
        CrabLotWorkflowStatus.completed => DashboardColors.healthy,
        CrabLotWorkflowStatus.cancelled => DashboardColors.risk,
      };

  static CrabLotWorkflowStatus resolve({
    required String raw,
    required int placed,
    required int quantity,
  }) {
    final key = raw.trim().toLowerCase().replaceAll(' ', '');
    if (key == 'cancelled' || key == 'canceled' || key == 'đãhủy' || key == 'dahuy') {
      return CrabLotWorkflowStatus.cancelled;
    }
    if (placed <= 0) return CrabLotWorkflowStatus.pending;
    if (placed < quantity) return CrabLotWorkflowStatus.allocating;
    return CrabLotWorkflowStatus.completed;
  }
}

extension CrabLotDateRangeX on CrabLotDateRange {
  String get label => switch (this) {
        CrabLotDateRange.all => 'Tất cả thời gian',
        CrabLotDateRange.last7 => '7 ngày qua',
        CrabLotDateRange.last30 => '30 ngày qua',
        CrabLotDateRange.thisMonth => 'Tháng này',
      };

  bool contains(DateTime date, DateTime now) {
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      CrabLotDateRange.all => true,
      CrabLotDateRange.last7 => !d.isBefore(today.subtract(const Duration(days: 6))),
      CrabLotDateRange.last30 => !d.isBefore(today.subtract(const Duration(days: 29))),
      CrabLotDateRange.thisMonth => d.year == today.year && d.month == today.month,
    };
  }
}
