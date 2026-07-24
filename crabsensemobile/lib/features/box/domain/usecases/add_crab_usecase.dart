import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/crab.dart';
import '../repositories/box_repository.dart';

/// Parameters for [AddCrabUseCase].
class AddCrabParams {
  const AddCrabParams({required this.boxId, required this.crab});

  /// The identifier of the box to add the crab to.
  final String boxId;

  /// The crab record to be persisted.
  ///
  /// The [Crab.weight] must be a positive decimal number (Requirement 16.2).
  /// The [Crab.addedBy] must not be empty (Requirement 16.6).
  final Crab crab;
}

/// Use case for adding a new crab record to a box.
///
/// Business rules enforced by this use case:
/// 1. Weight must be a positive decimal number (Requirement 16.2)
/// 2. Source must not be empty (validated via [CrabSource])
/// 3. The box crab count is incremented after successful addition
///    (Requirement 16.3) — this is handled by the repository implementation
/// 4. The crab record is associated with the caller's identity and a timestamp
///    (Requirement 16.6)
/// 5. When offline, the record is stored locally and synced within 10 seconds
///    when network is restored (Requirements 16.8, 16.9)
/// 6. Only Field Operator role or higher may add crabs (Requirement 16.10) —
///    enforced at the presentation / authorization layer
///
/// Requirements: 16.1-16.9
class AddCrabUseCase {
  const AddCrabUseCase(this._repository);

  final BoxRepository _repository;

  /// Executes the use case to add a crab to a box.
  ///
  /// Returns:
  /// - Right(Crab): Newly created crab record (with server-assigned ID)
  /// - Left(ValidationFailure): Input validation failed
  /// - Left(ServerFailure.notFound): Box with [params.boxId] does not exist
  /// - Left(NetworkFailure): No internet (record queued for sync)
  Future<Either<Failure, Crab>> call(AddCrabParams params) async {
    // Validate boxId
    if (params.boxId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Box ID'));
    }

    // Validate weight is a positive decimal number (Requirement 16.2)
    if (params.crab.weight <= 0) {
      return const Left(
        ValidationFailure('Crab weight must be a positive number.', code: 'INVALID_CRAB_WEIGHT'),
      );
    }

    // Validate addedBy is not empty (Requirement 16.6)
    if (params.crab.addedBy.trim().isEmpty) {
      return const Left(ValidationFailure.required('Added By'));
    }

    return _repository.addCrab(params.boxId, params.crab);
  }
}
