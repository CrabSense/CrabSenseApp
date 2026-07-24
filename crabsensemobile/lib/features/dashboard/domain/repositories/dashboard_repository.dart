import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_summary.dart';

/// Repository interface for dashboard data operations.
///
/// Defines the contract for fetching aggregated dashboard data following
/// Clean Architecture principles. The domain layer depends on this
/// abstraction — concrete implementations live in the data layer.
///
/// Implementations are responsible for:
/// - Fetching alerts, video tasks, water quality, and harvest data in parallel
/// - Returning cached data with [DashboardSummary.isFromCache] set to true
///   when the network is unavailable (Requirement 2.6)
/// - Persisting fetched data locally so offline reads are possible
/// - Mapping all data-layer errors to appropriate [Failure] subclasses
///
/// All methods follow the Either<Failure, T> convention:
/// - Left(Failure): operation failed with a specific reason
/// - Right(T): operation succeeded with the result data
abstract class DashboardRepository {
  /// Fetches an aggregated [DashboardSummary] for the current user.
  ///
  /// The implementation SHOULD:
  /// 1. Attempt to fetch fresh data from the remote API
  ///    (parallel requests: alerts, video schedule, water quality, harvests)
  /// 2. Cache the result locally on success
  /// 3. When offline, return cached data with [DashboardSummary.isFromCache]
  ///    set to `true` (Requirement 2.6)
  ///
  /// Returns:
  /// - Right([DashboardSummary]): Successfully loaded summary
  /// - Left([NetworkFailure]): No network; no cached data available either
  /// - Left([CacheFailure]): Offline and cache read failed
  /// - Left([ServerFailure]): Remote API returned an error
  ///
  /// Requirements: 2.1, 2.2, 2.3, 2.4, 2.6, 2.8
  Future<Either<Failure, DashboardSummary>> getDashboardSummary();

  /// Fetches the cached [DashboardSummary] from local storage without
  /// making any network requests.
  ///
  /// Useful for:
  /// - Initial render before network data arrives
  /// - Offline mode (Requirement 2.6)
  ///
  /// Returns:
  /// - Right([DashboardSummary]): Cached summary (isFromCache == true)
  /// - Left([CacheFailure]): No cached data exists or read failed
  ///
  /// Requirements: 2.6, 2.10
  Future<Either<Failure, DashboardSummary>> getCachedDashboardSummary();
}
