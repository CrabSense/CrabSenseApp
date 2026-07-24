// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/harvest.dart';
import '../../domain/entities/harvest_summary.dart';
import '../../domain/repositories/harvest_repository.dart';
import '../datasources/harvest_local_data_source.dart';
import '../datasources/harvest_remote_data_source.dart';
import '../models/harvest_model.dart';

/// Concrete implementation of [HarvestRepository].
///
/// Implements offline-first architecture:
/// - Reads: fetches remote when connected and caches locally; serves from cache when offline.
/// - Writes: persists locally first with `isDirty = true` and updates box inventory crab count.
///   Syncs immediately when online; queues in [SyncQueue] when offline.
///
/// Requirements: 11.1-11.10
class HarvestRepositoryImpl implements HarvestRepository {
  const HarvestRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
  });

  final HarvestRemoteDataSource remoteDataSource;
  final HarvestLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, Harvest>> recordHarvest(Harvest harvest) async {
    // Requirements: 11.1-11.8

    // Basic domain validation
    if (harvest.totalWeight <= 0) {
      return const Left(ValidationFailure('Total weight must be positive.'));
    }
    if (harvest.crabCount <= 0) {
      return const Left(ValidationFailure('Crab count must be positive.'));
    }

    final harvestWithId = harvest.id.trim().isEmpty ? harvest.copyWith(id: _uuid.v4()) : harvest;
    final localModel = HarvestModel.fromEntity(harvestWithId, isDirty: true);

    try {
      // Persist locally first and update box inventory crab count atomically (Requirement 11.4)
      await localDataSource.createLocalHarvest(localModel);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }

    if (await networkInfo.isConnected) {
      try {
        final remoteModel = await remoteDataSource.recordHarvest(localModel);
        await localDataSource.markAsSynced(remoteModel.id);
        return Right(remoteModel.toEntity());
      } on ServerException catch (e) {
        logger.w('HarvestRepo: remote record harvest failed for ${harvestWithId.id} — ${e.message}');
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        logger.w('HarvestRepo: network error on record harvest — ${e.message}');
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline: queue in SyncQueue for deferred background sync (Requirement 11.8)
    logger.d('HarvestRepo: offline — queuing harvest record ${harvestWithId.id}');
    try {
      await localDataSource.queueHarvestAction(
        operationType: 'record_harvest',
        entityId: harvestWithId.id,
        payload: localModel.toJson(),
      );
    } on CacheException catch (e) {
      logger.w('HarvestRepo: failed to queue harvest action — ${e.message}');
    }

    return Right(localModel.toEntity());
  }

  @override
  Future<Either<Failure, List<Harvest>>> getHarvestHistory({
    String? farmId,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
    int page = 1,
    int pageSize = 50,
  }) async {
    // Requirement 11.9
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getHarvestHistory(
          farmId: farmId,
          boxId: boxId,
          startDate: startDate,
          endDate: endDate,
          qualityGrade: qualityGrade,
          page: page,
          limit: pageSize,
        );
        await localDataSource.cacheHarvests(models.map((m) => m.toEntity()).toList());
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        logger.w('HarvestRepo: remote history error, falling back to cache — ${e.message}');
      } on NetworkException catch (e) {
        logger.w('HarvestRepo: network error, falling back to cache — ${e.message}');
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Serve from local cache when offline or on network failure
    try {
      final cached = await localDataSource.getCachedHarvestHistory(
        farmId: farmId,
        boxId: boxId,
        startDate: startDate,
        endDate: endDate,
        qualityGrade: qualityGrade,
        page: page,
        pageSize: pageSize,
      );
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, HarvestSummary>> getHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Requirement 11.10
    if (await networkInfo.isConnected) {
      try {
        final summaryModel = await remoteDataSource.getHarvestSummary(
          farmId: farmId,
          startDate: startDate,
          endDate: endDate,
        );
        return Right(summaryModel.toEntity());
      } on ServerException catch (e) {
        logger.w('HarvestRepo: remote summary error, calculating locally — ${e.message}');
      } on NetworkException catch (e) {
        logger.w('HarvestRepo: network summary error, calculating locally — ${e.message}');
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Local summary calculation for offline access
    try {
      final localSummary = await localDataSource.getLocalHarvestSummary(
        farmId: farmId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(localSummary.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, Harvest>> getHarvestById(String id) async {
    try {
      final cached = await localDataSource.getCachedHarvestById(id);
      if (cached != null) {
        return Right(cached.toEntity());
      }
    } on CacheException {
      // Fall through to remote read if cache read fails
    }

    if (await networkInfo.isConnected) {
      try {
        final remoteModel = await remoteDataSource.getHarvestById(id);
        await localDataSource.cacheHarvests([remoteModel.toEntity()]);
        return Right(remoteModel.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    return const Left(ServerFailure.notFound('Harvest record'));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  Failure _mapServerException(ServerException e) {
    switch (e.statusCode) {
      case 401:
        return const ServerFailure.unauthorized();
      case 403:
        return const ServerFailure.forbidden();
      case 404:
        return const ServerFailure.notFound('Harvest record');
      case 500:
      case 502:
      case 503:
        return const ServerFailure.internal();
      default:
        return ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    }
  }
}
