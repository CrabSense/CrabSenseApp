import 'package:equatable/equatable.dart';

import 'water_quality_thresholds.dart';

/// Qualified metadata for an online sensor measurement, not a legacy cache row.
enum LiveWaterKind {
  temperature('Nhiệt độ'), ph('pH'), oxygen('Oxy hòa tan'),
  salinity('Độ mặn'), tds('TDS');
  const LiveWaterKind(this.label);
  final String label;
}

class LiveWaterMetric extends Equatable {
  const LiveWaterMetric({
    required this.kind, required this.value, required this.unit,
    required this.receivedAt, required this.status,
    required this.sensorCode, this.min, this.max, this.alarm,
  });
  final LiveWaterKind kind;
  final double value;
  final String unit;
  final DateTime receivedAt;
  final String status;
  final String sensorCode;
  final double? min;
  final double? max;
  final String? alarm;

  bool get hasConfiguredThreshold => min != null || max != null;
  bool get outsideThreshold =>
      (min != null && value < min!) || (max != null && value > max!);
  @override
  List<Object?> get props => [kind,value,unit,receivedAt,status,sensorCode,min,max,alarm];
}

/// Water quality entity representing sensor readings for a specific location.
///
/// Captures real-time water quality parameters from IoT sensors deployed
/// in crab farming ponds. All measurements are timestamped for tracking
/// historical trends and detecting anomalies.
///
/// This is a pure domain entity with no external dependencies.
/// All fields are immutable (final); use [copyWith] to create modified copies.
///
/// Requirements: 8.1-8.10
class WaterQuality extends Equatable {
  const WaterQuality({
    required this.id,
    required this.sensorId,
    required this.farmId,
    required this.temperature,
    required this.ph,
    required this.dissolvedOxygen,
    required this.salinity,
    required this.timestamp,
    required this.isAlertTriggered,
    this.pondId,
    this.ammonia,
    this.nitrite,
    this.kh,
    this.calcium,
    this.magnesium,
    this.liveMetric,
  });

  /// Unique identifier for this water quality reading
  final String id;

  /// Identifier of the IoT sensor that captured these readings
  final String sensorId;

  /// Identifier of the farm where the sensor is located
  final String farmId;

  /// Optional identifier of the specific pond within the farm
  final String? pondId;

  /// Water temperature in degrees Celsius
  ///
  /// Normal range for mud crabs: 26.0°C - 30.0°C
  final double? temperature;

  /// pH level of the water
  ///
  /// Normal range for mud crabs: 7.5 - 8.5
  final double? ph;

  /// Dissolved oxygen concentration in milligrams per liter (mg/L)
  ///
  /// Minimum safe level for mud crabs: 5.0 mg/L
  final double? dissolvedOxygen;

  /// Salinity in parts per thousand (ppt)
  ///
  /// Normal range for mud crabs: 15.0 - 25.0 ppt
  final double? salinity;
  final double? ammonia;
  final double? nitrite;
  final double? kh;
  final double? calcium;
  final double? magnesium;
  final LiveWaterMetric? liveMetric;

  /// Timestamp when these readings were captured by the sensor
  final DateTime timestamp;

  /// Indicates whether any parameter exceeded threshold values
  ///
  /// When true, an alert notification should be displayed (Requirement 8.6).
  final bool isAlertTriggered;

  /// Returns true if the reading data is stale (older than 5 minutes).
  ///
  /// When stale, the UI should display a data freshness warning and
  /// indicate last known readings (Requirement 8.10).
  bool get isDataStale {
    final threshold = DateTime.now().subtract(const Duration(minutes: 5));
    return timestamp.isBefore(threshold);
  }

  /// Returns true if all parameters are within normal operating ranges.
  ///
  /// Uses [WaterQualityThresholds] to determine if values are acceptable.
  bool isWithinThresholds(WaterQualityThresholds thresholds) =>
      temperature?.isFinite == true && ph?.isFinite == true &&
      dissolvedOxygen?.isFinite == true && salinity?.isFinite == true &&
      temperature! >= thresholds.minTemperature &&
      temperature! <= thresholds.maxTemperature &&
      ph! >= thresholds.minPh &&
      ph! <= thresholds.maxPh &&
      dissolvedOxygen! >= thresholds.minDissolvedOxygen &&
      salinity! >= thresholds.minSalinity &&
      salinity! <= thresholds.maxSalinity;

  /// Creates a copy of this water quality reading with the given fields
  /// replaced with new values.
  WaterQuality copyWith({
    String? id,
    String? sensorId,
    String? farmId,
    String? pondId,
    double? temperature,
    double? ph,
    double? dissolvedOxygen,
    double? salinity,
    double? ammonia,
    double? nitrite,
    double? kh,
    double? calcium,
    double? magnesium,
    DateTime? timestamp,
    bool? isAlertTriggered,
    LiveWaterMetric? liveMetric,
  }) => WaterQuality(
    id: id ?? this.id,
    sensorId: sensorId ?? this.sensorId,
    farmId: farmId ?? this.farmId,
    pondId: pondId ?? this.pondId,
    temperature: temperature ?? this.temperature,
    ph: ph ?? this.ph,
    dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
    salinity: salinity ?? this.salinity,
    ammonia: ammonia ?? this.ammonia,
    nitrite: nitrite ?? this.nitrite,
    kh: kh ?? this.kh,
    calcium: calcium ?? this.calcium,
    magnesium: magnesium ?? this.magnesium,
    timestamp: timestamp ?? this.timestamp,
    isAlertTriggered: isAlertTriggered ?? this.isAlertTriggered,
    liveMetric: liveMetric ?? this.liveMetric,
  );

  @override
  List<Object?> get props => [
    id,
    sensorId,
    farmId,
    pondId,
    temperature,
    ph,
    dissolvedOxygen,
    salinity,
    ammonia,
    nitrite,
    kh,
    calcium,
    magnesium,
    timestamp,
    isAlertTriggered,
    liveMetric,
  ];

  @override
  String toString() =>
      'WaterQuality(id: $id, sensorId: $sensorId, farmId: $farmId, '
      'pondId: $pondId, temperature: $temperature°C, pH: $ph, '
      'dissolvedOxygen: ${dissolvedOxygen}mg/L, '
      'salinity: ${salinity}ppt, '
      'timestamp: $timestamp, isAlertTriggered: $isAlertTriggered)';
}
