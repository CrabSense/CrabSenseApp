import 'package:drift/drift.dart';

import '../database.dart';

/// Adds durable sync metadata, photo metadata and conflict storage.
class MigrationV3 {
  const MigrationV3._();

  static Future<void> apply(Migrator m, AppDatabase db) async {
    await m.createTable(db.entitySyncMetadata);
    await m.createTable(db.photoAssets);
    await m.createTable(db.syncConflicts);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_photo_assets_upload_status '
      'ON photo_assets (upload_status)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_conflicts_status '
      'ON sync_conflicts (status)',
    );
  }
}
