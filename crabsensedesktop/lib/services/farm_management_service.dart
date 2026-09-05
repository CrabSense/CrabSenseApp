import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/farm_record.dart';
import 'cloud_api_client.dart';

class FarmManagementService extends ChangeNotifier {
  FarmManagementService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<FarmRecord> _farms = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  FarmStatus? _statusFilter;
  int _currentPage = 1;

  static const int pageSize = 6;

  AuthSession get session => _session;
  bool get canManageFarms => _session.canManageFarms;
  List<FarmRecord> get farms => _farms;
  bool get loading => _loading;
  String? get error => _error;
  int get currentPage => _currentPage;
  FarmStatus? get statusFilter => _statusFilter;
  int get filteredCount => filteredFarms.length;
  int get totalPages {
    final n = filteredCount;
    if (n == 0) return 1;
    return ((n + pageSize - 1) ~/ pageSize).clamp(1, 999);
  }

  List<FarmRecord> get filteredFarms {
    final q = _search.trim().toLowerCase();
    return _farms.where((f) {
      if (_statusFilter != null && f.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      return f.code.toLowerCase().contains(q) ||
          f.name.toLowerCase().contains(q) ||
          f.displayLocation.toLowerCase().contains(q) ||
          (f.location?.toLowerCase().contains(q) ?? false) ||
          (f.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<FarmRecord> get pagedFarms {
    final list = filteredFarms;
    if (list.isEmpty) return const [];
    final page = _currentPage.clamp(1, totalPages);
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, list.length);
    if (start >= list.length) return const [];
    return list.sublist(start, end);
  }

  void goToPage(int page) {
    final next = page.clamp(1, totalPages);
    if (next == _currentPage) return;
    _currentPage = next;
    notifyListeners();
  }

  void _clampPage() {
    final max = totalPages;
    if (_currentPage > max) _currentPage = max;
    if (_currentPage < 1) _currentPage = 1;
  }

  void updateSession(AuthSession session) {
    _session = session;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    _currentPage = 1;
    notifyListeners();
  }

  void setStatusFilter(FarmStatus? value) {
    _statusFilter = value;
    _currentPage = 1;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _farms = await _api.fetchFarmRecords(_session.token);
      _clampPage();
      _error = null;
    } on CloudApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> fetchNextCode() => _api.fetchNextFarmCode(_session.token);

  Future<FarmRecord?> create({
    required String name,
    String? location,
    double? areaSquareMeters,
    String? description,
    FarmStatus status = FarmStatus.active,
  }) async {
    try {
      final farm = await _api.createFarm(
        _session.token,
        name: name,
        location: location,
        areaSquareMeters: areaSquareMeters,
        description: description,
        status: status,
      );
      _farms = [..._farms, farm]..sort((a, b) => a.code.compareTo(b.code));
      _currentPage = totalPages;
      notifyListeners();
      return farm;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<FarmRecord?> update(
    FarmRecord existing, {
    required String name,
    String? location,
    double? areaSquareMeters,
    String? description,
    FarmStatus status = FarmStatus.active,
  }) async {
    try {
      final farm = await _api.updateFarm(
        _session.token,
        existing.id,
        name: name,
        location: location,
        areaSquareMeters: areaSquareMeters,
        description: description,
        status: status,
      );
      _farms = _farms.map((f) => f.id == farm.id ? farm : f).toList()
        ..sort((a, b) => a.code.compareTo(b.code));
      notifyListeners();
      return farm;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> delete(FarmRecord farm) async {
    try {
      await _api.deleteFarm(_session.token, farm.id);
      _farms = _farms.where((f) => f.id != farm.id).toList();
      _clampPage();
      notifyListeners();
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
