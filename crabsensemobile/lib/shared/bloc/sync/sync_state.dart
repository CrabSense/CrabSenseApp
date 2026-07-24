import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../services/sync_progress.dart';

/// State representation for synchronization and network connectivity.
///
/// Requirements: 13.2, 13.8
class SyncState extends Equatable {
  const SyncState({
    this.isConnected = true,
    this.progress = const SyncProgress(status: SyncStatusEnum.idle),
    this.pendingCount = 0,
    this.lastSyncTimestamp,
    this.errorMessage,
  });

  factory SyncState.initial() => const SyncState();

  final bool isConnected;
  final SyncProgress progress;
  final int pendingCount;
  final DateTime? lastSyncTimestamp;
  final String? errorMessage;

  bool get isOffline => !isConnected;
  bool get isSyncing => progress.isSyncing;
  bool get hasPendingItems => pendingCount > 0;

  /// Formatted presentation string for last sync time.
  String get formattedLastSyncTime {
    final timestamp = lastSyncTimestamp ?? progress.lastSyncTime;
    if (timestamp == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM dd, yyyy HH:mm').format(timestamp);
    }
  }

  SyncState copyWith({
    bool? isConnected,
    SyncProgress? progress,
    int? pendingCount,
    DateTime? lastSyncTimestamp,
    String? errorMessage,
  }) =>
      SyncState(
        isConnected: isConnected ?? this.isConnected,
        progress: progress ?? this.progress,
        pendingCount: pendingCount ?? this.pendingCount,
        lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        isConnected,
        progress,
        pendingCount,
        lastSyncTimestamp,
        errorMessage,
      ];
}
