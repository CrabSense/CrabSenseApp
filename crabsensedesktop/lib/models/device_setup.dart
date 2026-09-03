import 'package:flutter/material.dart';

enum DeviceSetupSection {
  deviceInfo,
  wifi,
  mqtt,
  sensorMapping,
  relayMapping,
  testConnection,
  cloudEdge,
  otaFirmware,
}

extension DeviceSetupSectionX on DeviceSetupSection {
  String get label => switch (this) {
        DeviceSetupSection.deviceInfo => 'Thông tin thiết bị',
        DeviceSetupSection.wifi => 'ESP32 WiFi Setup',
        DeviceSetupSection.mqtt => 'MQTT Config',
        DeviceSetupSection.sensorMapping => 'Sensor Mapping',
        DeviceSetupSection.relayMapping => 'Relay Mapping',
        DeviceSetupSection.testConnection => 'Test Connection',
        DeviceSetupSection.cloudEdge => 'Cloud API',
        DeviceSetupSection.otaFirmware => 'OTA Firmware',
      };

  IconData get icon => switch (this) {
        DeviceSetupSection.deviceInfo => Icons.memory_outlined,
        DeviceSetupSection.wifi => Icons.wifi_outlined,
        DeviceSetupSection.mqtt => Icons.hub_outlined,
        DeviceSetupSection.sensorMapping => Icons.sensors_outlined,
        DeviceSetupSection.relayMapping => Icons.electrical_services_outlined,
        DeviceSetupSection.testConnection => Icons.network_check_outlined,
        DeviceSetupSection.cloudEdge => Icons.cloud_sync_outlined,
        DeviceSetupSection.otaFirmware => Icons.system_update_outlined,
      };
}

enum Esp32DeviceType {
  sensor,
  pump,
  skimmer,
  drum,
  oxy,
  feeder,
  valve,
}

extension Esp32DeviceTypeX on Esp32DeviceType {
  String get label => switch (this) {
        Esp32DeviceType.sensor => 'Sensor',
        Esp32DeviceType.pump => 'Pump',
        Esp32DeviceType.skimmer => 'Skimmer',
        Esp32DeviceType.drum => 'Drum',
        Esp32DeviceType.oxy => 'Oxy',
        Esp32DeviceType.feeder => 'Feeder',
        Esp32DeviceType.valve => 'Valve',
      };
}

enum DeviceOnlineStatus { online, offline }

class Esp32Device {
  const Esp32Device({
    required this.id,
    required this.name,
    required this.type,
    required this.area,
    required this.assignment,
    required this.firmwareVersion,
    required this.status,
    required this.lastSeen,
    required this.macAddress,
    required this.localIp,
    required this.uptime,
    required this.hardwareVersion,
  });

  final String id;
  final String name;
  final Esp32DeviceType type;
  final String area;
  final String assignment;
  final String firmwareVersion;
  final DeviceOnlineStatus status;
  final String lastSeen;
  final String macAddress;
  final String localIp;
  final String uptime;
  final String hardwareVersion;
}

class WifiNetwork {
  const WifiNetwork({
    required this.ssid,
    required this.rssi,
    required this.secured,
    this.selected = false,
  });

  final String ssid;
  final int rssi;
  final bool secured;
  final bool selected;
}

class WifiConfig {
  const WifiConfig({
    required this.ssid,
    required this.password,
    this.smartConfigEnabled = false,
    this.bleProvisioningEnabled = false,
    this.apModeEnabled = false,
  });

  final String ssid;
  final String password;
  final bool smartConfigEnabled;
  final bool bleProvisioningEnabled;
  final bool apModeEnabled;

  WifiConfig copyWith({
    String? ssid,
    String? password,
    bool? smartConfigEnabled,
    bool? bleProvisioningEnabled,
    bool? apModeEnabled,
  }) =>
      WifiConfig(
        ssid: ssid ?? this.ssid,
        password: password ?? this.password,
        smartConfigEnabled: smartConfigEnabled ?? this.smartConfigEnabled,
        bleProvisioningEnabled:
            bleProvisioningEnabled ?? this.bleProvisioningEnabled,
        apModeEnabled: apModeEnabled ?? this.apModeEnabled,
      );
}

