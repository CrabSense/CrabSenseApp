import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crabsensemobile/core/network/api_client.dart';
import 'package:crabsensemobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:crabsensemobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:crabsensemobile/features/home/domain/models/home_models.dart';
import 'package:crabsensemobile/features/home/presentation/widgets/farm_health_score_card.dart';
import 'package:flutter/material.dart';
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
  bool missing = false;
  bool withDevices = false;
  bool sourceRecords = false;
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
      data = {'count': missing ? '0' : 3};
    } else {
      if (area != a && area != b) throw StateError('Unscoped Home query: $path');
      if (path.endsWith('/boxes/overview')) {
        data = {'farmingAreaId': area, 'summary': {'total': 1},
          'areaDevices': {'totalCount': withDevices ? 2 : 0, 'onlineCount': 0, 'isOnline': false},
          'items': [{
          'id': 'box-$area', 'farmingAreaId': wrongBox ? (area == a ? b : a) : area,
          'isOccupied': missing, 'crabCount': missing ? 1 : 0,
        }]};
      } else if (path.endsWith('/dashboard/overview')) {
        if (area == a && delayA != null) {
          startedA!.complete();
          await delayA!.future;
        }
        status = overviewStatus;
        data = {'totalBoxes': area == a ? 1 : 2, 'totalCrabs': missing ? null : 0,
          'activeBoxes': missing ? '0' : 0, 'openAlerts': missing ? false : 0, 'iotOnlinePercentage': 100,
          'lastUpdated': '2026-11-28T05:00:00Z'};
      } else if (path.endsWith('/alerts')) {
        data = sourceRecords ? [{'id':'alert-a','createdAt':null,'severity':'warning'}] : <Object>[];
      } else if (path.endsWith('/operations/today')) {
        data = sourceRecords ? [{'id':'task-a','deadline':'bad'}] : <Object>[];
      } else if (path.endsWith('/operations/scheduled-tasks/today')) {
        data = sourceRecords ? [{'id':'due-a','isEnabled':true,
          'nextRunAt':'2026-11-28T12:00:00Z'}] : <Object>[];
      } else if (path.endsWith('/operations/recent')) {
        data = sourceRecords ? [{'id':'act-a','timestamp':null}] : <Object>[];
      } else if (path.endsWith('/iot/live')) {
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
      req.uri.path.endsWith('/operations/scheduled-tasks')), isEmpty);
    expect(adapter.requests.where((req) =>
      req.uri.path.endsWith('/operations/scheduled-tasks/today')), hasLength(1));
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

  test('legacy assessment not queried; strict counts and source timestamps', () async {
    adapter.missing = true;
    adapter.sourceRecords = true;
    final data = await repo.getHomeSummary(farmingAreaId:a);
    expect(data.healthScore.score,isNull);
    expect(data.healthScore.lastAiUpdated,isNull);
    expect(data.healthScore.waterQualityScore,isNull);
    expect(data.aiRecommendation.hasActiveRecommendation,isFalse);
    expect(data.aiRecommendation.confidencePercentage,isNull);
    expect(data.farmSummary.totalCrabs,isNull);
    expect(data.farmSummary.activeBoxes,isNull);
    expect(data.farmSummary.openAlerts,isNull);
    expect(data.farmSummary.iotOnlinePercentage,isNull);
    expect(data.farmSummary.lastUpdated,isNull);
    expect(data.unreadNotificationsCount,isNull);
    expect(data.boxStatusCounts['unknown'],1);
    expect(data.topAlerts.single.timestamp,isNull);
    expect(data.recentActivities.single.timestamp,isNull);
    expect(data.todayTasks.first.deadline,isNull);
    expect(data.todayTasks.last.deadline,DateTime.utc(2026,11,28,12));
    expect(adapter.requests.any((r) => r.uri.path.endsWith('/dashboard/metrics') ||
      r.uri.path.endsWith('/ai/recommendations') || r.uri.path.endsWith('/devices')),isFalse);
    adapter.missing = false;
    adapter.withDevices = true;
    final valid = await repo.getHomeSummary(farmingAreaId:a);
    expect(valid.farmSummary.totalCrabs,0);
    expect(valid.farmSummary.openAlerts,0);
    expect(valid.farmSummary.iotOnlinePercentage,0);
    expect(valid.unreadNotificationsCount,3);
  });

  test('count, inventory and timestamp decoder preserve unknown separately from zero', () {
    for (final raw in [null, '0', false, -1, 1.5]) {
      expect(homeCount(raw),isNull);
    }
    expect(homeCount(0),0);
    expect(homeCountLabel(null),'—');
    expect(DeviceSummary.fromAreaInventory({'totalCount':0,'onlineCount':0,'isOnline':false}).percentage,isNull);
    expect(DeviceSummary.fromAreaInventory({'totalCount':2,'onlineCount':0,'isOnline':false}).percentage,0);
    expect(DeviceSummary.fromAreaInventory({'totalCount':2,'onlineCount':1,'isOnline':false}).percentage,isNull);
    final now = DateTime.utc(2026,11,28,6);
    for(final raw in [null,'bad','2026-02-30T05:00:00Z','2026-11-28T05:00:00','2026-11-28T08:00:00Z']) {
      expect(homeSourceTime(raw,now:now),isNull);
    }
    final source = homeSourceTime('2026-11-28T12:30:00+07:00',now:now);
    expect(source,DateTime.utc(2026,11,28,5,30));
    expect(homeTimeLabel(source,now:now),'30 phút trước');
    expect(homeTimeLabel(null,now:now),'Chưa có thời gian');
    expect(homeSourceTime('2026-11-28T08:00:00Z',now:now,allowFuture:true),DateTime.utc(2026,11,28,8));
  });

  testWidgets('home assessment card does not display a numeric or safety claim', (tester) async {
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:FarmHealthScoreCard(
      healthScore:FarmHealthScore.unavailable,onAnalysisPressed:(){}))));
    expect(find.textContaining('Chưa có đánh giá xác minh'),findsOneWidget);
    expect(find.textContaining('70/100'),findsNothing);
    expect(find.textContaining('ổn định'),findsNothing);
  });
}
