import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/iot_device.dart';
import '../models/auth_models.dart';
import 'cloud_api_client.dart';

class IotDeviceService extends IoTDeviceService {
  IotDeviceService({required super.session});

  String _search = '';
  String _category = 'Tất cả';
  String? _selectedDeviceId;
  bool _emergencyStop = false;

  List<IotDevice> _uiDevices = [];
  List<IotAutomationRule> _rules = [];

  @override
  void updateSession(AuthSession session) {
    super.updateSession(session);
    _uiDevices = [];
    _selectedDeviceId = null;
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  String get category => _category;

  void setCategory(String cat) {
    _category = cat;
    notifyListeners();
  }

  IotDevice? get selectedDevice {
    if (_selectedDeviceId == null) return null;
    final list = _uiList();
    final idx = list.indexWhere((d) => d.id == _selectedDeviceId);
    return idx >= 0 ? list[idx] : null;
  }

  void selectDevice(String id) {
    _selectedDeviceId = _selectedDeviceId == id ? null : id;
    notifyListeners();
  }

  List<IotDevice> get filteredIotDevices {
    var list = _uiList();
    if (_category != 'Tất cả') {
      list = list.where((d) => d.typeLabel.contains(_category)).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((d) =>
          d.name.toLowerCase().contains(q) ||
          d.typeLabel.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<IotDevice> _uiList() => _uiDevices;

  IotDeviceOverview get overview {
    final list = _uiList();
    final online =
        list.where((d) => d.connection == IotConnectionStatus.online).length;
    final running =
        list.where((d) => d.runStatus == IotRunStatus.running).length;
    return IotDeviceOverview(
      total: list.length,
      online: online,
      offline: list.length - online,
      running: running,
      stopped: list.length - running,
      error: list.where((d) => d.runStatus == IotRunStatus.error).length,
      energyTodayKwh: 0,
    );
  }

  IotDeviceKpi get kpi {
    final o = overview;
    return IotDeviceKpi(
      online: o.online,
      offline: o.offline,
      running: o.running,
      error: o.error,
    );
  }
  List<IotActivityLog> get activityLogs => const [];
  List<IotScheduleEntry> get schedule => const [];
  List<IotCalendarBlock> get calendarBlocks => const [];
  IotDeviceStats get stats => const IotDeviceStats(
        totalRuntimeHours: 0,
        totalEnergyKwh: 0,
        powerOnCount: 0,
        errorCount: 0,
        efficiencyPercent: 0,
      );
  String get aiInsight => '';
  String get aiRecommendation => '';
  int get coreCpuPercent => 0;
  int get zigbeeSignalPercent => 0;
  List<IotDeviceAlert> get alerts => const [];

  List<IotAutomationRule> get rules => _rules;

  bool get emergencyStop => _emergencyStop;

  void emergencyStopAll() {
    _emergencyStop = true;
    notifyListeners();
  }

  void resetEmergency() {
    _emergencyStop = false;
    notifyListeners();
  }

  void togglePower(String id) {
    final list = _uiList();
    final idx = list.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      _uiDevices[idx] = list[idx].copyWithTogglePower();
      notifyListeners();
    }
  }

  void toggleMode(String id) {
    final list = _uiList();
    final idx = list.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      final d = list[idx];
      final next = d.mode == IotControlMode.auto
          ? IotControlMode.manual
          : IotControlMode.auto;
      _uiDevices[idx] = d.copyWithMode(next);
      notifyListeners();
    }
  }

  void setMode(String id, IotControlMode mode) {
    final list = _uiList();
    final idx = list.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      _uiDevices[idx] = list[idx].copyWithMode(mode);
      notifyListeners();
    }
  }

  void fixNow(String id) => notifyListeners();
  void testDevice(String id) => notifyListeners();
  void triggerWash(String id) => notifyListeners();
  void feedNow(String id) => notifyListeners();

  Future<void> loadUiDevices() async {
    await loadDevices();
    _uiDevices = devices.map(_toUiDevice).toList();
    notifyListeners();
  }

  static IotDevice _toUiDevice(IoTDevice d) {
    final online = d.status.toLowerCase() == 'online';
    final typeRaw = (d.firmwareVersion ?? '').toLowerCase();
    final type = typeRaw.contains('camera')
        ? IotDeviceType.fan
        : IotDeviceType.pump;
    return IotDevice(
      id: d.id,
      name: d.deviceName ?? d.deviceCode,
      type: type,
      typeLabel: d.deviceCode,
      location: d.areaName ?? d.boxCode ?? 'Khu nuôi',
      connection:
          online ? IotConnectionStatus.online : IotConnectionStatus.offline,
      runStatus: online ? IotRunStatus.running : IotRunStatus.stopped,
      mode: IotControlMode.auto,
      isOn: online,
      powerWatts: 0,
      runCount: 0,
      scheduleInfo: d.firmwareVersion ?? '—',
      meta: IotDeviceDetailMeta(
        deviceCode: d.deviceCode,
        firmware: d.firmwareVersion ?? '—',
        ip: d.ipLan ?? '—',
        mqttStatus: d.status,
        lastSeen: d.lastSeenAt?.toLocal().toString() ?? '—',
      ),
    );
  }

  void setValveOpen(String id, int percent) => notifyListeners();

  void toggleRule(String ruleId) {
    final idx = _rules.indexWhere((r) => r.id == ruleId);
    if (idx >= 0) {
      _rules[idx] = _rules[idx].copyWith(enabled: !_rules[idx].enabled);
      notifyListeners();
    }
  }
}

class IoTDeviceService extends ChangeNotifier {
  IoTDeviceService({required AuthSession session}) : _session = session;

