import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/esp_controller.dart';
import '../models/iot_device.dart';
import 'cloud_api_client.dart';
import 'controller_provisioning_service.dart';

enum ControllerMetaSaveResult { ok, conflict, failed }

/// Danh sách ESP32 / Controller theo khu — Sensor + Output thuộc từng board.
class ControllerService extends ChangeNotifier {
  ControllerService({
    required AuthSession session,
    CloudApiClient? api,
    ControllerProvisioningService? provisioning,
  })  : _session = session,
        _api = api ?? CloudApiClient(),
        _provisioning = provisioning ?? ControllerProvisioningService();

  AuthSession _session;
  final CloudApiClient _api;
  final ControllerProvisioningService _provisioning;

  List<IoTDevice> _items = [];
  bool _loading = false;
  String? _error;
  String? _detailError;
  String? _selectedId;
  ControllerDetail? _detail;
  bool _detailLoading = false;
  bool _detailRefreshing = false;
  DateTime? _detailRefreshedAt;
  bool _restarting = false;
  Timer? _liveTimer;

  List<IoTDevice> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  String? get detailError => _detailError;
  String? get selectedId => _selectedId;
  ControllerDetail? get detail => _detail;
  bool get detailLoading => _detailLoading;
  bool get detailRefreshing => _detailRefreshing;
  DateTime? get detailRefreshedAt => _detailRefreshedAt;
  bool get restarting => _restarting;
  AuthSession get session => _session;

  int get totalCount => _items.length;
  int get onlineCount => _items.where((d) => d.isOnline).length;
  int get offlineCount => _items
      .where((d) => d.isOffline && d.status.toLowerCase() != 'error')
      .length;
  int get errorCount =>
      _items.where((d) => d.status.toLowerCase() == 'error').length;
  int get attachedCount =>
      _items.fold<int>(0, (sum, d) => sum + d.sensorCount + d.actuatorCount);

