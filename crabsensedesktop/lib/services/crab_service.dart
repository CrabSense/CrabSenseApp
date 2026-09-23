import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../utils/app_formatters.dart';
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

enum CrabListSort {
  updatedDesc,
  code,
  weight,
  status,
  health,
  enteredAt;

  String get label => switch (this) {
        CrabListSort.updatedDesc => 'Mới nhất',
        CrabListSort.code => 'Mã cua',
        CrabListSort.weight => 'Cân nặng',
        CrabListSort.status => 'Trạng thái',
        CrabListSort.health => 'Sức khỏe',
        CrabListSort.enteredAt => 'Ngày nhập trại',
      };
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
  List<AreaRecord> _areas = [];
  List<RowRecord> _rowsInArea = [];
  List<BoxRecord> _boxes = [];
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
  String _areaFilter = kAllFilter;
  String _rowFilter = kAllFilter;
  String _boxFilter = kAllFilter;
  String _batchFilter = kAllFilter;
  CrabGender? _genderFilter;
  CrabLifecycleStatus? _lifecycleFilter;
  CrabDisplayHealth? _healthFilter;
  CrabManagementStatusFilter _statusFilter = CrabManagementStatusFilter.all;
  CrabListSort _sort = CrabListSort.updatedDesc;

  int _pageSize = 10;
  int _currentPage = 1;

  bool get loading => _loading;
  String? get error => _error;
  List<CrabIndividual> get crabs => List.unmodifiable(_crabs);
  List<AreaRecord> get areas => List.unmodifiable(_areas);

  String get areaFilter => _areaFilter;
  String get rowFilter => _rowFilter;
  String get boxFilter => _boxFilter;
  String get batchFilter => _batchFilter;
  CrabGender? get genderFilter => _genderFilter;
  CrabLifecycleStatus? get lifecycleFilter => _lifecycleFilter;
  CrabDisplayHealth? get healthFilter => _healthFilter;
  CrabManagementStatusFilter get statusFilter => _statusFilter;
  CrabListSort get sort => _sort;
  String get searchQuery => _searchQuery;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get displayTotal => _summary.total;

  CrabManagementSummary get summary => _summary;

  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;
  List<FarmingBatchRecord> get lots => List.unmodifiable(_lots);
  List<FarmingBatchRecord> get availableLots =>
      _lots.where((l) => l.remainingCount > 0).toList();
  CloudApiClient get api => _api;
  String get operatorName => _session.user.displayName;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _areaFilter != kAllFilter ||
      _rowFilter != kAllFilter ||
      _boxFilter != kAllFilter ||
      _batchFilter != kAllFilter ||
      _genderFilter != null ||
      _lifecycleFilter != null ||
      _healthFilter != null ||
      _statusFilter != CrabManagementStatusFilter.all;

  void updateSession(AuthSession session) {
    _session = session;
    _crabs = [];
    _areas = [];
    _rowsInArea = [];
    _boxes = [];
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
    _areaFilter = kAllFilter;
    _rowFilter = kAllFilter;
    _boxFilter = kAllFilter;
    _batchFilter = kAllFilter;
    _genderFilter = null;
    _lifecycleFilter = null;
    _healthFilter = null;
    _statusFilter = CrabManagementStatusFilter.all;
    notifyListeners();
  }

  List<(String, String)> get areaFilterItems {
    final items = <(String, String)>[];
    final seen = <String>{};
    for (final a in _areas) {
      if (seen.add(a.id)) {
        items.add((a.id, '${a.areaCode} — ${a.areaName}'));
      }
    }
    for (final c in _crabs) {
      if (c.areaId.isEmpty || !seen.add(c.areaId)) continue;
      items.add((
        c.areaId,
        c.areaCode.isNotEmpty ? '${c.areaCode} — ${c.areaName}' : c.areaLabel,
      ));
    }
    return items;
  }

