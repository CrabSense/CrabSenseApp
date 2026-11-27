import '../database.dart';

/// New isolated cache. Never copy legacy missing-as-zero measurements.
class MigrationV4 {
  const MigrationV4._();

  static Future<void> apply(AppDatabase db) async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS scoped_sensor_history_cache (
        user_id TEXT NOT NULL,
        query_key TEXT NOT NULL,
        area_id TEXT NOT NULL,
        saved_at_ms INTEGER NOT NULL,
        payload TEXT NOT NULL,
        PRIMARY KEY (user_id, query_key)
      )
    ''');
  }
}
