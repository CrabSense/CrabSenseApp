import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/ras_flow.dart';

class RasFlowService extends ChangeNotifier {
  RasFlowService({required AuthSession session}) : _session = session;

  static const livePollInterval = Duration(seconds: 2);

  AuthSession _session;

  void updateSession(AuthSession session) {
    _session = session;
    stopLiveRefresh(notify: false);
    _diagram = null;
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
  String? _liveAreaId;

  bool get loading => _loading;
  bool get isLiveActive => _liveTimer != null;
  bool get isRefreshing => _refreshInFlight;
  String? get error => _error;
  RasFlowDiagram? get diagram => _diagram;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;

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
    _liveTimer = Timer.periodic(interval, (_) {
      if (_liveAreaId == areaId) {
        unawaited(loadDiagram(areaId, silent: true));
      }
    });
    _notifyDeferred();
  }

  void stopLiveRefresh({bool notify = true}) {
    _liveTimer?.cancel();
    _liveTimer = null;
    _liveAreaId = null;
    if (notify) _notifyDeferred();
  }

  Future<void> loadDiagram(String areaId, {bool silent = false}) async {
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
          'nodeType': 'equipment',
          if (relayChannel != null && relayChannel.isNotEmpty)
            'relayChannel': relayChannel,
          if (paramDefaults != null && paramDefaults.isNotEmpty)
            'paramDefaults': _parseParamDefaults(paramDefaults),
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

  Map<String, String> _headers() => {
        'Authorization': 'Bearer ${_session.token}',
        'Content-Type': 'application/json',
      };

  Future<bool> _mutate(
    Future<http.Response> Function() call,
    String areaId, {
    bool expectNoContent = false,
  }) async {
    try {
      final res = await call();
      if (res.statusCode == 401) {
        _error = 'Phiên đăng nhập hết hạn';
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
