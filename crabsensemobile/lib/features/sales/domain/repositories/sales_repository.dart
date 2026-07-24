import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sale.dart';
import '../entities/sales_summary.dart';

/// Repository contract for sales management data operations following Clean Architecture.
///
/// Implementations live in the data layer and manage:
/// - Remote REST API sales calls
/// - Local caching / SQLite database (Drift)
/// - Offline queue for queued sales submissions (Requirement 12.8)
/// - Error mapping to domain [Failure] instances
///
/// Requirements: 12.1-12.10
abstract class SalesRepository {
  /// Submits a sales transaction record.
  ///
  /// Persisted locally and synchronized within 10 seconds when network is available
  /// (Requirement 12.7). Queued in offline storage when network is unavailable (Requirement 12.8).
  ///
  /// Returns:
  /// - `Right(Sale)`: Sale successfully recorded/queued
  /// - `Left(ValidationFailure)`: Sale data failed validation rules (e.g., exceeds inventory)
  /// - `Left(NetworkFailure)`: Network unavailable (queued offline)
  /// - `Left(ServerFailure)`: Server error
  ///
  /// Requirements: 12.1-12.8
  Future<Either<Failure, Sale>> createSale(Sale sale);

  /// Retrieves sales transaction history records with optional filters.
  ///
  /// Supports filtering by farm, buyer name, date range, payment method, and status.
  /// Supports pagination via [page] and [pageSize].
  ///
  /// Returns:
  /// - `Right(List<Sale>)`: List of matching sales records
  /// - `Left(CacheFailure)`: Error loading cached sales data
  /// - `Left(NetworkFailure)`: Network error when fetching remote data
  ///
  /// Requirements: 12.10
  Future<Either<Failure, List<Sale>>> getSalesHistory({
    String? farmId,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int page = 1,
    int pageSize = 50,
  });

  /// Calculates aggregated sales summary metrics for daily or weekly reporting.
  ///
  /// Parameters:
  /// - [farmId]: Optional farm identifier filter
  /// - [startDate]: Beginning of period (inclusive)
  /// - [endDate]: End of period (inclusive)
  ///
  /// Returns:
  /// - `Right(SalesSummary)`: Aggregated sales metrics (revenue, total quantity, transaction count)
  /// - `Left(Failure)`: Error calculating or fetching sales summary
  ///
  /// Requirements: 12.10
  Future<Either<Failure, SalesSummary>> getSalesSummary({
    String? farmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Retrieves a single sales record by its transaction identifier.
  ///
  /// Returns:
  /// - `Right(Sale)`: Matching sale record
  /// - `Left(ServerFailure.notFound)`: Record does not exist
  Future<Either<Failure, Sale>> getSaleById(String id);

  /// Retrieves available harvested inventory in kilograms for validation.
  ///
  /// Used by [CreateSaleUseCase] to validate that the sale quantity does not exceed
  /// available harvested inventory (Requirement 12.4).
  ///
  /// Returns:
  /// - `Right(double)`: Total available harvested weight in kg
  /// - `Left(Failure)`: Error querying inventory
  ///
  /// Requirements: 12.4
  Future<Either<Failure, double>> getAvailableHarvestedInventory({String? farmId});
}
