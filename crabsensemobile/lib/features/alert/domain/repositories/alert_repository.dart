import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/alert.dart';
import '../entities/alert_enums.dart';

/// Filter parameters for querying alerts.
///
/// All filter fields are optional. When omitted, no filtering is applied
/// for that dimension.
class AlertFilters {
  const AlertFilters({this.severity, this.type, this.status});

  /// Filter by severity level (null = all severities)
  final AlertSeverity? severity;

  /// Filter by alert type category (null = all types)
  final AlertType? type;

  /// Filter by processing status (null = all statuses)
  final AlertStatus? status;

  /// Returns true if no filters are applied.
  bool get isEmpty => severity == null && type == null && status == null;
}

/// Repository interface for alert management operations.
///
/// This interface defines the contract for alert data operations following
/// Clean Architecture principles. The domain layer depends on this
/// abstraction; concrete implementations live in the data layer.
///
/// Implementations should handle:
/// - Remote data via REST API
/// - Local cache via SQLite (drift) with 30-day history retention
/// - Offline-first: serve cached data when offline (Requirement 9.10)
/// - Offline queue for acknowledgements / dismissals (Requirement 9.10)
/// - Error mapping to domain Failures
///
/// All methods return `Either<Failure, T>` for functional error handling:
/// - Left(Failure): operation failed with a specific failure reason
/// - Right(T): operation succeeded with the result data
///
/// Requirements: 9.1-9.10
abstract class AlertRepository {
  /// Retrieves alerts, optionally filtered by severity, type, and status.
  ///
  /// Results are sorted by [Alert.createdAt] descending (newest first)
  /// as required by Requirement 9.4.
  ///
  /// History is limited to the last 30 days (Requirement 9.9).
  /// Returns cached data when offline (Requirement 9.10).
  ///
  /// Parameters:
  /// - [filters]: Optional filters for severity, type, and status
  ///
  /// Returns:
  /// - `Right(List<Alert>)`: Alerts matching the filters (may be empty)
  /// - `Left(NetworkFailure)`: No internet and no cached data
  /// - `Left(CacheFailure)`: Error reading from local storage
  /// - `Left(ServerFailure)`: Server error
  ///
  /// Requirements: 9.4, 9.8, 9.9, 9.10
  Future<Either<Failure, List<Alert>>> getAlerts({AlertFilters? filters});

  /// Retrieves a single alert by its unique identifier.
  ///
  /// Returns:
  /// - `Right(Alert)`: Alert with the given [alertId]
  /// - `Left(ServerFailure.notFound)`: Alert not found
  /// - `Left(NetworkFailure)`: No internet and no cached data
  /// - `Left(CacheFailure)`: Error reading from local storage
  ///
  /// Requirements: 9.5
  Future<Either<Failure, Alert>> getAlertById(String alertId);

  /// Acknowledges an alert, marking it as reviewed and acted upon.
  ///
  /// Sets [Alert.status] to [AlertStatus.acknowledged],
  /// [Alert.acknowledgedAt] to the current timestamp, and
  /// [Alert.acknowledgedBy] to [acknowledgedBy].
  ///
  /// Status must be updated within 2 seconds when online (Requirement 9.7).
  /// When offline, queues the acknowledgement for synchronisation
  /// (Requirement 9.10).
  ///
  /// Parameters:
  /// - [alertId]: Unique identifier of the alert to acknowledge
  /// - [acknowledgedBy]: Identifier of the user acknowledging the alert
  ///
  /// Returns:
  /// - `Right(Alert)`: Updated alert with acknowledged status
  /// - `Left(ValidationFailure)`: Alert is already dismissed
  /// - `Left(ServerFailure.notFound)`: Alert not found
  /// - `Left(NetworkFailure)`: No internet (queued for sync)
  ///
  /// Requirements: 9.6, 9.7, 9.10
  Future<Either<Failure, Alert>> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
  });

  /// Dismisses an alert, removing it from the active alert list.
  ///
  /// Sets [Alert.status] to [AlertStatus.dismissed].
  ///
  /// When offline, queues the dismissal for synchronisation
  /// (Requirement 9.10).
  ///
  /// Parameters:
  /// - [alertId]: Unique identifier of the alert to dismiss
  ///
  /// Returns:
  /// - `Right(Alert)`: Updated alert with dismissed status
  /// - `Left(ValidationFailure)`: Alert is already dismissed
  /// - `Left(ServerFailure.notFound)`: Alert not found
  /// - `Left(NetworkFailure)`: No internet (queued for sync)
  ///
  /// Requirements: 9.6, 9.10
  Future<Either<Failure, Alert>> dismissAlert(String alertId);

  /// Returns the count of unread alerts.
  ///
  /// Used to display the unread badge on the navigation tab
  /// (Requirement 9.2). Returns cached count when offline.
  ///
  /// Returns:
  /// - `Right(int)`: Count of alerts with [AlertStatus.unread]
  /// - `Left(CacheFailure)`: Error reading from local storage
  ///
  /// Requirements: 9.2
  Future<Either<Failure, int>> getUnreadCount();

  /// Returns a stream that emits the unread alert count as it changes.
  ///
  /// Enables the navigation badge to update in real time. Emits from
  /// the local cache immediately, then from the network as data arrives.
  ///
  /// Requirements: 9.2
  Stream<int> watchUnreadCount();
}