  List<(String, String)> get rowFilterItems {
    final areaId = _areaFilter == kAllFilter ? null : _areaFilter;
    final items = <(String, String)>[];
    final seen = <String>{};
    for (final r in _rowsInArea) {
      if (areaId != null && r.areaId != areaId) continue;
      if (!seen.add(r.id)) continue;
      final name = r.rowName.trim().isNotEmpty ? r.rowName : r.rowCode;
      items.add((r.id, name));
    }
    if (items.isEmpty) {
      for (final c in _crabs) {
        if (areaId != null && c.areaId != areaId) continue;
        if (c.rowId.isEmpty || !seen.add(c.rowId)) continue;
        items.add((c.rowId, c.rowLabel));
      }
    }
    return items;
  }

  List<(String, String)> get boxFilterItems {
    final areaId = _areaFilter == kAllFilter ? null : _areaFilter;
    final rowId = _rowFilter == kAllFilter ? null : _rowFilter;
    final items = <(String, String)>[];
    final seen = <String>{};
    for (final b in _boxes) {
      if (areaId != null && b.areaId != null && b.areaId != areaId) continue;
      if (rowId != null && b.rowId != rowId) continue;
      if (!seen.add(b.id)) continue;
      items.add((b.id, b.boxCode));
    }
    if (items.isEmpty) {
      for (final c in _crabs) {
        if (areaId != null && c.areaId != areaId) continue;
        if (rowId != null && c.rowId != rowId) continue;
        if (c.boxId.isEmpty || !seen.add(c.boxId)) continue;
        items.add((c.boxId, c.boxLabel));
      }
    }
    return items;
  }

  List<String> get areaOptions => [
        kAllFilter,
        ...areaFilterItems.map((e) => e.$2),
      ];

  List<String> get rowOptions => [
        kAllFilter,
        ...rowFilterItems.map((e) => e.$2),
      ];

  List<String> get boxOptions => [
        kAllFilter,
        ...boxFilterItems.map((e) => e.$2),
      ];

