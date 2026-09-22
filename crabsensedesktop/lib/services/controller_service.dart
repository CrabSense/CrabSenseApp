import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/esp_controller.dart';
import '../models/iot_device.dart';
import 'cloud_api_client.dart';

/// Danh sách ESP32 / Controller theo khu — Sensor + Output thuộc từng board.
class ControllerService extends ChangeNotifier {
  ControllerService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<IoTDevice> _items = [];
  bool _loading = false;
  String? _error;
  String? _selectedId;
  ControllerDetail? _detail;
  bool _detailLoading = false;

  List<IoTDevice> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedId => _selectedId;
  ControllerDetail? get detail => _detail;
  bool get detailLoading => _detailLoading;
  AuthSession get session => _session;

  int get onlineCount => _items.where((d) => d.isOnline).length;
  int get offlineCount => _items.length - onlineCount;

  void updateSession(AuthSession session) {
    _session = session;
    _items = [];
    _detail = null;
    _selectedId = null;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchCrabSenseDevices(
        _session.token,
        farmingAreaId: _session.selectedFarm.id,
      );
      _items = raw.map(IoTDevice.fromJson).toList()
        ..sort((a, b) => a.deviceCode.compareTo(b.deviceCode));
    } on CloudApiException catch (e) {
      _error = e.message;
      _items = [];
    } catch (e) {
      _error = '$e';
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> select(String id) async {
    if (_selectedId == id) {
      _selectedId = null;
      _detail = null;
      notifyListeners();
      return;
    }
    _selectedId = id;
    _detailLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchControllerDetail(_session.token, id);
      _detail = ControllerDetail.fromJson(raw);
    } catch (e) {
      _error = '$e';
      _detail = null;
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  Future<bool> add({
    required String deviceCode,
    String? name,
    String? deviceType,
    String? macAddress,
    String? ipAddress,
    String? firmwareVersion,
    String? farmingAreaId,
    bool registerRealtimeSensors = false,
  }) async {
    try {
      final created = await _api.createController(
        _session.token,
        deviceCode: deviceCode.trim(),
        name: name?.trim(),
        deviceType: deviceType,
        macAddress: macAddress?.trim(),
        ipAddress: ipAddress?.trim(),
        firmwareVersion: firmwareVersion?.trim(),
        farmingAreaId: farmingAreaId ?? _session.selectedFarm.id,
      );
      if (registerRealtimeSensors) {
        final deviceId = (created['id'] ?? created['Id'] ?? '').toString();
        final code = deviceCode.trim();
        if (deviceId.isNotEmpty) {
          await _registerRealtimeSensors(deviceId, code);
        }
      }
      await load();
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '$e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _registerRealtimeSensors(String deviceId, String deviceCode) async {
    const specs = [
      ('-temp', 'Temperature', 'C'),
      ('-ph', 'pH', 'pH'),
      ('-tds', 'TDS', 'ppm'),
    ];
    for (final spec in specs) {
      try {
        await _api.createSensor(
          _session.token,
          deviceId: deviceId,
          sensorCode: '$deviceCode${spec.$1}',
          sensorType: spec.$2,
          unit: spec.$3,
        );
      } on CloudApiException {
        // Already registered from a previous attempt — keep going.
      }
    }
  }
}
