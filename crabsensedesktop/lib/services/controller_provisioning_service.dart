import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Talks to the ESP32 on the provisioning AP or the farm LAN.
/// Wi-Fi password stays on this PC → ESP32 NVS. It is never sent to CrabSenseBE.
class EspProvisionInfo {
  const EspProvisionInfo({
    required this.deviceId,
    required this.deviceCode,
    required this.apName,
    required this.controllerType,
    required this.firmware,
    required this.mac,
    this.provisioned = false,
    this.staIp = '',
    this.baseUrl = ControllerProvisioningService.defaultApBase,
    this.board = '',
    this.wifiSsid = '',
    this.rssi,
    this.lastHeartbeatSeconds,
    this.sensorCount,
    this.outputCount,
  });

  final String deviceId;
  final String deviceCode;
  final String apName;
  final String controllerType;
  final String firmware;
  final String mac;
  final bool provisioned;
  final String staIp;
  final String baseUrl;
  final String board;
  final String wifiSsid;
  final double? rssi;
  final int? lastHeartbeatSeconds;
  final int? sensorCount;
  final int? outputCount;

  String get displayName => apName.isNotEmpty
      ? apName
      : (deviceCode.isNotEmpty ? deviceCode : deviceId);

  String get hardwareId => deviceId.isNotEmpty
      ? deviceId
      : (deviceCode.isNotEmpty ? deviceCode : mac);

  String get ip => staIp.isNotEmpty
      ? staIp
      : baseUrl.replaceFirst(RegExp(r'^https?://'), '').split('/').first;

  factory EspProvisionInfo.fromJson(
    Map<String, dynamic> json, {
    String baseUrl = ControllerProvisioningService.defaultApBase,
  }) {
    String read(String a, [String? b]) {
      final v = json[a] ?? (b == null ? null : json[b]);
      return v?.toString() ?? '';
    }

    num? n(dynamic v) => v is num ? v : num.tryParse('$v');
    return EspProvisionInfo(
      deviceId: read('deviceId', 'DeviceId'),
      deviceCode: read('deviceCode', 'DeviceCode'),
      apName: read('apName', 'ApName'),
      controllerType: read('controllerType', 'ControllerType'),
      firmware: read('firmware', 'Firmware'),
      mac: read('mac', 'Mac'),
      provisioned: json['provisioned'] == true || json['Provisioned'] == true,
      staIp: read('staIp', 'StaIp'),
      baseUrl: baseUrl,
      board: read('board', 'Board'),
      wifiSsid: read('wifiSsid', 'WifiSsid').isNotEmpty
          ? read('wifiSsid', 'WifiSsid')
          : read('ssid', 'Ssid'),
      rssi:
          n(json['rssi'] ?? json['Rssi'] ?? json['rssiDbm'] ?? json['RssiDbm'])
              ?.toDouble(),
      lastHeartbeatSeconds:
          n(json['lastHeartbeatSeconds'] ?? json['LastHeartbeatSeconds'])
              ?.toInt(),
      sensorCount: n(json['sensorCount'] ?? json['SensorCount'])?.toInt(),
      outputCount: n(json['outputCount'] ?? json['OutputCount'])?.toInt(),
    );
  }
}

class ControllerProvisioningService {
  ControllerProvisioningService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const defaultApBase = 'http://192.168.4.1';

