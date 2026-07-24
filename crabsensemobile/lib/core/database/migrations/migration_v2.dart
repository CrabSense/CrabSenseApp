// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import '../database.dart';
import 'database_migration_manager.dart' show DatabaseMigrationManager;

/// Version 2 schema migration.
///
/// Changes in v2:
///   - Added `inspections` table for manual crab inspection records.
///
/// Indexes added for performance:
///   - inspections(box_id, timestamp)  — history queries (Req 7.10)
///   - inspections(is_dirty)           — offline-sync queries (Req 7.7)
///   - inspections(operator_id)        — agreement rate queries (Req 7.8)
///
/// Requirements: 7.1-7.10, 13.3
class MigrationV2 {
  /// Applies the v2 schema changes.
  ///
  /// Called from [DatabaseMigrationManager.onUpgrade] when upgrading
  /// from any schema version prior to 2.
  static Future<void> apply(Migrator m, AppDatabase db) async {
    await m.createTable(db.inspections);
    await _createIndexes(db);
  }

  // ---------------------------------------------------------------------------
  // Index creation
  // ---------------------------------------------------------------------------

  /// Creates performance indexes for the inspections table.
  ///
  /// All statements use `IF NOT EXISTS` so they are safe to re-run.
  ///
  /// Requirement: 22.8
  static Future<void> _createIndexes(AppDatabase db) async {
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inspections_box_id_timestamp '
      'ON inspections (box_id, timestamp DESC)',
    );

    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inspections_is_dirty '
      'ON inspections (is_dirty)',
    );

    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inspections_operator_id '
      'ON inspections (operator_id)',
    );
  }
}
