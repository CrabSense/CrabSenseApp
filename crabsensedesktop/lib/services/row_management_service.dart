import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/farm_record.dart';
import '../models/production_models.dart';
import '../models/row_list_item.dart';
import '../models/row_status.dart';
import 'cloud_api_client.dart';

class RowSummaryStats {
  const RowSummaryStats({
    required this.total,
    required this.active,
    required this.suspended,
    required this.closed,
    required this.totalBoxes,
  });

  final int total;
  final int active;
  final int suspended;
  final int closed;
  final int totalBoxes;
}

class RowManagementService extends ChangeNotifier {
  RowManagementService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<AreaRecord> areas = [];
  List<RowListItem> items = [];
  RowSummaryStats summary = const RowSummaryStats(
    total: 0,
    active: 0,
    suspended: 0,
    closed: 0,
    totalBoxes: 0,
  );

  bool loading = false;
  String? error;
  String search = '';
  String? areaFilterId;
  RowStatusFilter statusFilter = RowStatusFilter.all;
  int page = 0;
  /// 9 = 3 cột × 3 hàng ở grid desktop.
  static const int pageSize = 9;

  AuthSession get session => _session;
  String get token => _session.token;

  void updateSession(AuthSession session) {
    _session = session;
    areas = [];
    items = [];
    summary = const RowSummaryStats(
      total: 0,
      active: 0,
      suspended: 0,
      closed: 0,
      totalBoxes: 0,
    );
    areaFilterId = session.selectedFarm.id.isEmpty ? null : session.selectedFarm.id;
    page = 0;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    page = 0;
    notifyListeners();
  }

  void setAreaFilter(String? areaId) {
    if (areaFilterId == areaId) return;
    areaFilterId = areaId;
    page = 0;
    load();
  }

  void setStatusFilter(RowStatusFilter filter) {
    statusFilter = filter;
    page = 0;
    notifyListeners();
  }

  void setPage(int value) {
    page = value;
    notifyListeners();
  }

  List<RowListItem> get filteredItems {
    var list = items;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((r) =>
              r.rowCode.toLowerCase().contains(q) ||
              r.rowName.toLowerCase().contains(q) ||
              (r.row.location?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    if (areaFilterId != null) {
      list = list.where((r) => r.areaId == areaFilterId).toList();
    }
    final status = statusFilter.farmStatus;
    if (status != null) {
      list = list.where((r) => r.status == status).toList();
    }
    return list;
  }

  int get totalPages {
    final n = filteredItems.length;
    if (n == 0) return 1;
    return (n + pageSize - 1) ~/ pageSize;
  }

  List<RowListItem> get pagedItems {
    final list = filteredItems;
    if (list.isEmpty) return [];
    final safePage = page.clamp(0, totalPages - 1);
    final start = safePage * pageSize;
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  Future<String> fetchNextCode() => _api.fetchNextDayCode(token);

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      areas = await _api.fetchAreas(token, '');
      if (areaFilterId != null && !areas.any((a) => a.id == areaFilterId)) {
        final selected = _session.selectedFarm.id;
        areaFilterId = areas.any((a) => a.id == selected) ? selected : null;
      }
      final areaById = {for (final a in areas) a.id: a};
      final rows = await _api.fetchAllRows(token, areaId: areaFilterId);
      items = rows
          .map((r) => RowListItem(
                row: r,
                areaCode: areaById[r.areaId]?.areaCode ?? '',
              ))
          .toList()
        ..sort((a, b) => a.rowCode.compareTo(b.rowCode));
      summary = RowSummaryStats(
        total: items.length,
        active: items.where((r) => r.status == FarmStatus.active).length,
        suspended: items.where((r) => r.status == FarmStatus.suspended).length,
        closed: items.where((r) => r.status == FarmStatus.closed).length,
        totalBoxes: items.fold(0, (s, r) => s + r.boxCount),
      );
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

  Future<RowRecord> create({
    required String areaId,
    required String name,
    String? location,
    int capacity = 0,
    String? description,
    FarmStatus status = FarmStatus.active,
  }) async {
    final row = await _api.createRow(
      token,
      areaId,
      rowName: name,
      location: location,
      capacity: capacity,
      description: description,
      status: status,
    );
    await load();
    return row;
  }

  Future<RowRecord> update(
    RowRecord existing, {
    required String name,
    String? location,
    int? capacity,
    String? description,
    FarmStatus status = FarmStatus.active,
  }) async {
    final row = await _api.updateRow(
      token,
      existing.id,
      rowName: name,
      location: location,
      capacity: capacity,
      description: description,
      status: status,
    );
    await load();
    return row;
  }

  Future<void> deleteRow(RowListItem item) async {
    await _api.deleteRow(token, item.rowId);
    await load();
  }
}
