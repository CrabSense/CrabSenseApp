import 'dart:async';

import 'package:crabsensemobile/core/network/network_info.dart';
import 'package:crabsensemobile/shared/bloc/sync/sync_bloc.dart';
import 'package:crabsensemobile/shared/bloc/sync/sync_event.dart';
import 'package:crabsensemobile/shared/bloc/sync/sync_state.dart';
import 'package:crabsensemobile/shared/services/bidirectional_sync_manager.dart';
import 'package:crabsensemobile/shared/services/conflict_resolver.dart';
import 'package:crabsensemobile/shared/services/sync_progress.dart';
import 'package:crabsensemobile/shared/services/sync_queue_item.dart';
import 'package:crabsensemobile/shared/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNetworkInfo implements NetworkInfo {
  bool connected = true;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  void setConnected(bool isConnected) {
    connected = isConnected;
    _controller.add(isConnected);
  }

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<List<NetworkType>> get currentNetworkTypes async =>
      connected ? [NetworkType.wifi] : [NetworkType.none];

  @override
  Stream<List<NetworkType>> get onNetworkTypesChanged => Stream.empty();

  @override
  Future<NetworkType> get primaryNetworkType async =>
      connected ? NetworkType.wifi : NetworkType.none;

  void dispose() {
    _controller.close();
  }
}

class FakeBidirectionalSyncManager implements BidirectionalSyncManager {
  final StreamController<SyncProgress> _progressController =
      StreamController<SyncProgress>.broadcast();
  SyncProgress _currentProgress = const SyncProgress(status: SyncStatusEnum.idle);
  DateTime? lastSyncTime;
  bool syncNowCalled = false;

  void emitProgress(SyncProgress progress) {
    _currentProgress = progress;
    _progressController.add(progress);
  }

  @override
  Stream<SyncProgress> get syncProgressStream => _progressController.stream;

  @override
  SyncProgress get currentProgress => _currentProgress;

  @override
  bool get isSyncing => _currentProgress.isSyncing;

  @override
  Future<SyncProgress> syncNow() async {
    syncNowCalled = true;
    final now = DateTime.now();
    lastSyncTime = now;
    final completed = SyncProgress.completed(lastSyncTime: now, totalItems: 2);
    emitProgress(completed);
    return completed;
  }

  @override
  void startAutoSyncListener() {}

  @override
  void stopAutoSyncListener() {}

  @override
  Future<DateTime?> getLastSyncTimestamp() async => lastSyncTime;

  @override
  ConflictResolverService? get conflictResolver => null;

  @override
  void dispose() {
    _progressController.close();
  }
}

class FakeSyncService implements SyncService {
  int pendingCount = 3;

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
  Future<int> getPendingCount() async => pendingCount;

  @override
  Future<void> markProcessing(String id) async {}

  @override
  Future<void> markCompleted(String id) async {
    pendingCount--;
  }

  @override
  Future<void> markFailed(String id, String errorMessage) async {}

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> clearQueue() async {}
}

void main() {
  late FakeNetworkInfo fakeNetworkInfo;
  late FakeBidirectionalSyncManager fakeSyncManager;
  late FakeSyncService fakeSyncService;
  late SyncBloc syncBloc;

  setUp(() {
    fakeNetworkInfo = FakeNetworkInfo();
    fakeSyncManager = FakeBidirectionalSyncManager();
    fakeSyncService = FakeSyncService();

    syncBloc = SyncBloc(
      networkInfo: fakeNetworkInfo,
      syncManager: fakeSyncManager,
      syncService: fakeSyncService,
    );
  });

  tearDown(() {
    syncBloc.close();
    fakeNetworkInfo.dispose();
    fakeSyncManager.dispose();
  });

  test('initial state is SyncState.initial()', () {
    expect(syncBloc.state, equals(SyncState.initial()));
  });

  test('SyncStarted fetches network status, last sync timestamp, and pending count', () async {
    final now = DateTime(2026, 7, 22, 10, 0);
    fakeSyncManager.lastSyncTime = now;
    fakeSyncService.pendingCount = 5;

    syncBloc.add(const SyncStarted());
    await pumpEventQueue();

    expect(syncBloc.state.isConnected, isTrue);
    expect(syncBloc.state.lastSyncTimestamp, equals(now));
    expect(syncBloc.state.pendingCount, equals(5));
  });

  test('SyncConnectivityChanged updates network status and pending count', () async {
    syncBloc.add(const SyncStarted());
    await pumpEventQueue();

    fakeNetworkInfo.setConnected(false);
    await pumpEventQueue();

    expect(syncBloc.state.isConnected, isFalse);
    expect(syncBloc.state.isOffline, isTrue);
  });

  test('SyncProgressUpdated updates progress and last sync time in state', () async {
    syncBloc.add(const SyncStarted());
    await pumpEventQueue();

    final now = DateTime.now();
    final progress = SyncProgress.syncing(
      totalItems: 4,
      processedItems: 2,
      currentStep: 'Uploading batch...',
      lastSyncTime: now,
    );

    fakeSyncManager.emitProgress(progress);
    await pumpEventQueue();

    expect(syncBloc.state.isSyncing, isTrue);
    expect(syncBloc.state.progress.processedItems, equals(2));
    expect(syncBloc.state.progress.totalItems, equals(4));
    expect(syncBloc.state.lastSyncTimestamp, equals(now));
  });

  test('SyncManualTriggered triggers syncNow when connected', () async {
    syncBloc.add(const SyncStarted());
    await pumpEventQueue();

    syncBloc.add(const SyncManualTriggered());
    await pumpEventQueue();

    expect(fakeSyncManager.syncNowCalled, isTrue);
    expect(syncBloc.state.progress.status, equals(SyncStatusEnum.completed));
  });

  test('SyncManualTriggered emits offline error when disconnected', () async {
    fakeNetworkInfo.connected = false;
    syncBloc.add(const SyncStarted());
    await pumpEventQueue();

    syncBloc.add(const SyncManualTriggered());
    await pumpEventQueue();

    expect(syncBloc.state.errorMessage, contains('Cannot sync while offline'));
  });

  test('formattedLastSyncTime displays friendly date/time representation', () {
    final now = DateTime.now();
    final stateRecent = SyncState(lastSyncTimestamp: now.subtract(const Duration(seconds: 10)));
    expect(stateRecent.formattedLastSyncTime, equals('Just now'));

    final stateMins = SyncState(lastSyncTimestamp: now.subtract(const Duration(minutes: 5)));
    expect(stateMins.formattedLastSyncTime, equals('5 minutes ago'));

    final stateNull = const SyncState(lastSyncTimestamp: null);
    expect(stateNull.formattedLastSyncTime, equals('Never'));
  });
}
