import 'dart:async';
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
    this.lastError = '',
    this.cloudBackendUrl = '',
    this.sensors = const [],
    this.outputs = const [],
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
  final String lastError;
  final String cloudBackendUrl;
  final List<EspSensorPin> sensors;
  final List<EspOutputPin> outputs;

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
    final pins = _parseSensors(json['sensors'] ?? json['Sensors']);
    final outputs = _parseOutputs(json['outputs'] ?? json['Outputs']);
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
          n(json['lastHeartbeatSeconds'] ?? json['LastHeartbeatSeconds'])?.toInt(),
      sensorCount: n(json['sensorCount'] ?? json['SensorCount'])?.toInt() ??
          (pins.isEmpty ? null : pins.length),
      outputCount: n(json['outputCount'] ?? json['OutputCount'])?.toInt() ??
          (outputs.isEmpty ? null : outputs.length),
      lastError: read('lastError', 'LastError'),
      cloudBackendUrl: read('backendUrl', 'BackendUrl'),
      sensors: pins,
      outputs: outputs,
    );
  }
}

class EspOutputPin {
  const EspOutputPin({required this.channel, required this.gpio, this.on});

  final int channel;
  final int gpio;
  final bool? on;
}

List<EspOutputPin> _parseOutputs(dynamic raw) {
  if (raw is! List) return const [];
  final pins = <EspOutputPin>[];
  for (final e in raw.whereType<Map>()) {
    final m = Map<String, dynamic>.from(e);
    final channel = m['channel'] ?? m['Channel'];
    final gpio = m['gpio'] ?? m['Gpio'] ?? m['pin'] ?? m['Pin'];
    final ch = channel is num ? channel.toInt() : int.tryParse('$channel') ?? 0;
    final pin = gpio is num ? gpio.toInt() : int.tryParse('$gpio') ?? 0;
    if (ch < 1 || pin <= 0) continue;
    pins.add(EspOutputPin(
      channel: ch,
      gpio: pin,
      on: m['on'] == true || m['On'] == true
          ? true
          : (m['on'] == false || m['On'] == false ? false : null),
    ));
  }
  return pins;
}

class EspSensorPin {
  const EspSensorPin({
    required this.suffix,
    required this.sensorCode,
    required this.sensorType,
    required this.unit,
    required this.interface,
    required this.gpio,
    required this.channel,
  });

  final String suffix;
  final String sensorCode;
  final String sensorType;
  final String unit;
  final String interface;
  final int gpio;
  final String channel;
}

List<EspSensorPin> _parseSensors(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((e) {
    final m = Map<String, dynamic>.from(e);
    String s(String a, [String? b]) =>
        (m[a] ?? (b == null ? null : m[b]))?.toString() ?? '';
    final gpio = m['gpio'] ?? m['Gpio'] ?? m['pin'] ?? m['Pin'];
    return EspSensorPin(
      suffix: s('suffix', 'Suffix'),
      sensorCode: s('sensorCode', 'SensorCode'),
      sensorType: s('sensorType', 'SensorType'),
      unit: s('unit', 'Unit'),
      interface: s('interface', 'Interface'),
      gpio: gpio is num ? gpio.toInt() : int.tryParse('$gpio') ?? 0,
      channel: s('channel', 'Channel'),
    );
  }).toList();
}

class ControllerProvisioningService {
  ControllerProvisioningService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const defaultApBase = 'http://192.168.4.1';
  static const setupSsid = 'CrabSense-C115';