  List<String> get batchOptions => [
        kAllFilter,
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
    if (_areaFilter != kAllFilter) {
      list = list.where((c) => c.areaId == _areaFilter).toList();
    }
    if (_rowFilter != kAllFilter) {
      list = list.where((c) => c.rowId == _rowFilter).toList();
    }
    if (_boxFilter != kAllFilter) {
      list = list.where((c) => c.boxId == _boxFilter).toList();
    }
    if (_batchFilter != kAllFilter) {
      list = list.where((c) => c.batchId == _batchFilter).toList();
    }
    if (_genderFilter != null) {
      list = list.where((c) => c.gender == _genderFilter).toList();
    }
    if (_lifecycleFilter != null) {
      list = list.where((c) => c.lifecycleStatus == _lifecycleFilter).toList();
    }
    if (_healthFilter != null) {
      list = list.where((c) => c.displayHealth == _healthFilter).toList();
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
                c.boxLabel.toLowerCase().contains(q) ||
                c.batchId.toLowerCase().contains(q),
          )
          .toList();
    }
    list = [...list]..sort(_compare);
    return list;
  }

  int _compare(CrabIndividual a, CrabIndividual b) {
    return switch (_sort) {
      CrabListSort.updatedDesc => b.lastUpdated.compareTo(a.lastUpdated),
      CrabListSort.code => a.code.compareTo(b.code),
      CrabListSort.weight => b.weightGram.compareTo(a.weightGram),
      CrabListSort.status =>
        a.lifecycleStatus.index.compareTo(b.lifecycleStatus.index),
      CrabListSort.health =>
        a.displayHealth.index.compareTo(b.displayHealth.index),
      CrabListSort.enteredAt => b.releaseDate.compareTo(a.releaseDate),
    };
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
      _summary = summarizeCrabs(_crabs);
      try {
        _areas = await _api.fetchAreas(token, '');
      } catch (_) {
        _areas = [];
      }
      try {
        _boxes = await _api.fetchAllBoxes(
          token,
          areaId: farmId.isEmpty ? null : farmId,
        );
      } catch (_) {
        _boxes = [];
      }
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
    _rowFilter = kAllFilter;
    _boxFilter = kAllFilter;
    _currentPage = 1;
    notifyListeners();
  }

  void setRowFilter(String value) {
    _rowFilter = value;
    _boxFilter = kAllFilter;
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

  void setGenderFilter(CrabGender? value) {
    _genderFilter = value;
    _currentPage = 1;
    notifyListeners();
  }

  void setLifecycleFilter(CrabLifecycleStatus? value) {
    _lifecycleFilter = value;
    if (value == null) {
      if (_statusFilter != CrabManagementStatusFilter.monitoring) {
        _statusFilter = CrabManagementStatusFilter.all;
      }
    } else {
      _statusFilter = switch (value) {
        CrabLifecycleStatus.growing => CrabManagementStatusFilter.growing,
        CrabLifecycleStatus.molting => CrabManagementStatusFilter.molting,
        CrabLifecycleStatus.readyHarvest =>
          CrabManagementStatusFilter.readyHarvest,
        CrabLifecycleStatus.dead => CrabManagementStatusFilter.dead,
        CrabLifecycleStatus.harvested => CrabManagementStatusFilter.all,
      };
    }
    _currentPage = 1;
    notifyListeners();
  }

  void setHealthFilter(CrabDisplayHealth? value) {
    _healthFilter = value;
    if (value == CrabDisplayHealth.monitoring) {
      _statusFilter = CrabManagementStatusFilter.monitoring;
    } else if (_statusFilter == CrabManagementStatusFilter.monitoring) {
      _statusFilter = CrabManagementStatusFilter.all;
    }
    _currentPage = 1;
    notifyListeners();
  }

  void setStatusFilter(CrabManagementStatusFilter value) {
    _statusFilter = value;
    _lifecycleFilter = switch (value) {
      CrabManagementStatusFilter.growing => CrabLifecycleStatus.growing,
      CrabManagementStatusFilter.molting => CrabLifecycleStatus.molting,
      CrabManagementStatusFilter.readyHarvest => CrabLifecycleStatus.readyHarvest,
      CrabManagementStatusFilter.dead => CrabLifecycleStatus.dead,
      _ => null,
    };
    _healthFilter = value == CrabManagementStatusFilter.monitoring
        ? CrabDisplayHealth.monitoring
        : null;
    _currentPage = 1;
    notifyListeners();
  }

  void setSort(CrabListSort value) {
    _sort = value;
    notifyListeners();
  }

  void setPageSize(int value) {
    _pageSize = value;
    _currentPage = 1;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _areaFilter = kAllFilter;
    _rowFilter = kAllFilter;
    _boxFilter = kAllFilter;
    _batchFilter = kAllFilter;
    _genderFilter = null;
    _lifecycleFilter = null;
    _healthFilter = null;
    _statusFilter = CrabManagementStatusFilter.all;
    _currentPage = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    _currentPage = page.clamp(1, totalPages);
    notifyListeners();
  }

  CrabIndividual? getById(String id) => findCrabById(_crabs, id);

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
    List<String> imagePaths = const [],
  }) async {
    try {
      var lot = await _api.createCrabLot(
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
      if (imagePaths.isNotEmpty) {
        final urls = await _api.uploadLotImages(token, lot.id, imagePaths);
        if (urls.isNotEmpty) {
          lot = await _api.fetchCrabLot(token, lot.id);
        }
      }
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
    final boxes = await fetchBoxes(areaId: areaId, rowId: rowId);
    return boxes.where((b) => !b.hasCrab).toList();
  }

  Future<List<BoxRecord>> fetchBoxes({
    String? areaId,
    String? rowId,
  }) =>
      _api.fetchAllBoxes(
        token,
        areaId: areaId,
        rowId: rowId,
      );

  Future<({String code, String? boxCode})> addCrab({
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
    final imageUrls = (imagePaths == null || imagePaths.isEmpty)
        ? const <String>[]
        : await _api.uploadCrabImages(token, imagePaths);
    final created = await _api.createBatchCrabExtended(
      token,
      batchId,
      gender: genderToApi(gender),
      weight: weightGram,
      shellWidth: carapaceWidthMm,
      carapaceLengthMm: carapaceLengthMm,
      profileNote: note,
      boxId: boxId,
      farmingAreaId: farmingAreaId,
      farmingRowId: farmingRowId,
      crabType: crabType,
      initialCondition: initialCondition,
      condition: condition,
      stockedAt: stockedAt,
      imageUrls: imageUrls.isEmpty ? null : imageUrls,
    );
    await load();
    await refreshLots();
    return (
      code: created.crabCode.isEmpty ? created.id : created.crabCode,
      boxCode: created.boxCode,
    );
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
    if (rows.isEmpty) return (saved: 0, errors: const ['Không có dòng nào để lưu.']);
    final first = rows.first;
    try {
      final items = <Map<String, dynamic>>[];
      for (final row in rows) {
        final imageUrls = (row.imagePaths == null || row.imagePaths!.isEmpty)
            ? const <String>[]
            : await _api.uploadCrabImages(token, row.imagePaths!);
        items.add({
          'gender': genderToApi(row.gender),
          'weightGram': row.weightGram,
          'carapaceWidthMm': row.carapaceWidthMm,
          'carapaceLengthMm': row.carapaceLengthMm,
          'autoAssign': row.boxId == null || row.boxId!.isEmpty,
          if (row.boxId != null && row.boxId!.isNotEmpty) 'targetBoxId': row.boxId,
          if (row.note != null && row.note!.isNotEmpty) 'note': row.note,
          if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        });
      }
      final saved = await _api.createCrabsBulk(
        token,
        batchId: first.batchId,
        farmingAreaId: first.farmingAreaId,
        farmingRowId: first.farmingRowId,
        crabType: first.crabType,
        condition: first.condition,
        initialCondition: first.initialCondition,
        stockedAt: first.stockedAt,
        items: items,
      );
      await load();
      await refreshLots();
      return (saved: saved, errors: const <String>[]);
    } on CloudApiException catch (e) {
      if (e.statusCode == 404) {
        return _addCrabsBulkSequential(rows);
      }
      _error = e.message;
      notifyListeners();
      return (saved: 0, errors: [e.message]);
    } catch (e) {
      _error = '$e';
      notifyListeners();
      return (saved: 0, errors: ['$e']);
    }
  }

  Future<({int saved, List<String> errors})> _addCrabsBulkSequential(
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
    await refreshLots();
    return (saved: saved, errors: errors);
  }

  Future<bool> updateCrabProfile(CrabIndividual crab) async {
    try {
      await _api.updateCrabProfile(
        token,
        crab.id,
        gender: genderToApi(crab.gender),
        crabType: crab.crabType,
        growthStage: lifecycleToMoltingStage(crab.lifecycleStatus, crab.developmentStage),
        condition: crab.lifecycleStatus == CrabLifecycleStatus.molting
            ? 'molting'
            : crab.lifecycleStatus == CrabLifecycleStatus.readyHarvest
                ? 'softshell'
                : healthDisplayToCondition(crab.displayHealth),
        notes: crab.quickNote,
        isAlive: crab.lifecycleStatus != CrabLifecycleStatus.dead
            && crab.lifecycleStatus != CrabLifecycleStatus.harvested,
      );
      await load();
      await loadDetail(crab.id);
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
    List<String> imagePaths = const [],
  }) async {
    try {
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      final crab = getById(id);
      final moltId = await _api.recordCrabMolt(
        token,
        id,
        moltDate: '$y-$m-$d',
        moltNumber: moltCount,
        condition: moltConditionToApi(condition),
        note: note,
        boxId: crab?.boxId,
      );
      if (imagePaths.isNotEmpty) {
        if (moltId == null || moltId.isEmpty) {
          _error = 'Đã ghi lột xác nhưng không lấy được mã bản ghi để tải ảnh';
          notifyListeners();
          await load();
          await loadDetail(id);
          return false;
        }
        await _api.uploadMoltImages(token, moltId, imagePaths);
      }
      await load();
      await loadDetail(id);
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markHarvested(String id, {String? note}) =>
      harvestToInventory(id, isSoftshell: false, note: note);

  Future<bool> exportSoftshell(String id, {String? note}) =>
      harvestToInventory(id, isSoftshell: true, note: note);

  Future<bool> harvestToInventory(
    String id, {
    required bool isSoftshell,
    String? note,
  }) async {
    final crab = getById(id);
    if (crab == null) return false;
    if (crab.lifeStatus != CrabLifeStatus.raising) {
      _error = 'Chỉ xuất cua đang nuôi';
      notifyListeners();
      return false;
    }
    try {
      final grams = crab.weightGram.round();
      await _api.createHarvestVoucher(
        token,
        harvestDate: DateTime.now(),
        notes: note ??
            (isSoftshell
                ? 'Xuất cua lột ${crab.code}'
                : 'Thu hoạch ${crab.code}'),
        quantity: 1,
        totalWeightKg: grams / 1000,
        farmingAreaId: farmId,
        performedByName: _session.user.displayName,
        lines: [
          {
            'crabId': id,
            'weightGram': grams <= 0 ? 1 : grams,
            'grade': 'A',
            'isSoftshell': isSoftshell,
            'conditionLabel': isSoftshell ? 'Cua lột' : crab.healthStatus.label,
            'result': 'passed',
          },
        ],
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

  Future<bool> markDead(String id, {required String cause, required DateTime date}) async {
    final crab = getById(id);
    if (crab == null) return false;
    return updateCrab(
      crab.copyWith(
        lifeStatus: CrabLifeStatus.dead,
        lifecycleStatus: CrabLifecycleStatus.dead,
        healthStatus: CrabHealthStatus.atRisk,
        healthScore: 0,
        updatedAt: date,
        quickNote: 'Đã chết ($cause) — ${formatDate(date)}',
      ),
    );
  }

  Future<bool> markMolting(
    String id, {
    required DateTime date,
    String? note,
  }) async {
    final crab = getById(id);
    if (crab == null) return false;
    final ok = await recordMolt(
      id,
      date: date,
      moltCount: crab.moltCount + 1,
      condition: MoltCondition.normal,
      note: note,
    );
    if (!ok) return false;
    return updateCrab(
      (getById(id) ?? crab).copyWith(
        lifecycleStatus: CrabLifecycleStatus.molting,
        lastMoltDate: date,
        updatedAt: date,
        quickNote: note ?? crab.quickNote,
      ),
    );
  }

  Future<bool> markReadyHarvest(String id) async {
    final crab = getById(id);
    if (crab == null) return false;
    return updateCrab(
      crab.copyWith(
        developmentStage: CrabDevelopmentStage.harvestReady,
        lifecycleStatus: CrabLifecycleStatus.readyHarvest,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> transferToBox(
    String id, {
    required String destinationBoxId,
    String? notes,
    String? targetFarmAreaId,
    String? targetRowId,
    String? reasonCode,
    String? reasonText,
    String? note,
  }) async {
    final crab = getById(id);
    await _api.transferCrab(
      token,
      crabId: id,
      destinationBoxId: destinationBoxId,
      sourceBoxId: crab?.boxId,
      notes: notes,
      targetFarmAreaId: targetFarmAreaId,
      targetRowId: targetRowId,
      reasonCode: reasonCode,
      reasonText: reasonText,
      note: note,
    );
    await load();
    await loadDetail(id);
  }

  Future<bool> bulkUpdateHealth(
    Iterable<String> ids,
    CrabDisplayHealth health,
  ) async {
    final mapped = switch (health) {
      CrabDisplayHealth.healthy => CrabHealthStatus.healthy,
      CrabDisplayHealth.monitoring => CrabHealthStatus.monitoring,
      CrabDisplayHealth.weak => CrabHealthStatus.atRisk,
      CrabDisplayHealth.alert => CrabHealthStatus.atRisk,
    };
    var ok = true;
    for (final id in ids) {
      final crab = getById(id);
      if (crab == null) continue;
      final saved = await updateCrab(crab.copyWith(healthStatus: mapped));
      if (!saved) ok = false;
    }
    return ok;
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
