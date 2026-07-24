import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

/// Severity for the Alerts Command Center.
enum AlertItemSeverity { critical, high, medium, low, resolved }

extension AlertItemSeverityX on AlertItemSeverity {
  String get label {
    switch (this) {
      case AlertItemSeverity.critical:
        return 'Nghiêm trọng';
      case AlertItemSeverity.high:
        return 'Cao';
      case AlertItemSeverity.medium:
        return 'Trung bình';
      case AlertItemSeverity.low:
        return 'Thấp';
      case AlertItemSeverity.resolved:
        return 'Đã giải quyết';
    }
  }

  String get labelVi {
    switch (this) {
      case AlertItemSeverity.critical:
        return 'Nghiêm trọng';
      case AlertItemSeverity.high:
        return 'Cao';
      case AlertItemSeverity.medium:
        return 'Trung bình';
      case AlertItemSeverity.low:
        return 'Thấp';
      case AlertItemSeverity.resolved:
        return 'Đã giải quyết';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertItemSeverity.critical:
        return Icons.error_rounded;
      case AlertItemSeverity.high:
        return Icons.warning_amber_rounded;
      case AlertItemSeverity.medium:
        return Icons.info_rounded;
      case AlertItemSeverity.low:
        return Icons.notifications_none_rounded;
      case AlertItemSeverity.resolved:
        return Icons.check_circle_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AlertItemSeverity.critical:
        return Colors.redAccent;
      case AlertItemSeverity.high:
        return kHomeOrange;
      case AlertItemSeverity.medium:
        return kHomeBlueLight;
      case AlertItemSeverity.low:
        return Colors.white54;
      case AlertItemSeverity.resolved:
        return kHomeGreen;
    }
  }

  /// Map priority score bands to display severity.
  static AlertItemSeverity fromPriorityScore(int score) {
    if (score >= 85) return AlertItemSeverity.critical;
    if (score >= 70) return AlertItemSeverity.high;
    if (score >= 50) return AlertItemSeverity.medium;
    return AlertItemSeverity.low;
  }
}

/// Alert category groups.
enum AlertCategory { waterQuality, crabHealth, device, ai, operations, system }

extension AlertCategoryX on AlertCategory {
  String get label {
    switch (this) {
      case AlertCategory.waterQuality:
        return 'Chất lượng nước';
      case AlertCategory.crabHealth:
        return 'Sức khỏe cua';
      case AlertCategory.device:
        return 'Thiết bị';
      case AlertCategory.ai:
        return 'AI';
      case AlertCategory.operations:
        return 'Vận hành';
      case AlertCategory.system:
        return 'Hệ thống';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertCategory.waterQuality:
        return Icons.water_drop_rounded;
      case AlertCategory.crabHealth:
        return Icons.pets_rounded;
      case AlertCategory.device:
        return Icons.sensors_rounded;
      case AlertCategory.ai:
        return Icons.auto_awesome_rounded;
      case AlertCategory.operations:
        return Icons.assignment_rounded;
      case AlertCategory.system:
        return Icons.settings_rounded;
    }
  }
}

/// Alert lifecycle status.
enum AlertLifecycleStatus {
  newly,
  acknowledged,
  inProgress,
  resolved,
  reopened,
  dismissed,
}

extension AlertLifecycleStatusX on AlertLifecycleStatus {
  String get label {
    switch (this) {
      case AlertLifecycleStatus.newly:
        return 'Chưa xử lý';
      case AlertLifecycleStatus.acknowledged:
        return 'Đã xem';
      case AlertLifecycleStatus.inProgress:
        return 'Đang xử lý';
      case AlertLifecycleStatus.resolved:
        return 'Đã giải quyết';
      case AlertLifecycleStatus.reopened:
        return 'Tái diễn';
      case AlertLifecycleStatus.dismissed:
        return 'Đã bỏ qua';
    }
  }

  Color get color {
    switch (this) {
      case AlertLifecycleStatus.newly:
        return Colors.redAccent;
      case AlertLifecycleStatus.acknowledged:
        return kHomeBlueLight;
      case AlertLifecycleStatus.inProgress:
        return kHomeOrange;
      case AlertLifecycleStatus.resolved:
        return kHomeGreen;
      case AlertLifecycleStatus.reopened:
        return Colors.redAccent;
      case AlertLifecycleStatus.dismissed:
        return Colors.white54;
    }
  }

  bool get isOpen =>
      this == AlertLifecycleStatus.newly ||
      this == AlertLifecycleStatus.acknowledged ||
      this == AlertLifecycleStatus.inProgress ||
      this == AlertLifecycleStatus.reopened;
}

