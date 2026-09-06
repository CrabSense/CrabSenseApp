import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/alerts_models.dart';
import '../../domain/repositories/alerts_command_repository.dart';

/// Production Alerts repository — GET /alerts, /alerts/history, acknowledge, resolve.
/// No mock seed data.
class AlertsCommandRepositoryImpl implements AlertsCommandRepository {
  AlertsCommandRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  AlertsStateData? _cached;
  final List<_PendingOp> _pending = [];
  final Set<String> _hiddenIds = {};

  @override
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
  }) async {
    if (!forceRefresh &&
        _cached != null &&
        farmingAreaId == _cached!.selectedFarmId &&
        showingHistory == _cached!.showingHistory) {
      return applyLocalFilters(
        current: _cached!.copyWith(
          canAcknowledge: canAcknowledge,
          canResolve: canResolve,
          canAssign: canAssign,
          canConfigureThresholds: canConfigureThresholds,
          canViewFullHistory: canViewFullHistory,
          canMarkAllRead: canMarkAllRead,
          searchQuery: searchQuery,
          quickFilters: quickFilters,
          sortOption: sortOption,
          groupBy: groupBy,
          historyRange: historyRange,
          showingHistory: showingHistory,
        ),
        searchQuery: searchQuery,
        quickFilters: quickFilters,
        sortOption: sortOption,
        groupBy: groupBy,
        showingHistory: showingHistory,
        historyRange: historyRange,
      );
    }

    final farms = await _fetchFarms();
    var farmId = farmingAreaId ?? _cached?.selectedFarmId ?? '';
    var farmName = _cached?.selectedFarmName ?? 'Trang trại';
    if (farmId.isEmpty && farms.isNotEmpty) {
      farmId = farms.first.id;
      farmName = farms.first.name;
    } else if (farmId.isNotEmpty) {
      farmName =
          farms.where((f) => f.id == farmId).map((f) => f.name).firstOrNull ??
          farmName;
    }

    try {
      final alerts = showingHistory
          ? await _fetchHistory(farmId, historyRange)
          : await _fetchActive(farmId);

      final base = AlertsStateData(
        selectedFarmId: farmId,
        selectedFarmName: farmName,
        availableFarms: farms,
        isOnline: true,
        isOfflineCached: false,
        lastSyncedAt: DateTime.now(),
        isRefreshing: false,
        isPaginating: false,
        hasMore: false,
        page: 1,
        searchQuery: searchQuery,
        quickFilters: quickFilters,
        sortOption: sortOption,
        groupBy: groupBy,
        summary: AlertSeveritySummary.empty,
        allAlerts: alerts.where((a) => !_hiddenIds.contains(a.id)).toList(),
        visibleAlerts: const [],
        groupedAlerts: const [],
        priorityAlert: null,
        selectedAlertId: null,
        pendingSyncCount: _pending.length,
        sectionError: null,
        canAcknowledge: canAcknowledge,
        canResolve: canResolve,
        canAssign: canAssign,
        canConfigureThresholds: canConfigureThresholds,
        canViewFullHistory: canViewFullHistory,
        canMarkAllRead: canMarkAllRead,
        historyRange: historyRange,
        showingHistory: showingHistory,
      );

      final filtered = applyLocalFilters(current: base);
      _cached = filtered;
      return filtered;
    } on DioException catch (e) {
      if (_cached != null) {
        final offline = applyLocalFilters(
          current: _cached!.copyWith(
            isOnline: false,
            isOfflineCached: true,
            sectionError: e.message,
            pendingSyncCount: _pending.length,
            canAcknowledge: canAcknowledge,
            canResolve: canResolve,
            canAssign: canAssign,
            canConfigureThresholds: canConfigureThresholds,
            canViewFullHistory: canViewFullHistory,
            canMarkAllRead: canMarkAllRead,
          ),
        );
        return offline;
      }
      rethrow;
    }
  }

  @override
  Future<AlertsStateData> switchFarm(String farmId) {
    return getAlertsSummary(
      farmingAreaId: farmId,
      forceRefresh: true,
      searchQuery: _cached?.searchQuery ?? '',
      quickFilters: _cached?.quickFilters ?? {AlertQuickFilter.all},
      sortOption: _cached?.sortOption ?? AlertSortOption.priorityDesc,
      groupBy: _cached?.groupBy ?? AlertGroupBy.severity,
      showingHistory: _cached?.showingHistory ?? false,
      historyRange: _cached?.historyRange ?? AlertHistoryRange.today,
      canAcknowledge: _cached?.canAcknowledge ?? false,
      canResolve: _cached?.canResolve ?? false,
      canAssign: _cached?.canAssign ?? false,
      canConfigureThresholds: _cached?.canConfigureThresholds ?? false,
      canViewFullHistory: _cached?.canViewFullHistory ?? false,
      canMarkAllRead: _cached?.canMarkAllRead ?? false,
    );
  }

  @override
  AlertsStateData applyLocalFilters({
    required AlertsStateData current,
    String? searchQuery,
    Set<AlertQuickFilter>? quickFilters,
    AlertSortOption? sortOption,
    AlertGroupBy? groupBy,
    bool? showingHistory,
    AlertHistoryRange? historyRange,
  }) {
    final q = (searchQuery ?? current.searchQuery).trim().toLowerCase();
    final filters = quickFilters ?? current.quickFilters;
    final sort = sortOption ?? current.sortOption;
    final group = groupBy ?? current.groupBy;
    final history = showingHistory ?? current.showingHistory;
    final range = historyRange ?? current.historyRange;

    var list = List<AlertItem>.from(
      current.allAlerts.where((a) => !_hiddenIds.contains(a.id)),
    );

    if (history) {
      list = list.where((a) => _inHistoryRange(a, range)).toList();
    }

    if (q.isNotEmpty) {
      list = list.where((a) {
        final hay = [
          a.title,
          a.description,
          a.code,
          a.boxCode ?? '',
          a.deviceName ?? '',
          a.category.label,
          a.assignment.assigneeName ?? '',
          a.areaName ?? '',
        ].join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    }

    if (!filters.contains(AlertQuickFilter.all)) {
      list = list.where((a) => _matchesFilters(a, filters)).toList();
    }

    list = _sort(list, sort);
    final summary = _buildSummary(current.allAlerts);
    final priority = history ? null : _pickPriority(list);
    final grouped = _group(list, group);

    final result = current.copyWith(
      searchQuery: searchQuery ?? current.searchQuery,
      quickFilters: filters,
      sortOption: sort,
      groupBy: group,
      showingHistory: history,
      historyRange: range,
      visibleAlerts: list,
      groupedAlerts: grouped,
      summary: summary,
      priorityAlert: priority,
      clearPriorityAlert: priority == null,
      pendingSyncCount: _pending.length,
    );
    _cached = result;
    return result;
  }

  @override
  Future<AlertItem?> acknowledge(
    String alertId, {
    required String userId,
    required String userName,
  }) async {
    try {
      final res = await _api.patch(
        ApiConstants.acknowledgeAlert(alertId),
        data: {'userId': userId},
      );
      final map = _asMap(_unwrapData(res.data));
      if (map == null) return null;
      final updated = _mapAlert(map);
      _patchCache(updated);
      return updated;
    } on DioException {
      _pending.add(
        _PendingOp(
          type: 'acknowledge',
          alertId: alertId,
          payload: {'userId': userId},
        ),
      );
      final local = _optimisticStatus(
        alertId,
        AlertLifecycleStatus.acknowledged,
        userName: userName,
      );
      return local;
    }
  }

  @override
  Future<AlertItem?> startProgress(
    String alertId, {
    required String userId,
    required String userName,
  }) {
    // Backend has Active → Acknowledged → Resolved (no InProgress).
    return acknowledge(alertId, userId: userId, userName: userName);
  }

  @override
  Future<AlertItem?> resolve(
    String alertId, {
    required String userId,
    required String userName,
    String? note,
  }) async {
    try {
      final res = await _api.patch(ApiConstants.resolveAlert(alertId));
      final map = _asMap(_unwrapData(res.data));
      if (map == null) return null;
      final updated = _mapAlert(map).copyWith(
        resolutionNotes: note == null || note.isEmpty ? const [] : [note],
      );
      _patchCache(updated);
      return updated;
    } on DioException {
      _pending.add(
        _PendingOp(
          type: 'resolve',
          alertId: alertId,
          payload: {'userId': userId, 'note': note},
        ),
      );
      return _optimisticStatus(
        alertId,
        AlertLifecycleStatus.resolved,
        userName: userName,
        note: note,
      );
    }
  }

  @override
  Future<AlertItem?> dismiss(String alertId) {
    return resolve(alertId, userId: 'current', userName: 'Operator');
  }

  @override
  Future<AlertItem?> assign(
    String alertId, {
    required String assigneeId,
    required String assigneeName,
    required String assigneeRole,
    DateTime? dueAt,
    String? note,
  }) async {
    // Assignment API not available on backend yet.
    return null;
  }

  @override
  Future<void> markAllRead() async {
    final actives = (_cached?.allAlerts ?? [])
        .where((a) => a.status == AlertLifecycleStatus.newly || a.isUnread)
        .toList();
    for (final a in actives) {
      try {
        await _api.patch(ApiConstants.acknowledgeAlert(a.id), data: const {});
      } catch (_) {}
    }
  }

  @override
  Future<void> hideAlert(String alertId) async {
    _hiddenIds.add(alertId);
    if (_cached != null) {
      _cached = applyLocalFilters(
        current: _cached!.copyWith(
          allAlerts: _cached!.allAlerts.where((a) => a.id != alertId).toList(),
        ),
      );
    }
  }

  @override
  Future<int> syncPending() async {
    if (_pending.isEmpty) {
      await getAlertsSummary(
        farmingAreaId: _cached?.selectedFarmId,
        forceRefresh: true,
        searchQuery: _cached?.searchQuery ?? '',
        quickFilters: _cached?.quickFilters ?? {AlertQuickFilter.all},
        sortOption: _cached?.sortOption ?? AlertSortOption.priorityDesc,
        groupBy: _cached?.groupBy ?? AlertGroupBy.severity,
        showingHistory: _cached?.showingHistory ?? false,
        historyRange: _cached?.historyRange ?? AlertHistoryRange.today,
        canAcknowledge: _cached?.canAcknowledge ?? false,
        canResolve: _cached?.canResolve ?? false,
        canAssign: _cached?.canAssign ?? false,
        canConfigureThresholds: _cached?.canConfigureThresholds ?? false,
        canViewFullHistory: _cached?.canViewFullHistory ?? false,
        canMarkAllRead: _cached?.canMarkAllRead ?? false,
      );
      return 0;
    }

    final ops = List<_PendingOp>.from(_pending);
    _pending.clear();
    var synced = 0;
    for (final op in ops) {
      try {
        if (op.type == 'acknowledge') {
          await _api.patch(
            ApiConstants.acknowledgeAlert(op.alertId),
            data: op.payload,
          );
          synced++;
        } else if (op.type == 'resolve') {
          await _api.patch(ApiConstants.resolveAlert(op.alertId));
          synced++;
        }
      } catch (_) {
        _pending.add(op);
      }
    }

    await getAlertsSummary(
      farmingAreaId: _cached?.selectedFarmId,
      forceRefresh: true,
      searchQuery: _cached?.searchQuery ?? '',
      quickFilters: _cached?.quickFilters ?? {AlertQuickFilter.all},
      sortOption: _cached?.sortOption ?? AlertSortOption.priorityDesc,
      groupBy: _cached?.groupBy ?? AlertGroupBy.severity,
      showingHistory: _cached?.showingHistory ?? false,
      historyRange: _cached?.historyRange ?? AlertHistoryRange.today,
      canAcknowledge: _cached?.canAcknowledge ?? false,
      canResolve: _cached?.canResolve ?? false,
      canAssign: _cached?.canAssign ?? false,
      canConfigureThresholds: _cached?.canConfigureThresholds ?? false,
      canViewFullHistory: _cached?.canViewFullHistory ?? false,
      canMarkAllRead: _cached?.canMarkAllRead ?? false,
    );
    return synced;
  }

  @override
  Future<AlertItem?> getAlertById(String alertId) async {
    try {
      final res = await _api.get(ApiConstants.alertDetails(alertId));
      final map = _asMap(_unwrapData(res.data));
      if (map == null) return null;
      return _mapAlert(map);
    } catch (_) {
      try {
        return _cached?.allAlerts.firstWhere((a) => a.id == alertId);
      } catch (_) {
        return null;
      }
    }
  }

  // ── Network helpers ───────────────────────────────────────────────────────

  Future<List<AlertFarmOption>> _fetchFarms() async {
    final res = await _api.get(ApiConstants.farmingAreas);
    final list = _extractList(res.data) ?? const [];
    final farms = <AlertFarmOption>[];
    for (final item in list) {
      final map = _asMap(item);
      if (map == null) continue;
      final id = map['id']?.toString();
      final name = map['name']?.toString() ?? map['code']?.toString();
      if (id == null || name == null) continue;
      farms.add(AlertFarmOption(id: id, name: name));
    }
    return farms;
  }

  Future<List<AlertItem>> _fetchActive(String farmId) async {
    final query = <String, dynamic>{'activeOnly': true};
    if (farmId.isNotEmpty) query['farmingAreaId'] = farmId;
    final res = await _api.get(ApiConstants.alerts, queryParameters: query);
    return _parseAlertList(res.data);
  }

  Future<List<AlertItem>> _fetchHistory(
    String farmId,
    AlertHistoryRange range,
  ) async {
    final days = switch (range) {
      AlertHistoryRange.today => 1,
      AlertHistoryRange.days7 => 7,
      AlertHistoryRange.days30 => 30,
      AlertHistoryRange.custom => 30,
    };
    final query = <String, dynamic>{'days': days};
    if (farmId.isNotEmpty) query['farmingAreaId'] = farmId;

    try {
      final res = await _api.get(
        ApiConstants.alertHistory,
        queryParameters: query,
      );
      return _parseAlertList(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback: full list then filter resolved locally.
        final queryAll = <String, dynamic>{'activeOnly': false};
        if (farmId.isNotEmpty) queryAll['farmingAreaId'] = farmId;
        final res = await _api.get(
          ApiConstants.alerts,
          queryParameters: queryAll,
        );
        return _parseAlertList(res.data)
            .where(
              (a) =>
                  a.status == AlertLifecycleStatus.resolved ||
                  a.status == AlertLifecycleStatus.acknowledged,
            )
            .toList();
      }
      rethrow;
    }
  }

  List<AlertItem> _parseAlertList(dynamic raw) {
    final list = _extractList(raw) ?? const [];
    return list
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(_mapAlert)
        .toList();
  }

  AlertItem _mapAlert(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final message = map['message']?.toString() ?? '';
    final title = map['title']?.toString().trim().isNotEmpty == true
        ? map['title'].toString()
        : (message.isEmpty ? 'Cảnh báo hệ thống' : message);
    final severity = _mapSeverity(
      map['severity']?.toString(),
      map['priorityScore'] as int? ?? map['priority_score'] as int?,
    );
    final status = _mapStatus(map['status']?.toString());
    final category = _mapCategory(map['category']?.toString(), message);
    final score =
        (map['priorityScore'] as num?)?.toInt() ??
        (map['priority_score'] as num?)?.toInt() ??
        _fallbackScore(severity);
    final priority = AlertPriorityScore(
      score: score.clamp(0, 100),
      explanation:
          map['priorityExplanation']?.toString() ??
          map['priority_explanation']?.toString() ??
          'Tính từ severity và mức vượt ngưỡng.',
      slaLabel:
          map['slaLabel']?.toString() ??
          map['sla_label']?.toString() ??
          _fallbackSla(score),
    );

    final trigger = map['triggerValue'] ?? map['trigger_value'];
    final min = map['thresholdMin'] ?? map['threshold_min'];
    final max = map['thresholdMax'] ?? map['threshold_max'];
    final unit = map['unit']?.toString();
    final sensorType =
        map['sensorType']?.toString() ?? map['sensor_type']?.toString();

    AlertThreshold? threshold;
    if (trigger != null || min != null || max != null) {
      final range = (min != null && max != null)
          ? '$min–$max'
          : (min != null ? '≥ $min' : (max != null ? '≤ $max' : null));
      threshold = AlertThreshold(
        label: sensorType ?? 'Giá trị',
        currentValue: trigger?.toString(),
        allowedRange: range,
        unit: unit,
      );
    }

    final aiText =
        map['aiRecommendation']?.toString() ??
        map['ai_recommendation']?.toString();
    final aiConfidence =
        (map['aiConfidence'] as num?)?.toInt() ??
        (map['ai_confidence'] as num?)?.toInt();
    AIRecommendedAction? ai;
    if (aiText != null && aiText.isNotEmpty) {
      ai = AIRecommendedAction(
        action: aiText,
        reason: message,
        confidence: aiConfidence ?? 70,
        deadline: priority.slaLabel,
        expectedImpact: 'Ổn định thông số / khôi phục giám sát.',
        recheckCondition: 'Đo lại sau khi xử lý',
        isDangerous: severity == AlertItemSeverity.critical,
      );
    }

    final detectedAt =
        DateTime.tryParse(
          map['createdAt']?.toString() ?? map['created_at']?.toString() ?? '',
        ) ??
        DateTime.now();
    final ackAt = DateTime.tryParse(
      map['acknowledgedAt']?.toString() ??
          map['acknowledged_at']?.toString() ??
          '',
    );

    final timeline = <AlertTimelineEvent>[
      AlertTimelineEvent(
        id: '$id-created',
        title: 'Cảnh báo được tạo',
        at: detectedAt,
        status: AlertLifecycleStatus.newly,
      ),
      if (ackAt != null)
        AlertTimelineEvent(
          id: '$id-ack',
          title: 'Đã xác nhận xem',
          at: ackAt,
          status: AlertLifecycleStatus.acknowledged,
        ),
      if (status == AlertLifecycleStatus.resolved)
        AlertTimelineEvent(
          id: '$id-resolved',
          title: 'Đã giải quyết',
          at: map['updatedAt'] != null
              ? DateTime.tryParse(map['updatedAt'].toString()) ?? detectedAt
              : detectedAt,
          status: AlertLifecycleStatus.resolved,
        ),
    ];

    return AlertItem(
      id: id,
      code: 'ALT-${id.length >= 8 ? id.substring(0, 8).toUpperCase() : id}',
      title: title,
      description: message,
      severity: status == AlertLifecycleStatus.resolved
          ? AlertItemSeverity.resolved
          : severity,
      category: category,
      status: status,
      priority: priority,
      threshold: threshold,
      boxId: map['boxId']?.toString() ?? map['box_id']?.toString(),
      boxCode: map['boxCode']?.toString() ?? map['box_code']?.toString(),
      deviceName:
          map['sensorCode']?.toString() ?? map['sensor_code']?.toString(),
      areaName:
          map['farmingAreaName']?.toString() ??
          map['farming_area_name']?.toString() ??
          map['locationLabel']?.toString() ??
          map['location_label']?.toString(),
      aiRecommendation: ai,
      detectedAt: detectedAt,
      updatedAt: ackAt ?? detectedAt,
      isUnread: status == AlertLifecycleStatus.newly,
      quickActions: _actionsFor(category),
      timeline: timeline,
      impactLevel: severity == AlertItemSeverity.critical
          ? 'Cao'
          : severity == AlertItemSeverity.high
          ? 'Trung bình-Cao'
          : 'Theo dõi',
      syncStatus: AlertSyncStatus.synced,
    );
  }

  List<AlertActionDef> _actionsFor(AlertCategory category) {
    switch (category) {
      case AlertCategory.waterQuality:
        return const [
          AlertActionDef(
            id: 'check_water',
            label: 'Kiểm tra nước',
            icon: Icons.science_rounded,
            isPrimary: true,
          ),
          AlertActionDef(
            id: 'view_chart',
            label: 'Xem biểu đồ',
            icon: Icons.show_chart_rounded,
          ),
          AlertActionDef(
            id: 'log_result',
            label: 'Ghi nhận kết quả',
            icon: Icons.edit_note_rounded,
          ),
        ];
      case AlertCategory.device:
        return const [
          AlertActionDef(
            id: 'retry_connect',
            label: 'Thử kết nối lại',
            icon: Icons.refresh_rounded,
            isPrimary: true,
          ),
          AlertActionDef(
            id: 'view_device',
            label: 'Xem thiết bị',
            icon: Icons.memory_rounded,
          ),
        ];
      case AlertCategory.ai:
        return const [
          AlertActionDef(
            id: 'retake_video',
            label: 'Quay lại video',
            icon: Icons.videocam_rounded,
            isPrimary: true,
          ),
          AlertActionDef(
            id: 'view_ai',
            label: 'Xem kết quả AI',
            icon: Icons.analytics_rounded,
          ),
        ];
      case AlertCategory.crabHealth:
        return const [
          AlertActionDef(
            id: 'manual_check',
            label: 'Kiểm tra thủ công',
            icon: Icons.search_rounded,
            isPrimary: true,
          ),
          AlertActionDef(
            id: 'ai_video',
            label: 'Quay video AI',
            icon: Icons.videocam_rounded,
          ),
        ];
      case AlertCategory.operations:
        return const [
          AlertActionDef(
            id: 'start_task',
            label: 'Bắt đầu công việc',
            icon: Icons.play_arrow_rounded,
            isPrimary: true,
          ),
          AlertActionDef(
            id: 'complete',
            label: 'Đánh dấu hoàn thành',
            icon: Icons.check_rounded,
          ),
        ];
      case AlertCategory.system:
        return const [
          AlertActionDef(
            id: 'retry_sync',
            label: 'Thử đồng bộ lại',
            icon: Icons.sync_rounded,
            isPrimary: true,
          ),
        ];
    }
  }

  AlertItemSeverity _mapSeverity(String? raw, int? score) {
    if (score != null) {
      return AlertItemSeverityX.fromPriorityScore(score);
    }
    final s = (raw ?? '').toLowerCase();
    if (s.contains('critical') || s.contains('danger')) {
      return AlertItemSeverity.critical;
    }
    if (s.contains('warning') || s.contains('high')) {
      return AlertItemSeverity.high;
    }
    if (s.contains('info') || s.contains('low')) {
      return AlertItemSeverity.low;
    }
    return AlertItemSeverity.medium;
  }

  AlertLifecycleStatus _mapStatus(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('resolv')) return AlertLifecycleStatus.resolved;
    if (s.contains('ack')) return AlertLifecycleStatus.acknowledged;
    if (s.contains('progress')) return AlertLifecycleStatus.inProgress;
    if (s.contains('dismiss')) return AlertLifecycleStatus.dismissed;
    if (s.contains('reopen')) return AlertLifecycleStatus.reopened;
    return AlertLifecycleStatus.newly;
  }

  AlertCategory _mapCategory(String? raw, String message) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('crab')) return AlertCategory.crabHealth;
    if (s.contains('device')) return AlertCategory.device;
    if (s == 'ai') return AlertCategory.ai;
    if (s.contains('operation')) return AlertCategory.operations;
    if (s.contains('system')) return AlertCategory.system;
    if (s.contains('water')) return AlertCategory.waterQuality;

    final m = message.toLowerCase();
    if (m.contains('mất kết nối') ||
        m.contains('offline') ||
        m.contains('camera') ||
        m.contains('esp32')) {
      return AlertCategory.device;
    }
    return AlertCategory.waterQuality;
  }

  int _fallbackScore(AlertItemSeverity severity) {
    switch (severity) {
      case AlertItemSeverity.critical:
        return 90;
      case AlertItemSeverity.high:
        return 75;
      case AlertItemSeverity.medium:
        return 58;
      case AlertItemSeverity.low:
        return 40;
      case AlertItemSeverity.resolved:
        return 20;
    }
  }

  String _fallbackSla(int score) {
    if (score >= 85) return 'Cần xử lý trong 10 phút';
    if (score >= 70) return 'Cần xử lý trong 1 giờ';
    if (score >= 50) return 'Theo dõi trong ca';
    return 'Theo dõi định kỳ';
  }

  void _patchCache(AlertItem updated) {
    if (_cached == null) return;
    final all = _cached!.allAlerts
        .map((a) => a.id == updated.id ? updated : a)
        .toList();
    if (!all.any((a) => a.id == updated.id)) all.insert(0, updated);
    _cached = applyLocalFilters(current: _cached!.copyWith(allAlerts: all));
  }

  AlertItem? _optimisticStatus(
    String alertId,
    AlertLifecycleStatus status, {
    String? userName,
    String? note,
  }) {
    final current = _cached?.allAlerts
        .where((a) => a.id == alertId)
        .firstOrNull;
    if (current == null) return null;
    final now = DateTime.now();
    final updated = current.copyWith(
      status: status,
      isUnread: false,
      severity: status == AlertLifecycleStatus.resolved
          ? AlertItemSeverity.resolved
          : current.severity,
      updatedAt: now,
      syncStatus: AlertSyncStatus.pending,
      timeline: [
        ...current.timeline,
        AlertTimelineEvent(
          id: '$alertId-$now',
          title: status.label,
          actorName: userName,
          note: note,
          at: now,
          status: status,
        ),
      ],
    );
    _patchCache(updated);
    return updated;
  }

  // ── Filter helpers ────────────────────────────────────────────────────────

  bool _inHistoryRange(AlertItem a, AlertHistoryRange range) {
    final now = DateTime.now();
    switch (range) {
      case AlertHistoryRange.today:
        return a.updatedAt.day == now.day &&
            a.updatedAt.month == now.month &&
            a.updatedAt.year == now.year;
      case AlertHistoryRange.days7:
        return a.updatedAt.isAfter(now.subtract(const Duration(days: 7)));
      case AlertHistoryRange.days30:
        return a.updatedAt.isAfter(now.subtract(const Duration(days: 30)));
      case AlertHistoryRange.custom:
        return true;
    }
  }

  bool _matchesFilters(AlertItem a, Set<AlertQuickFilter> filters) {
    for (final f in filters) {
      switch (f) {
        case AlertQuickFilter.all:
          return true;
        case AlertQuickFilter.critical:
          if (a.severity == AlertItemSeverity.critical) return true;
        case AlertQuickFilter.high:
          if (a.severity == AlertItemSeverity.high) return true;
        case AlertQuickFilter.unread:
          if (a.isUnread) return true;
        case AlertQuickFilter.inProgress:
          if (a.status == AlertLifecycleStatus.inProgress ||
              a.status == AlertLifecycleStatus.acknowledged) {
            return true;
          }
        case AlertQuickFilter.resolved:
          if (a.status == AlertLifecycleStatus.resolved) return true;
        case AlertQuickFilter.waterQuality:
          if (a.category == AlertCategory.waterQuality) return true;
        case AlertQuickFilter.crabHealth:
          if (a.category == AlertCategory.crabHealth) return true;
        case AlertQuickFilter.device:
          if (a.category == AlertCategory.device) return true;
        case AlertQuickFilter.ai:
          if (a.category == AlertCategory.ai) return true;
        case AlertQuickFilter.operations:
          if (a.category == AlertCategory.operations) return true;
        case AlertQuickFilter.system:
          if (a.category == AlertCategory.system) return true;
      }
    }
    return false;
  }

  List<AlertItem> _sort(List<AlertItem> list, AlertSortOption sort) {
    final copy = List<AlertItem>.from(list);
    switch (sort) {
      case AlertSortOption.priorityDesc:
        copy.sort((a, b) => b.priority.score.compareTo(a.priority.score));
      case AlertSortOption.newest:
        copy.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      case AlertSortOption.oldest:
        copy.sort((a, b) => a.detectedAt.compareTo(b.detectedAt));
      case AlertSortOption.severity:
        copy.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    }
    return copy;
  }

  AlertSeveritySummary _buildSummary(List<AlertItem> all) {
    final now = DateTime.now();
    var critical = 0, high = 0, medium = 0, low = 0;
    var acknowledged = 0, resolvedToday = 0, unread = 0, open = 0;

    for (final a in all) {
      if (_hiddenIds.contains(a.id)) continue;
      if (a.isUnread) unread++;
      if (a.status.isOpen) open++;
      if (a.status == AlertLifecycleStatus.acknowledged) acknowledged++;
      if (a.status == AlertLifecycleStatus.resolved &&
          a.updatedAt.day == now.day &&
          a.updatedAt.month == now.month &&
          a.updatedAt.year == now.year) {
        resolvedToday++;
      }
      if (!a.status.isOpen) continue;
      switch (a.severity) {
        case AlertItemSeverity.critical:
          critical++;
        case AlertItemSeverity.high:
          high++;
        case AlertItemSeverity.medium:
          medium++;
        case AlertItemSeverity.low:
          low++;
        case AlertItemSeverity.resolved:
          break;
      }
    }

    return AlertSeveritySummary(
      critical: critical,
      high: high,
      medium: medium,
      low: low,
      acknowledged: acknowledged,
      resolvedToday: resolvedToday,
      unread: unread,
      open: open,
    );
  }

  AlertItem? _pickPriority(List<AlertItem> list) {
    final candidates = list.where((a) => a.isPriorityHero).toList()
      ..sort((a, b) => b.priority.score.compareTo(a.priority.score));
    return candidates.isEmpty ? null : candidates.first;
  }

  List<AlertGroupedSection> _group(List<AlertItem> list, AlertGroupBy groupBy) {
    if (groupBy == AlertGroupBy.none) {
      return [AlertGroupedSection(title: 'Tất cả', items: list)];
    }

    final map = <String, List<AlertItem>>{};
    for (final a in list) {
      final key = switch (groupBy) {
        AlertGroupBy.severity => a.severity.label,
        AlertGroupBy.category => a.category.label,
        AlertGroupBy.status => a.status.label,
        AlertGroupBy.box => a.locationLabel,
        AlertGroupBy.date => _dateBucket(a.detectedAt),
        AlertGroupBy.none => 'Tất cả',
      };
      map.putIfAbsent(key, () => []).add(a);
    }

    if (groupBy == AlertGroupBy.severity) {
      const order = ['Nghiêm trọng', 'Cao', 'Trung bình', 'Thấp', 'Đã giải quyết'];
      return order
          .where(map.containsKey)
          .map((k) => AlertGroupedSection(title: k, items: map[k]!))
          .toList();
    }

    return map.entries
        .map((e) => AlertGroupedSection(title: e.key, items: e.value))
        .toList();
  }

  String _dateBucket(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return 'Cũ hơn';
  }

  List<dynamic>? _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final map = _asMap(raw);
      if (map == null) return null;
      final data = map['data'];
      if (data is List) return data;
      if (data is Map) {
        final inner = _asMap(data);
        if (inner?['items'] is List) return inner!['items'] as List;
        if (inner?['data'] is List) return inner!['data'] as List;
      }
      if (map['items'] is List) return map['items'] as List;
    }
    return null;
  }

  dynamic _unwrapData(dynamic raw) {
    if (raw is Map) {
      final map = _asMap(raw);
      if (map != null && map.containsKey('data')) return map['data'];
    }
    return raw;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}

class _PendingOp {
  const _PendingOp({
    required this.type,
    required this.alertId,
    required this.payload,
  });

  final String type;
  final String alertId;
  final Map<String, dynamic> payload;
}