  void updateSession(AuthSession session) {
    _session = session;
    _items = [];
    _detail = null;
    _selectedId = null;
    _error = null;
    _detailError = null;
    stopLiveRefresh();
    notifyListeners();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final raw = await _api.fetchCrabSenseDevices(
        _session.token,
        farmingAreaId: _session.selectedFarm.id,
      );
      _items = raw.map(IoTDevice.fromJson).toList()
        ..sort((a, b) => a.deviceCode.compareTo(b.deviceCode));
      _error = null;
      if (_selectedId != null && !_items.any((d) => d.id == _selectedId)) {
        _selectedId = null;
        _detail = null;
      }
      if (_selectedId == null && _items.isNotEmpty) {
        await select(_items.first.id, force: true);
      } else if (_selectedId != null) {
        await _loadDetail(_selectedId!, silent: true);
      }
    } on CloudApiException catch (e) {
      _error = e.message;
      if (!silent) _items = [];
    } catch (e) {
      _error = '$e';
      if (!silent) _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> select(String id, {bool force = false}) async {
    if (!force && _selectedId == id) return;
    _selectedId = id;
    _detailError = null;
    await _loadDetail(id);
    startLiveRefresh();
  }

  Future<void> _loadDetail(String id, {bool silent = false}) async {
    if (!silent) {
      _detailLoading = true;
      notifyListeners();
    } else {
      _detailRefreshing = true;
    }
    try {
      final raw = await _api.fetchControllerDetail(_session.token, id);
      _detail = ControllerDetail.fromJson(raw);
      _detailError = null;
      _detailRefreshedAt = DateTime.now();
      final idx = _items.indexWhere((d) => d.id == id);
      if (idx >= 0) {
        _items = [..._items]..[idx] = _detail!.controller;
      }
    } catch (e) {
      _detailError = '$e';
      if (!silent) _detail = null;
    } finally {
      _detailLoading = false;
      _detailRefreshing = false;
      notifyListeners();
    }
  }

  void startLiveRefresh() {
    _liveTimer?.cancel();
    final id = _selectedId;
    if (id == null) return;
    _liveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_selectedId == id) unawaited(_loadDetail(id, silent: true));
    });
  }

  void stopLiveRefresh() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  Future<bool> checkConnection(IoTDevice device) async {
    await _loadDetail(device.id, silent: true);
    final latest = _detail?.controller ?? device;
    final ip = (latest.ipLan ?? '').trim();
    if (ip.isEmpty) {
      return latest.isOnline;
    }
    try {
      await _provisioning.pingLan(ip).timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
      return latest.isOnline &&
          latest.lastSeenAt != null &&
          DateTime.now().difference(latest.lastSeenAt!.toLocal()) <=
              const Duration(seconds: 30);
    }
  }

  Future<bool> restart(IoTDevice device) async {
    final ip = (device.ipLan ?? '').trim();
    if (ip.isEmpty) return false;
    _restarting = true;
    notifyListeners();
    try {
      final ok = await _provisioning.restartLan(ip);
      return ok;
    } finally {
      _restarting = false;
      notifyListeners();
    }
  }

  Future<bool> sendWifi({
    required IoTDevice device,
    required String ssid,
    required String password,
    String? staticIp,
  }) async {
    final ip = (device.ipLan ?? '').trim();
    if (ip.isEmpty) {
      _detailError = 'Không có IP để gửi cấu hình WiFi.';
      notifyListeners();
      return false;
    }
    try {
      await _provisioning.provision(
        ssid: ssid,
        password: password,
        baseUrl: 'http://$ip',
      );
      await _loadDetail(device.id, silent: true);
      return true;
    } catch (e) {
      _detailError = '$e';
      notifyListeners();
      return false;
    }
  }

  Future<ControllerMetaSaveResult> updateMeta({
    required String id,
    String? name,
    String? deviceType,
    String? farmingAreaId,
    String? farmingRowId,
    String? installationLocation,
    String? note,
  }) async {
    try {
      await _api.updateController(
        _session.token,
        id,
        name: name,
        deviceType: deviceType,
        farmingAreaId: farmingAreaId,
        farmingRowId: farmingRowId,
        installationLocation: installationLocation,
        note: note,
      );
      await load(silent: true);
      return ControllerMetaSaveResult.ok;
    } on CloudApiException catch (e) {
      _detailError = e.message;
      notifyListeners();
      if (e.statusCode == 409) return ControllerMetaSaveResult.conflict;
      return ControllerMetaSaveResult.failed;
    } catch (e) {
      _detailError = '$e';
      notifyListeners();
      return ControllerMetaSaveResult.failed;
    }
  }

  /// Làm mới hardware/network từ heartbeat + ping LAN. Không đụng metadata form.
  Future<EspProvisionInfo?> refreshHardware(IoTDevice device) async {
    await _loadDetail(device.id, silent: true);
    final ip = (_detail?.controller.ipLan ?? device.ipLan ?? '').trim();
    if (ip.isEmpty) return null;
    try {
      return await _provisioning
          .pingLan(ip)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  Future<bool> deactivate(String id) async {
    try {
      await _api.updateController(_session.token, id, status: 'Maintenance');
      await load(silent: true);
      return true;
    } on CloudApiException catch (e) {
      _detailError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSensor({
    required String sensorId,
    String? sensorType,
    String? unit,
    bool? isActive,
    double? minThreshold,
    double? maxThreshold,
  }) async {
    try {
      await _api.updateSensor(
        _session.token,
        sensorId,
        sensorType: sensorType,
        unit: unit,
        isActive: isActive,
        minThreshold: minThreshold,
        maxThreshold: maxThreshold,
      );
      if (_selectedId != null) await _loadDetail(_selectedId!, silent: true);
      return true;
    } on CloudApiException catch (e) {
      _detailError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSensor(String sensorId) async {
    try {
      await _api.deleteSensor(_session.token, sensorId);
      if (_selectedId != null) await _loadDetail(_selectedId!, silent: true);
      return true;
    } on CloudApiException catch (e) {
      _detailError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSensor({
    required String deviceId,
    required String sensorCode,
    required String sensorType,
    String? unit,
  }) async {
    try {
      await _api.createSensor(
        _session.token,
        deviceId: deviceId,
        sensorCode: sensorCode,
        sensorType: sensorType,
        unit: unit,
      );
      await load(silent: true);
      return true;
    } on CloudApiException catch (e) {
      _detailError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> add({
    required String deviceCode,
    String? name,
    String? deviceType,
    String? macAddress,
    String? ipAddress,
    String? firmwareVersion,
    String? farmingAreaId,
    String? farmingRowId,
    String? installationLocation,
    String? note,
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
        farmingRowId: farmingRowId,
        installationLocation: installationLocation,
        note: note,
      );
      if (registerRealtimeSensors) {
        final deviceId = (created['id'] ?? created['Id'] ?? '').toString();
        final code = deviceCode.trim();
        if (deviceId.isNotEmpty) {
          await _registerRealtimeSensors(deviceId, code);
        }
      }
      await load();
      return created;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = '$e';
      notifyListeners();
      return null;
    }
  }

  Future<void> _registerRealtimeSensors(
      String deviceId, String deviceCode) async {
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

  @override
  void dispose() {
    stopLiveRefresh();
    super.dispose();
  }
}
