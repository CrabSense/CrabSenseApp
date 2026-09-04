import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Operational health status of a box on the Boxes tab.
enum BoxHealthStatus { healthy, warning, critical, offline }

extension BoxHealthStatusX on BoxHealthStatus {
  String get label {
    switch (this) {
      case BoxHealthStatus.healthy:
        return 'Healthy';
      case BoxHealthStatus.warning:
        return 'Warning';
      case BoxHealthStatus.critical:
        return 'Critical';
      case BoxHealthStatus.offline:
        return 'Offline';
    }
  }

  IconData get icon {
    switch (this) {
      case BoxHealthStatus.healthy:
        return Icons.check_circle_rounded;
      case BoxHealthStatus.warning:
        return Icons.warning_amber_rounded;
      case BoxHealthStatus.critical:
        return Icons.error_rounded;
      case BoxHealthStatus.offline:
        return Icons.cloud_off_rounded;
    }
  }

  Color get color {
    switch (this) {
      case BoxHealthStatus.healthy:
        return CrabSenseColors.success;
      case BoxHealthStatus.warning:
        return CrabSenseColors.warning;
      case BoxHealthStatus.critical:
        return CrabSenseColors.danger;
      case BoxHealthStatus.offline:
        return CrabSenseColors.hintText;
    }
  }
}

enum BoxTrend { improving, stable, declining }

extension BoxTrendX on BoxTrend {
  String get label {
    switch (this) {
      case BoxTrend.improving:
        return 'Improving';
      case BoxTrend.stable:
        return 'Stable';
      case BoxTrend.declining:
        return 'Declining';
    }
  }

  IconData get icon {
    switch (this) {
      case BoxTrend.improving:
        return Icons.trending_up_rounded;
      case BoxTrend.stable:
        return Icons.trending_flat_rounded;
      case BoxTrend.declining:
        return Icons.trending_down_rounded;
    }
  }

  Color get color {
    switch (this) {
      case BoxTrend.improving:
        return CrabSenseColors.success;
      case BoxTrend.stable:
        return CrabSenseColors.info;
      case BoxTrend.declining:
        return CrabSenseColors.danger;
    }
  }
}

enum BoxesViewMode { grid, list, farmMap }

enum BoxSortOption {
  name,
  lowestHealth,
  latestAlert,
  aiPriority,
  harvestDate,
  lastUpdated,
}

extension BoxSortOptionX on BoxSortOption {
  String get label {
    switch (this) {
      case BoxSortOption.name:
        return 'Tên Box';
      case BoxSortOption.lowestHealth:
        return 'Health Score thấp nhất';
      case BoxSortOption.latestAlert:
        return 'Cảnh báo mới nhất';
      case BoxSortOption.aiPriority:
        return 'AI Priority';
      case BoxSortOption.harvestDate:
        return 'Ngày thu hoạch dự kiến';
      case BoxSortOption.lastUpdated:
        return 'Lần cập nhật gần nhất';
    }
  }
}

/// Quick filter chips on the Boxes tab.
enum BoxQuickFilter {
  all,
  healthy,
  warning,
  critical,
  offline,
  hasAlert,
  hasAiRecommendation,
  nearHarvest,
}

extension BoxQuickFilterX on BoxQuickFilter {
  String get label {
    switch (this) {
      case BoxQuickFilter.all:
        return 'Tất cả';
      case BoxQuickFilter.healthy:
        return 'Healthy';
      case BoxQuickFilter.warning:
        return 'Warning';
      case BoxQuickFilter.critical:
        return 'Critical';
      case BoxQuickFilter.offline:
        return 'Offline';
      case BoxQuickFilter.hasAlert:
        return 'Có cảnh báo';
      case BoxQuickFilter.hasAiRecommendation:
        return 'Có đề xuất AI';
      case BoxQuickFilter.nearHarvest:
        return 'Sắp thu hoạch';
    }
  }
}

enum BoxSyncStatus { synced, pending, conflict, stale }

enum ActionPriorityLevel { high, medium, low }

/// AI Health Score for a single box (0–100).
class BoxHealthScore {
  final int score;
  final double aiConfidence;
  final BoxTrend trend;
  final String statusLabel;
  final String explanation;

  const BoxHealthScore({
    required this.score,
    required this.aiConfidence,
    required this.trend,
    required this.statusLabel,
    required this.explanation,
  });

