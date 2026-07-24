import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../../core/network/network_info.dart';
import 'conflict_resolver.dart';
import 'sync_conflict.dart';
import 'sync_progress.dart';
import 'sync_queue_item.dart';
import 'sync_remote_data_source.dart';
import 'sync_service.dart';

/// Key for storing last successful sync timestamp in secure storage.
const String kLastSyncTimestampKey = 'last_sync_timestamp';

/// Calculates exponential backoff duration based on retry count.
///
/// Delay sequence:
/// - Retry 1: 1 second  (2^0)
/// - Retry 2: 2 seconds (2^1)
/// - Retry 3: 4 seconds (2^2)
/// - Retry 4: 8 seconds (2^3)
/// - Retry 5+: 16 seconds (max cap)
///
/// Requirements: 13.7
Duration calculateExponentialBackoff(int retryCount) {
  if (retryCount <= 0) return Duration.zero;
  if (retryCount >= 5) return const Duration(seconds: 16);
  final seconds = 1 << (retryCount - 1);
  return Duration(seconds: seconds);
}

/// Abstract interface for Bidirectional Synchronization Logic.
///
/// Requirements: 13.5-13.8
abstract class BidirectionalSyncManager {
  /// Stream emitting real-time sync progress updates.
  Stream<SyncProgress> get syncProgressStream;

  /// Current sync progress state.
  SyncProgress get currentProgress;

  /// Returns whether a sync is currently in progress.
  bool get isSyncing;

  /// Triggers a full bidirectional synchronization pass.
  ///
  /// Uploads queued local changes in batch and downloads server changes since last sync.
  Future<SyncProgress> syncNow();

  /// Starts listening for network connectivity changes to automatically trigger sync when restored.
  ///
  /// Detects connectivity within 10 seconds of network restoration.
  /// Requirements: 13.5
  void startAutoSyncListener();

  /// Stops auto-sync connectivity listener.
  void stopAutoSyncListener();

  /// Retrieves the last recorded successful sync timestamp.
  Future<DateTime?> getLastSyncTimestamp();

  /// Optional conflict resolver service.
  ConflictResolverService? get conflictResolver;

  /// Disposes active streams and listeners.
  void dispose();
}

/// Implementation of [BidirectionalSyncManager].
class BidirectionalSyncManagerImpl implements BidirectionalSyncManager {
  BidirectionalSyncManagerImpl({
    required this.syncService,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.secureStorage,
    required this.logger,
    this.conflictResolver,
    this.batchSize = 10,
  }) {
    _initLastSyncTime();
  }

  final SyncService syncService;
  final SyncRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final FlutterSecureStorage secureStorage;
  final Logger logger;
  @override
  final ConflictResolverService? conflictResolver;
  final int batchSize;

  final StreamController<SyncProgress> _progressController =
      StreamController<SyncProgress>.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;

  SyncProgress _currentProgress = SyncProgress.idle();
  bool _isSyncing = false;
  bool _wasOffline = false;

  @override
  Stream<SyncProgress> get syncProgressStream => _progressController.stream;

  @override
  SyncProgress get currentProgress => _currentProgress;

  @override
  bool get isSyncing => _isSyncing;

  Future<void> _initLastSyncTime() async {
    final timestamp = await getLastSyncTimestamp();
    _currentProgress = SyncProgress.idle(lastSyncTime: timestamp);
    _emitProgress(_currentProgress);
  }

