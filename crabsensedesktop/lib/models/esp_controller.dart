import 'iot_device.dart';

class ControllerChild {
  const ControllerChild({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
    this.type,
    this.unit,
    this.isOn,
    this.latestValue,
    this.lastUpdatedAt,
    this.isActive = true,
    this.minThreshold,
    this.maxThreshold,
    this.relayChannel,
    this.controlMode,
    this.componentStatus,
    this.gpio,
    this.interface,
    this.channel,
  });

  final String id;
  final String code;
  final String name;
  final String kind;
  final String? type;
  final String? unit;
  final bool? isOn;
  final double? latestValue;
  final DateTime? lastUpdatedAt;
  final bool isActive;
  final double? minThreshold;
  final double? maxThreshold;
  final String? relayChannel;
  final String? controlMode;
  final String? componentStatus;
  final int? gpio;
  final String? interface;
  final String? channel;

  factory ControllerChild.sensor(Map<String, dynamic> json) {
    final raw = json['latestValue'] ?? json['LatestValue'];
    DateTime? dt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    final gpioRaw = json['gpio'] ?? json['Gpio'] ?? json['pin'] ?? json['Pin'];
    return ControllerChild(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      code: (json['sensorCode'] ?? json['SensorCode'] ?? '').toString(),
      name: (json['sensorType'] ?? json['SensorType'] ?? 'Sensor').toString(),
      kind: 'sensor',
      type: (json['sensorType'] ?? json['SensorType'])?.toString(),
      unit: (json['unit'] ?? json['Unit'])?.toString(),
      latestValue: raw is num ? raw.toDouble() : double.tryParse('$raw'),
      lastUpdatedAt: dt(json['latestMeasuredAt'] ?? json['LatestMeasuredAt'] ?? json['lastSeenAt'] ?? json['LastSeenAt']),
      isActive: json['isActive'] ?? json['IsActive'] ?? true,
      minThreshold: (json['minThreshold'] ?? json['MinThreshold'] as num?)?.toDouble(),
      maxThreshold: (json['maxThreshold'] ?? json['MaxThreshold'] as num?)?.toDouble(),
      gpio: gpioRaw is num ? gpioRaw.toInt() : int.tryParse('$gpioRaw'),
      interface: (json['interface'] ?? json['Interface'])?.toString(),
      channel: (json['channel'] ?? json['Channel'])?.toString(),
    );
  }

  factory ControllerChild.actuator(Map<String, dynamic> json) {
    return ControllerChild(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      kind: 'actuator',
      type: (json['type'] ?? json['Type'])?.toString(),
      isOn: json['isOn'] ?? json['IsOn'] as bool?,
      relayChannel: (json['relayChannel'] ?? json['RelayChannel'])?.toString(),
      controlMode: (json['controlMode'] ?? json['ControlMode'])?.toString(),
      componentStatus: (json['status'] ?? json['Status'])?.toString(),
    );
  }

  ControllerChild copyWith({
    int? gpio,
    String? interface,
    String? channel,
  }) {
    return ControllerChild(
      id: id,
      code: code,
      name: name,
      kind: kind,
      type: type,
      unit: unit,
      isOn: isOn,
      latestValue: latestValue,
      lastUpdatedAt: lastUpdatedAt,
      isActive: isActive,
      minThreshold: minThreshold,
      maxThreshold: maxThreshold,
      relayChannel: relayChannel,
      controlMode: controlMode,
      componentStatus: componentStatus,
      gpio: gpio ?? this.gpio,
      interface: interface ?? this.interface,
      channel: channel ?? this.channel,
    );
  }
}

class ControllerDetail {
  const ControllerDetail({
    required this.controller,
    required this.sensors,
    required this.actuators,
  });

  final IoTDevice controller;
  final List<ControllerChild> sensors;
  final List<ControllerChild> actuators;

  factory ControllerDetail.fromJson(Map<String, dynamic> json) {
    final sensorsRaw = json['sensors'] ?? json['Sensors'];
    final actsRaw = json['actuators'] ?? json['Actuators'];
    return ControllerDetail(
      controller: IoTDevice.fromJson(json),
      sensors: sensorsRaw is List
          ? sensorsRaw
              .whereType<Map>()
              .map((e) => ControllerChild.sensor(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      actuators: actsRaw is List
          ? actsRaw
              .whereType<Map>()
              .map((e) => ControllerChild.actuator(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
