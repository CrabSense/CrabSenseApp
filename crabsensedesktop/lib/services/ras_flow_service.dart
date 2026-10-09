import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/ras_flow.dart';
import 'cloud_auth_service.dart';

class RasFlowService extends ChangeNotifier {
  RasFlowService({required AuthSession session}) : _session = session;

  static const livePollInterval = Duration(seconds: 2);

  AuthSession _session;

  void updateSession(AuthSession session) {
    _session = session;
    stopLiveRefresh(notify: false);
    _diagram = null;
    _power = const PowerSnapshot();
    _error = null;
    _notifyDeferred();
  }

  void _notifyDeferred() => Future.microtask(notifyListeners);

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

  /// Bật làm mới sơ đồ RAS mỗi [interval] (mặc định 2s, khớp telemetry Edge ~5s).
  void startLiveRefresh(
    String areaId, {
    Duration interval = livePollInterval,
  }) {
    if (areaId.trim().isEmpty) return;
    if (_liveAreaId == areaId && _liveTimer != null) return;

    stopLiveRefresh();
    _liveAreaId = areaId;
    unawaited(loadDiagram(areaId));
    unawaited(refreshPower());
    _meterTimer = Timer.periodic(const Duration(seconds: 2), (_) {
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
    if (areaId.trim().isEmpty) return;
    if (!silent) {
      _loading = true;
      _error = null;
      _notifyDeferred();
    } else {
      _refreshInFlight = true;
    }
    try {
      final res = await http.get(
        Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow'),
        headers: _headers(),
      );
      if (res.statusCode == 401) {
        if (allowRefresh && await _renew()) {
          await loadDiagram(areaId, silent: silent, allowRefresh: false);
          return;
        }
        _error = 'Phiên đăng nhập hết hạn';
        stopLiveRefresh(notify: false);
        return;
      }
      final data = _requireData(res);
      _diagram = RasFlowDiagram.fromJson(data);
      _error = null;
      _lastRefreshedAt = DateTime.now();
    } catch (e) {
      _error = e.toString();
      if (!silent) _diagram = null;
    } finally {
      _loading = false;
      _refreshInFlight = false;
      _notifyDeferred();
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
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/devices').replace(
      queryParameters: {'farmingAreaId': areaId},
    );
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 401 && await _renew()) {
      final again = await http.get(uri, headers: _headers());
      return _controllersFrom(again);
    }
    return _controllersFrom(res);
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
    return _mutate(
      () => http.post(
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
    return _mutate(
      () => http.delete(
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
    return _mutate(
      () => http.post(
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
    return _mutate(
      () => http.post(
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
    return _mutate(
      () => http.put(
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
    return _mutate(
      () => http.delete(
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
      await http.post(
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
    return _mutate(
      () => http.post(
        Uri.parse(
          '${AppEnv.cloudApiUrl}/api/areas/$areaId/ras-flow/nodes/$nodeId/command',
        ),
        headers: _headers(),
        body: jsonEncode({'command': command}),
      ),
      areaId,
    );
  }

  Future<void> refreshPower() async {
    try {
      final res = await http.get(
        Uri.parse('${AppEnv.cloudApiUrl}/api/iot/live'),
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
        double? numOf(dynamic raw) => raw is num ? raw.toDouble() : double.tryParse('$raw');
        points[code] = PowerPoint(
          id: (row['id'] ?? row['Id'] ?? '').toString(),
          value: valueRaw is num ? valueRaw.toDouble() : double.tryParse('$valueRaw'),
          unit: (row['unit'] ?? row['Unit'])?.toString(),
          at: atRaw == null ? null : DateTime.tryParse(atRaw.toString()),
          min: numOf(row['minThreshold'] ?? row['MinThreshold']),
          max: numOf(row['maxThreshold'] ?? row['MaxThreshold']),
        );
      }
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
    final res = await http.get(uri, headers: _headers());
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

  Future<bool> _renew() async {
    final next = await CloudAuthService().refreshSession(LiveSession.current ?? _session);
    if (next == null) return false;
    _session = next;
    return true;
  }

  Future<bool> _mutate(
    Future<http.Response> Function() call,
    String areaId, {
    bool expectNoContent = false,
  }) async {
    try {
      var res = await call();
      if (res.statusCode == 401 && await _renew()) {
        res = await call();
      }
      if (res.statusCode == 401) {
        _error = 'Phiên đăng nhập hết hạn';
        stopLiveRefresh(notify: false);
        _notifyDeferred();
        return false;
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        _error = _messageOf(res) ?? 'Thao tác RAS thất bại (${res.statusCode})';
        _notifyDeferred();
        return false;
      }
      if (!expectNoContent) {
        try {
          final data = _requireData(res);
          _diagram = RasFlowDiagram.fromJson(data);
          _lastRefreshedAt = DateTime.now();
        } catch (_) {
          await loadDiagram(areaId, silent: true);
        }
      } else {
        await loadDiagram(areaId, silent: true);
      }
      _error = null;
      _notifyDeferred();
      return true;
    } catch (e) {
      _error = '$e';
      _notifyDeferred();
      return false;
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
    stopLiveRefresh();
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
