import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/alert.dart';
import '../repositories/alert_repository.dart';

/// Parameters for [DismissAlertUseCase].
class DismissAlertParams {
  const DismissAlertParams({required this.alertId});

  /// The unique identifier of the alert to dismiss.
  final String alertId;
}

/// Use case for dismissing an alert.
///
/// Marks an alert as dismissed, removing it from the active alert list.
/// When offline, the action is queued for synchronisation (Requirement 9.10).
///
/// Business rules enforced by this use case:
/// 1. [DismissAlertParams.alertId] must not be empty
///
/// Following Clean Architecture, this use case represents a single
/// write operation and delegates to [AlertRepository].
///
/// Requirements: 9.6, 9.10
class DismissAlertUseCase {
  const DismissAlertUseCase(this._repository);

  final AlertRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - `Right(Alert)`: Updated alert with dismissed status
  /// - `Left(ValidationFailure)`: alertId is empty, or alert is already
  ///   dismissed
  /// - `Left(ServerFailure.notFound)`: Alert not found
  /// - `Left(NetworkFailure)`: No internet (queued for sync)
  Future<Either<Failure, Alert>> call(DismissAlertParams params) async {
    if (params.alertId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Alert ID'));
    }

    return _repository.dismissAlert(params.alertId);
  }
}
