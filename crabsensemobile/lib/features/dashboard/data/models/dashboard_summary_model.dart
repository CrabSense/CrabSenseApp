// ignore_for_file: lines_longer_than_80_chars

import '../../domain/entities/dashboard_summary.dart';

/// JSON-serializable DTO for [AlertSummary].
class AlertSummaryModel {
  const AlertSummaryModel({
    required this.totalActive,
    required this.criticalCount,
    required this.warningCount,
    required this.infoCount,
  });

  factory AlertSummaryModel.fromJson(Map<String, dynamic> json) => AlertSummaryModel(
    totalActive: (json['totalActive'] as num?)?.toInt() ?? 0,
    criticalCount: (json['criticalCount'] as num?)?.toInt() ?? 0,
    warningCount: (json['warningCount'] as num?)?.toInt() ?? 0,
    infoCount: (json['infoCount'] as num?)?.toInt() ?? 0,
  );

  /// Creates an empty [AlertSummaryModel] used when no cached data is
  /// available.
  const AlertSummaryModel.empty()
    : totalActive = 0,
      criticalCount = 0,
      warningCount = 0,
      infoCount = 0;

  final int totalActive;
  final int criticalCount;
  final int warningCount;
  final int infoCount;

  Map<String, dynamic> toJson() => {
    'totalActive': totalActive,
    'criticalCount': criticalCount,
    'warningCount': warningCount,
    'infoCount': infoCount,
  };

  AlertSummary toDomain() => AlertSummary(
    totalActive: totalActive,
    criticalCount: criticalCount,
    warningCount: warningCount,
    infoCount: infoCount,
  );
}

// ---------------------------------------------------------------------------

/// JSON-serializable DTO for [VideoTask].
class VideoTaskModel {
  const VideoTaskModel({
    required this.boxId,
    required this.boxIdentifier,
    required this.farmId,
    required this.farmName,
    required this.scheduledAt,
    required this.isOverdue,
    this.pondId,
    this.pondName,
    this.lastCapturedAt,
  });

  factory VideoTaskModel.fromJson(Map<String, dynamic> json) => VideoTaskModel(
    boxId: json['boxId'] as String,
    boxIdentifier: json['boxIdentifier'] as String,
    farmId: json['farmId'] as String,
    farmName: json['farmName'] as String,
    pondId: json['pondId'] as String?,
    pondName: json['pondName'] as String?,
    scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    isOverdue: json['isOverdue'] as bool? ?? false,
    lastCapturedAt: json['lastCapturedAt'] != null
        ? DateTime.parse(json['lastCapturedAt'] as String)
        : null,
  );

  final String boxId;
  final String boxIdentifier;
  final String farmId;
  final String farmName;
  final String? pondId;
  final String? pondName;
  final DateTime scheduledAt;
  final bool isOverdue;
  final DateTime? lastCapturedAt;

  Map<String, dynamic> toJson() => {
    'boxId': boxId,
    'boxIdentifier': boxIdentifier,
    'farmId': farmId,
    'farmName': farmName,
    'pondId': pondId,
    'pondName': pondName,
    'scheduledAt': scheduledAt.toIso8601String(),
    'isOverdue': isOverdue,
    'lastCapturedAt': lastCapturedAt?.toIso8601String(),
  };

  VideoTask toDomain() => VideoTask(
    boxId: boxId,
    boxIdentifier: boxIdentifier,
    farmId: farmId,
    farmName: farmName,
    pondId: pondId,
    pondName: pondName,
    scheduledAt: scheduledAt,
    isOverdue: isOverdue,
    lastCapturedAt: lastCapturedAt,
  );
}

// ---------------------------------------------------------------------------

/// JSON-serializable DTO for [FarmWaterQualityStatus].
class FarmWaterQualityStatusModel {
  const FarmWaterQualityStatusModel({
    required this.farmId,
    required this.farmName,
    required this.isOnline,
    required this.hasAlert,
    this.temperature,
    this.ph,
    this.dissolvedOxygen,
    this.salinity,
    this.alertCount,
    this.lastUpdatedAt,
  });

  factory FarmWaterQualityStatusModel.fromJson(Map<String, dynamic> json) =>
      FarmWaterQualityStatusModel(
        farmId: json['farmId'] as String,
        farmName: json['farmName'] as String,
        isOnline: json['isOnline'] as bool? ?? false,
        hasAlert: json['hasAlert'] as bool? ?? false,
        temperature: (json['temperature'] as num?)?.toDouble(),
        ph: (json['ph'] as num?)?.toDouble(),
        dissolvedOxygen: (json['dissolvedOxygen'] as num?)?.toDouble(),
        salinity: (json['salinity'] as num?)?.toDouble(),
        alertCount: (json['alertCount'] as num?)?.toInt(),
        lastUpdatedAt: json['lastUpdatedAt'] != null
            ? DateTime.parse(json['lastUpdatedAt'] as String)
            : null,
      );

