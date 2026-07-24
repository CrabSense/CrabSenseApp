import 'box_enums.dart';

/// Represents the geographic location of a box within the farm layout.
///
/// Used to display box position on the farm map (Requirement 4.9).
class Location {
  const Location({required this.latitude, required this.longitude, this.label});

  /// Latitude coordinate
  final double latitude;

  /// Longitude coordinate
  final double longitude;

  /// Optional label for the location within the farm layout
  final String? label;

  /// Creates a copy of this location with the given fields replaced.
  Location copyWith({double? latitude, double? longitude, String? label}) => Location(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    label: label ?? this.label,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, label);

  @override
  String toString() =>
      'Location(latitude: $latitude, longitude: $longitude, '
      'label: $label)';
}

/// Box entity representing a crab farming container in the CrabSense system.
///
/// A Box is the primary unit of crab management — it holds a group of crabs,
/// belongs to a farm (optionally a pond), and is identified by a QR code.
///
/// This is a pure domain entity with no external dependencies.
/// All fields are immutable (final); use [copyWith] to create modified copies.
///
/// Requirements: 4.1-4.10
class Box {
  const Box({
    required this.id,
    required this.qrCode,
    required this.farmId,
    required this.location,
    required this.currentCrabCount,
    required this.capacity,
    required this.species,
    required this.averageWeight,
    required this.status,
    required this.createdAt,
    this.pondId,
    this.lastVideoAt,
  });

  /// Unique identifier for the box
  final String id;

  /// QR code string used to identify the box when scanned
  final String qrCode;

  /// Identifier of the farm this box belongs to
  final String farmId;

  /// Optional identifier of the pond this box is assigned to
  final String? pondId;

  /// Geographic location of the box within the farm layout
  final Location location;

  /// Number of crabs currently in this box
  final int currentCrabCount;

  /// Maximum number of crabs this box can hold
  final int capacity;

  /// Species of crabs in this box
  final CrabSpecies species;

  /// Average weight of crabs in this box (in grams)
  final double averageWeight;

  /// Current operational status of the box
  final BoxStatus status;

  /// Timestamp when this box was created
  final DateTime createdAt;

  /// Timestamp of the last video capture for this box (null if none)
  final DateTime? lastVideoAt;

  /// Returns true if the box data is stale (older than 30 minutes).
  ///
  /// When stale, the UI should display a data freshness warning.
  /// Requirement 4.10.
  bool get isDataStale {
    final threshold = DateTime.now().subtract(const Duration(minutes: 30));
    return createdAt.isBefore(threshold);
  }

  /// Returns true if the box has remaining capacity for more crabs.
  bool get hasCapacity => currentCrabCount < capacity;

  /// Returns the number of remaining crab slots.
  int get remainingCapacity => capacity - currentCrabCount;

  /// Creates a copy of this box with the given fields replaced with new values.
  Box copyWith({
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
  }) => Box(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Box &&
        other.id == id &&
        other.qrCode == qrCode &&
        other.farmId == farmId &&
        other.pondId == pondId &&
        other.location == location &&
        other.currentCrabCount == currentCrabCount &&
        other.capacity == capacity &&
        other.species == species &&
        other.averageWeight == averageWeight &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.lastVideoAt == lastVideoAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    qrCode,
    farmId,
    pondId,
    location,
    currentCrabCount,
    capacity,
    species,
    averageWeight,
    status,
    createdAt,
    lastVideoAt,
  );

  @override
  String toString() =>
      'Box(id: $id, qrCode: $qrCode, farmId: $farmId, '
      'pondId: $pondId, location: $location, '
      'currentCrabCount: $currentCrabCount, capacity: $capacity, '
      'species: ${species.displayName}, averageWeight: $averageWeight, '
      'status: ${status.displayName}, createdAt: $createdAt, '
      'lastVideoAt: $lastVideoAt)';
}
