// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/harvest.dart';
import '../models/harvest_model.dart';

/// Contract for harvest record caching and local database operations.
///
/// All operations interact directly with the Drift SQLite database.
///
/// Throws [CacheException] on storage failure.
///
/// Requirements: 11.1-11.10
abstract class HarvestLocalDataSource {
  /// Returns cached harvest records with optional filters and pagination.
  ///
  /// Requirements: 11.9
  Future<List<HarvestModel>> getCachedHarvestHistory({
    String? farmId,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
    int page = 1,
    int pageSize = 50,
  });

  /// Returns a single cached harvest record by ID, or null if not found.
  Future<HarvestModel?> getCachedHarvestById(String id);

  /// Persists a batch of remote harvest records locally.
  Future<void> cacheHarvests(List<Harvest> harvests);

  /// Creates a new harvest record in local storage (`isDirty = true`).
  ///
  /// Requirements: 11.7, 11.8
  Future<HarvestModel> createLocalHarvest(HarvestModel model);

  /// Returns all unsynced harvest records (`isDirty = true`).
  Future<List<HarvestModel>> getUnsyncedHarvests();

  /// Marks a harvest record as synced (`isDirty = false`, updates `syncedAt`).
  Future<void> markAsSynced(String id);

  /// Queues a harvest action in the [SyncQueue] table for offline sync.
  ///
  /// Requirements: 11.8
  Future<void> queueHarvestAction({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
  });

  /// Updates box inventory by reducing crab count (Requirement 11.4).
  Future<void> updateBoxCrabCountAfterHarvest({
    required String boxId,
    required int harvestedCount,
  });

  /// Calculates cumulative harvest metrics for a farm locally.
  ///
  /// Requirements: 11.10
  Future<HarvestSummaryModel> getLocalHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// Drift-backed implementation of [HarvestLocalDataSource].
class HarvestLocalDataSourceImpl implements HarvestLocalDataSource {
  HarvestLocalDataSourceImpl({required this.database});

  final db.AppDatabase database;

  static const _uuid = Uuid();

  @override
  Future<List<HarvestModel>> getCachedHarvestHistory({
    String? farmId,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final offset = (page - 1) * pageSize;

      final query = database.select(database.harvests)
        ..where((t) => _buildWhereExpression(t, boxId, startDate, endDate, qualityGrade))
        ..orderBy([(t) => OrderingTerm(expression: t.harvestDate, mode: OrderingMode.desc)])
        ..limit(pageSize, offset: offset);

      final rows = await query.get();
      return rows.map((r) => HarvestModel.fromDrift(r, farmId: farmId)).toList(growable: false);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read cached harvest history: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<HarvestModel?> getCachedHarvestById(String id) async {
    try {
      final query = database.select(database.harvests)
        ..where((t) => t.id.equals(id))
        ..limit(1);

      final rows = await query.get();
      if (rows.isEmpty) return null;
      return HarvestModel.fromDrift(rows.first);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read cached harvest $id: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> cacheHarvests(List<Harvest> harvests) async {
    try {
      await database.transaction(() async {
        final now = DateTime.now();
        for (final harvest in harvests) {
          final model = HarvestModel.fromEntity(harvest, isDirty: false, syncedAt: now);
          final companion = model.toDriftCompanion();
          await database.into(database.harvests).insertOnConflictUpdate(companion);
        }
      });
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to cache harvest records: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<HarvestModel> createLocalHarvest(HarvestModel model) async {
    try {
      final dirtyModel = model.copyWith(isDirty: true);
      final companion = dirtyModel.toDriftCompanion();
      await database.transaction(() async {
        await database.into(database.harvests).insert(companion);
        await updateBoxCrabCountAfterHarvest(
          boxId: model.boxId,
          harvestedCount: model.crabCount,
        );
      });
      return dirtyModel;
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to create local harvest record: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<List<HarvestModel>> getUnsyncedHarvests() async {
    try {
      final query = database.select(database.harvests)
        ..where((t) => t.isDirty.equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.harvestDate, mode: OrderingMode.asc)]);

      final rows = await query.get();
      return rows.map((r) => HarvestModel.fromDrift(r)).toList(growable: false);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read unsynced harvest records: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> markAsSynced(String id) async {
    try {
      await (database.update(database.harvests)..where((t) => t.id.equals(id))).write(
        db.HarvestsCompanion(
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to mark harvest $id as synced: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> queueHarvestAction({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final companion = db.SyncQueueCompanion(
        id: Value(_uuid.v4()),
        operationType: Value(operationType),
        entityId: Value(entityId),
        entityType: const Value('harvest'),
        payload: Value(jsonEncode(payload)),
        createdAt: Value(DateTime.now()),
        retryCount: const Value(0),
        status: const Value('pending'),
        priority: const Value(1),
      );
      await database.into(database.syncQueue).insert(companion);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to queue harvest action $operationType: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> updateBoxCrabCountAfterHarvest({
    required String boxId,
    required int harvestedCount,
  }) async {
    try {
      final query = database.select(database.boxes)..where((t) => t.id.equals(boxId));
      final rows = await query.get();

      if (rows.isNotEmpty) {
        final box = rows.first;
        final newCount = max(0, box.currentCrabCount - harvestedCount);
        final newStatus = newCount == 0 ? 'harvested' : box.status;

        await (database.update(database.boxes)..where((t) => t.id.equals(boxId))).write(
          db.BoxesCompanion(
            currentCrabCount: Value(newCount),
            status: Value(newStatus),
            isDirty: const Value(true),
          ),
        );
      }
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to update box crab count for box $boxId: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<HarvestSummaryModel> getLocalHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = database.select(database.harvests)
        ..where((t) => t.harvestDate.isBiggerOrEqualValue(startDate) & t.harvestDate.isSmallerOrEqualValue(endDate));

      final rows = await query.get();

      double totalWeight = 0.0;
      int totalCrabCount = 0;
      final gradeBreakdown = <QualityGrade, double>{
        QualityGrade.gradeA: 0.0,
        QualityGrade.gradeB: 0.0,
        QualityGrade.gradeC: 0.0,
      };

      for (final row in rows) {
        totalWeight += row.totalWeight;
        totalCrabCount += row.crabCount;
        final grade = QualityGrade.fromString(row.qualityGrade);
        gradeBreakdown[grade] = (gradeBreakdown[grade] ?? 0.0) + row.totalWeight;
      }

      return HarvestSummaryModel(
        farmId: farmId,
        startDate: startDate,
        endDate: endDate,
        totalWeight: totalWeight,
        totalCrabCount: totalCrabCount,
        totalHarvestsCount: rows.length,
        gradeBreakdown: gradeBreakdown,
      );
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to calculate local harvest summary for farm $farmId: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  Expression<bool> _buildWhereExpression(
    db.$HarvestsTable t,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
  ) {
    Expression<bool> expr = const Constant(true);

    if (boxId != null && boxId.isNotEmpty) {
      expr = expr & t.boxId.equals(boxId);
    }
    if (startDate != null) {
      expr = expr & t.harvestDate.isBiggerOrEqualValue(startDate);
    }
    if (endDate != null) {
      expr = expr & t.harvestDate.isSmallerOrEqualValue(endDate);
    }
    if (qualityGrade != null) {
      expr = expr & t.qualityGrade.equals(qualityGrade.toCode());
    }

    return expr;
  }
}
