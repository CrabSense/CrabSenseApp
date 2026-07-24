// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import '../database.dart';

/// Version 1 schema — initial release.
///
/// Tables created:
///   - users
///   - boxes
///   - crabs
///   - water_quality_readings
///   - alerts
///   - operation_logs
///   - harvests
///   - sales
///   - sync_queue
///
/// Indexes created for frequently queried fields (requirement 22.8):
///   - boxes(farm_id), boxes(status), boxes(is_dirty)
///   - crabs(box_id), crabs(is_dirty)
///   - water_quality_readings(farm_id, timestamp), water_quality_readings(is_dirty)
///   - alerts(status), alerts(severity), alerts(is_dirty)
///   - operation_logs(operator_id, timestamp), operation_logs(is_dirty)
///   - harvests(box_id, harvest_date), harvests(is_dirty)
///   - sales(sale_date), sales(is_dirty)
///   - sync_queue(status, priority, created_at)
///
/// Requirements: 13.3-13.10, 22.8, 23.6
class MigrationV1 {
  /// Creates all v1 tables and indexes.
  ///
  /// Called from [DatabaseMigrationManager.onCreate] when the database
  /// is freshly installed (no prior schema exists).
  static Future<void> create(Migrator m, AppDatabase db) async {
    // Create all tables defined in the @DriftDatabase annotation.
    await m.createAll();

    // Create performance indexes after tables exist.
    await _createIndexes(db);
  }

  // ---------------------------------------------------------------------------
  // Index creation
  // ---------------------------------------------------------------------------

  /// Creates database indexes for frequently queried fields.
  ///
  /// All statements use `IF NOT EXISTS` so they are idempotent and safe to
  /// re-run (e.g., if migration is called again accidentally).
  ///
  /// Requirement: 22.8
  static Future<void> _createIndexes(AppDatabase db) async {
    // boxes indexes
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_boxes_farm_id ON boxes (farm_id)');
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_boxes_status ON boxes (status)');
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_boxes_is_dirty ON boxes (is_dirty)');

    // crabs indexes
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_crabs_box_id ON crabs (box_id)');
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_crabs_is_dirty ON crabs (is_dirty)');

    // water_quality_readings indexes
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wqr_farm_id_timestamp '
      'ON water_quality_readings (farm_id, timestamp)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wqr_is_dirty '
      'ON water_quality_readings (is_dirty)',
    );

    // alerts indexes
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts (status)');
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_alerts_severity ON alerts (severity)');
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_alerts_is_dirty ON alerts (is_dirty)');

    // operation_logs indexes
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_operation_logs_operator_id_timestamp '
      'ON operation_logs (operator_id, timestamp)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_operation_logs_is_dirty '
      'ON operation_logs (is_dirty)',
    );

    // harvests indexes
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_harvests_box_id_harvest_date '
      'ON harvests (box_id, harvest_date)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_harvests_is_dirty ON harvests (is_dirty)',
    );

    // sales indexes
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_sales_sale_date ON sales (sale_date)');
    await db.customStatement('CREATE INDEX IF NOT EXISTS idx_sales_is_dirty ON sales (is_dirty)');

    // sync_queue indexes
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status_priority_created_at '
      'ON sync_queue (status, priority, created_at)',
    );
  }
}
