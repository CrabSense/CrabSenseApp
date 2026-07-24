/// Enums for the Operation Logs domain layer.
///
/// Defines the types of farm operations that can be logged by operators
/// in the CrabSense system.
library;

/// The type of farm operation performed on one or more boxes.
///
/// Requirements: 10.2
enum OperationType {
  /// Feeding the crabs (e.g., distributing feed pellets)
  feeding,

  /// Changing the water in a box or pond area
  waterChange,

  /// Adding minerals or supplements to the water
  mineralAddition,

  /// Cleaning a box, equipment, or farm area
  cleaning,

  /// Administering medication to crabs
  medication,

  /// Performing a manual visual inspection of the crabs
  inspection,
}

/// Extension on OperationType for display helpers.
extension OperationTypeExtension on OperationType {
  /// Returns the human-readable display name for the operation type.
  String get displayName {
    switch (this) {
      case OperationType.feeding:
        return 'Feeding';
      case OperationType.waterChange:
        return 'Water Change';
      case OperationType.mineralAddition:
        return 'Mineral Addition';
      case OperationType.cleaning:
        return 'Cleaning';
      case OperationType.medication:
        return 'Medication';
      case OperationType.inspection:
        return 'Inspection';
    }
  }

  /// Returns the icon name associated with this operation type.
  String get iconName {
    switch (this) {
      case OperationType.feeding:
        return 'restaurant';
      case OperationType.waterChange:
        return 'water';
      case OperationType.mineralAddition:
        return 'science';
      case OperationType.cleaning:
        return 'cleaning_services';
      case OperationType.medication:
        return 'medication';
      case OperationType.inspection:
        return 'search';
    }
  }

  /// Returns true if this operation type typically involves a quantity.
  bool get hasQuantity {
    switch (this) {
      case OperationType.feeding:
      case OperationType.waterChange:
      case OperationType.mineralAddition:
      case OperationType.medication:
        return true;
      case OperationType.cleaning:
      case OperationType.inspection:
        return false;
    }
  }
}