class MqttConfig {
  const MqttConfig({
    required this.brokerUrl,
    required this.port,
    required this.username,
    required this.password,
    required this.clientId,
    required this.topicPublish,
    required this.topicSubscribe,
    required this.qos,
    required this.keepAlive,
    required this.cleanSession,
    required this.tlsEnabled,
  });

  final String brokerUrl;
  final int port;
  final String username;
  final String password;
  final String clientId;
  final String topicPublish;
  final String topicSubscribe;
  final int qos;
  final int keepAlive;
  final bool cleanSession;
  final bool tlsEnabled;

  MqttConfig copyWith({
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
  }) =>
      MqttConfig(
        brokerUrl: brokerUrl ?? this.brokerUrl,
        port: port ?? this.port,
        username: username ?? this.username,
        password: password ?? this.password,
        clientId: clientId ?? this.clientId,
        topicPublish: topicPublish ?? this.topicPublish,
        topicSubscribe: topicSubscribe ?? this.topicSubscribe,
        qos: qos ?? this.qos,
        keepAlive: keepAlive ?? this.keepAlive,
        cleanSession: cleanSession ?? this.cleanSession,
        tlsEnabled: tlsEnabled ?? this.tlsEnabled,
      );
}

class SensorMapping {
  const SensorMapping({
    required this.id,
    required this.label,
    required this.gpio,
    required this.sendIntervalSeconds,
    required this.alertThreshold,
    required this.calibrationNote,
  });

  final String id;
  final String label;
  final int gpio;
  final int sendIntervalSeconds;
  final String alertThreshold;
  final String calibrationNote;

  SensorMapping copyWith({
    int? gpio,
    int? sendIntervalSeconds,
    String? alertThreshold,
    String? calibrationNote,
  }) =>
      SensorMapping(
        id: id,
        label: label,
        gpio: gpio ?? this.gpio,
        sendIntervalSeconds: sendIntervalSeconds ?? this.sendIntervalSeconds,
        alertThreshold: alertThreshold ?? this.alertThreshold,
        calibrationNote: calibrationNote ?? this.calibrationNote,
      );
}

enum RelayMode { auto, manual }

class RelayMapping {
  const RelayMapping({
    required this.id,
    required this.label,
    required this.gpio,
    required this.mode,
    required this.safeOnDisconnect,
  });

  final String id;
  final String label;
  final int gpio;
  final RelayMode mode;
  final String safeOnDisconnect;

  RelayMapping copyWith({
    int? gpio,
    RelayMode? mode,
    String? safeOnDisconnect,
  }) =>
      RelayMapping(
        id: id,
        label: label,
        gpio: gpio ?? this.gpio,
        mode: mode ?? this.mode,
        safeOnDisconnect: safeOnDisconnect ?? this.safeOnDisconnect,
      );
}

class FallbackRule {
  const FallbackRule({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class ConnectionTestResult {
  const ConnectionTestResult({
    required this.wifiConnected,
    required this.mqttConnected,
    required this.signalDbm,
    required this.latencyMs,
    required this.lastUpdate,
    required this.pingOk,
  });

  final bool wifiConnected;
  final bool mqttConnected;
  final int signalDbm;
  final int latencyMs;
  final String lastUpdate;
  final bool pingOk;
}

class OtaFirmwareInfo {
  const OtaFirmwareInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    required this.history,
  });

  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
  final List<OtaUpdateLog> history;
}

class OtaUpdateLog {
  const OtaUpdateLog({
    required this.version,
    required this.appliedAt,
    required this.status,
  });

  final String version;
  final String appliedAt;
  final String status;
}

enum DeviceSetupTestKind { wifi, mqtt, sensorPublish, relayCommand, ping }
