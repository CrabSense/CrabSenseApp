import 'dart:convert';
import 'dart:typed_data';

import 'package:crabsensemobile/core/network/api_client.dart';
import 'package:crabsensemobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:crabsensemobile/features/water_quality/data/repositories/scoped_history_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'scoped_history_cache_test.dart' as fixture;

class _AuthProbe implements AuthLocalDataSource {
  int accessReads = 0;
  int refreshReads = 0;

  @override
  Future<String> getAccessToken() async {
    accessReads++;
    return 'different-current-user';
  }

  @override
  Future<String> getRefreshToken() async {
    refreshReads++;
    throw StateError('History must never refresh the credential');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CaptureOutput extends LogOutput {
  final lines = <String>[];

  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

/// Exercises the actual Dio request pipeline and interceptors, without
/// connecting to production or issuing real JWTs.
class _HistoryAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body), status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (status == 302) 'location': ['https://example.invalid/history'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late ApiClient api;
  late _AuthProbe auth;
  late _HistoryAdapter adapter;
  late _CaptureOutput output;
  const identity = HistoryIdentity('user-a', 'fixture-pinned-token');

  setUp(() {
    auth = _AuthProbe();
    output = _CaptureOutput();
    api = ApiClient(logger: Logger(output: output), authLocalDataSource: auth);
    adapter = _HistoryAdapter();
    api.dio.httpClientAdapter = adapter;
    output.lines.clear();
    addTearDown(() => api.dio.close(force: true));
  });

  test('history uses exact scoped URL, cutoff and pinned bearer without logging', () async {
    final q = fixture.query();
    const cutoff = '2026-11-27T12:00:00.0000000Z';
    adapter.body = {'success': true, 'data': fixture.page(q)..['asOf'] = cutoff};
    final load = scopedHistoryHttpLoader(api);
    final first = await load(q, 1, null, identity);
    expect(first['asOf'], cutoff);
    await load(q, 2, cutoff, identity);
    expect(adapter.requests, hasLength(2));
    for (final req in adapter.requests) {
      expect(req.method, 'GET');
      expect(req.uri.path,
        '/api/areas/${q.areaId}/sensors/${q.sensorId}/history');
      expect(req.headers['Authorization'], 'Bearer fixture-pinned-token');
      expect(req.queryParameters['from'], q.from.toIso8601String());
      expect(req.queryParameters['to'], q.to.toIso8601String());
      expect(req.queryParameters['farmingRowId'], q.rowId);
      expect(req.queryParameters['pageSize'], 250);
      expect(req.followRedirects, isFalse);
      expect(req.extra['skipSensitiveLogging'], isTrue);
    }
    expect(adapter.requests.first.queryParameters['page'], 1);
    expect(adapter.requests.first.queryParameters.containsKey('asOf'), isFalse);
    expect(adapter.requests.last.queryParameters['page'], 2);
    expect(adapter.requests.last.queryParameters['asOf'], cutoff);
    expect(auth.accessReads, 0);
    expect(auth.refreshReads, 0);
    expect(output.lines, isEmpty);
  });

  for (final status in [401, 403, 302]) {
    test('HTTP $status never retries with another credential or redirect', () async {
      adapter.status = status;
      adapter.body = {'success': false, 'message': 'fixture-sensitive-body'};
      final load = scopedHistoryHttpLoader(api);
      await expectLater(load(fixture.query(), 1, null, identity),
        throwsA(isA<DioException>().having(
          (e) => e.response?.statusCode, 'status', status)));
      expect(adapter.requests, hasLength(1));
      expect(auth.accessReads, 0);
      expect(auth.refreshReads, 0);
      expect(output.lines, isEmpty);
    });
  }

  test('rejects invalid success envelopes without leaking body', () async {
    final load = scopedHistoryHttpLoader(api);
    for (final body in [
      {'success': false, 'data': fixture.page(fixture.query())},
      {'success': true, 'data': []},
      {'success': true},
    ]) {
      adapter.body = body;
      await expectLater(load(fixture.query(), 1, null, identity),
        throwsFormatException);
    }
    expect(adapter.requests, hasLength(3));
    expect(output.lines, isEmpty);
  });
}
