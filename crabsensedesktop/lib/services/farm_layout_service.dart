import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/farm_layout.dart';
import '../models/production_models.dart';
import '../utils/farm_layout_mapper.dart';
import 'cloud_api_client.dart';

/// Bản đồ trại — hộp theo khu đang chọn trên header (selectedFarm = FarmingArea).
class FarmLayoutService extends ChangeNotifier {
  FarmLayoutService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient(),
        selectedAreaId = _areaIdOf(session);

  static const columnsPerRow = 10;

  AuthSession _session;
  final CloudApiClient _api;

  List<FarmMapBox> boxes = [];
  List<AreaRecord> areas = [];
  List<RowRecord> rows = [];
  List<String> zones = [];
  final Map<String, int> boxesPerZone = {};
  FarmLayoutSummary summary = const FarmLayoutSummary(
    total: 0,
    occupied: 0,
    empty: 0,
    normal: 0,
    watch: 0,
    molting: 0,
    alert: 0,
    deceased: 0,
  );

  /// null = tất cả khu; ngược lại = id FarmingArea.
  String? selectedAreaId;

  bool loading = false;
  String? error;
  DateTime? loadedAt;
  int _generation = 0;
  bool _disposed = false;

  void _clearSnapshot() {
    boxes = []; areas = []; rows = []; zones = [];
    boxesPerZone.clear(); loadedAt = null; _resetSummary();
  }

  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  static String? _areaIdOf(AuthSession session) {
    final id = session.selectedFarm.id.trim();
    return id.isEmpty ? null : id;
  }

  void updateSession(AuthSession session) {
    ++_generation;
    _session = session;
    selectedAreaId = _areaIdOf(session);
    loading = false;
    error = null;
    _clearSnapshot();
    notifyListeners();
  }

  Future<void> selectArea(String? areaId) async {
    if (selectedAreaId == areaId && boxes.isNotEmpty && !loading) return;
    selectedAreaId = areaId;
    await load(force: true);
  }

  void _resetSummary() {
    summary = const FarmLayoutSummary(
      total: 0,
      occupied: 0,
      empty: 0,
      normal: 0,
      watch: 0,
      molting: 0,
      alert: 0,
      deceased: 0,
    );
  }

  Future<void> load({bool force = false}) async {
    if (_disposed || (loading && !force)) return;
    final generation = ++_generation;
    final bearer = token;
    final requestedArea = selectedAreaId;
    bool current() => !_disposed && generation == _generation && bearer == token;
    _clearSnapshot();
    loading = true;
    error = null;
    notifyListeners();

    try {
      final areaList = await _api.fetchAreas(bearer, '');
      if (!current()) return;
      if (requestedArea != null && !areaList.any((a) => a.id == requestedArea)) {
        throw StateError('Khu nuôi chưa được xác minh quyền truy cập.');
      }
      if (areaList.isEmpty) return;
      final fetchedRows = await _api.fetchAllRows(bearer, areaId: requestedArea);
      if (!current()) return;
      final rawBoxes = await _api.fetchAllBoxes(bearer, areaId: requestedArea);
      if (!current()) return;
      final areaById = {for (final a in areaList) a.id: a};
      final rowById = {for (final r in fetchedRows)
        if (areaById.containsKey(r.areaId) &&
            (requestedArea == null || requestedArea == r.areaId)) r.id: r};
      final merged = <FarmMapBox>[];
      final perZone = <String, int>{};
      final ids = <String>{};
      for (final box in rawBoxes) {
        final item = scopedFarmMapBox(box: box, areas: areaById,
          rows: rowById, selectedAreaId: requestedArea);
        if (item == null || box.id.isEmpty || !ids.add(box.id)) {
          throw StateError('Dữ liệu hộp không khớp phạm vi khu/dãy.');
        }
        merged.add(item);
        perZone[item.areaCode] = (perZone[item.areaCode] ?? 0) + 1;
      }
      merged.sort((a, b) {
        final z = a.areaCode.compareTo(b.areaCode);
        return z != 0 ? z : a.display.id.compareTo(b.display.id);
      });
      areas = areaList;
      rows = rowById.values.toList();
      boxes = merged;
      zones = [for (final a in areaList)
        if (requestedArea == null || a.id == requestedArea) a.areaCode];
      boxesPerZone.addAll(perZone);
      summary = merged.toSummary();
      // Local fetch time, not a measurement or box update timestamp.
      loadedAt = DateTime.now();
    } catch (e) {
      if (!current()) return;
      _clearSnapshot();
      error = e is CloudApiException ? e.message : '$e';
    } finally {
      if (current()) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    super.dispose();
  }

  String mascotMessage() => boxes.mascotMessage();

  int zoneCapacity(String zone) => boxesPerZone[zone] ?? 0;

  AreaRecord? get selectedArea {
    final id = selectedAreaId;
    if (id == null) return null;
    for (final a in areas) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<RowRecord> rowsForArea(String? areaId) {
    if (areaId == null || areaId.isEmpty) return List.of(rows);
    return rows.where((r) => r.areaId == areaId).toList();
  }

  String areaChipLabel(AreaRecord a) {
    final name = a.areaName.trim();
    if (name.isNotEmpty && name != a.areaCode) return name;
    return a.areaCode;
  }
}
