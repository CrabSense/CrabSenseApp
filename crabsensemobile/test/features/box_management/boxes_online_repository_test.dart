import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crabsensemobile/core/network/api_client.dart';
import 'package:crabsensemobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:crabsensemobile/features/box_management/data/repositories/boxes_repository_impl.dart';
import 'package:crabsensemobile/features/water_quality/data/repositories/scoped_history_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:hive/hive.dart';

class _Auth implements AuthLocalDataSource {
  @override
  Future<String> getAccessToken() async => throw StateError('Must use pinned token');
  @override
  Future<String> getRefreshToken() async => throw StateError('Must not retry');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const areaA = '00000000-0000-0000-0000-000000000001';
const areaB = '00000000-0000-0000-0000-000000000002';

Map<String, dynamic> envelope(Object data) => {'success': true, 'data': data};
Map<String, dynamic> overview(String area, {String? itemArea}) => envelope({
  'farmingAreaId': area,
  'syncedAt': '2026-11-28T05:00:00Z',
  'summary': {'total': 1},
  'items': [{
    'id': 'box-$area', 'code': 'BOX-$area', 'farmingAreaId': itemArea ?? area,
    'crabCount': 0, 'status': 'empty', 'lastUpdated': '2026-11-28T05:00:00Z',
  }],
});

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  bool emptyAreas = false;
  bool wrongArea = false;
  bool badEnvelope = false;
  Completer<void>? delayA;
  Completer<void>? startedA;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    requests.add(options);
    final path = options.uri.path;
    Object body;
    var code = 200;
    if (path.endsWith('/farming-areas')) {
      body = envelope({'items': emptyAreas ? [] : [
        {'id': areaA, 'name': 'A'}, {'id': areaB, 'name': 'B'},
      ]});
    } else if (path.endsWith('/boxes/overview')) {
      final area = options.queryParameters['farmingAreaId'] as String;
      if (area == areaA && delayA != null) {
        startedA?.complete();
        await delayA!.future;
      }
      code = status;
      body = badEnvelope ? {'success': false} :
          overview(area, itemArea: wrongArea ? areaB : null);
    } else {
      throw StateError('Unexpected legacy request: $path');
    }
    return ResponseBody.fromString(jsonEncode(body), code,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient api;
  late _Adapter adapter;
  late BoxesRepositoryImpl repo;
  late HistoryIdentity identity;
  late int revision;
  late bool online;
  setUp(() async {
    final preferencesDir = await Directory.systemTemp.createTemp('boxes-online-test-');
    Hive.init(preferencesDir.path);
    addTearDown(() async {
      await Hive.close();
      await preferencesDir.delete(recursive: true);
    });
    // Initialize real preference storage before exercising the repository.
    await Hive.openBox<dynamic>('ui_prefs');
    identity = const HistoryIdentity('staff-a', 'fixture-pinned');
    revision = 0;
    online = true;
    api = ApiClient(logger: Logger(), authLocalDataSource: _Auth());
    adapter = _Adapter();
    api.dio.httpClientAdapter = adapter;
    repo = BoxesRepositoryImpl(api: api, identity: () async => identity,
      revision: () => revision, boundUser: (_) => true,
      networkAvailable: () async => online);
    addTearDown(() => api.dio.close(force: true));
  });

  test('every load revalidates online and never returns an old snapshot after HTTP failure', () async {
    expect((await repo.getBoxesSummary(farmingAreaId: areaA)).allBoxes.single.farmId, areaA);
    for (final status in [404, 401, 403, 500]) {
      adapter.status = status;
      final before = adapter.requests.length;
      await expectLater(repo.getBoxesSummary(farmingAreaId: areaA), throwsA(isA<DioException>()));
      expect(adapter.requests.length - before, 2);
      expect(adapter.requests.last.uri.path, endsWith('/boxes/overview'));
    }
    for (final req in adapter.requests) {
      expect(req.headers['Authorization'], 'Bearer fixture-pinned');
      expect(req.extra['skipTokenRefresh'], isTrue);
      expect(req.extra['skipSensitiveLogging'], isTrue);
      expect(req.followRedirects, isFalse);
    }
    final count = adapter.requests.length;
    online = false;
    await expectLater(repo.getBoxesSummary(), throwsStateError);
    expect(adapter.requests.length, count);
  });

  test('reject wrong-area item and malformed envelope; no unscoped overview', () async {
    adapter.wrongArea = true;
    await expectLater(repo.getBoxesSummary(farmingAreaId: areaA), throwsFormatException);
    adapter.wrongArea = false;
    adapter.badEnvelope = true;
    await expectLater(repo.getBoxesSummary(farmingAreaId: areaA), throwsFormatException);
    adapter.badEnvelope = false;
    adapter.emptyAreas = true;
    final before = adapter.requests.length;
    final empty = await repo.getBoxesSummary(farmingAreaId: areaA);
    expect(empty.selectedFarmId, isNull);
    expect(empty.allBoxes, isEmpty);
    expect(adapter.requests.length - before, 1);
    adapter.emptyAreas = false;
    final allowed = await repo.getBoxesSummary(farmingAreaId: 'revoked-area');
    expect(allowed.selectedFarmId, areaA);
    expect(adapter.requests.last.queryParameters['farmingAreaId'], areaA);
  });

  test('late previous-area response cannot publish after new load', () async {
    adapter.delayA = Completer<void>();
    adapter.startedA = Completer<void>();
    final previous = repo.getBoxesSummary(farmingAreaId: areaA);
    final rejected = expectLater(previous, throwsStateError);
    await adapter.startedA!.future;
    final next = await repo.getBoxesSummary(farmingAreaId: areaB);
    expect(next.allBoxes.single.farmId, areaB);
    adapter.delayA!.complete();
    await rejected;
  });

  test('credential generation changes invalidate an in-flight response', () async {
    adapter.delayA = Completer<void>();
    adapter.startedA = Completer<void>();
    final previous = repo.getBoxesSummary(farmingAreaId: areaA);
    final rejected = expectLater(previous, throwsStateError);
    await adapter.startedA!.future;
    revision++;
    identity = const HistoryIdentity('staff-b', 'fixture-new');
    repo.invalidate();
    adapter.delayA!.complete();
    await rejected;
  });
}
