import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum FeedStockStatus {
  sufficient,
  normal,
  expiringSoon,
  useSoon,
  low;

  String get label => switch (this) {
        FeedStockStatus.sufficient => 'Đủ',
        FeedStockStatus.normal => 'Bình thường',
        FeedStockStatus.expiringSoon => 'Sắp hết hạn',
        FeedStockStatus.useSoon => 'Cần dùng sớm',
        FeedStockStatus.low => 'Sắp hết',
      };

  Color get color => switch (this) {
        FeedStockStatus.sufficient => DashboardColors.purple,
        FeedStockStatus.normal => DashboardColors.dead,
        FeedStockStatus.expiringSoon => DashboardColors.molting,
        FeedStockStatus.useSoon => DashboardColors.monitoring,
        FeedStockStatus.low => DashboardColors.risk,
      };
}

enum FcrRating {
  excellent,
  good,
  monitoring,
  poor;

  String get label => switch (this) {
        FcrRating.excellent => 'Rất tốt',
        FcrRating.good => 'Tốt',
        FcrRating.monitoring => 'Theo dõi',
        FcrRating.poor => 'Kém',
      };

  static FcrRating fromValue(double fcr) {
    if (fcr < 1.8) return FcrRating.excellent;
    if (fcr <= 2.2) return FcrRating.good;
    if (fcr <= 2.8) return FcrRating.monitoring;
    return FcrRating.poor;
  }
}

class FeedKpi {
  const FeedKpi({
    required this.totalStockKg,
    required this.stockTrendPercent,
    required this.consumedTodayKg,
    required this.weeklyAvgKg,
    required this.avgFcr,
    required this.fcrTarget,
    required this.feedingsPerDay,
    required this.feedingsCompleted,
    required this.lowStockCount,
    required this.monthlyConsumedKg,
  });

  final double totalStockKg;
  final double stockTrendPercent;
  final double consumedTodayKg;
  final double weeklyAvgKg;
  final double avgFcr;
  final double fcrTarget;
  final int feedingsPerDay;
  final int feedingsCompleted;
  final int lowStockCount;
  final double monthlyConsumedKg;
}

class FeedInventoryItem {
  const FeedInventoryItem({
    required this.id,
    required this.code,
    required this.name,
    required this.typeLabel,
    required this.stockKg,
    required this.unit,
    required this.expiryDate,
    required this.status,
  });

  final String id;
  final String code;
  final String name;
  final String typeLabel;
  final double stockKg;
  final String unit;
  final String expiryDate;
  final FeedStockStatus status;
}

class BatchFeedConsumption {
  const BatchFeedConsumption({
    required this.batchId,
    required this.crabCount,
    required this.totalFeedKg,
    required this.weightGainKg,
    required this.fcr,
  });

  final String batchId;
  final int crabCount;
  final double totalFeedKg;
  final double weightGainKg;
  final double fcr;

  FcrRating get rating => FcrRating.fromValue(fcr);
}

class DailyFeedConsumption {
  const DailyFeedConsumption({
    required this.date,
    required this.morningKg,
    required this.noonKg,
    required this.eveningKg,
    required this.leftoverKg,
    required this.eatRatePercent,
  });

  final String date;
  final double morningKg;
  final double noonKg;
  final double eveningKg;

  double get totalKg => morningKg + noonKg + eveningKg;
  final double leftoverKg;
  final double eatRatePercent;
}

class FeedingScheduleItem {
  FeedingScheduleItem({
    required this.id,
    required this.scheduledDate,
    required this.time,
    required this.area,
    required this.batchId,
    required this.feedName,
    required this.portionKg,
    required this.completed,
    this.completedAt,
    this.repeatRule = 'Hàng ngày',
  });

  final String id;
  final DateTime scheduledDate;
  final String time;
  final String area;
  final String batchId;
  final String feedName;
  final double portionKg;
  final String repeatRule;
  bool completed;
  String? completedAt;
}

/// Trạng thái một ngày trên lịch cho ăn (hiển thị dạng streak).
class FeedCalendarDayState {
  const FeedCalendarDayState({
    required this.date,
    required this.total,
    required this.completed,
    required this.isToday,
    required this.isSelected,
    required this.isMilestone,
    required this.streakSegment,
  });

  final DateTime date;
  final int total;
  final int completed;
  final bool isToday;
  final bool isSelected;
  final bool isMilestone;

  /// none | start | middle | end | single — nối các ngày hoàn thành liên tiếp.
  final String streakSegment;

  bool get hasSchedule => total > 0;
  bool get allComplete => total > 0 && completed >= total;
  bool get partial => completed > 0 && completed < total;
}

class FeedPortionSuggestion {
  const FeedPortionSuggestion({
    required this.batchId,
    required this.aliveCount,
    required this.avgWeightG,
    required this.totalBiomassKg,
    required this.dailyPercent,
    required this.dailyFeedKg,
  });

  final String batchId;
  final int aliveCount;
  final double avgWeightG;
  final double totalBiomassKg;
  final double dailyPercent;
  final double dailyFeedKg;
}
