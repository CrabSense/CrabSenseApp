// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart' show BoxesCompanion;
import '../../../dashboard/data/models/dashboard_summary_model.dart' show DashboardSummaryModel;
import '../../domain/entities/box.dart';
import '../../domain/entities/box_enums.dart';

/// Data Transfer Object (DTO) for the [Box] entity with JSON serialization.
///
/// This model handles serialization / deserialization of box data from API
/// responses and local Drift rows. It adds JSON parsing on top of the domain
/// [Box] entity.
///
/// The `fromJson` / `toJson` methods are hand-rolled because the [Box] entity
/// has nested value objects ([Location]) and enum fields that require custom
/// conversion. The pattern intentionally mirrors other models in this project
/// (e.g. [DashboardSummaryModel]) by using simple factory constructors and
/// plain `toJson` methods rather than code generation.
///
/// Requirements: 4.1-4.10, 16.1-16.10
class BoxModel extends Box {
  const BoxModel({
    required super.id,
    required super.qrCode,
    required super.farmId,
    required super.location,
    required super.currentCrabCount,
    required super.capacity,
    required super.species,
    required super.averageWeight,
    required super.status,
    required super.createdAt,
    super.pondId,
    super.lastVideoAt,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a [BoxModel] from a raw JSON map (API response).
  factory BoxModel.fromJson(Map<String, dynamic> json) {
    String asStr(Object? value) => value?.toString() ?? '';

    return BoxModel(
      id: asStr(json['id']),
      qrCode: asStr(
        json['qrCode'] ?? json['qr_code'] ?? json['code'],
      ),
      farmId: asStr(
        json['farmId'] ??
            json['farm_id'] ??
            json['farmingAreaId'] ??
            json['farming_area_id'],
      ),
      pondId: () {
        final raw =
            json['pondId'] ??
            json['pond_id'] ??
            json['farmingRowId'] ??
            json['farming_row_id'];
        final s = asStr(raw);
        return s.isEmpty ? null : s;
      }(),
      location: _resolveLocation(json['location']),
      currentCrabCount:
          (json['currentCrabCount'] as num?)?.toInt() ??
          (json['current_crab_count'] as num?)?.toInt() ??
          0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      species: _speciesFromString(json['species'] as String? ?? 'mudCrab'),
      averageWeight:
          (json['averageWeight'] as num?)?.toDouble() ??
          (json['average_weight'] as num?)?.toDouble() ??
          0.0,
      status: _statusFromString(json['status'] as String? ?? 'active'),
      createdAt: _parseDateTime(
        json['createdAt'] as String? ?? json['created_at'] as String?,
      ),
      lastVideoAt: _parseDateTimeNullable(
        json['lastVideoAt'] as String? ?? json['last_video_at'] as String?,
      ),
    );
  }

  /// Creates a [BoxModel] from a Drift row (local DB).
  ///
  /// The `location` column is stored as a JSON string in the database.
  factory BoxModel.fromDrift({
    required String id,
    required String qrCode,
    required String farmId,
    required String? pondId,
    required String? locationJson,
    required int currentCrabCount,
    required int capacity,
    required String species,
    required double averageWeight,
    required String status,
    required DateTime createdAt,
    required DateTime? lastVideoAt,
  }) => BoxModel(
    id: id,
    qrCode: qrCode,
    farmId: farmId,
    pondId: pondId,
    location: _resolveLocationJson(locationJson),
    currentCrabCount: currentCrabCount,
    capacity: capacity,
    species: _speciesFromString(species),
    averageWeight: averageWeight,
    status: _statusFromString(status),
    createdAt: createdAt,
    lastVideoAt: lastVideoAt,
  );

  /// Creates a [BoxModel] from a domain [Box] entity.
  factory BoxModel.fromEntity(Box box) => BoxModel(
    id: box.id,
    qrCode: box.qrCode,
    farmId: box.farmId,
    pondId: box.pondId,
    location: box.location,
    currentCrabCount: box.currentCrabCount,
    capacity: box.capacity,
    species: box.species,
    averageWeight: box.averageWeight,
    status: box.status,
    createdAt: box.createdAt,
    lastVideoAt: box.lastVideoAt,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Serialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this [BoxModel] to a JSON map suitable for API requests.
  Map<String, dynamic> toJson() => {
    'id': id,
    'qrCode': qrCode,
    'farmId': farmId,
    'pondId': pondId,
    'location': _locationToJson(location),
    'currentCrabCount': currentCrabCount,
    'capacity': capacity,
    'species': _speciesToString(species),
    'averageWeight': averageWeight,
    'status': _statusToString(status),
    'createdAt': createdAt.toIso8601String(),
    'lastVideoAt': lastVideoAt?.toIso8601String(),
  };

  /// Converts the [location] to a JSON string for Drift storage.
  String locationToJsonString() => jsonEncode(_locationToJson(location));

  /// Converts this [BoxModel] to a [BoxesCompanion] for Drift inserts/updates.
  BoxesCompanion toDriftCompanion({bool isDirty = false}) => BoxesCompanion(
    id: Value(id),
    qrCode: Value(qrCode),
    farmId: Value(farmId),
    pondId: Value(pondId),
    location: Value(locationToJsonString()),
    currentCrabCount: Value(currentCrabCount),
    capacity: Value(capacity),
    species: Value(_speciesToString(species)),
    averageWeight: Value(averageWeight),
    status: Value(_statusToString(status)),
    createdAt: Value(createdAt),
    lastVideoAt: Value(lastVideoAt),
    isDirty: Value(isDirty),
  );

  /// Converts this [BoxModel] to a domain [Box] entity.
  Box toEntity() => Box(
    id: id,
    qrCode: qrCode,
    farmId: farmId,
    pondId: pondId,
    location: location,
    currentCrabCount: currentCrabCount,
    capacity: capacity,
    species: species,
    averageWeight: averageWeight,
    status: status,
    createdAt: createdAt,
    lastVideoAt: lastVideoAt,
  );

  @override
  BoxModel copyWith({
    String? id,
    String? qrCode,
    String? farmId,
    String? pondId,
    Location? location,
    int? currentCrabCount,
    int? capacity,
    CrabSpecies? species,
    double? averageWeight,
    BoxStatus? status,
    DateTime? createdAt,
    DateTime? lastVideoAt,
  }) => BoxModel(
    id: id ?? this.id,
    qrCode: qrCode ?? this.qrCode,
    farmId: farmId ?? this.farmId,
    pondId: pondId ?? this.pondId,
    location: location ?? this.location,
    currentCrabCount: currentCrabCount ?? this.currentCrabCount,
    capacity: capacity ?? this.capacity,
    species: species ?? this.species,
    averageWeight: averageWeight ?? this.averageWeight,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    lastVideoAt: lastVideoAt ?? this.lastVideoAt,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Resolves a raw API location value (Map or JSON string) to a [Location].
  static Location _resolveLocation(Object? locationRaw) {
    if (locationRaw is Map<String, dynamic>) {
      return _locationFromJson(locationRaw);
    }
    if (locationRaw is String && locationRaw.isNotEmpty) {
      return _locationFromJson(jsonDecode(locationRaw) as Map<String, dynamic>);
    }
    return const Location(latitude: 0, longitude: 0);
  }

  /// Resolves a nullable JSON string (from Drift column) to a [Location].
  static Location _resolveLocationJson(String? locationJson) {
    if (locationJson == null || locationJson.isEmpty) {
      return const Location(latitude: 0, longitude: 0);
    }
    try {
      return _locationFromJson(jsonDecode(locationJson) as Map<String, dynamic>);
    } on Exception {
      return const Location(latitude: 0, longitude: 0);
    }
  }

  static Location _locationFromJson(Map<String, dynamic> json) => Location(
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    label: json['label'] as String?,
  );

  static Map<String, dynamic> _locationToJson(Location loc) => {
    'latitude': loc.latitude,
    'longitude': loc.longitude,
    'label': loc.label,
  };

  static CrabSpecies _speciesFromString(String value) {
    switch (value.toLowerCase()) {
      case 'bluecrab':
      case 'blue_crab':
        return CrabSpecies.blueCrab;
      case 'mudcrab':
      case 'mud_crab':
        return CrabSpecies.mudCrab;
      case 'softshell':
      case 'soft_shell':
        return CrabSpecies.softShell;
      default:
        return CrabSpecies.mudCrab;
    }
  }

  static String _speciesToString(CrabSpecies species) {
    switch (species) {
      case CrabSpecies.blueCrab:
        return 'blueCrab';
      case CrabSpecies.mudCrab:
        return 'mudCrab';
      case CrabSpecies.softShell:
        return 'softShell';
    }
  }

  static BoxStatus _statusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return BoxStatus.active;
      case 'inactive':
        return BoxStatus.inactive;
      case 'maintenance':
        return BoxStatus.maintenance;
      case 'harvested':
        return BoxStatus.harvested;
      default:
        return BoxStatus.active;
    }
  }

  static String _statusToString(BoxStatus status) {
    switch (status) {
      case BoxStatus.active:
        return 'active';
      case BoxStatus.inactive:
        return 'inactive';
      case BoxStatus.maintenance:
        return 'maintenance';
      case BoxStatus.harvested:
        return 'harvested';
    }
  }

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.parse(value);
  }

  static DateTime? _parseDateTimeNullable(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.parse(value);
  }
}
