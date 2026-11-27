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

  bool _disposed = false;
  int _generation = 0;
  int _version = 0;
  bool _current(int generation, int version) => !_disposed && generation == _generation && version == _version;
  void _notifyDeferred() {
    if (!_disposed) Future.microtask(() { if (!_disposed) notifyListeners(); });
  }

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
  AreaSensorLatestData? get data {
    final at=_lastRefreshedAt;
    if(at==null)return null;
    final age=DateTime.now().difference(at);
    return !age.isNegative && age<const Duration(seconds:15) ? _data : null;
  }
  AreaSensorLatestData? dataForBox(String areaId,String boxId) {
    final value=data;
    return value?.areaId==areaId && value?.boxId==boxId && value?.scope=='box' ? value : null;
  }
  DateTime? get lastRefreshedAt => _lastRefreshedAt;
  List<AreaEnvironmentMetric> get metrics => data?.metrics ?? const [];

  void startLiveRefresh(
    String areaId, {
    Duration interval = livePollInterval,
  }) {
    if (_disposed || areaId.trim().isEmpty) return;
    if (_liveAreaId == areaId && _liveBoxId == null && _liveTimer != null) return;

    stopLiveRefresh(notify: false);
    _data = null;
    _lastRefreshedAt = null;
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

  void startLiveRefreshByBox(String boxId,{String? areaId,
      Duration interval=livePollInterval}) {
    if(_disposed)return;
    if(boxId.trim().isEmpty || areaId==null || areaId.isEmpty) {
      clear();
      return;
    }
    if(_liveBoxId==boxId && _liveAreaId==areaId && _liveTimer!=null)return;
    stopLiveRefresh(notify:false);
    _liveBoxId=boxId;
    _liveAreaId=areaId;
    unawaited(loadByBox(boxId,areaId:areaId));
    _liveTimer=Timer.periodic(interval,(_){
      if(_liveBoxId==boxId && _liveAreaId==areaId) {
        unawaited(loadByBox(boxId,areaId:areaId,silent:true));
      }
    });
    _notifyDeferred();
  }

  void stopLiveRefresh({bool notify = true}) {
    ++_generation;
    _loading = false;
    _refreshInFlight = false;
    _liveTimer?.cancel();
    _liveTimer = null;
    _liveAreaId = null;
    _liveBoxId = null;
    _data = null;
    _lastRefreshedAt = null;
    if (notify) _notifyDeferred();
  }

  Future<void> loadByArea(String areaId, {bool silent = false}) async {
    if (_disposed || areaId.trim().isEmpty) return;
    await _fetchLive(
      areaId,
      silent: silent,
      emptyMessage: 'Chưa có cảm biến / dữ liệu cho khu này',
    );
  }

  /// All boxes inherit the same area-level RAS reference, not a selected
  /// farm fallback or an individual box/row sample.
  Future<void> loadByBox(String boxId,{String? areaId,bool silent=false}) async {
    if(_disposed)return;
    if(boxId.isEmpty || areaId==null || areaId.isEmpty) {
      clear();
      return;
    }
    await _fetchLive(areaId,silent:silent,emptyMessage:'Chưa có phép đo chung của khu.',
      boxId:boxId);
  }

  Future<void> _fetchLive(
    String areaId, {
    required bool silent,
    required String emptyMessage,
    String? boxId,
  }) async {
    if (_disposed || (silent && (_refreshInFlight || _loading))) return;
    final generation = _generation;
    final version = ++_version;
    if(!UserRoles.canUseDesktop(_session.user.role) || areaId=='default' ||
        (!_session.farms.any((f)=>f.id==areaId) && _session.selectedFarm.id!=areaId)) {
      _data=null;_lastRefreshedAt=null;_loading=false;_refreshInFlight=false;
      _error='Chưa xác minh quyền khu nuôi.';
      _notifyDeferred();
      return;
    }

    if (!silent || _data?.areaId!=areaId || _data?.boxId!=boxId) {
      _data=null;
      _lastRefreshedAt=null;
      _loading = true;
      _error = null;
      _notifyDeferred();
    } else {
      _refreshInFlight = true;
      _notifyDeferred();
    }

    try {
      final live =
          await _api.fetchIotLive(_session.token, farmingAreaId: areaId)
              .timeout(const Duration(seconds:10));
      if (!_current(generation, version)) return;
      final data=AreaSensorLatestData.fromIotLive(areaId:areaId,live:live,boxId:boxId);
      if (data.metrics.isEmpty) {
        _data = null;
        _lastRefreshedAt=null;
        _error = emptyMessage;
      } else {
        _data = data;
        _error = null;
        _lastRefreshedAt = DateTime.now();
      }
    } catch (e) {
      if (!_current(generation, version)) return;
      if (e is CloudApiException && e.statusCode == 401) {
        // Token hết hạn: dừng poll, nếu không Timer 2s sẽ gọi 401 mãi mãi.
        _error = 'Phiên đăng nhập hết hạn';
        stopLiveRefresh(notify: false);
        _data = null;
        _lastRefreshedAt = null;
        _notifyDeferred();
      } else {
        _data = null;
        _lastRefreshedAt=null;
        _error = 'Không xác minh được dữ liệu môi trường.';
      }
    } finally {
      if (_current(generation, version)) {
        _refreshInFlight = false;
        _loading = false;
        _notifyDeferred();
      }
    }
  }

  // Legacy history cannot prove the measurement's observed scope.
  Future<List<({DateTime at,double value})>> fetchSensorHistory(String sensorId,{
    required DateTime from,required DateTime to,
  }) async => const [];

  Future<List<Map<String, dynamic>>> fetchAlertHistory({String? farmingAreaId}) {
    return _api.fetchAlertHistory(
      _session.token,
      farmingAreaId: farmingAreaId,
      days: 30,
    );
  }

  Future<void> refreshCurrent() async {
    final boxId = _liveBoxId;
    if (boxId != null) {
      await loadByBox(boxId,areaId:_liveAreaId);
      return;
    }
    final areaId = _liveAreaId;
    if (areaId != null) await loadByArea(areaId);
  }

  void clear() {
    stopLiveRefresh(notify:false);
    _refreshInFlight = false;
    _lastRefreshedAt = null;
    _data = null;
    _error = null;
    _loading = false;
    _notifyDeferred();
  }

  @override
  void dispose() {
    _disposed = true;
    stopLiveRefresh(notify: false);
    super.dispose();
  }
}
