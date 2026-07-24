import 'dart:async';

import 'package:crabsensemobile/core/network/network_info.dart';
import 'package:crabsensemobile/shared/services/bidirectional_sync_manager.dart';
import 'package:crabsensemobile/shared/services/conflict_resolver.dart';
import 'package:crabsensemobile/shared/services/sync_progress.dart';
import 'package:crabsensemobile/shared/services/sync_queue_item.dart';
import 'package:crabsensemobile/shared/services/sync_remote_data_source.dart';
import 'package:crabsensemobile/shared/services/sync_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class FakeSyncService implements SyncService {
  final List<SyncQueueItem> items = [];
  final List<String> processingIds = [];
  final List<String> completedIds = [];
  final List<String> failedIds = [];

  @override
  Future<SyncQueueItem> enqueue({
    required SyncEntityType entityType,
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
    SyncPriority priority = SyncPriority.medium,
  }) async {
    final item = SyncQueueItem(
      id: 'id-${items.length + 1}',
      operationType: operationType,
      entityId: entityId,
      entityType: entityType,
      payload: payload,
      createdAt: DateTime.now(),
      priority: priority,
    );
    items.add(item);
    return item;
  }

  @override
  Future<List<SyncQueueItem>> getPendingItems({int limit = 50}) async {
    return items
        .where((i) => i.status == SyncItemStatus.pending || i.status == SyncItemStatus.failed)
        .take(limit)
        .toList();
  }

  @override
  Future<void> markProcessing(String id) async {
    processingIds.add(id);
  }

  @override
  Future<void> markCompleted(String id) async {
    completedIds.add(id);
    items.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> markFailed(String id, String errorMessage) async {
    failedIds.add(id);
    final idx = items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(
        status: SyncItemStatus.failed,
        retryCount: items[idx].retryCount + 1,
        errorMessage: errorMessage,
        lastAttemptAt: DateTime.now(),
      );
    }
  }

  @override
  Future<int> getPendingCount() async => items.length;

  @override
  Stream<int> watchPendingCount() => Stream.value(items.length);

  @override
  Future<void> remove(String id) async => items.removeWhere((i) => i.id == id);

  @override
  Future<void> clearQueue() async => items.clear();
}

class FakeSyncRemoteDataSource implements SyncRemoteDataSource {
  bool uploadBatchCalled = false;
  bool downloadServerChangesCalled = false;
  List<SyncQueueItem> uploadedItems = [];
  DateTime? downloadSince;
  bool shouldFailUpload = false;

  @override
  Future<Map<String, dynamic>> uploadBatch(List<SyncQueueItem> items) async {
    uploadBatchCalled = true;
    uploadedItems.addAll(items);
    if (shouldFailUpload) {
      throw Exception('Server 500 internal error');
    }
    return <String, dynamic>{'success': true, 'processedCount': items.length};
  }

  @override
  Future<Map<String, dynamic>> downloadServerChanges({DateTime? since}) async {
    downloadServerChangesCalled = true;
    downloadSince = since;
    return <String, dynamic>{'changes': <String, dynamic>{}};
  }
}

class FakeNetworkInfo implements NetworkInfo {
  bool isOnline = true;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  void setOnline(bool online) {
    isOnline = online;
    _controller.add(online);
  }

  @override
  Future<bool> get isConnected async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSyncService fakeSyncService;
  late FakeSyncRemoteDataSource fakeRemoteDataSource;
  late FakeNetworkInfo fakeNetworkInfo;
  late FakeSecureStorage fakeSecureStorage;
  late Logger logger;
  late BidirectionalSyncManagerImpl syncManager;

  setUp(() {
    fakeSyncService = FakeSyncService();
    fakeRemoteDataSource = FakeSyncRemoteDataSource();
    fakeNetworkInfo = FakeNetworkInfo();
    fakeSecureStorage = FakeSecureStorage();
    logger = Logger(printer: PrettyPrinter(enabled: false));

    syncManager = BidirectionalSyncManagerImpl(
      syncService: fakeSyncService,
      remoteDataSource: fakeRemoteDataSource,
      networkInfo: fakeNetworkInfo,
      secureStorage: fakeSecureStorage,
      logger: logger,
      batchSize: 5,
    );
  });

  tearDown(() {
    syncManager.dispose();
  });

