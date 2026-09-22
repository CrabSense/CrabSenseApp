import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/network_info.dart';
import '../../services/bidirectional_sync_manager.dart';
import '../../services/sync_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// BLoC for controlling application-wide sync state, connectivity status, and manual sync operations.
///
/// Requirements: 13.2, 13.8
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required this.networkInfo,
    required this.syncManager,
    required this.syncService,
  }) : super(SyncState.initial()) {
    on<SyncStarted>(_onStarted);
    on<SyncConnectivityChanged>(_onConnectivityChanged);
    on<SyncProgressUpdated>(_onProgressUpdated);
    on<SyncPendingCountRefreshed>(_onPendingCountRefreshed);
    on<SyncManualTriggered>(_onManualTriggered);
  }

  final NetworkInfo networkInfo;
  final BidirectionalSyncManager syncManager;
  final SyncService syncService;

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<dynamic>? _progressSubscription;

  Future<void> _onStarted(SyncStarted event, Emitter<SyncState> emit) async {
    // Cancel existing subscriptions if re-started
    await _connectivitySubscription?.cancel();
    await _progressSubscription?.cancel();

    // Start auto sync listener in manager
    syncManager.startAutoSyncListener();

    // Listen to network status changes
    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      connected,
    ) {
      add(SyncConnectivityChanged(connected));
    });

    // Listen to sync manager progress updates
    _progressSubscription = syncManager.syncProgressStream.listen((progress) {
      add(SyncProgressUpdated(progress));
    });

    // Fetch initial parameters
    final connected = await networkInfo.isConnected;
    final lastSync = await syncManager.getLastSyncTimestamp();
    final pending = await _safeGetPendingCount();

    emit(
      state.copyWith(
        isConnected: connected,
        lastSyncTimestamp: lastSync,
        pendingCount: pending,
        progress: syncManager.currentProgress,
      ),
    );

    // JWT is not ready here; CrabSenseApp syncs on Authenticated.
  }

  Future<void> _onConnectivityChanged(
    SyncConnectivityChanged event,
    Emitter<SyncState> emit,
  ) async {
    final pending = await _safeGetPendingCount();
    emit(state.copyWith(isConnected: event.isConnected, pendingCount: pending));
  }

  Future<void> _onProgressUpdated(
    SyncProgressUpdated event,
    Emitter<SyncState> emit,
  ) async {
    final progress = event.progress;
    final lastSync = progress.lastSyncTime ?? state.lastSyncTimestamp;
    final pending = await _safeGetPendingCount();

    emit(
      state.copyWith(
        progress: progress,
        lastSyncTimestamp: lastSync,
        pendingCount: pending,
        errorMessage: progress.isFailed ? progress.errorMessage : null,
      ),
    );
  }

  Future<void> _onPendingCountRefreshed(
    SyncPendingCountRefreshed event,
    Emitter<SyncState> emit,
  ) async {
    final count = await _safeGetPendingCount();
    emit(state.copyWith(pendingCount: count));
  }

  Future<void> _onManualTriggered(
    SyncManualTriggered event,
    Emitter<SyncState> emit,
  ) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      emit(
        state.copyWith(
          isConnected: false,
          errorMessage: 'Cannot sync while offline',
        ),
      );
      return;
    }

    final newProgress = await syncManager.syncNow();
    final lastSync = newProgress.lastSyncTime ?? state.lastSyncTimestamp;
    final count = await _safeGetPendingCount();

    emit(
      state.copyWith(
        progress: newProgress,
        lastSyncTimestamp: lastSync,
        pendingCount: count,
        errorMessage: newProgress.isFailed ? newProgress.errorMessage : null,
      ),
    );
  }

  Future<int> _safeGetPendingCount() async {
    try {
      return await syncService.getPendingCount();
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _progressSubscription?.cancel();
    return super.close();
  }
}
