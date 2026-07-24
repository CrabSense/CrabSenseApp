// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart' as db hide Inspection;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/inspection.dart';
import '../models/inspection_model.dart';

/// Contract for local inspection cache operations via Drift / SQLite.
///
/// All methods throw [CacheException] on storage failures.
///
/// Requirements: 7.7, 13.3-13.4
abstract class InspectionLocalDataSource {
  /// Inserts or replaces a single inspection record in the local database.
  ///
  /// Pass `isDirty: true` to flag the record as awaiting remote sync.
  ///
  /// Requirements: 7.7
  Future<void> saveInspection(Inspection inspection, {bool isDirty = false});

  /// Returns all inspection records for the given box, newest first.
  ///
  /// Returns an empty list when no records are cached.
  ///
  /// Requirements: 7.10
  Future<List<InspectionModel>> getInspections(String boxId);

  /// Returns a single inspection record by its ID.
  ///
  /// Throws [CacheException] with code `INSPECTION_NOT_FOUND` when no match.
  ///
  /// Requirements: 7.10
  Future<InspectionModel> getInspectionById(String inspectionId);

  /// Marks an inspection record as successfully synced with the remote server.
  ///
  /// Updates [SyncStatus] to [SyncStatus.synced] and clears the dirty flag.
  ///
  /// Requirements: 13.5-13.6
  Future<void> markAsSynced(String inspectionId);

  /// Marks an inspection record as having failed its last sync attempt.
  ///
  /// Updates [SyncStatus] to [SyncStatus.failed] for later retry.
  ///
  /// Requirements: 13.7
  Future<void> markAsFailed(String inspectionId);

  /// Returns all inspection records that have not yet been uploaded to the
  /// server (syncStatus == 'pending' or syncStatus == 'failed').
  ///
  /// Results are ordered chronologically (oldest first) so the sync service
  /// processes them in the correct sequence (Requirement 13.6).
  ///
  /// Requirements: 13.5-13.7
  Future<List<InspectionModel>> getPendingSyncInspections();

  /// Returns the total number of inspections and how many had aiAgreement==true
  /// for the given box, as a `(total, agreed)` record.
  ///
  /// Used to compute the agreement rate (Requirement 7.8).
  Future<({int total, int agreed})> getAgreementCounts(String boxId);

  /// Removes inspection records older than [retentionDays] days from the
  /// local cache to enforce the 30-day data retention policy (Req 23.6).
  Future<void> evictStaleRecords({int retentionDays = 30});

  /// Saves a pending AI feedback record to the SyncQueue table for offline
  /// queuing (Requirement 7.7, 13.4).
  ///
  /// The feedback will be uploaded to the AI service when connectivity is
  /// restored via [syncPendingFeedback].
  Future<void> savePendingFeedback(InspectionFeedback feedback);

  /// Returns all pending AI feedback records from the SyncQueue table.
  ///
  /// Results are ordered chronologically (oldest first) so the sync service
  /// processes them in the correct sequence (Requirement 13.6).
  Future<List<InspectionFeedback>> getPendingFeedbacks();

  /// Removes a feedback record from the SyncQueue after successful upload.
  ///
  /// The [inspectionId] uniquely identifies the feedback record.
  Future<void> removePendingFeedback(String inspectionId);
}

/// Drift-backed implementation of [InspectionLocalDataSource].
class InspectionLocalDataSourceImpl implements InspectionLocalDataSource {
  InspectionLocalDataSourceImpl({required this.database});

  final db.AppDatabase database;

