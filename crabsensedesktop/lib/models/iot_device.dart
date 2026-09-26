import 'package:flutter/material.dart';

// ─── Enums for IoT control page ─────────────────────────────────────────────

enum IotDeviceType {
  pump,
  drumFilter,
  skimmer,
  airPump,
  uv,
  fan,
  feeder,
  valve;

  IconData get icon => switch (this) {
        pump => Icons.water_drop_outlined,
        drumFilter => Icons.filter_alt_outlined,
        skimmer => Icons.bubble_chart_outlined,
        airPump => Icons.air_outlined,
        uv => Icons.wb_sunny_outlined,
        fan => Icons.mode_fan_off_outlined,
        feeder => Icons.restaurant_outlined,
        valve => Icons.toggle_on_outlined,
      };
}

enum IotConnectionStatus {
  online,
  offline;

  Color get color => switch (this) {
        online => const Color(0xFF22C55E),
        offline => const Color(0xFF64748B),
      };

  String get label => switch (this) {
        online => 'ONLINE',
        offline => 'OFFLINE',
      };
}

enum IotRunStatus {
  running,
  stopped,
  error,
  warning;

  Color get color => switch (this) {
        running => const Color(0xFF3B82F6),
        stopped => const Color(0xFF64748B),
        error => const Color(0xFFEF4444),
        warning => const Color(0xFFF59E0B),
      };
}

enum IotControlMode {
  auto,
  manual;

  String get label => switch (this) {
        auto => 'AUTO',
        manual => 'MANUAL',
      };

  String get modeButtonLabel => switch (this) {
        auto => 'AUTO ✓',
        manual => 'MANUAL',
      };
}

// ─── Data classes for IoT control page ──────────────────────────────────────

class IotDeviceDetailMeta {
  const IotDeviceDetailMeta({
    required this.deviceCode,
    required this.firmware,
    required this.ip,
    required this.mqttStatus,
    required this.lastSeen,
  });

  final String deviceCode;
  final String firmware;
  final String ip;
  final String mqttStatus;
  final String lastSeen;
}

