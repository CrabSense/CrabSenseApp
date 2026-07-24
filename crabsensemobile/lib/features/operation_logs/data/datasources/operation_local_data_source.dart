// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/operation_log.dart';
import '../../domain/entities/operation_type.dart';
import '../models/operation_log_model.dart';

/// Contract for operation log cache operations on the local database.
///
/// All reads and writes go through the Drift SQLite database.
/// The offline-first strategy requires every create/update to persist
/// locally first with [isDirty] = true, then be synced to the server.
///
/// Throws [CacheException] on any storage failure.
///
/// Requirements: 10.1-10.10
abstract class OperationLocalDataSource {
  /// Returns cached operation logs for a specific box.
  ///
  /// Results are sorted by timestamp descending (newest first).
  /// Supports optional date-range and type filtering (Requirement 10.8).
  ///
  /// Requirements: 10.4, 10.7, 10.8
  Future<List<OperationLogModel>> getCachedOperationLogs(
    String boxId, {
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
    int page = 1,
    int pageSize = 50,
  });

  /// Returns a single cached operation log by ID, or null if not found.
  ///
  /// Requirements: 10.9
  Future<OperationLogModel?> getCachedOperationLogById(String id);

  /// Persists a batch of remote operation logs to the local database.
  ///
  /// Uses insert-or-replace semantics so existing rows are updated.
  /// Sets [isDirty] = false and records [syncedAt] for all cached rows.
  ///
  /// Requirements: 10.7
  Future<void> cacheOperationLogs(List<OperationLog> logs);

  /// Creates a new operation log record in the local database.
  ///
  /// Sets [isDirty] = true so the sync service will upload this record.
  ///
  /// Requirements: 10.6, 10.7
  Future<OperationLogModel> createLocalOperationLog(OperationLogModel model);

  /// Updates an existing operation log in the local database.
  ///
  /// Sets [isDirty] = true so the sync service will upload the change.
  /// Editing is only permitted within 24 hours of creation (Req 10.9);
  /// callers should enforce this rule via [OperationLog.isEditable].
  ///
  /// Requirements: 10.9
  Future<OperationLogModel> updateLocalOperationLog(OperationLogModel model);

  /// Returns all locally created or modified logs not yet synced.
  ///
  /// Used by the sync service to identify pending uploads (Req 10.6).
  ///
  /// Requirements: 10.6, 10.7
  Future<List<OperationLogModel>> getUnsyncedOperationLogs();

  /// Marks a log as synced by clearing [isDirty] and setting [syncedAt].
  ///
  /// Called by the sync service after a successful server upload.
  ///
  /// Requirements: 10.6
  Future<void> markAsSynced(String id);

  /// Queues an operation log action in the SyncQueue table for deferred
  /// upload when connectivity is restored.
  ///
  /// [operationType] is a string such as "create_operation_log" or
  /// "update_operation_log". [payload] is the serialised action data.
  ///
  /// Priority is set to 1 (medium) matching design section 4.1.
  ///
  /// Requirements: 10.7
  Future<void> queueOperationLogAction({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
  });
}

/// Drift-based implementation of [OperationLocalDataSource].
class OperationLocalDataSourceImpl implements OperationLocalDataSource {
  OperationLocalDataSourceImpl({required this.database});

  final db.AppDatabase database;

  static const _uuid = Uuid();

  // ──────────────────────────────────────────────────────────────────────────
  // OperationLocalDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<OperationLogModel>> getCachedOperationLogs(
    String boxId, {
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final offset = (page - 1) * pageSize;

      final query = database.select(database.operationLogs)
        ..where((t) => _buildWhereExpression(t, boxId, startDate, endDate, type))
        ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
        ..limit(pageSize, offset: offset);

      final rows = await query.get();
      return rows.map(OperationLogModel.fromDrift).toList(growable: false);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read cached operation logs: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<OperationLogModel?> getCachedOperationLogById(String id) async {
    try {
      final query = database.select(database.operationLogs)
        ..where((t) => t.id.equals(id))
        ..limit(1);

      final rows = await query.get();
      if (rows.isEmpty) return null;
      return OperationLogModel.fromDrift(rows.first);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read cached operation log $id: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> cacheOperationLogs(List<OperationLog> logs) async {
    try {
      await database.transaction(() async {
        final now = DateTime.now();
        for (final log in logs) {
          // Mark as clean since these come directly from the server.
          final model = OperationLogModel.fromEntity(log, isDirty: false, syncedAt: now);
          final companion = model.toDriftCompanion();
          await database.into(database.operationLogs).insertOnConflictUpdate(companion);
        }
      });
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to cache operation logs: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<OperationLogModel> createLocalOperationLog(OperationLogModel model) async {
    try {
      // Ensure the model is marked dirty for the sync service.
      final dirtyModel = model.copyWith(isDirty: true);
      final companion = dirtyModel.toDriftCompanion();
      await database.into(database.operationLogs).insert(companion);
      return dirtyModel;
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to create local operation log: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<OperationLogModel> updateLocalOperationLog(OperationLogModel model) async {
    try {
      // Mark dirty so the sync service will push this update.
      final dirtyModel = model.copyWith(isDirty: true, syncedAt: null);
      final companion = dirtyModel.toDriftCompanion();
      await (database.update(
        database.operationLogs,
      )..where((t) => t.id.equals(model.id))).write(companion);
      return dirtyModel;
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to update local operation log ${model.id}: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<List<OperationLogModel>> getUnsyncedOperationLogs() async {
    try {
      final query = database.select(database.operationLogs)
        ..where((t) => t.isDirty.equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)]);

      final rows = await query.get();
      return rows.map(OperationLogModel.fromDrift).toList(growable: false);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read unsynced operation logs: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> markAsSynced(String id) async {
    try {
      await (database.update(database.operationLogs)..where((t) => t.id.equals(id))).write(
        db.OperationLogsCompanion(isDirty: const Value(false), syncedAt: Value(DateTime.now())),
      );
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to mark operation log $id as synced: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> queueOperationLogAction({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final companion = db.SyncQueueCompanion(
        id: Value(_uuid.v4()),
        operationType: Value(operationType),
        entityId: Value(entityId),
        entityType: const Value('operationLog'),
        payload: Value(jsonEncode(payload)),
        createdAt: Value(DateTime.now()),
        retryCount: const Value(0),
        status: const Value('pending'),
        // Priority 1 = medium — operation logs per design section 4.1.
        priority: const Value(1),
      );
      await database.into(database.syncQueue).insert(companion);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to queue operation log action $operationType: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Builds a Drift WHERE expression from optional filter parameters.
  ///
  /// The OperationLogs table stores box IDs as a JSON array in the [boxIds]
  /// column, so box filtering uses a LIKE query against the serialised value.
  Expression<bool> _buildWhereExpression(
    db.$OperationLogsTable t,
    String boxId,
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
  ) {
    // Filter by box ID: the JSON array contains the quoted string.
    Expression<bool> expr = t.boxIds.like('%"$boxId"%');

    if (startDate != null) {
      expr = expr & t.timestamp.isBiggerOrEqualValue(startDate);
    }
    if (endDate != null) {
      expr = expr & t.timestamp.isSmallerOrEqualValue(endDate);
    }
    if (type != null) {
      expr = expr & t.type.equals(type.name);
    }

    return expr;
  }
}
