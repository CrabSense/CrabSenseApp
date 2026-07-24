import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/alert.dart';
import '../entities/alert_enums.dart';
import '../repositories/alert_repository.dart';

/// Parameters for [GetAlertsUseCase].
class GetAlertsParams {
  const GetAlertsParams({this.severity, this.type, this.status});

  /// Optional filter to retrieve alerts of a specific severity only.
  final AlertSeverity? severity;

  /// Optional filter to retrieve alerts of a specific type only.
  final AlertType? type;

  /// Optional filter to retrieve alerts of a specific status only.
  final AlertStatus? status;

  /// Builds an [AlertFilters] instance from these params.
  AlertFilters toFilters() =>
      AlertFilters(severity: severity, type: type, status: status);
}

/// Use case for retrieving alerts, with optional filtering.
///
/// Returns alerts sorted by timestamp descending (newest first),
/// limited to the last 30 days (Requirement 9.9). Supports filtering
/// by severity, type, and status (Requirement 9.8).
///
/// Returns cached data when offline (Requirement 9.10).
///
/// Following Clean Architecture, this use case represents a single
/// read operation and delegates to [AlertRepository].
///
/// Requirements: 9.4, 9.8, 9.9, 9.10
class GetAlertsUseCase {
  const GetAlertsUseCase(this._repository);

  final AlertRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - `Right(List<Alert>)`: Alerts matching the filters (may be empty)
  /// - `Left(NetworkFailure)`: No internet and no cached data
  /// - `Left(CacheFailure)`: Error reading from local storage
  /// - `Left(ServerFailure)`: Server error
  Future<Either<Failure, List<Alert>>> call(GetAlertsParams params) async {
    final filters = params.toFilters();
    return _repository.getAlerts(filters: filters.isEmpty ? null : filters);
  }
}
