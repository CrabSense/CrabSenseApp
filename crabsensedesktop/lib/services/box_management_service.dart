import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/box_list_item.dart';
import '../models/crab_condition.dart';
import '../models/production_models.dart';
import 'cloud_api_client.dart';

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
  BoxOccupancyFilter occupancyFilter = BoxOccupancyFilter.all;
  CrabConditionFilter crabFilter = CrabConditionFilter.all;
  int page = 0;
  static const int pageSize = 6;

  AuthSession get session => _session;
  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  List<RowRecord> get rowsForFilter {
    if (areaFilterId == null) return rows;
    return rows.where((r) => r.areaId == areaFilterId).toList();
  }

  void updateSession(AuthSession session) {
    _session = session;
    areas = [];
    rows = [];
    items = [];
    areaFilterId = _defaultAreaId(session);
    rowFilterId = null;
    occupancyFilter = BoxOccupancyFilter.all;
    crabFilter = CrabConditionFilter.all;
    page = 0;
    notifyListeners();
  }

  String? _defaultAreaId(AuthSession session) {
    final id = session.selectedFarm.id;
    return id.isEmpty ? null : id;
  }

  void setSearch(String value) {
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

  void setOccupancyFilter(BoxOccupancyFilter filter) {
    occupancyFilter = filter;
    page = 0;
    notifyListeners();
  }

  void setCrabFilter(CrabConditionFilter filter) {
    crabFilter = filter;
    page = 0;
    notifyListeners();
  }

  void setPage(int value) {
    page = value;
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
        final crab = i.box.crabTag?.toLowerCase() ?? '';
        return i.displayName.toLowerCase().contains(q) ||
            i.box.boxCode.toLowerCase().contains(q) ||
            crab.contains(q);
      }).toList();
    }

    list = switch (occupancyFilter) {
      BoxOccupancyFilter.occupied => list.where((i) => i.hasCrab).toList(),
      BoxOccupancyFilter.empty => list.where((i) => !i.hasCrab).toList(),
      BoxOccupancyFilter.alert => list.where((i) => i.hasAlert).toList(),
      BoxOccupancyFilter.all => list,
    };

    final crab = crabFilter.condition;
    if (crab != null) {
      list = list.where((i) => i.crabCondition == crab).toList();
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
      }).toList()
        ..sort((a, b) => a.box.boxCode.compareTo(b.box.boxCode));

      if (areaFilterId != null && !areas.any((a) => a.id == areaFilterId)) {
        areaFilterId = null;
      }
      if (rowFilterId != null &&
          !rowsForFilter.any((r) => r.id == rowFilterId)) {
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
