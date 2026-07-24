// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart' as db;
import '../../core/errors/exceptions.dart';
import 'sync_queue_item.dart';

/// Contract for Sync Queue Management service.
///
/// Manages offline queue operations in the SQLite [db.SyncQueue] table.
/// Items are ordered by priority (1 critical -> 4 low) and creation timestamp.
///
/// Requirements: 13.3-13.4
abstract class SyncService {
  /// Enqueues a new operation for offline sync.
  ///
  /// Supported entity types: harvest, sale, operation_log, inspection, video, alert_ack.
  /// Priority defaults to [SyncPriority.medium] (3) if not specified.
  Future<SyncQueueItem> enqueue({
    required SyncEntityType entityType,
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
    SyncPriority priority = SyncPriority.medium,
  });

  /// Retrieves all pending items ordered by priority (1=critical first) and createdAt ASC.
  Future<List<SyncQueueItem>> getPendingItems({int limit = 50});

  /// Marks a queue item status as 'processing'.
  Future<void> markProcessing(String id);

  /// Marks a queue item status as 'completed' or deletes it from queue.
  Future<void> markCompleted(String id);

  /// Marks a queue item status as 'failed', increments retry count, and records error message.
  Future<void> markFailed(String id, String errorMessage);

  /// Returns total count of items pending sync (status = 'pending' or 'failed').
  Future<int> getPendingCount();

  /// Reactive stream for watching pending item count changes.
  Stream<int> watchPendingCount();

  /// Removes an item from the queue by ID.
  Future<void> remove(String id);

  /// Clears all entries from the sync queue.
  Future<void> clearQueue();
}

/// Implementation of [SyncService] backed by Drift SQLite database.
class SyncServiceImpl implements SyncService {
  SyncServiceImpl({
    required this.database,
    required this.logger,
  });

  final db.AppDatabase database;
  final Logger logger;
  static const _uuid = Uuid();

  @override
  Future<SyncQueueItem> enqueue({
    required SyncEntityType entityType,
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
    SyncPriority priority = SyncPriority.medium,
  }) async {
    try {
      final item = SyncQueueItem(
        id: _uuid.v4(),
        operationType: operationType,
        entityId: entityId,
        entityType: entityType,
        payload: payload,
        createdAt: DateTime.now(),
        retryCount: 0,
        status: SyncItemStatus.pending,
        priority: priority,
      );

      final companion = item.toDriftCompanion();
      await database.into(database.syncQueue).insert(companion);

      logger.d(
        'SyncService: Enqueued ${entityType.code} item (id=${item.id}, priority=${priority.value})',
      );

      return item;
    } on Exception catch (e) {
      logger.e('SyncService: Failed to enqueue sync item: $e');
      throw CacheException(
        message: 'Failed to enqueue sync item: $e',
        code: 'SYNC_QUEUE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<List<SyncQueueItem>> getPendingItems({int limit = 50}) async {
    try {
      final query = database.select(database.syncQueue)
        ..where((t) => t.status.equals(SyncItemStatus.pending.code) | t.status.equals(SyncItemStatus.failed.code))
        ..orderBy([
          (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.asc),
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
        ])
        ..limit(limit);

      final rows = await query.get();
      return rows.map(SyncQueueItem.fromDrift).toList(growable: false);
    } on Exception catch (e) {
      logger.e('SyncService: Failed to fetch pending sync items: $e');
      throw CacheException(
        message: 'Failed to fetch pending sync items: $e',
        code: 'SYNC_QUEUE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> markProcessing(String id) async {
    try {
      await (database.update(database.syncQueue)..where((t) => t.id.equals(id))).write(
        db.SyncQueueCompanion(
          status: Value(SyncItemStatus.processing.code),
          lastAttemptAt: Value(DateTime.now()),
        ),
      );
      logger.d('SyncService: Marked item $id as processing');
    } on Exception catch (e) {
      logger.e('SyncService: Failed to mark item $id as processing: $e');
      throw CacheException(
        message: 'Failed to update item status: $e',
        code: 'SYNC_QUEUE_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<void> markCompleted(String id) async {
    try {
      // Remove completed item from queue to prevent queue bloat
      await (database.delete(database.syncQueue)..where((t) => t.id.equals(id))).go();
      logger.d('SyncService: Marked item $id as completed (removed from queue)');
    } on Exception catch (e) {
      logger.e('SyncService: Failed to mark item $id as completed: $e');
      throw CacheException(
        message: 'Failed to mark item completed: $e',
        code: 'SYNC_QUEUE_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<void> markFailed(String id, String errorMessage) async {
    try {
      final query = database.select(database.syncQueue)..where((t) => t.id.equals(id));
      final rows = await query.get();

      if (rows.isEmpty) return;

      final currentItem = rows.first;
      final newRetryCount = currentItem.retryCount + 1;

      await (database.update(database.syncQueue)..where((t) => t.id.equals(id))).write(
        db.SyncQueueCompanion(
          status: Value(SyncItemStatus.failed.code),
          retryCount: Value(newRetryCount),
          errorMessage: Value(errorMessage),
          lastAttemptAt: Value(DateTime.now()),
        ),
      );

      logger.w(
        'SyncService: Marked item $id as failed (retryCount=$newRetryCount, error=$errorMessage)',
      );
    } on Exception catch (e) {
      logger.e('SyncService: Failed to mark item $id as failed: $e');
      throw CacheException(
        message: 'Failed to mark item failed: $e',
        code: 'SYNC_QUEUE_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<int> getPendingCount() async {
    try {
      final query = database.select(database.syncQueue)
        ..where((t) => t.status.equals(SyncItemStatus.pending.code) | t.status.equals(SyncItemStatus.failed.code));
      final rows = await query.get();
      return rows.length;
    } on Exception catch (e) {
      logger.e('SyncService: Failed to get pending count: $e');
      return 0;
    }
  }

  @override
  Stream<int> watchPendingCount() {
    final query = database.select(database.syncQueue)
      ..where((t) => t.status.equals(SyncItemStatus.pending.code) | t.status.equals(SyncItemStatus.failed.code));
    return query.watch().map((rows) => rows.length);
  }

  @override
  Future<void> remove(String id) async {
    try {
      await (database.delete(database.syncQueue)..where((t) => t.id.equals(id))).go();
      logger.d('SyncService: Removed item $id from queue');
    } on Exception catch (e) {
      logger.e('SyncService: Failed to remove item $id: $e');
      throw CacheException(
        message: 'Failed to remove queue item: $e',
        code: 'SYNC_QUEUE_DELETE_ERROR',
      );
    }
  }

  @override
  Future<void> clearQueue() async {
    try {
      await database.delete(database.syncQueue).go();
      logger.i('SyncService: Sync queue cleared');
    } on Exception catch (e) {
      logger.e('SyncService: Failed to clear sync queue: $e');
      throw CacheException(
        message: 'Failed to clear sync queue: $e',
        code: 'SYNC_QUEUE_DELETE_ERROR',
      );
    }
  }
}
