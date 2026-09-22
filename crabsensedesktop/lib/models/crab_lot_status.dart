import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

const kLotCyan = Color(0xFF06B6D4);
const kLotBlue = Color(0xFF2495E8);
const kLotCoral = Color(0xFFE07A5F);
const kLotTeal = Color(0xFF0D9488);
const kLotAmber = Color(0xFFF5B700);
const kLotSlate = Color(0xFF94A3B8);

enum CrabLotWorkflowStatus {
  pending,
  inspecting,
  allocating,
  completed,
  cancelled,
}

enum CrabLotDateRange { all, last7, last30, thisMonth }

enum CrabLotSort { newest, oldest, qtyHigh, qtyLow, progress }

enum CrabLotProgressBand { all, full, mid, low, none }

extension CrabLotWorkflowStatusX on CrabLotWorkflowStatus {
  String get api => switch (this) {
        CrabLotWorkflowStatus.pending => 'Pending',
        CrabLotWorkflowStatus.inspecting => 'Inspecting',
        CrabLotWorkflowStatus.allocating => 'Allocating',
        CrabLotWorkflowStatus.completed => 'Completed',
        CrabLotWorkflowStatus.cancelled => 'Cancelled',
      };

  String get label => switch (this) {
        CrabLotWorkflowStatus.pending => 'Chờ xử lý',
        CrabLotWorkflowStatus.inspecting => 'Đang kiểm tra',
        CrabLotWorkflowStatus.allocating => 'Đang phân hộp',
        CrabLotWorkflowStatus.completed => 'Đã hoàn tất',
        CrabLotWorkflowStatus.cancelled => 'Đã hủy',
      };

  Color get color => switch (this) {
        CrabLotWorkflowStatus.pending => kLotAmber,
        CrabLotWorkflowStatus.inspecting => kLotCyan,
        CrabLotWorkflowStatus.allocating => kLotBlue,
        CrabLotWorkflowStatus.completed => DashboardColors.brandGreen,
        CrabLotWorkflowStatus.cancelled => DashboardColors.risk,
      };

  bool get canAllocate =>
      this == CrabLotWorkflowStatus.pending ||
      this == CrabLotWorkflowStatus.inspecting ||
      this == CrabLotWorkflowStatus.allocating;

  bool get canCancel =>
      this == CrabLotWorkflowStatus.pending ||
      this == CrabLotWorkflowStatus.inspecting ||
      this == CrabLotWorkflowStatus.allocating;

  static CrabLotWorkflowStatus resolve({
    required String raw,
    required int placed,
    required int quantity,
  }) {
    final key = raw.trim().toLowerCase().replaceAll(' ', '');
    if (key == 'cancelled' ||
        key == 'canceled' ||
        key == 'đãhủy' ||
        key == 'dahuy') {
      return CrabLotWorkflowStatus.cancelled;
    }
    if (key == 'inspecting' ||
        key == 'checking' ||
        key == 'đangkiểmtra' ||
        key == 'dangkiemtra') {
      return CrabLotWorkflowStatus.inspecting;
    }
    if (placed <= 0) return CrabLotWorkflowStatus.pending;
    if (placed < quantity) return CrabLotWorkflowStatus.allocating;
    return CrabLotWorkflowStatus.completed;
  }
}

extension CrabLotSortX on CrabLotSort {
  String get label => switch (this) {
        CrabLotSort.newest => 'Ngày nhập gần nhất',
        CrabLotSort.oldest => 'Ngày nhập cũ nhất',
        CrabLotSort.qtyHigh => 'Số lượng cao → thấp',
        CrabLotSort.qtyLow => 'Số lượng thấp → cao',
        CrabLotSort.progress => 'Tỷ lệ phân hộp',
      };
}

extension CrabLotProgressBandX on CrabLotProgressBand {
  String get label => switch (this) {
        CrabLotProgressBand.all => 'Tất cả',
        CrabLotProgressBand.full => '100%',
        CrabLotProgressBand.mid => '50–99%',
        CrabLotProgressBand.low => '1–49%',
        CrabLotProgressBand.none => '0%',
      };

  bool matches(int percent) => switch (this) {
        CrabLotProgressBand.all => true,
        CrabLotProgressBand.full => percent >= 100,
        CrabLotProgressBand.mid => percent >= 50 && percent < 100,
        CrabLotProgressBand.low => percent >= 1 && percent < 50,
        CrabLotProgressBand.none => percent <= 0,
      };
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
      CrabLotDateRange.last7 =>
        !d.isBefore(today.subtract(const Duration(days: 6))),
      CrabLotDateRange.last30 =>
        !d.isBefore(today.subtract(const Duration(days: 29))),
      CrabLotDateRange.thisMonth =>
        d.year == today.year && d.month == today.month,
    };
  }
}
