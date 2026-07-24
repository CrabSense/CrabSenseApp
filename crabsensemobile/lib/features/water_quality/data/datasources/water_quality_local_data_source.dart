// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/water_quality.dart';
import '../../domain/repositories/water_quality_repository.dart' show HistoricalPeriod;
import '../models/water_quality_model.dart';

/// Local data source contract for water quality cache operations.
///
/// All reads and writes go through the Drift SQLite database.
/// Implements a 7-day retention policy for historical data: records
/// older than 7 days are deleted on every cache write to keep storage
/// manageable (Requirement 8.5, 23.6).
///
/// Throws [CacheException] on any storage failure.
///
/// Requirements: 8.1-8.10
abstract class WaterQualityLocalDataSource {
  /// Returns the most-recent cached reading(s) for a farm/pond.
  ///
  /// Returns an empty list if no cached data exists for the given location.
  ///
  /// Requirements: 8.1, 8.10
  Future<List<WaterQualityModel>> getCachedCurrentReadings({
    required String farmId,
    String? pondId,
  });

  /// Returns cached historical readings for the given period.
  ///
  /// Requirements: 8.5
  Future<List<WaterQualityModel>> getCachedHistoricalData({
    required String farmId,
    required HistoricalPeriod period,
    String? pondId,
  });

  /// Persists a list of fresh readings to the local database.
  ///
  /// Also triggers the 7-day retention cleanup so old records are removed.
  ///
  /// Requirements: 8.5, 23.6
  Future<void> cacheReadings(List<WaterQuality> readings);

  /// Deletes all water quality records older than 7 days.
  ///
  /// Called automatically by [cacheReadings] to enforce retention policy.
  ///
  /// Requirements: 23.6
  Future<void> deleteOldReadings();

  /// Returns a live stream of the most-recent reading for a farm/pond.
  ///
  /// Emits every time the underlying table changes. Used to push real-time
  /// updates to the BLoC without polling (Requirement 8.7).
  ///
  /// Requirements: 8.7
  Stream<List<WaterQuality>> watchCurrentReadings({required String farmId, String? pondId});
}

/// Drift-based implementation of [WaterQualityLocalDataSource].
class WaterQualityLocalDataSourceImpl implements WaterQualityLocalDataSource {
  WaterQualityLocalDataSourceImpl({required this.database});

  final db.AppDatabase database;

  /// 7-day retention window for historical data (Requirement 8.5 / 23.6).
  static const Duration _retentionPeriod = Duration(days: 7);

  // ──────────────────────────────────────────────────────────────────────────
  // WaterQualityLocalDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<WaterQualityModel>> getCachedCurrentReadings({
    required String farmId,
    String? pondId,
  }) async {
    try {
      final query = database.select(database.waterQualityReadings)
        ..where(
          (t) => pondId != null
              ? t.farmId.equals(farmId) & t.pondId.equals(pondId)
              : t.farmId.equals(farmId),
        )
        ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
        ..limit(1);

      final rows = await query.get();
      return rows.map(_rowToModel).toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached water quality readings: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<List<WaterQualityModel>> getCachedHistoricalData({
    required String farmId,
    required HistoricalPeriod period,
    String? pondId,
  }) async {
    try {
      final from = _periodStartDate(period);

      final query = database.select(database.waterQualityReadings)
        ..where((t) {
          final farmMatch = t.farmId.equals(farmId);
          final timeMatch = t.timestamp.isBiggerOrEqualValue(from);
          if (pondId != null) {
            return farmMatch & t.pondId.equals(pondId) & timeMatch;
          }
          return farmMatch & timeMatch;
        })
        ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]);

      final rows = await query.get();
      return rows.map(_rowToModel).toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached historical water quality data: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> cacheReadings(List<WaterQuality> readings) async {
    try {
      await database.transaction(() async {
        for (final reading in readings) {
          final companion = WaterQualityModel.fromEntity(reading).toDriftCompanion();
          await database.into(database.waterQualityReadings).insertOnConflictUpdate(companion);
        }
        // Enforce 7-day retention after every batch write.
        await deleteOldReadings();
      });
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache water quality readings: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> deleteOldReadings() async {
    try {
      final cutoff = DateTime.now().subtract(_retentionPeriod);
      await (database.delete(
        database.waterQualityReadings,
      )..where((t) => t.timestamp.isSmallerThanValue(cutoff))).go();
    } catch (e) {
      throw CacheException(
        message: 'Failed to delete old water quality readings: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Stream<List<WaterQuality>> watchCurrentReadings({required String farmId, String? pondId}) {
    final query = database.select(database.waterQualityReadings)
      ..where(
        (t) => pondId != null
            ? t.farmId.equals(farmId) & t.pondId.equals(pondId)
            : t.farmId.equals(farmId),
      )
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
      ..limit(1);

    return query.watch().map((rows) => rows.map(_rowToModel).toList(growable: false));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts a Drift [db.WaterQualityReading] row to a [WaterQualityModel].
  WaterQualityModel _rowToModel(db.WaterQualityReading row) => WaterQualityModel.fromDrift(
    id: row.id,
    sensorId: row.sensorId,
    farmId: row.farmId,
    pondId: row.pondId,
    temperature: row.temperature,
    ph: row.ph,
    dissolvedOxygen: row.dissolvedOxygen,
    salinity: row.salinity,
    timestamp: row.timestamp,
    isAlertTriggered: row.isAlertTriggered,
  );

  /// Calculates the start [DateTime] for the given [HistoricalPeriod].
  DateTime _periodStartDate(HistoricalPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case HistoricalPeriod.last24Hours:
        return now.subtract(const Duration(hours: 24));
      case HistoricalPeriod.last7Days:
        return now.subtract(const Duration(days: 7));
      case HistoricalPeriod.last30Days:
        return now.subtract(const Duration(days: 30));
    }
  }
}