  Color get scoreColor {
    if (score >= 85) return CrabSenseColors.success;
    if (score >= 70) return CrabSenseColors.info;
    if (score >= 50) return CrabSenseColors.warning;
    return CrabSenseColors.danger;
  }

  static BoxHealthScore fromScore(
    int score,
    double confidence,
    BoxTrend trend,
  ) {
    final clamped = score.clamp(0, 100);
    String label;
    if (clamped >= 85) {
      label = 'Excellent';
    } else if (clamped >= 70) {
      label = 'Good';
    } else if (clamped >= 50) {
      label = 'Warning';
    } else {
      label = 'Critical';
    }
    return BoxHealthScore(
      score: clamped,
      aiConfidence: confidence.clamp(0, 100),
      trend: trend,
      statusLabel: label,
      explanation:
          'Điểm sức khỏe tổng hợp từ chất lượng nước, tình trạng cua và thiết bị IoT.',
    );
  }
}

class BoxWaterSnapshot {
  final double? temperature;
  final double? ph;
  final double? dissolvedOxygen;

  const BoxWaterSnapshot({this.temperature, this.ph, this.dissolvedOxygen});

  static const empty = BoxWaterSnapshot();
}

class BoxDeviceStatus {
  final bool isOnline;
  final int onlineCount;
  final int totalCount;

  const BoxDeviceStatus({
    required this.isOnline,
    required this.onlineCount,
    required this.totalCount,
  });

  static const offline = BoxDeviceStatus(
    isOnline: false,
    onlineCount: 0,
    totalCount: 0,
  );
}

class BoxAlertSummary {
  final int count;
  final String? latestTitle;
  final DateTime? latestAt;

  const BoxAlertSummary({required this.count, this.latestTitle, this.latestAt});

  bool get hasAlerts => count > 0;

  static const none = BoxAlertSummary(count: 0);
}

class BoxAIRecommendation {
  final bool hasRecommendation;
  final String? title;
  final String? description;
  final ActionPriorityLevel priority;

  const BoxAIRecommendation({
    required this.hasRecommendation,
    this.title,
    this.description,
    this.priority = ActionPriorityLevel.low,
  });

  static const none = BoxAIRecommendation(hasRecommendation: false);
}

/// Relative layout position for Farm Digital Twin (not geo coordinates).
class BoxMapLocation {
  final double gridX;
  final double gridY;
  final String areaName;
  final String? rowName;
  final String areaId;

  const BoxMapLocation({
    required this.gridX,
    required this.gridY,
    required this.areaName,
    required this.areaId,
    this.rowName,
  });
}

class FarmAreaOption {
  final String id;
  final String name;

  const FarmAreaOption({required this.id, required this.name});
}

class FarmRowOption {
  final String id;
  final String name;
  final String farmingAreaId;
  final String? areaName;
  final int capacity;
  final int boxCount;
  final bool isActive;

  const FarmRowOption({
    required this.id,
    required this.name,
    required this.farmingAreaId,
    this.areaName,
    this.capacity = 0,
    this.boxCount = 0,
    this.isActive = true,
  });

  @override
  bool operator ==(Object other) => other is FarmRowOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Advanced filter state for the Boxes tab.
class BoxFilterState {
  final String? farmId;
  final String? areaId;
  final Set<BoxHealthStatus> statuses;
  final String? crabType;
  final String? batch;
  final DateTimeRange? stockedRange;
  final RangeValues healthScoreRange;
  final RangeValues aiConfidenceRange;
  final bool? hasAlerts;
  final bool? deviceOffline;
  final bool? hasAiRecommendation;
  final bool? waterTestDue;
  final bool? videoDue;
  final bool? nearHarvest;
  final ActionPriorityLevel? priority;
  final BoxSortOption sortOption;

  const BoxFilterState({
    this.farmId,
    this.areaId,
    this.statuses = const {},
    this.crabType,
    this.batch,
    this.stockedRange,
    this.healthScoreRange = const RangeValues(0, 100),
    this.aiConfidenceRange = const RangeValues(0, 100),
    this.hasAlerts,
    this.deviceOffline,
    this.hasAiRecommendation,
    this.waterTestDue,
    this.videoDue,
    this.nearHarvest,
    this.priority,
    this.sortOption = BoxSortOption.name,
  });

  static const initial = BoxFilterState();

