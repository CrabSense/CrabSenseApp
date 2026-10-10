class CameraDevice {
  final String id;
  final String gatewayId;
  final String? boxId;
  final String cameraCode;
  final String name;
  final String? streamUrl;
  final String? ipAddress;
  final String status;
  final DateTime? lastSeenAt;
  final String? boxCode;
  final String? snapshotUrl;
  final String? message;

  CameraDevice({
    required this.id,
    required this.gatewayId,
    this.boxId,
    required this.cameraCode,
    required this.name,
    this.streamUrl,
    this.ipAddress,
    required this.status,
    this.lastSeenAt,
    this.boxCode,
    this.snapshotUrl,
    this.message,
  });

  factory CameraDevice.fromBoxCamera(
    Map<String, dynamic> json, {
    String? fallbackBoxId,
  }) {
    final boxId = (json['boxId'] ?? json['BoxId'] ?? fallbackBoxId)?.toString();
    final deviceId = (json['deviceId'] ?? json['DeviceId'])?.toString();
    final code =
        (json['deviceCode'] ?? json['DeviceCode'] ?? 'CAM').toString();
    return CameraDevice(
      id: deviceId ?? boxId ?? code,
      gatewayId: '',
      boxId: boxId,
      cameraCode: code,
      name: code,
      streamUrl: (json['streamUrl'] ?? json['StreamUrl'])?.toString(),
      ipAddress: (json['snapshotUrl'] ?? json['SnapshotUrl'])?.toString(),
      status: (json['status'] ?? json['Status'] ?? 'offline').toString(),
      lastSeenAt: json['lastSeenAt'] != null || json['LastSeenAt'] != null
          ? DateTime.tryParse(
              (json['lastSeenAt'] ?? json['LastSeenAt']).toString(),
            )
          : null,
      boxCode: boxId,
      snapshotUrl: (json['snapshotUrl'] ?? json['SnapshotUrl'])?.toString(),
      message: (json['message'] ?? json['Message'])?.toString(),
    );
  }

  factory CameraDevice.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('deviceCode') || json.containsKey('DeviceCode')) {
      if (!(json.containsKey('id') || json.containsKey('Id'))) {
        return CameraDevice.fromBoxCamera(json);
      }
      final code = '${json['deviceCode'] ?? json['DeviceCode']}';
      final name = '${json['name'] ?? json['Name'] ?? ''}'.trim();
      return CameraDevice(
        id: '${json['id'] ?? json['Id']}',
        gatewayId: '${json['gatewayId'] ?? json['GatewayId'] ?? ''}',
        boxId: (json['boxId'] ?? json['BoxId'])?.toString(),
        cameraCode: code,
        name: name.isEmpty ? code : name,
        streamUrl: (json['streamUrl'] ?? json['StreamUrl'])?.toString(),
        ipAddress: (json['ipAddress'] ?? json['IpAddress'])?.toString(),
        status: '${json['status'] ?? json['Status'] ?? 'offline'}',
        lastSeenAt: json['lastSeenAt'] != null || json['LastSeenAt'] != null
            ? DateTime.tryParse((json['lastSeenAt'] ?? json['LastSeenAt']).toString())
            : null,
        snapshotUrl: (json['snapshotUrl'] ?? json['SnapshotUrl'])?.toString(),
      );
    }
    return CameraDevice(
      id: '${json['id'] ?? json['Id']}',
      gatewayId: '${json['gatewayId'] ?? json['GatewayId']}',
      boxId: (json['boxId'] ?? json['BoxId'])?.toString(),
      cameraCode: '${json['cameraCode'] ?? json['CameraCode']}',
      name: '${json['name'] ?? json['Name']}',
      streamUrl: (json['streamUrl'] ?? json['StreamUrl'] ?? json['stream_url'])
          ?.toString(),
      ipAddress: (json['ipAddress'] ?? json['IpAddress'] ?? json['ip_address'])
          ?.toString(),
      status: '${json['status'] ?? json['Status'] ?? 'offline'}',
      lastSeenAt: json['lastSeenAt'] != null || json['LastSeenAt'] != null
          ? DateTime.tryParse((json['lastSeenAt'] ?? json['LastSeenAt']).toString())
          : null,
      boxCode: json['boxCode'] as String? ?? json['BoxCode'] as String?,
      snapshotUrl: (json['snapshotUrl'] ?? json['SnapshotUrl'])?.toString(),
      message: (json['message'] ?? json['Message'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gatewayId': gatewayId,
      'boxId': boxId,
      'cameraCode': cameraCode,
      'name': name,
      'streamUrl': streamUrl,
      'ipAddress': ipAddress,
      'status': status,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'boxCode': boxCode,
    };
  }

  bool get isOnline => status.toLowerCase() == 'online';
}

class UpsertCameraRequest {
  final String? cameraCode;
  final String name;
  final String? boxId;
  final String? streamUrl;
  final String? ipAddress;
  final String status;

  UpsertCameraRequest({
    this.cameraCode,
    required this.name,
    this.boxId,
    this.streamUrl,
    this.ipAddress,
    this.status = 'offline',
  });

  Map<String, dynamic> toJson() {
    return {
      if (cameraCode != null) 'cameraCode': cameraCode,
      'name': name,
      if (boxId != null) 'boxId': boxId,
      if (streamUrl != null) 'streamUrl': streamUrl,
      if (ipAddress != null) 'ipAddress': ipAddress,
      'status': status,
    };
  }
}
