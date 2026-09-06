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
  });

  final String id;
  final String code;
  final String name;
  final String kind;
  final String? type;
  final String? unit;
  final bool? isOn;

  factory ControllerChild.sensor(Map<String, dynamic> json) {
    return ControllerChild(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      code: (json['sensorCode'] ?? json['SensorCode'] ?? '').toString(),
      name: (json['sensorType'] ?? json['SensorType'] ?? 'Sensor').toString(),
      kind: 'sensor',
      type: (json['sensorType'] ?? json['SensorType'])?.toString(),
      unit: (json['unit'] ?? json['Unit'])?.toString(),
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