enum AlertSyncStatus { synced, pending, conflict, offlineCached }

enum AlertSortOption { priorityDesc, newest, oldest, severity }

enum AlertGroupBy { severity, date, category, status, box, none }

enum AlertHistoryRange { today, days7, days30, custom }

enum AlertQuickFilter {
  all,
  critical,
  high,
  unread,
  inProgress,
  resolved,
  waterQuality,
  crabHealth,
  device,
  ai,
  operations,
  system,
}

extension AlertQuickFilterX on AlertQuickFilter {
  String get label {
    switch (this) {
      case AlertQuickFilter.all:
        return 'Tất cả';
      case AlertQuickFilter.critical:
        return 'Nghiêm trọng';
      case AlertQuickFilter.high:
        return 'Cao';
      case AlertQuickFilter.unread:
        return 'Chưa xem';
      case AlertQuickFilter.inProgress:
        return 'Đang xử lý';
      case AlertQuickFilter.resolved:
        return 'Đã giải quyết';
      case AlertQuickFilter.waterQuality:
        return 'Chất lượng nước';
      case AlertQuickFilter.crabHealth:
        return 'Sức khỏe cua';
      case AlertQuickFilter.device:
        return 'Thiết bị';
      case AlertQuickFilter.ai:
        return 'AI';
      case AlertQuickFilter.operations:
        return 'Vận hành';
      case AlertQuickFilter.system:
        return 'Hệ thống';
    }
  }
}

class AlertFarmOption {
  final String id;
  final String name;

  const AlertFarmOption({required this.id, required this.name});
}

class AlertPriorityScore {
  final int score;
  final String explanation;
  final String slaLabel;

  const AlertPriorityScore({
    required this.score,
    required this.explanation,
    required this.slaLabel,
  });

  AlertItemSeverity get band => AlertItemSeverityX.fromPriorityScore(score);

  Color get color {
    if (score >= 85) return Colors.redAccent;
    if (score >= 70) return kHomeOrange;
    if (score >= 50) return kHomeBlueLight;
    return Colors.white54;
  }
}

class AlertThreshold {
  final String label;
  final String? currentValue;
  final String? allowedRange;
  final String? unit;

  const AlertThreshold({
    required this.label,
    this.currentValue,
    this.allowedRange,
    this.unit,
  });
}

class AIRecommendedAction {
  final String action;
  final String reason;
  final int confidence;
  final String deadline;
  final String expectedImpact;
  final String recheckCondition;
  final bool isDangerous;

  const AIRecommendedAction({
    required this.action,
    required this.reason,
    required this.confidence,
    required this.deadline,
    required this.expectedImpact,
    required this.recheckCondition,
    this.isDangerous = false,
  });
}

class AlertAssignment {
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneeRole;
  final DateTime? dueAt;
  final String? note;
  final String acceptanceStatus;

  const AlertAssignment({
    this.assigneeId,
    this.assigneeName,
    this.assigneeRole,
    this.dueAt,
    this.note,
    this.acceptanceStatus = 'pending',
  });

  bool get isAssigned => assigneeId != null && assigneeId!.isNotEmpty;

  static const empty = AlertAssignment();
}

class AlertTimelineEvent {
  final String id;
  final String title;
  final String? note;
  final String? actorName;
  final DateTime at;
  final AlertLifecycleStatus? status;

  const AlertTimelineEvent({
    required this.id,
    required this.title,
    required this.at,
    this.note,
    this.actorName,
    this.status,
  });
}

class AlertActionDef {
  final String id;
  final String label;
  final IconData icon;
  final bool requiresConfirmation;
  final bool isPrimary;

  const AlertActionDef({
    required this.id,
    required this.label,
    required this.icon,
    this.requiresConfirmation = false,
    this.isPrimary = false,
  });
}

class AlertSeveritySummary {
  final int critical;
  final int high;
  final int medium;
  final int low;
  final int acknowledged;
  final int resolvedToday;
  final int unread;
  final int open;

  const AlertSeveritySummary({
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
    required this.acknowledged,
    required this.resolvedToday,
    required this.unread,
    required this.open,
  });

  static const empty = AlertSeveritySummary(
    critical: 0,
    high: 0,
    medium: 0,
    low: 0,
    acknowledged: 0,
    resolvedToday: 0,
    unread: 0,
    open: 0,
  );
}

