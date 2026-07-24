import '../models/alerts_models.dart';

/// Repository contract for the Alerts Command Center.
///
/// Backed by:
/// - GET `/api/alerts`
/// - GET `/api/alerts/history`
/// - GET `/api/alerts/unread/count`
/// - PATCH `/api/alerts/{id}/acknowledge`
/// - PATCH `/api/alerts/{id}/resolve`
///
/// Assignment is not supported by backend yet ([assign] returns null).
abstract class AlertsCommandRepository {
  Future<AlertsStateData> getAlertsSummary({
    String? farmingAreaId,
    bool forceRefresh = false,
    String searchQuery = '',
    Set<AlertQuickFilter> quickFilters = const {AlertQuickFilter.all},
    AlertSortOption sortOption = AlertSortOption.priorityDesc,
    AlertGroupBy groupBy = AlertGroupBy.severity,
    bool showingHistory = false,
    AlertHistoryRange historyRange = AlertHistoryRange.today,
    bool canAcknowledge = false,
    bool canResolve = false,
    bool canAssign = false,
    bool canConfigureThresholds = false,
    bool canViewFullHistory = false,
    bool canMarkAllRead = false,
  });

  Future<AlertsStateData> switchFarm(String farmId);

  AlertsStateData applyLocalFilters({
    required AlertsStateData current,
    String? searchQuery,
    Set<AlertQuickFilter>? quickFilters,
    AlertSortOption? sortOption,
    AlertGroupBy? groupBy,
    bool? showingHistory,
    AlertHistoryRange? historyRange,
  });

  Future<AlertItem?> acknowledge(
    String alertId, {
    required String userId,
    required String userName,
  });

  Future<AlertItem?> startProgress(
    String alertId, {
    required String userId,
    required String userName,
  });

  Future<AlertItem?> resolve(
    String alertId, {
    required String userId,
    required String userName,
    String? note,
  });

  Future<AlertItem?> dismiss(String alertId);

  Future<AlertItem?> assign(
    String alertId, {
    required String assigneeId,
    required String assigneeName,
    required String assigneeRole,
    DateTime? dueAt,
    String? note,
  });

  Future<void> markAllRead();

  Future<void> hideAlert(String alertId);

  Future<int> syncPending();

  Future<AlertItem?> getAlertById(String alertId);
}
