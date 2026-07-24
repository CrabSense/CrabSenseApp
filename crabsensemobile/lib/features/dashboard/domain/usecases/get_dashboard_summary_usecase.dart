import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

/// Use case for loading the dashboard summary.
///
/// Encapsulates the business logic for fetching all dashboard data:
/// 1. Requests an aggregated [DashboardSummary] from [DashboardRepository]
/// 2. Returns cached data transparently when the device is offline
/// 3. Propagates any failure to the presentation layer for error-state display
///
/// The presentation layer should:
/// - Show skeleton loading screens while awaiting the result (Requirement 2.10)
/// - Display the result when Right([DashboardSummary]) is returned
/// - Show an error state with a retry button on Left([Failure]) (Requirement 2.9)
/// - Display an offline indicator when [DashboardSummary.isFromCache] is true
///   (Requirement 2.6)
/// - Re-invoke this use case every 60 seconds when online (Requirement 2.7)
///
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.6, 2.7, 2.8, 2.9, 2.10
class GetDashboardSummaryUseCase {
  const GetDashboardSummaryUseCase(this._repository);

  final DashboardRepository _repository;

  /// Executes the use case.
  ///
  /// [forceRefresh] — when true, implementations should bypass any in-memory
  /// cache and fetch fresh data from the API (e.g. for pull-to-refresh).
  /// When false, a short-lived in-memory or disk cache may be used.
  ///
  /// Returns:
  /// - Right([DashboardSummary]): Successfully loaded summary (may be cached)
  /// - Left([NetworkFailure]): Offline and no cached data available
  /// - Left([CacheFailure]): Cache read error while offline
  /// - Left([ServerFailure]): Remote API returned an error
  ///
  /// Requirements: 2.1, 2.6, 2.9
  Future<Either<Failure, DashboardSummary>> call({bool forceRefresh = false}) async {
    if (forceRefresh) {
      // Pull-to-refresh: go straight to the network call
      return _repository.getDashboardSummary();
    }

    // Normal load: attempt network, fall back to cache on NetworkFailure
    final result = await _repository.getDashboardSummary();

    return result.fold((failure) async {
      if (failure is NetworkFailure) {
        // Requirement 2.6: return cached data with offline indicator
        return _repository.getCachedDashboardSummary();
      }
      // For non-network failures bubble up as-is
      return Left(failure);
    }, (summary) async => Right(summary));
  }
}
