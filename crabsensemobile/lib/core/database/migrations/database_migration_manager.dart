// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import '../database.dart';
import 'migration_v1.dart';
import 'migration_v2.dart';
import 'migration_v3.dart';

/// Encapsulates all database migration logic for the CrabSense local database.
///
/// This class is the single place to add, update, or remove migration steps.
/// [AppDatabase.migration] delegates to this manager, keeping the database
/// class lean and free of versioning details.
///
/// ### Schema version history
///
/// | Version | Description                                          |
/// |---------|------------------------------------------------------|
/// | 1       | Initial schema — 9 tables + performance indexes      |
/// | 2       | Added inspections table (Req 7.1-7.10)               |
///
/// ### Adding future migrations
///
/// 1. Implement a new `MigrationVN` class in `migrations/migration_vN.dart`.
/// 2. Add the `if (from < N)` block inside [onUpgrade].
/// 3. Increment `kDatabaseVersion` in `database.dart`.
///
/// Requirements: 13.3-13.10
class DatabaseMigrationManager {
  // Private constructor — this is a static-only utility class.
  const DatabaseMigrationManager._();

  // ---------------------------------------------------------------------------
  // onCreate
  // ---------------------------------------------------------------------------

  /// Called when the database is created for the first time (fresh install).
  ///
  /// Delegates to [MigrationV1.create], which creates all tables and
  /// performance indexes in a single pass.
  static Future<void> onCreate(Migrator m, AppDatabase db) async {
    await MigrationV1.create(m, db);
  }

  // ---------------------------------------------------------------------------
  // onUpgrade
  // ---------------------------------------------------------------------------

  /// Called when [AppDatabase.schemaVersion] is greater than the on-device
  /// database version.
  ///
  /// Migrations are applied incrementally: each block is guarded by
  /// `if (from < N)` so that devices skipping multiple versions still receive
  /// every intermediate change in the correct order.
  ///
  /// Example for a future v2 migration:
  /// ```dart
  /// if (from < 2) {
  ///   await MigrationV2.apply(m, db);
  /// }
  /// ```
  static Future<void> onUpgrade(
    Migrator m,
    int from,
    int to,
    AppDatabase db,
  ) async {
    if (from < 2) {
      await MigrationV2.apply(m, db);
    }
    if (from < 3) {
      await MigrationV3.apply(m, db);
    }
  }
}