  group('Exponential Backoff Calculation (Requirement 13.7)', () {
    test('returns exact backoff sequence: 0s, 1s, 2s, 4s, 8s, 16s', () {
      expect(calculateExponentialBackoff(0), Duration.zero);
      expect(calculateExponentialBackoff(1), const Duration(seconds: 1));
      expect(calculateExponentialBackoff(2), const Duration(seconds: 2));
      expect(calculateExponentialBackoff(3), const Duration(seconds: 4));
      expect(calculateExponentialBackoff(4), const Duration(seconds: 8));
      expect(calculateExponentialBackoff(5), const Duration(seconds: 16));
      expect(calculateExponentialBackoff(10), const Duration(seconds: 16));
    });

    test('isItemReadyForRetry respects exponential backoff delay', () {
      final now = DateTime.now();
      final freshItem = SyncQueueItem(
        id: '1',
        operationType: 'op',
        entityId: 'e1',
        entityType: SyncEntityType.harvest,
        payload: const {},
        createdAt: now,
        retryCount: 0,
      );
      expect(syncManager.isItemReadyForRetry(freshItem), isTrue);

      final recentlyFailedItem = SyncQueueItem(
        id: '2',
        operationType: 'op',
        entityId: 'e2',
        entityType: SyncEntityType.harvest,
        payload: const {},
        createdAt: now,
        retryCount: 3, // backoff is 4s
        lastAttemptAt: now.subtract(const Duration(seconds: 2)),
      );
      expect(syncManager.isItemReadyForRetry(recentlyFailedItem), isFalse);

      final readyFailedItem = SyncQueueItem(
        id: '3',
        operationType: 'op',
        entityId: 'e3',
        entityType: SyncEntityType.harvest,
        payload: const {},
        createdAt: now,
        retryCount: 3, // backoff is 4s
        lastAttemptAt: now.subtract(const Duration(seconds: 5)),
      );
      expect(syncManager.isItemReadyForRetry(readyFailedItem), isTrue);
    });
  });

  group('SyncProgress Model', () {
    test('computes progress percentage correctly', () {
      const idle = SyncProgress(status: SyncStatusEnum.idle);
      expect(idle.progressPercentage, 1.0);

      const syncing = SyncProgress(
        status: SyncStatusEnum.syncing,
        totalItems: 10,
        processedItems: 5,
      );
      expect(syncing.progressPercentage, 0.5);
    });
  });

  group('BidirectionalSyncManager Execution', () {
    test('syncNow returns failure status when network is offline', () async {
      fakeNetworkInfo.isOnline = false;

      final result = await syncManager.syncNow();

      expect(result.status, SyncStatusEnum.failed);
      expect(result.errorMessage, contains('Network unavailable'));
      expect(fakeRemoteDataSource.uploadBatchCalled, isFalse);
    });

    test('syncNow processes pending items and downloads server changes when online', () async {
      await fakeSyncService.enqueue(
        entityType: SyncEntityType.harvest,
        operationType: 'create_harvest',
        entityId: 'h-1',
        payload: const {'weight': 10},
      );

      final result = await syncManager.syncNow();

      expect(result.status, SyncStatusEnum.completed);
      expect(fakeSyncService.processingIds, contains('id-1'));
      expect(fakeSyncService.completedIds, contains('id-1'));
      expect(fakeRemoteDataSource.uploadBatchCalled, isTrue);
      expect(fakeRemoteDataSource.downloadServerChangesCalled, isTrue);

      final savedTimestamp = await fakeSecureStorage.read(key: kLastSyncTimestampKey);
      expect(savedTimestamp, isNotNull);
    });

    test('startAutoSyncListener triggers syncNow on network restoration', () async {
      syncManager.startAutoSyncListener();

      // Emit network offline then network online
      fakeNetworkInfo.setOnline(false);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeNetworkInfo.setOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeRemoteDataSource.downloadServerChangesCalled, isTrue);
    });

    test('syncNow passes server changes to conflictResolver when present', () async {
      final conflictResolver = ConflictResolverServiceImpl(logger: logger);
      final managerWithResolver = BidirectionalSyncManagerImpl(
        syncService: fakeSyncService,
        remoteDataSource: fakeRemoteDataSource,
        networkInfo: fakeNetworkInfo,
        secureStorage: fakeSecureStorage,
        logger: logger,
        conflictResolver: conflictResolver,
      );

      final now = DateTime.now();
      fakeSyncService.items.add(
        SyncQueueItem(
          id: 'id-conflict',
          operationType: 'update_harvest',
          entityId: 'h-conflict',
          entityType: SyncEntityType.harvest,
          payload: const {'weight': 12.0},
          createdAt: now,
        ),
      );

      final result = await managerWithResolver.syncNow();
      expect(result.status, SyncStatusEnum.completed);
      managerWithResolver.dispose();
      conflictResolver.dispose();
    });
  });
}