  // ──────────────────────────────────────────────────────────────────────────
  // InspectionLocalDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveInspection(Inspection inspection, {bool isDirty = false}) async {
    try {
      final companion = InspectionModel.fromEntity(inspection).toDriftCompanion(isDirty: isDirty);
      await database.into(database.inspections).insertOnConflictUpdate(companion);
    } catch (e) {
      throw CacheException(
        message: 'Failed to save inspection to local cache: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<List<InspectionModel>> getInspections(String boxId) async {
    try {
      final rows =
          await (database.select(database.inspections)
                ..where((t) => t.boxId.equals(boxId))
                ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
              .get();

      return rows.map(_rowToModel).toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read inspections from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<InspectionModel> getInspectionById(String inspectionId) async {
    try {
      final row = await (database.select(
        database.inspections,
      )..where((t) => t.id.equals(inspectionId))).getSingleOrNull();

      if (row == null) {
        throw CacheException(
          message: 'No cached inspection found with id: $inspectionId',
          code: 'INSPECTION_NOT_FOUND',
        );
      }

      return _rowToModel(row);
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read inspection from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> markAsSynced(String inspectionId) async {
    try {
      await (database.update(database.inspections)..where((t) => t.id.equals(inspectionId))).write(
        db.InspectionsCompanion(
          syncStatus: const Value('synced'),
          isDirty: const Value(false),
          syncedAt: Value(DateTime.now().toUtc()),
        ),
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to mark inspection as synced: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> markAsFailed(String inspectionId) async {
    try {
      await (database.update(database.inspections)..where((t) => t.id.equals(inspectionId))).write(
        const db.InspectionsCompanion(syncStatus: Value('failed')),
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to mark inspection sync as failed: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<List<InspectionModel>> getPendingSyncInspections() async {
    try {
      final rows =
          await (database.select(database.inspections)
                ..where((t) => t.syncStatus.equals('pending') | t.syncStatus.equals('failed'))
                ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
              .get();

      return rows.map(_rowToModel).toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read pending sync inspections: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<({int total, int agreed})> getAgreementCounts(String boxId) async {
    try {
      // Only count inspections that have an AI agreement value recorded.
      final rows = await (database.select(
        database.inspections,
      )..where((t) => t.boxId.equals(boxId) & t.aiAgreement.isNotNull())).get();

      final total = rows.length;
      final agreed = rows.where((r) => r.aiAgreement == true).length;
      return (total: total, agreed: agreed);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read agreement counts from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> evictStaleRecords({int retentionDays = 30}) async {
    try {
      final cutoff = DateTime.now().toUtc().subtract(Duration(days: retentionDays));

      await (database.delete(database.inspections)..where(
            (t) =>
                // Only evict records that are already synced and old.
                t.syncStatus.equals('synced') & t.cachedAt.isSmallerThanValue(cutoff),
          ))
          .go();
    } catch (e) {
      throw CacheException(
        message: 'Failed to evict stale inspection records: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> savePendingFeedback(InspectionFeedback feedback) async {
    try {
      final id = '${feedback.inspectionId}_feedback';
      final payloadJson = InspectionFeedbackModel.fromEntity(feedback).toJson();
      final payloadEncoded = jsonEncode(payloadJson);

      final companion = db.SyncQueueCompanion(
        id: Value(id),
        operationType: const Value('submit_ai_feedback'),
        entityId: Value(feedback.inspectionId),
        entityType: const Value('inspection'),
        payload: Value(payloadEncoded),
        createdAt: Value(DateTime.now().toUtc()),
        status: const Value('pending'),
        priority: const Value(1),
      );

      await database.into(database.syncQueue).insertOnConflictUpdate(companion);
    } catch (e) {
      throw CacheException(
        message: 'Failed to save pending feedback: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<List<InspectionFeedback>> getPendingFeedbacks() async {
    try {
      final rows =
          await (database.select(database.syncQueue)
                ..where(
                  (t) =>
                      t.operationType.equals('submit_ai_feedback') &
                      (t.status.equals('pending') | t.status.equals('failed')),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
              .get();

      return rows
          .map((row) {
            try {
              // Parse the JSON payload back to InspectionFeedback.
              final payloadStr = row.payload;
              final payloadMap = jsonDecode(payloadStr) as Map<String, dynamic>;
              final model = InspectionFeedbackModel.fromJson(payloadMap);
              return model.toEntity();
            } catch (e) {
              // Skip malformed payload.
              return null;
            }
          })
          .whereType<InspectionFeedback>()
          .toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read pending feedbacks: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> removePendingFeedback(String inspectionId) async {
    try {
      final id = '${inspectionId}_feedback';
      await (database.delete(database.syncQueue)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw CacheException(
        message: 'Failed to remove pending feedback: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Maps a raw Drift data-class row to an [InspectionModel].
  ///
  /// The parameter is typed as [dynamic] to avoid a naming collision between
  /// the Drift-generated `Inspection` row class and the domain entity
  /// `Inspection`. Dart will still resolve the field accesses at compile time.
  // ignore: avoid_dynamic_calls
  InspectionModel _rowToModel(row) => InspectionModel.fromDrift(
    id: row.id as String,
    boxId: row.boxId as String,
    relatedVideoId: row.relatedVideoId as String?,
    moltingStatus: row.moltingStatus as String,
    healthStatus: row.healthStatus as String,
    weight: row.weight as double,
    notes: row.notes as String,
    photoUrlsJson: row.photoUrls as String,
    timestamp: row.timestamp as DateTime,
    operatorId: row.operatorId as String,
    operatorName: row.operatorName as String,
    aiAgreement: row.aiAgreement as bool?,
    syncStatus: row.syncStatus as String,
  );
}
