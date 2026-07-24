import 'package:equatable/equatable.dart';

/// Threshold values for water quality parameters.
///
/// Defines the acceptable operating ranges for each water quality parameter
/// in crab farming operations. Values outside these thresholds trigger
/// visual warnings and alert notifications (Requirements 8.4, 8.6).
///
/// These thresholds are based on optimal conditions for mud crab (Scylla spp.)
/// cultivation and may vary by species and farming methodology.
///
/// Requirements: 8.4, 8.6
class WaterQualityThresholds extends Equatable {
  const WaterQualityThresholds({
    this.minTemperature = 26.0,
    this.maxTemperature = 30.0,
    this.minPh = 7.5,
    this.maxPh = 8.5,
    this.minDissolvedOxygen = 5.0,
    this.minSalinity = 15.0,
    this.maxSalinity = 25.0,
  });

  /// Minimum acceptable water temperature in degrees Celsius
  ///
  /// Below this value, crab metabolism slows and growth is impacted.
  final double minTemperature;

  /// Maximum acceptable water temperature in degrees Celsius
  ///
  /// Above this value, oxygen levels drop and stress increases.
  final double maxTemperature;

  /// Minimum acceptable pH level
  ///
  /// Below this value, water becomes too acidic for optimal crab health.
  final double minPh;

  /// Maximum acceptable pH level
  ///
  /// Above this value, water becomes too alkaline for optimal crab health.
  final double maxPh;

  /// Minimum acceptable dissolved oxygen in milligrams per liter (mg/L)
  ///
  /// Below this value, crabs experience hypoxia and mortality risk increases.
  final double minDissolvedOxygen;

  /// Minimum acceptable salinity in parts per thousand (ppt)
  ///
  /// Below this value, water is too fresh for mud crab health.
  final double minSalinity;

  /// Maximum acceptable salinity in parts per thousand (ppt)
  ///
  /// Above this value, water is too saline for optimal crab health.
  final double maxSalinity;

  /// Checks if a temperature value is within acceptable range.
  bool isTemperatureNormal(double temperature) =>
      temperature >= minTemperature && temperature <= maxTemperature;

  /// Checks if a pH value is within acceptable range.
  bool isPhNormal(double ph) => ph >= minPh && ph <= maxPh;

  /// Checks if a dissolved oxygen value is within acceptable range.
  bool isDissolvedOxygenNormal(double dissolvedOxygen) => dissolvedOxygen >= minDissolvedOxygen;

  /// Checks if a salinity value is within acceptable range.
  bool isSalinityNormal(double salinity) => salinity >= minSalinity && salinity <= maxSalinity;

  /// Creates a copy of these thresholds with the given fields replaced.
  WaterQualityThresholds copyWith({
    double? minTemperature,
    double? maxTemperature,
    double? minPh,
    double? maxPh,
    double? minDissolvedOxygen,
    double? minSalinity,
    double? maxSalinity,
  }) => WaterQualityThresholds(
    minTemperature: minTemperature ?? this.minTemperature,
    maxTemperature: maxTemperature ?? this.maxTemperature,
    minPh: minPh ?? this.minPh,
    maxPh: maxPh ?? this.maxPh,
    minDissolvedOxygen: minDissolvedOxygen ?? this.minDissolvedOxygen,
    minSalinity: minSalinity ?? this.minSalinity,
    maxSalinity: maxSalinity ?? this.maxSalinity,
  );

  @override
  List<Object?> get props => [
    minTemperature,
    maxTemperature,
    minPh,
    maxPh,
    minDissolvedOxygen,
    minSalinity,
    maxSalinity,
  ];

  @override
  String toString() =>
      'WaterQualityThresholds('
      'temperature: $minTemperature°C - $maxTemperature°C, '
      'pH: $minPh - $maxPh, '
      'dissolvedOxygen: >=$minDissolvedOxygen mg/L, '
      'salinity: $minSalinity - $maxSalinity ppt)';
}
