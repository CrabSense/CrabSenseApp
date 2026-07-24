// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/sale.dart';
import '../models/sale_model.dart';

/// Contract for sales record caching and local database operations.
///
/// All operations interact directly with the Drift SQLite database.
///
/// Throws [CacheException] on storage failure.
///
/// Requirements: 12.1-12.10
abstract class SalesLocalDataSource {
  /// Returns cached sales records with optional filters and pagination.
  ///
  /// Requirements: 12.10
  Future<List<SaleModel>> getCachedSalesHistory({
    String? farmId,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int page = 1,
    int pageSize = 50,
  });

  /// Returns a single cached sales transaction by ID, or null if not found.
  Future<SaleModel?> getCachedSaleById(String id);

  /// Persists a batch of remote sales records locally.
  Future<void> cacheSales(List<Sale> sales);

  /// Creates a new sales record in local storage (`isDirty = true`).
  ///
  /// Requirements: 12.7, 12.8
  Future<SaleModel> createLocalSale(SaleModel model);

  /// Returns all unsynced sales records (`isDirty = true`).
  Future<List<SaleModel>> getUnsyncedSales();

  /// Marks a sales record as synced (`isDirty = false`, updates `syncedAt`).
  Future<void> markAsSynced(String id);

  /// Queues a sales action in the [SyncQueue] table for offline sync.
  ///
  /// Requirements: 12.8
  Future<void> queueSaleAction({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
  });

  /// Calculates cumulative sales metrics locally.
  ///
  /// Requirements: 12.10
  Future<SalesSummaryModel> getLocalSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? farmId,
  });

  /// Calculates available harvested inventory locally from `Harvests` and `Sales` tables.
  ///
  /// Returns total harvested weight minus total sales quantity.
  ///
  /// Requirements: 12.4
  Future<double> getLocalAvailableHarvestedInventory({String? farmId});
}

/// Drift-backed implementation of [SalesLocalDataSource].
class SalesLocalDataSourceImpl implements SalesLocalDataSource {
  SalesLocalDataSourceImpl({required this.database});

  final db.AppDatabase database;

  static const _uuid = Uuid();

  @override
  Future<List<SaleModel>> getCachedSalesHistory({
    String? farmId,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final offset = (page - 1) * pageSize;

      final query = database.select(database.sales)
        ..where((t) => _buildWhereExpression(t, buyerName, startDate, endDate, paymentMethod, paymentStatus))
        ..orderBy([(t) => OrderingTerm(expression: t.saleDate, mode: OrderingMode.desc)])
        ..limit(pageSize, offset: offset);

      final rows = await query.get();
      return rows.map((r) => SaleModel.fromDrift(r, farmId: farmId)).toList(growable: false);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read cached sales history: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<SaleModel?> getCachedSaleById(String id) async {
    try {
      final query = database.select(database.sales)
        ..where((t) => t.id.equals(id))
        ..limit(1);

      final rows = await query.get();
      if (rows.isEmpty) return null;
      return SaleModel.fromDrift(rows.first);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read cached sale $id: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> cacheSales(List<Sale> sales) async {
    try {
      await database.transaction(() async {
        final now = DateTime.now();
        for (final sale in sales) {
          final model = SaleModel.fromEntity(sale, isDirty: false, syncedAt: now);
          final companion = model.toDriftCompanion();
          await database.into(database.sales).insertOnConflictUpdate(companion);
        }
      });
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to cache sales records: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<SaleModel> createLocalSale(SaleModel model) async {
    try {
      final dirtyModel = model.copyWith(isDirty: true);
      final companion = dirtyModel.toDriftCompanion();
      await database.transaction(() async {
        await database.into(database.sales).insert(companion);
      });
      return dirtyModel;
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to create local sales record: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<List<SaleModel>> getUnsyncedSales() async {
    try {
      final query = database.select(database.sales)
        ..where((t) => t.isDirty.equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.saleDate, mode: OrderingMode.asc)]);

      final rows = await query.get();
      return rows.map((r) => SaleModel.fromDrift(r)).toList(growable: false);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read unsynced sales records: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> markAsSynced(String id) async {
    try {
      await (database.update(database.sales)..where((t) => t.id.equals(id))).write(
        db.SalesCompanion(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to mark sale $id as synced: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> queueSaleAction({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final companion = db.SyncQueueCompanion(
        id: Value(_uuid.v4()),
        operationType: Value(operationType),
        entityId: Value(entityId),
        entityType: const Value('sale'),
        payload: Value(jsonEncode(payload)),
        createdAt: Value(DateTime.now()),
        retryCount: const Value(0),
        status: const Value('pending'),
        priority: const Value(2), // High priority for sales
      );
      await database.into(database.syncQueue).insert(companion);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to queue sales action $operationType: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<SalesSummaryModel> getLocalSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? farmId,
  }) async {
    try {
      final query = database.select(database.sales)
        ..where((t) =>
            t.saleDate.isBiggerOrEqualValue(startDate) &
            t.saleDate.isSmallerOrEqualValue(endDate) &
            t.paymentStatus.isNotValue(PaymentStatus.cancelled.toCode()));

      final rows = await query.get();

      double totalQuantity = 0.0;
      double totalRevenue = 0.0;
      final methodBreakdown = <PaymentMethod, double>{
        PaymentMethod.cash: 0.0,
        PaymentMethod.bankTransfer: 0.0,
        PaymentMethod.credit: 0.0,
      };

      for (final row in rows) {
        totalQuantity += row.quantity;
        totalRevenue += row.totalAmount;
        final method = PaymentMethod.fromString(row.paymentMethod);
        methodBreakdown[method] = (methodBreakdown[method] ?? 0.0) + row.totalAmount;
      }

      return SalesSummaryModel(
        farmId: farmId,
        startDate: startDate,
        endDate: endDate,
        totalSalesCount: rows.length,
        totalQuantity: totalQuantity,
        totalRevenue: totalRevenue,
        paymentMethodBreakdown: methodBreakdown,
      );
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to calculate local sales summary: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<double> getLocalAvailableHarvestedInventory({String? farmId}) async {
    try {
      // Total weight harvested
      final harvestQuery = database.select(database.harvests);
      final harvestRows = await harvestQuery.get();
      double totalHarvestedWeight = 0.0;
      for (final h in harvestRows) {
        totalHarvestedWeight += h.totalWeight;
      }

      // Total quantity sold (non-cancelled)
      final salesQuery = database.select(database.sales)
        ..where((t) => t.paymentStatus.isNotValue(PaymentStatus.cancelled.toCode()));
      final salesRows = await salesQuery.get();
      double totalSoldQuantity = 0.0;
      for (final s in salesRows) {
        totalSoldQuantity += s.quantity;
      }

      return max(0.0, totalHarvestedWeight - totalSoldQuantity);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to calculate local available harvested inventory: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  Expression<bool> _buildWhereExpression(
    db.$SalesTable t,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
  ) {
    Expression<bool> expr = const Constant(true);

    if (buyerName != null && buyerName.isNotEmpty) {
      expr = expr & t.buyerName.contains(buyerName);
    }
    if (startDate != null) {
      expr = expr & t.saleDate.isBiggerOrEqualValue(startDate);
    }
    if (endDate != null) {
      expr = expr & t.saleDate.isSmallerOrEqualValue(endDate);
    }
    if (paymentMethod != null) {
      expr = expr & t.paymentMethod.equals(paymentMethod.toCode());
    }
    if (paymentStatus != null) {
      expr = expr & t.paymentStatus.equals(paymentStatus.toCode());
    }

    return expr;
  }
}
