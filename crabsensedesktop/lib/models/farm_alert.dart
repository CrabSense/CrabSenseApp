import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum AlertLevel {
  info,
  warning,
  critical;

  String get label => switch (this) {
        AlertLevel.info => 'INFO',
        AlertLevel.warning => 'WARNING',
        AlertLevel.critical => 'CRITICAL',
      };

  String get labelVi => switch (this) {
        AlertLevel.info => 'Thông tin',
        AlertLevel.warning => 'Cần theo dõi',
        AlertLevel.critical => 'Nguy hiểm',
      };

  Color get color => switch (this) {
        AlertLevel.info => DashboardColors.blue,
        AlertLevel.warning => DashboardColors.monitoring,
        AlertLevel.critical => DashboardColors.risk,
      };
}

enum AlertWorkflowStatus {
  newAlert,
  notified,
  inProgress,
  resolved,
  ignored,
  falseAlarm;

  String get label => switch (this) {
        AlertWorkflowStatus.newAlert => 'Chưa xử lý',
        AlertWorkflowStatus.notified => 'Đã gửi thông báo',
        AlertWorkflowStatus.inProgress => 'Đang xử lý',
        AlertWorkflowStatus.resolved => 'Đã xử lý',
        AlertWorkflowStatus.ignored => 'Bỏ qua',
        AlertWorkflowStatus.falseAlarm => 'Báo sai',
      };

  Color get dotColor => switch (this) {
        AlertWorkflowStatus.newAlert => DashboardColors.risk,
        AlertWorkflowStatus.notified => DashboardColors.blue,
        AlertWorkflowStatus.inProgress => DashboardColors.monitoring,
        AlertWorkflowStatus.resolved => DashboardColors.healthy,
        AlertWorkflowStatus.ignored => DashboardColors.dead,
        AlertWorkflowStatus.falseAlarm => DashboardColors.dead,
      };
}

enum AlertTypeCategory {
  lowDo,
  phAbnormal,
  temperature,
  pumpError,
  drumStuck,
  powerLoss,
  crabDeath,
  noActivity,
  notEating,
  lowHealthScore,
  feedingDone,
  salinity,
  other;

  String get label => switch (this) {
        AlertTypeCategory.lowDo => 'DO thấp',
        AlertTypeCategory.phAbnormal => 'pH bất thường',
        AlertTypeCategory.temperature => 'Nhiệt độ bất thường',
        AlertTypeCategory.pumpError => 'Máy bơm lỗi',
        AlertTypeCategory.drumStuck => 'Drum Filter kẹt',
        AlertTypeCategory.powerLoss => 'Mất điện',
        AlertTypeCategory.crabDeath => 'Cua chết',
        AlertTypeCategory.noActivity => 'Không phát hiện hoạt động',
        AlertTypeCategory.notEating => 'Cua bỏ ăn',
        AlertTypeCategory.lowHealthScore => 'Health Score thấp',
        AlertTypeCategory.feedingDone => 'Cho ăn xong',
        AlertTypeCategory.salinity => 'Độ mặn dao động',
        AlertTypeCategory.other => 'Khác',
      };
}

class AlertKpi {
  const AlertKpi({
    required this.active,
    required this.critical,
    required this.warning,
    required this.info,
    required this.resolvedToday,
    required this.avgResponseMinutes,
  });

  final int active;
  final int critical;
  final int warning;
  final int info;
  final int resolvedToday;
  final int avgResponseMinutes;
}

class FarmAlert {
  const FarmAlert({
    required this.id,
    required this.time,
    required this.level,
    required this.type,
    required this.title,
    required this.location,
    required this.device,
    required this.status,
    required this.handler,
    required this.currentValue,
    required this.threshold,
    required this.recommendations,
    required this.suggestedActions,
    this.detectedAt = '',
    this.note = '',
  });

  final String id;
  final String time;
  final AlertLevel level;
  final AlertTypeCategory type;
  final String title;
  final String location;
  final String device;
  final AlertWorkflowStatus status;
  final String handler;
  final String currentValue;
  final String threshold;
  final List<String> recommendations;
  final List<String> suggestedActions;
  final String detectedAt;
  final String note;

  bool get isOpen =>
      status == AlertWorkflowStatus.newAlert ||
      status == AlertWorkflowStatus.notified ||
      status == AlertWorkflowStatus.inProgress;
}

class AlertHistoryRow {
  const AlertHistoryRow({
    required this.date,
    required this.typeLabel,
    required this.level,
    required this.location,
    required this.responseTime,
    required this.result,
  });

  final String date;
  final String typeLabel;
  final AlertLevel level;
  final String location;
  final String responseTime;
  final String result;
}

class AlertFrequencyPoint {
  const AlertFrequencyPoint({required this.hour, required this.count});

  final int hour;
  final int count;
}

class NotificationChannelConfig {
  const NotificationChannelConfig({
    required this.level,
    required this.channels,
  });

  final AlertLevel level;
  final List<String> channels;
}
