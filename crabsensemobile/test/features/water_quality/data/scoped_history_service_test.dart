import 'dart:async';
import 'dart:io';

import 'package:crabsensemobile/core/database/database.dart'
    show AppDatabase;
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/water_quality/data/datasources/scoped_history_cache.dart';
import 'package:crabsensemobile/features/water_quality/data/repositories/scoped_history_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scoped_history_cache_test.dart' as fixture;

User staff(String id) => User(id: id, email: '', name: '',
  role: UserRole.farmStaff, assignedFarmIds: const [],
  createdAt: fixture.now);

void main() {
  test('fetch online, store complete response and invalidate on denial or identity change', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final cache = ScopedHistoryCache(db, clock: () => fixture.now);
    var identity = const HistoryIdentity('a', 'token-a');
    var deny = false;
    final service = ScopedHistoryService(cache: cache,
      identity: () async => identity,
      loadPage: (q, page, asOf, id) async {
        expect(page, 1);
        expect(asOf, isNull);
        expect(id.accessToken, 'token-a');
        if (deny) throw StateError('Denied');
        return fixture.page(q);
      });
    await service.bindUser(staff('a'));
    expect((await service.fetchOnline(fixture.query())).pointCount, 1);
    expect(await db.customSelect('SELECT * FROM scoped_sensor_history_cache').get(),
      hasLength(1));
    deny = true;
    await expectLater(service.fetchOnline(fixture.query()), throwsStateError);
    expect(await db.customSelect('SELECT * FROM scoped_sensor_history_cache').get(), isEmpty);
    identity = const HistoryIdentity('b', 'token-b');
    await expectLater(service.fetchOnline(fixture.query()), throwsStateError);
    await service.bindUser(null);
    await expectLater(service.fetchOnline(fixture.query()), throwsStateError);
  });

  test('preserves exact asOf on subsequent pages and rejects response after logout', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final cache = ScopedHistoryCache(db, clock: () => fixture.now);
    final started = Completer<void>();
    final response = Completer<Map<String, dynamic>>();
    final service = ScopedHistoryService(cache: cache,
      identity: () async => const HistoryIdentity('a', 'token-a'),
      loadPage: (q, page, asOf, id) async {
        if (page == 1) {
          return fixture.page(q)..['pageSize'] = 1..['hasMore'] = true;
        }
        expect(page, 2);
        expect(asOf, fixture.now.toIso8601String());
        started.complete();
        return response.future;
      });
    await service.bindUser(staff('a'));
    final pending = service.fetchOnline(fixture.query());
    final check = expectLater(pending, throwsStateError);
    await started.future;
    await service.bindUser(null);
    response.complete(fixture.page(fixture.query())
      ..['page'] = 2..['pageSize'] = 1..['items'] = []);
    await check;
    expect(await db.customSelect('SELECT * FROM scoped_sensor_history_cache').get(), isEmpty);
  });

  test('v3 database upgrades to v4 without copying legacy cache', () async {
    final dir = await Directory.systemTemp.createTemp('history-migration-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.sqlite');
    final old = AppDatabase.forTesting(NativeDatabase(file));
    await old.customStatement('DROP TABLE scoped_sensor_history_cache');
    await old.customStatement(
      'INSERT INTO water_quality_readings (id,sensor_id,farm_id,timestamp) '
      'VALUES (?,?,?,?)', ['legacy', 'sensor', 'area', 1700000000]);
    await old.customStatement('PRAGMA user_version = 3');
    await old.close();
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    final version = await upgraded.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 4);
    expect(await upgraded.customSelect('SELECT * FROM scoped_sensor_history_cache').get(), isEmpty);
    expect(await upgraded.customSelect('SELECT * FROM water_quality_readings').get(), hasLength(1));
  });

  test('invalidates revision synchronously before SQLite purge completes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final cache = ScopedHistoryCache(db, clock: () => fixture.now);
    final service = ScopedHistoryService(cache: cache,
      identity: () async => const HistoryIdentity('a', 'token-a'),
      loadPage: (q, page, asOf, id) async => fixture.page(q));
    await service.bindUser(staff('a'));
    await service.fetchOnline(fixture.query());
    final seen = <int>[];
    final sub = service.invalidations.listen(seen.add);
    addTearDown(sub.cancel);
    final previous = service.revision;
    final purge = service.bindUser(null);
    expect(service.revision, previous + 1);
    expect(seen, [previous + 1]);
    await purge;
    expect(await db.customSelect('SELECT * FROM scoped_sensor_history_cache').get(),
      isEmpty);
    await expectLater(service.fetchOnline(fixture.query()), throwsStateError);
  });

  test('offline refuses even a previously cached exact query and purges it', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final cache = ScopedHistoryCache(db, clock: () => fixture.now);
    var online = true;
    var requests = 0;
    final service = ScopedHistoryService(cache: cache,
      networkAvailable: () async => online,
      identity: () async => const HistoryIdentity('a', 'token-a'),
      loadPage: (q, page, asOf, id) async {
        requests++;
        return fixture.page(q);
      });
    await service.bindUser(staff('a'));
    await service.fetchOnline(fixture.query());
    expect(requests, 1);
    expect(await db.customSelect('SELECT * FROM scoped_sensor_history_cache').get(),
      hasLength(1));
    online = false;
    await expectLater(service.fetchOnline(fixture.query()), throwsStateError);
    expect(requests, 1);
    expect(await db.customSelect('SELECT * FROM scoped_sensor_history_cache').get(),
      isEmpty);
    online = true;
    expect((await service.fetchOnline(fixture.query())).pointCount, 1);
    expect(requests, 2);
  });

  test('disconnect during HTTP response rejects data before saving', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final cache = ScopedHistoryCache(db, clock: () => fixture.now);
    var online = true;
    final started = Completer<void>();
    final pending = Completer<Map<String, dynamic>>();
    final service = ScopedHistoryService(cache: cache,
      networkAvailable: () async => online,
      identity: () async => const HistoryIdentity('a', 'token-a'),
      loadPage: (q, page, asOf, id) {
        started.complete();
        return pending.future;
      });
    await service.bindUser(staff('a'));
    final result = service.fetchOnline(fixture.query());
    final check = expectLater(result, throwsStateError);
    await started.future;
    online = false;
    pending.complete(fixture.page(fixture.query()));
    await check;
    expect(await db.customSelect('SELECT * FROM scoped_sensor_history_cache').get(),
      isEmpty);
  });
}
