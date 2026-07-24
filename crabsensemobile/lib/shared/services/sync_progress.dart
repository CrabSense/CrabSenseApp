import 'package:equatable/equatable.dart';

/// Status of the bidirectional sync operation.
enum SyncStatusEnum {
  idle,
  syncing,
  completed,
  failed,
}

/// Progress state model for bidirectional synchronization.
///
/// Requirements: 13.8 - Display synchronization progress with item count and status.
class SyncProgress extends Equatable {
  const SyncProgress({
    required this.status,
    this.totalItems = 0,
    this.processedItems = 0,
    this.currentStep = '',
    this.lastSyncTime,
    this.errorMessage,
  });

  factory SyncProgress.idle({DateTime? lastSyncTime}) => SyncProgress(
        status: SyncStatusEnum.idle,
        lastSyncTime: lastSyncTime,
        currentStep: 'Idle',
      );

  factory SyncProgress.syncing({
    required int totalItems,
    required int processedItems,
    required String currentStep,
    DateTime? lastSyncTime,
  }) =>
      SyncProgress(
        status: SyncStatusEnum.syncing,
        totalItems: totalItems,
        processedItems: processedItems,
        currentStep: currentStep,
        lastSyncTime: lastSyncTime,
      );

  factory SyncProgress.completed({
    required DateTime lastSyncTime,
    int totalItems = 0,
  }) =>
      SyncProgress(
        status: SyncStatusEnum.completed,
        totalItems: totalItems,
        processedItems: totalItems,
        lastSyncTime: lastSyncTime,
        currentStep: 'Sync completed',
      );

  factory SyncProgress.failed({
    required String errorMessage,
    DateTime? lastSyncTime,
    int totalItems = 0,
    int processedItems = 0,
  }) =>
      SyncProgress(
        status: SyncStatusEnum.failed,
        totalItems: totalItems,
        processedItems: processedItems,
        errorMessage: errorMessage,
        lastSyncTime: lastSyncTime,
        currentStep: 'Sync failed: $errorMessage',
      );

  final SyncStatusEnum status;
  final int totalItems;
  final int processedItems;
  final String currentStep;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  bool get isSyncing => status == SyncStatusEnum.syncing;
  bool get isCompleted => status == SyncStatusEnum.completed;
  bool get isFailed => status == SyncStatusEnum.failed;
  bool get isSuccess => status == SyncStatusEnum.completed;

  /// Progress fraction between 0.0 and 1.0.
  double get progressPercentage {
    if (totalItems <= 0) return 1.0;
    return (processedItems / totalItems).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        status,
        totalItems,
        processedItems,
        currentStep,
        lastSyncTime,
        errorMessage,
      ];
}
