import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/harvest.dart';
import '../repositories/harvest_repository.dart';

/// Parameters for [GetHarvestHistoryUseCase].
class GetHarvestHistoryParams {
  const GetHarvestHistoryParams({
    this.farmId,
    this.boxId,
    this.startDate,
    this.endDate,
    this.qualityGrade,
    this.page = 1,
    this.pageSize = 50,
  });

  final String? farmId;
  final String? boxId;
  final DateTime? startDate;
  final DateTime? endDate;
  final QualityGrade? qualityGrade;
  final int page;
  final int pageSize;
}

/// Use case for retrieving historical harvest records with optional filter parameters.
///
/// Supports filtering by farm, box, date range, and quality grade (Requirement 11.9).
/// Validates date range constraints and pagination settings.
///
/// Requirements: 11.9
class GetHarvestHistoryUseCase {
  const GetHarvestHistoryUseCase(this._repository);

  final HarvestRepository _repository;

  Future<Either<Failure, List<Harvest>>> call(GetHarvestHistoryParams params) async {
    // Validate pagination parameters
    if (params.page < 1) {
      return const Left(ValidationFailure('Page number must be at least 1.'));
    }

    if (params.pageSize < 1 || params.pageSize > 200) {
      return const Left(ValidationFailure('Page size must be between 1 and 200.'));
    }

    // Validate date range logic
    if (params.startDate != null &&
        params.endDate != null &&
        params.startDate!.isAfter(params.endDate!)) {
      return const Left(ValidationFailure('Start date cannot be after end date.'));
    }

    return _repository.getHarvestHistory(
      farmId: params.farmId,
      boxId: params.boxId,
      startDate: params.startDate,
      endDate: params.endDate,
      qualityGrade: params.qualityGrade,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