  bool get hasActiveAdvancedFilters {
    return statuses.isNotEmpty ||
        (crabType != null && crabType!.isNotEmpty) ||
        (batch != null && batch!.isNotEmpty) ||
        stockedRange != null ||
        healthScoreRange.start > 0 ||
        healthScoreRange.end < 100 ||
        aiConfidenceRange.start > 0 ||
        aiConfidenceRange.end < 100 ||
        hasAlerts != null ||
        deviceOffline != null ||
        hasAiRecommendation != null ||
        waterTestDue != null ||
        videoDue != null ||
        nearHarvest != null ||
        priority != null ||
        sortOption != BoxSortOption.name;
  }

  BoxFilterState copyWith({
    String? farmId,
    String? areaId,
    Set<BoxHealthStatus>? statuses,
    String? crabType,
    String? batch,
    DateTimeRange? stockedRange,
    RangeValues? healthScoreRange,
    RangeValues? aiConfidenceRange,
    bool? hasAlerts,
    bool? deviceOffline,
    bool? hasAiRecommendation,
    bool? waterTestDue,
    bool? videoDue,
    bool? nearHarvest,
    ActionPriorityLevel? priority,
    BoxSortOption? sortOption,
    bool clearStockedRange = false,
    bool clearHasAlerts = false,
    bool clearDeviceOffline = false,
    bool clearHasAi = false,
    bool clearWaterDue = false,
    bool clearVideoDue = false,
    bool clearNearHarvest = false,
    bool clearPriority = false,
    bool clearCrabType = false,
    bool clearBatch = false,
  }) {
    return BoxFilterState(
      farmId: farmId ?? this.farmId,
      areaId: areaId ?? this.areaId,
      statuses: statuses ?? this.statuses,
      crabType: clearCrabType ? null : (crabType ?? this.crabType),
      batch: clearBatch ? null : (batch ?? this.batch),
      stockedRange: clearStockedRange
          ? null
          : (stockedRange ?? this.stockedRange),
      healthScoreRange: healthScoreRange ?? this.healthScoreRange,
      aiConfidenceRange: aiConfidenceRange ?? this.aiConfidenceRange,
      hasAlerts: clearHasAlerts ? null : (hasAlerts ?? this.hasAlerts),
      deviceOffline: clearDeviceOffline
          ? null
          : (deviceOffline ?? this.deviceOffline),
      hasAiRecommendation: clearHasAi
          ? null
          : (hasAiRecommendation ?? this.hasAiRecommendation),
      waterTestDue: clearWaterDue ? null : (waterTestDue ?? this.waterTestDue),
      videoDue: clearVideoDue ? null : (videoDue ?? this.videoDue),
      nearHarvest: clearNearHarvest ? null : (nearHarvest ?? this.nearHarvest),
      priority: clearPriority ? null : (priority ?? this.priority),
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

/// Compact box card model for Grid / List / Map.
class BoxSummary {
  final String id;
  final String code;
  final String name;
  final String qrCode;
  final String farmId;
  final String farmName;
  final BoxMapLocation location;
  final BoxHealthStatus status;
  final BoxHealthScore healthScore;
  final int crabCount;
  final String? crabType;
  final String? batch;
  final BoxWaterSnapshot water;
  final BoxDeviceStatus devices;
  final BoxAlertSummary alerts;
  final BoxAIRecommendation aiRecommendation;
  final DateTime lastUpdated;
  final DateTime? expectedHarvestAt;
  final bool waterTestDue;
  final bool videoDue;
  final BoxSyncStatus syncStatus;
  final ActionPriorityLevel priority;

  const BoxSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.qrCode,
    required this.farmId,
    required this.farmName,
    required this.location,
    required this.status,
    required this.healthScore,
    required this.crabCount,
    required this.water,
    required this.devices,
    required this.alerts,
    required this.aiRecommendation,
    required this.lastUpdated,
    required this.syncStatus,
    required this.priority,
    this.crabType,
    this.batch,
    this.expectedHarvestAt,
    this.waterTestDue = false,
    this.videoDue = false,
  });

  bool get isNearHarvest {
    if (expectedHarvestAt == null) return false;
    return expectedHarvestAt!.difference(DateTime.now()).inDays <= 7;
  }

  String get semanticLabel =>
      'Box $code, khu ${location.areaName}, trạng thái ${status.label}, '
      'health score ${healthScore.score}';
}

class FarmBoxesOverview {
  final int total;
  final int healthy;
  final int warning;
  final int critical;
  final int offline;
  final int withAiRecommendation;

  const FarmBoxesOverview({
    required this.total,
    required this.healthy,
    required this.warning,
    required this.critical,
    required this.offline,
    required this.withAiRecommendation,
  });

