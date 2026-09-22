/// Enums for the Box domain layer.
///
/// Defines status types and classifications for boxes and crabs
/// used throughout the box management feature.
library;

/// Status of a crab farming box.
///
/// Requirements: 4.1-4.10
enum BoxStatus {
  /// Box is in active use with crabs
  active,

  /// Box is not currently in use
  inactive,

  /// Box is undergoing maintenance
  maintenance,

  /// Box has been harvested
  harvested,
}

/// Extension on BoxStatus for display helpers.
extension BoxStatusExtension on BoxStatus {
  /// Returns the human-readable display name for the status.
  String get displayName {
    switch (this) {
      case BoxStatus.active:
        return 'Bình thường';
      case BoxStatus.inactive:
        return 'Hộp trống';
      case BoxStatus.maintenance:
        return 'Cần theo dõi';
      case BoxStatus.harvested:
        return 'Hộp trống';
    }
  }

  /// Returns true if the box can accept new crabs.
  bool get canAddCrabs => this == BoxStatus.active;
}

/// Species of crab contained in a box.
///
/// Requirements: 4.2, 16.1
enum CrabSpecies {
  /// Blue crab (Callinectes sapidus)
  blueCrab,

  /// Mud crab (Scylla serrata)
  mudCrab,

  /// Soft-shell crab
  softShell,
}

/// Extension on CrabSpecies for display helpers.
extension CrabSpeciesExtension on CrabSpecies {
  /// Returns the human-readable display name for the species.
  String get displayName {
    switch (this) {
      case CrabSpecies.blueCrab:
        return 'Blue Crab';
      case CrabSpecies.mudCrab:
        return 'Mud Crab';
      case CrabSpecies.softShell:
        return 'Soft Shell';
    }
  }
}

/// Molting stage of a crab.
///
/// Requirements: 4.4
enum MoltingStatus {
  /// Crab is preparing to molt
  preMolt,

  /// Crab is actively molting
  molting,

  /// Crab has recently molted, shell still soft
  postMolt,

  /// Crab has a fully hardened shell
  hardShell,
}

/// Extension on MoltingStatus for display helpers.
extension MoltingStatusExtension on MoltingStatus {
  /// Returns the human-readable display name.
  String get displayName {
    switch (this) {
      case MoltingStatus.preMolt:
        return 'Lột xác';
      case MoltingStatus.molting:
        return 'Lột xác';
      case MoltingStatus.postMolt:
        return 'Lột xác';
      case MoltingStatus.hardShell:
        return 'Bình thường';
    }
  }

  /// Returns true if the crab is in a vulnerable molting stage.
  bool get isVulnerable => this == MoltingStatus.molting || this == MoltingStatus.postMolt;
}

/// Health status of a crab as determined by AI detection or manual inspection.
///
/// Requirements: 4.4
enum HealthStatus {
  /// Crab appears normal and healthy
  normal,

  /// Crab shows signs of disease
  disease,

  /// Crab is under stress
  stress,

  /// Health status cannot be determined
  unknown,
}

/// Extension on HealthStatus for display helpers.
extension HealthStatusExtension on HealthStatus {
  /// Returns the human-readable display name.
  String get displayName {
    switch (this) {
      case HealthStatus.normal:
        return 'Bình thường';
      case HealthStatus.disease:
        return 'Cảnh báo';
      case HealthStatus.stress:
        return 'Cần theo dõi';
      case HealthStatus.unknown:
        return 'Cần theo dõi';
    }
  }

  /// Returns true if the health status requires immediate attention.
  bool get requiresAttention => this == HealthStatus.disease || this == HealthStatus.stress;
}
