import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/box_list_item.dart';
import '../models/production_models.dart';
import 'cloud_api_client.dart';

enum BoxViewFilter { all, farming, empty, attention }

extension BoxViewFilterX on BoxViewFilter {
  String get label => switch (this) {
        BoxViewFilter.all => 'Tất cả',
        BoxViewFilter.farming => 'Đang nuôi',
        BoxViewFilter.empty => 'Hộp trống',
        BoxViewFilter.attention => 'Cần chú ý',
      };
}

class BoxRowStats {
  const BoxRowStats({
    required this.total,
    required this.farming,
    required this.empty,
    required this.attention,
  });

  final int total;
  final int farming;
  final int empty;
  final int attention;
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
  String? selectedAreaId;
  String? selectedRowId;
  BoxViewFilter viewFilter = BoxViewFilter.all;

  AuthSession get session => _session;
  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  RowRecord? get selectedRow {
    final id = selectedRowId;
    if (id == null) return null;
    for (final r in rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  void updateSession(AuthSession session) {
    _session = session;
    areas = [];
    rows = [];
    items = [];
    selectedAreaId = null;
    selectedRowId = null;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void setViewFilter(BoxViewFilter f) {
    viewFilter = f;
    notifyListeners();
  }

  Future<void> selectArea(String? areaId) async {
    selectedAreaId = areaId;
    selectedRowId = null;
    rows = [];
    notifyListeners();
    if (areaId == null) return;
    loading = true;
    notifyListeners();
    try {
      rows = await _api.fetchRows(token, areaId);
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

  void selectRow(String? rowId) {
    selectedRowId = rowId;
    notifyListeners();
  }

  static bool isEmptyBox(BoxRecord b) {
    final s = b.status.toLowerCase();
    return s == 'empty' || s == 'deceased';
  }

  static bool needsAttention(BoxRecord b) {
    final s = b.status.toLowerCase();
    return s == 'maintenance' ||
        s == 'alert' ||
        s == 'warning' ||
        s == 'disabled';
  }

  static bool isFarming(BoxRecord b) =>
      !isEmptyBox(b) && !needsAttention(b);

  List<BoxListItem> get _scopedItems {
    var list = items;
    if (selectedRowId != null) {
      list = list.where((i) => i.rowId == selectedRowId).toList();
    } else if (selectedAreaId != null) {
      list = list.where((i) => i.areaId == selectedAreaId).toList();
    }
    return list;
  }

  List<BoxListItem> get filteredItems {
    var list = _scopedItems;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((i) =>
              i.box.boxCode.toLowerCase().contains(q) ||
              (i.box.position?.toLowerCase().contains(q) ?? false) ||
              i.rowCode.toLowerCase().contains(q))
          .toList();
    }
    return switch (viewFilter) {
      BoxViewFilter.farming =>
        list.where((i) => isFarming(i.box)).toList(),
      BoxViewFilter.empty =>
        list.where((i) => isEmptyBox(i.box)).toList(),
      BoxViewFilter.attention =>
        list.where((i) => needsAttention(i.box)).toList(),
      BoxViewFilter.all => list,
    };
  }

  BoxRowStats get rowStats {
    final list = selectedRowId != null
        ? items.where((i) => i.rowId == selectedRowId)
        : _scopedItems;
    final boxes = list.map((i) => i.box).toList();
    return BoxRowStats(
      total: boxes.length,
      farming: boxes.where(isFarming).length,
      empty: boxes.where(isEmptyBox).length,
      attention: boxes.where(needsAttention).length,
    );
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      areas = await _api.fetchAreas(token, farmId);
      final merged = <BoxListItem>[];
      final rowList = <RowRecord>[];
      for (final area in areas) {
        final detail = await _api.fetchAreaDetail(token, area.id);
        rowList.addAll(detail.rows);
        for (final box in detail.boxes) {
          final row = detail.rows.firstWhere(
            (r) => r.id == box.rowId,
            orElse: () => RowRecord(
              id: box.rowId,
              areaId: area.id,
              rowCode: '—',
              rowName: '—',
            ),
          );
          merged.add(
            BoxListItem(
              box: box,
              areaId: area.id,
              areaCode: area.areaCode,
              areaName: area.areaName,
              rowId: row.id,
              rowCode: row.rowCode,
              rowName: row.rowName,
            ),
          );
        }
      }
      items = merged;
      if (selectedAreaId != null &&
          areas.any((a) => a.id == selectedAreaId)) {
        rows = await _api.fetchRows(token, selectedAreaId!);
      } else {
        rows = rowList
            .where((r) => selectedAreaId == null || r.areaId == selectedAreaId)
            .toList();
      }
      if (selectedRowId != null &&
          !rows.any((r) => r.id == selectedRowId)) {
        selectedRowId = null;
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
