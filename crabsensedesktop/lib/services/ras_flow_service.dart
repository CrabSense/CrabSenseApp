import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/ras_flow.dart';
import 'cloud_auth_service.dart';

class RasFlowService extends ChangeNotifier {
  RasFlowService({required AuthSession session, http.Client? client})
      : _session = session, _client = client ?? http.Client(), _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  int _generation = 0;
  int _readVersion = 0;
  int _powerVersion = 0;
  bool _mutating = false;
  bool _current(int generation) => !_disposed && generation == _generation;
  bool _assigned(String area) => area.isNotEmpty && _session.farms.any((f) => f.id == area);
  bool get hardwareDisabled => _diagram?.hardwareControlDisabled != false;
  bool get canOperate => _session.user.role == UserRoles.farmManager &&
      !hardwareDisabled && !_disposed && !_mutating && _diagram != null &&
      _assigned(_diagram!.areaId) && _diagram!.areaId == _session.selectedFarm.id &&
      _lastRefreshedAt != null && DateTime.now().difference(_lastRefreshedAt!) <= const Duration(seconds: 30);

  /// Live view refresh. Backend /api/iot/live is heavy, so 5s matches the Edge
  /// telemetry cadence instead of hammering it every 2s.
  static const livePollInterval = Duration(seconds: 5);

  AuthSession _session;

  bool get canManageStructure => _session.user.isFarmOwner;
  bool get canConfigureRelay => _session.user.isSystemAdmin;

  void updateSession(AuthSession session) {
    _session = session;
    stopLiveRefresh(notify: false);
    _diagram = null;
    _power = const PowerSnapshot();
    _lastRefreshedAt = null;
    _error = null;
    _notifyDeferred();
  }

  bool _disposed = false;

  void _notifyDeferred() {
    if (_disposed) return;
    Future.microtask(() {
      // A screen may leave while a refresh or HTTP request is still pending.
      if (!_disposed) notifyListeners();
    });
  }

  var _loading = false;
  var _refreshInFlight = false;
  String? _error;
  RasFlowDiagram? _diagram;
  DateTime? _lastRefreshedAt;

  Timer? _liveTimer;
  Timer? _meterTimer;
  String? _liveAreaId;
  PowerSnapshot _power = const PowerSnapshot();

  bool get loading => _loading;
  bool get isLiveActive => _liveTimer != null;
  bool get isRefreshing => _refreshInFlight;
  String? get error => _error;
  RasFlowDiagram? get diagram => _diagram;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;
  PowerSnapshot get power => _power;

  /// Bật làm mới sơ đồ RAS mỗi [interval] (mặc định 5s, khớp telemetry Edge ~5s).
  void startLiveRefresh(
    String areaId, {
    Duration interval = livePollInterval,
  }) {
    if (_disposed || !_assigned(areaId)) return;
    if (_liveAreaId == areaId && _liveTimer != null) return;

    stopLiveRefresh(notify: false);
    _diagram = null;
    _power = const PowerSnapshot();
    _lastRefreshedAt = null;
    _error = null;
    _liveAreaId = areaId;
    unawaited(loadDiagram(areaId));
    unawaited(refreshPower());
    _meterTimer = Timer.periodic(interval, (_) {
      unawaited(refreshPower());
    });
    _liveTimer = Timer.periodic(interval, (_) {
      if (_liveAreaId == areaId) {
        unawaited(loadDiagram(areaId, silent: true));
      }
    });
    _notifyDeferred();
  }

  void stopLiveRefresh({bool notify = true}) {
    ++_generation;
    _loading = false;
    _refreshInFlight = false;
    _mutating = false;
    _liveTimer?.cancel();
    _meterTimer?.cancel();
    _liveTimer = null;
    _meterTimer = null;
    _liveAreaId = null;
    if (notify) _notifyDeferred();
  }

