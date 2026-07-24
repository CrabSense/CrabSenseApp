import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/water_quality.dart';
import '../repositories/water_quality_repository.dart';

/// Parameters for [GetHistoricalDataUseCase].
class GetHistoricalDataParams {
  const GetHistoricalDataParams({required this.farmId, required this.period, this.pondId});

  /// The farm to retrieve historical data for.
  final String farmId;

  /// Optional specific pond within the farm to filter readings.
  final String? pondId;

  /// Time period for historical data (24 hours, 7 days, or 30 days).
  final HistoricalPeriod period;
}

/// Use case for retrieving historical water quality data for charting.
///
/// Fetches time-series sensor readings for the specified period to display
/// trends in temperature, pH, dissolved oxygen, and salinity over time
/// (Requirement 8.5).
///
/// The UI should provide options for last 24 hours, 7 days, and 30 days
/// (Requirement 8.5).
///
/// Following Clean Architecture, this use case represents a single
/// read operation and delegates to [WaterQualityRepository].
///
/// Requirements: 8.5
class GetHistoricalDataUseCase {
  const GetHistoricalDataUseCase(this._repository);

  final WaterQualityRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - `Right(List<WaterQuality>)`: Historical readings by timestamp
  /// - `Left(ValidationFailure)`: `params.farmId` is empty
  /// - `Left(NetworkFailure)`: No internet and no cached data
  /// - `Left(ServerFailure)`: Server error
  Future<Either<Failure, List<WaterQuality>>> call(GetHistoricalDataParams params) async {
    // Validate farmId
    if (params.farmId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Farm ID'));
    }

    // Validate pondId if provided
    if (params.pondId != null && params.pondId!.trim().isEmpty) {
      return const Left(ValidationFailure.required('Pond ID'));
    }

    return _repository.getHistoricalData(
      farmId: params.farmId,
      pondId: params.pondId,
      period: params.period,
    );
  }
}
