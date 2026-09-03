import 'package:flutter/foundation.dart';

import '../data/mock_crab_data.dart';
import '../models/auth_models.dart';
import '../models/crab_individual.dart';
import '../models/crab_status.dart';
import '../models/production_models.dart';
import '../utils/crab_management_mapper.dart';
import 'cloud_api_client.dart';

class CrabBatchChoice {
  const CrabBatchChoice({
    required this.batchId,
    required this.batchCode,
    required this.boxCode,
    required this.label,
  });

  final String batchId;
  final String batchCode;
  final String boxCode;
  final String label;
}

class CrabService extends ChangeNotifier {
  CrabService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<CrabIndividual> _crabs = [];
  List<FarmingBatchRecord> _lots = [];
  CrabManagementSummary _summary = const CrabManagementSummary(
    total: 0,
    alive: 0,
    dead: 0,
    molting: 0,
    readyHarvest: 0,
    aliveRate: 0,
  );

  bool _loading = false;
  String? _error;

  String _searchQuery = '';
  String _areaFilter = MockCrabData.allOption;
  String _rowFilter = MockCrabData.allOption;
  String _boxFilter = MockCrabData.allOption;
  String _batchFilter = MockCrabData.allOption;
  CrabManagementStatusFilter _statusFilter = CrabManagementStatusFilter.all;

  static const _pageSize = 10;
  int _currentPage = 1;

  bool get loading => _loading;
  String? get error => _error;
  List<CrabIndividual> get crabs => List.unmodifiable(_crabs);

  String get areaFilter => _areaFilter;
  String get rowFilter => _rowFilter;
  String get boxFilter => _boxFilter;
  String get batchFilter => _batchFilter;
  CrabManagementStatusFilter get statusFilter => _statusFilter;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get displayTotal => _summary.total;

  CrabManagementSummary get summary => _summary;

  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  void updateSession(AuthSession session) {
    _session = session;
    _crabs = [];
    _lots = [];
    _summary = const CrabManagementSummary(
      total: 0,
      alive: 0,
      dead: 0,
      molting: 0,
      readyHarvest: 0,
      aliveRate: 0,
    );
    _currentPage = 1;
    notifyListeners();
  }

  List<String> get areaOptions => [
        MockCrabData.allOption,
        ..._crabs.map((c) => c.areaName).toSet(),
      ];

  List<String> get rowOptions {
    var list = _crabs;
    if (_areaFilter != MockCrabData.allOption) {
      list = list.where((c) => c.areaName == _areaFilter).toList();
    }
    return [MockCrabData.allOption, ...list.map((c) => c.rowName).toSet()];
  }

  List<String> get boxOptions {
    var list = _crabs;
    if (_areaFilter != MockCrabData.allOption) {
      list = list.where((c) => c.areaName == _areaFilter).toList();
    }
    if (_rowFilter != MockCrabData.allOption) {
      list = list.where((c) => c.rowName == _rowFilter).toList();
    }
    return [MockCrabData.allOption, ...list.map((c) => c.boxLabel).toSet()];
  }

  List<String> get batchOptions => [
        MockCrabData.allOption,
        ...{
          ..._lots.map((l) => l.batchCode),
          ..._crabs.map((c) => c.batchId),
        },
      ];

  List<CrabBatchChoice> get batchChoices {
    if (_lots.isNotEmpty) {
      final codeCount = <String, int>{};
      for (final l in _lots) {
        codeCount[l.batchCode] = (codeCount[l.batchCode] ?? 0) + 1;
      }
      final seen = <String>{};
      return [
        for (final l in _lots)
          if (seen.add(l.id))
            CrabBatchChoice(
              batchId: l.id,
              batchCode: l.batchCode,
              boxCode: l.boxCode ?? '',
              label: (codeCount[l.batchCode] ?? 0) > 1
                  ? '${l.batchCode} · ${l.id.length >= 8 ? l.id.substring(0, 8) : l.id}'
                  : (l.batchCode.isEmpty ? l.id : l.batchCode),
            ),
      ];
    }
    final seen = <String>{};
    final out = <CrabBatchChoice>[];
    for (final c in _crabs) {
      final batchId = _batchIdForCrab(c);
      if (batchId == null || seen.contains(batchId)) continue;
      seen.add(batchId);
      out.add(
        CrabBatchChoice(
          batchId: batchId,
          batchCode: c.batchId,
          boxCode: c.boxName ?? c.boxId,
          label: c.batchId,
        ),
      );
    }
    return out;
  }

