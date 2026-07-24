/// Thiết bị IoT từ GET /api/devices.
class IotDevice {
  const IotDevice({
    required this.id,
    required this.deviceCode,
    required this.deviceType,
    required this.status,
    this.firmwareVersion,
    this.batteryLevel,
    this.rssiDbm,
    this.lastSeenAt,
    this.sensorCount = 0,
  });

  final String id;
  final String deviceCode;
  final String deviceType;
  final String status;
  final String? firmwareVersion;
  final double? batteryLevel;
  final double? rssiDbm;
  final DateTime? lastSeenAt;
  final int sensorCount;

  bool get isOnline {
    final s = status.toLowerCase();
    return s == 'active' || s == 'online' || s == 'ready' || s == 'running';
  }

  String get typeLabel {
    final t = deviceType.toLowerCase();
    if (t.contains('esp') || t.contains('controller') || t.contains('gateway')) {
      return 'ESP32 / Gateway';
    }
    if (t.contains('cam')) return 'Camera AI';
    if (t.contains('sensor')) return 'Cảm biến';
    if (t.contains('pump') || t.contains('bơm')) return 'Máy bơm';
    if (t.contains('valve') || t.contains('van')) return 'Van';
    if (deviceType.trim().isEmpty) return 'Thiết bị';
    return deviceType;
  }

  String get statusLabelVi {
    if (isOnline) return 'Online';
    final s = status.toLowerCase();
    if (s.contains('offline') || s.contains('disconnect')) return 'Offline';
    if (s.contains('maintain')) return 'Bảo trì';
    if (status.trim().isEmpty) return 'Không rõ';
    return status;
  }

  factory IotDevice.fromJson(Map<String, dynamic> json) {
    DateTime? lastSeen;
    final raw = json['lastSeenAt']?.toString();
    if (raw != null && raw.isNotEmpty) {
      lastSeen = DateTime.tryParse(raw);
    }
    return IotDevice(
      id: json['id']?.toString() ?? '',
      deviceCode: json['deviceCode']?.toString() ??
          json['code']?.toString() ??
          '—',
      deviceType: json['deviceType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      firmwareVersion: json['firmwareVersion']?.toString(),
      batteryLevel: (json['batteryLevel'] as num?)?.toDouble(),
      rssiDbm: (json['rssiDbm'] as num?)?.toDouble(),
      lastSeenAt: lastSeen,
      sensorCount: (json['sensorCount'] as num?)?.toInt() ?? 0,
    );
  }
}

enum DevicesFilter { all, online, offline }

enum DevicesTypeFilter { all, esp, camera, sensor, pump, valve }