  /// Kiosk URL the ESP can reach: this PC on the farm LAN, port 8090.
  static Future<String> localKioskUrl({int port = 8090}) async {
    String? other;
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
          if (ip.startsWith('192.168.1.')) return 'http://$ip:$port';
          if (ip.startsWith('192.168.') && other == null) other = ip;
        }
      }
    } catch (_) {}
    if (other != null) return 'http://$other:$port';
    return 'http://192.168.1.95:$port';
  }

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
    // The board stops answering while a kiosk call is in flight (~5s).
    final res =
        await _client.get(uri).timeout(const Duration(seconds: 8));
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
    final prefixes = <String>{};
    try {
      final ifaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (!ip.startsWith('192.168.') || ip.startsWith('192.168.4.')) {
            continue;
          }
          final parts = ip.split('.');
          if (parts.length == 4) {
            prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
          }
        }
      }
    } catch (_) {}
    if (prefixes.isEmpty) prefixes.add('192.168.1');

    final targets = <String>[
      for (final prefix in prefixes)
        for (var i = 1; i <= 254; i++) '$prefix.$i',
    ];
    const batch = 48;
    for (var i = 0; i < targets.length; i += batch) {
      final end = min(i + batch, targets.length);
      await Future.wait(
        targets.sublist(i, end).map(
              (host) => Process.run(
                'ping',
                ['-n', '1', '-w', '200', host],
                runInShell: true,
              ).then((_) {}, onError: (_) {}),
            ),
      );
    }

    final hosts = <String>{'192.168.4.1'};
    try {
      final arp = await Process.run('arp', ['-a'], runInShell: true);
      final re = RegExp(r'\b((?:\d{1,3}\.){3}\d{1,3})\b');
      for (final match in re.allMatches(arp.stdout.toString())) {
        final ip = match.group(1)!;
        if (ip.startsWith('192.168.') && !ip.endsWith('.255')) hosts.add(ip);
      }
    } catch (_) {}
    return hosts.toList();
  }

  Future<EspProvisionInfo> provision({
    required String ssid,
    required String password,
    String? backendUrl,
    String? kioskUrl,
    String? baseUrl,
  }) async {
    final root = baseUrl ?? defaultApBase;
    final uri = Uri.parse('$root/api/provision');
    final payload = jsonEncode({
      'ssid': ssid.trim(),
      'password': password,
      if (backendUrl != null && backendUrl.trim().isNotEmpty)
        'backendUrl': backendUrl.trim(),
      if (kioskUrl != null && kioskUrl.trim().isNotEmpty)
        'kioskUrl': kioskUrl.trim(),
    });

    try {
      final res = await _postProvision(uri, payload);
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
    } on TimeoutException {
      throw const FormatException(
        'ESP32 không phản hồi. Máy tính phải đang ở Wi-Fi CrabSense-C115.',
      );
    }
  }

  Future<String?> currentSsid() async {
    try {
      final result = await Process.run(
        'netsh',
        ['wlan', 'show', 'interfaces'],
      );
      final match = RegExp(r'^\s*SSID\s*:\s*(.+)\s*$', multiLine: true)
          .firstMatch(result.stdout.toString());
      final name = match?.group(1)?.trim();
      if (name == null || name.isEmpty) return null;
      return name;
    } catch (_) {
      return null;
    }
  }

  /// Join the board's open setup network so 192.168.4.1 is reachable.
  Future<void> joinSetupAp() async {
    if (await currentSsid() == setupSsid) {
      await _waitForSetupAp();
      return;
    }
    final xmlPath = '${Directory.systemTemp.path}\\CrabSense-C115.xml';
    await File(xmlPath).writeAsString(_setupProfileXml, flush: true);
    final add = await Process.run(
      'netsh',
      ['wlan', 'add', 'profile', 'filename=$xmlPath'],
    );
    if (add.exitCode != 0) {
      throw const FormatException('Không thêm được Wi-Fi CrabSense-C115');
    }
    final connect = await Process.run(
      'netsh',
      ['wlan', 'connect', 'name=$setupSsid'],
    );
    if (connect.exitCode != 0) {
      throw const FormatException('Không kết nối được Wi-Fi CrabSense-C115');
    }
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (await currentSsid() == setupSsid) break;
      if (i == 19) {
        throw const FormatException('Không vào được Wi-Fi CrabSense-C115');
      }
    }
    await _waitForSetupAp();
  }

  Future<void> _waitForSetupAp() async {
    Object? last;
    for (var i = 0; i < 4; i++) {
      try {
        await discover();
        return;
      } catch (e) {
        last = e;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw FormatException('Không mở được cấu hình trên CrabSense-C115. $last');
  }

  Future<void> joinSaved(String profile) async {
    final name = profile.trim();
    if (name.isEmpty) return;
    await Process.run(
      'netsh',
      ['wlan', 'connect', 'name=$name', 'ssid=$name'],
    );
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (await currentSsid() == name) return;
    }
  }

  static const _setupProfileXml = '''
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>CrabSense-C115</name>
  <SSIDConfig>
    <SSID><name>CrabSense-C115</name></SSID>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>manual</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>open</authentication>
        <encryption>none</encryption>
        <useOneX>false</useOneX>
      </authEncryption>
    </security>
  </MSM>
</WLANProfile>
''';

  Future<http.Response> _postProvision(Uri uri, String payload) {
    return _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Connection': 'close',
            'Expect': '',
          },
          body: payload,
        )
        .timeout(const Duration(seconds: 6));
  }

  /// Chỉ gửi URL BE cho ESP. Không đổi Wi-Fi, không restart.
  Future<void> pushBackendUrl({
    required String baseUrl,
    required String backendUrl,
  }) async {
    final root = baseUrl.startsWith('http') ? baseUrl : 'http://$baseUrl';
    final uri = Uri.parse('$root/api/provision');
    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Connection': 'close',
          },
          body: jsonEncode({'backendUrl': backendUrl.trim()}),
        )
        .timeout(const Duration(seconds: 4));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw const FormatException('Không gửi được URL backend tới Controller');
    }
  }

  /// Ping ESP trên LAN qua `/api/info`. Không đổi trạng thái backend.
  Future<EspProvisionInfo> pingLan(String ip) {
    final host = ip.trim().replaceFirst(RegExp(r'^https?://'), '');
    return discover(baseUrl: 'http://$host');
  }

  /// Gửi lệnh restart nếu firmware hỗ trợ. Trả về false nếu không có kênh.
  Future<bool> restartLan(String ip) async {
    final host = ip.trim().replaceFirst(RegExp(r'^https?://'), '');
    try {
      final res = await _client
          .post(
            Uri.parse('http://$host/api/restart'),
            headers: {'Connection': 'close'},
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode >= 200 && res.statusCode < 300;
    } on TimeoutException {
      return true;
    } on SocketException {
      return true;
    } on http.ClientException {
      return true;
    }
  }

  /// Cafe page only stores farm Wi-Fi. Desktop sends the Kiosk address after the board is picked.
  Future<void> pushKioskUrl({
    required String baseUrl,
    required String kioskUrl,
  }) async {
    final root = baseUrl.startsWith('http') ? baseUrl : 'http://$baseUrl';
    final uri = Uri.parse('$root/api/provision');
    await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'kioskUrl': kioskUrl.trim()}),
        )
        .timeout(const Duration(seconds: 8));
  }

  /// Bật/tắt SSR trên board. `status` chỉ đọc trạng thái.
  Future<({bool output1, bool output2})?> commandEsp({
    required String ip,
    required String command,
    int? channel,
  }) async {
    final host = ip.trim().replaceFirst(RegExp(r'^https?://'), '');
    final res = await _client
        .post(
          Uri.parse('http://$host/api/command'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'command': command,
            if (channel != null) 'channel': channel,
          }),
        )
        .timeout(const Duration(seconds: 8));
    final decoded = jsonDecode(res.body);
    if (decoded is! Map || res.statusCode < 200 || res.statusCode >= 300) {
      return null;
    }
    return (
      output1: decoded['output1'] == true,
      output2: decoded['output2'] == true,
    );
  }
}
