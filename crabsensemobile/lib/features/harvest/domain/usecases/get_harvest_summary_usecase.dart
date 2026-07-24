import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/harvest_summary.dart';
import '../repositories/harvest_repository.dart';

/// Parameters for [GetHarvestSummaryUseCase].
class GetHarvestSummaryParams {
  const GetHarvestSummaryParams({
    required this.farmId,
    required this.startDate,
    required this.endDate,
  });

  /// Target farm identifier
  final String farmId;

  /// Start date of summary window
  final DateTime startDate;

  /// End date of summary window
  final DateTime endDate;
}

/// Use case for calculating cumulative harvest summary metrics per farm.
///
/// Computes total weight, crab count, and quality grade breakdowns for a given period
/// (Requirement 11.10).
///
/// Requirements: 11.10
class GetHarvestSummaryUseCase {
  const GetHarvestSummaryUseCase(this._repository);

  final HarvestRepository _repository;

  Future<Either<Failure, HarvestSummary>> call(GetHarvestSummaryParams params) async {
    if (params.farmId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Farm selection'));
    }

    if (params.startDate.isAfter(params.endDate)) {
      return const Left(ValidationFailure('Start date cannot be after end date.'));
    }

    return _repository.getHarvestSummary(
      farmId: params.farmId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
