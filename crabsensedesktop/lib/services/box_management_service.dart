import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/box_list_item.dart';
import '../models/production_models.dart';
import 'cloud_api_client.dart';

class BoxKpiSnapshot {
  const BoxKpiSnapshot({
    required this.total,
    required this.occupied,
    required this.empty,
    required this.monitoring,
    required this.alerts,
  });

  final int total;
  final int occupied;
  final int empty;
  final int monitoring;
  final int alerts;
}

class BoxManagementService extends ChangeNotifier {
  BoxManagementService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<AreaRecord> areas = [];
  List<RowRecord> rows = [];
  List<BoxListItem> items = [];
  bool loading = false;
  String? error;
  String search = '';
  String? areaFilterId;
  String? rowFilterId;
  BoxStatusFilter statusFilter = BoxStatusFilter.all;
  BoxHealthFilter healthFilter = BoxHealthFilter.all;
  var alertOnly = false;
  BoxListSort sort = BoxListSort.newest;
  int page = 0;
  int pageSize = 12;

  AuthSession get session => _session;
  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  List<RowRecord> get rowsForFilter {
    if (areaFilterId == null) return rows;
    return rows.where((r) => r.areaId == areaFilterId).toList();
  }

  /// KPI từ toàn bộ hộp đã tải (không tính theo trang).
  BoxKpiSnapshot get kpi {
    final all = items;
    return BoxKpiSnapshot(
      total: all.length,
      occupied: all.where((i) => i.uiStatus == BoxUiStatus.occupied).length,
      empty: all.where((i) => i.uiStatus == BoxUiStatus.empty).length,
      monitoring: all.where((i) => i.healthUi == BoxHealthUi.monitoring).length,
      alerts: all.where((i) => i.hasAlert).length,
    );
  }

  void updateSession(AuthSession session) {
    _session = session;
    areas = [];
    rows = [];
    items = [];
    areaFilterId = _defaultAreaId(session);
    rowFilterId = null;
    statusFilter = BoxStatusFilter.all;
    healthFilter = BoxHealthFilter.all;
    alertOnly = false;
    sort = BoxListSort.newest;
    page = 0;
    notifyListeners();
  }

  String? _defaultAreaId(AuthSession session) {
    final id = session.selectedFarm.id;
    return id.isEmpty ? null : id;
  }

  void setSearch(String value) {
    if (search == value) return;
    search = value;
    page = 0;
    notifyListeners();
  }

  void setAreaFilter(String? areaId) {
    if (areaFilterId == areaId) return;
    areaFilterId = areaId;
    rowFilterId = null;
    page = 0;
    load();
  }

  void setRowFilter(String? rowId) {
    rowFilterId = rowId;
    page = 0;
    notifyListeners();
  }

  void setStatusFilter(BoxStatusFilter filter) {
    statusFilter = filter;
    if (filter != BoxStatusFilter.all) alertOnly = false;
    page = 0;
    notifyListeners();
  }

  void setHealthFilter(BoxHealthFilter filter) {
    healthFilter = filter;
    page = 0;
    notifyListeners();
  }

  void setAlertOnly(bool value) {
    alertOnly = value;
    if (value) statusFilter = BoxStatusFilter.all;
    page = 0;
    notifyListeners();
  }

  void setSort(BoxListSort value) {
    sort = value;
    notifyListeners();
  }

  void setPage(int value) {
    page = value;
    notifyListeners();
  }

  void setPageSize(int value) {
    if (pageSize == value) return;
    pageSize = value;
    page = 0;
    notifyListeners();
  }

  void clearFilters() {
    search = '';
    rowFilterId = null;
    statusFilter = BoxStatusFilter.all;
    healthFilter = BoxHealthFilter.all;
    alertOnly = false;
    page = 0;
    notifyListeners();
  }

  void applyKpi(BoxStatusFilter? status, {bool alerts = false, BoxHealthFilter? health}) {
    statusFilter = status ?? BoxStatusFilter.all;
    healthFilter = health ?? BoxHealthFilter.all;
    alertOnly = alerts;
    page = 0;
    notifyListeners();
  }

  void attachDevices(List<BoxListItem> next) {
    items = next;
    notifyListeners();
  }

