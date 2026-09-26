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
        AlertLevel.warning => 'Cảnh báo',
        AlertLevel.critical => 'Nghiêm trọng',
      };

  Color get color => switch (this) {
        AlertLevel.info => const Color(0xFF2495E8),
        AlertLevel.warning => const Color(0xFFF5B700),
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
        AlertWorkflowStatus.newAlert => 'Đang mở',
        AlertWorkflowStatus.notified => 'Đã xác nhận',
        AlertWorkflowStatus.inProgress => 'Đang xử lý',
        AlertWorkflowStatus.resolved => 'Đã xử lý',
        AlertWorkflowStatus.ignored => 'Đã hủy',
        AlertWorkflowStatus.falseAlarm => 'Đã tự khôi phục',
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

enum AlertKind {
  controller,
  camera,
  sensor,
  ras,
  waterAnalysis,
  crab,
  system;

  String get label => switch (this) {
        AlertKind.controller => 'Controller',
        AlertKind.camera => 'Camera',
        AlertKind.sensor => 'Cảm biến',
        AlertKind.ras => 'RAS',
        AlertKind.waterAnalysis => 'Phân tích nước',
        AlertKind.crab => 'Cua',
        AlertKind.system => 'Hệ thống',
      };
}

class AlertKpi {
  const AlertKpi({
    required this.active,
    required this.critical,
    required this.warning,
    required this.info,
    required this.resolvedToday,
    this.acknowledged = 0,
    this.avgResponseMinutes,
    this.activeDelta,
    this.criticalDelta,
    this.warningDelta,
    this.acknowledgedDelta,
    this.resolvedDelta,
  });

  final int active;
  final int critical;
  final int warning;
  final int info;
  final int resolvedToday;
  final int acknowledged;
  final int? avgResponseMinutes;
  final int? activeDelta;
  final int? criticalDelta;
  final int? warningDelta;
  final int? acknowledgedDelta;
  final int? resolvedDelta;
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
    this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.description = '',
    this.sourceLabel = 'System',
    this.kind = AlertKind.system,
    this.areaCode = '',
    this.areaName = '',
    this.deviceCode = '',
    this.deviceKindLabel = '',
    this.unit = '',
    this.measuredValue,
    this.thresholdMin,
    this.thresholdMax,
    this.occurrenceCount = 1,
    this.lastOccurredAt,
    this.affected = const [],
    this.analysisTestId,
    this.aiConfidence,
    this.incidentId,
    this.ruleKey,
    this.farmingAreaId,
    this.aiRecommendation,
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
  final DateTime? createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String description;
  final String sourceLabel;
  final AlertKind kind;
  final String areaCode;
  final String areaName;
  final String deviceCode;
  final String deviceKindLabel;
  final String unit;
  final double? measuredValue;
  final double? thresholdMin;
  final double? thresholdMax;
  final int occurrenceCount;
  final DateTime? lastOccurredAt;
  final List<String> affected;
  final String? analysisTestId;
  final double? aiConfidence;
  final String? incidentId;
  final String? ruleKey;
  final String? farmingAreaId;
  final String? aiRecommendation;

  bool get isOpen =>
      status == AlertWorkflowStatus.newAlert ||
      status == AlertWorkflowStatus.notified ||
      status == AlertWorkflowStatus.inProgress;

  String get displayCode {
    final raw = id.replaceAll('-', '');
    if (raw.length >= 4) return 'ALERT-${raw.substring(0, 4).toUpperCase()}';
    return id;
  }

  String get areaLabel {
    if (areaCode.isNotEmpty && areaName.isNotEmpty) return '$areaCode — $areaName';
    if (areaName.isNotEmpty) return areaName;
    if (location.isNotEmpty) return location;
    return 'Không xác định';
  }

  Duration? get openDuration {
    final start = createdAt;
    if (start == null) return null;
    final end = resolvedAt ?? DateTime.now();
    return end.difference(start);
  }

  double? get overThreshold {
    if (measuredValue == null || thresholdMax == null) return null;
    if (measuredValue! <= thresholdMax!) return null;
    return measuredValue! - thresholdMax!;
  }

  FarmAlert copyWith({
    AlertWorkflowStatus? status,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    List<String>? affected,
    int? occurrenceCount,
  }) {
    return FarmAlert(
      id: id,
      time: time,
      level: level,
      type: type,
      title: title,
      location: location,
      device: device,
      status: status ?? this.status,
      handler: handler,
      currentValue: currentValue,
      threshold: threshold,
      recommendations: recommendations,
      suggestedActions: suggestedActions,
      detectedAt: detectedAt,
      note: note,
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      description: description,
      sourceLabel: sourceLabel,
      kind: kind,
      areaCode: areaCode,
      areaName: areaName,
      deviceCode: deviceCode,
      deviceKindLabel: deviceKindLabel,
      unit: unit,
      measuredValue: measuredValue,
      thresholdMin: thresholdMin,
      thresholdMax: thresholdMax,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      lastOccurredAt: lastOccurredAt,
      affected: affected ?? this.affected,
      analysisTestId: analysisTestId,
      aiConfidence: aiConfidence,
      incidentId: incidentId,
      ruleKey: ruleKey,
      farmingAreaId: farmingAreaId,
      aiRecommendation: aiRecommendation,
    );
  }
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