  AuthSession _session;

  String get selectedFarmName => _session.selectedFarm.name;
  String get selectedFarmId => _session.selectedFarm.id;

  void updateSession(AuthSession session) {
    _session = session;
    _devices = [];
    _error = null;
    notifyListeners();
  }

  var _loading = false;
  String? _error;
  List<IoTDevice> _devices = [];
  String? _selectedBoxId;

  bool get loading => _loading;
  String? get error => _error;
  List<IoTDevice> get devices => List.unmodifiable(_devices);
  String? get selectedBoxId => _selectedBoxId;

  List<IoTDevice> get filteredDevices {
    if (_selectedBoxId == null) return _devices;
    return _devices.where((d) => d.boxId == _selectedBoxId).toList();
  }

  void selectBox(String? boxId) {
    _selectedBoxId = boxId;
    notifyListeners();
  }

  Future<void> loadDevices({String? farmId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _session.token;
      final fid = farmId ?? _session.selectedFarm.id;
      final raw = await CloudApiClient().fetchCrabSenseDevices(
        token,
        farmingAreaId: fid,
      );
      _devices = raw.map(IoTDevice.fromJson).toList();
      _error = null;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      Future.microtask(() {
        if (hasListeners) notifyListeners();
      });
    }
  }

  /// Tải thiết bị thuộc các hộp trên dãy (Quản lý hộp) hoặc một hộp.
  Future<void> loadDevicesForBoxes(
    List<String> boxIds, {
    String? farmId,
  }) async {
    if (boxIds.isEmpty) {
      _devices = [];
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }
    if (boxIds.length == 1) {
      await loadDevicesByBox(boxIds.first);
      return;
    }

    await loadDevices(farmId: farmId);
    final allowed = boxIds.toSet();
    _devices = _devices
        .where((d) => d.boxId != null && allowed.contains(d.boxId))
        .toList();
    notifyListeners();
  }

  Future<void> loadDevicesByBox(String boxId) async {
    await loadDevices();
  }

  Future<String?> getNextDeviceCode({String? farmId}) async {
    return 'DEV-${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  Future<IoTDevice?> createDevice(
    UpsertDeviceRequest request, {
    String? farmId,
  }) async {
    try {
      final token = _session.token;
      final url = Uri.parse('${AppEnv.cloudApiUrl}/api/devices');
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'deviceCode': request.deviceCode ??
              'DEV-${DateTime.now().millisecondsSinceEpoch % 100000}',
          'deviceType': 'esp32',
          if (request.firmwareVersion != null)
            'firmwareVersion': request.firmwareVersion,
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = json['data'] ?? json['Data'] ?? json['device'] ?? json['Device'];
        if (raw is! Map) return null;
        final device = IoTDevice.fromJson(Map<String, dynamic>.from(raw));
        _devices.add(device);
        notifyListeners();
        return device;
      } else {
        _error = 'HTTP ${res.statusCode}: ${res.body}';
        notifyListeners();
      }
    } catch (e) {
      _error = '$e';
      notifyListeners();
    }
    return null;
  }

  Future<IoTDevice?> updateDevice(
    String deviceId,
    UpsertDeviceRequest request,
  ) async {
    try {
      final token = _session.token;
      final url = Uri.parse('${AppEnv.cloudApiUrl}/api/devices/$deviceId');
      final res = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'deviceType': 'esp32',
          if (request.firmwareVersion != null)
            'firmwareVersion': request.firmwareVersion,
          'status': request.status,
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = json['data'] ?? json['Data'] ?? json['device'] ?? json['Device'];
        if (raw is! Map) return null;
        final device = IoTDevice.fromJson(Map<String, dynamic>.from(raw));
        final index = _devices.indexWhere((d) => d.id == deviceId);
        if (index >= 0) {
          _devices[index] = device;
          notifyListeners();
        }
        return device;
      } else {
        _error = 'HTTP ${res.statusCode}: ${res.body}';
        notifyListeners();
      }
    } catch (e) {
      _error = '$e';
      notifyListeners();
    }
    return null;
  }

  Future<bool> deleteDevice(String deviceId) async {
    try {
      final token = _session.token;
      final url = Uri.parse('${AppEnv.cloudApiUrl}/api/devices/$deviceId');
      final res = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _devices.removeWhere((d) => d.id == deviceId);
        notifyListeners();
        return true;
      } else {
        _error = 'HTTP ${res.statusCode}: ${res.body}';
        notifyListeners();
      }
    } catch (e) {
      _error = '$e';
      notifyListeners();
    }
    return false;
  }
}

