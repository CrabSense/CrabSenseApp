import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/scan_quick_result.dart';
import '../../domain/entities/scan_result.dart';

/// Local data source for QR scanner offline queue operations.
///
/// Uses the shared Drift [AppDatabase] to persist scan results that
/// could not be processed online. Each queued scan is stored as a
/// [SyncQueueCompanion] row with:
///   - operationType: 'scan_qr'
///   - entityType:    'scan'
///   - payload:       JSON-encoded scan data (rawValue, boxId, scannedAt)
///   - priority:      1 (medium — operation logs and inspections tier)
///
/// Requirements: 3.7, 13.3–13.10
abstract class ScannerLocalDataSource {
  /// Persists [scanResult] to the local sync queue for later upload.
  Future<void> queueScan(ScanResult scanResult);

  /// Returns all scan entries whose status is 'pending' (not yet synced).
  Future<List<ScanResult>> getPendingScans();

  /// Marks the sync queue row with [scanId] as 'completed'.
  Future<void> markScanSynced(String scanId);

  /// Recent successful scans (max 10), session + memory.
  Future<List<ScanHistoryEntry>> getScanHistory();

  Future<void> saveScanHistory(ScanHistoryEntry entry);

  /// Cached quick result for offline replay by boxId.
  Future<void> cacheQuickResult(ScanQuickResult result);

  Future<ScanQuickResult?> getCachedQuickResult(String boxId);
}

/// Drift-backed implementation of [ScannerLocalDataSource].
class ScannerLocalDataSourceImpl implements ScannerLocalDataSource {
  ScannerLocalDataSourceImpl({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  static const _operationType = 'scan_qr';
  static const _entityType = 'scan';
  static const _statusPending = 'pending';
  static const _statusCompleted = 'completed';
  static const _priority = 1; // medium priority

  /// Session history (newest first), capped at 10.
  static final List<ScanHistoryEntry> _history = [];

  /// Soft cache of last quick results by boxId for offline replay.
  static final Map<String, ScanQuickResult> _quickCache = {};

  /// Generates a simple random UUID-like identifier.
  static String _generateId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  @override
  Future<void> queueScan(ScanResult scanResult) async {
    try {
      final id = scanResult.id ?? _generateId();

      final payload = jsonEncode({
        'raw_value': scanResult.rawValue,
        'box_id': scanResult.boxId,
        'scanned_at': scanResult.scannedAt.toIso8601String(),
        'is_valid': scanResult.isValid,
      });

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              id: id,
              operationType: _operationType,
              entityId: id,
              entityType: _entityType,
              payload: payload,
              createdAt: scanResult.scannedAt,
              status: const Value(_statusPending),
              priority: const Value(_priority),
            ),
          );
    } on Exception catch (e) {
      throw CacheException(message: 'Failed to queue scan locally: $e', code: 'QUEUE_WRITE_ERROR');
    }
  }

  @override
  Future<List<ScanResult>> getPendingScans() async {
    try {
      final rows =
          await (_db.select(_db.syncQueue)
                ..where(
                  (t) => t.operationType.equals(_operationType) & t.status.equals(_statusPending),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
              .get();

      return rows.map(_rowToScanResult).toList();
    } on Exception catch (e) {
      throw CacheException(message: 'Failed to read pending scans: $e', code: 'QUEUE_READ_ERROR');
    }
  }

  @override
  Future<void> markScanSynced(String scanId) async {
    try {
      await (_db.update(_db.syncQueue)..where((t) => t.id.equals(scanId))).write(
        const SyncQueueCompanion(status: Value(_statusCompleted)),
      );
    } on Exception catch (e) {
      throw CacheException(
        message: 'Failed to mark scan as synced: $e',
        code: 'QUEUE_UPDATE_ERROR',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ScanResult _rowToScanResult(SyncQueueData row) {
    try {
      final payload = jsonDecode(row.payload) as Map<String, dynamic>;

      return ScanResult(
        id: row.id,
        rawValue: payload['raw_value'] as String? ?? '',
        boxId: payload['box_id'] as String? ?? '',
        isValid: payload['is_valid'] as bool? ?? true,
        scannedAt: DateTime.tryParse(payload['scanned_at'] as String? ?? '') ?? row.createdAt,
        isSynced: row.status == _statusCompleted,
      );
    } on Exception {
      return ScanResult(
        id: row.id,
        rawValue: '',
        boxId: '',
        isValid: false,
        scannedAt: row.createdAt,
      );
    }
  }

  @override
  Future<List<ScanHistoryEntry>> getScanHistory() async =>
      List<ScanHistoryEntry>.unmodifiable(_history);

  @override
  Future<void> saveScanHistory(ScanHistoryEntry entry) async {
    _history.removeWhere((e) => e.boxId == entry.boxId && e.rawValue == entry.rawValue);
    _history.insert(0, entry);
    if (_history.length > 10) {
      _history.removeRange(10, _history.length);
    }
  }

  @override
  Future<void> cacheQuickResult(ScanQuickResult result) async {
    _quickCache[result.boxId] = result;
  }

  @override
  Future<ScanQuickResult?> getCachedQuickResult(String boxId) async =>
      _quickCache[boxId];
}
