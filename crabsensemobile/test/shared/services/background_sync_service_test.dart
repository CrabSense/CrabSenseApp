import 'package:crabsensemobile/shared/services/background_sync_service.dart';
import 'package:crabsensemobile/shared/services/bidirectional_sync_manager.dart';
import 'package:crabsensemobile/shared/services/conflict_resolver.dart';
import 'package:crabsensemobile/shared/services/sync_progress.dart';
import 'package:crabsensemobile/shared/services/sync_queue_item.dart';
import 'package:crabsensemobile/shared/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:workmanager/workmanager.dart';

class FakeWorkmanager implements Workmanager {
  bool initialized = false;
  Function? callbackDispatcher;
  final List<Map<String, dynamic>> registeredTasks = [];
  final List<String> cancelledTasks = [];

  @override
  Future<void> initialize(Function callbackDispatcher, {bool? isInDebugMode}) async {
    initialized = true;
    this.callbackDispatcher = callbackDispatcher;
  }

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    OutOfQuotaPolicy? outOfQuotaPolicy,
    Map<String, dynamic>? inputData,
    String? tag,
  }) async {
    registeredTasks.add({
      'uniqueName': uniqueName,
      'taskName': taskName,
      'frequency': frequency,
      'constraints': constraints,
    });
  }

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {
    cancelledTasks.add(uniqueName);
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelByTag(String tag) async {}

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    Duration? initialDelay,
    Constraints? constraints,
    ExistingWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    OutOfQuotaPolicy? outOfQuotaPolicy,
    Map<String, dynamic>? inputData,
    String? tag,
  }) async {}

  @override
  Future<void> printScheduledTasks() async {}
}

class FakeSyncServiceForBg implements SyncService {
  int mockPendingCount = 0;

  @override
  Future<int> getPendingCount() async => mockPendingCount;

  @override
  Future<SyncQueueItem> enqueue({
    required SyncEntityType entityType,
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
    SyncPriority priority = SyncPriority.medium,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<SyncQueueItem>> getPendingItems({int limit = 50}) async => [];

  @override
  Future<void> markProcessing(String id) async {}

  @override
  Future<void> markCompleted(String id) async {}

  @override
  Future<void> markFailed(String id, String errorMessage) async {}

  @override
  Stream<int> watchPendingCount() => Stream.value(mockPendingCount);

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> clearQueue() async {}
}

class FakeBidirectionalSyncManagerForBg implements BidirectionalSyncManager {
  bool syncNowCalled = false;
  SyncProgress resultProgress = SyncProgress.completed();

  @override
  Future<SyncProgress> syncNow() async {
    syncNowCalled = true;
    return resultProgress;
  }

  @override
  SyncProgress get currentProgress => resultProgress;

  @override
  bool get isSyncing => false;

  @override
  Stream<SyncProgress> get syncProgressStream => Stream.value(resultProgress);

  @override
  void startAutoSyncListener() {}

  @override
  void stopAutoSyncListener() {}

  @override
  Future<DateTime?> getLastSyncTimestamp() async => null;

  @override
  ConflictResolverService? get conflictResolver => null;

  @override
  void dispose() {}
}

void main() {
  late BackgroundSyncServiceImpl backgroundSyncService;
  late FakeWorkmanager fakeWorkmanager;
  late FakeSyncServiceForBg fakeSyncService;
  late FakeBidirectionalSyncManagerForBg fakeSyncManager;
  late Logger logger;

  setUp(() {
    fakeWorkmanager = FakeWorkmanager();
    fakeSyncService = FakeSyncServiceForBg();
    fakeSyncManager = FakeBidirectionalSyncManagerForBg();
    logger = Logger(printer: PrettyPrinter(methodCount: 0));

    backgroundSyncService = BackgroundSyncServiceImpl(
      syncService: fakeSyncService,
      syncManager: fakeSyncManager,
      logger: logger,
      workmanager: fakeWorkmanager,
    );
  });

  group('BackgroundSyncService Tests', () {
    test('initialize calls Workmanager initialize', () async {
      await backgroundSyncService.initialize();
      expect(fakeWorkmanager.initialized, isTrue);
      expect(fakeWorkmanager.callbackDispatcher, isNotNull);
    });

    test('schedulePeriodicSync registers task with 15 min frequency & battery constraint', () async {
      await backgroundSyncService.schedulePeriodicSync(
        frequency: const Duration(minutes: 15),
      );

      expect(fakeWorkmanager.registeredTasks.length, equals(1));
      final task = fakeWorkmanager.registeredTasks.first;
      expect(task['uniqueName'], equals(kPeriodicSyncTask));
      expect(task['taskName'], equals(kPeriodicSyncTask));
      expect(task['frequency'], equals(const Duration(minutes: 15)));

      final constraints = task['constraints'] as Constraints?;
      expect(constraints, isNotNull);
      expect(constraints?.networkType, equals(NetworkType.connected));
      expect(constraints?.requiresBatteryNotLow, isTrue);
    });

    test('schedulePeriodicSync enforces minimum 15 minute frequency', () async {
      await backgroundSyncService.schedulePeriodicSync(
        frequency: const Duration(minutes: 5),
      );

      expect(fakeWorkmanager.registeredTasks.length, equals(1));
      final task = fakeWorkmanager.registeredTasks.first;
      expect(task['frequency'], equals(const Duration(minutes: 15)));
    });

    test('cancelSync calls Workmanager cancelByUniqueName', () async {
      await backgroundSyncService.cancelSync();
      expect(fakeWorkmanager.cancelledTasks, contains(kPeriodicSyncTask));
    });

    test('syncIfQueueNotEmpty skips sync when pending count is 0', () async {
      fakeSyncService.mockPendingCount = 0;

      final synced = await backgroundSyncService.syncIfQueueNotEmpty();

      expect(synced, isFalse);
      expect(fakeSyncManager.syncNowCalled, isFalse);
    });

    test('syncIfQueueNotEmpty triggers sync when pending items exist', () async {
      fakeSyncService.mockPendingCount = 3;
      fakeSyncManager.resultProgress = SyncProgress.completed();

      final synced = await backgroundSyncService.syncIfQueueNotEmpty();

      expect(synced, isTrue);
      expect(fakeSyncManager.syncNowCalled, isTrue);
    });

    test('syncIfQueueNotEmpty returns false if sync fails', () async {
      fakeSyncService.mockPendingCount = 2;
      fakeSyncManager.resultProgress = SyncProgress.failed(errorMessage: 'Network error');

      final synced = await backgroundSyncService.syncIfQueueNotEmpty();

      expect(synced, isFalse);
      expect(fakeSyncManager.syncNowCalled, isTrue);
    });
  });
}
