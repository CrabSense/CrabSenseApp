import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../water_quality/data/repositories/scoped_history_service.dart';
import '../../domain/models/boxes_models.dart';
import '../../domain/repositories/boxes_repository.dart';

/// Production Boxes repository — uses GET /boxes/overview (no mock enrichment).
class BoxesRepositoryImpl implements BoxesRepository {
  BoxesRepositoryImpl({required ApiClient api,
    required Future<HistoryIdentity> Function() identity,
    required int Function() revision,
    required bool Function(String) boundUser,
    required Future<bool> Function() networkAvailable,
  }) : _api = api, _identity = identity, _revision = revision,
       _boundUser = boundUser, _networkAvailable = networkAvailable;

  final Future<HistoryIdentity> Function() _identity;
  final int Function() _revision;
  final bool Function(String) _boundUser;
  final Future<bool> Function() _networkAvailable;
  int _generation = 0;
  String? _selectedAreaId;

  void invalidate() {
    ++_generation;
    _selectedAreaId = null;
    _recentSearches.clear();
  }

  Future<void> _verify(int generation, int revision, HistoryIdentity identity) async {
    if (generation != _generation || revision != _revision() ||
        !_boundUser(identity.userId) || !await _networkAvailable()) {
      throw StateError('Boxes session or network changed');
    }
    final current = await _identity();
    if (generation != _generation || revision != _revision() ||
        !_boundUser(identity.userId) || !identity.matches(current)) {
      throw StateError('Boxes session changed');
    }
  }

  Options _pinned(HistoryIdentity identity) => Options(
    followRedirects: false,
    validateStatus: (status) => status == 200,
    headers: {'Authorization': 'Bearer ${identity.accessToken}'},
    extra: const {'skipAuthInterceptor': true, 'skipTokenRefresh': true,
      'skipSensitiveLogging': true},
  );

  final ApiClient _api;

  /// Box Hive nhỏ cho lựa chọn UI (mở lazily, không cần sửa main.dart).
  static const _uiPrefsBox = 'ui_prefs';
  static const _layoutOrderKey = 'boxLayoutOrder';

  BoxesViewMode _viewMode = BoxesViewMode.grid;
  BoxLayoutOrder _layoutOrder = BoxLayoutOrder.rowLtr;
  bool _layoutOrderLoaded = false;
  final List<String> _recentSearches = [];

  @override
  BoxesViewMode get savedViewMode => _viewMode;

  @override
  Future<void> saveViewMode(BoxesViewMode mode) async {
    _viewMode = mode;
  }

  @override
  BoxLayoutOrder get savedBoxLayoutOrder => _layoutOrder;

  /// Đọc hướng đánh số đã lưu. Không có/lỗi → mặc định trái→phải.
  Future<void> _loadLayoutOrder() async {
    if (_layoutOrderLoaded) return;
    _layoutOrderLoaded = true;
    try {
      final box = await Hive.openBox<dynamic>(_uiPrefsBox);
      final saved = box.get(_layoutOrderKey);
      _layoutOrder = BoxLayoutOrder.values.firstWhere(
        (o) => o.name == saved,
        orElse: () => BoxLayoutOrder.rowLtr,
      );
    } catch (_) {
      // ponytail: Hive chưa sẵn sàng thì dùng mặc định, không chặn tải hộp.
    }
  }

  @override
  Future<void> saveBoxLayoutOrder(BoxLayoutOrder order) async {
    _layoutOrder = order;
    try {
      final box = await Hive.openBox<dynamic>(_uiPrefsBox);
      await box.put(_layoutOrderKey, order.name);
    } catch (_) {
      // ponytail: không ghi được thì chỉ mất lựa chọn sau khi mở lại app.
    }
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

  Future<BoxesStateData> _reload() => getBoxesSummary(
    farmingAreaId: _selectedAreaId,
    forceRefresh: true,
    viewMode: _viewMode,
  );

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
    // No previous snapshot may authorize a new request or survive a failure.
    final generation = ++_generation;
    final revision = _revision();
    _selectedAreaId = null;
    if (!await _networkAvailable()) throw StateError('Boxes unavailable offline');
    final identity = await _identity();
    await _verify(generation, revision, identity);
    await _loadLayoutOrder();
    await _verify(generation, revision, identity);
    final farms = await _fetchFarms(identity);
    await _verify(generation, revision, identity);
    // A stored selection may belong to a previous account or revoked area.
    // Select only an area present in the freshly authorized inventory.
    final selected = farms.where((f) =>
        f.id.toLowerCase() == farmingAreaId?.toLowerCase()).firstOrNull
        ?? farms.firstOrNull;
    final areaId = selected?.id;
    final overview = areaId == null
        ? const _OverviewPayload(boxes: [], summary: FarmBoxesOverview.empty)
        : await _fetchOverview(areaId, identity);
    await _verify(generation, revision, identity);
    final boxes = overview.boxes;
    final base = BoxesStateData(
      selectedFarmId: areaId,
      selectedFarmName: selected?.name ?? 'Chưa có khu được phân công',
      availableFarms: List.unmodifiable(farms),
      availableAreas: boxes.map((b) => b.location.areaName).toSet().toList()..sort(),
      allBoxes: List.unmodifiable(boxes),
      visibleBoxes: List.unmodifiable(boxes),
      overview: overview.summary,
      searchQuery: searchQuery,
      quickFilters: quickFilters.isEmpty ? {BoxQuickFilter.all} : quickFilters,
      advancedFilter: advancedFilter,
      viewMode: _viewMode,
      boxLayoutOrder: _layoutOrder,
      isOnline: true,
      isOfflineCached: false,
      lastSyncedAt: overview.syncedAt,
      recentSearches: List.unmodifiable(_recentSearches),
      canCreateBox: canCreateBox,
      canEditBox: canEditBox,
      canPerformActions: canPerformActions,
    );
    _selectedAreaId = areaId;
    return applyLocalFilters(current: base, searchQuery: searchQuery,
      quickFilters: quickFilters, advancedFilter: advancedFilter);
  }

