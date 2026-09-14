import 'package:flutter/foundation.dart';

import '../models/device_setup.dart';

class DeviceSetupService extends ChangeNotifier {
  DeviceSetupService() {
    _device = const Esp32Device(
      id: '',
      name: '',
      type: Esp32DeviceType.sensor,
      area: '',
      assignment: '',
      firmwareVersion: '',
      status: DeviceOnlineStatus.offline,
      lastSeen: '—',
      macAddress: '',
      localIp: '',
      uptime: '—',
      hardwareVersion: '',
    );
    _wifi = const WifiConfig(ssid: '', password: '');
    _wifiNetworks = [];
    _mqtt = const MqttConfig(
      brokerUrl: '',
      port: 1883,
      username: '',
      password: '',
      clientId: '',
      topicPublish: '',
      topicSubscribe: '',
      qos: 0,
      keepAlive: 60,
      cleanSession: true,
      tlsEnabled: false,
    );
    _sensorMappings = [];
    _relayMappings = [];
    _fallbackRules = [];
    _testResult = null;
    _ota = const OtaFirmwareInfo(
      currentVersion: '',
      latestVersion: '',
      updateAvailable: false,
      history: [],
    );
  }

  DeviceSetupSection _section = DeviceSetupSection.wifi;
  late Esp32Device _device;
  late WifiConfig _wifi;
  late List<WifiNetwork> _wifiNetworks;
  late MqttConfig _mqtt;
  late List<SensorMapping> _sensorMappings;
  late List<RelayMapping> _relayMappings;
  late List<FallbackRule> _fallbackRules;
  ConnectionTestResult? _testResult;
  late OtaFirmwareInfo _ota;

  bool _wifiPasswordVisible = false;
  bool _mqttPasswordVisible = false;
  bool _busy = false;
  String? _statusMessage;
  String _wifiPasswordPlain = '';

  DeviceSetupSection get section => _section;
  Esp32Device get device => _device;
  WifiConfig get wifi => _wifi;
  List<WifiNetwork> get wifiNetworks => _wifiNetworks;
  MqttConfig get mqtt => _mqtt;
  List<SensorMapping> get sensorMappings => _sensorMappings;
  List<RelayMapping> get relayMappings => _relayMappings;
  List<FallbackRule> get fallbackRules => _fallbackRules;
  ConnectionTestResult? get testResult => _testResult;
  OtaFirmwareInfo get ota => _ota;
  bool get wifiPasswordVisible => _wifiPasswordVisible;
  bool get mqttPasswordVisible => _mqttPasswordVisible;
  bool get busy => _busy;
  String? get statusMessage => _statusMessage;
  List<String> get mqttTopicTemplates => _device.id.isEmpty
      ? const []
      : [
          'crabfarm/device/${_device.id}/sensor',
          'crabfarm/device/${_device.id}/command',
        ];
  String get nodeStatusLabel =>
      _device.status == DeviceOnlineStatus.online ? 'Đang kết nối' : 'Chưa kết nối';

  String get wifiPasswordDisplay =>
      _wifiPasswordVisible ? _wifiPasswordPlain : _wifi.password;

  String get mqttPasswordDisplay =>
      _mqttPasswordVisible ? _mqtt.password : _mqtt.password;

  void selectSection(DeviceSetupSection s) {
    if (_section == s) return;
    _section = s;
    notifyListeners();
  }

  void updateDevice({
    String? name,
    Esp32DeviceType? type,
    String? area,
    String? assignment,
  }) {
    _device = Esp32Device(
      id: _device.id,
      name: name ?? _device.name,
      type: type ?? _device.type,
      area: area ?? _device.area,
      assignment: assignment ?? _device.assignment,
      firmwareVersion: _device.firmwareVersion,
      status: _device.status,
      lastSeen: _device.lastSeen,
      macAddress: _device.macAddress,
      localIp: _device.localIp,
      uptime: _device.uptime,
      hardwareVersion: _device.hardwareVersion,
    );
    notifyListeners();
  }

  void setWifiSsid(String ssid) {
    _wifi = _wifi.copyWith(ssid: ssid);
    notifyListeners();
  }

  void setWifiPassword(String value) {
    _wifiPasswordPlain = value;
    _wifi = _wifi.copyWith(password: value.isEmpty ? '' : '••••••••••••');
    notifyListeners();
  }

  void toggleWifiPasswordVisible() {
    _wifiPasswordVisible = !_wifiPasswordVisible;
    notifyListeners();
  }

  void setWifiOption({
    bool? smartConfig,
    bool? ble,
    bool? apMode,
  }) {
    _wifi = _wifi.copyWith(
      smartConfigEnabled: smartConfig,
      bleProvisioningEnabled: ble,
      apModeEnabled: apMode,
    );
    notifyListeners();
  }

  Future<void> rescanWifi() async {
    _busy = true;
    _statusMessage = 'Đang quét WiFi...';
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _wifiNetworks = [];
    _busy = false;
    _statusMessage = 'Chưa có mạng WiFi. Quét từ thiết bị khi đã kết nối.';
    notifyListeners();
  }

