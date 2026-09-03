import 'package:flutter/material.dart';

import '../models/device_setup.dart';

abstract final class MockDeviceSetupData {
  static Esp32Device defaultDevice() => const Esp32Device(
        id: 'ESP32-KHU-A-01',
        name: 'Node cảm biến Khu A',
        type: Esp32DeviceType.sensor,
        area: 'Khu A — Dãy 1',
        assignment: 'Bể RAS-01 / Hộp A3',
        firmwareVersion: 'v1.8.4-stable',
        status: DeviceOnlineStatus.online,
        lastSeen: '22:35:10 — Hôm nay',
        macAddress: '48:E7:29:A1:CB:D4',
        localIp: '192.168.1.104',
        uptime: '14d 06h 22m',
        hardwareVersion: 'HARDWARE V2.4',
      );

  static WifiConfig wifi() => const WifiConfig(
        ssid: 'CrabFarm_HighSpeed_5G',
        password: '••••••••••••',
      );

  static List<WifiNetwork> wifiNetworks() => const [
        WifiNetwork(
          ssid: 'CrabFarm_Production_EXT',
          rssi: -42,
          secured: true,
          selected: true,
        ),
        WifiNetwork(
          ssid: 'CrabFarm_HighSpeed_5G',
          rssi: -55,
          secured: true,
        ),
        WifiNetwork(
          ssid: 'Neighbor_Farm_Guest',
          rssi: -78,
          secured: true,
        ),
      ];

  static MqttConfig mqtt(String deviceId) => MqttConfig(
        brokerUrl: 'mqtt.crabfarm.local',
        port: 8883,
        username: 'esp32_node',
        password: '••••••••',
        clientId: 'crabfarm_$deviceId',
        topicPublish: 'crabfarm/device/$deviceId/sensor',
        topicSubscribe: 'crabfarm/device/$deviceId/command',
        qos: 1,
        keepAlive: 60,
        cleanSession: true,
        tlsEnabled: true,
      );

  static List<String> mqttTopicTemplates(String deviceId) => [
        'crabfarm/device/$deviceId/sensor',
        'crabfarm/device/$deviceId/status',
        'crabfarm/device/$deviceId/command',
        'crabfarm/device/$deviceId/config',
      ];

  static List<SensorMapping> sensorMappings() => const [
        SensorMapping(
          id: 'ph',
          label: 'pH Sensor',
          gpio: 34,
          sendIntervalSeconds: 5,
          alertThreshold: '6.5 – 8.2',
          calibrationNote: 'Hiệu chuẩn lần cuối: 12/05/2026',
        ),
        SensorMapping(
          id: 'do',
          label: 'DO Sensor',
          gpio: 35,
          sendIntervalSeconds: 5,
          alertThreshold: '≥ 5.0 mg/L',
          calibrationNote: 'Probe mới — chưa hiệu chuẩn',
        ),
        SensorMapping(
          id: 'temp',
          label: 'Temperature',
          gpio: 32,
          sendIntervalSeconds: 10,
          alertThreshold: '26 – 32 °C',
          calibrationNote: 'Offset +0.2°C',
        ),
        SensorMapping(
          id: 'level',
          label: 'Water Level',
          gpio: 33,
          sendIntervalSeconds: 15,
          alertThreshold: 'Min 45%',
          calibrationNote: 'Ultrasonic — ổn định',
        ),
      ];

  static List<RelayMapping> relayMappings() => const [
        RelayMapping(
          id: 'pump',
          label: 'Relay máy bơm',
          gpio: 26,
          mode: RelayMode.auto,
          safeOnDisconnect: 'Tiếp tục chạy',
        ),
        RelayMapping(
          id: 'oxy',
          label: 'Relay sủi oxy',
          gpio: 27,
          mode: RelayMode.auto,
          safeOnDisconnect: 'Bật (NC)',
        ),
        RelayMapping(
          id: 'skimmer',
          label: 'Relay skimmer',
          gpio: 14,
          mode: RelayMode.auto,
          safeOnDisconnect: 'Tắt',
        ),
        RelayMapping(
          id: 'drum',
          label: 'Relay drum filter',
          gpio: 12,
          mode: RelayMode.manual,
          safeOnDisconnect: 'Tắt',
        ),
        RelayMapping(
          id: 'uv',
          label: 'Relay đèn UV',
          gpio: 13,
          mode: RelayMode.auto,
          safeOnDisconnect: 'Tắt',
        ),
        RelayMapping(
          id: 'feeder',
          label: 'Relay máy cho ăn',
          gpio: 15,
          mode: RelayMode.auto,
          safeOnDisconnect: 'Tắt',
        ),
        RelayMapping(
          id: 'valve',
          label: 'Relay van điện từ',
          gpio: 16,
          mode: RelayMode.auto,
          safeOnDisconnect: 'Giữ trạng thái an toàn',
        ),
      ];

  static List<FallbackRule> fallbackRules() => const [
        FallbackRule(
          title: 'Mất kết nối mạng',
          description:
              'Thiết bị chuyển chế độ Standalone, ghi dữ liệu vào thẻ SD tối đa 48 giờ.',
          icon: Icons.wifi_off_outlined,
        ),
        FallbackRule(
          title: 'Mất phản hồi MQTT (> 60s)',
          description:
              'Máy bơm tiếp tục chạy, oxy bật, máy cho ăn & UV tắt, van giữ trạng thái an toàn (NC).',
          icon: Icons.cloud_off_outlined,
        ),
      ];

  static ConnectionTestResult testResult() => const ConnectionTestResult(
        wifiConnected: true,
        mqttConnected: true,
        signalDbm: -62,
        latencyMs: 120,
        lastUpdate: '22:35:10',
        pingOk: true,
      );

  static OtaFirmwareInfo ota() => const OtaFirmwareInfo(
        currentVersion: 'v1.8.4-stable',
        latestVersion: 'v1.9.0-beta',
        updateAvailable: true,
        history: [
          OtaUpdateLog(
            version: 'v1.8.4-stable',
            appliedAt: '10/05/2026 08:12',
            status: 'Thành công',
          ),
          OtaUpdateLog(
            version: 'v1.8.2',
            appliedAt: '22/04/2026 19:40',
            status: 'Rollback',
          ),
        ],
      );

  static String nodeStatusLabel() => 'Kết nối ổn định';
}
