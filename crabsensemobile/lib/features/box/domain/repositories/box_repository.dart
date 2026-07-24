import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/box.dart';
import '../entities/crab.dart';

/// Repository interface for box and crab management operations.
///
/// This interface defines the contract for box data operations following
/// Clean Architecture principles. The domain layer depends on this
/// abstraction; concrete implementations live in the data layer.
///
/// Implementations should handle:
/// - Remote data via REST API
/// - Local cache via SQLite (drift)
/// - Offline-first: serve cached data when offline (Requirement 4.7)
/// - Error mapping to domain Failures
///
/// All methods return `Either<Failure, T>` for functional error handling:
/// - Left(Failure): operation failed with a specific failure reason
/// - Right(T): operation succeeded with the result data
///
/// Requirements: 4.1-4.10, 16.1-16.10
abstract class BoxRepository {
  /// Retrieves the details of a single box by its unique ID.
  ///
  /// Returns the cached box when offline (Requirement 4.7).
  ///
  /// Returns:
  /// - Right(Box): Box found and returned
  /// - Left(ServerFailure.notFound): Box with [boxId] does not exist
  /// - Left(NetworkFailure): No internet and no cached data available
  /// - Left(CacheFailure): Error reading from local storage
  ///
  /// Requirements: 4.1, 4.2, 4.7, 4.10
  Future<Either<Failure, Box>> getBoxDetails(String boxId);

  /// Retrieves a box by its QR code string.
  ///
  /// Used after a QR scan to look up the associated box.
  ///
  /// Returns:
  /// - Right(Box): Box found by QR code
  /// - Left(ServerFailure.notFound): No box matches [qrCode]
  /// - Left(NetworkFailure): No internet connection
  /// - Left(ServerFailure): Server error
  ///
  /// Requirements: 4.1
  Future<Either<Failure, Box>> getBoxByQrCode(String qrCode);

  /// Retrieves all boxes belonging to a farm.
  ///
  /// Returns:
  /// - Right(List<Box>): All boxes for the farm (may be empty)
  /// - Left(NetworkFailure): No internet and no cached data
  /// - Left(ServerFailure): Server error
  ///
  /// Requirements: 4.1, 4.9
  Future<Either<Failure, List<Box>>> getBoxesByFarm(String farmId);

  /// Adds a new crab record to a box and increments the box crab count.
  ///
  /// This operation must:
  /// - Persist the crab record with [crab.addedAt] and [crab.addedBy]
  /// - Increment the [boxId] box's [Box.currentCrabCount]
  /// - Queue locally when offline and sync within 10 seconds when online
  ///   (Requirements 16.8, 16.9)
  ///
  /// Returns:
  /// - Right(Crab): Newly created crab record with server-assigned ID
  /// - Left(ValidationFailure): Crab data failed validation
  /// - Left(ServerFailure.notFound): Box with [boxId] does not exist
  /// - Left(NetworkFailure): No internet (crab queued for sync)
  ///
  /// Requirements: 16.1, 16.2, 16.3, 16.6, 16.8, 16.9
  Future<Either<Failure, Crab>> addCrab(String boxId, Crab crab);

  /// Transfers a crab from one box to another atomically.
  ///
  /// The transfer must:
  /// - Decrement [sourceBoxId] crab count
  /// - Increment [destinationBoxId] crab count
  /// - Update the crab record's [Crab.boxId]
  /// - Both decrements and increments must succeed or both must be rolled back
  ///   (Requirement 16.5)
  ///
  /// Returns:
  /// - Right(void): Transfer completed successfully
  /// - Left(ValidationFailure): Source and destination are the same box
  /// - Left(ServerFailure.notFound): Crab or boxes not found
  /// - Left(NetworkFailure): No internet connection
  ///
  /// Requirements: 16.4, 16.5
  Future<Either<Failure, void>> transferCrab(
    String crabId,
    String sourceBoxId,
    String destinationBoxId,
  );

  /// Updates an existing box record.
  ///
  /// Returns:
  /// - Right(Box): Updated box
  /// - Left(ValidationFailure): Box data failed validation
  /// - Left(ServerFailure.notFound): Box does not exist
  /// - Left(NetworkFailure): No internet connection
  ///
  /// Requirements: 4.1
  Future<Either<Failure, Box>> updateBox(Box box);

  /// Retrieves all crab records for a given box.
  ///
  /// Returns:
  /// - Right(List<Crab>): All crabs in the box (may be empty)
  /// - Left(ServerFailure.notFound): Box does not exist
  /// - Left(NetworkFailure): No internet and no cached data
  ///
  /// Requirements: 16.1
  Future<Either<Failure, List<Crab>>> getCrabsByBox(String boxId);

  /// Deletes a crab record.
  ///
  /// Note: This does NOT automatically decrement the box count — the caller
  /// is responsible for updating the box if required.
  ///
  /// Returns:
  /// - Right(void): Crab deleted
  /// - Left(ServerFailure.notFound): Crab does not exist
  /// - Left(NetworkFailure): No internet connection
  ///
  /// Requirements: 16.10
  Future<Either<Failure, void>> deleteCrab(String crabId);

  /// Returns a stream that emits the latest [Box] state whenever it changes.
  ///
  /// Useful for real-time UI updates. Emits from local cache immediately,
  /// then from network as data arrives.
  ///
  /// The stream does not close on error — implementations should handle
  /// errors by emitting updated data after reconnection.
  ///
  /// Requirements: 4.1, 4.7
  Stream<Box> watchBox(String boxId);
}
