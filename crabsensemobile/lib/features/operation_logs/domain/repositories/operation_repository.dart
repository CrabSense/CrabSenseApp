import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/operation_log.dart';
import '../entities/operation_type.dart';

/// Repository interface for operation log management.
///
/// This interface defines the contract for operation log data operations
/// following Clean Architecture principles. The domain layer depends on
/// this abstraction; concrete implementations live in the data layer.
///
/// Implementations should handle:
/// - Remote data via REST API
/// - Local cache via SQLite (drift) for offline-first support
/// - Offline queue: logs created/edited offline are queued and synced
///   within 10 seconds when network is available (Requirement 10.6)
/// - Error mapping to domain [Failure] types
///
/// All methods return `Either<Failure, T>` for functional error handling:
/// - `Left(Failure)`: operation failed with a specific failure reason
/// - `Right(T)`: operation succeeded with the result data
///
/// Requirements: 10.1-10.10
abstract class OperationRepository {
  /// Creates a new operation log record.
  ///
  /// The log is persisted locally and synced within 10 seconds when the
  /// network is available (Requirement 10.6). When offline, it is stored
  /// in the local queue (Requirement 10.7).
  ///
  /// Parameters:
  /// - [log]: The operation log to create. [log.id] may be a temporary
  ///   client-side ID; the server will assign a permanent ID.
  ///
  /// Returns:
  /// - `Right(OperationLog)`: Created log with server-assigned ID
  /// - `Left(ValidationFailure)`: Log data failed validation
  /// - `Left(NetworkFailure)`: No internet (log queued for sync)
  /// - `Left(ServerFailure)`: Server error
  ///
  /// Requirements: 10.1, 10.3, 10.6, 10.7, 10.10
  Future<Either<Failure, OperationLog>> createOperationLog(OperationLog log);

  /// Retrieves the operation history for a specific box with optional filters.
  ///
  /// Results are sorted by [OperationLog.timestamp] descending (newest first).
  /// Supports pagination via [page] and [pageSize] (Requirement 10.8).
  ///
  /// Returns cached data when offline (Requirement 10.7).
  ///
  /// Parameters:
  /// - [boxId]: The box whose operation history to retrieve
  /// - [startDate]: Optional lower bound on [OperationLog.timestamp]
  /// - [endDate]: Optional upper bound on [OperationLog.timestamp]
  /// - [type]: Optional filter to retrieve only one operation type
  /// - [page]: 1-based page number (defaults to 1)
  /// - [pageSize]: Number of items per page (defaults to 50)
  ///
  /// Returns:
  /// - `Right(List<OperationLog>)`: Matching logs (may be empty)
  /// - `Left(NetworkFailure)`: No internet and no cached data
  /// - `Left(CacheFailure)`: Error reading from local storage
  /// - `Left(ServerFailure)`: Server error
  ///
  /// Requirements: 10.4, 10.7, 10.8
  Future<Either<Failure, List<OperationLog>>> getOperationHistory({
    required String boxId,
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
    int page = 1,
    int pageSize = 50,
  });

  /// Retrieves all operation logs across every box, sorted by
  /// [OperationLog.timestamp] descending (newest first).
  ///
  /// Online: fetches from `GET /operations`, refreshes the local cache,
  /// then serves from cache so logs still pending sync are included.
  /// Offline: serves directly from the local cache.
  /// Supports pagination via [page] and [pageSize].
  ///
  /// Returns:
  /// - `Right(List<OperationLog>)`: Matching logs (may be empty)
  /// - `Left(CacheFailure)`: Error reading from local storage
  Future<Either<Failure, List<OperationLog>>> getAllOperationLogs({
    int page = 1,
    int pageSize = 50,
  });

  /// Updates an existing operation log.
  ///
  /// Editing is only permitted within 24 hours of the log's [timestamp]
  /// (Requirement 10.9). The repository implementation must enforce this
  /// rule and return a [ValidationFailure] when the window has passed.
  ///
  /// Parameters:
  /// - [log]: The operation log with updated fields. [log.id] must
  ///   reference an existing record.
  ///
  /// Returns:
  /// - `Right(OperationLog)`: Updated log
  /// - `Left(ValidationFailure)`: Editing window (24 h) has expired, or
  ///   log data failed validation
  /// - `Left(ServerFailure.notFound)`: Log with [log.id] does not exist
  /// - `Left(NetworkFailure)`: No internet connection
  ///
  /// Requirements: 10.9
  Future<Either<Failure, OperationLog>> updateOperationLog(OperationLog log);

  /// Retrieves a single operation log by its unique identifier.
  ///
  /// Returns:
  /// - `Right(OperationLog)`: Log with the given [id]
  /// - `Left(ServerFailure.notFound)`: Log does not exist
  /// - `Left(NetworkFailure)`: No internet and no cached data
  /// - `Left(CacheFailure)`: Error reading from local storage
  ///
  /// Requirements: 10.8
  Future<Either<Failure, OperationLog>> getOperationById(String id);
}
