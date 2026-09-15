import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/water_analysis.dart';
import 'cloud_api_client.dart';

class WaterAnalysisService extends ChangeNotifier {
  WaterAnalysisService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  WaterAnalysisSnapshot? _snapshot;
  bool _loading = false;
  bool _starting = false;
  String? _error;
  Timer? _poll;

  WaterAnalysisSnapshot? get snapshot => _snapshot;
  bool get loading => _loading;
  bool get starting => _starting;
  String? get error => _error;
  bool get isRunning => _snapshot?.active?.isRunning == true;

  void updateSession(AuthSession session) {
    _session = session;
    _snapshot = null;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchWaterAnalysis(
        _session.token,
        _session.selectedFarm.id,
      );
      _snapshot = WaterAnalysisSnapshot.fromJson(raw);
      _syncPoll();
    } on CloudApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> start() async {
    if (_starting || isRunning) return false;
    _starting = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.startWaterAnalysis(
        _session.token,
        _session.selectedFarm.id,
      );
      _snapshot = WaterAnalysisSnapshot.fromJson(raw);
      _syncPoll();
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = '$e';
      return false;
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  void _syncPoll() {
    _poll?.cancel();
    if (!isRunning) return;
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_tick());
    });
  }

  Future<void> _tick() async {
    try {
      final raw = await _api.fetchWaterAnalysis(
        _session.token,
        _session.selectedFarm.id,
      );
      _snapshot = WaterAnalysisSnapshot.fromJson(raw);
      if (!isRunning) _poll?.cancel();
      notifyListeners();
    } catch (e) {
      // Token hết hạn: dừng poll, nếu không Timer 1s sẽ gọi 401 mãi mãi.
      if (e is CloudApiException && e.statusCode == 401) {
        _poll?.cancel();
        _error = 'Phiên đăng nhập hết hạn';
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
