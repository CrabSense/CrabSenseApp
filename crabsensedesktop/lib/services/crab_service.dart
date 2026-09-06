import 'package:flutter/foundation.dart';

import '../data/mock_crab_data.dart';
import '../models/auth_models.dart';
import '../models/crab_individual.dart';
import '../models/crab_profile.dart';
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
  List<RowRecord> _rowsInArea = [];
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
    _rowsInArea = [];
    _lots = [];
    _profiles.clear();
    _summary = const CrabManagementSummary(
      total: 0,
      alive: 0,
      dead: 0,
      molting: 0,
      readyHarvest: 0,
      aliveRate: 0,
    );
    _currentPage = 1;
    _areaFilter = MockCrabData.allOption;
    _rowFilter = MockCrabData.allOption;
    _boxFilter = MockCrabData.allOption;
    notifyListeners();
  }

  List<String> get areaOptions => [
        MockCrabData.allOption,
        ..._crabs.map((c) => c.areaName).toSet(),
      ];

  List<String> get rowOptions {
    if (_rowsInArea.isNotEmpty) {
      return [
        MockCrabData.allOption,
        ..._rowsInArea.map((r) {
          final name = r.rowName.trim();
          return name.isNotEmpty ? name : r.rowCode;
        }),
      ];
    }
    return [
      MockCrabData.allOption,
      ..._crabs.map((c) => c.rowName).where((n) => n.trim().isNotEmpty).toSet(),
    ];
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
      final seen = <String>{};
      return [
        for (final l in _lots)
          if (seen.add(l.id))
            CrabBatchChoice(
              batchId: l.id,
              batchCode: l.batchCode,
              boxCode: l.boxCode ?? '',
              label: l.displayLabel,
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
  final Map<String, CrabProfile> _profiles = {};

  CrabProfile? profileOf(String crabId) => _profiles[crabId];

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
      try {
        _rowsInArea = farmId.isEmpty
            ? []
            : await _api.fetchAllRows(token, areaId: farmId);
      } catch (_) {
        _rowsInArea = [];
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
      try {
        _profiles[crabId] = await _api.fetchCrabProfile(token, crabId);
      } catch (_) {}
      final body = await _api.fetchCrabDetail(token, crabId);
      final urls = parseCrabImageUrls(body['imageUrls'] ?? body['ImageUrls']);
      final existingProfile = _profiles[crabId];
      if (existingProfile == null) {
        _profiles[crabId] = CrabProfile.fromJson({
          'crab': body,
          'imageUrls': urls,
        });
      } else if (urls.isNotEmpty) {
        _profiles[crabId] = existingProfile.withImageUrls(urls);
      }
      final base = getById(crabId);
      if (base == null) return;
      final profile = _profiles[crabId];
      var merged = mergeCrabDetail(base, body);
      if (profile != null) {
        merged = merged.copyWith(
          areaName: profile.areaName.isNotEmpty ? profile.areaName : merged.areaName,
          rowName: profile.rowName.isNotEmpty ? profile.rowName : merged.rowName,
          boxName: profile.boxCode.isNotEmpty ? profile.boxCode : merged.boxName,
          batchId: profile.lotCode.isNotEmpty ? profile.lotCode : merged.batchId,
        );
      }
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

  List<CrabIndividual> crabsInLot({required String lotId, String? lotCode}) {
    final ids = _lastListItems
        .where((i) => i.batchId == lotId)
        .map((i) => i.id)
        .toSet();
    return _crabs.where((c) {
      if (ids.contains(c.id)) return true;
      if (lotCode != null && lotCode.isNotEmpty && c.batchId == lotCode) {
        return true;
      }
      return c.batchId == lotId;
    }).toList();
  }

  Future<void> refreshLots() async {
    try {
      _lots = await _api.fetchCrabLots(token);
      notifyListeners();
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = '$e';
      notifyListeners();
    }
  }

  Future<FarmingBatchRecord?> ensureDefaultLot() async {
    try {
      if (_lots.isEmpty) {
        _lots = await _api.fetchCrabLots(token);
        notifyListeners();
      }
      return _lots.isEmpty ? null : _lots.first;
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

  Future<String> peekNextLotCode({DateTime? importDate}) async {
    return _api.fetchNextLotCode(token, importDate: importDate);
  }

  Future<FarmingBatchRecord?> importLot({
    required String name,
    required DateTime importDate,
    required int quantity,
    String? lotCode,
    String? supplierName,
    double? totalWeightKg,
    double? weightMinGram,
    double? weightMaxGram,
    double? unitPriceVndPerKg,
    double? shippingCostVnd,
    double? otherCostVnd,
    String condition = 'Good',
    int deadOnArrival = 0,
    String? notes,
  }) async {
    try {
      final lot = await _api.createCrabLot(
        token,
        name: name,
        importDate: importDate,
        quantity: quantity,
        lotCode: lotCode,
        supplierName: supplierName,
        totalWeightKg: totalWeightKg,
        weightMinGram: weightMinGram,
        weightMaxGram: weightMaxGram,
        unitPriceVndPerKg: unitPriceVndPerKg,
        shippingCostVnd: shippingCostVnd,
        otherCostVnd: otherCostVnd,
        condition: condition,
        deadOnArrival: deadOnArrival,
        notes: notes,
      );
      _lots = [lot, ..._lots.where((l) => l.id != lot.id)];
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

  Future<({String code, String qrCode})?> peekNextCrabIdentity() async {
    try {
      return await _api.fetchNextCrabIdentity(token);
    } catch (_) {
      return null;
    }
  }

  Future<List<AreaRecord>> fetchAreas() => _api.fetchAreas(token, '');

  Future<List<RowRecord>> fetchRows(String areaId) =>
      _api.fetchAllRows(token, areaId: areaId);

  Future<List<BoxRecord>> fetchEmptyBoxes({
    String? areaId,
    String? rowId,
  }) async {
    final boxes = await _api.fetchAllBoxes(
      token,
      areaId: areaId,
      rowId: rowId,
    );
    return boxes.where((b) => !b.hasCrab).toList();
  }

  Future<bool> addCrab({
    required String batchId,
    required CrabGender gender,
    double? weightGram,
    double? carapaceWidthMm,
    double? carapaceLengthMm,
    String? note,
    String? boxId,
    String? farmingAreaId,
    String? farmingRowId,
    String? crabType,
    String? initialCondition,
    String condition = 'normal',
    DateTime? stockedAt,
    List<String>? imagePaths,
  }) async {
    try {
      final imageUrls = (imagePaths == null || imagePaths.isEmpty)
          ? const <String>[]
          : await _api.uploadCrabImages(token, imagePaths);
      await _api.createBatchCrabExtended(
        token,
        batchId,
        gender: genderToApi(gender),
        weight: weightGram,
        shellWidth: carapaceWidthMm,
        carapaceLengthMm: carapaceLengthMm,
        profileNote: note,
        boxId: boxId,
        farmingAreaId: farmingAreaId ?? farmId,
        farmingRowId: farmingRowId,
        crabType: crabType,
        initialCondition: initialCondition,
        condition: condition,
        stockedAt: stockedAt,
        imageUrls: imageUrls.isEmpty ? null : imageUrls,
      );
      await load();
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<({int saved, List<String> errors})> addCrabsBulk(
    List<({
      String batchId,
      CrabGender gender,
      double weightGram,
      double carapaceWidthMm,
      double carapaceLengthMm,
      String? note,
      String? boxId,
      String? farmingAreaId,
      String? farmingRowId,
      String? crabType,
      String? initialCondition,
      String condition,
      DateTime? stockedAt,
      List<String>? imagePaths,
    })> rows,
  ) async {
    var saved = 0;
    final errors = <String>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      try {
        final imageUrls = (row.imagePaths == null || row.imagePaths!.isEmpty)
            ? const <String>[]
            : await _api.uploadCrabImages(token, row.imagePaths!);
        await _api.createBatchCrabExtended(
          token,
          row.batchId,
          gender: genderToApi(row.gender),
          weight: row.weightGram,
          shellWidth: row.carapaceWidthMm,
          carapaceLengthMm: row.carapaceLengthMm,
          profileNote: row.note,
          boxId: row.boxId,
          farmingAreaId: row.farmingAreaId ?? farmId,
          farmingRowId: row.farmingRowId,
          crabType: row.crabType,
          initialCondition: row.initialCondition,
          condition: row.condition,
          stockedAt: row.stockedAt,
          imageUrls: imageUrls.isEmpty ? null : imageUrls,
        );
        saved++;
      } on CloudApiException catch (e) {
        errors.add('Dòng ${i + 1}: ${e.message}');
      } catch (e) {
        errors.add('Dòng ${i + 1}: $e');
      }
    }
    await load();
    return (saved: saved, errors: errors);
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
        shellLength: crab.carapaceLengthMm,
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
