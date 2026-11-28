// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/water_quality.dart';
import '../../domain/repositories/water_quality_repository.dart';
import '../datasources/water_quality_local_data_source.dart';
import '../datasources/water_quality_remote_data_source.dart';

/// Concrete implementation of [WaterQualityRepository].
///
/// Verified online reads only until the cache preserves presence and user scope.
///
/// All data-layer exceptions are mapped to domain [Failure] types:
/// - [ServerException]  → [ServerFailure]
/// - [NetworkException] → [NetworkFailure]
/// - [CacheException]   → [CacheFailure]
/// - [ParseException]   → [ParseFailure]
///
/// Requirements: 8.1-8.10
class WaterQualityRepositoryImpl implements WaterQualityRepository {
  const WaterQualityRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
  });

  final WaterQualityRemoteDataSource remoteDataSource;
  final WaterQualityLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;

  // ──────────────────────────────────────────────────────────────────────────
  // WaterQualityRepository implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<WaterQuality>>> getCurrentReadings({
    required String farmId,
    String? pondId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final readings = await remoteDataSource.getCurrentReadings(farmId: farmId, pondId: pondId);
        // Legacy cache cannot preserve nullable values or user provenance.
        return Right(readings.map((r) => r.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    return const Left(NetworkFailure('No verified offline sensor readings.'));
  }

  @override
  Future<Either<Failure, List<WaterQuality>>> getHistoricalData({
    required String farmId,
    required HistoricalPeriod period,
    String? pondId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final readings = await remoteDataSource.getHistoricalData(
          farmId: farmId,
          period: period,
          pondId: pondId,
        );
        // Never cache unqualified historical data.
        return Right(readings.map((r) => r.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        // Fall through to cached data on network failure.
        logger.w(
          'WaterQualityRepo: network error fetching historical data, '
          'serving cache — ${e.message}',
        );
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    return const Left(NetworkFailure('No verified offline sensor history.'));
  }

  @override
  Stream<List<WaterQuality>> watchCurrentReadings({required String farmId, String? pondId}) =>
      const Stream.empty();

  @override
  Future<Either<Failure, bool>> checkDeviceStatus({required String sensorId}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Cannot check device status — no internet connection.'));
    }

    try {
      final isOnline = await remoteDataSource.checkDeviceStatus(sensorId: sensorId);
      return Right(isOnline);
    } on ServerException catch (e) {
      return Left(_mapServerException(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, e.code));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts a [ServerException] to the most specific [Failure] subtype.
  Failure _mapServerException(ServerException e) {
    switch (e.statusCode) {
      case 401:
        return const ServerFailure.unauthorized();
      case 403:
        return const ServerFailure.forbidden();
      case 404:
        return const ServerFailure.notFound('Sensor or farm');
      case 500:
      case 502:
      case 503:
        return const ServerFailure.internal();
      default:
        return ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    }
  }
}
