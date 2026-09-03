import 'package:flutter/material.dart';

import 'device_status.dart';

class FarmDevice {
  const FarmDevice({
    required this.apiId,
    required this.id,
    required this.name,
    required this.typeLabel,
    required this.location,
    required this.status,
    required this.lastSync,
    required this.icon,
    this.areaId,
    this.areaCode,
    this.areaName,
  });

  /// Id GUID trên Cloud (cập nhật / xóa qua API).
  final String apiId;

  /// Mã hiển thị (deviceCode).
  final String id;
  final String name;
  final String typeLabel;
  final String location;
  final DeviceStatus status;
  final String lastSync;
  final IconData icon;
  final String? areaId;
  final String? areaCode;
  final String? areaName;
}
