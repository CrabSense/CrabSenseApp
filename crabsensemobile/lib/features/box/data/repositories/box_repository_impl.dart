// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../shared/services/sync_queue_item.dart';
import '../../../../shared/services/sync_service.dart';
import '../../domain/entities/box.dart';
import '../../domain/entities/crab.dart';
import '../../domain/repositories/box_repository.dart';
import '../datasources/box_local_data_source.dart';
import '../datasources/box_remote_data_source.dart';
import '../models/box_model.dart';
import '../models/crab_model.dart';

/// Concrete implementation of [BoxRepository].
///
/// Follows an offline-first strategy:
/// - **Reads**: local cache first; fetch from remote only when the cache misses.
/// - **Writes**: persist locally and enqueue a sync operation immediately.
///
/// All data-layer exceptions are mapped to domain [Failure] types so callers
/// never depend on infrastructure details:
/// - [ServerException]  → [ServerFailure]
/// - [NetworkException] → [NetworkFailure]
/// - [CacheException]   → [CacheFailure]
/// - [ParseException]   → [ParseFailure]
///
/// Requirements: 4.1-4.10, 16.1-16.10
class BoxRepositoryImpl implements BoxRepository {
  const BoxRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    this.syncService,
  });

  final BoxRemoteDataSource remoteDataSource;
  final BoxLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final SyncService? syncService;

  // ---------------------------------------------------------------------------
  // BoxRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, Box>> getBoxDetails(String boxId) async {
    try {
      final cached = await localDataSource.getCachedBox(boxId);
      return Right(cached.toEntity());
    } on CacheException catch (cacheError) {
      if (!await networkInfo.isConnected) {
        return Left(CacheFailure(cacheError.message, cacheError.code));
      }
      try {
        final box = await remoteDataSource.getBoxDetails(boxId);
        await localDataSource.cacheBox(box);
        return Right(box.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Box>> getBoxByQrCode(String qrCode) async {
    try {
      final cached = await localDataSource.getCachedBoxByQrCode(qrCode);
      return Right(cached.toEntity());
    } on CacheException catch (cacheError) {
      if (!await networkInfo.isConnected) {
        return Left(CacheFailure(cacheError.message, cacheError.code));
      }
      try {
        final box = await remoteDataSource.getBoxByQrCode(qrCode);
        await localDataSource.cacheBox(box);
        return Right(box.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<Box>>> getBoxesByFarm(String farmId) async {
    try {
      final cached = await localDataSource.getCachedBoxesByFarm(farmId);
      return Right(cached.map((b) => b.toEntity()).toList());
    } on CacheException catch (cacheError) {
      if (!await networkInfo.isConnected) {
        return Left(CacheFailure(cacheError.message, cacheError.code));
      }
      try {
        final boxes = await remoteDataSource.getBoxesByFarm(farmId);
        await localDataSource.cacheBoxes(boxes);
        return Right(boxes.map((b) => b.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Crab>> addCrab(String boxId, Crab crab) async {
    try {
      await localDataSource.cacheCrab(crab, isDirty: true);
      await syncService?.enqueue(
        entityType: SyncEntityType.crab,
        operationType: 'create_crab',
        entityId: crab.id,
        payload: <String, dynamic>{
          'boxId': boxId,
          'crab': CrabModel.fromEntity(crab).toJson(),
          'clientUpdatedAt': DateTime.now().toIso8601String(),
        },
        priority: SyncPriority.high,
      );
      return Right(crab);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, void>> transferCrab(
    String crabId,
    String sourceBoxId,
    String destinationBoxId,
  ) async {
    try {
      await localDataSource.moveCachedCrab(crabId, destinationBoxId);
      await syncService?.enqueue(
        entityType: SyncEntityType.transfer,
        operationType: 'transfer_crab',
        entityId: crabId,
        payload: <String, dynamic>{
          'sourceBoxId': sourceBoxId,
          'destinationBoxId': destinationBoxId,
          'clientUpdatedAt': DateTime.now().toIso8601String(),
        },
        priority: SyncPriority.high,
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, Box>> updateBox(Box box) async {
    try {
      await localDataSource.cacheBox(box, isDirty: true);
      await syncService?.enqueue(
        entityType: SyncEntityType.box,
        operationType: 'update_box',
        entityId: box.id,
        payload: <String, dynamic>{
          'box': BoxModel.fromEntity(box).toJson(),
          'clientUpdatedAt': DateTime.now().toIso8601String(),
        },
      );
      return Right(box);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, List<Crab>>> getCrabsByBox(String boxId) async {
    try {
      final cached = await localDataSource.getCachedCrabsByBox(boxId);
      return Right(cached.map((c) => c.toEntity()).toList());
    } on CacheException catch (cacheError) {
      if (!await networkInfo.isConnected) {
        return Left(CacheFailure(cacheError.message, cacheError.code));
      }
      try {
        final crabs = await remoteDataSource.getCrabsByBox(boxId);
        for (final crab in crabs) {
          await localDataSource.cacheCrab(crab);
        }
        return Right(crabs.map((c) => c.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, void>> deleteCrab(String crabId) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(
          'Deleting a crab record requires an active connection. '
          'Please retry when online.',
        ),
      );
    }

    try {
      await remoteDataSource.deleteCrab(crabId);
      await localDataSource.deleteCachedCrab(crabId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(_mapServerException(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, e.code));
    } on CacheException catch (e) {
      // Remote succeeded; local cleanup failure is non-critical but surfaced.
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Stream<Box> watchBox(String boxId) => localDataSource.watchBox(boxId);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Converts a [ServerException] to the most specific [Failure] subtype.
  Failure _mapServerException(ServerException e) {
    switch (e.statusCode) {
      case 401:
        return const ServerFailure.unauthorized();
      case 403:
        return const ServerFailure.forbidden();
      case 404:
        return const ServerFailure.notFound();
      case 422:
        if (e.details != null) {
          final fields = <String, String>{};
          e.details!.forEach((k, v) => fields[k] = v.toString());
          return ValidationFailure.fields(fields);
        }
        return ValidationFailure(e.message);
      case 500:
      case 502:
      case 503:
        return const ServerFailure.internal();
      default:
        return ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    }
  }
}
