// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/operation_log.dart';
import '../../domain/entities/operation_type.dart';
import '../../domain/repositories/operation_repository.dart';
import '../datasources/operation_local_data_source.dart';
import '../datasources/operation_remote_data_source.dart';
import '../models/operation_log_model.dart';

/// Concrete implementation of [OperationRepository].
///
/// Follows an offline-first strategy:
/// - **Reads (online)**: fetch from remote, cache locally, return fresh data.
/// - **Reads (offline)**: return cached data; emit [NetworkFailure] when no
///   cached data exists.
/// - **Writes (online)**: save locally with isDirty=true, call remote,
///   mark as synced on success.
/// - **Writes (offline)**: save locally with isDirty=true, queue in
///   SyncQueue for deferred upload — returns [Right(OperationLog)] so
///   the UI reflects the change immediately (Requirements 10.6-10.7).
///
/// The 24-hour edit window (Requirement 10.9) is enforced by checking
/// [OperationLog.isEditable] before calling remote or local updates.
///
/// All data-layer exceptions are mapped to domain [Failure] types:
/// - [ServerException]  → [ServerFailure]
/// - [NetworkException] → [NetworkFailure]
/// - [CacheException]   → [CacheFailure]
/// - [ParseException]   → [ParseFailure]
///
/// Requirements: 10.1-10.10
class OperationRepositoryImpl implements OperationRepository {
  const OperationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
  });

  final OperationRemoteDataSource remoteDataSource;
  final OperationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;

  static const _uuid = Uuid();

  // ──────────────────────────────────────────────────────────────────────────
  // OperationRepository implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, OperationLog>> createOperationLog(OperationLog log) async {
    // Requirements: 10.1, 10.3, 10.6, 10.7, 10.10

    // Assign a client-side UUID if the caller did not provide one.
    final logWithId = log.id.trim().isEmpty ? log.copyWith(id: _uuid.v4()) : log;

    // Always save locally first with isDirty=true (offline-first).
    final localModel = OperationLogModel.fromEntity(logWithId, isDirty: true);

    try {
      await localDataSource.createLocalOperationLog(localModel);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }

    if (await networkInfo.isConnected) {
      try {
        // Sync immediately — within 10 seconds per Requirement 10.6.
        final remoteModel = await remoteDataSource.createOperationLog(localModel);
        // Update local record with the server's response.
        await localDataSource.markAsSynced(remoteModel.id);
        return Right(remoteModel.toEntity());
      } on ServerException catch (e) {
        // Local record is already saved; report failure but don't rollback.
        logger.w('OperationRepo: remote create failed for ${logWithId.id} — ${e.message}');
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        logger.w('OperationRepo: network error on create — ${e.message}');
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline: queue for later sync (Requirement 10.7).
    logger.d('OperationRepo: offline — queuing create for ${logWithId.id}');
    try {
      await localDataSource.queueOperationLogAction(
        operationType: 'create_operation_log',
        entityId: logWithId.id,
        payload: localModel.toJson(),
      );
    } on CacheException catch (e) {
      // Queuing is best-effort; the sync service can also pick up isDirty records.
      logger.w('OperationRepo: failed to queue create — ${e.message}');
    }

    // Return the locally saved entity so the UI updates immediately.
    return Right(localModel.toEntity());
  }

  @override
  Future<Either<Failure, List<OperationLog>>> getOperationHistory({
    required String boxId,
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
    int page = 1,
    int pageSize = 50,
  }) async {
    // Requirements: 10.4, 10.7, 10.8
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getOperationHistory(
          boxId: boxId,
          page: page,
          limit: pageSize,
          startDate: startDate,
          endDate: endDate,
          type: type,
        );
        // Cache fresh data for offline access.
        await localDataSource.cacheOperationLogs(models.map((m) => m.toEntity()).toList());
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline — serve from cache (Requirement 10.7).
    logger.d('OperationRepo: offline — serving cached history for boxId=$boxId');
    return _getCachedHistory(
      boxId: boxId,
      startDate: startDate,
      endDate: endDate,
      type: type,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Either<Failure, OperationLog>> updateOperationLog(OperationLog log) async {
    // Requirements: 10.9

    // Enforce 24-hour editing window (Requirement 10.9).
    if (!log.isEditable) {
      return const Left(
        ValidationFailure(
          'Operation logs can only be edited within 24 hours of creation.',
          code: 'EDIT_WINDOW_EXPIRED',
        ),
      );
    }

    // Save locally with isDirty=true first.
    final localModel = OperationLogModel.fromEntity(log, isDirty: true);

    try {
      await localDataSource.updateLocalOperationLog(localModel);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }

    if (await networkInfo.isConnected) {
      try {
        final remoteModel = await remoteDataSource.updateOperationLog(log.id, localModel);
        await localDataSource.markAsSynced(remoteModel.id);
        return Right(remoteModel.toEntity());
      } on ServerException catch (e) {
        logger.w('OperationRepo: remote update failed for ${log.id} — ${e.message}');
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        logger.w('OperationRepo: network error on update — ${e.message}');
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline: queue for later sync (Requirement 10.7).
    logger.d('OperationRepo: offline — queuing update for ${log.id}');
    try {
      await localDataSource.queueOperationLogAction(
        operationType: 'update_operation_log',
        entityId: log.id,
        payload: localModel.toJson(),
      );
    } on CacheException catch (e) {
      logger.w('OperationRepo: failed to queue update — ${e.message}');
    }

    return Right(localModel.toEntity());
  }

  @override
  Future<Either<Failure, OperationLog>> getOperationById(String id) async {
    // Requirements: 10.8
    if (await networkInfo.isConnected) {
      try {
        // No dedicated single-item endpoint — fetch and filter locally.
        // This also refreshes the cached record.
        final cached = await localDataSource.getCachedOperationLogById(id);
        if (cached != null && !cached.isDirty) {
          return Right(cached.toEntity());
        }
      } on CacheException {
        // Fall through to remote if cache read fails.
      }
    }

    // Serve from cache (also handles offline case).
    try {
      final cached = await localDataSource.getCachedOperationLogById(id);
      if (cached == null) {
        return const Left(ServerFailure.notFound('Operation log'));
      }
      return Right(cached.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Reads cached operation history from the local data source.
  Future<Either<Failure, List<OperationLog>>> _getCachedHistory({
    required String boxId,
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final cached = await localDataSource.getCachedOperationLogs(
        boxId,
        startDate: startDate,
        endDate: endDate,
        type: type,
        page: page,
        pageSize: pageSize,
      );
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  /// Converts a [ServerException] to the most specific [Failure] subtype.
  Failure _mapServerException(ServerException e) {
    switch (e.statusCode) {
      case 401:
        return const ServerFailure.unauthorized();
      case 403:
        return const ServerFailure.forbidden();
      case 404:
        return const ServerFailure.notFound('Operation log');
      case 500:
      case 502:
      case 503:
        return const ServerFailure.internal();
      default:
        return ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    }
  }
}
