import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/alert.dart';
import '../repositories/alert_repository.dart';

/// Parameters for [AcknowledgeAlertUseCase].
class AcknowledgeAlertParams {
  const AcknowledgeAlertParams({
    required this.alertId,
    required this.acknowledgedBy,
  });

  /// The unique identifier of the alert to acknowledge.
  final String alertId;

  /// The identifier of the user performing the acknowledgement.
  final String acknowledgedBy;
}

/// Use case for acknowledging an alert.
///
/// Marks an alert as acknowledged, recording the user and timestamp.
/// Status must update within 2 seconds when online (Requirement 9.7).
/// When offline, the action is queued for synchronisation (Requirement 9.10).
///
/// Business rules enforced by this use case:
/// 1. [AcknowledgeAlertParams.alertId] must not be empty
/// 2. [AcknowledgeAlertParams.acknowledgedBy] must not be empty
///
/// Following Clean Architecture, this use case represents a single
/// write operation and delegates to [AlertRepository].
///
/// Requirements: 9.6, 9.7, 9.10
class AcknowledgeAlertUseCase {
  const AcknowledgeAlertUseCase(this._repository);

  final AlertRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - `Right(Alert)`: Updated alert with acknowledged status
  /// - `Left(ValidationFailure)`: alertId or acknowledgedBy is empty,
  ///   or alert is already dismissed
  /// - `Left(ServerFailure.notFound)`: Alert not found
  /// - `Left(NetworkFailure)`: No internet (queued for sync)
  Future<Either<Failure, Alert>> call(AcknowledgeAlertParams params) async {
    if (params.alertId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Alert ID'));
    }

    if (params.acknowledgedBy.trim().isEmpty) {
      return const Left(ValidationFailure.required('Acknowledged By'));
    }

    return _repository.acknowledgeAlert(
      alertId: params.alertId,
      acknowledgedBy: params.acknowledgedBy,
    );
  }
}
