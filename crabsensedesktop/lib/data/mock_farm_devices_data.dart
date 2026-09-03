import 'package:flutter/material.dart';

import '../models/device_status.dart';
import '../models/farm_device.dart';

export 'device_summary.dart';

abstract final class MockFarmDevicesData {
  static const areaName = 'Khu vực A';
  static const totalDevices = 128;
  static const pageSize = 4;

  static List<FarmDevice> allDevices() => [
        const FarmDevice(
          apiId: 'mock-001',
          id: '#SN-2024-001',
          name: 'Dissolved Oxygen Sensor',
          typeLabel: 'Cảm biến DO',
          location: 'Tank A-01',
          status: DeviceStatus.online,
          lastSync: 'Just now',
          icon: Icons.air_outlined,
        ),
        const FarmDevice(
          apiId: 'mock-002',
          id: '#SN-2024-002',
          name: 'Nano Aerator',
          typeLabel: 'Máy sục khí',
          location: 'Tank A-02',
          status: DeviceStatus.online,
          lastSync: '5 mins ago',
          icon: Icons.bubble_chart_outlined,
        ),
        const FarmDevice(
          apiId: 'mock-003',
          id: '#SN-2024-003',
          name: 'Salinity Sensor',
          typeLabel: 'Cảm biến độ mặn',
          location: 'Tank A-03',
          status: DeviceStatus.maintenance,
          lastSync: '2 hours ago',
          icon: Icons.waves_outlined,
        ),
        const FarmDevice(
          apiId: 'mock-004',
          id: '#SN-2024-004',
          name: 'Recirculating Pump',
          typeLabel: 'Máy bơm tuần hoàn',
          location: 'Filter Cluster A',
          status: DeviceStatus.offline,
          lastSync: '1 day ago',
          icon: Icons.settings_input_component_outlined,
        ),
        const FarmDevice(
          apiId: 'mock-005',
          id: '#SN-2024-005',
          name: 'pH Sensor',
          typeLabel: 'Cảm biến pH',
          location: 'Tank A-04',
          status: DeviceStatus.online,
          lastSync: 'Just now',
          icon: Icons.science_outlined,
        ),
        const FarmDevice(
          apiId: 'mock-006',
          id: '#SN-2024-006',
          name: 'Temperature Probe',
          typeLabel: 'Cảm biến nhiệt độ',
          location: 'Tank A-05',
          status: DeviceStatus.online,
          lastSync: '12 mins ago',
          icon: Icons.thermostat_outlined,
        ),
        const FarmDevice(
          apiId: 'mock-007',
          id: '#SN-2024-007',
          name: 'Auto Feeder F-02',
          typeLabel: 'Máy cho ăn tự động',
          location: 'Tank A-06',
          status: DeviceStatus.online,
          lastSync: '3 mins ago',
          icon: Icons.restaurant_outlined,
        ),
        const FarmDevice(
          apiId: 'mock-008',
          id: '#SN-2024-008',
          name: 'NH3 Sensor S-21',
          typeLabel: 'Cảm biến NH3',
          location: 'Tank A-07',
          status: DeviceStatus.maintenance,
          lastSync: '45 mins ago',
          icon: Icons.warning_amber_outlined,
        ),
      ];
}
