// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/database/database.dart' show SyncQueue;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../datasources/inspection_local_data_source.dart';
import '../datasources/inspection_remote_data_source.dart';
import '../models/inspection_model.dart';

/// Offline-first implementation of [InspectionRepository].
///
/// Strategy:
/// - **Writes**: persist to local DB immediately (so the UI confirms quickly),
///   then attempt remote sync when online.  When offline the record is marked
///   `syncStatus: pending` and uploaded by [syncPendingInspections] later.
/// - **Reads**: try remote first when online and cache the result; fall back to
///   cached data when offline.
/// - **Feedback**: send directly to the remote AI service when online; queue
///   in [SyncQueue] via the SyncService when offline.
/// - **Errors**: all data-layer exceptions are mapped to typed [Failure]
///   values so callers never depend on infrastructure details.
///
/// Requirements: 7.1-7.10, 13.3-13.7
class InspectionRepositoryImpl implements InspectionRepository {
  const InspectionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
  });

  final InspectionRemoteDataSource remoteDataSource;
  final InspectionLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;

  // ──────────────────────────────────────────────────────────────────────────
  // InspectionRepository implementation
  // ──────────────────────────────────────────────────────────────────────────

  /// Saves an inspection locally and, when online, immediately syncs it.
  ///
  /// The record is persisted locally first regardless of connectivity so the
  /// UI can confirm submission even when offline (Requirement 7.7).
  ///
  /// Requirements: 7.4, 7.6, 7.7
  @override
  Future<Either<Failure, Inspection>> submitInspection(Inspection inspection) async {
    // 1. Validate the inspection before persisting anything.
    if (!inspection.hasValidWeight) {
      return const Left(
        ValidationFailure('Weight must be a positive number.', code: 'INVALID_WEIGHT'),
      );
    }

    // 2. Persist locally first — mark dirty so it gets picked up for sync.
    try {
      await localDataSource.saveInspection(inspection, isDirty: true);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }

    // 3. If online, sync immediately and update the local record status.
    if (await networkInfo.isConnected) {
      try {
        final model = InspectionModel.fromEntity(inspection);
        final synced = await remoteDataSource.submitInspection(model);

        // Update the local copy to reflect the synced state.
        await localDataSource.saveInspection(synced.copyWith(syncStatus: SyncStatus.synced));

        return Right(synced.toEntity());
      } on ServerException catch (e) {
        // Remote sync failed — mark the local record so it can be retried.
        await _tryMarkFailed(inspection.id);
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        await _tryMarkFailed(inspection.id);
        return Left(NetworkFailure(e.message, e.code));
      } on CacheException catch (e) {
        // Remote succeeded but local update failed — non-critical.
        logger.w(
          'InspectionRepositoryImpl: local update after sync failed: '
          '${e.message}',
        );
      }
    }

    // Offline path — return the locally-saved entity with pending status.
    final pending = inspection.copyWith(syncStatus: SyncStatus.pending);
    return Right(pending);
  }

  /// Sends feedback to the remote AI service.
  ///
  /// When offline the feedback is queued in the SyncQueue table and sent
  /// with the next sync cycle (Requirement 7.7, 13.4).
  ///
  /// Requirements: 7.5
  @override
  Future<Either<Failure, void>> submitFeedback(InspectionFeedback feedback) async {
    if (!await networkInfo.isConnected) {
      // Queue feedback offline via SyncQueue (Requirement 7.7, 13.4).
      try {
        await localDataSource.savePendingFeedback(feedback);
        return const Right(null);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message, e.code));
      }
    }

    try {
      final model = InspectionFeedbackModel.fromEntity(feedback);
      await remoteDataSource.submitFeedback(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(_mapServerException(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, e.code));
    }
  }

  /// Returns inspection history for a box, newest-first.
  ///
  /// Online: fetch from server and refresh the local cache.
  /// Offline: serve from local cache (Requirement 7.7, 7.10).
  ///
  /// Requirements: 7.10
  @override
  Future<Either<Failure, List<Inspection>>> getInspectionHistory(String boxId) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getInspectionHistory(boxId);

        // Cache each record for offline access.
        for (final model in models) {
          await localDataSource.saveInspection(model.copyWith(syncStatus: SyncStatus.synced));
        }

        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        // Remote failed — fall through to cache.
        logger.w(
          'InspectionRepositoryImpl: remote getInspectionHistory failed '
          '(${e.statusCode}), serving from cache.',
        );
      } on NetworkException catch (e) {
        logger.w(
          'InspectionRepositoryImpl: network error in getInspectionHistory: '
          '${e.message}',
        );
      }
    }

    // Offline / remote-failed fallback — serve from local cache.
    try {
      final cached = await localDataSource.getInspections(boxId);
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  /// Computes the AI agreement rate for a box.
  ///
  /// Agreement rate = number of inspections where aiAgreement==true divided
  /// by all inspections with a non-null aiAgreement (Requirement 7.8).
  /// Returns `0.0` when no comparable inspections exist.
  ///
  /// Requirements: 7.8
  @override
  Future<Either<Failure, double>> getAgreementRate(String boxId) async {
    try {
      final counts = await localDataSource.getAgreementCounts(boxId);

      if (counts.total == 0) return const Right(0);

      final rate = counts.agreed / counts.total;
      return Right(rate);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  /// Uploads all pending (offline-queued) inspection records to the server.
  ///
  /// Processing order is chronological (oldest first) per Requirement 13.6.
  /// Failed items are marked with [SyncStatus.failed] so they are retried
  /// with exponential backoff by the SyncService (Requirement 13.7).
  ///
  /// Requirements: 7.7, 13.5-13.7
  @override
  Future<Either<Failure, void>> syncPendingInspections() async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(
          'No internet connection. Sync deferred until connectivity is restored.',
          'NETWORK_ERROR',
        ),
      );
    }

    List<InspectionModel> pending;
    try {
      pending = await localDataSource.getPendingSyncInspections();
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }

    if (pending.isEmpty) return const Right(null);

    var failedCount = 0;

    for (final inspection in pending) {
      try {
        final synced = await remoteDataSource.submitInspection(inspection);

        await localDataSource.saveInspection(synced.copyWith(syncStatus: SyncStatus.synced));
      } on ServerException catch (e) {
        logger.w(
          'InspectionRepositoryImpl: sync failed for ${inspection.id}: '
          '${e.message}',
        );
        await _tryMarkFailed(inspection.id);
        failedCount++;
      } on NetworkException catch (e) {
        // Network dropped mid-sync — stop processing, retry later.
        logger.w('InspectionRepositoryImpl: network lost during sync: ${e.message}');
        await _tryMarkFailed(inspection.id);
        failedCount++;
        break;
      }
    }

    if (failedCount > 0) {
      return Left(SyncFailure.uploadFailed(failedCount));
    }

    return const Right(null);
  }

  /// Uploads all queued AI feedback records to the AI service.
  ///
  /// Queued feedback (stored in SyncQueue) is uploaded when connectivity
  /// is restored (Requirement 7.7, 13.5-13.6).
  ///
  /// Requirements: 7.5, 7.7
  @override
  Future<Either<Failure, void>> syncPendingFeedback() async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(
          'No internet connection. Feedback sync deferred until connectivity is restored.',
          'NETWORK_ERROR',
        ),
      );
    }

    List<InspectionFeedback> pending;
    try {
      pending = await localDataSource.getPendingFeedbacks();
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }

    if (pending.isEmpty) return const Right(null);

    var failedCount = 0;

    for (final feedback in pending) {
      try {
        final model = InspectionFeedbackModel.fromEntity(feedback);
        await remoteDataSource.submitFeedback(model);

        // Remove from queue after successful upload.
        await localDataSource.removePendingFeedback(feedback.inspectionId);
      } on ServerException catch (e) {
        logger.w(
          'InspectionRepositoryImpl: feedback sync failed for '
          '${feedback.inspectionId}: ${e.message}',
        );
        failedCount++;
      } on NetworkException catch (e) {
        // Network dropped mid-sync — stop processing, retry later.
        logger.w('InspectionRepositoryImpl: network lost during feedback sync: ${e.message}');
        failedCount++;
        break;
      }
    }

    if (failedCount > 0) {
      return Left(SyncFailure.uploadFailed(failedCount));
    }

    return const Right(null);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Attempts to mark a record as failed without surfacing cache errors.
  Future<void> _tryMarkFailed(String inspectionId) async {
    try {
      await localDataSource.markAsFailed(inspectionId);
    } catch (e) {
      logger.w(
        'InspectionRepositoryImpl: could not mark $inspectionId as '
        'failed: $e',
      );
    }
  }

  /// Maps a [ServerException] to the most specific [Failure] subtype.
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
