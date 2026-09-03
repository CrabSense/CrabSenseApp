import '../models/device_status.dart';
import '../models/farm_device.dart';

class DeviceAreaSummary {
  const DeviceAreaSummary({
    required this.total,
    required this.active,
    required this.activePercent,
    required this.maintenance,
    required this.emergencyMaintenance,
    required this.offline,
    required this.connectionPercent,
  });

  final int total;
  final int active;
  final double activePercent;
  final int maintenance;
  final int emergencyMaintenance;
  final int offline;
  final double connectionPercent;

  static DeviceAreaSummary fromDevices(List<FarmDevice> devices) {
    if (devices.isEmpty) {
      return const DeviceAreaSummary(
        total: 0,
        active: 0,
        activePercent: 0,
        maintenance: 0,
        emergencyMaintenance: 0,
        offline: 0,
        connectionPercent: 0,
      );
    }

    final total = devices.length;
    final active =
        devices.where((d) => d.status == DeviceStatus.online).length;
    final maintenance =
        devices.where((d) => d.status == DeviceStatus.maintenance).length;
    final offline =
        devices.where((d) => d.status == DeviceStatus.offline).length;
    return DeviceAreaSummary(
      total: total,
      active: active,
      activePercent: double.parse((active / total * 100).toStringAsFixed(1)),
      maintenance: maintenance,
      emergencyMaintenance: maintenance,
      offline: offline,
      connectionPercent: double.parse((active / total * 100).toStringAsFixed(1)),
    );
  }
}
