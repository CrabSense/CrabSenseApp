import 'package:flutter/foundation.dart';

import '../models/area_status.dart';
import '../models/auth_models.dart';
import '../models/production_models.dart';
import 'cloud_api_client.dart';

class AreaManagementService extends ChangeNotifier {
  AreaManagementService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<AreaRecord> areas = [];
  AreaSummaryStats summary = const AreaSummaryStats(
    total: 0,
    active: 0,
    maintenance: 0,
    disabled: 0,
    totalBoxes: 0,
  );

  bool loading = false;
  String? error;
  String search = '';
  AreaStatusFilter statusFilter = AreaStatusFilter.all;
  int page = 0;
  static const int pageSize = 8;

  AuthSession get session => _session;
  String get farmId => _session.selectedFarm.id;
  String get token => _session.token;

  void updateSession(AuthSession session) {
    _session = session;
    areas = [];
    summary = const AreaSummaryStats(
      total: 0,
      active: 0,
      maintenance: 0,
      disabled: 0,
      totalBoxes: 0,
    );
    page = 0;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    page = 0;
    notifyListeners();
  }

  void setStatusFilter(AreaStatusFilter filter) {
    statusFilter = filter;
    page = 0;
    notifyListeners();
  }

  void setPage(int value) {
    page = value;
    notifyListeners();
  }

  List<AreaRecord> get filteredAreas {
    var list = areas;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((a) =>
              a.areaCode.toLowerCase().contains(q) ||
              a.areaName.toLowerCase().contains(q) ||
              (a.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    final status = statusFilter.apiValue;
    if (status.isNotEmpty) {
      list = list.where((a) => a.status == status).toList();
    }
    return list;
  }

  int get totalPages {
    final n = filteredAreas.length;
    if (n == 0) return 1;
    return (n + pageSize - 1) ~/ pageSize;
  }

  List<AreaRecord> get pagedAreas {
    final list = filteredAreas;
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
      final result = await _api.fetchAreasWithSummary(token, farmId);
      areas = result.areas;
      summary = result.summary;
      if (areas.isNotEmpty && summary.total == 0) {
        summary = AreaSummaryStats(
          total: areas.length,
          active: areas.where((a) => a.status == 'active').length,
          maintenance: areas.where((a) => a.status == 'maintenance').length,
          disabled: areas.where((a) => a.status == 'disabled').length,
          totalBoxes: areas.fold(0, (s, a) => s + a.boxCount),
        );
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

  Future<String> fetchNextAreaCode() =>
      _api.fetchNextAreaCode(token, farmId);

  Future<AreaRecord> createArea({
    required String areaName,
    String? description,
    String status = 'active',
  }) async {
    final a = await _api.createArea(
      token,
      farmId,
      areaName: areaName,
      description: description,
      status: status,
    );
    await load();
    return a;
  }

  Future<AreaRecord> updateArea(
    AreaRecord item, {
    required String areaName,
    String? description,
    required String status,
  }) async {
    final a = await _api.updateArea(
      token,
      item.id,
      areaCode: item.areaCode,
      areaName: areaName,
      description: description,
      status: status,
    );
    await load();
    return a;
  }

  Future<void> deleteArea(AreaRecord item) async {
    await _api.deleteArea(token, item.id);
    await load();
  }

  Future<({AreaRecord detail, List<RowRecord> rows, List<BoxRecord> boxes})>
      loadAreaDetail(String areaId) =>
          _api.fetchAreaDetail(token, areaId);
}
