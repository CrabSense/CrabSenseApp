import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/crab_condition.dart';
// Export lại để mọi file đang import `boxes_models.dart` không phải đổi import.
export '../../../../shared/models/crab_condition.dart';

/// Trạng thái XẤU NHẤT của cua trong hộp (BE trả `crabCondition`).
///
/// Hộp đang nuôi luôn có status `active`, nên nếu chỉ đọc `status` thì mọi hộp
/// đều xanh — màu phải lấy từ đây mới thấy được cua bệnh / đang lột. Nhãn và
/// màu lấy từ [BoxStatus], cùng bảng với huy hiệu cua và màn chi tiết hộp.
///
/// Bản sao của `mapCrabCondition` bên desktop; đọc qua [displayStatusOf] để
/// không có bảng thứ hai.
BoxStatus boxStatusFromCrabCondition(String? condition) =>
    displayStatusOf(CrabCondition.tryParse(condition));


/// Đọc `status` hộp từ BE — bản sao của `mapBoxApiStatus` bên desktop, để hai
/// app quy cùng một chuỗi API về cùng một trạng thái.
BoxStatus boxStatusFromApi(String? status) {
  final s = (status ?? '').trim().toLowerCase();
  return switch (s) {
    '' || 'empty' || 'available' || 'idle' || 'vacant' => BoxStatus.empty,
    'farming' || 'active' || 'occupied' => BoxStatus.normal,
    'maintenance' || 'watch' => BoxStatus.watch,
    'warning' || 'alert' || 'disease' || 'quarantine' => BoxStatus.alert,
    'molting' => BoxStatus.molting,
    // Cua chết / đã bán ⇒ BE trả hộp về trống, không còn là "sự cố".
    'dead' || 'deceased' || 'harvested' || 'sold' => BoxStatus.empty,
    _ => BoxStatus.normal,
  };
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

/// Hướng đánh số hộp trên giàn. Lưới luôn vẽ theo thứ tự đọc (trái→phải rồi
/// xuống dòng); enum này đổi thứ tự phần tử để số hộp tăng đúng theo cách
/// nông dân dán số ngoài giàn thật.
enum BoxLayoutOrder { rowLtr, rowRtl, columnLtr, columnRtl }

extension BoxLayoutOrderX on BoxLayoutOrder {
  /// Mũi tên thứ nhất: hướng đi trong dòng (hoặc trong cột).
  IconData get firstArrow => switch (this) {
        BoxLayoutOrder.rowLtr => Icons.arrow_forward_rounded,
        BoxLayoutOrder.rowRtl => Icons.arrow_back_rounded,
        BoxLayoutOrder.columnLtr => Icons.south_rounded,
        BoxLayoutOrder.columnRtl => Icons.south_rounded,
      };

  /// Mũi tên thứ hai: hướng sang dòng (hoặc cột) kế tiếp.
  IconData get secondArrow => switch (this) {
        BoxLayoutOrder.rowLtr => Icons.south_rounded,
        BoxLayoutOrder.rowRtl => Icons.south_rounded,
        BoxLayoutOrder.columnLtr => Icons.arrow_forward_rounded,
        BoxLayoutOrder.columnRtl => Icons.arrow_back_rounded,
      };

  String get tooltip => switch (this) {
        BoxLayoutOrder.rowLtr => 'Ngang trái → phải, rồi xuống dòng',
        BoxLayoutOrder.rowRtl => 'Ngang phải → trái, rồi xuống dòng',
        BoxLayoutOrder.columnLtr => 'Dọc trên → xuống, cột trái → phải',
        BoxLayoutOrder.columnRtl => 'Dọc trên → xuống, cột phải → trái',
      };
}

/// Sắp lại danh sách hộp cho khớp [order] khi lưới vẽ với [columns] cột.
///
/// Lưới tiêu thụ danh sách theo thứ tự đọc (trái→phải, trên→xuống), nên hộp
/// thứ i được đặt vào ô thứ i theo hướng [order]; kết quả trả về đã ở thứ tự
/// đọc. Ô cuối dòng có thể thiếu nên phải bỏ qua ô trống.
List<T> applyBoxLayoutOrder<T>(
  List<T> boxes,
  BoxLayoutOrder order,
  int columns,
) {
  if (order == BoxLayoutOrder.rowLtr || boxes.length < 2 || columns < 2) {
    return boxes;
  }
  final n = boxes.length;
  final rows = (n + columns - 1) ~/ columns;
  if (rows < 2) return boxes;

  final out = List<T?>.filled(n, null);
  var i = 0;
  void place(int r, int c) {
    if (r * columns + c >= n) return; // ô trống ở dòng cuối
    out[r * columns + c] = boxes[i++];
  }

  switch (order) {
    case BoxLayoutOrder.rowLtr:
      break; // đã trả sớm ở trên
    case BoxLayoutOrder.rowRtl:
      for (var r = 0; r < rows; r++) {
        for (var c = columns - 1; c >= 0; c--) {
          place(r, c);
        }
      }
    case BoxLayoutOrder.columnLtr:
      for (var c = 0; c < columns; c++) {
        for (var r = 0; r < rows; r++) {
          place(r, c);
        }
      }
    case BoxLayoutOrder.columnRtl:
      for (var c = columns - 1; c >= 0; c--) {
        for (var r = 0; r < rows; r++) {
          place(r, c);
        }
      }
  }
  return [for (final v in out) v as T];
}

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
  occupied,
  empty,
  normal,
  watch,
  molting,
  alert,
  hasAlert,
  hasAiRecommendation,
  nearHarvest,
}

