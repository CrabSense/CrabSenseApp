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
  bool _stopping = false;
  bool _savingSample = false;
  String? _error;
  String? _historyError;
  String? _systemError;
  Timer? _poll;

  WaterAnalysisSnapshot? get snapshot => _snapshot;
  bool get loading => _loading;
  bool get starting => _starting;
  bool get stopping => _stopping;
  bool get savingSample => _savingSample;
  String? get error => _error;
  String? get historyError => _historyError;
  String? get systemError => _systemError ?? _snapshot?.systemError;
  bool get isRunning => _snapshot?.active?.isRunning == true;
  bool get canStart => _snapshot?.canStart == true && !isRunning && !_starting;

  List<WaterAnalysisBlocker> get blockers =>
      _snapshot?.blockers ?? const <WaterAnalysisBlocker>[];

  void updateSession(AuthSession session) {
    _session = session;
    _snapshot = null;
    notifyListeners();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      _historyError = null;
      _systemError = null;
      notifyListeners();
    }
    try {
      final raw = await _api.fetchWaterAnalysis(
        _session.token,
        _session.selectedFarm.id,
      );
      _snapshot = WaterAnalysisSnapshot.fromJson(raw);
      _error = null;
      _historyError = null;
      _systemError = _snapshot?.systemError;
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

  Future<bool> start({
    required String analyte,
    String? sampleSource,
    String? sampleLocation,
    String? notes,
  }) async {
    if (_starting || isRunning) return false;
    if (_snapshot?.canStart != true) {
      _error = _snapshot?.blockers.isNotEmpty == true
          ? 'Chưa thể bắt đầu: ${_snapshot!.blockers.map((b) => '${b.label}: ${b.reason}').join(' • ')}'
          : 'Hệ thống chưa sẵn sàng.';
      notifyListeners();
      return false;
    }
    _starting = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.startWaterAnalysis(
        _session.token,
        _session.selectedFarm.id,
        analyte: analyte,
        sampleSource: sampleSource,
        sampleLocation: sampleLocation,
        notes: notes,
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

  Future<bool> stop() async {
    if (_stopping || !isRunning) return false;
    _stopping = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.stopWaterAnalysis(
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
      _stopping = false;
      notifyListeners();
    }
  }

  Future<WaterAnalysisDetail> fetchDetail(String runId) async {
    final raw = await _api.fetchWaterAnalysisDetail(
      _session.token,
      _session.selectedFarm.id,
      runId,
    );
    return WaterAnalysisDetail.fromJson(raw);
  }

  Future<bool> updateSample({
    required String sampleSource,
    String? sampleLocation,
    String? notes,
  }) async {
    _savingSample = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.updateWaterAnalysisSample(
        _session.token,
        _session.selectedFarm.id,
        sampleSource: sampleSource,
        sampleLocation: sampleLocation,
        notes: notes,
      );
      _snapshot = WaterAnalysisSnapshot.fromJson(raw);
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = '$e';
      return false;
    } finally {
      _savingSample = false;
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
