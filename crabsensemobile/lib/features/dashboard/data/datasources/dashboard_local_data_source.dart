// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/dashboard_summary_model.dart';

/// Contract for caching and retrieving dashboard data locally.
abstract class DashboardLocalDataSource {
  /// Returns the most recently cached [DashboardSummaryModel].
  ///
  /// Throws [CacheException] if no cached data exists or the read fails.
  Future<DashboardSummaryModel> getCachedDashboardSummary();

  /// Persists a [DashboardSummaryModel] to local storage.
  ///
  /// Throws [CacheException] if the write fails.
  Future<void> cacheDashboardSummary(DashboardSummaryModel summary);
}

/// Drift-backed implementation that derives dashboard data from the
/// local database tables already populated by other features.
///
/// Cache strategy:
/// - **Write path** (`cacheDashboardSummary`): serialises the full model to
///   JSON and upserts it into a SyncQueue row with
///   `operationType = 'cache_blob'`.
/// - **Read path** (`getCachedDashboardSummary`): reads the stored JSON blob
///   and returns it as a [DashboardSummaryModel] with `isFromCache = true`.
///
/// If no persisted JSON blob exists, the method falls back to assembling a
/// best-effort summary from the raw Drift tables (Alerts, Boxes,
/// WaterQualityReadings, Harvests). This keeps the offline experience working
/// even before the first successful network fetch.
///
/// Requirements: 2.6, 2.10
class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  DashboardLocalDataSourceImpl({required AppDatabase database, required this._logger})
    : _db = database;

  final AppDatabase _db;
  final Logger _logger;

  /// Sentinel row key used in the dashboard_cache table.
  static const String _cacheKey = 'dashboard_summary_v1';

  // ─────────────────────────────────────────────────────────────────────────
  // Read
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<DashboardSummaryModel> getCachedDashboardSummary() async {
    _logger.d('DashboardLocalDataSource: reading cached summary');

    try {
      // 1. Try the JSON blob cache first (fastest path).
      final blob = await _readCachedBlob();
      if (blob != null) {
        _logger.d('DashboardLocalDataSource: found JSON blob cache');
        return blob.copyWithIsFromCache(isFromCache: true);
      }

      // 2. Assemble from raw tables as a best-effort fallback.
      _logger.d('DashboardLocalDataSource: no blob cache — assembling from tables');
      return _assembleFromTables();
    } catch (e) {
      _logger.e('DashboardLocalDataSource: read failed — $e');
      throw CacheException(
        message: 'Failed to read cached dashboard data: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Write
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> cacheDashboardSummary(DashboardSummaryModel summary) async {
    _logger.d('DashboardLocalDataSource: caching summary');

    try {
      final jsonBlob = jsonEncode(summary.toJson());
      await _writeCachedBlob(jsonBlob);
      _logger.d('DashboardLocalDataSource: cache write succeeded');
    } catch (e) {
      _logger.e('DashboardLocalDataSource: write failed — $e');
      throw CacheException(
        message: 'Failed to cache dashboard data: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // JSON blob helpers — uses Drift's `customSelect` to store key/value pairs
  // in a lightweight virtual table backed by the existing SyncQueue table.
  //
  // We use a dedicated SELECT/INSERT OR REPLACE approach against a "dashboard
  // cache" entry inside SyncQueue (operationType = 'cache_blob', entityType =
  // 'dashboard', entityId = _cacheKey).  This avoids adding a new migration.
  // ─────────────────────────────────────────────────────────────────────────

  Future<DashboardSummaryModel?> _readCachedBlob() async {
    final rows =
        await (_db.select(_db.syncQueue)
              ..where(
                (t) =>
                    t.operationType.equals('cache_blob') &
                    t.entityType.equals('dashboard') &
                    t.entityId.equals(_cacheKey),
              )
              ..limit(1))
            .get();

    if (rows.isEmpty) {
      return null;
    }

    final payload = rows.first.payload;
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    return DashboardSummaryModel.fromJson(decoded);
  }

  Future<void> _writeCachedBlob(String jsonBlob) async {
    await _db
        .into(_db.syncQueue)
        .insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: 'dashboard_summary_cache',
            operationType: 'cache_blob',
            entityId: _cacheKey,
            entityType: 'dashboard',
            payload: jsonBlob,
            createdAt: DateTime.now().toUtc(),
            status: const Value('completed'),
          ),
        );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Table-based assembly (best-effort fallback)
  // ─────────────────────────────────────────────────────────────────────────

  /// Assembles a [DashboardSummaryModel] directly from the Drift tables.
  ///
  /// This is less precise than the API payload but allows the dashboard to
  /// display meaningful data even before the first network fetch.
  Future<DashboardSummaryModel> _assembleFromTables() async {
    final results = await Future.wait([
      _buildAlertSummaryFromTable(),
      _buildVideoTasksFromTable(),
      _buildWaterQualityFromTable(),
      _buildHarvestSummaryFromTable(),
      _buildQuickMetricsFromTable(),
    ]);

    final alertSummary = results[0] as AlertSummaryModel;
    final videoTasks = results[1] as List<VideoTaskModel>;
    final waterQuality = results[2] as List<FarmWaterQualityStatusModel>;
    final harvest = results[3] as WeeklyHarvestSummaryModel;
    final metrics = results[4] as QuickMetricsModel;

    return DashboardSummaryModel(
      alertSummary: alertSummary,
      todayVideoTasks: videoTasks,
      farmWaterQualityStatuses: waterQuality,
      weeklyHarvestSummary: harvest,
      quickMetrics: metrics,
      fetchedAt: DateTime.now().toUtc(),
      isFromCache: true,
    );
  }

  Future<AlertSummaryModel> _buildAlertSummaryFromTable() async {
    final alerts = await _db
        .customSelect(
          '''
          SELECT
            COUNT(*) AS total,
            SUM(CASE WHEN severity = 'critical' THEN 1 ELSE 0 END) AS critical,
            SUM(CASE WHEN severity = 'warning'  THEN 1 ELSE 0 END) AS warning,
            SUM(CASE WHEN severity = 'info'     THEN 1 ELSE 0 END) AS info
          FROM alerts
          WHERE status IN ('unread', 'read')
          ''',
          readsFrom: {_db.alerts},
        )
        .getSingleOrNull();

    if (alerts == null) {
      return const AlertSummaryModel.empty();
    }

    return AlertSummaryModel(
      totalActive: alerts.read<int>('total'),
      criticalCount: alerts.read<int>('critical'),
      warningCount: alerts.read<int>('warning'),
      infoCount: alerts.read<int>('info'),
    );
  }

  Future<List<VideoTaskModel>> _buildVideoTasksFromTable() async {
    // Derive today's video tasks from the boxes that are active and have a
    // scheduled video time today.  We use lastVideoAt as a proxy for
    // scheduledAt since the Boxes table doesn't store a separate schedule.
    final today = DateTime.now().toUtc();
    final todayStart = DateTime.utc(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final rows =
        await (_db.select(_db.boxes)..where(
              (t) =>
                  t.status.equals('active') &
                  t.lastVideoAt.isBiggerOrEqualValue(todayStart) &
                  t.lastVideoAt.isSmallerThanValue(todayEnd),
            ))
            .get();

    return rows
        .map(
          (b) => VideoTaskModel(
            boxId: b.id,
            boxIdentifier: b.qrCode,
            farmId: b.farmId,
            farmName: b.farmId, // farmName not in Boxes table; use farmId
            pondId: b.pondId,
            scheduledAt: b.lastVideoAt ?? todayStart,
            isOverdue: b.lastVideoAt != null && b.lastVideoAt!.isBefore(DateTime.now().toUtc()),
          ),
        )
        .toList();
  }

  Future<List<FarmWaterQualityStatusModel>> _buildWaterQualityFromTable() async {
    // Get the most recent reading per farm.
    final rows = await _db
        .customSelect(
          '''
      SELECT
        farm_id,
        temperature,
        ph,
        dissolved_oxygen,
        salinity,
        is_alert_triggered,
        timestamp
      FROM water_quality_readings
      WHERE (farm_id, timestamp) IN (
        SELECT farm_id, MAX(timestamp)
        FROM water_quality_readings
        GROUP BY farm_id
      )
      ''',
          readsFrom: {_db.waterQualityReadings},
        )
        .get();

    return rows
        .map(
          (r) => FarmWaterQualityStatusModel(
            farmId: r.read<String>('farm_id'),
            farmName: r.read<String>('farm_id'), // not stored; fallback to id
            isOnline: true, // if we have a reading the sensor was online
            hasAlert: r.read<bool>('is_alert_triggered'),
            temperature: r.read<double?>('temperature'),
            ph: r.read<double?>('ph'),
            dissolvedOxygen: r.read<double?>('dissolved_oxygen'),
            salinity: r.read<double?>('salinity'),
            lastUpdatedAt: r.read<DateTime?>('timestamp'),
          ),
        )
        .toList();
  }

  Future<WeeklyHarvestSummaryModel> _buildHarvestSummaryFromTable() async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final row = await _db
        .customSelect(
          '''
          SELECT
            SUM(total_weight) AS total_weight,
            SUM(crab_count)   AS crab_count,
            COUNT(*)          AS harvest_count,
            COUNT(DISTINCT box_id) AS boxes_harvested
          FROM harvests
          WHERE harvest_date >= ? AND harvest_date <= ?
          ''',
          variables: [Variable<DateTime>(weekStart), Variable<DateTime>(weekEnd)],
          readsFrom: {_db.harvests},
        )
        .getSingleOrNull();

    if (row == null) {
      return WeeklyHarvestSummaryModel.empty();
    }

    return WeeklyHarvestSummaryModel(
      weekStartDate: weekStart,
      weekEndDate: weekEnd,
      totalWeightKg: row.read<double?>('total_weight') ?? 0.0,
      totalCrabCount: row.read<int?>('crab_count') ?? 0,
      harvestCount: row.read<int?>('harvest_count') ?? 0,
      boxesHarvested: row.read<int?>('boxes_harvested') ?? 0,
    );
  }

  Future<QuickMetricsModel> _buildQuickMetricsFromTable() async {
    final today = DateTime.now().toUtc();
    final todayStart = DateTime.utc(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final row = await _db
        .customSelect(
          '''
          SELECT
            (SELECT COUNT(*) FROM boxes WHERE status = 'active') AS active_boxes,
            (SELECT COUNT(DISTINCT farm_id) FROM boxes WHERE status = 'active') AS active_farms,
            (SELECT COUNT(*) FROM boxes WHERE status = 'active'
               AND last_video_at < ?) AS videos_due,
            (SELECT COUNT(*) FROM boxes WHERE status = 'active'
               AND last_video_at >= ? AND last_video_at < ?) AS videos_done
          ''',
          variables: [
            Variable<DateTime>(todayStart),
            Variable<DateTime>(todayStart),
            Variable<DateTime>(todayEnd),
          ],
          readsFrom: {_db.boxes},
        )
        .getSingleOrNull();

    if (row == null) {
      return const QuickMetricsModel.empty();
    }

    return QuickMetricsModel(
      activeBoxCount: row.read<int>('active_boxes'),
      activeFarmCount: row.read<int>('active_farms'),
      videosDueToday: row.read<int>('videos_due'),
      videosCompletedToday: row.read<int>('videos_done'),
    );
  }
}
