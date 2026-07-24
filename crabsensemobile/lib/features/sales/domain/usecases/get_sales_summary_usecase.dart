import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sales_summary.dart';
import '../repositories/sales_repository.dart';

/// Parameters for [GetSalesSummaryUseCase].
class GetSalesSummaryParams {
  const GetSalesSummaryParams({
    required this.startDate,
    required this.endDate,
    this.farmId,
  });

  final String? farmId;
  final DateTime startDate;
  final DateTime endDate;
}

/// Use case for retrieving aggregated sales metrics (daily/weekly sales summary reports).
///
/// Requirement 12.10: Display daily and weekly sales summary reports.
class GetSalesSummaryUseCase {
  const GetSalesSummaryUseCase(this._repository);

  final SalesRepository _repository;

  Future<Either<Failure, SalesSummary>> call(GetSalesSummaryParams params) async {
    // Validate date range constraints
    if (params.startDate.isAfter(params.endDate)) {
      return const Left(ValidationFailure('Start date cannot be after end date.'));
    }

    return _repository.getSalesSummary(
      farmId: params.farmId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
