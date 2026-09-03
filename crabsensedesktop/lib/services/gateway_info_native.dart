import 'dart:io';

/// Native (Windows/macOS/Linux) — lấy hostname, IP, OS từ dart:io
Future<Map<String, String>> getGatewayNativeInfo() async {
  final hostname = Platform.localHostname;
  final osVersion = Platform.operatingSystemVersion;

  String localIp = '127.0.0.1';
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) {
          localIp = addr.address;
          break;
        }
      }
      if (localIp != '127.0.0.1') break;
    }
  } catch (_) {}

  final osShort = osVersion.length > 50 ? osVersion.substring(0, 50) : osVersion;
  final hostShort =
      hostname.length > 40 ? hostname.substring(0, 40) : hostname;

  return {
    'hostname': hostShort,
    'localIp': localIp.length > 50 ? localIp.substring(0, 50) : localIp,
    'osVersion': osShort,
  };
}
