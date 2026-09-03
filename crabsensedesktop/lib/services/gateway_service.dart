import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../models/auth_models.dart';
import 'gateway_info_stub.dart'
    if (dart.library.io) 'gateway_info_native.dart';

/// CrabSenseBE không có `/api/gateways`. Desktop chỉ ghi nhận hostname local.
class GatewayService extends ChangeNotifier {
  GatewayService({required AuthSession session}) : _session = session;

  AuthSession _session;
  String? _gatewayId;
  String? _error;
  bool _registered = false;

  String get gatewayId => _gatewayId ?? AppEnv.defaultGatewayId;
  String? get error => _error;
  bool get registered => _registered;

  void updateSession(AuthSession session) {
    _session = session;
  }

  Future<void> registerHeartbeat() async {
    try {
      final info = await getGatewayNativeInfo();
      _gatewayId = info['hostname'] ?? 'desktop';
      _registered = true;
      _error = null;
      debugPrint(
        'Desktop gateway: $_gatewayId (farm=${_session.selectedFarm.id})',
      );
    } catch (e) {
      _error = '$e';
    }
  }
}