  Future<void> loadDiagram(
    String areaId, {
    bool silent = false,
    bool allowRefresh = true,
  }) async {
    if (_disposed || !_assigned(areaId) ||
        (_liveAreaId != null && _liveAreaId != areaId) || _mutating ||
        (silent && (_loading || _refreshInFlight))) return;
    final generation = _generation;
    final version = ++_readVersion;
    bool active() => _current(generation) && version == _readVersion;
    if (!silent) {
      _loading = true;
      _error = null;
      _notifyDeferred();
    } else {
      _refreshInFlight = true;
    }
    try {
      final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow');
      var res = await _client.get(uri, headers: _headers());
      if (!active()) return;
      if (res.statusCode == 401 && allowRefresh && await _renew(generation)) {
        if (!active()) return;
        res = await _client.get(uri, headers: _headers());
      }
      if (!active()) return;
      if (res.statusCode == 401) {
        stopLiveRefresh(notify: false);
        _diagram = null;
        _power = const PowerSnapshot();
        _lastRefreshedAt = null;
        _error = 'Phiên đăng nhập hết hạn';
        _notifyDeferred();
        return;
      }
      final next = RasFlowDiagram.fromJson(_requireData(res));
      if (next.areaId != areaId) throw StateError('Phản hồi RAS sai khu nuôi.');
      _diagram = next;
      _error = null;
      _lastRefreshedAt = DateTime.now();
    } catch (e) {
      if (!active()) return;
      _error = e.toString();
      if (!silent) _diagram = null;
    } finally {
      if (active()) {
        _loading = false;
        _refreshInFlight = false;
        _notifyDeferred();
      }
    }
  }

  Object? _parseParamDefaults(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    try {
      return jsonDecode(t);
    } catch (_) {
      return {'label': t};
    }
  }

