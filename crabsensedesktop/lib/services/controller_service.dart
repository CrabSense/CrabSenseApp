import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/esp_controller.dart';
import '../models/iot_device.dart';
import 'cloud_api_client.dart';
import 'cloud_auth_service.dart';
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

  /// Đổi access token, không xóa danh sách controller đang hiện.
  Future<String?> renewToken() async {
    final next = await CloudAuthService().refreshSession(_session);
    if (next == null) return null;
    _session = next;
    return next.token;
  }

  Future<void> load({bool silent = false, bool allowRefresh = true}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final raw = await _api.fetchCrabSenseDevices(
        LiveSession.tokenOf(_session),
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
      if (e.statusCode == 401 && allowRefresh) {
        final renewed = await renewToken();
        if (renewed != null) {
          await load(silent: silent, allowRefresh: false);
          return;
        }
      }
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

  bool _detailBusy = false;

  Future<void> _loadDetail(String id, {bool silent = false}) async {
    if (silent && _detailBusy) return;
    _detailBusy = true;
    if (!silent) {
      _detailLoading = true;
      notifyListeners();
    } else {
      _detailRefreshing = true;
    }
    try {
      final raw = await _api.fetchControllerDetail(_session.token, id);
      final loaded = ControllerDetail.fromJson(raw);
      final previous = _detail?.controller.id == id ? _detail : null;
      _detail = previous == null
          ? loaded
          : ControllerDetail(
              controller: loaded.controller,
              sensors: _reuseSensorPins(loaded.sensors, previous.sensors),
              actuators: loaded.actuators,
              boardOutputs: previous.boardOutputs,
            );
      _detailError = null;
      _detailRefreshedAt = DateTime.now();
      await _mergePinsFromEsp(_detail!);
      final idx = _items.indexWhere((d) => d.id == id);
      if (idx >= 0) {
        _items = [..._items]..[idx] = _detail!.controller;
      }
    } catch (e) {
      _detailError = '$e';
      if (!silent) _detail = null;
    } finally {
      _detailBusy = false;
      _detailLoading = false;
      _detailRefreshing = false;
      notifyListeners();
    }
  }

  List<ControllerChild> _reuseSensorPins(
    List<ControllerChild> next,
    List<ControllerChild> previous,
  ) {
    return next.map((s) {
      for (final old in previous) {
        if (old.code == s.code && old.gpio != null) {
          return s.copyWith(
            gpio: old.gpio,
            interface: old.interface,
            channel: old.channel,
          );
        }
      }
      return s;
    }).toList();
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
    _restarting = true;
    notifyListeners();
    try {
      final ip = await _resolveReachableIp(device, [
        if (device.ipLan != null && device.ipLan!.trim().isNotEmpty)
          device.ipLan!.trim(),
      ]);
      if (ip == null) return false;
      try {
        final info = await _provisioning.pingLan(ip);
        await _ensureBackendUrl(info);
      } catch (_) {}
      return await _provisioning.restartLan(ip);
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
    String? liveIp,
  }) async {
    final candidates = <String>{
      if (liveIp != null && liveIp.trim().isNotEmpty) liveIp.trim(),
      if (device.ipLan != null && device.ipLan!.trim().isNotEmpty)
        device.ipLan!.trim(),
      if (staticIp != null && staticIp.trim().isNotEmpty) staticIp.trim(),
    };
    if (candidates.isEmpty) {
      _detailError = 'Không có IP để gửi cấu hình WiFi.';
      notifyListeners();
      return false;
    }

    final resolved = await _resolveReachableIp(device, candidates);
    if (resolved == null) {
      _detailError =
          'Không thấy Controller trên LAN. Nếu vừa đổi Wi-Fi, nối hotspot CrabSense-XXXX rồi gửi lại.';
      notifyListeners();
      return false;
    }

    try {
      await _provisioning.provision(
        ssid: ssid,
        password: password,
        backendUrl: await ControllerProvisioningService.backendUrlForEsp(
          AppEnv.cloudApiUrl,
        ),
        baseUrl: 'http://$resolved',
      );
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(const Duration(seconds: 3));
        try {
          final info = await _provisioning.pingLan(resolved);
          if (info.lastError.isNotEmpty) {
            _detailError = info.lastError;
            notifyListeners();
            return false;
          }
          if (info.wifiSsid.trim().toLowerCase() == ssid.trim().toLowerCase()) {
            await _loadDetail(device.id, silent: true);
            return true;
          }
        } catch (_) {}
      }
      await _loadDetail(device.id, silent: true);
      return true;
    } catch (e) {
      _detailError = '$e';
      notifyListeners();
      return false;
    }
  }

  Future<String?> _resolveReachableIp(
    IoTDevice device,
    Iterable<String> candidates,
  ) async {
    for (final ip in candidates) {
      try {
        final info = await _provisioning.pingLan(ip);
        if (_sameBoard(info, device)) return ip;
      } catch (_) {}
    }
    try {
      final nearby = await _provisioning.discoverAllNearby();
      for (final info in nearby) {
        if (_sameBoard(info, device)) {
          final ip = info.staIp.trim().isNotEmpty ? info.staIp.trim() : info.ip;
          if (ip.isNotEmpty) return ip;
        }
      }
    } catch (_) {}
    return null;
  }

  bool _sameBoard(EspProvisionInfo info, IoTDevice device) {
    final codes = {
      device.deviceCode.toLowerCase(),
      if (device.macAddress != null) device.macAddress!.toLowerCase(),
    }..removeWhere((e) => e.isEmpty);
    if (codes.isEmpty) return true;
    final got = {
      info.deviceCode.toLowerCase(),
      info.apName.toLowerCase(),
      info.mac.toLowerCase(),
      info.deviceId.toLowerCase(),
    };
    return codes.any(got.contains);
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
    EspProvisionInfo? info;
    final ip = (_detail?.controller.ipLan ?? device.ipLan ?? '').trim();
    if (ip.isNotEmpty) {
      try {
        info = await _provisioning
            .pingLan(ip)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    if (info == null) {
      try {
        final nearby = await _provisioning.discoverAllNearby();
        for (final found in nearby) {
          if (_sameBoard(found, device)) {
            info = found;
            break;
          }
        }
      } catch (_) {}
    }
    if (info != null) {
      await _ensureBackendUrl(info);
    }
    return info;
  }

  Future<void> _ensureBackendUrl(EspProvisionInfo info) async {
    final want = await ControllerProvisioningService.backendUrlForEsp(
      AppEnv.cloudApiUrl,
    );
    final now = info.cloudBackendUrl.trim();
    final bad = now.isEmpty ||
        now.contains('localhost') ||
        now.contains('127.0.0.1') ||
        now != want;
    if (!bad) return;
    try {
      await _provisioning.pushBackendUrl(
        baseUrl: 'http://${info.ip}',
        backendUrl: want,
      );
    } catch (_) {}
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

  Future<bool> deleteController(String deviceId) async {
    try {
      await _api.deleteController(_session.token, deviceId);
      if (_selectedId == deviceId) {
        _selectedId = null;
        _detail = null;
      }
      await load();
      return true;
    } on CloudApiException catch (e) {
      _error = e.message;
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
    List<EspSensorPin> firmwareSensors = const [],
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
      await _afterCreate(
        created,
        deviceCode.trim(),
        registerRealtimeSensors,
        firmwareSensors,
      );
      await load();
      return created;
    } on CloudApiException catch (e) {
      if (e.statusCode == 409 ||
          e.message.toLowerCase().contains('already') ||
          e.message.toLowerCase().contains('exists')) {
        final claimed = await _claimExisting(
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
        if (claimed != null) {
          await _afterCreate(
            claimed,
            deviceCode.trim(),
            registerRealtimeSensors,
            firmwareSensors,
          );
          await load();
          return claimed;
        }
      }
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = '$e';
      notifyListeners();
      return null;
    }
  }

  Future<void> _afterCreate(
    Map<String, dynamic> created,
    String deviceCode,
    bool registerRealtimeSensors,
    List<EspSensorPin> firmwareSensors,
  ) async {
    if (!registerRealtimeSensors) return;
    final deviceId = (created['id'] ?? created['Id'] ?? '').toString();
    if (deviceId.isEmpty) return;
    try {
      await _registerRealtimeSensors(deviceId, deviceCode, firmwareSensors);
    } on CloudApiException {
      // Sensors may already be linked to this controller.
    }
  }

  Future<Map<String, dynamic>?> _claimExisting({
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
  }) async {
    final all = await _api.fetchCrabSenseDevices(_session.token);
    Map<String, dynamic>? found;
    for (final raw in all) {
      final code = (raw['deviceCode'] ?? raw['DeviceCode'] ?? '')
          .toString()
          .toLowerCase();
      if (code == deviceCode.toLowerCase()) {
        found = raw;
        break;
      }
    }
    if (found == null) return null;
    final id = (found['id'] ?? found['Id'] ?? '').toString();
    if (id.isEmpty) return null;
    return _api.updateController(
      _session.token,
      id,
      name: name,
      deviceType: deviceType,
      ipAddress: ipAddress,
      farmingAreaId: farmingAreaId,
      farmingRowId: farmingRowId,
      firmwareVersion: firmwareVersion,
      macAddress: macAddress,
      installationLocation: installationLocation,
      note: note,
    );
  }

  Future<void> _registerRealtimeSensors(
    String deviceId,
    String deviceCode,
    List<EspSensorPin> firmwareSensors,
  ) async {
    final specs = <(String, String, String)>[
      if (firmwareSensors.isNotEmpty)
        for (final s in firmwareSensors)
          (
            s.suffix.isNotEmpty
                ? s.suffix
                : (s.sensorCode.startsWith(deviceCode)
                    ? s.sensorCode.substring(deviceCode.length)
                    : '-${s.sensorType.toLowerCase()}'),
            s.sensorType,
            s.unit,
          )
      else
        ...const [
          ('-temp', 'Temperature', 'C'),
          ('-ph', 'pH', 'pH'),
          ('-tds', 'Salinity', 'ppt'),
        ],
      ...const [
        ('meter_v', 'Voltage', 'V'),
        ('meter_a', 'Current', 'A'),
        ('meter_w', 'Power', 'W'),
        ('meter_va', 'ApparentPower', 'VA'),
        ('meter_kwh', 'Energy', 'kWh'),
        ('meter_hz', 'Frequency', 'Hz'),
        ('meter_pf', 'PowerFactor', '%'),
      ],
    ];
    for (final spec in specs) {
      try {
        await _api.createSensor(
          _session.token,
          deviceId: deviceId,
          sensorCode: spec.$1.startsWith('-')
              ? '$deviceCode${spec.$1}'
              : spec.$1,
          sensorType: spec.$2,
          unit: spec.$3,
        );
      } on CloudApiException {
        // Already registered from a previous attempt — keep going.
      }
    }
  }

  Future<List<Map<String, dynamic>>> sensorHistory(String sensorId) {
    final to = DateTime.now().toUtc();
    return _api.fetchSensorHistory(
      _session.token,
      sensorId: sensorId,
      from: to.subtract(const Duration(hours: 24)),
      to: to,
      pageSize: 200,
    );
  }

  Future<void> _mergePinsFromEsp(ControllerDetail detail) async {
    final ip = detail.controller.ipLan?.trim() ?? '';
    if (ip.isEmpty) return;
    try {
      final info = await _provisioning.pingLan(ip).timeout(const Duration(seconds: 8));
      if (info.sensors.isEmpty && info.outputs.isEmpty) return;
      final mapped = detail.sensors.map((s) {
        EspSensorPin? pin;
        for (final p in info.sensors) {
          if (p.sensorCode.isNotEmpty &&
              p.sensorCode.toLowerCase() == s.code.toLowerCase()) {
            pin = p;
            break;
          }
          if (p.suffix.isNotEmpty && s.code.toLowerCase().endsWith(p.suffix.toLowerCase())) {
            pin = p;
            break;
          }
        }
        if (pin == null) return s;
        return s.copyWith(
          gpio: pin.gpio,
          interface: pin.interface,
          channel: pin.channel.isNotEmpty ? pin.channel : 'GPIO${pin.gpio}',
        );
      }).toList();
      _detail = ControllerDetail(
        controller: detail.controller,
        sensors: mapped,
        actuators: detail.actuators,
        boardOutputs: info.outputs,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    stopLiveRefresh();
    super.dispose();
  }
}
