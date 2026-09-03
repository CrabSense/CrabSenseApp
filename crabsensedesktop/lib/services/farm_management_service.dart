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

  AuthSession get session => _session;
  bool get canManageFarms => _session.canManageFarms;
  List<FarmRecord> get farms => _farms;
  bool get loading => _loading;
  String? get error => _error;

  List<FarmRecord> get filteredFarms {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _farms;
    return _farms
        .where((f) =>
            f.code.toLowerCase().contains(q) ||
            f.name.toLowerCase().contains(q) ||
            (f.address?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  void updateSession(AuthSession session) {
    _session = session;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _farms = await _api.fetchFarmRecords(_session.token);
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
    String? address,
    String? description,
  }) async {
    try {
      final farm = await _api.createFarm(
        _session.token,
        name: name,
        address: address,
        description: description,
      );
      _farms = [..._farms, farm]..sort((a, b) => a.code.compareTo(b.code));
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
    String? address,
    String? description,
  }) async {
    try {
      final farm = await _api.updateFarm(
        _session.token,
        existing.id,
        name: name,
        address: address,
        description: description,
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
      notifyListeners();
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
