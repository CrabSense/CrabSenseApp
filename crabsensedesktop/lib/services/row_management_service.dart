import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/production_models.dart';
import '../models/row_list_item.dart';
import '../models/row_status.dart';
import 'cloud_api_client.dart';

class RowSummaryStats {
  const RowSummaryStats({
    required this.total,
    required this.active,
    required this.maintenance,
    required this.disabled,
    required this.totalBoxes,
  });

  final int total;
  final int active;
  final int maintenance;
  final int disabled;
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
    maintenance: 0,
    disabled: 0,
    totalBoxes: 0,
  );

  bool loading = false;
  String? error;
  String search = '';
  String? areaFilterId;
  RowStatusFilter statusFilter = RowStatusFilter.all;
  int page = 0;
  static const int pageSize = 10;

  AuthSession get session => _session;
  String get farmId => _session.selectedFarm.id;
  String get token => _session.token;

  void updateSession(AuthSession session) {
    _session = session;
    areas = [];
    items = [];
    summary = const RowSummaryStats(
      total: 0,
      active: 0,
      maintenance: 0,
      disabled: 0,
      totalBoxes: 0,
    );
    areaFilterId = null;
    page = 0;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    page = 0;
    notifyListeners();
  }

  void setAreaFilter(String? areaId) {
    areaFilterId = areaId;
    page = 0;
    notifyListeners();
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
              r.areaCode.toLowerCase().contains(q) ||
              r.areaName.toLowerCase().contains(q))
          .toList();
    }
    if (areaFilterId != null) {
      list = list.where((r) => r.areaId == areaFilterId).toList();
    }
    final status = statusFilter.apiValue;
    if (status.isNotEmpty) {
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

  static String deriveRowStatus(AreaRecord area, List<BoxRecord> rowBoxes) {
    if (area.status == 'maintenance') return 'maintenance';
    if (area.status == 'disabled') return 'disabled';
    if (rowBoxes.isEmpty) return 'active';
    final inUse = rowBoxes.where((b) {
      final s = b.status.toLowerCase();
      return s != 'empty' && s != 'deceased';
    }).length;
    if (inUse == 0) return 'disabled';
    return 'active';
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      areas = await _api.fetchAreas(token, farmId);
      final merged = <RowListItem>[];
      for (final area in areas) {
        final detail = await _api.fetchAreaDetail(token, area.id);
        for (final row in detail.rows) {
          final rowBoxes =
              detail.boxes.where((b) => b.rowId == row.id).toList();
          merged.add(
            RowListItem(
              row: row,
              areaId: area.id,
              areaCode: area.areaCode,
              areaName: area.areaName,
              boxCount: rowBoxes.length,
              status: deriveRowStatus(area, rowBoxes),
              esp32Count: area.esp32Count > 0 ? 1 : 0,
              cameraCount: area.cameraCount > 0 ? 1 : 0,
            ),
          );
        }
      }
      items = merged;
      summary = RowSummaryStats(
        total: items.length,
        active: items.where((r) => r.status == 'active').length,
        maintenance: items.where((r) => r.status == 'maintenance').length,
        disabled: items.where((r) => r.status == 'disabled').length,
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

  Future<void> deleteRow(RowListItem item) async {
    await _api.deleteRow(token, item.rowId);
    await load();
  }
}
