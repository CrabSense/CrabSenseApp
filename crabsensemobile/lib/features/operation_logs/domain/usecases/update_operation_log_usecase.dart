import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../authentication/domain/entities/user.dart';
import '../entities/operation_log.dart';
import '../repositories/operation_repository.dart';

/// Parameters for [UpdateOperationLogUseCase].
class UpdateOperationLogParams {
  const UpdateOperationLogParams({required this.log, this.userRole});

  /// The operation log with updated fields.
  ///
  /// [log.id] must reference an existing record and must not be empty.
  /// The edit must be within 24 hours of [log.timestamp] (Requirement 10.9).
  final OperationLog log;

  /// Optional user role of the operator performing the edit.
  /// Enforces Field_Operator role or higher (Requirement 10.10).
  final UserRole? userRole;
}

/// Use case for updating an existing operation log.
///
/// Validates that:
/// - The operator has Field_Operator role or higher (Requirement 10.10)
/// - The log ID is not empty
/// - The log still falls within the 24-hour editable window (Requirement 10.9)
/// - All required fields remain valid after the update
///
/// Delegates to [OperationRepository] for persistence.
///
/// Requirements: 10.9, 10.10
class UpdateOperationLogUseCase {
  const UpdateOperationLogUseCase(this._repository);

  final OperationRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - `Right(OperationLog)`: Updated log
  /// - `Left(ValidationFailure)`: [log.id] is empty, the 24-hour editing
  ///   window has expired, required field validation failed, or permission denied
  /// - `Left(ServerFailure.notFound)`: Log does not exist
  /// - `Left(NetworkFailure)`: No internet connection
  Future<Either<Failure, OperationLog>> call(UpdateOperationLogParams params) async {
    final log = params.log;
    final role = params.userRole;

    // Validate: Field_Operator role or higher required (Requirement 10.10)
    if (role != null && !role.canPerformFieldOperations) {
      return const Left(
        ValidationFailure(
          'Requires Field Operator role or higher to edit operation logs.',
          code: 'PERMISSION_DENIED',
        ),
      );
    }

    // Validate: ID must not be empty
    if (log.id.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operation log ID'));
    }

    // Validate: must be within the 24-hour editing window (Requirement 10.9)
    if (!log.isEditable) {
      return const Left(
        ValidationFailure('Operation logs can only be edited within 24 hours of creation.'),
      );
    }

    // Validate: at least one box must remain selected (Requirement 10.4)
    if (log.boxIds.isEmpty) {
      return const Left(ValidationFailure('At least one box must be selected.'));
    }

    // Validate: all box IDs must be non-empty strings
    if (log.boxIds.any((id) => id.trim().isEmpty)) {
      return const Left(ValidationFailure('Invalid box ID in selection.'));
    }

    // Validate: operatorId must be present
    if (log.operatorId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator ID'));
    }

    // Validate: timestamp must not be in the future
    if (log.timestamp.isAfter(DateTime.now())) {
      return const Left(ValidationFailure('Operation timestamp cannot be in the future.'));
    }

    return _repository.updateOperationLog(log);
  }
}