/// Rich alert item for the Command Center UI.
class AlertItem {
  final String id;
  final String code;
  final String title;
  final String description;
  final AlertItemSeverity severity;
  final AlertCategory category;
  final AlertLifecycleStatus status;
  final AlertPriorityScore priority;
  final AlertThreshold? threshold;
  final String? boxId;
  final String? boxCode;
  final String? deviceName;
  final String? areaName;
  final AIRecommendedAction? aiRecommendation;
  final AlertAssignment assignment;
  final List<AlertTimelineEvent> timeline;
  final List<AlertActionDef> quickActions;
  final DateTime detectedAt;
  final DateTime updatedAt;
  final bool isUnread;
  final bool isHidden;
  final AlertSyncStatus syncStatus;
  final String? impactLevel;
  final String? possibleCause;
  final List<String> resolutionNotes;

  const AlertItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.status,
    required this.priority,
    required this.detectedAt,
    required this.updatedAt,
    required this.isUnread,
    required this.quickActions,
    this.threshold,
    this.boxId,
    this.boxCode,
    this.deviceName,
    this.areaName,
    this.aiRecommendation,
    this.assignment = AlertAssignment.empty,
    this.timeline = const [],
    this.isHidden = false,
    this.syncStatus = AlertSyncStatus.synced,
    this.impactLevel,
    this.possibleCause,
    this.resolutionNotes = const [],
  });

  String get locationLabel {
    if (boxCode != null && boxCode!.isNotEmpty) return 'Box $boxCode';
    if (deviceName != null && deviceName!.isNotEmpty) return deviceName!;
    if (areaName != null && areaName!.isNotEmpty) return areaName!;
    return 'Hệ thống';
  }

  Duration get age => DateTime.now().difference(detectedAt);

  bool get isPriorityHero =>
      status.isOpen &&
      (severity == AlertItemSeverity.critical ||
          severity == AlertItemSeverity.high ||
          priority.score >= 70);

  AlertItem copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    AlertItemSeverity? severity,
    AlertCategory? category,
    AlertLifecycleStatus? status,
    AlertPriorityScore? priority,
    AlertThreshold? threshold,
    String? boxId,
    String? boxCode,
    String? deviceName,
    String? areaName,
    AIRecommendedAction? aiRecommendation,
    AlertAssignment? assignment,
    List<AlertTimelineEvent>? timeline,
    List<AlertActionDef>? quickActions,
    DateTime? detectedAt,
    DateTime? updatedAt,
    bool? isUnread,
    bool? isHidden,
    AlertSyncStatus? syncStatus,
    String? impactLevel,
    String? possibleCause,
    List<String>? resolutionNotes,
  }) {
    return AlertItem(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      threshold: threshold ?? this.threshold,
      boxId: boxId ?? this.boxId,
      boxCode: boxCode ?? this.boxCode,
      deviceName: deviceName ?? this.deviceName,
      areaName: areaName ?? this.areaName,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
      assignment: assignment ?? this.assignment,
      timeline: timeline ?? this.timeline,
      quickActions: quickActions ?? this.quickActions,
      detectedAt: detectedAt ?? this.detectedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUnread: isUnread ?? this.isUnread,
      isHidden: isHidden ?? this.isHidden,
      syncStatus: syncStatus ?? this.syncStatus,
      impactLevel: impactLevel ?? this.impactLevel,
      possibleCause: possibleCause ?? this.possibleCause,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }
}

class AlertGroupedSection {
  final String title;
  final List<AlertItem> items;

  const AlertGroupedSection({required this.title, required this.items});
}

/// Full Alerts tab state.
class AlertsStateData {
  final String selectedFarmId;
  final String selectedFarmName;
  final List<AlertFarmOption> availableFarms;
  final bool isOnline;
  final bool isOfflineCached;
  final DateTime? lastSyncedAt;
  final bool isRefreshing;
  final bool isPaginating;
  final bool hasMore;
  final int page;
  final String searchQuery;
  final Set<AlertQuickFilter> quickFilters;
  final AlertSortOption sortOption;
  final AlertGroupBy groupBy;
  final AlertSeveritySummary summary;
  final List<AlertItem> allAlerts;
  final List<AlertItem> visibleAlerts;
  final List<AlertGroupedSection> groupedAlerts;
  final AlertItem? priorityAlert;
  final String? selectedAlertId;
  final int pendingSyncCount;
  final String? sectionError;
  final bool canAcknowledge;
  final bool canResolve;
  final bool canAssign;
  final bool canConfigureThresholds;
  final bool canViewFullHistory;
  final bool canMarkAllRead;
  final AlertHistoryRange historyRange;
  final bool showingHistory;