  /// Desktop uses localhost; ESP cannot. Replace with this PC's LAN IPv4.
  static Future<String> backendUrlForEsp(String cloudApiUrl) async {
    final uri = Uri.tryParse(cloudApiUrl);
    if (uri == null || uri.host.isEmpty) return cloudApiUrl;
    final loopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (!loopback) return cloudApiUrl;

    String? fallback;
    try {
      final ifaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('127.') ||
              ip.startsWith('169.254.') ||
              ip.startsWith('192.168.4.')) {
            continue;
          }
          fallback ??= ip;
          if (ip.startsWith('192.168.110.')) {
            return uri.replace(host: ip).toString();
          }
        }
      }
    } catch (_) {}

    if (fallback == null) return cloudApiUrl;
    return uri.replace(host: fallback).toString();
  }

  Future<EspProvisionInfo> discover({String baseUrl = defaultApBase}) async {
    final uri = Uri.parse('$baseUrl/api/info');
    final res =
        await _client.get(uri).timeout(const Duration(milliseconds: 700));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw const FormatException('Controller không trả /api/info');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw const FormatException('Phản hồi /api/info không hợp lệ');
    }
    return EspProvisionInfo.fromJson(
      Map<String, dynamic>.from(decoded),
      baseUrl: baseUrl,
    );
  }

  /// AP 192.168.4.1 first, then the farm LAN (ESP may already have left AP-only mode).
  Future<EspProvisionInfo> discoverNearby() async {
    final all = await discoverAllNearby();
    if (all.isEmpty) {
      throw const FormatException(
        'Không thấy CrabSense trên 192.168.4.1 hay LAN. '
        'Nếu ESP đã vào Wi-Fi trại, bấm Tìm khi PC cùng mạng, hoặc đăng ký thủ công.',
      );
    }
    return all.first;
  }

  /// Quét toàn LAN, trả mọi board phản hồi `/api/info`.
  Future<List<EspProvisionInfo>> discoverAllNearby() async {
    final found = <String, EspProvisionInfo>{};
    void keep(EspProvisionInfo? info) {
      if (info == null) return;
      if (info.deviceCode.isEmpty &&
          info.deviceId.isEmpty &&
          info.mac.isEmpty) {
        return;
      }
      final key = [
        info.mac,
        info.deviceId,
        info.deviceCode,
        info.ip,
      ].where((e) => e.isNotEmpty).join('|');
      found[key] = info;
    }

    try {
      keep(await discover(baseUrl: defaultApBase));
    } catch (_) {}

    final hosts = await _lanHosts();
    const batch = 32;
    for (var i = 0; i < hosts.length; i += batch) {
      final end = min(i + batch, hosts.length);
      final slice = hosts.sublist(i, end);
      final results = await Future.wait(
        slice.map((host) async {
          try {
            return await discover(baseUrl: 'http://$host');
          } catch (_) {
            return null;
          }
        }),
      );
      for (final info in results) {
        keep(info);
      }
    }
    return found.values.toList();
  }

  Future<List<String>> _lanHosts() async {
    final hosts = <String>{'192.168.110.240', '192.168.4.1'};
    try {
      final ifaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length != 4) continue;
          if (parts[0] == '127') continue;
          final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
          for (var i = 1; i <= 254; i++) {
            hosts.add('$prefix.$i');
          }
        }
      }
    } catch (_) {}
    return hosts.toList();
  }

  Future<EspProvisionInfo> provision({
    required String ssid,
    required String password,
    String? kioskUrl,
    String? baseUrl,
  }) async {
    final root = baseUrl ?? defaultApBase;
    final uri = Uri.parse('$root/api/provision');
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ssid': ssid.trim(),
            'password': password,
            if (kioskUrl != null && kioskUrl.trim().isNotEmpty)
              'kioskUrl': kioskUrl.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw const FormatException('Phản hồi provision không hợp lệ');
    }
    final map = Map<String, dynamic>.from(decoded);
    if (res.statusCode < 200 ||
        res.statusCode >= 300 ||
        map['success'] == false) {
      throw FormatException(
        (map['message'] ?? 'Không gửi được Wi-Fi tới ESP32').toString(),
      );
    }

    return EspProvisionInfo(
      deviceId: (map['deviceId'] ?? '').toString(),
      deviceCode: (map['deviceCode'] ?? '').toString(),
      apName: (map['deviceCode'] ?? '').toString(),
      controllerType: '',
      firmware: '',
      mac: (map['mac'] ?? '').toString(),
      provisioned: true,
      baseUrl: root,
    );
  }

  /// Ping ESP trên LAN qua `/api/info`. Không đổi trạng thái backend.
  Future<EspProvisionInfo> pingLan(String ip) {
    final host = ip.trim().replaceFirst(RegExp(r'^https?://'), '');
    return discover(baseUrl: 'http://$host');
  }

  /// Gửi lệnh restart nếu firmware hỗ trợ. Trả về false nếu không có kênh.
  Future<bool> restartLan(String ip) async {
    final host = ip.trim().replaceFirst(RegExp(r'^https?://'), '');
    for (final path in const [
      '/api/restart',
      '/api/reboot',
      '/restart',
      '/reboot'
    ]) {
      try {
        final res = await _client
            .post(Uri.parse('http://$host$path'))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode >= 200 && res.statusCode < 300) return true;
      } catch (_) {}
    }
    return false;
  }
}
