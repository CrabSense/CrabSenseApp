import 'package:equatable/equatable.dart';

/// Represents the alert severity levels for dashboard display.
///
/// Requirement 2.2: show active alerts count with severity indicators
enum AlertSeverity {
  /// Critical alert requiring immediate attention
  critical,

  /// Warning alert requiring monitoring
  warning,

  /// Informational alert
  info,
}

/// Represents a single scheduled video capture task for today.
///
/// Requirement 2.3: display today's scheduled video capture tasks
class VideoTask extends Equatable {
  const VideoTask({
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

  /// Unique identifier for the box
  final String boxId;

  /// Human-readable box identifier (e.g. QR code label)
  final String boxIdentifier;

  /// Identifier for the farm owning this box
  final String farmId;

  /// Display name for the farm
  final String farmName;

  /// Optional pond identifier within the farm
  final String? pondId;

  /// Optional pond display name
  final String? pondName;

  /// Scheduled time for the video capture
  final DateTime scheduledAt;

  /// Whether this task is past its scheduled time
  final bool isOverdue;

  /// When the last video was captured for this box (null if never)
  final DateTime? lastCapturedAt;

  @override
  List<Object?> get props => [
    boxId,
    boxIdentifier,
    farmId,
    farmName,
    pondId,
    pondName,
    scheduledAt,
    isOverdue,
    lastCapturedAt,
  ];

  @override
  String toString() =>
      'VideoTask(boxId: $boxId, boxIdentifier: $boxIdentifier, '
      'farmId: $farmId, isOverdue: $isOverdue)';
}

/// Represents the real-time water quality status for a single farm.
///
/// Requirement 2.4: show real-time water quality status for all active farms
class FarmWaterQualityStatus extends Equatable {
  const FarmWaterQualityStatus({
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

  /// Unique identifier for the farm
  final String farmId;

  /// Display name for the farm
  final String farmName;

  /// Whether the IoT sensor for this farm is currently online
  final bool isOnline;

  /// Current temperature in Celsius (null if sensor offline)
  final double? temperature;

  /// Current pH level (null if sensor offline)
  final double? ph;

  /// Current dissolved oxygen in mg/L (null if sensor offline)
  final double? dissolvedOxygen;

  /// Current salinity in ppt (null if sensor offline)
  final double? salinity;

  /// Whether any water quality parameter is outside acceptable thresholds
  final bool hasAlert;

  /// Number of active water quality alerts for this farm
  final int? alertCount;

  /// Timestamp of the last sensor reading
  final DateTime? lastUpdatedAt;

  @override
  List<Object?> get props => [
    farmId,
    farmName,
    isOnline,
    temperature,
    ph,
    dissolvedOxygen,
    salinity,
    hasAlert,
    alertCount,
    lastUpdatedAt,
  ];

  @override
  String toString() =>
      'FarmWaterQualityStatus(farmId: $farmId, farmName: $farmName, '
      'isOnline: $isOnline, hasAlert: $hasAlert)';
}

/// Weekly harvest summary metrics.
///
/// Requirement 2.8: display harvest summary for current week
class WeeklyHarvestSummary extends Equatable {
  const WeeklyHarvestSummary({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.totalWeightKg,
    required this.totalCrabCount,
    required this.harvestCount,
    required this.boxesHarvested,
  });

  /// Start date of the current week (Monday)
  final DateTime weekStartDate;

  /// End date of the current week (Sunday)
  final DateTime weekEndDate;

  /// Total weight of harvested crabs in kilograms
  final double totalWeightKg;

  /// Total number of individual crabs harvested
  final int totalCrabCount;

  /// Number of distinct harvest operations recorded
  final int harvestCount;

  /// Number of distinct boxes harvested from
  final int boxesHarvested;

  @override
  List<Object?> get props => [
    weekStartDate,
    weekEndDate,
    totalWeightKg,
    totalCrabCount,
    harvestCount,
    boxesHarvested,
  ];

  @override
  String toString() =>
      'WeeklyHarvestSummary(weekStart: $weekStartDate, '
      'totalWeightKg: $totalWeightKg, totalCrabCount: $totalCrabCount)';
}

/// Aggregate summary of alert counts broken down by severity.
///
/// Requirement 2.2: show active alerts count with severity indicators
class AlertSummary extends Equatable {
  const AlertSummary({
    required this.totalActive,
    required this.criticalCount,
    required this.warningCount,
    required this.infoCount,
  });

  /// Total number of active (unread + read) alerts
  final int totalActive;

  /// Number of critical severity alerts
  final int criticalCount;

  /// Number of warning severity alerts
  final int warningCount;

  /// Number of informational alerts
  final int infoCount;

  @override
  List<Object?> get props => [totalActive, criticalCount, warningCount, infoCount];

  @override
  String toString() =>
      'AlertSummary(total: $totalActive, critical: $criticalCount, '
      'warning: $warningCount, info: $infoCount)';
}

/// Quick operational metrics shown on the dashboard.
///
/// Supports Requirement 2.1: display data within 3 seconds
class QuickMetrics extends Equatable {
  const QuickMetrics({
    required this.activeBoxCount,
    required this.videosDueToday,
    required this.videosCompletedToday,
    required this.activeFarmCount,
  });

  /// Number of boxes with active status across all farms
  final int activeBoxCount;

  /// Number of video capture tasks scheduled for today
  final int videosDueToday;

  /// Number of video capture tasks completed today
  final int videosCompletedToday;

  /// Number of farms currently active
  final int activeFarmCount;

  /// Completion percentage for today's video tasks (0.0 – 1.0)
  double get videoCompletionRatio {
    if (videosDueToday == 0) return 1;
    return videosCompletedToday / videosDueToday;
  }

  @override
  List<Object?> get props => [
    activeBoxCount,
    videosDueToday,
    videosCompletedToday,
    activeFarmCount,
  ];

  @override
  String toString() =>
      'QuickMetrics(activeBoxCount: $activeBoxCount, '
      'videosDueToday: $videosDueToday, '
      'videosCompletedToday: $videosCompletedToday)';
}

/// The aggregate entity representing all data displayed on the dashboard.
///
/// This entity is populated by [GetDashboardSummaryUseCase] and satisfies:
/// - Requirement 2.1: display data within 3 seconds
/// - Requirement 2.2: active alerts count with severity indicators
/// - Requirement 2.3: today's scheduled video capture tasks
/// - Requirement 2.4: real-time water quality status for all active farms
/// - Requirement 2.5: quick action buttons (used by presentation layer)
/// - Requirement 2.6: cached data with offline indicator support
/// - Requirement 2.7: auto-refresh every 60 seconds (refreshed at)
/// - Requirement 2.8: harvest summary for current week
/// - Requirement 2.9: error state with retry (via Either at use-case level)
/// - Requirement 2.10: skeleton loading (driven by presentation layer)
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.alertSummary,
    required this.todayVideoTasks,
    required this.farmWaterQualityStatuses,
    required this.weeklyHarvestSummary,
    required this.quickMetrics,
    required this.fetchedAt,
    required this.isFromCache,
    this.lastSyncedAt,
  });

  /// Aggregated alert counts and severity breakdown
  ///
  /// Requirement 2.2
  final AlertSummary alertSummary;

  /// List of video capture tasks scheduled for today
  ///
  /// Requirement 2.3
  final List<VideoTask> todayVideoTasks;

  /// Real-time water quality status for each active farm
  ///
  /// Requirement 2.4
  final List<FarmWaterQualityStatus> farmWaterQualityStatuses;

  /// Harvest statistics for the current week
  ///
  /// Requirement 2.8
  final WeeklyHarvestSummary weeklyHarvestSummary;

  /// High-level operational counts for the quick metrics cards
  final QuickMetrics quickMetrics;

  /// UTC timestamp when this summary was fetched or generated
  ///
  /// Used by the presentation layer to drive the 60-second auto-refresh
  /// (Requirement 2.7) and to display data freshness.
  final DateTime fetchedAt;

  /// Whether this summary was loaded from the local cache
  ///
  /// Requirement 2.6: display cached data with offline indicator
  final bool isFromCache;

  /// UTC timestamp of the most recent successful server sync,
  /// null when data has never been synced from server.
  final DateTime? lastSyncedAt;

  /// Creates a copy of this entity with specific fields replaced.
  DashboardSummary copyWith({
    AlertSummary? alertSummary,
    List<VideoTask>? todayVideoTasks,
    List<FarmWaterQualityStatus>? farmWaterQualityStatuses,
    WeeklyHarvestSummary? weeklyHarvestSummary,
    QuickMetrics? quickMetrics,
    DateTime? fetchedAt,
    bool? isFromCache,
    DateTime? lastSyncedAt,
  }) => DashboardSummary(
    alertSummary: alertSummary ?? this.alertSummary,
    todayVideoTasks: todayVideoTasks ?? this.todayVideoTasks,
    farmWaterQualityStatuses: farmWaterQualityStatuses ?? this.farmWaterQualityStatuses,
    weeklyHarvestSummary: weeklyHarvestSummary ?? this.weeklyHarvestSummary,
    quickMetrics: quickMetrics ?? this.quickMetrics,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    isFromCache: isFromCache ?? this.isFromCache,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  @override
  List<Object?> get props => [
    alertSummary,
    todayVideoTasks,
    farmWaterQualityStatuses,
    weeklyHarvestSummary,
    quickMetrics,
    fetchedAt,
    isFromCache,
    lastSyncedAt,
  ];

  @override
  String toString() =>
      'DashboardSummary(fetchedAt: $fetchedAt, isFromCache: $isFromCache, '
      'alerts: $alertSummary, quickMetrics: $quickMetrics)';
}