  const AlertsStateData({
    required this.selectedFarmId,
    required this.selectedFarmName,
    required this.availableFarms,
    required this.isOnline,
    required this.isOfflineCached,
    required this.lastSyncedAt,
    required this.isRefreshing,
    required this.isPaginating,
    required this.hasMore,
    required this.page,
    required this.searchQuery,
    required this.quickFilters,
    required this.sortOption,
    required this.groupBy,
    required this.summary,
    required this.allAlerts,
    required this.visibleAlerts,
    required this.groupedAlerts,
    required this.priorityAlert,
    required this.selectedAlertId,
    required this.pendingSyncCount,
    required this.sectionError,
    required this.canAcknowledge,
    required this.canResolve,
    required this.canAssign,
    required this.canConfigureThresholds,
    required this.canViewFullHistory,
    required this.canMarkAllRead,
    required this.historyRange,
    required this.showingHistory,
  });

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      !(quickFilters.length == 1 &&
          quickFilters.contains(AlertQuickFilter.all));

  factory AlertsStateData.empty() => const AlertsStateData(
    selectedFarmId: '',
    selectedFarmName: 'Trang trại',
    availableFarms: [],
    isOnline: true,
    isOfflineCached: false,
    lastSyncedAt: null,
    isRefreshing: false,
    isPaginating: false,
    hasMore: false,
    page: 1,
    searchQuery: '',
    quickFilters: {AlertQuickFilter.all},
    sortOption: AlertSortOption.priorityDesc,
    groupBy: AlertGroupBy.severity,
    summary: AlertSeveritySummary.empty,
    allAlerts: [],
    visibleAlerts: [],
    groupedAlerts: [],
    priorityAlert: null,
    selectedAlertId: null,
    pendingSyncCount: 0,
    sectionError: null,
    canAcknowledge: false,
    canResolve: false,
    canAssign: false,
    canConfigureThresholds: false,
    canViewFullHistory: false,
    canMarkAllRead: false,
    historyRange: AlertHistoryRange.today,
    showingHistory: false,
  );

  AlertsStateData copyWith({
    String? selectedFarmId,
    String? selectedFarmName,
    List<AlertFarmOption>? availableFarms,
    bool? isOnline,
    bool? isOfflineCached,
    DateTime? lastSyncedAt,
    bool? isRefreshing,
    bool? isPaginating,
    bool? hasMore,
    int? page,
    String? searchQuery,
    Set<AlertQuickFilter>? quickFilters,
    AlertSortOption? sortOption,
    AlertGroupBy? groupBy,
    AlertSeveritySummary? summary,
    List<AlertItem>? allAlerts,
    List<AlertItem>? visibleAlerts,
    List<AlertGroupedSection>? groupedAlerts,
    AlertItem? priorityAlert,
    bool clearPriorityAlert = false,
    String? selectedAlertId,
    bool clearSelectedAlert = false,
    int? pendingSyncCount,
    String? sectionError,
    bool clearSectionError = false,
    bool? canAcknowledge,
    bool? canResolve,
    bool? canAssign,
    bool? canConfigureThresholds,
    bool? canViewFullHistory,
    bool? canMarkAllRead,
    AlertHistoryRange? historyRange,
    bool? showingHistory,
  }) {
    return AlertsStateData(
      selectedFarmId: selectedFarmId ?? this.selectedFarmId,
      selectedFarmName: selectedFarmName ?? this.selectedFarmName,
      availableFarms: availableFarms ?? this.availableFarms,
      isOnline: isOnline ?? this.isOnline,
      isOfflineCached: isOfflineCached ?? this.isOfflineCached,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      quickFilters: quickFilters ?? this.quickFilters,
      sortOption: sortOption ?? this.sortOption,
      groupBy: groupBy ?? this.groupBy,
      summary: summary ?? this.summary,
      allAlerts: allAlerts ?? this.allAlerts,
      visibleAlerts: visibleAlerts ?? this.visibleAlerts,
      groupedAlerts: groupedAlerts ?? this.groupedAlerts,
      priorityAlert: clearPriorityAlert
          ? null
          : (priorityAlert ?? this.priorityAlert),
      selectedAlertId: clearSelectedAlert
          ? null
          : (selectedAlertId ?? this.selectedAlertId),
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      sectionError: clearSectionError
          ? null
          : (sectionError ?? this.sectionError),
      canAcknowledge: canAcknowledge ?? this.canAcknowledge,
      canResolve: canResolve ?? this.canResolve,
      canAssign: canAssign ?? this.canAssign,
      canConfigureThresholds:
          canConfigureThresholds ?? this.canConfigureThresholds,
      canViewFullHistory: canViewFullHistory ?? this.canViewFullHistory,
      canMarkAllRead: canMarkAllRead ?? this.canMarkAllRead,
      historyRange: historyRange ?? this.historyRange,
      showingHistory: showingHistory ?? this.showingHistory,
    );
  }
}
