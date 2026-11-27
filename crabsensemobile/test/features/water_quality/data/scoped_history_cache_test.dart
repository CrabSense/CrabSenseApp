import 'dart:convert';

import 'package:crabsensemobile/core/database/database.dart';
import 'package:crabsensemobile/features/water_quality/data/datasources/scoped_history_cache.dart';
import 'package:crabsensemobile/features/water_quality/data/models/scoped_history_snapshot.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const area = '11111111-1111-1111-1111-111111111111';
const sensor = '22222222-2222-2222-2222-222222222222';
const row = '33333333-3333-3333-3333-333333333333';
const point = '44444444-4444-4444-4444-444444444444';
final now = DateTime.utc(2026, 11, 27, 12);

ScopedHistoryQuery query({String areaId = area, String? rowId = row}) =>
    ScopedHistoryQuery(areaId: areaId, sensorId: sensor, rowId: rowId,
      from: now.subtract(const Duration(hours: 1)), to: now);

Map<String, dynamic> page(ScopedHistoryQuery q) => {
  'contract': 'scoped-sensor-history-v1', 'farmingAreaId': q.areaId,
  'sensorId': sensor, 'farmingRowId': row, 'sensorType': 'Salinity',
  'unit': 'ppt', 'sensorActive': true, 'from': q.from.toIso8601String(),
  'to': q.to.toIso8601String(), 'asOf': now.toIso8601String(),
  'page': 1, 'pageSize': 250, 'hasMore': false,
  'legacyUnqualifiedExcluded': true,
  'scopeBasis': 'configured_location_at_ingest',
  'physicalLocationVerified': false, 'databaseSnapshotGuaranteed': false,
  'chemicalResultIncluded': false,
  'items': [
    {'id': point, 'sensorId': sensor, 'value': 0, 'unit': 'ppt',
      'measuredAt': q.from.toIso8601String(),
      'receivedAt': now.toIso8601String(), 'dataQuality': 'Realtime',
      'farmingAreaId': q.areaId, 'farmingRowId': row,
      'sensorType': 'Salinity', 'source': 'edge'},
  ],
};

void main() {
  test('strict decoder preserves zero; rejects missing value and incomplete pages', () {
    final q = query();
    final p = page(q);
    final snapshot = ScopedHistorySnapshot.fromPages(q, [p]);
    expect(snapshot.pointCount, 1);
    expect(jsonDecode(snapshot.encodedPages)[0]['items'][0]['value'], 0);
    (p['items'] as List).first['value'] = null;
    expect(() => ScopedHistorySnapshot.fromPages(q, [p]), throwsFormatException);
    expect(() => ScopedHistorySnapshot.fromPages(q, [page(q)..['hasMore'] = true]),
      throwsFormatException);
    expect(() => ScopedHistorySnapshot.fromPages(q, [page(q)..['unit'] = 'mg/L']),
      throwsFormatException);
    expect(() => ScopedHistorySnapshot.fromPages(q, [page(q)..['chemicalResultIncluded'] = true]),
      throwsFormatException);
  });

  test('SQLite exact scope, expiry, logout and stale write rejection', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    var time = now;
    final cache = ScopedHistoryCache(db, clock: () => time);
    final q = query();
    final snapshot = ScopedHistorySnapshot.fromPages(q, [page(q)]);
    final first = await cache.beginSession('user-a');
    expect(await cache.saveOnline(first, snapshot), isTrue);
    expect((await cache.read(first, q))?.pointCount, 1);
    expect(await cache.read(first, query(rowId: null)), isNull);
    expect(await cache.read(first, query(areaId: point)), isNull);
    time = now.add(const Duration(minutes: 6));
    expect(await cache.read(first, q), isNull);
    time = now;
    final second = await cache.beginSession('user-b');
    expect(await cache.read(first, q), isNull);
    expect(await cache.read(second, q), isNull);
    expect(await cache.saveOnline(first, snapshot), isFalse);
    expect(await cache.saveOnline(second, snapshot), isTrue);
    final pending = cache.saveOnline(second, snapshot);
    await cache.revokeScope();
    expect(await pending, isFalse);
    expect(await cache.read(second, q), isNull);
    final rows = await db.customSelect('SELECT * FROM scoped_sensor_history_cache').get();
    expect(rows, isEmpty);
  });
}
