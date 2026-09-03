import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum BatchFeedingMethod { automatic, manual }

enum BatchFeedingLogStatus { completed, pending }

extension BatchFeedingMethodX on BatchFeedingMethod {
  String get label => switch (this) {
        BatchFeedingMethod.automatic => 'Tự động',
        BatchFeedingMethod.manual => 'Thủ công',
      };

  IconData get icon => switch (this) {
        BatchFeedingMethod.automatic => Icons.precision_manufacturing_outlined,
        BatchFeedingMethod.manual => Icons.person_outline,
      };
}

extension BatchFeedingLogStatusX on BatchFeedingLogStatus {
  String get label => switch (this) {
        BatchFeedingLogStatus.completed => 'Hoàn tất',
        BatchFeedingLogStatus.pending => 'Đang chờ',
      };

  Color get color => switch (this) {
        BatchFeedingLogStatus.completed => DashboardColors.seaGreen,
        BatchFeedingLogStatus.pending => DashboardColors.textMuted,
      };

  IconData get icon => switch (this) {
        BatchFeedingLogStatus.completed => Icons.check_circle,
        BatchFeedingLogStatus.pending => Icons.schedule,
      };
}

class BatchFeedingLogEntry {
  const BatchFeedingLogEntry({
    required this.at,
    required this.feedType,
    required this.weightKg,
    required this.method,
    required this.status,
    this.dayLabel,
  });

  final DateTime at;
  final String feedType;
  final double weightKg;
  final BatchFeedingMethod method;
  final BatchFeedingLogStatus status;
  final String? dayLabel;
}

class BatchFeedHistorySummary {
  const BatchFeedHistorySummary({
    required this.totalFeedKg,
    required this.totalTrendPercent,
    required this.todayKg,
    required this.avgFcr,
    required this.nextFeedingTime,
    required this.nextFeedingSubtitle,
  });

  final double totalFeedKg;
  final double totalTrendPercent;
  final double todayKg;
  final double avgFcr;
  final String nextFeedingTime;
  final String nextFeedingSubtitle;
}

class BatchFeedAiInsight {
  const BatchFeedAiInsight({
    required this.message,
    required this.doMgL,
    required this.temperatureC,
  });

  final String message;
  final double doMgL;
  final double temperatureC;
}
