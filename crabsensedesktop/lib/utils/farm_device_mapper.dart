import 'package:flutter/material.dart';

import '../models/device_status.dart';
import '../models/farm_device.dart';
import '../models/iot_device.dart';

DeviceStatus mapApiDeviceStatus(String status) {
  final s = status.trim().toLowerCase();
  return switch (s) {
    'online' || 'active' => DeviceStatus.online,
    'maintenance' || 'error' || 'warning' => DeviceStatus.maintenance,
    _ => DeviceStatus.offline,
  };
}

String formatDeviceLastSync(IoTDevice device) {
  final at = device.lastTelemetryAt ?? device.lastSeenAt;
  if (at == null) return 'Chưa có dữ liệu';
  final diff = DateTime.now().difference(at.toLocal());
  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return '${at.day.toString().padLeft(2, '0')}/'
      '${at.month.toString().padLeft(2, '0')}/'
      '${at.year}';
}

IconData iconForDevice(IoTDevice device) {
  final code = device.deviceCode.toUpperCase();
  final name = (device.deviceName ?? '').toLowerCase();
  if (code.startsWith('CAM') || name.contains('camera')) {
    return Icons.videocam_outlined;
  }
  if (code.startsWith('ESP') || name.contains('plc') || name.contains('gateway')) {
    return Icons.memory_outlined;
  }
  if (name.contains('bơm') || name.contains('pump')) {
    return Icons.settings_input_component_outlined;
  }
  if (name.contains('nhiệt') || name.contains('temp')) {
    return Icons.thermostat_outlined;
  }
  if (name.contains('ph')) return Icons.science_outlined;
  if (name.contains('oxy') || name.contains('do')) {
    return Icons.air_outlined;
  }
  return Icons.sensors_outlined;
}

String deviceTypeLabel(IoTDevice device) {
  final name = device.deviceName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final code = device.deviceCode.toUpperCase();
  if (code.startsWith('ESP')) return 'Thiết bị ESP32 / PLC';
  if (code.startsWith('CAM')) return 'Camera';
  return 'Thiết bị IoT';
}

String deviceLocationLabel(IoTDevice device) {
  final code = device.areaCode?.trim();
  final name = device.areaName?.trim();
  if (code != null && code.isNotEmpty) {
    if (name != null && name.isNotEmpty && name != code) {
      return 'Khu $code — $name';
    }
    return 'Khu $code';
  }
  if (name != null && name.isNotEmpty) {
    return 'Khu $name';
  }
  if (device.areaId != null && device.areaId!.trim().isNotEmpty) {
    return 'Đã gắn khu';
  }
  return 'Chưa gắn khu';
}

FarmDevice toFarmDevice(IoTDevice device) {
  return FarmDevice(
    apiId: device.id,
    id: device.deviceCode,
    name: device.deviceName?.trim().isNotEmpty == true
        ? device.deviceName!.trim()
        : device.deviceCode,
    typeLabel: deviceTypeLabel(device),
    location: deviceLocationLabel(device),
    status: mapApiDeviceStatus(device.status),
    lastSync: formatDeviceLastSync(device),
    icon: iconForDevice(device),
    areaId: device.areaId,
    areaCode: device.areaCode,
    areaName: device.areaName,
  );
}