class IotDevice {
  const IotDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.location,
    required this.connection,
    required this.runStatus,
    required this.mode,
    required this.isOn,
    required this.powerWatts,
    required this.runCount,
    required this.scheduleInfo,
    required this.meta,
    this.lastRunTime = '',
    this.flowRate,
    this.errorMessage,
    this.hasNoError = true,
    this.showFixNow = false,
    this.showTestButton = false,
    this.doCurrent,
    this.doTarget,
    this.fanSpeedPercent,
    this.envTemp,
    this.fanThreshold,
    this.feedPortionG,
    this.feedsToday,
    this.feedSchedule,
    this.lastWashTime,
    this.cycleMinutes,
    this.totalWashes,
    this.skimmerEfficiency,
    this.uvHoursPerDay,
    this.uvLifespanHours,
    this.valveOpenPercent,
    this.valveCycleCount,
  });

  final String id;
  final String name;
  final IotDeviceType type;
  final String typeLabel;
  final String location;
  final IotConnectionStatus connection;
  final IotRunStatus runStatus;
  final IotControlMode mode;
  final bool isOn;
  final int powerWatts;
  final int runCount;
  final String scheduleInfo;
  final IotDeviceDetailMeta meta;
  final String lastRunTime;
  final String? flowRate;
  final String? errorMessage;
  final bool hasNoError;
  final bool showFixNow;
  final bool showTestButton;
  final double? doCurrent;
  final double? doTarget;
  final int? fanSpeedPercent;
  final int? envTemp;
  final int? fanThreshold;
  final int? feedPortionG;
  final int? feedsToday;
  final List<String>? feedSchedule;
  final String? lastWashTime;
  final int? cycleMinutes;
  final int? totalWashes;
  final int? skimmerEfficiency;
  final int? uvHoursPerDay;
  final int? uvLifespanHours;
  final int? valveOpenPercent;
  final int? valveCycleCount;

  bool get isRunning => runStatus == IotRunStatus.running;

  IotDevice copyWithTogglePower() => IotDevice(
        id: id, name: name, type: type, typeLabel: typeLabel,
        location: location, connection: connection, runStatus: runStatus,
        mode: mode, isOn: !isOn, powerWatts: powerWatts, runCount: runCount,
        scheduleInfo: scheduleInfo, meta: meta, lastRunTime: lastRunTime,
        flowRate: flowRate, errorMessage: errorMessage, hasNoError: hasNoError,
        showFixNow: showFixNow, showTestButton: showTestButton,
        doCurrent: doCurrent, doTarget: doTarget,
        fanSpeedPercent: fanSpeedPercent, envTemp: envTemp,
        fanThreshold: fanThreshold, feedPortionG: feedPortionG,
        feedsToday: feedsToday, feedSchedule: feedSchedule,
        lastWashTime: lastWashTime, cycleMinutes: cycleMinutes,
        totalWashes: totalWashes, skimmerEfficiency: skimmerEfficiency,
        uvHoursPerDay: uvHoursPerDay, uvLifespanHours: uvLifespanHours,
        valveOpenPercent: valveOpenPercent, valveCycleCount: valveCycleCount,
      );

  IotDevice copyWithMode(IotControlMode newMode) => IotDevice(
        id: id, name: name, type: type, typeLabel: typeLabel,
        location: location, connection: connection, runStatus: runStatus,
        mode: newMode, isOn: isOn, powerWatts: powerWatts, runCount: runCount,
        scheduleInfo: scheduleInfo, meta: meta, lastRunTime: lastRunTime,
        flowRate: flowRate, errorMessage: errorMessage, hasNoError: hasNoError,
        showFixNow: showFixNow, showTestButton: showTestButton,
        doCurrent: doCurrent, doTarget: doTarget,
        fanSpeedPercent: fanSpeedPercent, envTemp: envTemp,
        fanThreshold: fanThreshold, feedPortionG: feedPortionG,
        feedsToday: feedsToday, feedSchedule: feedSchedule,
        lastWashTime: lastWashTime, cycleMinutes: cycleMinutes,
        totalWashes: totalWashes, skimmerEfficiency: skimmerEfficiency,
        uvHoursPerDay: uvHoursPerDay, uvLifespanHours: uvLifespanHours,
        valveOpenPercent: valveOpenPercent, valveCycleCount: valveCycleCount,
      );
}

class IotDeviceKpi {
  const IotDeviceKpi({
    required this.online,
    required this.offline,
    required this.running,
    required this.error,
  });

  final int online;
  final int offline;
  final int running;
  final int error;
}

class IotDeviceOverview {
  const IotDeviceOverview({
    required this.total,
    required this.online,
    required this.offline,
    required this.running,
    required this.stopped,
    required this.error,
    required this.energyTodayKwh,
  });

  final int total;
  final int online;
  final int offline;
  final int running;
  final int stopped;
  final int error;
  final double energyTodayKwh;
}

class IotActivityLog {
  const IotActivityLog({
    required this.time,
    required this.deviceName,
    required this.action,
    required this.success,
  });

  final String time;
  final String deviceName;
  final String action;
  final bool success;
}

class IotAutomationRule {
  const IotAutomationRule({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
  });

  final String id;
  final String title;
  final String description;
  final bool enabled;

  IotAutomationRule copyWith({bool? enabled}) => IotAutomationRule(
        id: id,
        title: title,
        description: description,
        enabled: enabled ?? this.enabled,
      );
}

class IotScheduleEntry {
  const IotScheduleEntry({required this.time, required this.action});

  final String time;
  final String action;
}

class IotCalendarBlock {
  const IotCalendarBlock({required this.range, required this.label});

  final String range;
  final String label;
}

class IotDeviceStats {
  const IotDeviceStats({
    required this.totalRuntimeHours,
    required this.totalEnergyKwh,
    required this.powerOnCount,
    required this.errorCount,
    required this.efficiencyPercent,
  });