  List<BoxListItem> get filteredItems {
    var list = items;
    if (areaFilterId != null) {
      list = list.where((i) => i.areaId == areaFilterId).toList();
    }
    if (rowFilterId != null) {
      list = list.where((i) => i.rowId == rowFilterId).toList();
    }

    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((i) {
        final hay = [
          i.box.boxCode,
          i.displayName,
          i.box.crabTag,
          i.box.position,
          i.areaName,
          i.areaCode,
          i.rowName,
          i.rowCode,
        ].whereType<String>().join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    }

    list = switch (statusFilter) {
      BoxStatusFilter.occupied => list.where((i) => i.uiStatus == BoxUiStatus.occupied).toList(),
      BoxStatusFilter.empty => list.where((i) => i.uiStatus == BoxUiStatus.empty).toList(),
      BoxStatusFilter.maintenance => list.where((i) => i.uiStatus == BoxUiStatus.maintenance).toList(),
      BoxStatusFilter.locked => list.where((i) => i.uiStatus == BoxUiStatus.locked).toList(),
      BoxStatusFilter.offline => list.where((i) => i.uiStatus == BoxUiStatus.offline || (i.deviceTotal > 0 && i.deviceOnline == 0)).toList(),
      BoxStatusFilter.all => list,
    };

    list = switch (healthFilter) {
      BoxHealthFilter.healthy => list.where((i) => i.healthUi == BoxHealthUi.healthy).toList(),
      BoxHealthFilter.monitoring => list.where((i) => i.healthUi == BoxHealthUi.monitoring).toList(),
      BoxHealthFilter.weak => list.where((i) => i.healthUi == BoxHealthUi.weak).toList(),
      BoxHealthFilter.alert => list.where((i) => i.healthUi == BoxHealthUi.alert).toList(),
      BoxHealthFilter.empty => list.where((i) => i.healthUi == BoxHealthUi.none).toList(),
      BoxHealthFilter.all => list,
    };

    if (alertOnly) {
      list = list.where((i) => i.hasAlert).toList();
    }

    list = [...list];
    int byCode(BoxListItem a, BoxListItem b) => a.box.boxCode.toLowerCase().compareTo(b.box.boxCode.toLowerCase());
    DateTime ts(BoxListItem i) => i.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    switch (sort) {
      case BoxListSort.newest:
        list.sort((a, b) {
          final c = ts(b).compareTo(ts(a));
          return c != 0 ? c : byCode(a, b);
        });
      case BoxListSort.codeAz:
        list.sort(byCode);
      case BoxListSort.codeZa:
        list.sort((a, b) => byCode(b, a));
      case BoxListSort.mostAlerts:
        list.sort((a, b) {
          final c = b.box.alertCount.compareTo(a.box.alertCount);
          return c != 0 ? c : byCode(a, b);
        });
      case BoxListSort.watchFirst:
        list.sort((a, b) {
          final aw = a.healthUi == BoxHealthUi.monitoring || a.healthUi == BoxHealthUi.weak || a.healthUi == BoxHealthUi.alert ? 1 : 0;
          final bw = b.healthUi == BoxHealthUi.monitoring || b.healthUi == BoxHealthUi.weak || b.healthUi == BoxHealthUi.alert ? 1 : 0;
          final c = bw.compareTo(aw);
          return c != 0 ? c : byCode(a, b);
        });
      case BoxListSort.emptyFirst:
        list.sort((a, b) {
          final ae = a.uiStatus == BoxUiStatus.empty ? 0 : 1;
          final be = b.uiStatus == BoxUiStatus.empty ? 0 : 1;
          final c = ae.compareTo(be);
          return c != 0 ? c : byCode(a, b);
        });
    }
    return list;
  }

  int get totalPages {
    final n = filteredItems.length;
    if (n == 0) return 1;
    return (n + pageSize - 1) ~/ pageSize;
  }

  List<BoxListItem> get pagedItems {
    final list = filteredItems;
    if (list.isEmpty) return [];
    final safePage = page.clamp(0, totalPages - 1);
    final start = safePage * pageSize;
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      areas = await _api.fetchAreas(token, '');
      if (areaFilterId != null && !areas.any((a) => a.id == areaFilterId)) {
        areaFilterId = _defaultAreaId(_session);
        if (areaFilterId != null && !areas.any((a) => a.id == areaFilterId)) {
          areaFilterId = null;
        }
      }
      rows = await _api.fetchAllRows(token, areaId: areaFilterId);
      final areaById = {for (final a in areas) a.id: a};
      final rowById = {for (final r in rows) r.id: r};
      final boxes = await _api.fetchAllBoxes(token, areaId: areaFilterId);
      items = boxes.map((box) {
        final row = rowById[box.rowId];
        final areaId = box.areaId ?? row?.areaId ?? '';
        final area = areaById[areaId];
        return BoxListItem(
          box: box,
          areaId: areaId,
          areaCode: box.areaCode ?? area?.areaCode ?? '',
          areaName: box.areaName ?? area?.areaName ?? '',
          rowId: box.rowId,
          rowCode: box.rowCode ?? row?.rowCode ?? '',
          rowName: box.rowName ?? row?.rowName ?? '',
        );
      }).toList();

      if (areaFilterId != null && !areas.any((a) => a.id == areaFilterId)) {
        areaFilterId = null;
      }
      if (rowFilterId != null && !rowsForFilter.any((r) => r.id == rowFilterId)) {
        rowFilterId = null;
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

  Future<void> deleteBox(BoxListItem item) async {
    await _api.deleteBox(token, item.box.id);
    await load();
  }
}