  final String farmId;
  final String farmName;
  final bool isOnline;
  final bool hasAlert;
  final double? temperature;
  final double? ph;
  final double? dissolvedOxygen;
  final double? salinity;
  final int? alertCount;
  final DateTime? lastUpdatedAt;

  Map<String, dynamic> toJson() => {
    'farmId': farmId,
    'farmName': farmName,
    'isOnline': isOnline,
    'hasAlert': hasAlert,
    'temperature': temperature,
    'ph': ph,
    'dissolvedOxygen': dissolvedOxygen,
    'salinity': salinity,
    'alertCount': alertCount,
    'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
  };

  FarmWaterQualityStatus toDomain() => FarmWaterQualityStatus(
    farmId: farmId,
    farmName: farmName,
    isOnline: isOnline,
    hasAlert: hasAlert,
    temperature: temperature,
    ph: ph,
    dissolvedOxygen: dissolvedOxygen,
    salinity: salinity,
    alertCount: alertCount,
    lastUpdatedAt: lastUpdatedAt,
  );
}

// ---------------------------------------------------------------------------

/// JSON-serializable DTO for [WeeklyHarvestSummary].
class WeeklyHarvestSummaryModel {
  const WeeklyHarvestSummaryModel({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.totalWeightKg,
    required this.totalCrabCount,
    required this.harvestCount,
    required this.boxesHarvested,
  });

  factory WeeklyHarvestSummaryModel.fromJson(Map<String, dynamic> json) =>
      WeeklyHarvestSummaryModel(
        weekStartDate: DateTime.parse(json['weekStartDate'] as String),
        weekEndDate: DateTime.parse(json['weekEndDate'] as String),
        totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble() ?? 0.0,
        totalCrabCount: (json['totalCrabCount'] as num?)?.toInt() ?? 0,
        harvestCount: (json['harvestCount'] as num?)?.toInt() ?? 0,
        boxesHarvested: (json['boxesHarvested'] as num?)?.toInt() ?? 0,
      );

  /// Creates a [WeeklyHarvestSummaryModel] with zeroed totals for the
  /// current ISO week when no cached data is available.
  factory WeeklyHarvestSummaryModel.empty() {
    final now = DateTime.now().toUtc();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return WeeklyHarvestSummaryModel(
      weekStartDate: weekStart,
      weekEndDate: weekEnd,
      totalWeightKg: 0,
      totalCrabCount: 0,
      harvestCount: 0,
      boxesHarvested: 0,
    );
  }

  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final double totalWeightKg;
  final int totalCrabCount;
  final int harvestCount;
  final int boxesHarvested;

  Map<String, dynamic> toJson() => {
    'weekStartDate': weekStartDate.toIso8601String(),
    'weekEndDate': weekEndDate.toIso8601String(),
    'totalWeightKg': totalWeightKg,
    'totalCrabCount': totalCrabCount,
    'harvestCount': harvestCount,
    'boxesHarvested': boxesHarvested,
  };

  WeeklyHarvestSummary toDomain() => WeeklyHarvestSummary(
    weekStartDate: weekStartDate,
    weekEndDate: weekEndDate,
    totalWeightKg: totalWeightKg,
    totalCrabCount: totalCrabCount,
    harvestCount: harvestCount,
    boxesHarvested: boxesHarvested,
  );
}

// ---------------------------------------------------------------------------

/// JSON-serializable DTO for [QuickMetrics].
class QuickMetricsModel {
  const QuickMetricsModel({
    required this.activeBoxCount,
    required this.videosDueToday,
    required this.videosCompletedToday,
    required this.activeFarmCount,
  });

  factory QuickMetricsModel.fromJson(Map<String, dynamic> json) => QuickMetricsModel(
    activeBoxCount: (json['activeBoxCount'] as num?)?.toInt() ?? 0,
    videosDueToday: (json['videosDueToday'] as num?)?.toInt() ?? 0,
    videosCompletedToday: (json['videosCompletedToday'] as num?)?.toInt() ?? 0,
    activeFarmCount: (json['activeFarmCount'] as num?)?.toInt() ?? 0,
  );

  /// Creates an empty [QuickMetricsModel] for use when no cached data is
  /// available.
  const QuickMetricsModel.empty()
    : activeBoxCount = 0,
      videosDueToday = 0,
      videosCompletedToday = 0,
      activeFarmCount = 0;

  final int activeBoxCount;
  final int videosDueToday;
  final int videosCompletedToday;
  final int activeFarmCount;

