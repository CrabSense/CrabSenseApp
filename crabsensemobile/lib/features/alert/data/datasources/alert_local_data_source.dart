// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_enums.dart';
import '../../domain/repositories/alert_repository.dart' show AlertFilters;
import '../models/alert_model.dart';

/// Contract for alert cache operations on the local database.
///
/// All reads and writes go through the Drift SQLite database.
/// Enforces a 30-day retention policy: records older than 30 days are
/// deleted on every cache write to keep storage manageable
/// (Requirement 9.9).
///
/// Throws [CacheException] on any storage failure.
///
/// Requirements: 9.1-9.10
abstract class AlertLocalDataSource {
  /// Returns cached alerts, optionally filtered by severity, type, or status.
  ///
  /// Results are sorted by createdAt descending (newest first).
  ///
  /// Requirements: 9.4, 9.8, 9.9, 9.10
  Future<List<AlertModel>> getCachedAlerts({AlertFilters? filters});

  /// Returns a single cached alert by ID, or null if not found.
  ///
  /// Requirements: 9.5, 9.10
  Future<AlertModel?> getCachedAlertById(String alertId);

  /// Persists a batch of fresh alerts to the local database.
  ///
  /// Uses insert-or-replace semantics so existing rows are updated.
  /// Also triggers the 30-day retention cleanup (Requirement 9.9).
  ///
  /// Requirements: 9.9, 9.10
  Future<void> cacheAlerts(List<Alert> alerts);

  /// Updates the status fields of a cached alert in-place.
  ///
  /// Used when an acknowledge/dismiss action succeeds either online or
  /// offline. Sets isDirty to false after a successful server sync.
  ///
  /// Requirements: 9.6, 9.7
  Future<void> updateAlertStatus({
    required String alertId,
    required String status,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
  });

  /// Returns the count of alerts currently in unread status.
  ///
  /// Requirements: 9.2
  Future<int> getCachedUnreadCount();

  /// Deletes all alert records older than 30 days.
  ///
  /// Called automatically by [cacheAlerts] to enforce retention policy.
  ///
  /// Requirements: 9.9
  Future<void> deleteOldAlerts();

  /// Returns a live stream of cached alerts, re-emitting on table changes.
  ///
  /// Requirements: 9.4, 9.10
  Stream<List<AlertModel>> watchAlerts({AlertFilters? filters});

  /// Returns a live stream of the unread alert count.
  ///
  /// Emits the current count immediately and on every table change.
  /// Used to keep the navigation badge in sync (Requirement 9.2).
  ///
  /// Requirements: 9.2
  Stream<int> watchUnreadCount();

  /// Queues an alert action (acknowledge/dismiss) in the SyncQueue table
  /// for deferred upload when connectivity is restored.
  ///
  /// [operationType] is a string like "acknowledge_alert" or "dismiss_alert".
  /// [payload] is the action-specific data that will be replayed to the server.
  ///
  /// Priority is set to 3 (critical) because alerts require timely sync
  /// (Requirement 9.10).
  ///
  /// Requirements: 9.10
  Future<void> queueAlertAction({
    required String operationType,
    required String alertId,
    required Map<String, dynamic> payload,
  });
}

/// Drift-based implementation of [AlertLocalDataSource].
class AlertLocalDataSourceImpl implements AlertLocalDataSource {
  AlertLocalDataSourceImpl({required this.database});

  final db.AppDatabase database;

  /// 30-day retention window for alert history (Requirement 9.9).
  static const Duration _retentionPeriod = Duration(days: 30);

  static const _uuid = Uuid();

  // ──────────────────────────────────────────────────────────────────────────
  // AlertLocalDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<AlertModel>> getCachedAlerts({AlertFilters? filters}) async {
    try {
      final query = database.select(database.alerts)
        ..where((t) => _buildWhereExpression(t, filters))
        ..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]);

      final rows = await query.get();
      return rows.map(AlertModel.fromDrift).toList(growable: false);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read cached alerts: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<AlertModel?> getCachedAlertById(String alertId) async {
    try {
      final query = database.select(database.alerts)
        ..where((t) => t.id.equals(alertId))
        ..limit(1);

      final rows = await query.get();
      if (rows.isEmpty) {
        return null;
      }
      return AlertModel.fromDrift(rows.first);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read cached alert $alertId: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> cacheAlerts(List<Alert> alerts) async {
    try {
      await database.transaction(() async {
        for (final alert in alerts) {
          final companion = AlertModel.fromEntity(alert).toDriftCompanion();
          await database
              .into(database.alerts)
              .insertOnConflictUpdate(companion);
        }
        // Enforce 30-day retention after every batch write.
        await deleteOldAlerts();
      });
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to cache alerts: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> updateAlertStatus({
    required String alertId,
    required String status,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
  }) async {
    try {
      await (database.update(
        database.alerts,
      )..where((t) => t.id.equals(alertId))).write(
        db.AlertsCompanion(
          status: Value(status),
          acknowledgedAt: Value(acknowledgedAt),
          acknowledgedBy: Value(acknowledgedBy),
          // isDirty = false: local is now in sync with server action.
          isDirty: const Value(false),
        ),
      );
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to update status for alert $alertId: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<int> getCachedUnreadCount() async {
    try {
      final query = database.select(database.alerts)
        ..where((t) => t.status.equals('unread'));
      final rows = await query.get();
      return rows.length;
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to read unread alert count: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> deleteOldAlerts() async {
    try {
      final cutoff = DateTime.now().subtract(_retentionPeriod);
      await (database.delete(
        database.alerts,
      )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to delete old alerts: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Stream<List<AlertModel>> watchAlerts({AlertFilters? filters}) {
    final query = database.select(database.alerts)
      ..where((t) => _buildWhereExpression(t, filters))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map(
      (rows) => rows.map(AlertModel.fromDrift).toList(growable: false),
    );
  }

  @override
  Stream<int> watchUnreadCount() {
    final query = database.select(database.alerts)
      ..where((t) => t.status.equals('unread'));
    return query.watch().map((rows) => rows.length);
  }

  @override
  Future<void> queueAlertAction({
    required String operationType,
    required String alertId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final companion = db.SyncQueueCompanion(
        id: Value(_uuid.v4()),
        operationType: Value(operationType),
        entityId: Value(alertId),
        entityType: const Value('alert'),
        payload: Value(jsonEncode(payload)),
        createdAt: Value(DateTime.now()),
        retryCount: const Value(0),
        status: const Value('pending'),
        // Priority 3 = critical — alerts require timely sync (Req 9.10).
        priority: const Value(3),
      );
      await database.into(database.syncQueue).insert(companion);
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to queue alert action $operationType: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Builds a Drift WHERE expression from an [AlertFilters] object.
  ///
  /// Returns a tautology (1=1 equivalent) when filters is null or empty.
  Expression<bool> _buildWhereExpression(
    db.$AlertsTable t,
    AlertFilters? filters,
  ) {
    if (filters == null || filters.isEmpty) {
      return const Constant(true);
    }

    Expression<bool> expr = const Constant(true);

    if (filters.severity != null) {
      expr = expr & t.severity.equals(_severityName(filters.severity!));
    }
    if (filters.type != null) {
      expr = expr & t.type.equals(_typeName(filters.type!));
    }
    if (filters.status != null) {
      expr = expr & t.status.equals(_statusName(filters.status!));
    }

    return expr;
  }

  String _severityName(AlertSeverity severity) => severity.name;

  String _typeName(AlertType type) => type.name;

  String _statusName(AlertStatus status) => status.name;
}