  final int totalRuntimeHours;
  final int totalEnergyKwh;
  final int powerOnCount;
  final int errorCount;
  final int efficiencyPercent;
}

class IotDeviceAlert {
  const IotDeviceAlert({
    required this.deviceName,
    required this.message,
    required this.severity,
  });

  final String deviceName;
  final String message;
  final IotRunStatus severity;
}

// ─── Cloud API model ────────────────────────────────────────────────────────

class IoTDevice {
  const IoTDevice({
    required this.id,
    required this.farmId,
    this.boxId,
    required this.deviceCode,
    this.deviceName,
    this.macAddress,
    this.firmwareVersion,
    this.ipLan,
    required this.status,
    this.lastTelemetryAt,
    this.lastSeenAt,
    this.boxCode,
    this.areaName,
    this.areaId,
    this.areaCode,
    this.sensorCount = 0,
    this.actuatorCount = 0,
    this.deviceType,
    this.rssiDbm,
    this.batteryLevel,
    this.rowId,
    this.rowName,
    this.rowCode,
    this.installationLocation,
    this.note,
  });

  final String id;
  final String farmId;
  final String? boxId;
  final String deviceCode;
  final String? deviceName;
  final String? macAddress;
  final String? firmwareVersion;
  final String? ipLan;
  final String status;
  final DateTime? lastTelemetryAt;
  final DateTime? lastSeenAt;
  final String? boxCode;
  final String? areaName;
  final String? areaId;
  final String? areaCode;
  final int sensorCount;
  final int actuatorCount;
  final String? deviceType;
  final double? rssiDbm;
  final double? batteryLevel;
  final String? rowId;
  final String? rowName;
  final String? rowCode;
  final String? installationLocation;
  final String? note;

