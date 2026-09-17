import 'box_enums.dart';

/// Valid source values for a crab's origin.
///
/// Crabs can come from farm breeding, external purchase, or transfer
/// from another box (Requirement 16.1).
enum CrabSource {
  /// Crab was bred on the farm
  farm,

  /// Crab was purchased externally
  purchase,

  /// Crab was transferred from another box
  transfer,
}

/// Extension on CrabSource for display helpers.
extension CrabSourceExtension on CrabSource {
  /// Returns the human-readable display name for the source.
  String get displayName {
    switch (this) {
      case CrabSource.farm:
        return 'Farm';
      case CrabSource.purchase:
        return 'Purchase';
      case CrabSource.transfer:
        return 'Transfer';
    }
  }

  /// Returns the string identifier used in persistence / API.
  String get value {
    switch (this) {
      case CrabSource.farm:
        return 'farm';
      case CrabSource.purchase:
        return 'purchase';
      case CrabSource.transfer:
        return 'transfer';
    }
  }
}

/// Parses a raw source string into a [CrabSource].
///
/// Returns null if the value is not recognised.
CrabSource? crabSourceFromString(String value) {
  switch (value.toLowerCase()) {
    case 'farm':
      return CrabSource.farm;
    case 'purchase':
      return CrabSource.purchase;
    case 'transfer':
      return CrabSource.transfer;
    default:
      return null;
  }
}

/// Crab entity representing an individual crab record in the CrabSense system.
///
/// A crab record is associated with a specific box and tracks species,
/// weight, health, molting stage, origin, and who added it.
///
/// This is a pure domain entity with no external dependencies.
/// All fields are immutable (final); use [copyWith] to create modified copies.
///
/// Requirements: 16.1-16.10
class Crab {
  const Crab({
    required this.id,
    required this.boxId,
    required this.species,
    required this.weight,
    required this.moltingStatus,
    required this.healthStatus,
    required this.source,
    required this.addedAt,
    required this.addedBy,
    this.condition,
  });

  /// Unique identifier for the crab record
  final String id;

  /// Identifier of the box this crab belongs to
  final String boxId;

  /// Species classification of the crab
  final CrabSpecies species;

  /// Weight of the crab in grams — must be a positive value (Requirement 16.2)
  final double weight;

  /// Current molting stage of the crab
  final MoltingStatus moltingStatus;

  /// Current health status of the crab
  final HealthStatus healthStatus;

  /// Origin of the crab (farm, purchase, or transfer)
  final CrabSource source;

  /// Timestamp when this crab record was created (Requirement 16.6)
  final DateTime addedAt;

  /// Identifier of the Field Operator who added this crab (Requirement 16.6)
  final String addedBy;

  /// Tình trạng cua theo BE (`CrabDto.Condition`: normal, premolt, molting,
  /// softshell, problem, weak, dead…). Đây mới là trường app desktop dùng để
  /// hiện nhãn + màu; [moltingStatus] / [healthStatus] là bộ enum cũ của spec,
  /// BE không trả nên luôn rơi về mặc định. Null khi BE không trả.
  final String? condition;

  /// Returns true if this crab's weight is valid (positive decimal number).
  ///
  /// Requirement 16.2.
  bool get hasValidWeight => weight > 0;

  /// Creates a copy of this crab with the given fields replaced with new values
  Crab copyWith({
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
  }) => Crab(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Crab &&
        other.id == id &&
        other.boxId == boxId &&
        other.species == species &&
        other.weight == weight &&
        other.moltingStatus == moltingStatus &&
        other.healthStatus == healthStatus &&
        other.source == source &&
        other.addedAt == addedAt &&
        other.addedBy == addedBy &&
        other.condition == condition;
  }

  @override
  int get hashCode => Object.hash(
    id,
    boxId,
    species,
    weight,
    moltingStatus,
    healthStatus,
    source,
    addedAt,
    addedBy,
    condition,
  );

  @override
  String toString() =>
      'Crab(id: $id, boxId: $boxId, '
      'species: ${species.displayName}, weight: $weight, '
      'moltingStatus: ${moltingStatus.displayName}, '
      'healthStatus: ${healthStatus.displayName}, '
      'source: ${source.displayName}, addedAt: $addedAt, '
      'addedBy: $addedBy)';
}
