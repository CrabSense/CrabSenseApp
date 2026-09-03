import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/farm_layout.dart';
import '../models/production_models.dart';
import '../utils/farm_layout_mapper.dart';
import 'cloud_api_client.dart';

/// Tải toàn bộ hộp trại từ API areas + detail.
class FarmLayoutService extends ChangeNotifier {
  FarmLayoutService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

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

  bool loading = false;
  String? error;
  DateTime? loadedAt;

  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  void updateSession(AuthSession session) {
    _session = session;
    boxes = [];
    areas = [];
    zones = [];
    boxesPerZone.clear();
    _resetSummary();
    notifyListeners();
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
      final areaList = await _api.fetchAreas(token, farmId);
      final merged = <FarmMapBox>[];
      final perZone = <String, int>{};

      for (final area in areaList) {
        final detail = await _api.fetchAreaDetail(token, area.id);
        final rowById = {for (final r in detail.rows) r.id: r};

        for (final box in detail.boxes) {
          final row = rowById[box.rowId] ??
              RowRecord(
                id: box.rowId,
                areaId: area.id,
                rowCode: '—',
                rowName: '—',
              );
          merged.add(toFarmMapBox(box: box, area: area, row: row));
          final z = area.areaCode;
          perZone[z] = (perZone[z] ?? 0) + 1;
        }
      }

      merged.sort((a, b) {
        final z = a.areaCode.compareTo(b.areaCode);
        if (z != 0) return z;
        return a.display.id.compareTo(b.display.id);
      });

      areas = areaList;
      boxes = merged;
      zones = areaList.map((a) => a.areaCode).toList()..sort();
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
}