  Future<List<({String id, String code, String name, String ip})>> areaControllers(
    String areaId,
  ) async {
    if (_disposed || !_assigned(areaId)) return const [];
    final generation = _generation;
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/devices').replace(
      queryParameters: {'farmingAreaId': areaId},
    );
    final res = await _client.get(uri, headers: _headers());
    if (!_current(generation)) return const [];
    if (res.statusCode == 401 && await _renew(generation)) {
      if (!_current(generation)) return const [];
      final again = await _client.get(uri, headers: _headers());
      return _current(generation) ? _controllersFrom(again) : const [];
    }
    return _current(generation) ? _controllersFrom(res) : const [];
  }

  List<({String id, String code, String name, String ip})> _controllersFrom(
    http.Response res,
  ) {
    if (res.statusCode < 200 || res.statusCode >= 300) return const [];
    final data = _decode(res.body)['data'] ?? _decode(res.body)['Data'];
    if (data is! List) return const [];
    final out = <({String id, String code, String name, String ip})>[];
    for (final raw in data) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final code = (m['deviceCode'] ?? m['DeviceCode'] ?? '').toString();
      if (code.isEmpty) continue;
      out.add((
        id: (m['id'] ?? m['Id'] ?? '').toString(),
        code: code,
        name: (m['name'] ?? m['Name'] ?? code).toString(),
        ip: (m['ipAddress'] ?? m['IpAddress'] ?? '').toString(),
      ));
    }
    return out;
  }

  Future<bool> addFlow({
    required String areaId,
    required String fromId,
    required String toId,
  }) {
    if (!canManageStructure) {
      _error = 'Cấu hình RAS thuộc quyền quản trị trên Web.';
      return Future.value(false);
    }
    return _mutate(
      () => _client.post(
        Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow/flows'),
        headers: _headers(),
        body: jsonEncode({
          'fromComponentId': fromId,
          'toComponentId': toId,
        }),
      ),
      areaId,
    );
  }

  Future<bool> deleteFlow({
    required String areaId,
    required String flowId,
  }) {
    if (!canManageStructure) {
      _error = 'Cấu hình RAS thuộc quyền quản trị trên Web.';
      return Future.value(false);
    }
    return _mutate(
      () => _client.delete(
        Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow/flows/$flowId'),
        headers: _headers(),
      ),
      areaId,
    );
  }

  Future<bool> reorderNodes({
    required String areaId,
    required List<String> nodeIdsInOrder,
  }) async {
    if (!canManageStructure) {
      _error = 'Cấu hình RAS thuộc quyền quản trị trên Web.';
      return false;
    }
    return _mutate(
      () => _client.post(
        Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow/reorder'),
        headers: _headers(),
        body: jsonEncode({'nodeIds': nodeIdsInOrder}),
      ),
      areaId,
    );
  }

    Future<bool> addNode({
    required String areaId,
    required String nodeCode,
    required String displayLabel,
    required int sortOrder,
    String? relayChannel,
    String? relayDeviceId,
    String nodeType = 'equipment',
    String? type,
    String? paramDefaults,
  }) async {
    if (!canManageStructure) {
      _error = 'Cấu hình RAS thuộc quyền quản trị trên Web.';
      return false;
    }
    return _mutate(
      () => _client.post(
        Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow/nodes'),
        headers: _headers(),
        body: jsonEncode({
          'nodeCode': nodeCode,
          'displayLabel': displayLabel,
          'sortOrder': sortOrder,
          'nodeType': nodeType,
          if (type != null && type.isNotEmpty) 'type': type,
          if (relayChannel != null && relayChannel.isNotEmpty)
            'relayChannel': relayChannel,
          if (relayDeviceId != null && relayDeviceId.isNotEmpty)
            'relayDeviceId': relayDeviceId,
          if (paramDefaults != null && paramDefaults.isNotEmpty)
            'paramDefaults': _parseParamDefaults(paramDefaults),
        }),
      ),
      areaId,
    );
  }

  Future<bool> updateNodeRelay({
    required String areaId,
    required String nodeId,
    String? relayDeviceId,
    String? relayDeviceCode,
    String? relayChannel,
    String? paramDefaultsJson,
  }) async {
    if (!canConfigureRelay) {
      _error = 'Cấu hình RAS thuộc quyền quản trị trên Web.';
      return false;
    }
    return _mutate(
      () => _client.put(
        Uri.parse(
          '${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow/nodes/$nodeId/relay',
        ),
        headers: _headers(),
        body: jsonEncode({
          'relayDeviceId': relayDeviceId,
          'relayDeviceCode': relayDeviceCode,
          'paramDefaultsJson': paramDefaultsJson,
          'relayChannel': relayChannel,
        }),
      ),
      areaId,
    );
  }

  Future<bool> deleteNode({
    required String areaId,
    required String nodeId,
  }) async {
    if (!canManageStructure) {
      _error = 'Cấu hình RAS thuộc quyền quản trị trên Web.';
      return false;
    }
    return _mutate(
      () => _client.delete(
        Uri.parse(
          '${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow/nodes/$nodeId',
        ),
        headers: _headers(),
      ),
      areaId,
      expectNoContent: true,
    );
  }

  Future<void> reportRelay({
    required String deviceCode,
    required int channel,
    required bool on,
  }) async {
    try {
      await _client.post(
        Uri.parse('${AppEnv.cloudApiUrl}/api/iot/relay-state'),
        headers: _headers(),
        body: jsonEncode({
          'deviceCode': deviceCode,
          'channel': channel,
          'on': on,
        }),
      );
    } catch (_) {}
  }

  Future<bool> sendCommand({
    required String areaId,
    required String nodeId,
    required String command,
  }) async {
    final node = _diagram?.nodes.where((n) => n.id == nodeId).firstOrNull;
    final normalized = command.trim().toLowerCase();
    if (!canOperate || _diagram?.areaId != areaId || node == null ||
        !node.hasRelay || node.isOnline != true ||
        node.relayDeviceId == null || node.relayDeviceId!.isEmpty ||
        (node.relayChannel ?? '').isEmpty || node.portPresent == false ||
        node.commandPending || !const {'on','off','start','stop','auto','manual'}.contains(normalized)) {
      _error = 'Lệnh bị chặn: kiểm tra khu, kết nối, cấu hình cổng và trạng thái xác nhận.';
      _notifyDeferred();
      return false;
    }
    return _mutate(
      () => _client.post(
        Uri.parse(
          '${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow/nodes/$nodeId/command',
        ),
        headers: _headers(),
        body: jsonEncode({'command': normalized}),
      ),
      areaId,
    );
  }

  Future<void> refreshPower() async {
    final area = _liveAreaId;
    if (_disposed || area == null || !_assigned(area)) return;
    final generation = _generation;
    final version = ++_powerVersion;
    try {
      final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/iot/live').replace(
        queryParameters: {
          'farmingAreaId': area,
        },
      );
      final res = await _client.get(
        uri,
        headers: _headers(),
      );
      if (res.statusCode != 200) return;
      final body = _decode(res.body);
      final data = body['data'] ?? body['Data'];
      if (data is! List) return;
      final points = <String, PowerPoint>{};
      for (final raw in data) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final code = (row['sensorCode'] ?? row['SensorCode'] ?? '').toString();
        if (!code.startsWith('meter_') && !code.startsWith('float_')) continue;
        final valueRaw = row['latestValue'] ?? row['LatestValue'];
        final atRaw = row['latestMeasuredAt'] ?? row['LatestMeasuredAt'];
        final at = atRaw == null ? null : DateTime.tryParse(atRaw.toString());
        if (code.startsWith('meter_')
            && (at == null
                || DateTime.now().toUtc().difference(at.toUtc()).abs()
                    > const Duration(seconds: 15))) {
          continue;
        }
        double? numOf(dynamic raw) => raw is num ? raw.toDouble() : double.tryParse('$raw');
        points[code] = PowerPoint(
          id: (row['id'] ?? row['Id'] ?? '').toString(),
          value: valueRaw is num ? valueRaw.toDouble() : double.tryParse('$valueRaw'),
          unit: (row['unit'] ?? row['Unit'])?.toString(),
          at: at,
          min: numOf(row['minThreshold'] ?? row['MinThreshold']),
          max: numOf(row['maxThreshold'] ?? row['MaxThreshold']),
        );
      }
      if (!_current(generation) || version != _powerVersion) return;
      _power = PowerSnapshot(points);
      _notifyDeferred();
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> powerHistory(
    String sensorId, {
    Duration range = const Duration(hours: 24),
  }) async {
    final to = DateTime.now().toUtc();
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/iot/sensor-data/$sensorId').replace(
      queryParameters: {
        'from': to.subtract(range).toIso8601String(),
        'to': to.toIso8601String(),
        'page': '1',
        'pageSize': '200',
      },
    );
    final res = await _client.get(uri, headers: _headers());
    final body = _decode(res.body);
    final data = body['data'] ?? body['Data'];
    final items = data is Map ? (data['items'] ?? data['Items']) : data;
    if (items is! List) return const [];
    return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, String> _headers() => {
        'Authorization': 'Bearer ${LiveSession.tokenOf(_session)}',
        'Content-Type': 'application/json',
      };

  Future<bool> _renew(int generation) async {
    if (!_current(generation)) return false;
    final next = await CloudAuthService().refreshSession(LiveSession.current ?? _session);
    if (next == null || !_current(generation) || next.user.id != _session.user.id) return false;
    _session = _session.copyWith(token: next.token, refreshToken: next.refreshToken, user: next.user);
    return true;
  }

  Future<bool> _mutate(
    Future<http.Response> Function() call,
    String areaId, {
    bool expectNoContent = false,
  }) async {
    if (_disposed || !_assigned(areaId) || _mutating ||
        (_liveAreaId != null && _liveAreaId != areaId)) return false;
    final generation = _generation;
    ++_readVersion;
    _loading = false;
    _refreshInFlight = false;
    _mutating = true;
    _notifyDeferred();
    bool reload = false;
    try {
      var res = await call();
      if (!_current(generation)) return false;
      if (res.statusCode == 401 && await _renew(generation)) {
        if (!_current(generation)) return false;
        res = await call();
      }
      if (!_current(generation)) return false;
      if (res.statusCode == 401) {
        stopLiveRefresh(notify: false);
        _diagram = null;
        _power = const PowerSnapshot();
        _lastRefreshedAt = null;
        _error = 'Phiên đăng nhập hết hạn';
        _notifyDeferred();
        return false;
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        _error = _messageOf(res) ?? 'Thao tác RAS thất bại (${res.statusCode})';
        return false;
      }
      if (expectNoContent) {
        reload = true;
      } else {
        final next = RasFlowDiagram.fromJson(_requireData(res));
        if (next.areaId != areaId) throw StateError('Phản hồi RAS sai khu nuôi.');
        _diagram = next;
        _lastRefreshedAt = DateTime.now();
      }
      _error = null;
      return true;
    } catch (e) {
      if (_current(generation)) _error = '$e';
      return false;
    } finally {
      if (_current(generation)) {
        _mutating = false;
        if (reload) unawaited(loadDiagram(areaId));
        _notifyDeferred();
      }
    }
  }

  Map<String, dynamic> _requireData(http.Response res) {
    if (res.statusCode == 401) {
      throw StateError('Phiên đăng nhập hết hạn');
    }
    final body = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError(body['message']?.toString() ?? 'Lỗi API (${res.statusCode})');
    }
    if (body['success'] == false) {
      throw StateError(body['message']?.toString() ?? 'Thao tác thất bại');
    }
    final data = body['data'] ?? body['Data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return body;
  }

  String? _messageOf(http.Response res) {
    try {
      return _decode(res.body)['message']?.toString();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decode(String raw) {
    if (raw.isEmpty) return {};
    final v = jsonDecode(raw);
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  @override
  void dispose() {
    _disposed = true;
    stopLiveRefresh(notify: false);
    if (_ownsClient) _client.close();
    super.dispose();
  }
}

class PowerPoint {
  const PowerPoint({required this.id, this.value, this.unit, this.at, this.min, this.max});

  final String id;
  final double? value;
  final String? unit;
  final DateTime? at;
  final double? min;
  final double? max;
}

class PowerSnapshot {
  const PowerSnapshot([this.points = const {}]);

  final Map<String, PowerPoint> points;

  PowerPoint? operator [](String code) => points[code];

  bool get hasData => points.values.any((p) => p.value != null);
}
