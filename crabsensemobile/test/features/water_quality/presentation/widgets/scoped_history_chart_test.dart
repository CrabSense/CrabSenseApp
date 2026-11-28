import 'dart:async';

import 'package:crabsensemobile/features/water_quality/data/models/scoped_history_snapshot.dart';
import 'package:crabsensemobile/features/water_quality/domain/entities/water_quality.dart';
import 'package:crabsensemobile/features/water_quality/presentation/models/scoped_history_series.dart';
import 'package:crabsensemobile/features/water_quality/presentation/widgets/scoped_history_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/scoped_history_cache_test.dart' as fixture;

WaterQuality reading({String area = fixture.area}) => WaterQuality(
  id: fixture.point, sensorId: fixture.sensor, farmId: area,
  pondId: fixture.row, temperature: null, ph: null, dissolvedOxygen: null,
  salinity: 0, timestamp: fixture.now, isAlertTriggered: false,
);

ScopedHistorySnapshot response(ScopedHistoryQuery q) {
  final p = fixture.page(q)..['asOf'] = q.to.toIso8601String();
  (p['items'] as List<Map<String, dynamic>>).first['receivedAt'] =
      q.to.toIso8601String();
  return ScopedHistorySnapshot.fromPages(q, [p]);
}

void main() {
  test('selects only explicit area/row and preserves zero without merging sensors', () {
    final readings = [reading(), reading(area: fixture.point)];
    expect(historySensors('default', null, readings), isEmpty);
    expect(historySensors(fixture.area, fixture.point, readings), isEmpty);
    final sensor = historySensors(fixture.area, null, readings).single;
    expect(sensor.rowId, fixture.row);
    expect(sensor.metric, HistoryMetric.salinity);
    final series = HistorySeries.fromSnapshot(sensor, response(fixture.query()));
    expect(series.points.single.value, 0);
    expect(series.points.single.at, fixture.query().from);
    final wrong = HistorySensor(fixture.area, fixture.row, fixture.sensor,
      HistoryMetric.oxygen);
    expect(() => HistorySeries.fromSnapshot(wrong, response(fixture.query())),
      throwsFormatException);
  });

  testWidgets('plots real zero, then clears on credential invalidation and scope change', (tester) async {
    final changes = StreamController<int>.broadcast(sync: true);
    addTearDown(changes.close);
    var revision = 0;
    Future<ScopedHistorySnapshot> fetch(ScopedHistoryQuery q) async => response(q);
    Widget view(String area) => MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ScopedHistoryChart(areaId: area, rowId: null,
        readings: [reading()], online: true, fetch: fetch,
        revision: () => revision, invalidations: changes.stream),
    )));
    await tester.pumpWidget(view(fixture.area));
    await tester.tap(find.byKey(const Key('history-sensor-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Độ mặn ·').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-fetch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-measured-plot')), findsOneWidget);
    revision++;
    changes.add(revision);
    // The production stream is synchronous. Exactly the next frame must
    // remove the old plot; do not wait for the one-minute expiry timer.
    await tester.pump();
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    expect(find.text('Phiên hoặc quyền truy cập thay đổi. Hãy tải lại.'),
      findsOneWidget);
    await tester.pumpWidget(view(fixture.point));
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    expect(find.byKey(const Key('history-fetch')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ignores old response after switching scope', (tester) async {
    final changes = StreamController<int>.broadcast(sync: true);
    addTearDown(changes.close);
    final pending = Completer<ScopedHistorySnapshot>();
    ScopedHistoryQuery? sent;
    Future<ScopedHistorySnapshot> fetch(ScopedHistoryQuery q) {
      sent = q;
      return pending.future;
    }
    Widget view(String area) => MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ScopedHistoryChart(areaId: area, rowId: null,
        readings: [reading()], online: true, fetch: fetch,
        revision: () => 0, invalidations: changes.stream),
    )));
    await tester.pumpWidget(view(fixture.area));
    await tester.tap(find.byKey(const Key('history-sensor-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Độ mặn ·').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-fetch')));
    await tester.pump();
    expect(sent, isNotNull);
    await tester.pumpWidget(view(fixture.point));
    pending.complete(response(sent!));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ignores pending response after credential invalidation', (tester) async {
    final changes = StreamController<int>.broadcast(sync: true);
    addTearDown(changes.close);
    var revision = 0;
    final pending = Completer<ScopedHistorySnapshot>();
    ScopedHistoryQuery? sent;
    Future<ScopedHistorySnapshot> fetch(ScopedHistoryQuery q) {
      sent = q;
      return pending.future;
    }
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ScopedHistoryChart(areaId: fixture.area, rowId: null,
        readings: [reading()], online: true, fetch: fetch,
        revision: () => revision, invalidations: changes.stream),
    ))));
    await tester.tap(find.byKey(const Key('history-sensor-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Độ mặn ·').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-fetch')));
    await tester.pump();
    expect(sent, isNotNull);
    revision++;
    changes.add(revision);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    pending.complete(response(sent!));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('offline hides chart and reconnect requires a new explicit load', (tester) async {
    final changes = StreamController<int>.broadcast(sync: true);
    addTearDown(changes.close);
    var requests = 0;
    Future<ScopedHistorySnapshot> fetch(ScopedHistoryQuery q) async {
      requests++;
      return response(q);
    }
    Widget view(bool online) => MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ScopedHistoryChart(areaId: fixture.area, rowId: null,
        readings: [reading()], online: online, fetch: fetch,
        revision: () => 0, invalidations: changes.stream),
    )));
    await tester.pumpWidget(view(true));
    await tester.tap(find.byKey(const Key('history-sensor-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Độ mặn ·').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-fetch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-measured-plot')), findsOneWidget);
    await tester.pumpWidget(view(false));
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    expect(find.byKey(const Key('history-fetch')), findsNothing);
    expect(find.text('Mất kết nối. Không hiển thị cache lịch sử.'), findsOneWidget);
    await tester.pumpWidget(view(true));
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    expect(requests, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('background clears chart and late response cannot restore it', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final changes = StreamController<int>.broadcast(sync: true);
    addTearDown(changes.close);
    final pending = Completer<ScopedHistorySnapshot>();
    ScopedHistoryQuery? sent;
    var requests = 0;
    Future<ScopedHistorySnapshot> fetch(ScopedHistoryQuery q) async {
      requests++;
      sent = q;
      return requests == 1 ? response(q) : pending.future;
    }
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ScopedHistoryChart(areaId: fixture.area, rowId: null,
        readings: [reading()], online: true, fetch: fetch,
        revision: () => 0, invalidations: changes.stream),
    ))));
    Future<void> choose() async {
      await tester.tap(find.byKey(const Key('history-sensor-select')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Độ mặn ·').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-fetch')));
      await tester.pump();
    }
    await choose();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-measured-plot')), findsOneWidget);
    // Simulate OS lifecycle while parent still supplies online=true.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    expect(find.byKey(const Key('history-fetch')), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    expect(requests, 1);
    await choose();
    expect(requests, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    pending.complete(response(sent!));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-measured-plot')), findsNothing);
    expect(requests, 2);
    await tester.pumpWidget(const SizedBox());
  });
}
