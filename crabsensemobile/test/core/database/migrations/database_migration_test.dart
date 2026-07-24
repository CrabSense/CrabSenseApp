// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crabsensemobile/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // NativeDatabase.memory() creates a pure in-memory SQLite database.
    // Each test gets a fresh, isolated database instance.
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Table creation (fresh install / onCreate)
  // ---------------------------------------------------------------------------

  group('onCreate — all 9 tables are created', () {
    /// Checks that a given table name exists in sqlite_master after schema
    /// creation (which is triggered lazily on first query).
    Future<bool> tableExists(String tableName) async {
      final result = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            variables: [Variable.withString(tableName)],
          )
          .get();
      return result.isNotEmpty;
    }

    test('users table exists', () async {
      expect(await tableExists('users'), isTrue);
    });

    test('boxes table exists', () async {
      expect(await tableExists('boxes'), isTrue);
    });

    test('crabs table exists', () async {
      expect(await tableExists('crabs'), isTrue);
    });

    test('water_quality_readings table exists', () async {
      expect(await tableExists('water_quality_readings'), isTrue);
    });

    test('alerts table exists', () async {
      expect(await tableExists('alerts'), isTrue);
    });

    test('operation_logs table exists', () async {
      expect(await tableExists('operation_logs'), isTrue);
    });

    test('harvests table exists', () async {
      expect(await tableExists('harvests'), isTrue);
    });

    test('sales table exists', () async {
      expect(await tableExists('sales'), isTrue);
    });

    test('sync_queue table exists', () async {
      expect(await tableExists('sync_queue'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Index creation
  // ---------------------------------------------------------------------------

  group('onCreate — performance indexes are created', () {
    Future<bool> indexExists(String indexName) async {
      final result = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
            variables: [Variable.withString(indexName)],
          )
          .get();
      return result.isNotEmpty;
    }

    test('idx_boxes_farm_id exists', () async {
      expect(await indexExists('idx_boxes_farm_id'), isTrue);
    });

    test('idx_boxes_status exists', () async {
      expect(await indexExists('idx_boxes_status'), isTrue);
    });

    test('idx_boxes_is_dirty exists', () async {
      expect(await indexExists('idx_boxes_is_dirty'), isTrue);
    });

    test('idx_crabs_box_id exists', () async {
      expect(await indexExists('idx_crabs_box_id'), isTrue);
    });

    test('idx_crabs_is_dirty exists', () async {
      expect(await indexExists('idx_crabs_is_dirty'), isTrue);
    });

    test('idx_wqr_farm_id_timestamp exists', () async {
      expect(await indexExists('idx_wqr_farm_id_timestamp'), isTrue);
    });

    test('idx_wqr_is_dirty exists', () async {
      expect(await indexExists('idx_wqr_is_dirty'), isTrue);
    });

    test('idx_alerts_status exists', () async {
      expect(await indexExists('idx_alerts_status'), isTrue);
    });

    test('idx_alerts_severity exists', () async {
      expect(await indexExists('idx_alerts_severity'), isTrue);
    });

    test('idx_alerts_is_dirty exists', () async {
      expect(await indexExists('idx_alerts_is_dirty'), isTrue);
    });

    test('idx_operation_logs_operator_id_timestamp exists', () async {
      expect(await indexExists('idx_operation_logs_operator_id_timestamp'), isTrue);
    });

    test('idx_operation_logs_is_dirty exists', () async {
      expect(await indexExists('idx_operation_logs_is_dirty'), isTrue);
    });

    test('idx_harvests_box_id_harvest_date exists', () async {
      expect(await indexExists('idx_harvests_box_id_harvest_date'), isTrue);
    });

    test('idx_harvests_is_dirty exists', () async {
      expect(await indexExists('idx_harvests_is_dirty'), isTrue);
    });

    test('idx_sales_sale_date exists', () async {
      expect(await indexExists('idx_sales_sale_date'), isTrue);
    });

    test('idx_sales_is_dirty exists', () async {
      expect(await indexExists('idx_sales_is_dirty'), isTrue);
    });

    test('idx_sync_queue_status_priority_created_at exists', () async {
      expect(await indexExists('idx_sync_queue_status_priority_created_at'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // PRAGMA foreign_keys = ON (beforeOpen)
  // ---------------------------------------------------------------------------

  group('beforeOpen — PRAGMA foreign_keys is enabled', () {
    test('foreign_keys pragma is ON after database opens', () async {
      final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
      // SQLite returns 1 when foreign keys are enabled.
      expect(result.read<int>('foreign_keys'), equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Foreign key constraint enforcement (crabs → boxes)
  // ---------------------------------------------------------------------------

  group('foreign key constraints', () {
    test('inserting a crab with a valid box_id succeeds', () async {
      final now = DateTime.now();

      // Insert a parent box first.
      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'box-001',
              qrCode: 'QR-001',
              farmId: 'farm-001',
              species: 'mudCrab',
              createdAt: now,
            ),
          );

      // Inserting a crab that references the existing box must not throw.
      await expectLater(
        db
            .into(db.crabs)
            .insert(
              CrabsCompanion.insert(
                id: 'crab-001',
                boxId: 'box-001',
                species: 'mudCrab',
                moltingStatus: 'hardShell',
                source: 'farm',
                addedAt: now,
                addedBy: 'user-001',
              ),
            ),
        completes,
      );
    });

    test('inserting a crab with a non-existent box_id throws a database exception', () async {
      final now = DateTime.now();

      // No parent box is inserted — this must violate the FK constraint.
      await expectLater(
        db
            .into(db.crabs)
            .insert(
              CrabsCompanion.insert(
                id: 'crab-orphan',
                boxId: 'box-does-not-exist',
                species: 'mudCrab',
                moltingStatus: 'hardShell',
                source: 'farm',
                addedAt: now,
                addedBy: 'user-001',
              ),
            ),
        throwsA(anything),
      );
    });

    test('deleting a box that has crabs throws a database exception', () async {
      final now = DateTime.now();

      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'box-with-crabs',
              qrCode: 'QR-002',
              farmId: 'farm-001',
              species: 'mudCrab',
              createdAt: now,
            ),
          );

      await db
          .into(db.crabs)
          .insert(
            CrabsCompanion.insert(
              id: 'crab-002',
              boxId: 'box-with-crabs',
              species: 'mudCrab',
              moltingStatus: 'preMolt',
              source: 'purchase',
              addedAt: now,
              addedBy: 'user-001',
            ),
          );

      // Deleting the parent box while a child crab still references it must
      // be rejected by the foreign key constraint.
      await expectLater(
        (db.delete(db.boxes)..where((t) => t.id.equals('box-with-crabs'))).go(),
        throwsA(anything),
      );
    });
  });
}
