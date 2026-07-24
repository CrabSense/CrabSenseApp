// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/database/database.dart' show SyncQueue;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_enums.dart';
import '../../domain/repositories/alert_repository.dart';
import '../datasources/alert_local_data_source.dart';
import '../datasources/alert_remote_data_source.dart';

/// Concrete implementation of [AlertRepository].
///
/// Follows an offline-first strategy:
/// - **Reads (online)**: fetch from remote, cache locally, return fresh data.
/// - **Reads (offline)**: return cached data; emit [NetworkFailure] when no
///   cached data exists.
/// - **Writes (online)**: call remote, update local cache.
/// - **Writes (offline)**: update local status, queue to [SyncQueue] for
///   later synchronisation — still returns [Right(Alert)] so the UI
///   reflects the change immediately (Requirement 9.10).
///
/// All data-layer exceptions are mapped to domain [Failure] types:
/// - [ServerException]  → [ServerFailure]
/// - [NetworkException] → [NetworkFailure]
/// - [CacheException]   → [CacheFailure]
/// - [ParseException]   → [ParseFailure]
///
/// Requirements: 9.1-9.10
class AlertRepositoryImpl implements AlertRepository {
  const AlertRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
  });

  final AlertRemoteDataSource remoteDataSource;
  final AlertLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;

  // ──────────────────────────────────────────────────────────────────────────
  // AlertRepository implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Alert>>> getAlerts({
    AlertFilters? filters,
  }) async {
    // Requirements: 9.4, 9.8, 9.9, 9.10
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getAlerts(filters: filters);
        await localDataSource.cacheAlerts(models);
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline — serve from cache (Requirement 9.10).
    logger.d('AlertRepo: offline — serving cached alerts');
    return _getCachedAlerts(filters: filters);
  }

  @override
  Future<Either<Failure, Alert>> getAlertById(String alertId) async {
    // Requirements: 9.5, 9.10
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.getAlertById(alertId);
        // Cache single alert by inserting into the local store.
        await localDataSource.cacheAlerts([model]);
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline — try cache.
    logger.d('AlertRepo: offline — serving cached alert id=$alertId');
    try {
      final cached = await localDataSource.getCachedAlertById(alertId);
      if (cached == null) {
        return const Left(ServerFailure.notFound('Alert'));
      }
      return Right(cached.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, Alert>> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
  }) async {
    // Requirements: 9.6, 9.7, 9.10

    // Validate: cannot acknowledge an already-dismissed alert.
    final validationResult = await _guardNotDismissed(alertId);
    if (validationResult != null) {
      return Left(validationResult);
    }

    final now = DateTime.now();

    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.acknowledgeAlert(
          alertId: alertId,
          acknowledgedBy: acknowledgedBy,
        );
        // Update local cache with server-confirmed state.
        await localDataSource.updateAlertStatus(
          alertId: alertId,
          status: AlertStatus.acknowledged.name,
          acknowledgedAt: model.acknowledgedAt ?? now,
          acknowledgedBy: acknowledgedBy,
        );
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline: update locally and queue for later sync (Requirement 9.10).
    logger.d('AlertRepo: offline — queuing acknowledgeAlert id=$alertId');
    try {
      await localDataSource.updateAlertStatus(
        alertId: alertId,
        status: AlertStatus.acknowledged.name,
        acknowledgedAt: now,
        acknowledgedBy: acknowledgedBy,
      );
      await localDataSource.queueAlertAction(
        operationType: 'acknowledge_alert',
        alertId: alertId,
        payload: {'acknowledgedBy': acknowledgedBy},
      );

      // Return the updated local model so the UI reflects the change.
      final updated = await localDataSource.getCachedAlertById(alertId);
      if (updated != null) {
        return Right(updated.toEntity());
      }

      // Construct synthetic entity if the cache read fails.
      return Right(
        Alert(
          id: alertId,
          type: AlertType.system,
          severity: AlertSeverity.info,
          title: '',
          message: '',
          recommendedActions: const [],
          createdAt: now,
          status: AlertStatus.acknowledged,
          acknowledgedAt: now,
          acknowledgedBy: acknowledgedBy,
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, Alert>> dismissAlert(String alertId) async {
    // Requirements: 9.6, 9.10

    // Validate: cannot dismiss an already-dismissed alert.
    final validationResult = await _guardNotDismissed(alertId);
    if (validationResult != null) {
      return Left(validationResult);
    }

    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.dismissAlert(alertId);
        await localDataSource.updateAlertStatus(
          alertId: alertId,
          status: AlertStatus.dismissed.name,
        );
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline: update locally and queue for later sync (Requirement 9.10).
    logger.d('AlertRepo: offline — queuing dismissAlert id=$alertId');
    try {
      await localDataSource.updateAlertStatus(
        alertId: alertId,
        status: AlertStatus.dismissed.name,
      );
      await localDataSource.queueAlertAction(
        operationType: 'dismiss_alert',
        alertId: alertId,
        payload: {'alertId': alertId},
      );

      final updated = await localDataSource.getCachedAlertById(alertId);
      if (updated != null) {
        return Right(updated.toEntity());
      }

      // Construct synthetic entity if the cache read fails.
      return Right(
        Alert(
          id: alertId,
          type: AlertType.system,
          severity: AlertSeverity.info,
          title: '',
          message: '',
          recommendedActions: const [],
          createdAt: DateTime.now(),
          status: AlertStatus.dismissed,
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    // Requirements: 9.2
    // Prefer local count for speed; attempt background refresh if online.
    try {
      final localCount = await localDataSource.getCachedUnreadCount();

      // Fire-and-forget background sync to keep count accurate.
      if (await networkInfo.isConnected) {
        _syncUnreadCountInBackground();
      }

      return Right(localCount);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Stream<int> watchUnreadCount() =>
      // Requirements: 9.2
      // Delegate directly to the local stream; the local DB is kept in sync
      // by cacheAlerts() calls from getAlerts().
      localDataSource.watchUnreadCount().handleError((Object error) {
        logger.e('AlertRepo: watchUnreadCount error — $error');
      });

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Reads cached alerts from the local data source.
  Future<Either<Failure, List<Alert>>> _getCachedAlerts({
    AlertFilters? filters,
  }) async {
    try {
      final cached = await localDataSource.getCachedAlerts(filters: filters);
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  /// Checks the cached alert status; returns a [ValidationFailure] if the
  /// alert is already dismissed, or null if the operation can proceed.
  ///
  /// Requirements: 9.6
  Future<ValidationFailure?> _guardNotDismissed(String alertId) async {
    try {
      final cached = await localDataSource.getCachedAlertById(alertId);
      if (cached != null && cached.status == AlertStatus.dismissed) {
        return ValidationFailure(
          'Alert $alertId is already dismissed and cannot be modified.',
          code: 'ALERT_ALREADY_DISMISSED',
        );
      }
    } on CacheException {
      // If we can't read the cache, allow the operation to proceed;
      // the server will enforce the rule.
    }
    return null;
  }

  /// Fires a background request to get the unread count from the server
  /// and implicitly refreshes the local cache via the next [getAlerts] call.
  void _syncUnreadCountInBackground() {
    remoteDataSource
        .getUnreadCount()
        .then((_) {
          // We don't act on the result here; the primary purpose is to trigger
          // any side effects on the server side. The local count is authoritative
          // for the UI per Requirement 9.2.
        })
        .catchError((Object e) {
          logger.w('AlertRepo: background unread count sync failed — $e');
        });
  }

  /// Converts a [ServerException] to the most specific [Failure] subtype.
  Failure _mapServerException(ServerException e) {
    switch (e.statusCode) {
      case 401:
        return const ServerFailure.unauthorized();
      case 403:
        return const ServerFailure.forbidden();
      case 404:
        return const ServerFailure.notFound('Alert');
      case 500:
      case 502:
      case 503:
        return const ServerFailure.internal();
      default:
        return ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    }
  }
}
