/// Enums for the Alert domain layer.
///
/// Defines alert type, severity, and status classifications used
/// throughout the alert management feature.
library;

/// Category of an alert indicating its source or subject area.
///
/// Requirements: 9.3, 9.5
enum AlertType {
  /// Alert related to water quality parameters (e.g., pH out of range)
  waterQuality,

  /// Alert related to equipment failure or maintenance
  equipment,

  /// Alert related to crab health detection results
  crabHealth,

  /// Alert related to scheduled or overdue maintenance tasks
  maintenance,

  /// Alert related to task reminders or schedule items
  task,

  /// System-generated alert (e.g., sync failure, app update)
  system,
}

/// Extension on AlertType for display helpers.
extension AlertTypeExtension on AlertType {
  /// Returns the human-readable display name for the alert type.
  String get displayName {
    switch (this) {
      case AlertType.waterQuality:
        return 'Water Quality';
      case AlertType.equipment:
        return 'Equipment';
      case AlertType.crabHealth:
        return 'Crab Health';
      case AlertType.maintenance:
        return 'Maintenance';
      case AlertType.task:
        return 'Task';
      case AlertType.system:
        return 'System';
    }
  }

  /// Returns the icon name associated with this alert type.
  String get iconName {
    switch (this) {
      case AlertType.waterQuality:
        return 'water_drop';
      case AlertType.equipment:
        return 'build';
      case AlertType.crabHealth:
        return 'pets';
      case AlertType.maintenance:
        return 'handyman';
      case AlertType.task:
        return 'assignment';
      case AlertType.system:
        return 'settings';
    }
  }
}

/// Severity level of an alert indicating urgency.
///
/// Requirements: 9.3, 9.5
enum AlertSeverity {
  /// Critical alert requiring immediate attention
  /// (e.g., water quality emergency, equipment failure)
  critical,

  /// Warning alert for conditions approaching threshold
  /// (e.g., parameter nearing limit, maintenance due)
  warning,

  /// Informational alert for routine updates
  /// (e.g., task reminder, system update)
  info,
}

/// Extension on AlertSeverity for display helpers.
extension AlertSeverityExtension on AlertSeverity {
  /// Returns the human-readable display name for the severity.
  String get displayName {
    switch (this) {
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.info:
        return 'Info';
    }
  }

  /// Returns true if this severity requires immediate user action.
  bool get requiresImmediateAction => this == AlertSeverity.critical;
}

/// Processing status of an alert in the user's workflow.
///
/// Requirements: 9.6, 9.7
enum AlertStatus {
  /// Alert has not been seen by the user
  unread,

  /// Alert has been opened/viewed but not acted upon
  read,

  /// Alert has been explicitly acknowledged by the user
  acknowledged,

  /// Alert has been dismissed and will not require further action
  dismissed,
}

/// Extension on AlertStatus for display helpers.
extension AlertStatusExtension on AlertStatus {
  /// Returns the human-readable display name for the status.
  String get displayName {
    switch (this) {
      case AlertStatus.unread:
        return 'Unread';
      case AlertStatus.read:
        return 'Read';
      case AlertStatus.acknowledged:
        return 'Acknowledged';
      case AlertStatus.dismissed:
        return 'Dismissed';
    }
  }

  /// Returns true if the alert is still active (not dismissed).
  bool get isActive => this != AlertStatus.dismissed;

  /// Returns true if the alert has not been read.
  bool get isUnread => this == AlertStatus.unread;
}
