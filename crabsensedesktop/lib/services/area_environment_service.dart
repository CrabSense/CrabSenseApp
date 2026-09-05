import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/area_environment_metric.dart';
import '../models/auth_models.dart';
import 'cloud_api_client.dart';

class AreaEnvironmentService extends ChangeNotifier {
  AreaEnvironmentService({required AuthSession session, CloudApiClient? api})
      : _session = session,
        _api = api ?? CloudApiClient();

  final CloudApiClient _api;

  static const livePollInterval = Duration(seconds: 2);

  AuthSession _session;

  void updateSession(AuthSession session) {
    _session = session;
    stopLiveRefresh(notify: false);
    _data = null;
    _error = null;
    _notifyDeferred();
  }

  void _notifyDeferred() => Future.microtask(notifyListeners);

  var _loading = false;
  var _refreshInFlight = false;
  String? _error;
  AreaSensorLatestData? _data;
  DateTime? _lastRefreshedAt;

  Timer? _liveTimer;
  String? _liveAreaId;
  String? _liveBoxId;

  bool get loading => _loading;
  bool get isLiveActive => _liveTimer != null;
  bool get isRefreshing => _refreshInFlight;
  String? get error => _error;
  AreaSensorLatestData? get data => _data;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;
  List<AreaEnvironmentMetric> get metrics => _data?.metrics ?? const [];

  void startLiveRefresh(
    String areaId, {
    Duration interval = livePollInterval,
  }) {
    if (areaId.trim().isEmpty) return;
    if (_liveAreaId == areaId && _liveTimer != null) return;

    stopLiveRefresh(notify: false);
    _liveAreaId = areaId;
    _liveBoxId = null;
    unawaited(loadByArea(areaId));
    _liveTimer = Timer.periodic(interval, (_) {
      if (_liveAreaId == areaId) {
        unawaited(loadByArea(areaId, silent: true));
      }
    });
    _notifyDeferred();
  }

  void startLiveRefreshByBox(
    String boxId, {
    Duration interval = livePollInterval,
  }) {
    if (boxId.trim().isEmpty) return;
    if (_liveBoxId == boxId && _liveTimer != null) return;

    stopLiveRefresh(notify: false);
    _liveBoxId = boxId;
    _liveAreaId = null;
    unawaited(loadByBox(boxId));
    _liveTimer = Timer.periodic(interval, (_) {
      if (_liveBoxId == boxId) {
        unawaited(loadByBox(boxId, silent: true));
      }
    });
    _notifyDeferred();
  }

  void stopLiveRefresh({bool notify = true}) {
    _liveTimer?.cancel();
    _liveTimer = null;
    _liveAreaId = null;
    _liveBoxId = null;
    if (notify) _notifyDeferred();
  }

  Future<void> loadByArea(String areaId, {bool silent = false}) async {
    if (areaId.trim().isEmpty) return;
    await _fetchLive(
      areaId,
      liveKey: areaId,
      silent: silent,
      emptyMessage: 'Chưa có cảm biến / dữ liệu cho khu này',
    );
  }

  /// Chỉ số bể chung khu — hộp kế thừa từ `/api/iot/live`.
  Future<void> loadByBox(String boxId, {bool silent = false}) async {
    if (boxId.trim().isEmpty) return;
    await _fetchLive(
      _session.selectedFarm.id,
      liveKey: boxId,
      silent: silent,
      emptyMessage: 'Chưa có chỉ số môi trường cho hộp này',
      boxId: boxId,
    );
  }

  Future<void> _fetchLive(
    String areaId, {
    required String? liveKey,
    required bool silent,
    required String emptyMessage,
    String? boxId,
  }) async {
    if (silent && _refreshInFlight) return;

    if (!silent) {
      _loading = true;
      _error = null;
      _notifyDeferred();
    } else {
      _refreshInFlight = true;
      _notifyDeferred();
    }

    try {
      final live =
          await _api.fetchIotLive(_session.token, farmingAreaId: areaId);
      var data = AreaSensorLatestData.fromIotLive(areaId: areaId, live: live);
      if (boxId != null) {
        data = AreaSensorLatestData(
          areaId: data.areaId,
          areaCode: data.areaCode,
          areaName: data.areaName,
          scope: 'box',
          inheritedByBox: true,
          lastUpdatedAt: data.lastUpdatedAt,
          metrics: data.metrics,
          boxId: boxId,
        );
      }
      if (data.metrics.isEmpty) {
        _data = null;
        if (!silent) _error = emptyMessage;
      } else {
        _data = data;
        _error = null;
        _lastRefreshedAt = DateTime.now();
      }
    } catch (e) {
      if (!silent) {
        _data = null;
        _error = '$e';
      }
    } finally {
      if (silent) {
        _refreshInFlight = false;
      } else {
        _loading = false;
      }
      if (silent && liveKey != null) {
        if (_liveAreaId != liveKey && _liveBoxId != liveKey) return;
      }
      _notifyDeferred();
    }
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    _notifyDeferred();
  }

  @override
  void dispose() {
    stopLiveRefresh(notify: false);
    super.dispose();
  }
}
