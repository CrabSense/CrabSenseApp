// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart' show WaterQualityReadingsCompanion;
import '../../domain/entities/water_quality.dart';

/// Data Transfer Object (DTO) for the [WaterQuality] entity.
///
/// Handles JSON serialization/deserialization for API responses and
/// Drift row mapping for local database operations. Extends the domain
/// entity so it can be used directly as a [WaterQuality] wherever needed.
///
/// Requirements: 8.1-8.10
class WaterQualityModel extends WaterQuality {
  const WaterQualityModel({
    required super.id,
    required super.sensorId,
    required super.farmId,
    required super.temperature,
    required super.ph,
    required super.dissolvedOxygen,
    required super.salinity,
    required super.timestamp,
    required super.isAlertTriggered,
    super.pondId,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a [WaterQualityModel] from a raw API JSON map.
  ///
  /// Accepts both camelCase and snake_case field names for compatibility
  /// with different API response shapes.
  factory WaterQualityModel.fromJson(Map<String, dynamic> json) => WaterQualityModel(
    id: json['id'] as String,
    sensorId: json['sensorId'] as String? ?? json['sensor_id'] as String? ?? '',
    farmId: json['farmId'] as String? ?? json['farm_id'] as String? ?? '',
    pondId: json['pondId'] as String? ?? json['pond_id'] as String?,
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
    ph: (json['ph'] as num?)?.toDouble() ?? 0.0,
    dissolvedOxygen:
        (json['dissolvedOxygen'] as num?)?.toDouble() ??
        (json['dissolved_oxygen'] as num?)?.toDouble() ??
        0.0,
    salinity: (json['salinity'] as num?)?.toDouble() ?? 0.0,
    timestamp: _parseDateTime(json['timestamp'] as String? ?? json['recorded_at'] as String?),
    isAlertTriggered:
        json['isAlertTriggered'] as bool? ?? json['is_alert_triggered'] as bool? ?? false,
  );

  /// Creates a [WaterQualityModel] from a Drift database row.
  factory WaterQualityModel.fromDrift({
    required String id,
    required String sensorId,
    required String farmId,
    required String? pondId,
    required double temperature,
    required double ph,
    required double dissolvedOxygen,
    required double salinity,
    required DateTime timestamp,
    required bool isAlertTriggered,
  }) => WaterQualityModel(
    id: id,
    sensorId: sensorId,
    farmId: farmId,
    pondId: pondId,
    temperature: temperature,
    ph: ph,
    dissolvedOxygen: dissolvedOxygen,
    salinity: salinity,
    timestamp: timestamp,
    isAlertTriggered: isAlertTriggered,
  );

  /// Creates a [WaterQualityModel] from a domain [WaterQuality] entity.
  factory WaterQualityModel.fromEntity(WaterQuality entity) => WaterQualityModel(
    id: entity.id,
    sensorId: entity.sensorId,
    farmId: entity.farmId,
    pondId: entity.pondId,
    temperature: entity.temperature,
    ph: entity.ph,
    dissolvedOxygen: entity.dissolvedOxygen,
    salinity: entity.salinity,
    timestamp: entity.timestamp,
    isAlertTriggered: entity.isAlertTriggered,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Serialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
    'id': id,
    'sensorId': sensorId,
    'farmId': farmId,
    'pondId': pondId,
    'temperature': temperature,
    'ph': ph,
    'dissolvedOxygen': dissolvedOxygen,
    'salinity': salinity,
    'timestamp': timestamp.toIso8601String(),
    'isAlertTriggered': isAlertTriggered,
  };

  /// Converts this model to a [WaterQualityReadingsCompanion] for Drift.
  WaterQualityReadingsCompanion toDriftCompanion({bool isDirty = false}) =>
      WaterQualityReadingsCompanion(
        id: Value(id),
        sensorId: Value(sensorId),
        farmId: Value(farmId),
        pondId: Value(pondId),
        temperature: Value(temperature),
        ph: Value(ph),
        dissolvedOxygen: Value(dissolvedOxygen),
        salinity: Value(salinity),
        timestamp: Value(timestamp),
        isAlertTriggered: Value(isAlertTriggered),
        isDirty: Value(isDirty),
      );

  /// Converts this model to the domain [WaterQuality] entity.
  WaterQuality toEntity() => WaterQuality(
    id: id,
    sensorId: sensorId,
    farmId: farmId,
    pondId: pondId,
    temperature: temperature,
    ph: ph,
    dissolvedOxygen: dissolvedOxygen,
    salinity: salinity,
    timestamp: timestamp,
    isAlertTriggered: isAlertTriggered,
  );

  @override
  WaterQualityModel copyWith({
    String? id,
    String? sensorId,
    String? farmId,
    String? pondId,
    double? temperature,
    double? ph,
    double? dissolvedOxygen,
    double? salinity,
    DateTime? timestamp,
    bool? isAlertTriggered,
  }) => WaterQualityModel(
    id: id ?? this.id,
    sensorId: sensorId ?? this.sensorId,
    farmId: farmId ?? this.farmId,
    pondId: pondId ?? this.pondId,
    temperature: temperature ?? this.temperature,
    ph: ph ?? this.ph,
    dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
    salinity: salinity ?? this.salinity,
    timestamp: timestamp ?? this.timestamp,
    isAlertTriggered: isAlertTriggered ?? this.isAlertTriggered,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.parse(value);
  }
}
