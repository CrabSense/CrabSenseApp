import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/water_quality.dart';
import '../repositories/water_quality_repository.dart';

/// Parameters for [GetCurrentReadingsUseCase].
class GetCurrentReadingsParams {
  const GetCurrentReadingsParams({required this.farmId, this.pondId});

  /// The farm to retrieve current readings for.
  final String farmId;

  /// Optional specific pond within the farm to filter readings.
  final String? pondId;
}

/// Use case for retrieving current water quality sensor readings.
///
/// Fetches the most recent readings for temperature, pH, dissolved oxygen,
/// and salinity from IoT sensors (Requirement 8.2). Returns cached data
/// when offline with staleness indicator (Requirement 8.10).
///
/// Data should be displayed within 3 seconds of screen load
/// (Requirement 8.1).
///
/// Following Clean Architecture, this use case represents a single
/// read operation and delegates to [WaterQualityRepository].
///
/// Requirements: 8.1, 8.2, 8.3, 8.8, 8.10
class GetCurrentReadingsUseCase {
  const GetCurrentReadingsUseCase(this._repository);

  final WaterQualityRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - `Right(List<WaterQuality>)`: Sensor readings (may be empty)
  /// - `Left(ValidationFailure)`: `params.farmId` is empty
  /// - `Left(NetworkFailure)`: No internet and no cached data available
  /// - `Left(CacheFailure)`: Error reading from local storage
  /// - `Left(ServerFailure)`: Server error or IoT device offline
  Future<Either<Failure, List<WaterQuality>>> call(GetCurrentReadingsParams params) async {
    // Validate farmId
    if (params.farmId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Farm ID'));
    }

    // Validate pondId if provided
    if (params.pondId != null && params.pondId!.trim().isEmpty) {
      return const Left(ValidationFailure.required('Pond ID'));
    }

    return _repository.getCurrentReadings(farmId: params.farmId, pondId: params.pondId);
  }
}
