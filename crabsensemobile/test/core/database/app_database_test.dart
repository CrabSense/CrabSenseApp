// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crabsensemobile/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // 1. CRUD — Users table
  // ---------------------------------------------------------------------------

  group('CRUD — Users', () {
    test('insert and read back a user (verify all fields including nullable photoUrl)', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: 'user-001',
              email: 'alice@example.com',
              name: 'Alice',
              role: 'admin',
              createdAt: now,
              photoUrl: const Value('https://example.com/photo.jpg'),
            ),
          );

      final user = await (db.select(db.users)..where((u) => u.id.equals('user-001'))).getSingle();
      expect(user.id, 'user-001');
      expect(user.email, 'alice@example.com');
      expect(user.name, 'Alice');
      expect(user.role, 'admin');
      expect(user.assignedFarmIds, '[]');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.lastLoginAt, isNull);
    });

    test('update user name and lastLoginAt', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: 'user-002',
              email: 'bob@example.com',
              name: 'Bob',
              role: 'fieldOperator',
              createdAt: now,
            ),
          );

      final loginTime = DateTime.fromMillisecondsSinceEpoch(
        (now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000) * 1000,
        isUtc: true,
      );
      await (db.update(db.users)..where((u) => u.id.equals('user-002'))).write(
        UsersCompanion(name: const Value('Bobby'), lastLoginAt: Value(loginTime)),
      );

      final user = await (db.select(db.users)..where((u) => u.id.equals('user-002'))).getSingle();
      expect(user.name, 'Bobby');
      expect(user.lastLoginAt!.millisecondsSinceEpoch, loginTime.millisecondsSinceEpoch);
    });

    test('delete a user and confirm gone', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: 'user-003',
              email: 'charlie@example.com',
              name: 'Charlie',
              role: 'viewer',
              createdAt: now,
            ),
          );
      await (db.delete(db.users)..where((u) => u.id.equals('user-003'))).go();
      final rows = await (db.select(db.users)..where((u) => u.id.equals('user-003'))).get();
      expect(rows, isEmpty);
    });

    test('insert multiple users and query all', () async {
      final now = DateTime.now().toUtc();
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.users)
            .insert(
              UsersCompanion.insert(
                id: 'user-multi-$i',
                email: 'user$i@example.com',
                name: 'User $i',
                role: 'viewer',
                createdAt: now,
              ),
            );
      }
      final all = await db.select(db.users).get();
      expect(all.length, greaterThanOrEqualTo(3));
    });
  });

  // ---------------------------------------------------------------------------
  // 2. CRUD — Boxes table
  // ---------------------------------------------------------------------------

  group('CRUD — Boxes', () {
    test(
      'insert and read back a box (verify defaults: isDirty=false, currentCrabCount=0, status=active)',
      () async {
        final now = DateTime.now().toUtc();
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

        final box = await (db.select(db.boxes)..where((b) => b.id.equals('box-001'))).getSingle();
        expect(box.id, 'box-001');
        expect(box.qrCode, 'QR-001');
        expect(box.farmId, 'farm-001');
        expect(box.isDirty, isFalse);
        expect(box.currentCrabCount, 0);
        expect(box.status, 'active');
      },
    );

    test('update box crabCount and averageWeight', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'box-002',
              qrCode: 'QR-002',
              farmId: 'farm-001',
              species: 'mudCrab',
              createdAt: now,
            ),
          );
      await (db.update(db.boxes)..where((b) => b.id.equals('box-002'))).write(
        const BoxesCompanion(currentCrabCount: Value(10), averageWeight: Value(0.5)),
      );

      final box = await (db.select(db.boxes)..where((b) => b.id.equals('box-002'))).getSingle();
      expect(box.currentCrabCount, 10);
      expect(box.averageWeight, 0.5);
    });

    test('delete a box (no children) and confirm gone', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'box-del',
              qrCode: 'QR-del',
              farmId: 'farm-001',
              species: 'blueCrab',
              createdAt: now,
            ),
          );
      await (db.delete(db.boxes)..where((b) => b.id.equals('box-del'))).go();
      final rows = await (db.select(db.boxes)..where((b) => b.id.equals('box-del'))).get();
      expect(rows, isEmpty);
    });

    test('query boxes by farmId', () async {
      final now = DateTime.now().toUtc();
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.boxes)
            .insert(
              BoxesCompanion.insert(
                id: 'box-farm-a-$i',
                qrCode: 'QR-FA-$i',
                farmId: 'farm-A',
                species: 'mudCrab',
                createdAt: now,
              ),
            );
      }
      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'box-farm-b-1',
              qrCode: 'QR-FB-1',
              farmId: 'farm-B',
              species: 'mudCrab',
              createdAt: now,
            ),
          );

      final farmABoxes = await (db.select(db.boxes)..where((b) => b.farmId.equals('farm-A'))).get();
      expect(farmABoxes.length, 3);
      expect(farmABoxes.every((b) => b.farmId == 'farm-A'), isTrue);
    });

    test('query boxes filtered by status=active', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'box-active-1',
              qrCode: 'QR-A1',
              farmId: 'farm-X',
              species: 'mudCrab',
              createdAt: now,
            ),
          );
      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'box-inactive-1',
              qrCode: 'QR-I1',
              farmId: 'farm-X',
              species: 'mudCrab',
              createdAt: now,
              status: const Value('inactive'),
            ),
          );

      final active = await (db.select(db.boxes)..where((b) => b.status.equals('active'))).get();
      expect(active.every((b) => b.status == 'active'), isTrue);
      expect(active.any((b) => b.id == 'box-active-1'), isTrue);
      expect(active.any((b) => b.id == 'box-inactive-1'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. CRUD — Crabs table
  // ---------------------------------------------------------------------------

  group('CRUD — Crabs', () {
    late DateTime now;

    setUp(() async {
      now = DateTime.now().toUtc();
      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'box-crab-parent',
              qrCode: 'QR-CP',
              farmId: 'farm-001',
              species: 'mudCrab',
              createdAt: now,
            ),
          );
    });

    test('insert a crab under a valid box and read it back', () async {
      await db
          .into(db.crabs)
          .insert(
            CrabsCompanion.insert(
              id: 'crab-001',
              boxId: 'box-crab-parent',
              species: 'mudCrab',
              moltingStatus: 'hardShell',
              source: 'farm',
              addedAt: now,
              addedBy: 'user-001',
            ),
          );

      final crab = await (db.select(db.crabs)..where((c) => c.id.equals('crab-001'))).getSingle();
      expect(crab.id, 'crab-001');
      expect(crab.boxId, 'box-crab-parent');
      expect(crab.moltingStatus, 'hardShell');
      expect(crab.healthStatus, 'unknown');
      expect(crab.isDirty, isFalse);
    });

    test('update crab moltingStatus', () async {
      await db
          .into(db.crabs)
          .insert(
            CrabsCompanion.insert(
              id: 'crab-002',
              boxId: 'box-crab-parent',
              species: 'mudCrab',
              moltingStatus: 'preMolt',
              source: 'purchase',
              addedAt: now,
              addedBy: 'user-001',
            ),
          );
      await (db.update(db.crabs)..where((c) => c.id.equals('crab-002'))).write(
        const CrabsCompanion(moltingStatus: Value('molting')),
      );

      final crab = await (db.select(db.crabs)..where((c) => c.id.equals('crab-002'))).getSingle();
      expect(crab.moltingStatus, 'molting');
    });

    test('delete a crab and confirm gone', () async {
      await db
          .into(db.crabs)
          .insert(
            CrabsCompanion.insert(
              id: 'crab-del',
              boxId: 'box-crab-parent',
              species: 'mudCrab',
              moltingStatus: 'hardShell',
              source: 'farm',
              addedAt: now,
              addedBy: 'user-001',
            ),
          );
      await (db.delete(db.crabs)..where((c) => c.id.equals('crab-del'))).go();
      final rows = await (db.select(db.crabs)..where((c) => c.id.equals('crab-del'))).get();
      expect(rows, isEmpty);
    });

    test('query crabs by boxId', () async {
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.crabs)
            .insert(
              CrabsCompanion.insert(
                id: 'crab-qbox-$i',
                boxId: 'box-crab-parent',
                species: 'mudCrab',
                moltingStatus: 'hardShell',
                source: 'farm',
                addedAt: now,
                addedBy: 'user-001',
              ),
            );
      }
      final crabs = await (db.select(
        db.crabs,
      )..where((c) => c.boxId.equals('box-crab-parent'))).get();
      expect(crabs.length, greaterThanOrEqualTo(3));
      expect(crabs.every((c) => c.boxId == 'box-crab-parent'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. CRUD — WaterQualityReadings table
  // ---------------------------------------------------------------------------

  group('CRUD — WaterQualityReadings', () {
    test('insert a reading and read it back (verify all numeric fields)', () async {
      final ts = DateTime.now().toUtc();
      await db
          .into(db.waterQualityReadings)
          .insert(
            WaterQualityReadingsCompanion.insert(
              id: 'wqr-001',
              sensorId: 'sensor-001',
              farmId: 'farm-001',
              timestamp: ts,
              temperature: const Value(27.5),
              ph: const Value(7.8),
              dissolvedOxygen: const Value(6.2),
              salinity: const Value(20),
            ),
          );

      final wqr = await (db.select(
        db.waterQualityReadings,
      )..where((r) => r.id.equals('wqr-001'))).getSingle();
      expect(wqr.id, 'wqr-001');
      expect(wqr.sensorId, 'sensor-001');
      expect(wqr.temperature, 27.5);
      expect(wqr.ph, 7.8);
      expect(wqr.dissolvedOxygen, 6.2);
      expect(wqr.salinity, 20.0);
      expect(wqr.isAlertTriggered, isFalse);
    });

    test('update isAlertTriggered', () async {
      final ts = DateTime.now().toUtc();
      await db
          .into(db.waterQualityReadings)
          .insert(
            WaterQualityReadingsCompanion.insert(
              id: 'wqr-002',
              sensorId: 'sensor-001',
              farmId: 'farm-001',
              timestamp: ts,
            ),
          );
      await (db.update(db.waterQualityReadings)..where((r) => r.id.equals('wqr-002'))).write(
        const WaterQualityReadingsCompanion(isAlertTriggered: Value(true)),
      );

      final wqr = await (db.select(
        db.waterQualityReadings,
      )..where((r) => r.id.equals('wqr-002'))).getSingle();
      expect(wqr.isAlertTriggered, isTrue);
    });

    test('delete a reading and confirm gone', () async {
      final ts = DateTime.now().toUtc();
      await db
          .into(db.waterQualityReadings)
          .insert(
            WaterQualityReadingsCompanion.insert(
              id: 'wqr-del',
              sensorId: 'sensor-001',
              farmId: 'farm-001',
              timestamp: ts,
            ),
          );
      await (db.delete(db.waterQualityReadings)..where((r) => r.id.equals('wqr-del'))).go();
      final rows = await (db.select(
        db.waterQualityReadings,
      )..where((r) => r.id.equals('wqr-del'))).get();
      expect(rows, isEmpty);
    });

    test('query readings filtered by farmId ordered by timestamp descending', () async {
      final base = DateTime(2024, 1, 1, 12).toUtc();
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.waterQualityReadings)
            .insert(
              WaterQualityReadingsCompanion.insert(
                id: 'wqr-farm-$i',
                sensorId: 'sensor-001',
                farmId: 'farm-Q',
                timestamp: base.add(Duration(hours: i)),
              ),
            );
      }
      await db
          .into(db.waterQualityReadings)
          .insert(
            WaterQualityReadingsCompanion.insert(
              id: 'wqr-other',
              sensorId: 'sensor-002',
              farmId: 'farm-other',
              timestamp: base,
            ),
          );

      final readings =
          await (db.select(db.waterQualityReadings)
                ..where((r) => r.farmId.equals('farm-Q'))
                ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
              .get();

      expect(readings.length, 3);
      expect(readings.every((r) => r.farmId == 'farm-Q'), isTrue);
      // Verify descending order
      for (var i = 0; i < readings.length - 1; i++) {
        expect(readings[i].timestamp.isAfter(readings[i + 1].timestamp), isTrue);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 5. CRUD — Alerts table
  // ---------------------------------------------------------------------------

  group('CRUD — Alerts', () {
    test('insert an alert and read it back (verify status=unread, isDirty=false)', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.alerts)
          .insert(
            AlertsCompanion.insert(
              id: 'alert-001',
              type: 'waterQuality',
              severity: 'critical',
              title: 'Low DO',
              message: 'Dissolved oxygen below threshold',
              createdAt: now,
            ),
          );

      final alert = await (db.select(
        db.alerts,
      )..where((a) => a.id.equals('alert-001'))).getSingle();
      expect(alert.id, 'alert-001');
      expect(alert.status, 'unread');
      expect(alert.isDirty, isFalse);
      expect(alert.acknowledgedAt, isNull);
      expect(alert.acknowledgedBy, isNull);
      expect(alert.recommendedActions, '[]');
    });

    test('update alert status to acknowledged and set acknowledgedAt/acknowledgedBy', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.alerts)
          .insert(
            AlertsCompanion.insert(
              id: 'alert-002',
              type: 'equipment',
              severity: 'warning',
              title: 'Pump failure',
              message: 'Pump offline',
              createdAt: now,
            ),
          );

      final ackTime = DateTime.fromMillisecondsSinceEpoch(
        (now.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000) * 1000,
        isUtc: true,
      );
      await (db.update(db.alerts)..where((a) => a.id.equals('alert-002'))).write(
        AlertsCompanion(
          status: const Value('acknowledged'),
          acknowledgedAt: Value(ackTime),
          acknowledgedBy: const Value('user-001'),
        ),
      );

      final alert = await (db.select(
        db.alerts,
      )..where((a) => a.id.equals('alert-002'))).getSingle();
      expect(alert.status, 'acknowledged');
      expect(alert.acknowledgedAt!.millisecondsSinceEpoch, ackTime.millisecondsSinceEpoch);
      expect(alert.acknowledgedBy, 'user-001');
    });

    test('delete an alert and confirm gone', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.alerts)
          .insert(
            AlertsCompanion.insert(
              id: 'alert-del',
              type: 'system',
              severity: 'info',
              title: 'Test',
              message: 'Test message',
              createdAt: now,
            ),
          );
      await (db.delete(db.alerts)..where((a) => a.id.equals('alert-del'))).go();
      final rows = await (db.select(db.alerts)..where((a) => a.id.equals('alert-del'))).get();
      expect(rows, isEmpty);
    });

    test('query unread alerts sorted by createdAt descending', () async {
      final base = DateTime(2024, 6, 1, 8).toUtc();
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.alerts)
            .insert(
              AlertsCompanion.insert(
                id: 'alert-unread-$i',
                type: 'waterQuality',
                severity: 'warning',
                title: 'Alert $i',
                message: 'Message $i',
                createdAt: base.add(Duration(hours: i)),
              ),
            );
      }
      await db
          .into(db.alerts)
          .insert(
            AlertsCompanion.insert(
              id: 'alert-acked',
              type: 'system',
              severity: 'info',
              title: 'Acked',
              message: 'Done',
              createdAt: base,
              status: const Value('acknowledged'),
            ),
          );

      final unread =
          await (db.select(db.alerts)
                ..where((a) => a.status.equals('unread'))
                ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
              .get();

      expect(unread.every((a) => a.status == 'unread'), isTrue);
      expect(unread.any((a) => a.id == 'alert-acked'), isFalse);
      for (var i = 0; i < unread.length - 1; i++) {
        expect(unread[i].createdAt.isAfter(unread[i + 1].createdAt), isTrue);
      }
    });

    test('query alerts filtered by severity=critical', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.alerts)
          .insert(
            AlertsCompanion.insert(
              id: 'alert-crit-1',
              type: 'waterQuality',
              severity: 'critical',
              title: 'Crit1',
              message: 'Msg',
              createdAt: now,
            ),
          );
      await db
          .into(db.alerts)
          .insert(
            AlertsCompanion.insert(
              id: 'alert-warn-1',
              type: 'system',
              severity: 'warning',
              title: 'Warn1',
              message: 'Msg',
              createdAt: now,
            ),
          );

      final critical = await (db.select(
        db.alerts,
      )..where((a) => a.severity.equals('critical'))).get();
      expect(critical.every((a) => a.severity == 'critical'), isTrue);
      expect(critical.any((a) => a.id == 'alert-crit-1'), isTrue);
      expect(critical.any((a) => a.id == 'alert-warn-1'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. CRUD — OperationLogs table
  // ---------------------------------------------------------------------------

  group('CRUD — OperationLogs', () {
    test(
      'insert an operation log and read it back (verify notes defaults to empty, photoUrls defaults to [])',
      () async {
        final ts = DateTime.now().toUtc();
        await db
            .into(db.operationLogs)
            .insert(
              OperationLogsCompanion.insert(
                id: 'oplog-001',
                type: 'feeding',
                timestamp: ts,
                operatorId: 'user-001',
                operatorName: 'Alice',
              ),
            );

        final log = await (db.select(
          db.operationLogs,
        )..where((l) => l.id.equals('oplog-001'))).getSingle();
        expect(log.id, 'oplog-001');
        expect(log.notes, '');
        expect(log.photoUrls, '[]');
        expect(log.boxIds, '[]');
      },
    );

    test('update notes field', () async {
      final ts = DateTime.now().toUtc();
      await db
          .into(db.operationLogs)
          .insert(
            OperationLogsCompanion.insert(
              id: 'oplog-002',
              type: 'waterChange',
              timestamp: ts,
              operatorId: 'user-001',
              operatorName: 'Alice',
            ),
          );
      await (db.update(db.operationLogs)..where((l) => l.id.equals('oplog-002'))).write(
        const OperationLogsCompanion(notes: Value('Changed 50% water in pond 3')),
      );

      final log = await (db.select(
        db.operationLogs,
      )..where((l) => l.id.equals('oplog-002'))).getSingle();
      expect(log.notes, 'Changed 50% water in pond 3');
    });

    test('delete a log and confirm gone', () async {
      final ts = DateTime.now().toUtc();
      await db
          .into(db.operationLogs)
          .insert(
            OperationLogsCompanion.insert(
              id: 'oplog-del',
              type: 'cleaning',
              timestamp: ts,
              operatorId: 'user-001',
              operatorName: 'Alice',
            ),
          );
      await (db.delete(db.operationLogs)..where((l) => l.id.equals('oplog-del'))).go();
      final rows = await (db.select(
        db.operationLogs,
      )..where((l) => l.id.equals('oplog-del'))).get();
      expect(rows, isEmpty);
    });

    test('query logs by operatorId ordered by timestamp', () async {
      final base = DateTime(2024, 3, 1, 9).toUtc();
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.operationLogs)
            .insert(
              OperationLogsCompanion.insert(
                id: 'oplog-op1-$i',
                type: 'feeding',
                timestamp: base.add(Duration(hours: i)),
                operatorId: 'op-A',
                operatorName: 'Operator A',
              ),
            );
      }
      await db
          .into(db.operationLogs)
          .insert(
            OperationLogsCompanion.insert(
              id: 'oplog-op2-1',
              type: 'inspection',
              timestamp: base,
              operatorId: 'op-B',
              operatorName: 'Operator B',
            ),
          );

      final opALogs =
          await (db.select(db.operationLogs)
                ..where((l) => l.operatorId.equals('op-A'))
                ..orderBy([(l) => OrderingTerm.asc(l.timestamp)]))
              .get();

      expect(opALogs.length, 3);
      expect(opALogs.every((l) => l.operatorId == 'op-A'), isTrue);
      for (var i = 0; i < opALogs.length - 1; i++) {
        expect(opALogs[i].timestamp.isBefore(opALogs[i + 1].timestamp), isTrue);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 7. CRUD — Harvests table
  // ---------------------------------------------------------------------------

  group('CRUD — Harvests', () {
    late DateTime now;

    setUp(() async {
      now = DateTime.now().toUtc();
      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'box-harvest-parent',
              qrCode: 'QR-HP',
              farmId: 'farm-001',
              species: 'mudCrab',
              createdAt: now,
            ),
          );
    });

    test('insert a harvest (with valid box) and read it back', () async {
      await db
          .into(db.harvests)
          .insert(
            HarvestsCompanion.insert(
              id: 'harvest-001',
              boxId: 'box-harvest-parent',
              qualityGrade: 'gradeA',
              harvestDate: now,
              harvestedBy: 'user-001',
              totalWeight: const Value(12.5),
              crabCount: const Value(25),
            ),
          );

      final harvest = await (db.select(
        db.harvests,
      )..where((h) => h.id.equals('harvest-001'))).getSingle();
      expect(harvest.id, 'harvest-001');
      expect(harvest.boxId, 'box-harvest-parent');
      expect(harvest.totalWeight, 12.5);
      expect(harvest.crabCount, 25);
      expect(harvest.qualityGrade, 'gradeA');
      expect(harvest.notes, '');
      expect(harvest.photoUrls, '[]');
    });

    test('update totalWeight and qualityGrade', () async {
      await db
          .into(db.harvests)
          .insert(
            HarvestsCompanion.insert(
              id: 'harvest-002',
              boxId: 'box-harvest-parent',
              qualityGrade: 'gradeB',
              harvestDate: now,
              harvestedBy: 'user-001',
            ),
          );
      await (db.update(db.harvests)..where((h) => h.id.equals('harvest-002'))).write(
        const HarvestsCompanion(totalWeight: Value(8), qualityGrade: Value('gradeA')),
      );

      final harvest = await (db.select(
        db.harvests,
      )..where((h) => h.id.equals('harvest-002'))).getSingle();
      expect(harvest.totalWeight, 8.0);
      expect(harvest.qualityGrade, 'gradeA');
    });

    test('delete a harvest and confirm gone', () async {
      await db
          .into(db.harvests)
          .insert(
            HarvestsCompanion.insert(
              id: 'harvest-del',
              boxId: 'box-harvest-parent',
              qualityGrade: 'gradeC',
              harvestDate: now,
              harvestedBy: 'user-001',
            ),
          );
      await (db.delete(db.harvests)..where((h) => h.id.equals('harvest-del'))).go();
      final rows = await (db.select(db.harvests)..where((h) => h.id.equals('harvest-del'))).get();
      expect(rows, isEmpty);
    });

    test('query harvests by boxId ordered by harvestDate descending', () async {
      final base = DateTime(2024, 5).toUtc();
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.harvests)
            .insert(
              HarvestsCompanion.insert(
                id: 'harvest-q-$i',
                boxId: 'box-harvest-parent',
                qualityGrade: 'gradeA',
                harvestDate: base.add(Duration(days: i)),
                harvestedBy: 'user-001',
              ),
            );
      }

      final harvests =
          await (db.select(db.harvests)
                ..where((h) => h.boxId.equals('box-harvest-parent'))
                ..orderBy([(h) => OrderingTerm.desc(h.harvestDate)]))
              .get();

      expect(harvests.length, 3);
      for (var i = 0; i < harvests.length - 1; i++) {
        expect(harvests[i].harvestDate.isAfter(harvests[i + 1].harvestDate), isTrue);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 8. CRUD — Sales table
  // ---------------------------------------------------------------------------

  group('CRUD — Sales', () {
    test('insert a sale and read it back (verify paymentStatus=pending)', () async {
      final saleDate = DateTime.now().toUtc();
      await db
          .into(db.sales)
          .insert(
            SalesCompanion.insert(
              id: 'sale-001',
              transactionId: 'TXN-001',
              buyerName: 'Buyer A',
              paymentMethod: 'cash',
              saleDate: saleDate,
              quantity: const Value(5),
              unitPrice: const Value(200),
              totalAmount: const Value(1000),
            ),
          );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals('sale-001'))).getSingle();
      expect(sale.id, 'sale-001');
      expect(sale.paymentStatus, 'pending');
      expect(sale.buyerName, 'Buyer A');
      expect(sale.totalAmount, 1000.0);
      expect(sale.isDirty, isFalse);
    });

    test('update paymentStatus to completed', () async {
      final saleDate = DateTime.now().toUtc();
      await db
          .into(db.sales)
          .insert(
            SalesCompanion.insert(
              id: 'sale-002',
              transactionId: 'TXN-002',
              buyerName: 'Buyer B',
              paymentMethod: 'bankTransfer',
              saleDate: saleDate,
            ),
          );
      await (db.update(db.sales)..where((s) => s.id.equals('sale-002'))).write(
        const SalesCompanion(paymentStatus: Value('completed')),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals('sale-002'))).getSingle();
      expect(sale.paymentStatus, 'completed');
    });

    test('delete a sale and confirm gone', () async {
      final saleDate = DateTime.now().toUtc();
      await db
          .into(db.sales)
          .insert(
            SalesCompanion.insert(
              id: 'sale-del',
              transactionId: 'TXN-DEL',
              buyerName: 'Buyer Del',
              paymentMethod: 'cash',
              saleDate: saleDate,
            ),
          );
      await (db.delete(db.sales)..where((s) => s.id.equals('sale-del'))).go();
      final rows = await (db.select(db.sales)..where((s) => s.id.equals('sale-del'))).get();
      expect(rows, isEmpty);
    });

    test('query sales ordered by saleDate descending', () async {
      final base = DateTime(2024, 4).toUtc();
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.sales)
            .insert(
              SalesCompanion.insert(
                id: 'sale-ord-$i',
                transactionId: 'TXN-ORD-$i',
                buyerName: 'Buyer $i',
                paymentMethod: 'cash',
                saleDate: base.add(Duration(days: i)),
              ),
            );
      }

      final sales =
          await (db.select(db.sales)
                ..where((s) => s.transactionId.like('TXN-ORD-%'))
                ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
              .get();

      expect(sales.length, 3);
      for (var i = 0; i < sales.length - 1; i++) {
        expect(sales[i].saleDate.isAfter(sales[i + 1].saleDate), isTrue);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 9. CRUD — SyncQueue table
  // ---------------------------------------------------------------------------

  group('CRUD — SyncQueue', () {
    test(
      'insert a queue item and read it back (verify status=pending, retryCount=0, priority=1)',
      () async {
        final now = DateTime.now().toUtc();
        await db
            .into(db.syncQueue)
            .insert(
              SyncQueueCompanion.insert(
                id: 'sq-001',
                operationType: 'create_harvest',
                entityId: 'harvest-001',
                entityType: 'harvest',
                payload: '{"key":"value"}',
                createdAt: now,
              ),
            );

        final item = await (db.select(
          db.syncQueue,
        )..where((q) => q.id.equals('sq-001'))).getSingle();
        expect(item.id, 'sq-001');
        expect(item.status, 'pending');
        expect(item.retryCount, 0);
        expect(item.priority, 1);
        expect(item.lastAttemptAt, isNull);
        expect(item.errorMessage, isNull);
      },
    );

    test('update status to processing and increment retryCount', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              id: 'sq-002',
              operationType: 'acknowledge_alert',
              entityId: 'alert-001',
              entityType: 'alert',
              payload: '{}',
              createdAt: now,
            ),
          );
      final attemptTime = DateTime.fromMillisecondsSinceEpoch(
        (now.add(const Duration(seconds: 30)).millisecondsSinceEpoch ~/ 1000) * 1000,
        isUtc: true,
      );
      await (db.update(db.syncQueue)..where((q) => q.id.equals('sq-002'))).write(
        SyncQueueCompanion(
          status: const Value('processing'),
          retryCount: const Value(1),
          lastAttemptAt: Value(attemptTime),
        ),
      );

      final item = await (db.select(db.syncQueue)..where((q) => q.id.equals('sq-002'))).getSingle();
      expect(item.status, 'processing');
      expect(item.retryCount, 1);
      expect(item.lastAttemptAt!.millisecondsSinceEpoch, attemptTime.millisecondsSinceEpoch);
    });

    test('delete a completed item and confirm gone', () async {
      final now = DateTime.now().toUtc();
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              id: 'sq-del',
              operationType: 'create_sale',
              entityId: 'sale-001',
              entityType: 'sale',
              payload: '{}',
              createdAt: now,
              status: const Value('completed'),
            ),
          );
      await (db.delete(db.syncQueue)..where((q) => q.id.equals('sq-del'))).go();
      final rows = await (db.select(db.syncQueue)..where((q) => q.id.equals('sq-del'))).get();
      expect(rows, isEmpty);
    });

    test('query pending items ordered by priority DESC, createdAt ASC', () async {
      final base = DateTime(2024, 7, 1, 10).toUtc();
      // priority=3 (critical), inserted later
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              id: 'sq-p3',
              operationType: 'create_alert',
              entityId: 'alert-x',
              entityType: 'alert',
              payload: '{}',
              createdAt: base.add(const Duration(minutes: 2)),
              priority: const Value(3),
            ),
          );
      // priority=1 (medium), inserted first
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              id: 'sq-p1a',
              operationType: 'create_log',
              entityId: 'log-1',
              entityType: 'operationLog',
              payload: '{}',
              createdAt: base,
              priority: const Value(1),
            ),
          );
      // priority=1 (medium), inserted second
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              id: 'sq-p1b',
              operationType: 'create_log',
              entityId: 'log-2',
              entityType: 'operationLog',
              payload: '{}',
              createdAt: base.add(const Duration(minutes: 1)),
              priority: const Value(1),
            ),
          );

      final pending =
          await (db.select(db.syncQueue)
                ..where((q) => q.status.equals('pending'))
                ..orderBy([
                  (q) => OrderingTerm.desc(q.priority),
                  (q) => OrderingTerm.asc(q.createdAt),
                ]))
              .get();

      expect(pending.length, 3);
      expect(pending.first.id, 'sq-p3'); // highest priority first
      expect(pending[1].id, 'sq-p1a'); // same priority, earliest first
      expect(pending[2].id, 'sq-p1b');
    });
  });

  // ---------------------------------------------------------------------------
  // 10. Transaction rollback behavior
  // ---------------------------------------------------------------------------

  group('Transaction rollback behavior', () {
    test('transaction rollback: insert then throw — box NOT persisted', () async {
      final now = DateTime.now().toUtc();
      try {
        await db.transaction(() async {
          await db
              .into(db.boxes)
              .insert(
                BoxesCompanion.insert(
                  id: 'box-tx-rollback',
                  qrCode: 'QR-TX-RB',
                  farmId: 'farm-001',
                  species: 'mudCrab',
                  createdAt: now,
                ),
              );
          throw Exception('intentional rollback');
        });
      } catch (_) {
        // expected
      }

      final rows = await (db.select(db.boxes)..where((b) => b.id.equals('box-tx-rollback'))).get();
      expect(rows, isEmpty);
    });

    test('transaction commit: insert box and crab together — both persisted', () async {
      final now = DateTime.now().toUtc();
      await db.transaction(() async {
        await db
            .into(db.boxes)
            .insert(
              BoxesCompanion.insert(
                id: 'box-tx-commit',
                qrCode: 'QR-TX-C',
                farmId: 'farm-001',
                species: 'mudCrab',
                createdAt: now,
              ),
            );
        await db
            .into(db.crabs)
            .insert(
              CrabsCompanion.insert(
                id: 'crab-tx-commit',
                boxId: 'box-tx-commit',
                species: 'mudCrab',
                moltingStatus: 'hardShell',
                source: 'farm',
                addedAt: now,
                addedBy: 'user-001',
              ),
            );
      });

      final box = await (db.select(
        db.boxes,
      )..where((b) => b.id.equals('box-tx-commit'))).getSingle();
      final crab = await (db.select(
        db.crabs,
      )..where((c) => c.id.equals('crab-tx-commit'))).getSingle();
      expect(box.id, 'box-tx-commit');
      expect(crab.id, 'crab-tx-commit');
    });

    test('transaction commit: insert multiple operation logs atomically — verify count', () async {
      final now = DateTime.now().toUtc();
      await db.transaction(() async {
        for (var i = 1; i <= 5; i++) {
          await db
              .into(db.operationLogs)
              .insert(
                OperationLogsCompanion.insert(
                  id: 'oplog-atomic-$i',
                  type: 'feeding',
                  timestamp: now.add(Duration(minutes: i)),
                  operatorId: 'op-tx',
                  operatorName: 'Tx Operator',
                ),
              );
        }
      });

      final logs = await (db.select(
        db.operationLogs,
      )..where((l) => l.operatorId.equals('op-tx'))).get();
      expect(logs.length, 5);
    });
  });

  // ---------------------------------------------------------------------------
  // 11. Query performance with indexed fields (smoke tests)
  // ---------------------------------------------------------------------------

  group('Query performance — indexed fields (smoke tests)', () {
    late DateTime now;

    setUp(() async {
      now = DateTime.now().toUtc();
    });

    test('query boxes by farm_id (idx_boxes_farm_id) — returns correct items', () async {
      for (var i = 1; i <= 4; i++) {
        await db
            .into(db.boxes)
            .insert(
              BoxesCompanion.insert(
                id: 'idx-box-$i',
                qrCode: 'QR-IDX-$i',
                farmId: i <= 3 ? 'idx-farm-A' : 'idx-farm-B',
                species: 'mudCrab',
                createdAt: now,
              ),
            );
      }

      final results = await (db.select(
        db.boxes,
      )..where((b) => b.farmId.equals('idx-farm-A'))).get();
      expect(results.length, 3);
      expect(results.every((b) => b.farmId == 'idx-farm-A'), isTrue);
    });

    test('query crabs by box_id (idx_crabs_box_id) — correct count returned', () async {
      await db
          .into(db.boxes)
          .insert(
            BoxesCompanion.insert(
              id: 'idx-box-crab',
              qrCode: 'QR-IDX-CB',
              farmId: 'farm-001',
              species: 'mudCrab',
              createdAt: now,
            ),
          );
      for (var i = 1; i <= 5; i++) {
        await db
            .into(db.crabs)
            .insert(
              CrabsCompanion.insert(
                id: 'idx-crab-$i',
                boxId: 'idx-box-crab',
                species: 'mudCrab',
                moltingStatus: 'hardShell',
                source: 'farm',
                addedAt: now,
                addedBy: 'user-001',
              ),
            );
      }

      final crabs = await (db.select(db.crabs)..where((c) => c.boxId.equals('idx-box-crab'))).get();
      expect(crabs.length, 5);
    });

    test(
      'query alerts by status (idx_alerts_status) — unread count matches inserted count',
      () async {
        const insertCount = 4;
        for (var i = 1; i <= insertCount; i++) {
          await db
              .into(db.alerts)
              .insert(
                AlertsCompanion.insert(
                  id: 'idx-alert-$i',
                  type: 'waterQuality',
                  severity: 'warning',
                  title: 'Alert $i',
                  message: 'Message $i',
                  createdAt: now.add(Duration(minutes: i)),
                ),
              );
        }
        // One extra with different status
        await db
            .into(db.alerts)
            .insert(
              AlertsCompanion.insert(
                id: 'idx-alert-read',
                type: 'system',
                severity: 'info',
                title: 'Read Alert',
                message: 'Already read',
                createdAt: now,
                status: const Value('read'),
              ),
            );

        final unread = await (db.select(db.alerts)..where((a) => a.status.equals('unread'))).get();
        // At least the insertCount unread alerts we just inserted
        expect(
          unread.where((a) => a.id.startsWith('idx-alert-') && a.id != 'idx-alert-read').length,
          insertCount,
        );
      },
    );

    test(
      'query water_quality_readings by (farm_id, timestamp) range (idx_wqr_farm_id_timestamp) — filtered results',
      () async {
        final base = DateTime(2024, 8).toUtc();
        for (var i = 0; i < 6; i++) {
          await db
              .into(db.waterQualityReadings)
              .insert(
                WaterQualityReadingsCompanion.insert(
                  id: 'idx-wqr-$i',
                  sensorId: 'sensor-idx',
                  farmId: 'idx-farm-wqr',
                  timestamp: base.add(Duration(hours: i)),
                ),
              );
        }

        final rangeStart = base.add(const Duration(hours: 2));
        final rangeEnd = base.add(const Duration(hours: 4));

        final results =
            await (db.select(db.waterQualityReadings)..where(
                  (r) =>
                      r.farmId.equals('idx-farm-wqr') &
                      r.timestamp.isBiggerOrEqualValue(rangeStart) &
                      r.timestamp.isSmallerOrEqualValue(rangeEnd),
                ))
                .get();

        // Should return hours 2, 3, 4 = 3 readings
        expect(results.length, 3);
        expect(
          results.every((r) => !r.timestamp.isBefore(rangeStart) && !r.timestamp.isAfter(rangeEnd)),
          isTrue,
        );
      },
    );

    test(
      'query sync_queue by (status, priority) (idx_sync_queue_status_priority_created_at) — correct ordering',
      () async {
        final base = DateTime(2024, 9, 1, 8).toUtc();
        // Insert with varying priorities, all pending
        final testData = [
          ('sq-idx-1', 2, base),
          ('sq-idx-2', 3, base.add(const Duration(minutes: 1))),
          ('sq-idx-3', 1, base.add(const Duration(minutes: 2))),
          ('sq-idx-4', 3, base.add(const Duration(minutes: 3))),
        ];
        for (final (id, prio, ts) in testData) {
          await db
              .into(db.syncQueue)
              .insert(
                SyncQueueCompanion.insert(
                  id: id,
                  operationType: 'create_log',
                  entityId: 'log-$id',
                  entityType: 'operationLog',
                  payload: '{}',
                  createdAt: ts,
                  priority: Value(prio),
                ),
              );
        }

        final pending =
            await (db.select(db.syncQueue)
                  ..where((q) => q.status.equals('pending') & q.id.like('sq-idx-%'))
                  ..orderBy([
                    (q) => OrderingTerm.desc(q.priority),
                    (q) => OrderingTerm.asc(q.createdAt),
                  ]))
                .get();

        expect(pending.length, 4);
        // First two should be priority=3, ordered by createdAt
        expect(pending[0].id, 'sq-idx-2'); // priority=3, earlier
        expect(pending[1].id, 'sq-idx-4'); // priority=3, later
        expect(pending[2].priority, 2);
        expect(pending[3].priority, 1);
      },
    );
  });
}
