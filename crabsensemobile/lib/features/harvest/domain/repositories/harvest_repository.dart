import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/harvest.dart';
import '../entities/harvest_summary.dart';

/// Repository contract for harvest data operations following Clean Architecture.
///
/// Implementations live in the data layer and manage:
/// - Remote REST API calls
/// - Local caching / SQLite database (Drift)
/// - Offline queue for queued harvest submissions (Requirement 11.8)
/// - Error mapping to domain [Failure] instances
///
/// Requirements: 11.1-11.10
abstract class HarvestRepository {
  /// Submits a harvest record.
  ///
  /// Persisted locally and synchronized within 10 seconds when network is available
  /// (Requirement 11.7). Queued in offline storage when network is unavailable (Requirement 11.8).
  /// Updates box inventory by reducing crab count (Requirement 11.4).
  ///
  /// Returns:
  /// - `Right(Harvest)`: Harvest successfully recorded/queued
  /// - `Left(ValidationFailure)`: Harvest data failed validation rules
  /// - `Left(NetworkFailure)`: Network unavailable (queued offline)
  /// - `Left(ServerFailure)`: Server error
  ///
  /// Requirements: 11.3, 11.4, 11.5, 11.7, 11.8
  Future<Either<Failure, Harvest>> recordHarvest(Harvest harvest);

  /// Retrieves harvest history records with optional filters.
  ///
  /// Supports filtering by farm, box, date range, and quality grade (Requirement 11.9).
  /// Supports pagination via [page] and [pageSize].
  ///
  /// Returns:
  /// - `Right(List<Harvest>)`: List of matching harvest records
  /// - `Left(CacheFailure)`: Error loading cached harvest data
  /// - `Left(NetworkFailure)`: Network error when fetching remote data
  ///
  /// Requirements: 11.9
  Future<Either<Failure, List<Harvest>>> getHarvestHistory({
    String? farmId,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
    int page = 1,
    int pageSize = 50,
  });

  /// Calculates cumulative harvest metrics per farm for a given date range.
  ///
  /// Used for Weekly Farm Harvest Summary view (Requirement 11.10).
  ///
  /// Parameters:
  /// - [farmId]: Target farm identifier
  /// - [startDate]: Beginning of period (inclusive)
  /// - [endDate]: End of period (inclusive)
  ///
  /// Returns:
  /// - `Right(HarvestSummary)`: Aggregated harvest metrics
  /// - `Left(Failure)`: Error calculating or fetching summary
  ///
  /// Requirements: 11.10
  Future<Either<Failure, HarvestSummary>> getHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Retrieves a single harvest record by identifier.
  ///
  /// Returns:
  /// - `Right(Harvest)`: Matching harvest record
  /// - `Left(ServerFailure.notFound)`: Record does not exist
  Future<Either<Failure, Harvest>> getHarvestById(String id);
}
