import 'package:crabsensemobile/core/constants/api_constants.dart';
import 'package:crabsensemobile/core/errors/exceptions.dart';
import 'package:crabsensemobile/core/network/api_client.dart';
import 'package:crabsensemobile/shared/services/sync_queue_item.dart';
import 'package:crabsensemobile/shared/services/sync_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class FakeApiClient implements ApiClient {
  bool postCalled = false;
  bool getCalled = false;
  String? lastPostPath;
  Map<String, dynamic>? lastPostData;
  Map<String, dynamic>? lastGetQueryParams;
  bool shouldThrowOnPost = false;
  bool shouldThrowOnGet = false;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postCalled = true;
    lastPostPath = path;
    if (data is Map<String, dynamic>) {
      lastPostData = data;
    }
    if (shouldThrowOnPost) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network connection failed',
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{'success': true, 'processedCount': 1} as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getCalled = true;
    lastGetQueryParams = queryParameters;
    if (shouldThrowOnGet) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network error',
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{'changes': <String, dynamic>{}} as T,
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeApiClient fakeApiClient;
  late Logger logger;
  late SyncRemoteDataSource remoteDataSource;

  setUp(() {
    fakeApiClient = FakeApiClient();
    logger = Logger(printer: PrettyPrinter(enabled: false));
    remoteDataSource = SyncRemoteDataSourceImpl(
      apiClient: fakeApiClient,
      logger: logger,
    );
  });

  final testItem = SyncQueueItem(
    id: 'item-001',
    operationType: 'record_harvest',
    entityId: 'h-001',
    entityType: SyncEntityType.harvest,
    payload: const {'weight': 20.5},
    createdAt: DateTime(2026, 7, 21, 10, 0),
    priority: SyncPriority.high,
  );

  group('SyncRemoteDataSource', () {
    test('uploadBatch returns early success when items list is empty', () async {
      final result = await remoteDataSource.uploadBatch([]);
      expect(result['success'], isTrue);
      expect(result['processedCount'], 0);
      expect(fakeApiClient.postCalled, isFalse);
    });

    test('uploadBatch posts items to ApiConstants.uploadBatch endpoint', () async {
      final result = await remoteDataSource.uploadBatch([testItem]);

      expect(result['success'], isTrue);
      expect(fakeApiClient.postCalled, isTrue);
      expect(fakeApiClient.lastPostPath, ApiConstants.uploadBatch);
      expect(fakeApiClient.lastPostData, isNotNull);
      expect(fakeApiClient.lastPostData!['items'], isA<List>());
    });

    test('uploadBatch throws ServerException when HTTP call fails', () async {
      fakeApiClient.shouldThrowOnPost = true;

      expect(
        () => remoteDataSource.uploadBatch([testItem]),
        throwsA(isA<ServerException>()),
      );
    });

    test('downloadServerChanges passes since queryParam when provided', () async {
      final since = DateTime(2026, 7, 20, 12, 0);

      final result = await remoteDataSource.downloadServerChanges(since: since);

      expect(result['changes'], isNotNull);
      expect(fakeApiClient.getCalled, isTrue);
      expect(
        fakeApiClient.lastGetQueryParams?['since'],
        since.toIso8601String(),
      );
    });

    test('downloadServerChanges throws ServerException on failure', () async {
      fakeApiClient.shouldThrowOnGet = true;

      expect(
        () => remoteDataSource.downloadServerChanges(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
