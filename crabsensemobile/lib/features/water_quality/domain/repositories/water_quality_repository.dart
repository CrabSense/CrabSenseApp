import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/water_quality.dart';

/// Time period for historical data queries.
enum HistoricalPeriod {
  /// Last 24 hours of data
  last24Hours,

  /// Last 7 days of data
  last7Days,

  /// Last 30 days of data
  last30Days,
}

/// Repository interface for water quality data operations.
///
/// This interface defines the contract for water quality data operations
/// following Clean Architecture principles. The domain layer depends on
/// this abstraction; concrete implementations live in the data layer.
///
/// Implementations should handle:
/// - Remote data via REST API (IoT sensor readings)
/// - Local cache via SQLite (drift)
/// - Offline-first: serve cached readings when offline (Requirement 8.10)
/// - Auto-refresh every 30 seconds (Requirement 8.7)
/// - Error mapping to domain Failures
///
/// All methods return `Either<Failure, T>` for functional error handling:
/// - Left(Failure): operation failed with a specific failure reason
/// - Right(T): operation succeeded with the result data
///
/// Requirements: 8.1-8.10
abstract class WaterQualityRepository {
  /// Retrieves the most recent water quality readings for a farm or pond.
  ///
  /// Returns cached readings when offline with staleness indicator
  /// (Requirement 8.10). Data should be displayed within 3 seconds
  /// (Requirement 8.1).
  ///
  /// Parameters:
  /// - [farmId]: The farm to retrieve readings for
  /// - [pondId]: Optional specific pond within the farm
  ///
  /// Returns:
  /// - `Right(List<WaterQuality>)`: Sensor readings (may be empty)
  /// - `Left(NetworkFailure)`: No internet and no cached data
  /// - `Left(CacheFailure)`: Error reading from local storage
  /// - `Left(ServerFailure)`: Server error or IoT device offline
  ///
  /// Requirements: 8.1, 8.2, 8.3, 8.8, 8.10
  Future<Either<Failure, List<WaterQuality>>> getCurrentReadings({
    required String farmId,
    String? pondId,
  });

  /// Retrieves historical water quality readings for charting.
  ///
  /// Returns time-series data for the specified period to display
  /// historical trends (Requirement 8.5).
  ///
  /// Parameters:
  /// - [farmId]: The farm to retrieve historical data for
  /// - [pondId]: Optional specific pond within the farm
  /// - [period]: Time period (24 hours, 7 days, or 30 days)
  ///
  /// Returns:
  /// - `Right(List<WaterQuality>)`: Readings sorted by timestamp
  /// - `Left(NetworkFailure)`: No internet and no cached data
  /// - `Left(ServerFailure)`: Server error
  /// - `Left(ValidationFailure)`: Invalid parameters
  ///
  /// Requirements: 8.5
  Future<Either<Failure, List<WaterQuality>>> getHistoricalData({
    required String farmId,
    required HistoricalPeriod period,
    String? pondId,
  });

  /// Returns a stream that emits water quality readings as they update.
  ///
  /// This stream enables real-time UI updates and auto-refresh every
  /// 30 seconds (Requirement 8.7). The stream emits from local cache
  /// immediately, then from network as new data arrives.
  ///
  /// The stream does not close on error — implementations should handle
  /// errors by emitting updated data after reconnection.
  ///
  /// Parameters:
  /// - [farmId]: The farm to watch readings for
  /// - [pondId]: Optional specific pond within the farm
  ///
  /// Requirements: 8.7
  Stream<List<WaterQuality>> watchCurrentReadings({required String farmId, String? pondId});

  /// Checks the online status of an IoT device/sensor.
  ///
  /// Used to display device offline status when sensor is not responding
  /// (Requirement 8.8).
  ///
  /// Returns:
  /// - `Right(bool)`: true if device is online, false if offline
  /// - `Left(NetworkFailure)`: Cannot determine status (no internet)
  /// - `Left(ServerFailure)`: Server error
  ///
  /// Requirements: 8.8
  Future<Either<Failure, bool>> checkDeviceStatus({required String sensorId});
}
