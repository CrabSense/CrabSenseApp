import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../authentication/domain/entities/user.dart';
import '../entities/operation_log.dart';
import '../repositories/operation_repository.dart';

/// Parameters for [CreateOperationLogUseCase].
class CreateOperationLogParams {
  const CreateOperationLogParams({required this.log, this.userRole});

  /// The operation log to create.
  ///
  /// The following fields are required and validated before submission:
  /// - [OperationLog.boxIds]: must not be empty (Requirement 10.4)
  /// - [OperationLog.type]: must be provided (Requirement 10.2)
  /// - [OperationLog.timestamp]: must not be in the future (Requirement 10.3)
  /// - [OperationLog.operatorId]: must not be empty (Requirement 10.10)
  final OperationLog log;

  /// Optional user role of the operator performing the creation.
  /// Enforces Field_Operator role or higher (Requirement 10.10).
  final UserRole? userRole;
}

/// Use case for creating a new operation log record.
///
/// Validates required fields before delegating to [OperationRepository].
/// Operator must have Field_Operator role or higher (Requirement 10.10).
/// Created logs are synced within 10 seconds when online, or queued
/// locally when offline (Requirements 10.6-10.7).
///
/// Requirements: 10.1-10.7, 10.10
class CreateOperationLogUseCase {
  const CreateOperationLogUseCase(this._repository);

  final OperationRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - `Right(OperationLog)`: Created log with server-assigned ID
  /// - `Left(ValidationFailure)`: Required field validation failed or permission denied
  /// - `Left(NetworkFailure)`: No internet (log queued for sync)
  /// - `Left(ServerFailure)`: Server error
  Future<Either<Failure, OperationLog>> call(CreateOperationLogParams params) async {
    final log = params.log;
    final role = params.userRole;

    // Validate: Field_Operator role or higher required (Requirement 10.10)
    if (role != null && !role.canPerformFieldOperations) {
      return const Left(
        ValidationFailure(
          'Requires Field Operator role or higher to create operation logs.',
          code: 'PERMISSION_DENIED',
        ),
      );
    }

    // Validate: at least one box must be selected (Requirement 10.4)
    if (log.boxIds.isEmpty) {
      return const Left(ValidationFailure('At least one box must be selected.'));
    }

    // Validate: all box IDs must be non-empty strings
    if (log.boxIds.any((id) => id.trim().isEmpty)) {
      return const Left(ValidationFailure('Invalid box ID in selection.'));
    }

    // Validate: operatorId must be provided (Requirement 10.10)
    if (log.operatorId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator ID'));
    }

    // Validate: operatorName must be provided
    if (log.operatorName.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator name'));
    }

    // Validate: timestamp must not be in the future (Requirement 10.3)
    if (log.timestamp.isAfter(DateTime.now())) {
      return const Left(ValidationFailure('Operation timestamp cannot be in the future.'));
    }

    return _repository.createOperationLog(log);
  }
}

