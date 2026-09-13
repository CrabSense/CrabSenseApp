import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/boxes_models.dart';
import '../../domain/repositories/boxes_repository.dart';

/// Production Boxes repository — uses GET /boxes/overview (no mock enrichment).
class BoxesRepositoryImpl implements BoxesRepository {
  BoxesRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  BoxesStateData? _cached;
  BoxesViewMode _viewMode = BoxesViewMode.grid;
  BoxLayoutOrder _layoutOrder = BoxLayoutOrder.rowLtr;
  final List<String> _recentSearches = [];

  @override
  BoxesViewMode get savedViewMode => _viewMode;

  @override
  Future<void> saveViewMode(BoxesViewMode mode) async {
    _viewMode = mode;
  }

  @override
  BoxLayoutOrder get savedBoxLayoutOrder => _layoutOrder;

  @override
  Future<void> saveBoxLayoutOrder(BoxLayoutOrder order) async {
    _layoutOrder = order;
  }

  @override
  Future<BoxesStateData> createBox({
    required String farmingRowId,
    String? code,
  }) async {
    await _api.post(
      ApiConstants.boxes,
      data: {
        'farmingRowId': farmingRowId,
        if (code != null && code.isNotEmpty) 'code': code,
      },
    );
    return _reload();
  }

  Future<BoxesStateData> _reload() {
    return getBoxesSummary(
      farmingAreaId: _cached?.selectedFarmId,
      forceRefresh: true,
      viewMode: _cached?.viewMode ?? _viewMode,
      searchQuery: _cached?.searchQuery ?? '',
      quickFilters: _cached?.quickFilters ?? {BoxQuickFilter.all},
      advancedFilter: _cached?.advancedFilter ?? BoxFilterState.initial,
      canCreateBox: _cached?.canCreateBox ?? false,
      canEditBox: _cached?.canEditBox ?? false,
      canPerformActions: _cached?.canPerformActions ?? false,
    );
  }

  @override
  Future<BoxesStateData> updateBox({
    required String id,
    required String code,
    String? status,
    required bool isOccupied,
  }) async {
    await _api.put(
      ApiConstants.boxDetails(id),
      data: {
        'code': code,
        if (status != null) 'status': status,
        'isOccupied': isOccupied,
      },
    );
    return _reload();
  }

  @override
  Future<BoxesStateData> deleteBox(String id) async {
    await _api.delete(ApiConstants.boxDetails(id));
    return _reload();
  }

