// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart' show CrabsCompanion;
import '../../domain/entities/box_enums.dart';
import '../../domain/entities/crab.dart';

/// Data Transfer Object (DTO) for the [Crab] entity with JSON serialization.
///
/// Handles serialization / deserialization of crab records from API responses
/// and local Drift rows. Enum fields use explicit string conversion helpers
/// for forward-compatibility with new enum values.
///
/// Requirements: 16.1-16.10
class CrabModel extends Crab {
  const CrabModel({
    required super.id,
    required super.boxId,
    required super.species,
    required super.weight,
    required super.moltingStatus,
    required super.healthStatus,
    required super.source,
    required super.addedAt,
    required super.addedBy,
    super.condition,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a [CrabModel] from a raw JSON map (API response).
  factory CrabModel.fromJson(Map<String, dynamic> json) {
    String asStr(Object? value) => value?.toString() ?? '';

    return CrabModel(
      id: asStr(json['id'] ?? json['Id']),
      boxId: asStr(json['boxId'] ?? json['box_id'] ?? json['BoxId']),
      species: _speciesFromString(
        asStr(json['species']).isEmpty ? 'mudCrab' : asStr(json['species']),
      ),
      weight: _asDouble(json['weight'] ?? json['weightGram'] ?? json['weight_gram']),
      moltingStatus: _moltingStatusFromString(
        asStr(
          json['moltingStatus'] ??
              json['molting_status'] ??
              json['moltingStage'] ??
              json['molting_stage'] ??
              'unknown',
        ),
      ),
      healthStatus: _healthStatusFromString(
        asStr(json['healthStatus'] ?? json['health_status'] ?? 'unknown'),
      ),
      source: _sourceFromString(
        asStr(json['source']).isEmpty ? 'farm' : asStr(json['source']),
      ),
      addedAt: _parseDateTime(
        asStr(
          json['addedAt'] ?? json['added_at'] ?? json['stockedAt'] ?? json['stocked_at'],
        ),
      ),
      addedBy: () {
        final tag = asStr(json['tag']);
        if (tag.isNotEmpty && tag.toLowerCase() != 'system') return tag;
        final by = asStr(json['addedBy'] ?? json['added_by']);
        return by;
      }(),
      // Trường chuẩn để hiện tình trạng cua (nhãn + màu giống app desktop).
      condition: (json['condition'] ?? json['Condition'])?.toString(),
    );
  }

  /// Creates a [CrabModel] from Drift column values (local DB row).
  factory CrabModel.fromDrift({
    required String id,
    required String boxId,
    required String species,
    required double weight,
    required String moltingStatus,
    required String healthStatus,
    required String source,
    required DateTime addedAt,
    required String addedBy,
  }) => CrabModel(
    id: id,
    boxId: boxId,
    species: _speciesFromString(species),
    weight: weight,
    moltingStatus: _moltingStatusFromString(moltingStatus),
    healthStatus: _healthStatusFromString(healthStatus),
    source: _sourceFromString(source),
    addedAt: addedAt,
    addedBy: addedBy,
  );

  /// Creates a [CrabModel] from a domain [Crab] entity.
  factory CrabModel.fromEntity(Crab crab) => CrabModel(
    id: crab.id,
    boxId: crab.boxId,
    species: crab.species,
    weight: crab.weight,
    moltingStatus: crab.moltingStatus,
    healthStatus: crab.healthStatus,
    source: crab.source,
    addedAt: crab.addedAt,
    addedBy: crab.addedBy,
    condition: crab.condition,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Serialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this [CrabModel] to a JSON map suitable for API requests.
  Map<String, dynamic> toJson() => {
    'id': id,
    'boxId': boxId,
    'species': _speciesToString(species),
    'weight': weight,
    'moltingStatus': _moltingStatusToString(moltingStatus),
    'healthStatus': _healthStatusToString(healthStatus),
    'source': source.value,
    'addedAt': addedAt.toIso8601String(),
    'addedBy': addedBy,
  };

  /// Converts this [CrabModel] to a domain [Crab] entity.
  Crab toEntity() => Crab(
    id: id,
    boxId: boxId,
    species: species,
    weight: weight,
    moltingStatus: moltingStatus,
    healthStatus: healthStatus,
    source: source,
    addedAt: addedAt,
    addedBy: addedBy,
    condition: condition,
  );

  /// Converts this [CrabModel] to a [CrabsCompanion] for Drift inserts/updates.
  CrabsCompanion toDriftCompanion({bool isDirty = false}) => CrabsCompanion(
    id: Value(id),
    boxId: Value(boxId),
    species: Value(_speciesToString(species)),
    weight: Value(weight),
    moltingStatus: Value(_moltingStatusToString(moltingStatus)),
    healthStatus: Value(_healthStatusToString(healthStatus)),
    source: Value(source.value),
    addedAt: Value(addedAt),
    addedBy: Value(addedBy),
    isDirty: Value(isDirty),
  );

  @override
  CrabModel copyWith({
    String? id,
    String? boxId,
    CrabSpecies? species,
    double? weight,
    MoltingStatus? moltingStatus,
    HealthStatus? healthStatus,
    CrabSource? source,
    DateTime? addedAt,
    String? addedBy,
    String? condition,
  }) => CrabModel(
    id: id ?? this.id,
    boxId: boxId ?? this.boxId,
    species: species ?? this.species,
    weight: weight ?? this.weight,
    moltingStatus: moltingStatus ?? this.moltingStatus,
    healthStatus: healthStatus ?? this.healthStatus,
    source: source ?? this.source,
    addedAt: addedAt ?? this.addedAt,
    addedBy: addedBy ?? this.addedBy,
    condition: condition ?? this.condition,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Private enum helpers
  // ──────────────────────────────────────────────────────────────────────────

  static CrabSpecies _speciesFromString(String value) {
    switch (value.toLowerCase()) {
      case 'bluecrab':
      case 'blue_crab':
        return CrabSpecies.blueCrab;
      case 'softshell':
      case 'soft_shell':
        return CrabSpecies.softShell;
      case 'mudcrab':
      case 'mud_crab':
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

  static MoltingStatus _moltingStatusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'premolt':
      case 'pre_molt':
      case 'medium':
        return MoltingStatus.preMolt;
      case 'molting':
        return MoltingStatus.molting;
      case 'postmolt':
      case 'post_molt':
      case 'soft':
        return MoltingStatus.postMolt;
      case 'hardshell':
      case 'hard_shell':
      case 'hard':
        return MoltingStatus.hardShell;
      default:
        return MoltingStatus.hardShell;
    }
  }

  static String _moltingStatusToString(MoltingStatus status) {
    switch (status) {
      case MoltingStatus.preMolt:
        return 'preMolt';
      case MoltingStatus.molting:
        return 'molting';
      case MoltingStatus.postMolt:
        return 'postMolt';
      case MoltingStatus.hardShell:
        return 'hardShell';
    }
  }

  static HealthStatus _healthStatusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'normal':
        return HealthStatus.normal;
      case 'disease':
        return HealthStatus.disease;
      case 'stress':
        return HealthStatus.stress;
      default:
        return HealthStatus.unknown;
    }
  }

  static String _healthStatusToString(HealthStatus status) {
    switch (status) {
      case HealthStatus.normal:
        return 'normal';
      case HealthStatus.disease:
        return 'disease';
      case HealthStatus.stress:
        return 'stress';
      case HealthStatus.unknown:
        return 'unknown';
    }
  }

  static CrabSource _sourceFromString(String value) =>
      crabSourceFromString(value) ?? CrabSource.farm;

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.tryParse(value) ?? DateTime.now().toUtc();
  }
}