  static const empty = FarmBoxesOverview(
    total: 0,
    healthy: 0,
    warning: 0,
    critical: 0,
    offline: 0,
    withAiRecommendation: 0,
  );

  factory FarmBoxesOverview.fromBoxes(List<BoxSummary> boxes) {
    var healthy = 0, warning = 0, critical = 0, offline = 0, ai = 0;
    for (final b in boxes) {
      switch (b.status) {
        case BoxHealthStatus.healthy:
          healthy++;
        case BoxHealthStatus.warning:
          warning++;
        case BoxHealthStatus.critical:
          critical++;
        case BoxHealthStatus.offline:
          offline++;
      }
      if (b.aiRecommendation.hasRecommendation) ai++;
    }
    return FarmBoxesOverview(
      total: boxes.length,
      healthy: healthy,
      warning: warning,
      critical: critical,
      offline: offline,
      withAiRecommendation: ai,
    );
  }
}

/// Full state for the Boxes tab.
class BoxesStateData {
  final String? selectedFarmId;
  final String selectedFarmName;
  final List<FarmAreaOption> availableFarms;
  final List<String> availableAreas;
  final List<BoxSummary> allBoxes;
  final List<BoxSummary> visibleBoxes;
  final FarmBoxesOverview overview;
  final String searchQuery;
  final Set<BoxQuickFilter> quickFilters;
  final BoxFilterState advancedFilter;
  final BoxesViewMode viewMode;
  final String? selectedBoxId;
  final bool isOnline;
  final bool isOfflineCached;
  final DateTime? lastSyncedAt;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? sectionError;
  final List<String> recentSearches;
  final bool canCreateBox;
  final bool canEditBox;
  final bool canPerformActions;

  const BoxesStateData({
    this.selectedFarmId,
    required this.selectedFarmName,
    required this.availableFarms,
    required this.availableAreas,
    required this.allBoxes,
    required this.visibleBoxes,
    required this.overview,
    required this.searchQuery,
    required this.quickFilters,
    required this.advancedFilter,
    required this.viewMode,
    this.selectedBoxId,
    required this.isOnline,
    this.isOfflineCached = false,
    this.lastSyncedAt,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.page = 1,
    this.sectionError,
    this.recentSearches = const [],
    this.canCreateBox = false,
    this.canEditBox = false,
    this.canPerformActions = false,
  });

  BoxesStateData copyWith({
    String? selectedFarmId,
    String? selectedFarmName,
    List<FarmAreaOption>? availableFarms,
    List<String>? availableAreas,
    List<BoxSummary>? allBoxes,
    List<BoxSummary>? visibleBoxes,
    FarmBoxesOverview? overview,
    String? searchQuery,
    Set<BoxQuickFilter>? quickFilters,
    BoxFilterState? advancedFilter,
    BoxesViewMode? viewMode,
    String? selectedBoxId,
    bool? isOnline,
    bool? isOfflineCached,
    DateTime? lastSyncedAt,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? sectionError,
    List<String>? recentSearches,
    bool? canCreateBox,
    bool? canEditBox,
    bool? canPerformActions,
    bool clearSelectedBox = false,
    bool clearSectionError = false,
  }) {
    return BoxesStateData(
      selectedFarmId: selectedFarmId ?? this.selectedFarmId,
      selectedFarmName: selectedFarmName ?? this.selectedFarmName,
      availableFarms: availableFarms ?? this.availableFarms,
      availableAreas: availableAreas ?? this.availableAreas,
      allBoxes: allBoxes ?? this.allBoxes,
      visibleBoxes: visibleBoxes ?? this.visibleBoxes,
      overview: overview ?? this.overview,
      searchQuery: searchQuery ?? this.searchQuery,
      quickFilters: quickFilters ?? this.quickFilters,
      advancedFilter: advancedFilter ?? this.advancedFilter,
      viewMode: viewMode ?? this.viewMode,
      selectedBoxId: clearSelectedBox
          ? null
          : (selectedBoxId ?? this.selectedBoxId),
      isOnline: isOnline ?? this.isOnline,
      isOfflineCached: isOfflineCached ?? this.isOfflineCached,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      sectionError: clearSectionError
          ? null
          : (sectionError ?? this.sectionError),
      recentSearches: recentSearches ?? this.recentSearches,
      canCreateBox: canCreateBox ?? this.canCreateBox,
      canEditBox: canEditBox ?? this.canEditBox,
      canPerformActions: canPerformActions ?? this.canPerformActions,
    );
  }
}
