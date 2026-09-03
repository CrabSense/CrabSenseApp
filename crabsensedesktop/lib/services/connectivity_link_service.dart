import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/cloud_edge_connectivity.dart';
import 'cloud_api_client.dart';

/// Trạng thái kết nối Cloud (thật qua `.env` + JWT). Edge không dùng trên desktop.
class ConnectivityLinkService extends ChangeNotifier {
  ConnectivityLinkService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient(),
        _edge = _edgeNotUsed() {
    _cloud = _cloudFromSession(connected: true);
  }

  AuthSession _session;
  final CloudApiClient _api;

  late ConnectivityLinkStatus _cloud;
  final ConnectivityLinkStatus _edge;
  bool _busy = false;

  AuthSession get session => _session;

  /// Desktop app: chỉ Cloud API.
  bool get cloudOnly => true;

  ConnectivityLinkStatus get cloud => _cloud;
  ConnectivityLinkStatus get edge => _edge;
  bool get busy => _busy;
  bool get cloudConnected => _cloud.isConnected;
  bool get allConnected => cloudConnected;

  String get cloudApiUrl => AppEnv.cloudApiUrl;
  String get farmLabel => _session.selectedFarm.name;
  String get farmCode => _session.selectedFarm.code;
  String get userEmail => _session.user.email;

  void updateSession(AuthSession session) {
    _session = session;
    final connected = _cloud.isConnected;
    _cloud = _cloudFromSession(connected: connected);
    notifyListeners();
  }

  String _timeNow() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}:'
        '${n.second.toString().padLeft(2, '0')}';
  }

  ConnectivityLinkStatus _cloudFromSession({required bool connected}) {
    return ConnectivityLinkStatus(
      kind: ConnectivityLinkKind.cloud,
      state: connected
          ? ConnectivityLinkState.connected
          : ConnectivityLinkState.disconnected,
      endpoint: AppEnv.cloudApiUrl,
      message: connected
          ? 'JWT hợp lệ — $farmLabel · $userEmail'
          : 'Chưa xác minh Cloud',
      lastChecked: connected ? _timeNow() : null,
    );
  }

  static ConnectivityLinkStatus _edgeNotUsed() {
    return const ConnectivityLinkStatus(
      kind: ConnectivityLinkKind.edge,
      state: ConnectivityLinkState.unknown,
      endpoint: '—',
      message: 'Desktop không nối Edge (chỉ Cloud API)',
    );
  }

  /// Gọi sau khi vào shell — xác minh `/health` + `/api/auth/me`.
  Future<void> refreshCloud() => testCloud();

  Future<bool> testCloud() async {
    _busy = true;
    _cloud = _cloud.copyWith(
      state: ConnectivityLinkState.checking,
      message: 'Đang kiểm tra /health và /api/auth/me...',
    );
    notifyListeners();

    final sw = Stopwatch()..start();
    var healthOk = false;
    String? err;

    try {
      healthOk = await _api.healthCheck();
      if (!healthOk) {
        err = 'GET /health không phản hồi';
      } else {
        await _api.authMe(_session.token);
      }
    } on CloudApiException catch (e) {
      err = e.message;
      healthOk = false;
    } catch (e) {
      err = 'Lỗi mạng: $e';
      healthOk = false;
    }

    sw.stop();
    final ok = healthOk && err == null;

    _cloud = ConnectivityLinkStatus(
      kind: ConnectivityLinkKind.cloud,
      state: ok ? ConnectivityLinkState.connected : ConnectivityLinkState.disconnected,
      endpoint: AppEnv.cloudApiUrl,
      latencyMs: ok ? sw.elapsedMilliseconds : null,
      lastChecked: _timeNow(),
      message: ok
          ? 'Cloud OK — $farmLabel ($farmCode) · $userEmail'
          : (err ?? 'Không kết nối được Cloud'),
    );

    _busy = false;
    notifyListeners();
    return ok;
  }

  /// Giữ API cũ — desktop không test Edge.
  Future<bool> testEdge() async {
    notifyListeners();
    return false;
  }

  Future<void> testAll() async {
    await testCloud();
  }
}