  factory IoTDevice.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return IoTDevice(
      id: (json['id'] ?? json['Id']).toString(),
      farmId: (json['farmId'] ??
              json['FarmId'] ??
              json['farmingAreaId'] ??
              json['FarmingAreaId'] ??
              '')
          .toString(),
      boxId: (json['boxId'] ?? json['BoxId'])?.toString(),
      deviceCode: (json['deviceCode'] ?? json['DeviceCode'] ?? '').toString(),
      deviceName: (json['name'] ??
              json['Name'] ??
              json['deviceName'] ??
              json['DeviceName'] ??
              json['deviceCode'] ??
              json['DeviceCode'])
          ?.toString(),
      macAddress: (json['macAddress'] ?? json['MacAddress'])?.toString(),
      firmwareVersion:
          (json['firmwareVersion'] ?? json['FirmwareVersion'])?.toString(),
      ipLan: (json['ipAddress'] ??
              json['IpAddress'] ??
              json['ipLan'] ??
              json['IpLan'])
          ?.toString(),
      status: (json['status'] ?? json['Status'] ?? 'offline').toString(),
      lastTelemetryAt: parseDt(json['lastTelemetryAt'] ?? json['LastTelemetryAt']),
      lastSeenAt: parseDt(json['lastSeenAt'] ?? json['LastSeenAt']),
      boxCode: (json['boxCode'] ?? json['BoxCode'])?.toString(),
      areaName: (json['areaName'] ?? json['AreaName'])?.toString(),
      areaId: (json['areaId'] ?? json['AreaId'])?.toString(),
      areaCode: (json['areaCode'] ?? json['AreaCode'])?.toString(),
      sensorCount: (json['sensorCount'] ?? json['SensorCount'] as num?)?.toInt() ?? 0,
      actuatorCount:
          (json['actuatorCount'] ?? json['ActuatorCount'] as num?)?.toInt() ?? 0,
      deviceType: (json['deviceType'] ?? json['DeviceType'])?.toString(),
      rssiDbm: (json['rssiDbm'] ?? json['RssiDbm'] as num?)?.toDouble(),
      batteryLevel:
          (json['batteryLevel'] ?? json['BatteryLevel'] as num?)?.toDouble(),
      rowId: (json['farmingRowId'] ?? json['FarmingRowId'] ?? json['rowId'] ?? json['RowId'])?.toString(),
      rowName: (json['rowName'] ?? json['RowName'])?.toString(),
      rowCode: (json['rowCode'] ?? json['RowCode'])?.toString(),
      installationLocation: (json['installationLocation'] ?? json['InstallationLocation'])?.toString(),
      note: (json['note'] ?? json['Note'] ?? json['notes'] ?? json['Notes'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'boxId': boxId,
        'deviceCode': deviceCode,
        'deviceName': deviceName,
        'macAddress': macAddress,
        'firmwareVersion': firmwareVersion,
        'ipLan': ipLan,
        'status': status,
        'lastTelemetryAt': lastTelemetryAt?.toIso8601String(),
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'boxCode': boxCode,
        'areaName': areaName,
        'areaId': areaId,
        'areaCode': areaCode,
      };

  IoTDevice copyWith({
    String? id,
    String? farmId,
    String? Function()? boxId,
    String? deviceCode,
    String? Function()? deviceName,
    String? Function()? macAddress,
    String? Function()? firmwareVersion,
    String? Function()? ipLan,
    String? status,
    DateTime? Function()? lastTelemetryAt,
    DateTime? Function()? lastSeenAt,
    String? Function()? boxCode,
    String? Function()? areaName,
    String? Function()? areaId,
    String? Function()? areaCode,
  }) {
    return IoTDevice(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      boxId: boxId != null ? boxId() : this.boxId,
      deviceCode: deviceCode ?? this.deviceCode,
      deviceName: deviceName != null ? deviceName() : this.deviceName,
      macAddress: macAddress != null ? macAddress() : this.macAddress,
      firmwareVersion:
          firmwareVersion != null ? firmwareVersion() : this.firmwareVersion,
      ipLan: ipLan != null ? ipLan() : this.ipLan,
      status: status ?? this.status,
      lastTelemetryAt:
          lastTelemetryAt != null ? lastTelemetryAt() : this.lastTelemetryAt,
      lastSeenAt: lastSeenAt != null ? lastSeenAt() : this.lastSeenAt,
      boxCode: boxCode != null ? boxCode() : this.boxCode,
      areaName: areaName != null ? areaName() : this.areaName,
      areaId: areaId != null ? areaId() : this.areaId,
      areaCode: areaCode != null ? areaCode() : this.areaCode,
      sensorCount: sensorCount,
      actuatorCount: actuatorCount,
      deviceType: deviceType,
      rssiDbm: rssiDbm,
      batteryLevel: batteryLevel,
      rowId: rowId,
      rowName: rowName,
      rowCode: rowCode,
      installationLocation: installationLocation,
      note: note,
    );
  }

  bool get isOnline => status.toLowerCase() == 'online';
  bool get isOffline => !isOnline;

  String get statusLabel {
    switch (status) {
      case 'online':
        return 'Hoạt động';
      case 'offline':
        return 'Ngoại tuyến';
      case 'error':
        return 'Lỗi';
      default:
        return status;
    }
  }
}

class UpsertDeviceRequest {
  const UpsertDeviceRequest({
    this.deviceCode,
    this.deviceName,
    this.areaId,
    this.boxId,
    this.macAddress,
    this.firmwareVersion,
    this.ipLan,
    this.status = 'offline',
  });

  final String? deviceCode;
  final String? deviceName;
  final String? areaId;
  final String? boxId;
  final String? macAddress;
  final String? firmwareVersion;
  final String? ipLan;
  final String status;

  Map<String, dynamic> toJson() => {
        if (deviceCode != null) 'deviceCode': deviceCode,
        if (deviceName != null) 'deviceName': deviceName,
        if (areaId != null) 'areaId': areaId,
        if (boxId != null) 'boxId': boxId,
        if (macAddress != null) 'macAddress': macAddress,
        if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
        if (ipLan != null) 'ipLan': ipLan,
        'status': status,
      };
}