  String? _batchIdForCrab(CrabIndividual c) {
    for (final item in _lastListItems) {
      if (item.id == c.id) return item.batchId;
    }
    return null;
  }

  List<CrabManagementListItem> _lastListItems = [];

  List<CrabIndividual> get filteredCrabs {
    var list = _crabs;
    if (_areaFilter != MockCrabData.allOption) {
      list = list.where((c) => c.areaName == _areaFilter).toList();
    }
    if (_rowFilter != MockCrabData.allOption) {
      list = list.where((c) => c.rowName == _rowFilter).toList();
    }
    if (_boxFilter != MockCrabData.allOption) {
      list = list.where((c) => c.boxLabel == _boxFilter).toList();
    }
    if (_batchFilter != MockCrabData.allOption) {
      list = list.where((c) => c.batchId == _batchFilter).toList();
    }
    if (_statusFilter != CrabManagementStatusFilter.all) {
      list = list.where((c) => c.matchesStatusFilter(_statusFilter)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (c) =>
                c.code.toLowerCase().contains(q) ||
                c.id.toLowerCase().contains(q) ||
                c.boxId.toLowerCase().contains(q) ||
                c.batchId.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  List<CrabIndividual> get paginatedCrabs {
    final list = filteredCrabs;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= list.length) return [];
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get filteredCount => filteredCrabs.length;

  int get totalPages => (filteredCount / _pageSize).ceil().clamp(1, 999);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.fetchFarmCrabs(token, farmId);
      try {
        _lots = await _api.fetchCrabLots(token);
      } catch (_) {
        _lots = [];
      }
      _lastListItems = result.crabs;
      _crabs = result.crabs.map(crabFromListItem).toList();
      final s = result.summary;
      _summary = CrabManagementSummary(
        total: s.total,
        alive: s.alive,
        dead: s.dead,
        molting: s.molting,
        readyHarvest: s.readyHarvest,
        aliveRate: s.total > 0 ? s.alive / s.total * 100 : 0,
      );
      _error = null;
    } on CloudApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(String crabId) async {
    try {
      final body = await _api.fetchCrabDetail(token, crabId);
      final base = getById(crabId);
      if (base == null) return;
      final merged = mergeCrabDetail(base, body);
      final i = _crabs.indexWhere((c) => c.id == crabId);
      if (i >= 0) {
        _crabs = [..._crabs]..[i] = merged;
        notifyListeners();
      }
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
  }

  void setAreaFilter(String value) {
    _areaFilter = value;
    _rowFilter = MockCrabData.allOption;
    _boxFilter = MockCrabData.allOption;
    _currentPage = 1;
    notifyListeners();
  }

  void setRowFilter(String value) {
    _rowFilter = value;
    _boxFilter = MockCrabData.allOption;
    _currentPage = 1;
    notifyListeners();
  }

  void setBoxFilter(String value) {
    _boxFilter = value;
    _currentPage = 1;
    notifyListeners();
  }

  void setBatchFilter(String value) {
    _batchFilter = value;
    _currentPage = 1;
    notifyListeners();
  }

  void setStatusFilter(CrabManagementStatusFilter value) {
    _statusFilter = value;
    _currentPage = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    _currentPage = page.clamp(1, totalPages);
    notifyListeners();
  }

  CrabIndividual? getById(String id) => MockCrabData.findById(_crabs, id);

  Future<FarmingBatchRecord?> ensureDefaultLot() async {
    try {
      if (_lots.isEmpty) {
        _lots = await _api.fetchCrabLots(token);
      }
      if (_lots.isNotEmpty) {
        notifyListeners();
        return _lots.first;
      }
      final lot = await _api.createBatch(token, farmId, startDate: DateTime.now());
      _lots = [..._lots, lot];
      notifyListeners();
      return lot;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = '$e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> generateNextCodeForBatch(String batchId) async {
    try {
      return await _api.fetchNextBatchCrabCode(token, batchId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> addCrab({
    required String batchId,
    required String crabCode,
    required CrabGender gender,
    required double weightGram,
    required double shellSizeCm,
    required CrabHealthStatus healthStatus,
    required CrabLifeStatus lifeStatus,
    required CrabDevelopmentStage developmentStage,
    String? note,
  }) async {
    try {
      await _api.createBatchCrabExtended(
        token,
        batchId,
        crabCode: crabCode,
        gender: genderToApi(gender),
        weight: weightGram,
        shellWidth: shellSizeCm,
        status: lifeStatusToApi(lifeStatus),
        healthStatus: healthStatusToApi(healthStatus),
        growthStage: growthStageToApi(developmentStage),
        profileNote: note,
        farmingAreaId: farmId,
      );
      await load();
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCrab(CrabIndividual crab) async {
    try {
      await _api.updateBatchCrabExtended(
        token,
        crab.id,
        crabCode: crab.code,
        gender: genderToApi(crab.gender),
        weight: crab.weightGram,
        shellWidth: crab.shellSizeCm,
        status: lifeStatusToApi(crab.lifeStatus),
        healthStatus: healthStatusToApi(crab.healthStatus),
        growthStage: growthStageToApi(crab.developmentStage),
        profileNote: crab.quickNote.isEmpty ? null : crab.quickNote,
        moltCount: crab.moltCount,
      );
      await load();
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCrab(String id) async {
    try {
      await _api.deleteBatchCrab(token, id);
      await load();
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordHealth(
    String id, {
    required double weightGram,
    required double shellSizeCm,
    required String shellCondition,
    required String diseaseNote,
    String? note,
    required DateTime recordedAt,
  }) async {
    try {
      await _api.recordCrabHealth(
        token,
        id,
        weight: weightGram,
        shellWidth: shellSizeCm,
        shellStatus: shellCondition,
        diseaseStatus: diseaseNote,
        recordedAt: recordedAt,
      );
      await load();
      await loadDetail(id);
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordMolt(
    String id, {
    required DateTime date,
    required int moltCount,
    required MoltCondition condition,
    String? note,
  }) async {
    try {
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      await _api.recordCrabMolt(
        token,
        id,
        moltDate: '$y-$m-$d',
        moltNumber: moltCount,
        condition: moltConditionToApi(condition),
        note: note,
      );
      await load();
      await loadDetail(id);
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markHarvested(String id, {String? note}) async {
    final crab = getById(id);
    if (crab == null) return false;
    return updateCrab(
      crab.copyWith(
        lifeStatus: CrabLifeStatus.sold,
        quickNote: note ?? 'Đã thu hoạch ${MockCrabData.formatDate(DateTime.now())}',
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<bool> markDead(String id, {required String cause, required DateTime date}) async {
    final crab = getById(id);
    if (crab == null) return false;
    return updateCrab(
      crab.copyWith(
        lifeStatus: CrabLifeStatus.dead,
        healthStatus: CrabHealthStatus.atRisk,
        healthScore: 0,
        updatedAt: date,
        quickNote: 'Đã chết ($cause) — ${MockCrabData.formatDate(date)}',
      ),
    );
  }

  void updateWeight(
    String id, {
    required double weightGram,
    required double shellSizeCm,
    required DateTime measuredAt,
    String? note,
  }) {
    recordHealth(
      id,
      weightGram: weightGram,
      shellSizeCm: shellSizeCm,
      shellCondition: 'Bình thường',
      diseaseNote: 'Không',
      note: note,
      recordedAt: measuredAt,
    );
  }

  void recordDisease(
    String id, {
    required String name,
    required DiseaseSeverity severity,
    required String symptoms,
    required String treatment,
    required DateTime date,
  }) {
    recordHealth(
      id,
      weightGram: getById(id)?.weightGram ?? 0,
      shellSizeCm: getById(id)?.shellSizeCm ?? 0,
      shellCondition: symptoms,
      diseaseNote: '$name ($treatment)',
      recordedAt: date,
    );
  }

  void updateHealthStatus(String id, CrabHealthStatus status) {
    final crab = getById(id);
    if (crab == null) return;
    updateCrab(crab.copyWith(healthStatus: status, updatedAt: DateTime.now()));
  }

  Future<bool> markReadyForSale(String id) async {
    final crab = getById(id);
    if (crab == null) return false;
    return updateCrab(
      crab.copyWith(
        lifeStatus: CrabLifeStatus.readyForSale,
        healthStatus: CrabHealthStatus.good,
        developmentStage: CrabDevelopmentStage.harvestReady,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @Deprecated('Dùng generateNextCodeForBatch')
  String generateDisplayCode() => 'CR-${1000 + _crabs.length}';

  @Deprecated('Dùng API batch')
  String generateNextId(String boxId) => 'legacy-$boxId';
}
