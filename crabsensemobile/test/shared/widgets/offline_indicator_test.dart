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
import 'package:crabsensemobile/shared/widgets/sync/offline_banner.dart';
import 'package:crabsensemobile/shared/widgets/sync/sync_app_bar_action.dart';
import 'package:crabsensemobile/shared/widgets/sync/sync_status_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class WidgetTestNetworkInfo implements NetworkInfo {
  bool connected = true;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();

  @override
  Future<List<NetworkType>> get currentNetworkTypes async =>
      connected ? [NetworkType.wifi] : [NetworkType.none];

  @override
  Stream<List<NetworkType>> get onNetworkTypesChanged => const Stream.empty();

  @override
  Future<NetworkType> get primaryNetworkType async =>
      connected ? NetworkType.wifi : NetworkType.none;
}

class WidgetTestSyncManager implements BidirectionalSyncManager {
  SyncProgress progress = const SyncProgress(status: SyncStatusEnum.idle);
  bool syncNowCalled = false;

  @override
  Stream<SyncProgress> get syncProgressStream => const Stream.empty();

  @override
  SyncProgress get currentProgress => progress;

  @override
  bool get isSyncing => progress.isSyncing;

  @override
  Future<SyncProgress> syncNow() async {
    syncNowCalled = true;
    return progress;
  }

  @override
  void startAutoSyncListener() {}

  @override
  void stopAutoSyncListener() {}

  @override
  Future<DateTime?> getLastSyncTimestamp() async => progress.lastSyncTime;

  @override
  ConflictResolverService? get conflictResolver => null;

  @override
  void dispose() {}
}

class WidgetTestSyncService implements SyncService {
  int count = 0;

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
  Future<int> getPendingCount() async => count;

  @override
  Future<void> markProcessing(String id) async {}

  @override
  Future<void> markCompleted(String id) async {}

  @override
  Future<void> markFailed(String id, String errorMessage) async {}

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> clearQueue() async {}
}

void main() {
  late WidgetTestNetworkInfo fakeNetworkInfo;
  late WidgetTestSyncManager fakeSyncManager;
  late WidgetTestSyncService fakeSyncService;
  late SyncBloc syncBloc;

  setUp(() {
    fakeNetworkInfo = WidgetTestNetworkInfo();
    fakeSyncManager = WidgetTestSyncManager();
    fakeSyncService = WidgetTestSyncService();

    syncBloc = SyncBloc(
      networkInfo: fakeNetworkInfo,
      syncManager: fakeSyncManager,
      syncService: fakeSyncService,
    );
  });

  tearDown(() {
    syncBloc.close();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Test Bar'),
            actions: const [SyncAppBarAction()],
          ),
          body: Column(
            children: [
              const OfflineBannerWidget(),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('SyncAppBarAction displays offline badge when network is offline', (tester) async {
    fakeNetworkInfo.connected = false;
    syncBloc.add(const SyncStarted());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appbar_offline_indicator')), findsOneWidget);
    expect(find.text('Offline'), findsWidgets);
  });

  testWidgets('SyncAppBarAction displays sync icon button when online', (tester) async {
    fakeNetworkInfo.connected = true;
    syncBloc.add(const SyncStarted());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appbar_sync_button')), findsOneWidget);
  });

  testWidgets('OfflineBannerWidget displays warning banner when offline', (tester) async {
    fakeNetworkInfo.connected = false;
    syncBloc.add(const SyncStarted());
    await tester.pumpAndSettle();

    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('Changes will sync automatically when back online'), findsOneWidget);
  });

  testWidgets('OfflineBannerWidget displays syncing progress bar when syncing', (tester) async {
    fakeNetworkInfo.connected = true;
    syncBloc.add(const SyncStarted());
    await tester.pumpAndSettle();

    final now = DateTime.now();
    syncBloc.add(
      SyncProgressUpdated(
        SyncProgress.syncing(
          totalItems: 5,
          processedItems: 2,
          currentStep: 'Uploading items...',
          lastSyncTime: now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Syncing (2/5 items)...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('SyncStatusBottomSheet renders network state, last sync time, and manual sync button', (tester) async {
    final lastSync = DateTime(2026, 7, 22, 14, 30);
    fakeSyncManager.progress = SyncProgress.idle(lastSyncTime: lastSync);
    fakeNetworkInfo.connected = true;

    syncBloc.add(const SyncStarted());
    await tester.pumpAndSettle();

    // Tap app bar sync action to open bottom sheet
    await tester.tap(find.byKey(const Key('appbar_sync_button')));
    await tester.pumpAndSettle();

    expect(find.text('Sync & Network Status'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);
    expect(find.byKey(const Key('manual_sync_button')), findsOneWidget);
  });
}
