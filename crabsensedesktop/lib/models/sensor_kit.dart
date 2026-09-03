class SensorKitPlan {
  const SensorKitPlan({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.description,
    required this.features,
    required this.sensorCount,
    required this.includesAi,
    required this.recommended,
  });

  final String id;
  final String name;
  final String priceLabel;
  final String description;
  final List<String> features;
  final int sensorCount;
  final bool includesAi;
  final bool recommended;
}

class CurrentSensorKit {
  const CurrentSensorKit({
    required this.planName,
    required this.activeSensors,
    required this.maxSensors,
    required this.firmwareVersion,
    required this.lastSync,
  });

  final String planName;
  final int activeSensors;
  final int maxSensors;
  final String firmwareVersion;
  final String lastSync;
}
