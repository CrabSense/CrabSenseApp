import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/farm_record.dart';
import '../models/production_models.dart';
import 'cloud_api_client.dart';

enum ProductionTab { area, row, box, batch, crab }

class ProductionManagementService extends ChangeNotifier {
  ProductionManagementService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  ProductionTab tab = ProductionTab.area;
  bool loading = false;
  String? error;
  String search = '';

  List<AreaRecord> areas = [];
  List<RowRecord> rows = [];
  List<BoxRecord> boxes = [];
  List<FarmingBatchRecord> batches = [];
  List<BatchCrabRecord> crabs = [];

  String? selectedAreaId;
  String? selectedRowId;
  String? selectedBoxId;
  String? selectedBatchId;

  AuthSession get session => _session;
  String get farmId => _session.selectedFarm.id;
  String get token => _session.token;
  bool get isOrgAdmin => _session.isOrgAdmin;

  void updateSession(AuthSession session) {
    _session = session;
    areas = [];
    rows = [];
    boxes = [];
    batches = [];
    crabs = [];
    selectedAreaId = null;
    selectedRowId = null;
    selectedBoxId = null;
    selectedBatchId = null;
    notifyListeners();
  }

  void setTab(ProductionTab value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void selectArea(String? id) {
    selectedAreaId = id;
    selectedRowId = null;
    selectedBoxId = null;
    selectedBatchId = null;
    rows = [];
    boxes = [];
    batches = [];
    crabs = [];
    notifyListeners();
    if (id != null) loadRows();
  }

  void selectRow(String? id) {
    selectedRowId = id;
    selectedBoxId = null;
    selectedBatchId = null;
    boxes = [];
    batches = [];
    crabs = [];
    notifyListeners();
    if (id != null) {
      loadBoxes();
      loadBatches();
    }
  }

  void selectBox(String? id) {
    selectedBoxId = id;
    selectedBatchId = null;
    batches = [];
    crabs = [];
    notifyListeners();
    if (id != null) loadBatches();
  }

  void selectBatch(String? id) {
    selectedBatchId = id;
    crabs = [];
    notifyListeners();
    if (id != null) loadCrabs();
  }

  String _q(String s) => search.trim().toLowerCase();

  List<AreaRecord> get filteredAreasWithSearch {
    final q = _q(search);
    if (q.isEmpty) return areas;
    return areas
        .where((a) =>
            a.areaCode.toLowerCase().contains(q) ||
            a.areaName.toLowerCase().contains(q) ||
            (a.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<RowRecord> get filteredRows {
    final q = _q(search);
    if (q.isEmpty) return rows;
    return rows
        .where((r) =>
            r.rowCode.toLowerCase().contains(q) ||
            r.rowName.toLowerCase().contains(q))
        .toList();
  }

  List<BoxRecord> get filteredBoxes {
    final q = _q(search);
    if (q.isEmpty) return boxes;
    return boxes
        .where((b) =>
            b.boxCode.toLowerCase().contains(q) ||
            (b.position?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<FarmingBatchRecord> get filteredBatches {
    final q = _q(search);
    if (q.isEmpty) return batches;
    return batches
        .where((b) =>
            b.batchCode.toLowerCase().contains(q) ||
            (b.boxCode?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<BatchCrabRecord> get filteredCrabs {
    final q = _q(search);
    if (q.isEmpty) return crabs;
    return crabs
        .where((c) => c.crabCode.toLowerCase().contains(q))
        .toList();
  }

  Future<void> loadCurrentTab() async {
    switch (tab) {
      case ProductionTab.area:
        return loadAreas();
      case ProductionTab.row:
        if (selectedAreaId != null) return loadRows();
        return loadAreas();
      case ProductionTab.box:
        if (selectedRowId != null) return loadBoxes();
        if (selectedAreaId != null) return loadRows();
        return loadAreas();
      case ProductionTab.batch:
        if (selectedRowId != null) return loadBatches();
        if (selectedAreaId != null) return loadRows();
        return loadAreas();
      case ProductionTab.crab:
        if (selectedBatchId != null) return loadCrabs();
        if (selectedBoxId != null) return loadBatches();
        return loadAreas();
    }
  }

  Future<void> loadAreas() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      areas = await _api.fetchAreas(token, farmId);
      if (selectedAreaId != null &&
          !areas.any((a) => a.id == selectedAreaId)) {
        selectedAreaId = areas.isNotEmpty ? areas.first.id : null;
      }
      error = null;
    } on CloudApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadRows() async {
    final areaId = selectedAreaId;
    if (areaId == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      rows = await _api.fetchRows(token, areaId);
      if (selectedRowId != null && !rows.any((r) => r.id == selectedRowId)) {
        selectedRowId = rows.isNotEmpty ? rows.first.id : null;
      }
      error = null;
    } on CloudApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<RowRecord>> fetchRowsForArea(String areaId) =>
      _api.fetchRows(token, areaId);

  Future<RowRecord> fetchRowById(String id) => _api.fetchRowById(token, id);

  Future<List<BoxRecord>> createBoxesInRow({
    required String rowId,
    required int count,
  }) async {
    if (count <= 0) return const [];
    final created = await _api.createBoxesQuantity(token, rowId, count);
    if (created.isEmpty && count > 0) {
      throw CloudApiException('Không tạo được hộp. Vui lòng thử lại.');
    }
    boxes = [...boxes, ...created]..sort((x, y) => x.boxCode.compareTo(y.boxCode));
    notifyListeners();
    return created;
  }

  Future<List<BoxRecord>> fetchBoxesOfRow(String rowId) =>
      _api.fetchBoxes(token, rowId);

  Future<void> loadBoxes() async {
    final rowId = selectedRowId;
    if (rowId == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      boxes = await _api.fetchBoxes(token, rowId);
      if (selectedBoxId != null && !boxes.any((b) => b.id == selectedBoxId)) {
        selectedBoxId = boxes.isNotEmpty ? boxes.first.id : null;
      }
      error = null;
    } on CloudApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadBatches() async {
    final rowId = selectedRowId;
    if (rowId == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      batches = await _api.fetchBatchesByRow(token, rowId);
      if (selectedBatchId != null &&
          !batches.any((b) => b.id == selectedBatchId)) {
        selectedBatchId = batches.isNotEmpty ? batches.first.id : null;
      }
      error = null;
    } on CloudApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCrabs() async {
    final batchId = selectedBatchId;
    if (batchId == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      crabs = await _api.fetchBatchCrabs(token, batchId);
      error = null;
    } on CloudApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String> fetchNextAreaCode() => _api.fetchNextAreaCode(token, farmId);

  Future<String> fetchNextRowCode() =>
      _api.fetchNextRowCode(token, selectedAreaId!);

  Future<String> fetchNextBoxCode() =>
      _api.fetchNextBoxCode(token, selectedRowId!);

  Future<String> fetchNextBatchCode() =>
      _api.fetchNextBatchCode(token, selectedBoxId!);

  Future<String> fetchNextCrabCode() =>
      _api.fetchNextBatchCrabCode(token, selectedBatchId!);

  // ── Area CRUD ──
  Future<AreaRecord> createArea({
    required String areaName,
    String? description,
  }) async {
    final a = await _api.createArea(token, farmId,
        areaName: areaName, description: description);
    areas = [...areas, a]..sort((x, y) => x.areaCode.compareTo(y.areaCode));
    notifyListeners();
    return a;
  }

  Future<AreaRecord> updateArea(AreaRecord item,
      {required String areaCode,
      required String areaName,
      String? description}) async {
    final a = await _api.updateArea(token, item.id,
        areaCode: areaCode, areaName: areaName, description: description);
    areas = areas.map((x) => x.id == a.id ? a : x).toList()
      ..sort((x, y) => x.areaCode.compareTo(y.areaCode));
    notifyListeners();
    return a;
  }

  Future<void> deleteArea(AreaRecord item, {bool cascade = false}) async {
    await _api.deleteArea(token, item.id, cascade: cascade);
    areas = areas.where((x) => x.id != item.id).toList();
    if (selectedAreaId == item.id) selectArea(null);
    notifyListeners();
  }

  // ── Row CRUD ──
  Future<RowRecord> createRow({
    required String rowName,
    String? location,
    int capacity = 0,
    String? description,
    FarmStatus status = FarmStatus.active,
  }) async {
    final areaId = selectedAreaId!;
    final r = await _api.createRow(
      token,
      areaId,
      rowName: rowName,
      location: location,
      capacity: capacity,
      description: description,
      status: status,
    );
    rows = [...rows, r]..sort((x, y) => x.rowCode.compareTo(y.rowCode));
    notifyListeners();
    return r;
  }

  Future<RowRecord> updateRow(
    RowRecord item, {
    required String rowName,
    String? location,
    int? capacity,
    String? description,
    FarmStatus status = FarmStatus.active,
  }) async {
    final r = await _api.updateRow(
      token,
      item.id,
      rowName: rowName,
      location: location,
      capacity: capacity,
      description: description,
      status: status,
    );
    rows = rows.map((x) => x.id == r.id ? r : x).toList()
      ..sort((x, y) => x.rowCode.compareTo(y.rowCode));
    notifyListeners();
    return r;
  }

  Future<void> deleteRow(RowRecord item) async {
    await _api.deleteRow(token, item.id);
    rows = rows.where((x) => x.id != item.id).toList();
    if (selectedRowId == item.id) selectRow(null);
    notifyListeners();
  }

  // ── Box CRUD ──
  Future<BoxRecord> createBox({
    String? position,
    double? volume,
    String status = 'empty',
  }) async {
    final list = await createBoxes(
      count: 1,
      positionPrefix: position,
      volume: volume,
      status: status,
    );
    return list.first;
  }

  Future<List<BoxRecord>> createBoxes({
    required int count,
    String? positionPrefix,
    double? volume,
    String status = 'empty',
  }) async {
    final rowId = selectedRowId!;
    final created = count <= 1
        ? [await _api.createBox(token, rowId)]
        : await _api.createBoxesBulk(token, rowId, count: count);
    boxes = [...boxes, ...created]..sort((x, y) => x.boxCode.compareTo(y.boxCode));
    notifyListeners();
    return created;
  }

  Future<BoxRecord> updateBox(BoxRecord item,
      {required String boxCode,
      String? position,
      double? volume,
      required String status}) async {
    final r = await _api.updateBox(token, item.id,
        boxCode: boxCode, position: position, volume: volume, status: status);
    boxes = boxes.map((x) => x.id == r.id ? r : x).toList()
      ..sort((x, y) => x.boxCode.compareTo(y.boxCode));
    notifyListeners();
    return r;
  }

  Future<void> deleteBox(BoxRecord item) async {
    await _api.deleteBox(token, item.id);
    boxes = boxes.where((x) => x.id != item.id).toList();
    if (selectedBoxId == item.id) selectBox(null);
    notifyListeners();
  }

  // ── Batch CRUD ──
  Future<List<FarmingBatchRecord>> createBatches({
    required List<String> boxIds,
    required DateTime startDate,
    required DateTime expectedHarvestDate,
    int initialQuantity = 0,
    bool startNow = true,
    String status = 'active',
  }) async {
    final rowId = selectedRowId!;
    final created = boxIds.length <= 1 && boxIds.isNotEmpty
        ? [
            await _api.createBatch(
              token,
              boxIds.first,
              startDate: startDate,
              expectedHarvestDate: expectedHarvestDate,
              initialQuantity: initialQuantity,
              status: status,
              startNow: startNow,
            )
          ]
        : await _api.createBatchesBulk(
            token,
            rowId,
            boxIds: boxIds,
            startDate: startDate,
            expectedHarvestDate: expectedHarvestDate,
            initialQuantity: initialQuantity,
            startNow: startNow,
            status: status,
          );
    batches = [...batches, ...created]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    await loadBoxes();
    notifyListeners();
    return created;
  }

  Future<FarmingBatchRecord> updateBatch(
    FarmingBatchRecord item, {
    required DateTime startDate,
    required DateTime expectedHarvestDate,
    DateTime? actualHarvestDate,
    required int initialQuantity,
    required int currentQuantity,
    required String status,
    bool startNow = false,
  }) async {
    final b = await _api.updateBatch(
      token,
      item.id,
      batchCode: item.batchCode,
      startDate: startDate,
      expectedHarvestDate: expectedHarvestDate,
      actualHarvestDate: actualHarvestDate,
      initialQuantity: initialQuantity,
      currentQuantity: currentQuantity,
      status: status,
      startNow: startNow,
    );
    batches = batches.map((x) => x.id == b.id ? b : x).toList();
    await loadBoxes();
    notifyListeners();
    return b;
  }

  Future<void> deleteBatch(FarmingBatchRecord item) async {
    await _api.deleteBatch(token, item.id);
    batches = batches.where((x) => x.id != item.id).toList();
    if (selectedBatchId == item.id) selectBatch(null);
    notifyListeners();
  }

  // ── Crab CRUD ──
  Future<BatchCrabRecord> createCrab({
    String gender = 'unknown',
    double? weight,
    double? shellWidth,
    String status = 'alive',
  }) async {
    final c = await _api.createBatchCrab(
      token,
      selectedBatchId!,
      gender: gender,
      weight: weight,
      shellWidth: shellWidth,
      status: status,
      boxId: selectedBoxId,
      farmingAreaId: farmId,
    );
    crabs = [...crabs, c]..sort((x, y) => x.crabCode.compareTo(y.crabCode));
    notifyListeners();
    return c;
  }

  Future<BatchCrabRecord> updateCrab(BatchCrabRecord item,
      {required String crabCode,
      required String gender,
      double? weight,
      double? shellWidth,
      required String status}) async {
    final c = await _api.updateBatchCrab(token, item.id,
        crabCode: crabCode,
        gender: gender,
        weight: weight,
        shellWidth: shellWidth,
        status: status);
    crabs = crabs.map((x) => x.id == c.id ? c : x).toList()
      ..sort((x, y) => x.crabCode.compareTo(y.crabCode));
    notifyListeners();
    return c;
  }

  Future<void> deleteCrab(BatchCrabRecord item) async {
    await _api.deleteBatchCrab(token, item.id);
    crabs = crabs.where((x) => x.id != item.id).toList();
    notifyListeners();
  }
}