  void selectWifiNetwork(String ssid) {
    _wifiNetworks = [
      for (final n in _wifiNetworks)
        WifiNetwork(
          ssid: n.ssid,
          rssi: n.rssi,
          secured: n.secured,
          selected: n.ssid == ssid,
        ),
    ];
    _wifi = _wifi.copyWith(ssid: ssid);
    notifyListeners();
  }

  void updateMqtt(MqttConfig config) {
    _mqtt = config;
    notifyListeners();
  }

  void setMqttField({
    String? brokerUrl,
    int? port,
    String? username,
    String? password,
    String? clientId,
    String? topicPublish,
    String? topicSubscribe,
    int? qos,
    int? keepAlive,
    bool? cleanSession,
    bool? tlsEnabled,
  }) {
    if (password != null) {
      _mqtt = _mqtt.copyWith(password: password.isEmpty ? '' : '••••••••');
    } else {
      _mqtt = _mqtt.copyWith(
        brokerUrl: brokerUrl,
        port: port,
        username: username,
        clientId: clientId,
        topicPublish: topicPublish,
        topicSubscribe: topicSubscribe,
        qos: qos,
        keepAlive: keepAlive,
        cleanSession: cleanSession,
        tlsEnabled: tlsEnabled,
      );
    }
    notifyListeners();
  }

  void toggleMqttPasswordVisible() {
    _mqttPasswordVisible = !_mqttPasswordVisible;
    notifyListeners();
  }

  void applySuggestedTopics() {
    final t = mqttTopicTemplates;
    _mqtt = _mqtt.copyWith(
      topicPublish: t[0],
      topicSubscribe: t[2],
    );
    notifyListeners();
  }

  void updateSensorMapping(String id, SensorMapping mapping) {
    _sensorMappings = [
      for (final m in _sensorMappings) m.id == id ? mapping : m,
    ];
    notifyListeners();
  }

  void updateRelayMapping(String id, RelayMapping mapping) {
    _relayMappings = [
      for (final r in _relayMappings) r.id == id ? mapping : r,
    ];
    notifyListeners();
  }

  Future<bool> runTest(DeviceSetupTestKind kind) async {
    _busy = true;
    _statusMessage = switch (kind) {
      DeviceSetupTestKind.wifi => 'Đang kiểm tra WiFi...',
      DeviceSetupTestKind.mqtt => 'Đang kiểm tra MQTT...',
      DeviceSetupTestKind.sensorPublish => 'Đang gửi thử dữ liệu sensor...',
      DeviceSetupTestKind.relayCommand => 'Đang gửi lệnh relay ON/OFF...',
      DeviceSetupTestKind.ping => 'Đang ping broker...',
    };
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    _testResult = null;
    _busy = false;
    _statusMessage = 'Chưa kết nối thiết bị để kiểm tra.';
    notifyListeners();
    return false;
  }

  Future<bool> saveWifiToDevice() async {
    _busy = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _busy = false;
    _statusMessage = 'Đã lưu cấu hình WiFi lên ESP32';
    notifyListeners();
    return true;
  }

  Future<bool> saveMqttToDevice() async {
    _busy = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _busy = false;
    _statusMessage = 'Đã lưu cấu hình MQTT lên ESP32';
    notifyListeners();
    return true;
  }

  Future<bool> saveMappingsToDevice() async {
    _busy = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _busy = false;
    _statusMessage = 'Đã đồng bộ mapping GPIO';
    notifyListeners();
    return true;
  }

  Future<bool> checkOtaUpdate() async {
    _busy = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _busy = false;
    _statusMessage = 'Chưa có thông tin firmware từ thiết bị.';
    notifyListeners();
    return _ota.updateAvailable;
  }

  Future<bool> applyOtaUpdate() async {
    _busy = true;
    _statusMessage = 'Đang cập nhật OTA...';
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    _device = Esp32Device(
      id: _device.id,
      name: _device.name,
      type: _device.type,
      area: _device.area,
      assignment: _device.assignment,
      firmwareVersion: _ota.latestVersion,
      status: _device.status,
      lastSeen: 'Vừa xong',
      macAddress: _device.macAddress,
      localIp: _device.localIp,
      uptime: '0d 00h 05m',
      hardwareVersion: _device.hardwareVersion,
    );
    _ota = OtaFirmwareInfo(
      currentVersion: _ota.latestVersion,
      latestVersion: _ota.latestVersion,
      updateAvailable: false,
      history: [
        OtaUpdateLog(
          version: _ota.latestVersion,
          appliedAt: 'Vừa xong',
          status: 'Thành công',
        ),
        ..._ota.history,
      ],
    );
    _busy = false;
    _statusMessage = 'Cập nhật OTA thành công';
    notifyListeners();
    return true;
  }

  Future<void> restartNode() async {
    _busy = true;
    _statusMessage = 'Đang khởi động lại node...';
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    _busy = false;
    _statusMessage = 'Node đã khởi động lại';
    notifyListeners();
  }
}
