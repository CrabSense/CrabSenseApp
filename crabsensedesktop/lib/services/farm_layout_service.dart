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

  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  static String? _areaIdOf(AuthSession session) {
    final id = session.selectedFarm.id.trim();
    return id.isEmpty ? null : id;
  }

  void updateSession(AuthSession session) {
    _session = session;
    selectedAreaId = _areaIdOf(session);
    boxes = [];
    areas = [];
    zones = [];
    boxesPerZone.clear();
    _resetSummary();
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
    if (loading && !force) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final areaList = await _api.fetchAreas(token, '');
      if (selectedAreaId != null &&
          !areaList.any((a) => a.id == selectedAreaId)) {
        final fromHeader = _areaIdOf(_session);
        selectedAreaId = areaList.any((a) => a.id == fromHeader)
            ? fromHeader
            : (areaList.isEmpty ? null : areaList.first.id);
      }

      final rows = await _api.fetchAllRows(token, areaId: selectedAreaId);
      final rawBoxes = await _api.fetchAllBoxes(token, areaId: selectedAreaId);
      final areaById = {for (final a in areaList) a.id: a};
      final rowById = {for (final r in rows) r.id: r};
      final merged = <FarmMapBox>[];
      final perZone = <String, int>{};

      for (final box in rawBoxes) {
        final row = rowById[box.rowId];
        final areaId = box.areaId ?? row?.areaId ?? selectedAreaId ?? '';
        final area = areaById[areaId] ??
            (areaList.isEmpty
                ? AreaRecord(
                    id: areaId,
                    farmId: farmId,
                    areaCode: box.areaCode ?? '—',
                    areaName: box.areaName ?? 'Khu',
                  )
                : areaList.first);
        final safeRow = row ??
            RowRecord(
              id: box.rowId,
              areaId: area.id,
              rowCode: box.rowCode ?? '—',
              rowName: box.rowName ?? '—',
            );
        merged.add(toFarmMapBox(box: box, area: area, row: safeRow));
        final z = area.areaCode;
        perZone[z] = (perZone[z] ?? 0) + 1;
      }

      merged.sort((a, b) {
        final z = a.areaCode.compareTo(b.areaCode);
        if (z != 0) return z;
        return a.display.id.compareTo(b.display.id);
      });

      areas = areaList;
      boxes = merged;
      zones = [
        for (final a in areaList)
          if (selectedAreaId == null || a.id == selectedAreaId) a.areaCode,
      ];
      boxesPerZone
        ..clear()
        ..addAll(perZone);
      summary = merged.toSummary();
      loadedAt = DateTime.now();
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

  String areaChipLabel(AreaRecord a) {
    final name = a.areaName.trim();
    if (name.isNotEmpty && name != a.areaCode) return name;
    return a.areaCode;
  }
}
