import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crabsensemobile/core/network/api_client.dart';
import 'package:crabsensemobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:crabsensemobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:crabsensemobile/features/water_quality/data/repositories/scoped_history_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _Auth implements AuthLocalDataSource {
  @override
  Future<String> getAccessToken() async => throw StateError('Use pinned token');
  @override
  Future<String> getRefreshToken() async => throw StateError('No token retry');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const a = '00000000-0000-0000-0000-000000000001';
const b = '00000000-0000-0000-0000-000000000002';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool noAreas = false;
  bool wrongBox = false;
  bool wrongActor = false;
  int overviewStatus = 200;
  Completer<void>? startedA;
  Completer<void>? delayA;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    requests.add(options);
    final path = options.uri.path;
    final area = options.queryParameters['farmingAreaId'];
    Object data;
    var status = 200;
    if (path.endsWith('/auth/me')) {
      data = {'id': wrongActor ? 'other' : 'staff', 'fullName': 'Staff'};
    } else if (path.endsWith('/farming-areas')) {
      data = {'items': noAreas ? [] : [
        {'id': a, 'name': 'A'}, {'id': b, 'name': 'B'}
      ]};
    } else if (path.endsWith('/notifications/unread/count')) {
      data = {'count': 3};
    } else {
      if (area != a && area != b) throw StateError('Unscoped Home query: $path');
      if (path.endsWith('/boxes/overview')) {
        data = {'farmingAreaId': area, 'summary': {'total': 1}, 'items': [{
          'id': 'box-$area', 'farmingAreaId': wrongBox ? (area == a ? b : a) : area,
          'isOccupied': false, 'crabCount': 0,
        }]};
      } else if (path.endsWith('/dashboard/overview')) {
        if (area == a && delayA != null) {
          startedA!.complete();
          await delayA!.future;
        }
        status = overviewStatus;
        data = {'totalBoxes': area == a ? 1 : 2, 'totalCrabs': 0,
          'activeBoxes': 0, 'openAlerts': 0, 'iotOnlinePercentage': 0,
          'lastUpdated': '2026-11-28T05:00:00Z'};
      } else if (path.endsWith('/dashboard/metrics')) {
        data = {'score': 70, 'statusLevel': 'good'};
      } else if (path.endsWith('/alerts') || path.endsWith('/iot/live') ||
          path.endsWith('/devices') || path.endsWith('/ai/recommendations') ||
          path.endsWith('/operations/today') ||
          path.endsWith('/operations/scheduled-tasks') ||
          path.endsWith('/operations/recent')) {
        data = <Object>[];
      } else {
        throw StateError('Unexpected Home request: $path');
      }
    }
    return ResponseBody.fromString(jsonEncode({'success':status==200,'data':data}),
      status, headers:{Headers.contentTypeHeader:[Headers.jsonContentType]});
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  late ApiClient api;
  late _Adapter adapter;
  late HomeRepositoryImpl repo;
  late HistoryIdentity identity;
  late int revision;
  late bool online;
  setUp(() {
    identity = const HistoryIdentity('staff', 'fixture');
    revision = 0;
    online = true;
    api = ApiClient(logger: Logger(), authLocalDataSource: _Auth());
    adapter = _Adapter();
    api.dio.httpClientAdapter = adapter;
    repo = HomeRepositoryImpl(api: api, identity: () async => identity,
      revision: () => revision, boundUser: (id) => id == 'staff',
      networkAvailable: () async => online);
    addTearDown(() {
      final pending = adapter.delayA;
      if (pending != null && !pending.isCompleted) pending.complete();
      api.dio.close(force:true);
    });
  });

  test('fresh authorized area only, no unscoped histories or credential retry', () async {
    final data = await repo.getHomeSummary(farmingAreaId:'revoked');
    expect(data.selectedFarmId,a);
    expect(data.unreadNotificationsCount,3);
    expect(data.farmSummary.openAlerts,0);
    expect(data.feedingHistory,isEmpty);
    expect(data.boxStatusHistory,isEmpty);
    expect(adapter.requests.where((req) =>
      req.uri.path.endsWith('/operations/scheduled-tasks')), hasLength(1));
    expect(adapter.requests.where((req) =>
      req.uri.path.endsWith('/operations/scheduled-tasks/today')), isEmpty);
    for(final req in adapter.requests) {
      expect(req.headers['Authorization'],'Bearer fixture');
      expect(req.extra['skipTokenRefresh'],isTrue);
      expect(req.extra['skipSensitiveLogging'],isTrue);
      expect(req.followRedirects,isFalse);
      expect(req.uri.path, isNot(contains('feeding-history')));
      expect(req.uri.path, isNot(contains('status-history-daily')));
      if(!req.uri.path.endsWith('/auth/me') &&
          !req.uri.path.endsWith('/farming-areas') &&
          !req.uri.path.endsWith('/notifications/unread/count')) {
        expect(req.queryParameters['farmingAreaId'],a);
      }
    }
    adapter.noAreas = true;
    final before = adapter.requests.length;
    await expectLater(repo.getHomeSummary(farmingAreaId:a),throwsStateError);
    expect(adapter.requests.length-before,2);
  });

  test('errors, offline and actor mismatch do not return a prior snapshot', () async {
    await repo.getHomeSummary(farmingAreaId:a);
    for(final status in [401,403,404,500]) {
      adapter.overviewStatus = status;
      await expectLater(repo.getHomeSummary(farmingAreaId:a),throwsA(isA<DioException>()));
    }
    adapter.overviewStatus = 200;
    online = false;
    final before = adapter.requests.length;
    await expectLater(repo.getHomeSummary(farmingAreaId:a),throwsStateError);
    expect(adapter.requests.length,before);
    online = true;
    adapter.wrongActor = true;
    await expectLater(repo.getHomeSummary(farmingAreaId:a),throwsStateError);
    adapter.wrongActor = false;
    adapter.wrongBox = true;
    await expectLater(repo.getHomeSummary(farmingAreaId:a),throwsFormatException);
  });

  test('late old area cannot replace a newer authorized area', () async {
    adapter.startedA = Completer<void>();
    adapter.delayA = Completer<void>();
    final old = repo.getHomeSummary(farmingAreaId:a);
    final rejected = expectLater(old,throwsStateError);
    try {
      await adapter.startedA!.future.timeout(const Duration(seconds: 10));
      final current = await repo.getHomeSummary(farmingAreaId:b);
      expect(current.selectedFarmId,b);
      expect(current.farmSummary.totalBoxes,2);
    } finally {
      if (!adapter.delayA!.isCompleted) adapter.delayA!.complete();
      await rejected;
    }
  });

  test('late old credential response is rejected after invalidation', () async {
    adapter.startedA = Completer<void>();
    adapter.delayA = Completer<void>();
    final old = repo.getHomeSummary(farmingAreaId:a);
    final rejected = expectLater(old,throwsStateError);
    try {
      await adapter.startedA!.future.timeout(const Duration(seconds: 10));
      revision++;
      identity = const HistoryIdentity('staff','new-fixture');
      repo.invalidate();
    } finally {
      if (!adapter.delayA!.isCompleted) adapter.delayA!.complete();
      await rejected;
    }
  });
}