  Map<String, dynamic> toJson() => {
    'activeBoxCount': activeBoxCount,
    'videosDueToday': videosDueToday,
    'videosCompletedToday': videosCompletedToday,
    'activeFarmCount': activeFarmCount,
  };

  QuickMetrics toDomain() => QuickMetrics(
    activeBoxCount: activeBoxCount,
    videosDueToday: videosDueToday,
    videosCompletedToday: videosCompletedToday,
    activeFarmCount: activeFarmCount,
  );
}

// ---------------------------------------------------------------------------

/// Aggregate JSON-serializable DTO for [DashboardSummary].
///
/// Maps directly to the `/dashboard/summary` API response structure and
/// to the local cache JSON blob. All nested sub-entities have their own
/// model classes with `fromJson` / `toJson` / `toDomain` helpers.
///
/// Requirements: 2.1–2.10
class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.alertSummary,
    required this.todayVideoTasks,
    required this.farmWaterQualityStatuses,
    required this.weeklyHarvestSummary,
    required this.quickMetrics,
    required this.fetchedAt,
    required this.isFromCache,
    this.lastSyncedAt,
  });

  /// Deserialises the JSON payload returned by `/dashboard/summary`.
  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final alertSummaryJson = json['alertSummary'] as Map<String, dynamic>? ?? {};
    final videoTasksJson = (json['todayVideoTasks'] as List<dynamic>?) ?? [];
    final waterQualityJson = (json['farmWaterQualityStatuses'] as List<dynamic>?) ?? [];
    final harvestJson = json['weeklyHarvestSummary'] as Map<String, dynamic>?;
    final metricsJson = json['quickMetrics'] as Map<String, dynamic>? ?? {};

    return DashboardSummaryModel(
      alertSummary: AlertSummaryModel.fromJson(alertSummaryJson),
      todayVideoTasks: videoTasksJson
          .map((e) => VideoTaskModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      farmWaterQualityStatuses: waterQualityJson
          .map((e) => FarmWaterQualityStatusModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      weeklyHarvestSummary: harvestJson != null
          ? WeeklyHarvestSummaryModel.fromJson(harvestJson)
          : WeeklyHarvestSummaryModel.empty(),
      quickMetrics: QuickMetricsModel.fromJson(metricsJson),
      fetchedAt: json['fetchedAt'] != null
          ? DateTime.parse(json['fetchedAt'] as String)
          : DateTime.now().toUtc(),
      isFromCache: json['isFromCache'] as bool? ?? false,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
    );
  }

  final AlertSummaryModel alertSummary;
  final List<VideoTaskModel> todayVideoTasks;
  final List<FarmWaterQualityStatusModel> farmWaterQualityStatuses;
  final WeeklyHarvestSummaryModel weeklyHarvestSummary;
  final QuickMetricsModel quickMetrics;
  final DateTime fetchedAt;
  final bool isFromCache;
  final DateTime? lastSyncedAt;

  Map<String, dynamic> toJson() => {
    'alertSummary': alertSummary.toJson(),
    'todayVideoTasks': todayVideoTasks.map((t) => t.toJson()).toList(),
    'farmWaterQualityStatuses': farmWaterQualityStatuses.map((s) => s.toJson()).toList(),
    'weeklyHarvestSummary': weeklyHarvestSummary.toJson(),
    'quickMetrics': quickMetrics.toJson(),
    'fetchedAt': fetchedAt.toIso8601String(),
    'isFromCache': isFromCache,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
  };

  /// Converts this DTO to the domain [DashboardSummary] entity.
  DashboardSummary toDomain() => DashboardSummary(
    alertSummary: alertSummary.toDomain(),
    todayVideoTasks: todayVideoTasks.map((t) => t.toDomain()).toList(),
    farmWaterQualityStatuses: farmWaterQualityStatuses.map((s) => s.toDomain()).toList(),
    weeklyHarvestSummary: weeklyHarvestSummary.toDomain(),
    quickMetrics: quickMetrics.toDomain(),
    fetchedAt: fetchedAt,
    isFromCache: isFromCache,
    lastSyncedAt: lastSyncedAt,
  );

  /// Returns a copy with [isFromCache] overridden.
  DashboardSummaryModel copyWithIsFromCache({required bool isFromCache}) => DashboardSummaryModel(
    alertSummary: alertSummary,
    todayVideoTasks: todayVideoTasks,
    farmWaterQualityStatuses: farmWaterQualityStatuses,
    weeklyHarvestSummary: weeklyHarvestSummary,
    quickMetrics: quickMetrics,
    fetchedAt: fetchedAt,
    isFromCache: isFromCache,
    lastSyncedAt: lastSyncedAt,
  );
}