extension BoxQuickFilterX on BoxQuickFilter {
  String get label {
    switch (this) {
      case BoxQuickFilter.all:
        return 'Tất cả';
      case BoxQuickFilter.occupied:
        return BoxStatus.normal.label;
      case BoxQuickFilter.empty:
        return BoxStatus.empty.label;
      // Nhãn lấy thẳng từ [BoxStatus] để chip lọc không bao giờ lệch lưới hộp.
      case BoxQuickFilter.normal:
        return BoxStatus.normal.label;
      case BoxQuickFilter.watch:
        return BoxStatus.watch.label;
      case BoxQuickFilter.molting:
        return BoxStatus.molting.label;
      case BoxQuickFilter.alert:
        return BoxStatus.alert.label;
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
  final Set<BoxStatus> statuses;
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
    Set<BoxStatus>? statuses,
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
  final BoxStatus status;
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

  /// Tình trạng xấu nhất của cua đang nuôi trong hộp (API key: normal, premolt,
  /// molting, softshell, problem, weak, dead). Null khi chưa đánh dấu.
  final String? crabCondition;

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
    this.crabCondition,
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
  final int normal;
  final int watch;
  final int molting;
  final int alert;
  final int withAiRecommendation;

  const FarmBoxesOverview({
    required this.total,
    required this.normal,
    required this.watch,
    required this.molting,
    required this.alert,
    required this.withAiRecommendation,
  });

  static const empty = FarmBoxesOverview(
    total: 0,
    normal: 0,
    watch: 0,
    molting: 0,
    alert: 0,
    withAiRecommendation: 0,
  );

  factory FarmBoxesOverview.fromBoxes(List<BoxSummary> boxes) {
    var normal = 0, watch = 0, molting = 0, alert = 0, ai = 0;
    for (final b in boxes) {
      switch (b.status) {
        case BoxStatus.normal:
          normal++;
        case BoxStatus.watch:
          watch++;
        case BoxStatus.molting:
          molting++;
        case BoxStatus.alert:
          alert++;
        case BoxStatus.deceased:
        case BoxStatus.empty:
          break; // Hộp trống / sự cố không tính vào nhóm đang nuôi.
      }
      if (b.aiRecommendation.hasRecommendation) ai++;
    }
    return FarmBoxesOverview(
      total: boxes.length,
      normal: normal,
      watch: watch,
      molting: molting,
      alert: alert,
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
  final BoxLayoutOrder boxLayoutOrder;
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
    this.boxLayoutOrder = BoxLayoutOrder.rowLtr,
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
    BoxLayoutOrder? boxLayoutOrder,
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
      boxLayoutOrder: boxLayoutOrder ?? this.boxLayoutOrder,
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
