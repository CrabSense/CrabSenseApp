import 'package:equatable/equatable.dart';

import '../../services/sync_progress.dart';

/// Events triggering state changes in [SyncBloc].
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Initial event to start listening to network connectivity and sync manager streams.
class SyncStarted extends SyncEvent {
  const SyncStarted();
}

/// Triggered when network connectivity status changes (connected = true / false).
class SyncConnectivityChanged extends SyncEvent {
  const SyncConnectivityChanged(this.isConnected);

  final bool isConnected;

  @override
  List<Object?> get props => [isConnected];
}

/// Triggered when [BidirectionalSyncManager] emits a new [SyncProgress].
class SyncProgressUpdated extends SyncEvent {
  const SyncProgressUpdated(this.progress);

  final SyncProgress progress;

  @override
  List<Object?> get props => [progress];
}

/// Triggered to refresh the count of pending items in the offline queue.
class SyncPendingCountRefreshed extends SyncEvent {
  const SyncPendingCountRefreshed();
}

/// User requested manual synchronization pass.
class SyncManualTriggered extends SyncEvent {
  const SyncManualTriggered();
}
