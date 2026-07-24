import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inspection.dart';
import '../repositories/inspection_repository.dart';

/// Use case for submitting a manual crab inspection.
///
/// Enforces business rules before delegating persistence to the repository:
///
/// 1. Required text fields must not be blank (Requirement 7.4).
/// 2. Weight must be a positive number (Requirement 7.4).
/// 3. The caller must supply a non-empty [operatorId] — role enforcement
///    (Field Operator or higher) is performed at the authorisation layer
///    (Requirement 7.9).
/// 4. On success the repository stores the record locally and queues it
///    for server sync; the returned [Inspection] reflects the current
///    [SyncStatus] (Requirement 7.7).
///
/// Requirements: 7.1-7.10
class SubmitInspectionUseCase {
  /// Creates the use case with the given [InspectionRepository].
  const SubmitInspectionUseCase(this._repository);

  final InspectionRepository _repository;

  /// Validates [inspection] and, if valid, persists it via the repository.
  ///
  /// Returns:
  /// - `Right(Inspection)` — record submitted (may have [SyncStatus.pending]
  ///   when offline)
  /// - `Left(ValidationFailure)` — one or more fields failed validation
  /// - `Left(CacheFailure)` — local storage write failed
  Future<Either<Failure, Inspection>> call(Inspection inspection) async {
    // --- Validate required identifiers ---

    if (inspection.id.trim().isEmpty) {
      return const Left(ValidationFailure.required('Inspection ID'));
    }

    if (inspection.boxId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Box ID'));
    }

    // --- Validate operator (Requirement 7.9) ---

    if (inspection.operatorId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator ID'));
    }

    if (inspection.operatorName.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator name'));
    }

    // --- Validate weight (Requirement 7.4) ---

    if (inspection.weight <= 0) {
      return const Left(
        ValidationFailure('Weight must be a positive number.', code: 'INVALID_WEIGHT'),
      );
    }

    // --- Delegate to repository ---

    return _repository.submitInspection(inspection);
  }
}
