import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../authentication/domain/entities/user.dart';
import '../entities/harvest.dart';
import '../repositories/harvest_repository.dart';

/// Parameters for [RecordHarvestUseCase].
class RecordHarvestParams {
  const RecordHarvestParams({
    required this.harvest,
    this.userRole,
  });

  /// The harvest record to be created.
  final Harvest harvest;

  /// Role of the operator performing the action.
  /// Used for authorization validation (Requirement 19.3).
  final UserRole? userRole;
}

/// Use case for recording a new harvest in the CrabSense system.
///
/// Enforces business validation rules before passing data to [HarvestRepository]:
/// - User must have Field_Operator role or higher (Requirement 19.3)
/// - Box ID must be non-empty (Requirement 11.1)
/// - Farm ID must be non-empty
/// - Operator ID & operator name must be non-empty (Requirement 11.5)
/// - Total weight must be a positive number (> 0) (Requirement 11.3)
/// - Crab count must be positive (> 0) (Requirement 11.2)
/// - Harvest date must not be in the future (Requirement 11.2)
///
/// Requirements: 11.1-11.8, 19.3
class RecordHarvestUseCase {
  const RecordHarvestUseCase(this._repository);

  final HarvestRepository _repository;

  Future<Either<Failure, Harvest>> call(RecordHarvestParams params) async {
    final harvest = params.harvest;
    final role = params.userRole;

    // Validate authorization: Field_Operator role or higher required (Requirement 19.3)
    if (role != null && !role.canPerformFieldOperations) {
      return const Left(
        ValidationFailure(
          'Requires Field Operator role or higher to record harvests.',
          code: 'PERMISSION_DENIED',
        ),
      );
    }

    // Validate required identifiers
    if (harvest.boxId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Box selection'));
    }

    if (harvest.farmId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Farm selection'));
    }

    if (harvest.operatorId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator ID'));
    }

    if (harvest.operatorName.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator name'));
    }

    // Validate positive total weight (Requirement 11.3)
    if (harvest.totalWeight <= 0) {
      return const Left(
        ValidationFailure(
          'Total weight must be a positive number.',
          code: 'INVALID_WEIGHT',
        ),
      );
    }

    // Validate positive crab count (Requirement 11.2)
    if (harvest.crabCount <= 0) {
      return const Left(
        ValidationFailure(
          'Crab count must be at least 1.',
          code: 'INVALID_CRAB_COUNT',
        ),
      );
    }

    // Validate harvest date not in future (Requirement 11.2)
    if (harvest.harvestDate.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return const Left(
        ValidationFailure(
          'Harvest date cannot be in the future.',
          code: 'INVALID_DATE',
        ),
      );
    }

    return _repository.recordHarvest(harvest);
  }
}
