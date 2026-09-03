import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/batch_list_item.dart';
import '../models/batch_status.dart';
import '../models/farming_batch_group.dart';
import '../models/production_models.dart';
import 'cloud_api_client.dart';

class BatchSummaryStats {
  const BatchSummaryStats({
    required this.total,
    required this.active,
    required this.harvested,
    required this.failed,
  });

  final int total;
  final int active;
  final int harvested;
  final int failed;
}

class BatchManagementService extends ChangeNotifier {
  BatchManagementService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<AreaRecord> areas = [];
  List<RowRecord> rows = [];
  List<BoxRecord> boxes = [];
  List<BatchListItem> items = [];
  BatchSummaryStats summary = const BatchSummaryStats(
    total: 0,
    active: 0,
    harvested: 0,
    failed: 0,
  );

  bool loading = false;
  String? error;
  String search = '';
  String? areaFilterId;
  String? rowFilterId;
  String? boxFilterId;
  BatchStatusFilter statusFilter = BatchStatusFilter.all;
  int page = 0;
  static const int pageSize = 10;

  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  void updateSession(AuthSession session) {
    _session = session;
    areas = [];
    rows = [];
    boxes = [];
    items = [];
    areaFilterId = null;
    rowFilterId = null;
    boxFilterId = null;
    page = 0;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    page = 0;
    notifyListeners();
  }

  void setStatusFilter(BatchStatusFilter f) {
    statusFilter = f;
    page = 0;
    notifyListeners();
  }

  void setPage(int p) {
    page = p;
    notifyListeners();
  }

  Future<void> selectArea(String? id) async {
    areaFilterId = id;
    rowFilterId = null;
    boxFilterId = null;
    rows = [];
    boxes = [];
    notifyListeners();
    if (id == null) return;
    loading = true;
    notifyListeners();
    try {
      rows = await _api.fetchRows(token, id);
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

  Future<void> selectRow(String? id) async {
    rowFilterId = id;
    boxFilterId = null;
    boxes = [];
    notifyListeners();
    if (id == null) return;
    loading = true;
    notifyListeners();
    try {
      boxes = await _api.fetchBoxes(token, id);
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

  void selectBox(String? id) {
    boxFilterId = id;
    page = 0;
    notifyListeners();
  }

  List<FarmingBatchGroup> get _allGroups => FarmingBatchGroup.fromItems(items);

  List<FarmingBatchGroup> get filteredGroups {
    var list = _allGroups;
    if (areaFilterId != null) {
      list = list.where((g) => g.areaId == areaFilterId).toList();
    }
    if (rowFilterId != null) {
      list = list.where((g) => g.rowId == rowFilterId).toList();
    }
    if (boxFilterId != null) {
      list = list
          .where((g) => g.members.any((m) => m.batch.boxId == boxFilterId))
          .toList();
    }
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((g) {
        return g.batchCode.toLowerCase().contains(q) ||
            g.boxCodes.any((c) => c.toLowerCase().contains(q)) ||
            g.rowCode.toLowerCase().contains(q) ||
            g.areaCode.toLowerCase().contains(q);
      }).toList();
    }
    final st = statusFilter.apiValue;
    if (st.isNotEmpty) {
      list = list.where((g) => g.status == st).toList();
    }
    return list;
  }

  int get totalPages {
    final n = filteredGroups.length;
    if (n == 0) return 1;
    return (n + pageSize - 1) ~/ pageSize;
  }

  List<FarmingBatchGroup> get pagedGroups {
    final list = filteredGroups;
    if (list.isEmpty) return [];
    final safe = page.clamp(0, totalPages - 1);
    final start = safe * pageSize;
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      areas = await _api.fetchAreas(token, farmId);
      final lots = await _api.fetchCrabLots(token);
      final area = areas.isNotEmpty
          ? areas.firstWhere(
              (a) => a.id == farmId,
              orElse: () => areas.first,
            )
          : null;
      items = [
        for (final lot in lots)
          BatchListItem(
            batch: lot,
            areaId: area?.id ?? farmId,
            areaCode: area?.areaCode ?? '',
            areaName: area?.areaName ?? '',
            rowId: '',
            rowCode: '',
            rowName: '',
            boxCode: lot.boxCode ?? '—',
          ),
      ];
      final groups = FarmingBatchGroup.fromItems(items);
      summary = BatchSummaryStats(
        total: groups.length,
        active: groups.where((g) => g.status == 'active').length,
        harvested: groups.where((g) => g.status == 'harvested').length,
        failed: groups.where((g) => g.status == 'failed').length,
      );
      if (areaFilterId != null) {
        rows = await _api.fetchRows(token, areaFilterId!);
        if (rowFilterId != null) {
          boxes = await _api.fetchBoxes(token, rowFilterId!);
        }
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

  Future<void> deleteBatch(BatchListItem item) async {
    await _api.deleteBatch(token, item.id);
    await load();
  }

  Future<void> deleteGroup(FarmingBatchGroup group) async {
    for (final m in group.members) {
      await _api.deleteBatch(token, m.id);
    }
    await load();
  }

  Future<FarmingBatchRecord> endBatch(BatchListItem item) async {
    final b = item.batch;
    final today = DateTime.now();
    final updated = await _api.updateBatch(
      token,
      b.id,
      batchCode: b.batchCode,
      startDate: b.startDate,
      expectedHarvestDate: b.expectedHarvestDate ?? today,
      actualHarvestDate: today,
      initialQuantity: b.initialQuantity,
      currentQuantity: b.currentQuantity,
      status: 'harvested',
    );
    await load();
    return updated;
  }

  Future<void> endGroup(FarmingBatchGroup group) async {
    final today = DateTime.now();
    for (final m in group.members) {
      final b = m.batch;
      await _api.updateBatch(
        token,
        b.id,
        batchCode: b.batchCode,
        startDate: b.startDate,
        expectedHarvestDate: b.expectedHarvestDate ?? today,
        actualHarvestDate: today,
        initialQuantity: b.initialQuantity,
        currentQuantity: b.currentQuantity,
        status: 'harvested',
      );
    }
    await load();
  }

  Future<List<BatchCrabRecord>> loadCrabs(String batchId) =>
      _api.fetchBatchCrabs(token, batchId);

  Future<List<BatchCrabWithBox>> loadCrabsForGroup(
    FarmingBatchGroup group,
  ) async {
    final merged = <BatchCrabWithBox>[];
    for (final m in group.members) {
      final crabs = await _api.fetchBatchCrabs(token, m.id);
      for (final c in crabs) {
        merged.add(BatchCrabWithBox(crab: c, boxCode: m.boxCode));
      }
    }
    merged.sort((a, b) => a.crab.crabCode.compareTo(b.crab.crabCode));
    return merged;
  }

  FarmingBatchGroup? findGroup(String key) {
    try {
      return _allGroups.firstWhere((g) => g.key == key);
    } catch (_) {
      return null;
    }
  }

  FarmingBatchGroup? findGroupContainingBatchId(String batchId) {
    try {
      return _allGroups.firstWhere(
        (g) => g.members.any((m) => m.id == batchId),
      );
    } catch (_) {
      return null;
    }
  }

  BatchListItem? findItem(String batchId) {
    try {
      return items.firstWhere((i) => i.id == batchId);
    } catch (_) {
      return null;
    }
  }
}

/// Cua trong đợt kèm mã hộp (chi tiết đợt nhiều hộp).
class BatchCrabWithBox {
  const BatchCrabWithBox({required this.crab, required this.boxCode});

  final BatchCrabRecord crab;
  final String boxCode;
}