  void _emitProgress(SyncProgress progress) {
    _currentProgress = progress;
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  @override
  void startAutoSyncListener() {
    stopAutoSyncListener();
    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((isConnected) async {
      logger.d('BidirectionalSyncManager: Connectivity changed (connected=$isConnected)');
      if (isConnected) {
        if (_wasOffline || !_isSyncing) {
          _wasOffline = false;
          logger.i('BidirectionalSyncManager: Network restored, triggering auto-sync');
          await syncNow();
        }
      } else {
        _wasOffline = true;
      }
    });
  }

  @override
  void stopAutoSyncListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final rawStr = await secureStorage.read(key: kLastSyncTimestampKey);
      if (rawStr != null && rawStr.isNotEmpty) {
        return DateTime.tryParse(rawStr);
      }
    } catch (e) {
      logger.w('BidirectionalSyncManager: Error reading last sync timestamp: $e');
    }
    return null;
  }

  /// Checks if an item with retries is ready based on exponential backoff requirement.
  bool isItemReadyForRetry(SyncQueueItem item) {
    if (item.retryCount == 0 || item.lastAttemptAt == null) {
      return true;
    }
    final backoffDelay = calculateExponentialBackoff(item.retryCount);
    final elapsed = DateTime.now().difference(item.lastAttemptAt!);
    return elapsed >= backoffDelay;
  }

  @override
  Future<SyncProgress> syncNow() async {
    if (_isSyncing) {
      logger.d('BidirectionalSyncManager: Sync already in progress, skipping duplicate call');
      return _currentProgress;
    }

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      logger.w('BidirectionalSyncManager: Network unavailable, cannot sync');
      final lastSync = await getLastSyncTimestamp();
      final offlineProgress = SyncProgress.failed(
        errorMessage: 'Network unavailable',
        lastSyncTime: lastSync,
      );
      _emitProgress(offlineProgress);
      return offlineProgress;
    }

    _isSyncing = true;
    final lastSyncTime = await getLastSyncTimestamp();

    try {
      // 1. Fetch pending items
      final allPending = await syncService.getPendingItems(limit: 100);
      final readyItems = allPending.where(isItemReadyForRetry).toList();

      final totalCount = readyItems.length + 1; // +1 for server download step
      var processedCount = 0;

      _emitProgress(
        SyncProgress.syncing(
          totalItems: totalCount,
          processedItems: processedCount,
          currentStep: 'Preparing batch upload (${readyItems.length} items queued)',
          lastSyncTime: lastSyncTime,
        ),
      );

      // 2. Batch Upload queued items
      if (readyItems.isNotEmpty) {
        for (var i = 0; i < readyItems.length; i += batchSize) {
          final end = (i + batchSize < readyItems.length) ? i + batchSize : readyItems.length;
          final batch = readyItems.sublist(i, end);

          _emitProgress(
            SyncProgress.syncing(
              totalItems: totalCount,
              processedItems: processedCount,
              currentStep: 'Uploading batch (${i + 1}-${end} of ${readyItems.length})...',
              lastSyncTime: lastSyncTime,
            ),
          );

          // Mark processing
          for (final item in batch) {
            await syncService.markProcessing(item.id);
          }

          try {
            final result = await remoteDataSource.uploadBatch(batch);
            final failedIds = <String>{};

            // Process response item failures if specified in API response
            if (result['failedItemIds'] is List) {
              failedIds.addAll(
                (result['failedItemIds'] as List).map((id) => id.toString()),
              );
            }

            for (final item in batch) {
              if (failedIds.contains(item.id)) {
                await syncService.markFailed(item.id, 'Server returned item error');
              } else {
                await syncService.markCompleted(item.id);
              }
            }
          } on Exception catch (e) {
            logger.e('BidirectionalSyncManager: Error uploading batch: $e');
            for (final item in batch) {
              await syncService.markFailed(item.id, e.toString());
            }
          }

          processedCount += batch.length;
          _emitProgress(
            SyncProgress.syncing(
              totalItems: totalCount,
              processedItems: processedCount,
              currentStep: 'Batch processed ($processedCount/${readyItems.length})',
              lastSyncTime: lastSyncTime,
            ),
          );
        }
      }

      // 3. Download Server Changes
      _emitProgress(
        SyncProgress.syncing(
          totalItems: totalCount,
          processedItems: processedCount,
          currentStep: 'Downloading server changes since last sync...',
          lastSyncTime: lastSyncTime,
        ),
      );

      final newSyncTime = DateTime.now();
      final serverChanges = await remoteDataSource.downloadServerChanges(since: lastSyncTime);

      if (conflictResolver != null && serverChanges['changes'] is Map) {
        final changesMap = serverChanges['changes'] as Map<String, dynamic>;
        for (final entry in changesMap.entries) {
          final entityTypeCode = entry.key;
          final entityType = SyncEntityType.fromCode(entityTypeCode);

          if (entry.value is List) {
            final itemsList = entry.value as List;
            for (final itemData in itemsList) {
              if (itemData is Map<String, dynamic>) {
                final entityId = itemData['id']?.toString() ?? '';
                final serverTimestampStr = itemData['updatedAt']?.toString() ??
                    itemData['createdAt']?.toString() ??
                    newSyncTime.toIso8601String();
                final serverTimestamp = DateTime.tryParse(serverTimestampStr) ?? newSyncTime;

                // Check local queue item for matching entity
                final localPending = allPending.where(
                  (p) => p.entityType == entityType && p.entityId == entityId,
                ).toList();

                if (localPending.isNotEmpty) {
                  final localItem = localPending.first;
                  final localTimestamp = localItem.createdAt;

                  await conflictResolver!.processIncomingEntityChange(
                    entityType: entityType,
                    entityId: entityId,
                    localVersion: localItem.payload,
                    localTimestamp: localTimestamp,
                    serverVersion: itemData,
                    serverTimestamp: serverTimestamp,
                  );
                }
              }
            }
          }
        }
      }

      // Save new sync timestamp
      await secureStorage.write(
        key: kLastSyncTimestampKey,
        value: newSyncTime.toIso8601String(),
      );

      processedCount += 1;

      final completedProgress = SyncProgress.completed(
        lastSyncTime: newSyncTime,
        totalItems: totalCount,
      );

      _emitProgress(completedProgress);
      logger.i('BidirectionalSyncManager: Sync completed successfully at $newSyncTime');
      return completedProgress;
    } on Exception catch (e) {
      logger.e('BidirectionalSyncManager: Sync failed: $e');
      final failedProgress = SyncProgress.failed(
        errorMessage: e.toString(),
        lastSyncTime: lastSyncTime,
      );
      _emitProgress(failedProgress);
      return failedProgress;
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    stopAutoSyncListener();
    _progressController.close();
  }
}
