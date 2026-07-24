// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_data_source.dart';
import '../datasources/dashboard_remote_data_source.dart';

/// Concrete implementation of [DashboardRepository].
///
/// Orchestration logic:
/// 1. `getDashboardSummary`: attempts a remote fetch; on success caches
///    the result and returns it. On [NetworkException] / [NetworkFailure]
///    falls back to the local cache with `isFromCache` set to `true`
///    (Requirement 2.6). Any other exception maps to a [Failure] and is
///    returned as `Left`.
/// 2. `getCachedDashboardSummary`: reads directly from the local data
///    source without touching the network (Requirements 2.6, 2.10).
///
/// Requirements: 2.1–2.10
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required DashboardRemoteDataSource remoteDataSource,
    required DashboardLocalDataSource localDataSource,
    required this._logger,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final DashboardRemoteDataSource _remote;
  final DashboardLocalDataSource _local;
  final Logger _logger;

  // ─────────────────────────────────────────────────────────────────────────
  // getDashboardSummary
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, DashboardSummary>> getDashboardSummary() async {
    _logger.d('DashboardRepository: getDashboardSummary');

    try {
      // 1. Fetch from the remote API.
      final model = await _remote.getDashboardSummary();

      // 2. Cache the fresh result (fire-and-forget; failure is non-fatal).
      try {
        await _local.cacheDashboardSummary(model);
      } on Exception catch (cacheWriteError) {
        _logger.w(
          'DashboardRepository: cache write failed '
          '(non-fatal) — $cacheWriteError',
        );
      }

      // 3. Return the fresh domain entity.
      _logger.d('DashboardRepository: remote fetch succeeded');
      return Right(model.toDomain());
    } on NetworkException catch (e) {
      // 4. Offline path — fall back to local cache.
      _logger.w(
        'DashboardRepository: network unavailable (${e.message}), '
        'falling back to cache',
      );
      return _getCachedOrNetworkFailure(e);
    } on CacheException catch (e) {
      _logger.e('DashboardRepository: cache error — ${e.message}');
      return Left(CacheFailure(e.message, e.code));
    } on ServerException catch (e) {
      _logger.e('DashboardRepository: server error ${e.statusCode} — ${e.message}');
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } on Object catch (e, st) {
      _logger.e('DashboardRepository: unexpected error — $e');
      return Left(ErrorMapper.mapExceptionToFailure(e, st));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // getCachedDashboardSummary
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, DashboardSummary>> getCachedDashboardSummary() async {
    _logger.d('DashboardRepository: getCachedDashboardSummary');

    try {
      final model = await _local.getCachedDashboardSummary();
      // Always mark as from cache when served from local storage.
      final cachedModel = model.copyWithIsFromCache(isFromCache: true);
      return Right(cachedModel.toDomain());
    } on CacheException catch (e) {
      _logger.w('DashboardRepository: no cached data available — ${e.message}');
      return const Left(CacheFailure.readError());
    } on Object catch (e, st) {
      _logger.e('DashboardRepository: unexpected cache read error — $e');
      return Left(ErrorMapper.mapExceptionToFailure(e, st));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Attempts to serve cached data; falls back to [NetworkFailure] if the
  /// cache is also empty.
  Future<Either<Failure, DashboardSummary>> _getCachedOrNetworkFailure(
    NetworkException networkException,
  ) async {
    try {
      final cached = await _local.getCachedDashboardSummary();
      final cachedModel = cached.copyWithIsFromCache(isFromCache: true);
      _logger.d(
        'DashboardRepository: serving cached data '
        '(fetchedAt: ${cachedModel.fetchedAt})',
      );
      return Right(cachedModel.toDomain());
    } on CacheException catch (e) {
      // Both network and cache failed — nothing to show.
      _logger.e(
        'DashboardRepository: no network and no cache — '
        'network: ${networkException.message}, cache: ${e.message}',
      );
      return Left(NetworkFailure(networkException.message, networkException.code));
    }
  }
}
