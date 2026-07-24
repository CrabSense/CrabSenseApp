// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sales_summary.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_local_data_source.dart';
import '../datasources/sales_remote_data_source.dart';
import '../models/sale_model.dart';

/// Concrete implementation of [SalesRepository].
///
/// Implements offline-first architecture:
/// - Reads: fetches remote when connected and caches locally; serves from cache when offline.
/// - Writes: persists locally first with `isDirty = true`.
///   Syncs immediately when online; queues in [SyncQueue] when offline.
///
/// Requirements: 12.1-12.10
class SalesRepositoryImpl implements SalesRepository {
  const SalesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
  });

  final SalesRemoteDataSource remoteDataSource;
  final SalesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, Sale>> createSale(Sale sale) async {
    // Requirements: 12.1-12.8

    // Basic domain validation
    if (sale.quantity <= 0) {
      return const Left(ValidationFailure('Quantity must be positive.'));
    }
    if (sale.unitPrice <= 0) {
      return const Left(ValidationFailure('Unit price must be positive.'));
    }
    if (sale.buyerName.trim().isEmpty) {
      return const Left(ValidationFailure('Buyer name is required.'));
    }

    final saleWithId = sale.id.trim().isEmpty ? sale.copyWith(id: _uuid.v4()) : sale;
    final localModel = SaleModel.fromEntity(saleWithId, isDirty: true);

    try {
      // Persist locally first
      await localDataSource.createLocalSale(localModel);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }

    if (await networkInfo.isConnected) {
      try {
        final remoteModel = await remoteDataSource.createSale(localModel);
        await localDataSource.markAsSynced(remoteModel.id);
        return Right(remoteModel.toEntity());
      } on ServerException catch (e) {
        logger.w('SalesRepo: remote create sale failed for ${saleWithId.id} — ${e.message}');
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        logger.w('SalesRepo: network error on create sale — ${e.message}');
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline: queue in SyncQueue for deferred background sync (Requirement 12.8)
    logger.d('SalesRepo: offline — queuing sale record ${saleWithId.id}');
    try {
      await localDataSource.queueSaleAction(
        operationType: 'create_sale',
        entityId: saleWithId.id,
        payload: localModel.toJson(),
      );
    } on CacheException catch (e) {
      logger.w('SalesRepo: failed to queue sale action — ${e.message}');
    }

    return Right(localModel.toEntity());
  }

  @override
  Future<Either<Failure, List<Sale>>> getSalesHistory({
    String? farmId,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int page = 1,
    int pageSize = 50,
  }) async {
    // Requirement 12.10
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getSalesHistory(
          farmId: farmId,
          buyerName: buyerName,
          startDate: startDate,
          endDate: endDate,
          paymentMethod: paymentMethod,
          paymentStatus: paymentStatus,
          page: page,
          limit: pageSize,
        );
        await localDataSource.cacheSales(models.map((m) => m.toEntity()).toList());
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        logger.w('SalesRepo: remote history error, falling back to cache — ${e.message}');
      } on NetworkException catch (e) {
        logger.w('SalesRepo: network error, falling back to cache — ${e.message}');
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Serve from local cache when offline or on network failure
    try {
      final cached = await localDataSource.getCachedSalesHistory(
        farmId: farmId,
        buyerName: buyerName,
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        page: page,
        pageSize: pageSize,
      );
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, SalesSummary>> getSalesSummary({
    String? farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Requirement 12.10
    if (await networkInfo.isConnected) {
      try {
        final summaryModel = await remoteDataSource.getSalesSummary(
          farmId: farmId,
          startDate: startDate,
          endDate: endDate,
        );
        return Right(summaryModel.toEntity());
      } on ServerException catch (e) {
        logger.w('SalesRepo: remote summary error, calculating locally — ${e.message}');
      } on NetworkException catch (e) {
        logger.w('SalesRepo: network summary error, calculating locally — ${e.message}');
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Local summary calculation for offline access
    try {
      final localSummary = await localDataSource.getLocalSalesSummary(
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
  Future<Either<Failure, Sale>> getSaleById(String id) async {
    try {
      final cached = await localDataSource.getCachedSaleById(id);
      if (cached != null) {
        return Right(cached.toEntity());
      }
    } on CacheException {
      // Fall through to remote read if cache read fails
    }

    if (await networkInfo.isConnected) {
      try {
        final remoteModel = await remoteDataSource.getSaleById(id);
        await localDataSource.cacheSales([remoteModel.toEntity()]);
        return Right(remoteModel.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    return const Left(ServerFailure.notFound('Sales record'));
  }

  @override
  Future<Either<Failure, double>> getAvailableHarvestedInventory({String? farmId}) async {
    // Requirement 12.4
    if (await networkInfo.isConnected) {
      try {
        final available = await remoteDataSource.getAvailableHarvestedInventory(farmId: farmId);
        return Right(available);
      } on ServerException catch (e) {
        logger.w('SalesRepo: remote inventory query error, falling back to local calculation — ${e.message}');
      } on NetworkException catch (e) {
        logger.w('SalesRepo: network inventory query error, falling back to local calculation — ${e.message}');
      }
    }

    // Fallback to local calculation from Harvests and Sales tables
    try {
      final availableLocal = await localDataSource.getLocalAvailableHarvestedInventory(farmId: farmId);
      return Right(availableLocal);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
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
        return const ServerFailure.notFound('Sales record');
      case 500:
      case 502:
      case 503:
        return const ServerFailure.internal();
      default:
        return ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    }
  }
}