  @override
  Future<BoxesStateData> createArea({required String name, String? description}) async {
    await _api.post(
      ApiConstants.farmingAreas,
      data: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
    return _reload();
  }

  @override
  Future<BoxesStateData> updateArea({
    required String id,
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    await _api.put(
      ApiConstants.farmDetails(id),
      data: {
        'name': name,
        'description': description,
        'isActive': isActive,
      },
    );
    return _reload();
  }

  @override
  Future<BoxesStateData> deleteArea(String id, {bool cascade = false}) async {
    await _api.delete(
      ApiConstants.farmDetails(id),
      queryParameters: cascade ? const {'cascade': true} : null,
    );
    return _reload();
  }

  @override
  Future<BoxesStateData> createRow({
    required String farmingAreaId,
    required String name,
    required int capacity,
  }) async {
    await _api.post(
      ApiConstants.farmingRows,
      data: {
        'farmingAreaId': farmingAreaId,
        'name': name,
        'capacity': capacity,
      },
    );
    return _reload();
  }

  @override
  Future<BoxesStateData> updateRow({
    required String id,
    required String name,
    required int capacity,
    bool isActive = true,
  }) async {
    await _api.put(
      ApiConstants.pondDetails(id),
      data: {
        'name': name,
        'capacity': capacity,
        'isActive': isActive,
      },
    );
    return _reload();
  }

  @override
  Future<BoxesStateData> deleteRow(String id) async {
    await _api.delete(ApiConstants.pondDetails(id));
    return _reload();
  }

  @override
  Future<List<FarmRowOption>> fetchRowDetails(String? farmingAreaId) async {
    final query = <String, dynamic>{};
    if (farmingAreaId != null && farmingAreaId.isNotEmpty) {
      query['farmingAreaId'] = farmingAreaId;
    }
    final res = await _api.get(
      ApiConstants.farmingRows,
      queryParameters: query.isEmpty ? null : query,
    );
    final list = _extractList(res.data) ?? const [];
    final rows = <FarmRowOption>[];
    for (final item in list) {
      final map = _asMap(item);
      if (map == null) continue;
      final id = map['id']?.toString();
      final name = map['name']?.toString() ?? map['code']?.toString();
      final areaId = map['farmingAreaId']?.toString();
      if (id == null || name == null || areaId == null) continue;
      rows.add(
        FarmRowOption(
          id: id,
          name: name,
          farmingAreaId: areaId,
          areaName: map['areaName']?.toString(),
          capacity: (map['capacity'] as num?)?.toInt() ?? 0,
          boxCount: (map['boxCount'] as num?)?.toInt() ?? 0,
          isActive: map['isActive'] != false,
        ),
      );
    }
    return rows;
  }

  /// Lists farming rows for [farmingAreaId] (for create-box picker).
  Future<List<({String id, String name})>> fetchRows(String? farmingAreaId) async {
    final query = <String, dynamic>{};
    if (farmingAreaId != null && farmingAreaId.isNotEmpty) {
      query['farmingAreaId'] = farmingAreaId;
    }
    final res = await _api.get(
      ApiConstants.farmingRows,
      queryParameters: query.isEmpty ? null : query,
    );
    final list = _extractList(res.data) ?? const [];
    final rows = <({String id, String name})>[];
    for (final item in list) {
      final map = _asMap(item);
      if (map == null) continue;
      final id = map['id']?.toString();
      final name = map['name']?.toString() ?? map['code']?.toString();
      if (id == null || name == null) continue;
      rows.add((id: id, name: name));
    }
    return rows;
  }

  @override
  Future<BoxesStateData> getBoxesSummary({
    String? farmingAreaId,
    bool forceRefresh = false,
    BoxesViewMode viewMode = BoxesViewMode.grid,
    String searchQuery = '',
    Set<BoxQuickFilter> quickFilters = const {BoxQuickFilter.all},
    BoxFilterState advancedFilter = BoxFilterState.initial,
    bool canCreateBox = false,
    bool canEditBox = false,
    bool canPerformActions = false,
  }) async {
    _viewMode = viewMode;

    if (_cached != null &&
        !forceRefresh &&
        (farmingAreaId == null || farmingAreaId == _cached!.selectedFarmId)) {
      return applyLocalFilters(
        current: _cached!.copyWith(
          canCreateBox: canCreateBox,
          canEditBox: canEditBox,
          canPerformActions: canPerformActions,
          viewMode: viewMode,
        ),
        searchQuery: searchQuery,
        quickFilters: quickFilters,
        advancedFilter: advancedFilter,
      );
    }

    try {
      final farms = await _fetchFarms();
      final selected = _resolveFarm(
        farms,
        farmingAreaId ?? _cached?.selectedFarmId,
      );
      final areaId = selected?.id;

      final overview = await _fetchOverview(areaId);
      final boxes = overview.boxes;
      final areas =
          boxes.map((b) => b.location.areaName).toSet().toList()..sort();

      final base = BoxesStateData(
        selectedFarmId: selected?.id ?? overview.farmingAreaId,
        selectedFarmName:
            selected?.name ?? overview.farmName ?? 'Chưa có trang trại',
        availableFarms: farms,
        availableAreas: areas,
        allBoxes: boxes,
        visibleBoxes: boxes,
        overview: overview.summary,
        searchQuery: searchQuery,
        quickFilters: quickFilters.isEmpty
            ? {BoxQuickFilter.all}
            : quickFilters,
        advancedFilter: advancedFilter,
        viewMode: _viewMode,
        boxLayoutOrder: _layoutOrder,
        isOnline: true,
        isOfflineCached: false,
        lastSyncedAt: overview.syncedAt ?? DateTime.now(),
        recentSearches: List.unmodifiable(_recentSearches),
        canCreateBox: canCreateBox,
        canEditBox: canEditBox,
        canPerformActions: canPerformActions,
      );

      final filtered = applyLocalFilters(
        current: base,
        searchQuery: searchQuery,
        quickFilters: quickFilters,
        advancedFilter: advancedFilter,
      );
      _cached = filtered;
      return filtered;
    } catch (e) {
      if (_cached != null) {
        final offline = _cached!.copyWith(
          isOnline: false,
          isOfflineCached: true,
          canCreateBox: canCreateBox,
          canEditBox: canEditBox,
          canPerformActions: canPerformActions,
          viewMode: viewMode,
          sectionError: e.toString(),
        );
        return applyLocalFilters(
          current: offline,
          searchQuery: searchQuery,
          quickFilters: quickFilters,
          advancedFilter: advancedFilter,
        );
      }
      rethrow;
    }
  }

  @override
  Future<BoxesStateData> switchFarm(String farmId) {
    return getBoxesSummary(
      farmingAreaId: farmId,
      forceRefresh: true,
      viewMode: _cached?.viewMode ?? _viewMode,
      searchQuery: _cached?.searchQuery ?? '',
      quickFilters: _cached?.quickFilters ?? {BoxQuickFilter.all},
      advancedFilter: _cached?.advancedFilter ?? BoxFilterState.initial,
      canCreateBox: _cached?.canCreateBox ?? false,
      canEditBox: _cached?.canEditBox ?? false,
      canPerformActions: _cached?.canPerformActions ?? false,
    );
  }

  @override
  BoxesStateData applyLocalFilters({
    required BoxesStateData current,
    String? searchQuery,
    Set<BoxQuickFilter>? quickFilters,
    BoxFilterState? advancedFilter,
  }) {
    final query = (searchQuery ?? current.searchQuery).trim().toLowerCase();
    final chips = quickFilters ?? current.quickFilters;
    final adv = advancedFilter ?? current.advancedFilter;

    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 8) {
        _recentSearches.removeLast();
      }
    }

    var list = List<BoxSummary>.from(current.allBoxes);

    if (query.isNotEmpty) {
      list = list.where((b) {
        return b.code.toLowerCase().contains(query) ||
            b.name.toLowerCase().contains(query) ||
            b.qrCode.toLowerCase().contains(query) ||
            b.location.areaName.toLowerCase().contains(query) ||
            (b.batch?.toLowerCase().contains(query) ?? false) ||
            (b.crabType?.toLowerCase().contains(query) ?? false) ||
            (b.location.rowName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    final effectiveChips =
        chips.contains(BoxQuickFilter.all) && chips.length == 1
        ? chips
        : chips.where((c) => c != BoxQuickFilter.all).toSet();

    if (effectiveChips.isNotEmpty &&
        !effectiveChips.contains(BoxQuickFilter.all)) {
      list = list.where((b) {
        return effectiveChips.any((chip) {
          switch (chip) {
            case BoxQuickFilter.all:
              return true;
            case BoxQuickFilter.occupied:
              return b.crabCount > 0;
            case BoxQuickFilter.empty:
              return b.crabCount <= 0;
            case BoxQuickFilter.healthy:
              return b.status == BoxHealthStatus.healthy;
            case BoxQuickFilter.warning:
              return b.status == BoxHealthStatus.warning;
            case BoxQuickFilter.critical:
              return b.status == BoxHealthStatus.critical;
            case BoxQuickFilter.offline:
              return b.status == BoxHealthStatus.offline;
            case BoxQuickFilter.hasAlert:
              return b.alerts.hasAlerts;
            case BoxQuickFilter.hasAiRecommendation:
              return b.aiRecommendation.hasRecommendation;
            case BoxQuickFilter.nearHarvest:
              return b.isNearHarvest;
          }
        });
      }).toList();
    }

    if (adv.statuses.isNotEmpty) {
      list = list.where((b) => adv.statuses.contains(b.status)).toList();
    }
    if (adv.areaId != null && adv.areaId!.isNotEmpty) {
      list = list
          .where(
            (b) =>
                b.location.areaId == adv.areaId ||
                b.location.areaName == adv.areaId,
          )
          .toList();
    }
    if (adv.crabType != null && adv.crabType!.isNotEmpty) {
      list = list
          .where(
            (b) => (b.crabType ?? '').toLowerCase().contains(
              adv.crabType!.toLowerCase(),
            ),
          )
          .toList();
    }
    if (adv.batch != null && adv.batch!.isNotEmpty) {
      list = list
          .where(
            (b) =>
                (b.batch ?? '').toLowerCase().contains(adv.batch!.toLowerCase()),
          )
          .toList();
    }
    list = list.where((b) {
      final s = b.healthScore.score.toDouble();
      final c = b.healthScore.aiConfidence;
      if (s < adv.healthScoreRange.start || s > adv.healthScoreRange.end) {
        return false;
      }
      if (c < adv.aiConfidenceRange.start || c > adv.aiConfidenceRange.end) {
        return false;
      }
      return true;
    }).toList();

    if (adv.hasAlerts == true) {
      list = list.where((b) => b.alerts.hasAlerts).toList();
    }
    if (adv.deviceOffline == true) {
      list = list.where((b) => !b.devices.isOnline).toList();
    }
    if (adv.hasAiRecommendation == true) {
      list = list.where((b) => b.aiRecommendation.hasRecommendation).toList();
    }
    if (adv.waterTestDue == true) {
      list = list.where((b) => b.waterTestDue).toList();
    }
    if (adv.videoDue == true) {
      list = list.where((b) => b.videoDue).toList();
    }
    if (adv.nearHarvest == true) {
      list = list.where((b) => b.isNearHarvest).toList();
    }
    if (adv.priority != null) {
      list = list.where((b) => b.priority == adv.priority).toList();
    }

    list = _sortBoxes(list, adv.sortOption);

    return current.copyWith(
      searchQuery: query,
      quickFilters: chips.isEmpty ? {BoxQuickFilter.all} : chips,
      advancedFilter: adv,
      visibleBoxes: list,
      overview: FarmBoxesOverview.fromBoxes(current.allBoxes),
      recentSearches: List.unmodifiable(_recentSearches),
      clearSectionError: true,
    );
  }

  List<BoxSummary> _sortBoxes(List<BoxSummary> list, BoxSortOption sort) {
    final sorted = List<BoxSummary>.from(list);
    switch (sort) {
      case BoxSortOption.name:
        sorted.sort((a, b) => a.code.compareTo(b.code));
      case BoxSortOption.lowestHealth:
        sorted.sort((a, b) => a.healthScore.score.compareTo(b.healthScore.score));
      case BoxSortOption.latestAlert:
        sorted.sort((a, b) {
          final at =
              a.alerts.latestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt =
              b.alerts.latestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
      case BoxSortOption.aiPriority:
        sorted.sort((a, b) => a.priority.index.compareTo(b.priority.index));
      case BoxSortOption.harvestDate:
        sorted.sort((a, b) {
          final at = a.expectedHarvestAt ?? DateTime(2099);
          final bt = b.expectedHarvestAt ?? DateTime(2099);
          return at.compareTo(bt);
        });
      case BoxSortOption.lastUpdated:
        sorted.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    }
    return sorted;
  }

  FarmAreaOption? _resolveFarm(List<FarmAreaOption> farms, String? preferredId) {
    if (farms.isEmpty) return null;
    if (preferredId != null) {
      for (final f in farms) {
        if (f.id == preferredId) return f;
      }
    }
    return farms.first;
  }

  Future<List<FarmAreaOption>> _fetchFarms() async {
    final res = await _api.get(
      ApiConstants.farmingAreas,
      queryParameters: const {'page': 1, 'pageSize': 200},
    );
    if (res.statusCode == 200 && res.data != null) {
      final list = _extractList(res.data);
      if (list != null) {
        final farms = <FarmAreaOption>[];
        for (final item in list) {
          final map = _asMap(item);
          if (map == null) continue;
          final id = map['id']?.toString();
          final name = map['name']?.toString() ?? map['code']?.toString();
          if (id == null || name == null) continue;
          farms.add(FarmAreaOption(id: id, name: name));
        }
        return farms;
      }
    }
    return const [];
  }

  Future<_OverviewPayload> _fetchOverview(String? farmingAreaId) async {
    final query = <String, dynamic>{};
    if (farmingAreaId != null && farmingAreaId.isNotEmpty) {
      query['farmingAreaId'] = farmingAreaId;
    }

    try {
      final res = await _api.get(
        ApiConstants.boxesOverview,
        queryParameters: query.isEmpty ? null : query,
      );
      if (res.statusCode == 200 && res.data != null) {
        return _parseOverview(res.data);
      }
    } on DioException catch (e) {
      // Older backends without /overview — compose from farming-status + IoT.
      if (e.response?.statusCode == 404) {
        return _fetchOverviewFallback(farmingAreaId);
      }
      rethrow;
    }

    return _fetchOverviewFallback(farmingAreaId);
  }

  Future<_OverviewPayload> _fetchOverviewFallback(String? farmingAreaId) async {
    final query = <String, dynamic>{};
    if (farmingAreaId != null && farmingAreaId.isNotEmpty) {
      query['farmingAreaId'] = farmingAreaId;
    }

    final results = await Future.wait([
      _api.get(
        ApiConstants.boxesFarmingStatus,
        queryParameters: query.isEmpty ? null : query,
      ),
      _api.get(
        ApiConstants.waterQualityLatest,
        queryParameters: query.isEmpty ? null : query,
      ),
      _api.get(
        ApiConstants.alerts,
        queryParameters: {
          'activeOnly': true,
          if (farmingAreaId != null && farmingAreaId.isNotEmpty)
            'farmingAreaId': farmingAreaId,
        },
      ),
      _api.get(
        ApiConstants.devices,
        queryParameters: query.isEmpty ? null : query,
      ),
    ]);

    final statusList = _extractList(results[0].data) ?? const [];
    final liveList = _extractList(results[1].data) ?? const [];
    final alertList = _extractList(results[2].data) ?? const [];
    final deviceList = _extractList(results[3].data) ?? const [];

    final water = _waterFromLive(liveList);
    final devices = _devicesFromList(deviceList);
    final openAlerts = alertList.length;

    final boxes = <BoxSummary>[];
    var idx = 0;
    for (final item in statusList) {
      final map = _asMap(item);
      if (map == null) continue;
      final id = map['boxId']?.toString() ?? map['id']?.toString();
      final code = map['code']?.toString();
      if (id == null || code == null) continue;

      final areaId =
          map['farmingAreaId']?.toString() ?? farmingAreaId ?? '';
      final areaName = map['areaName']?.toString() ?? 'Khu nuôi';
      final rowName = map['rowName']?.toString();
      final apiStatus = map['status']?.toString();
      final occupied = map['isOccupied'] == true;
        final crabCount = (map['currentCrabCount'] as num?)?.toInt() ??
          (map['crabCount'] as num?)?.toInt() ??
          (map['currentCrabId'] != null ? 1 : 0);

      final healthStatus = _statusFromApi(apiStatus, devices.isOnline);
      final score = _scoreFromStatus(healthStatus, openAlerts, devices);
      final trend = BoxTrend.stable;

      boxes.add(
        BoxSummary(
          id: id,
          code: code,
          name: code,
          qrCode: code,
          farmId: areaId,
          farmName: areaName,
          location: BoxMapLocation(
            gridX: (idx % 6) + 0.5,
            gridY: (idx ~/ 6) + 0.5,
            areaName: areaName,
            areaId: areaId,
            rowName: rowName,
          ),
          status: healthStatus,
          healthScore: BoxHealthScore.fromScore(
            score,
            devices.totalCount == 0 ? 70 : 75.0 + devices.onlineCount * 5,
            trend,
          ),
          crabCount: crabCount,
          crabType: map['currentMoltingStage']?.toString(),
          batch: map['currentCrabTag']?.toString(),
          water: water,
          devices: devices,
          alerts: openAlerts > 0 && occupied
              ? BoxAlertSummary(
                  count: healthStatus == BoxHealthStatus.critical
                      ? openAlerts.clamp(1, 3)
                      : 1,
                  latestTitle: 'Cảnh báo khu nuôi',
                  latestAt: DateTime.now(),
                )
              : BoxAlertSummary.none,
          aiRecommendation: healthStatus == BoxHealthStatus.healthy
              ? BoxAIRecommendation.none
              : BoxAIRecommendation(
                  hasRecommendation: true,
                  title: healthStatus == BoxHealthStatus.critical
                      ? 'Ưu tiên kiểm tra nước'
                      : 'Theo dõi box $code',
                  description: 'Dựa trên trạng thái farming + cảnh báo khu',
                  priority: healthStatus == BoxHealthStatus.critical
                      ? ActionPriorityLevel.high
                      : ActionPriorityLevel.medium,
                ),
          lastUpdated: DateTime.now(),
          expectedHarvestAt: apiStatus?.toLowerCase() == 'molting'
              ? DateTime.now().add(const Duration(hours: 6))
              : null,
          waterTestDue: water.temperature == null && water.ph == null,
          videoDue: apiStatus?.toLowerCase() == 'molting',
          syncStatus: BoxSyncStatus.synced,
          priority: healthStatus == BoxHealthStatus.critical
              ? ActionPriorityLevel.high
              : ActionPriorityLevel.low,
        ),
      );
      idx++;
    }

    return _OverviewPayload(
      farmingAreaId: farmingAreaId,
      farmName: boxes.isNotEmpty ? boxes.first.farmName : null,
      boxes: boxes,
      summary: FarmBoxesOverview.fromBoxes(boxes),
      syncedAt: DateTime.now(),
    );
  }

  _OverviewPayload _parseOverview(dynamic data) {
    final root = _asMap(data);
    final payload = _asMap(root?['data']) ?? root;
    if (payload == null) {
      return const _OverviewPayload(boxes: [], summary: FarmBoxesOverview.empty);
    }

    final summaryMap = _asMap(payload['summary']);
    final items = payload['items'] is List ? payload['items'] as List : const [];
    final boxes = <BoxSummary>[];

    for (final item in items) {
      final map = _asMap(item);
      if (map == null) continue;
      try {
        final box = _mapOverviewItem(map);
        if (box != null) boxes.add(box);
      } catch (_) {
        // Skip malformed items so one bad box doesn't blank the whole tab.
      }
    }

    final summary = summaryMap != null
        ? FarmBoxesOverview(
            total: (summaryMap['total'] as num?)?.toInt() ?? boxes.length,
            healthy: (summaryMap['healthy'] as num?)?.toInt() ?? 0,
            warning: (summaryMap['warning'] as num?)?.toInt() ?? 0,
            critical: (summaryMap['critical'] as num?)?.toInt() ?? 0,
            offline: (summaryMap['offline'] as num?)?.toInt() ?? 0,
            withAiRecommendation:
                (summaryMap['withAiRecommendation'] as num?)?.toInt() ?? 0,
          )
        : FarmBoxesOverview.fromBoxes(boxes);

    return _OverviewPayload(
      farmingAreaId: payload['farmingAreaId']?.toString(),
      farmName: payload['farmName']?.toString(),
      boxes: boxes,
      summary: summary,
      syncedAt: DateTime.tryParse(payload['syncedAt']?.toString() ?? ''),
    );
  }

  BoxSummary? _mapOverviewItem(Map<String, dynamic> map) {
    final id = map['id']?.toString();
    final code = map['code']?.toString();
    if (id == null || code == null) return null;

    final healthMap = _asMap(map['health']);
    final waterMap = _asMap(map['water']);
    final devicesMap = _asMap(map['devices']);
    final layoutMap = _asMap(map['layout']);
    final aiMap = _asMap(map['aiRecommendation']);

    final score = (healthMap?['score'] as num?)?.toInt() ?? 70;
    final confidence =
        (healthMap?['aiConfidence'] as num?)?.toDouble() ?? 75;
    final trendStr = healthMap?['trend']?.toString().toLowerCase() ?? 'stable';
    final trend = switch (trendStr) {
      'improving' => BoxTrend.improving,
      'declining' => BoxTrend.declining,
      _ => BoxTrend.stable,
    };

    final crabCount = (map['crabCount'] as num?)?.toInt() ?? 0;
    final healthStatus = crabCount == 0
      ? BoxHealthStatus.healthy
      : _parseHealthStatus(map['healthStatus']?.toString());
    final priorityStr = map['priority']?.toString().toLowerCase() ?? 'low';
    final priority = switch (priorityStr) {
      'high' => ActionPriorityLevel.high,
      'medium' => ActionPriorityLevel.medium,
      _ => ActionPriorityLevel.low,
    };

    final hasAi = aiMap?['hasRecommendation'] == true;
    final alertCount = (map['alertCount'] as num?)?.toInt() ?? 0;

    return BoxSummary(
      id: id,
      code: code,
      name: map['name']?.toString() ?? code,
      qrCode: map['qrCode']?.toString() ?? code,
      farmId: map['farmingAreaId']?.toString() ?? '',
      farmName: map['farmName']?.toString() ??
          map['areaName']?.toString() ??
          'Trang trại',
      location: BoxMapLocation(
        gridX: (layoutMap?['gridX'] as num?)?.toDouble() ?? 0.5,
        gridY: (layoutMap?['gridY'] as num?)?.toDouble() ?? 0.5,
        areaName: map['areaName']?.toString() ?? 'Khu nuôi',
        areaId: map['farmingAreaId']?.toString() ?? '',
        rowName: map['rowName']?.toString(),
      ),
      status: healthStatus,
      healthScore: BoxHealthScore(
        score: score,
        aiConfidence: confidence,
        trend: trend,
        statusLabel: healthMap?['statusLabel']?.toString() ??
            BoxHealthScore.fromScore(score, confidence, trend).statusLabel,
        explanation: healthMap?['explanation']?.toString() ??
            'Điểm sức khỏe tổng hợp từ nước, cua và thiết bị.',
      ),
      crabCount: crabCount,
      crabType: map['crabType']?.toString(),
      batch: map['batch']?.toString(),
      crabCondition: map['crabCondition']?.toString(),
      water: BoxWaterSnapshot(
        temperature: (waterMap?['temperature'] as num?)?.toDouble(),
        ph: (waterMap?['ph'] as num?)?.toDouble(),
        dissolvedOxygen: (waterMap?['dissolvedOxygen'] as num?)?.toDouble(),
      ),
      devices: BoxDeviceStatus(
        isOnline: devicesMap?['isOnline'] == true,
        onlineCount: (devicesMap?['onlineCount'] as num?)?.toInt() ?? 0,
        totalCount: (devicesMap?['totalCount'] as num?)?.toInt() ?? 0,
      ),
      alerts: alertCount > 0
          ? BoxAlertSummary(
              count: alertCount,
              latestTitle: map['latestAlertTitle']?.toString(),
              latestAt: DateTime.tryParse(
                map['latestAlertAt']?.toString() ?? '',
              ),
            )
          : BoxAlertSummary.none,
      aiRecommendation: hasAi
          ? BoxAIRecommendation(
              hasRecommendation: true,
              title: aiMap?['title']?.toString(),
              description: aiMap?['description']?.toString(),
              priority: switch (aiMap?['priority']?.toString().toLowerCase()) {
                'high' => ActionPriorityLevel.high,
                'medium' => ActionPriorityLevel.medium,
                _ => ActionPriorityLevel.low,
              },
            )
          : BoxAIRecommendation.none,
      lastUpdated:
          DateTime.tryParse(map['lastUpdated']?.toString() ?? '') ??
          DateTime.now(),
      expectedHarvestAt: DateTime.tryParse(
        map['expectedHarvestAt']?.toString() ?? '',
      ),
      waterTestDue: map['waterTestDue'] == true,
      videoDue: map['videoDue'] == true,
      syncStatus: BoxSyncStatus.synced,
      priority: priority,
    );
  }

  BoxWaterSnapshot _waterFromLive(List liveList) {
    double? temp, ph, dout;
    for (final item in liveList) {
      final map = _asMap(item);
      if (map == null) continue;
      final type = (map['sensorType'] ?? map['type'] ?? '')
          .toString()
          .toLowerCase();
      final raw = map['latestValue'] ?? map['value'] ?? map['currentValue'];
      final val = raw is num ? raw.toDouble() : double.tryParse('$raw');
      if (val == null) continue;
      if (type.contains('temp') || type.contains('nhiệt')) temp = val;
      if (type == 'ph' || type.contains('ph')) ph = val;
      if (type == 'do' || type.contains('dissolved') || type.contains('oxy')) {
        dout = val;
      }
    }
    return BoxWaterSnapshot(
      temperature: temp,
      ph: ph,
      dissolvedOxygen: dout,
    );
  }

  BoxDeviceStatus _devicesFromList(List deviceList) {
    if (deviceList.isEmpty) {
      return const BoxDeviceStatus(isOnline: true, onlineCount: 0, totalCount: 0);
    }
    var online = 0;
    for (final item in deviceList) {
      final map = _asMap(item);
      final st = map?['status']?.toString().toLowerCase() ?? '';
      if (st == 'online') online++;
    }
    return BoxDeviceStatus(
      isOnline: online > 0,
      onlineCount: online,
      totalCount: deviceList.length,
    );
  }

  BoxHealthStatus _parseHealthStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'warning':
        return BoxHealthStatus.warning;
      case 'critical':
        return BoxHealthStatus.critical;
      case 'offline':
        return BoxHealthStatus.offline;
      default:
        return BoxHealthStatus.healthy;
    }
  }

  BoxHealthStatus _statusFromApi(String? apiStatus, bool areaOnline) {
    final s = (apiStatus ?? '').toLowerCase();
    if (s == 'maintenance' || (!areaOnline && s.isNotEmpty)) {
      return BoxHealthStatus.offline;
    }
    if (s == 'quarantine') return BoxHealthStatus.critical;
    if (s == 'molting') return BoxHealthStatus.warning;
    return BoxHealthStatus.healthy;
  }

  int _scoreFromStatus(
    BoxHealthStatus status,
    int openAlerts,
    BoxDeviceStatus devices,
  ) {
    var score = switch (status) {
      BoxHealthStatus.healthy => 90,
      BoxHealthStatus.warning => 65,
      BoxHealthStatus.critical => 40,
      BoxHealthStatus.offline => 45,
    };
    score -= openAlerts.clamp(0, 5) * 2;
    if (devices.totalCount > 0 && !devices.isOnline) score -= 10;
    return score.clamp(0, 100);
  }

  List? _extractList(dynamic data) {
    if (data is List) return data;
    final root = _asMap(data);
    if (root == null) return null;
    final inner = _asMap(root['data']) ?? root;
    if (inner['items'] is List) return inner['items'] as List;
    if (inner['Items'] is List) return inner['Items'] as List;
    if (root['items'] is List) return root['items'] as List;
    if (root['data'] is List) return root['data'] as List;
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

class _OverviewPayload {
  const _OverviewPayload({
    required this.boxes,
    required this.summary,
    this.farmingAreaId,
    this.farmName,
    this.syncedAt,
  });

  final String? farmingAreaId;
  final String? farmName;
  final List<BoxSummary> boxes;
  final FarmBoxesOverview summary;
  final DateTime? syncedAt;
}