  @override
  Future<BoxesStateData> switchFarm(String farmId) => getBoxesSummary(
    farmingAreaId: farmId, forceRefresh: true, viewMode: _viewMode,
  );

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
            case BoxQuickFilter.normal:
              return b.status == BoxStatus.normal && b.crabCount > 0;
            case BoxQuickFilter.watch:
              return b.status == BoxStatus.watch;
            case BoxQuickFilter.molting:
              return b.status == BoxStatus.molting;
            case BoxQuickFilter.alert:
              return b.status == BoxStatus.alert;
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
      list = list.where((b) => b.devices.verifiedOnline == false).toList();
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

  Future<List<FarmAreaOption>> _fetchFarms(HistoryIdentity identity) async {
    final res = await _api.get(ApiConstants.farmingAreas,
      queryParameters: const {'page': 1, 'pageSize': 200},
      options: _pinned(identity));
    final root = _asMap(res.data);
    if (root?['success'] != true) throw const FormatException('Invalid areas envelope');
    final list = _extractList(root!['data']);
    if (list == null) throw const FormatException('Invalid areas inventory');
    final farms = <FarmAreaOption>[];
    final seen = <String>{};
    for (final item in list) {
      final map = _asMap(item);
      final id = map?['id']?.toString().trim() ?? '';
      if (id.isEmpty || !seen.add(id.toLowerCase())) {
        throw const FormatException('Invalid area identity');
      }
      final name = (map?['name'] ?? map?['code'])?.toString().trim();
      farms.add(FarmAreaOption(id: id,
        name: name == null || name.isEmpty ? 'Khu nuôi' : name));
    }
    return farms;
  }

  Future<_OverviewPayload> _fetchOverview(String areaId, HistoryIdentity identity) async {
    final res = await _api.get(ApiConstants.boxesOverview,
      queryParameters: {'farmingAreaId': areaId}, options: _pinned(identity));
    final root = _asMap(res.data);
    final payload = _asMap(root?['data']);
    if (root?['success'] != true || payload == null ||
        payload['farmingAreaId']?.toString().toLowerCase() != areaId.toLowerCase() ||
        payload['items'] is! List) {
      throw const FormatException('Invalid scoped boxes envelope');
    }
    final boxes = <BoxSummary>[];
    final ids = <String>{};
    for (final item in payload['items'] as List) {
      final map = _asMap(item);
      if (map == null || map['farmingAreaId']?.toString().toLowerCase() != areaId.toLowerCase()) {
        throw const FormatException('Box outside selected area');
      }
      final box = _mapOverviewItem(map);
      if (box == null || box.id.isEmpty || !ids.add(box.id.toLowerCase())) {
        throw const FormatException('Invalid box identity');
      }
      boxes.add(box);
    }
    final summary = _asMap(payload['summary']);
    if (summary?['total'] != boxes.length) {
      throw const FormatException('Incomplete boxes response');
    }
    final syncedAt = DateTime.tryParse(payload['syncedAt']?.toString() ?? '');
    if (syncedAt == null) throw const FormatException('Missing boxes sync timestamp');
    return _OverviewPayload(boxes: boxes, summary: FarmBoxesOverview.fromBoxes(boxes),
      syncedAt: syncedAt);
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
    final crabCondition = map['crabCondition']?.toString();
    // Trạng thái hộp suy như desktop: ưu tiên tình trạng xấu nhất của cua trong
    // hộp, chỉ khi hộp không còn cua sống mới xét `status` của BE.
    final status = _boxStatus(
      apiStatus: map['status']?.toString(),
      crabCount: crabCount,
      crabCondition: crabCondition,
    );
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
      status: status,
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
      devices: BoxDeviceStatus.fromApi(devicesMap),
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

  /// Trạng thái hộp — suy đúng như `toFarmMapBox` bên desktop: hộp đang có cua
  /// thì lấy tình trạng XẤU NHẤT của cua trong hộp, chỉ khi hộp không còn cua
  /// sống mới xét `status` do BE trả.
  ///
  /// Trước đây mobile suy từ `healthStatus` + `apiStatus`, mà BE trả status
  /// `active` cho mọi hộp đang nuôi nên hộp nào cũng ra "Healthy" — lưới cùng
  /// một màu và nhãn lệch hẳn với desktop.
  BoxStatus _boxStatus({
    required String? apiStatus,
    required int crabCount,
    String? crabCondition,
  }) {
    if (crabCount <= 0) {
      // Hộp không còn cua sống ⇒ coi như trống, nhưng giữ tín hiệu bảo trì /
      // cảnh báo mà BE đánh dấu trên chính hộp đó.
      final api = boxStatusFromApi(apiStatus);
      return (api == BoxStatus.watch || api == BoxStatus.alert)
          ? api
          : BoxStatus.empty;
    }
    return boxStatusFromCrabCondition(crabCondition);
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
    this.syncedAt,
  });

  final List<BoxSummary> boxes;
  final FarmBoxesOverview summary;
  final DateTime? syncedAt;
}
