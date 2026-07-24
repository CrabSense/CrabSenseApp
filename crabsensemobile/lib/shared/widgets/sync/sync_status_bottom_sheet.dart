import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../bloc/sync/sync_bloc.dart';
import '../../bloc/sync/sync_event.dart';
import '../../bloc/sync/sync_state.dart';

/// Modal bottom sheet detailing current sync progress, network status, last sync timestamp, and manual sync trigger.
///
/// Requirements: 13.2, 13.8
class SyncStatusBottomSheet extends StatelessWidget {
  const SyncStatusBottomSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: CrabSenseColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => BlocProvider.value(
          value: context.read<SyncBloc>(),
          child: const SyncStatusBottomSheet(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final isOffline = state.isOffline;
        final isSyncing = state.isSyncing;
        final progress = state.progress;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle indicator ──────────────────────────────────────
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CrabSenseColors.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header (Title + Connectivity Chip) ──────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sync & Network Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOffline
                          ? CrabSenseColors.warning.withValues(alpha: 0.15)
                          : CrabSenseColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOffline
                            ? CrabSenseColors.warning.withValues(alpha: 0.4)
                            : CrabSenseColors.secondary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                          size: 14,
                          color: isOffline ? CrabSenseColors.warning : CrabSenseColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOffline ? 'Offline' : 'Online',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOffline ? CrabSenseColors.warning : CrabSenseColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Sync Progress Section ──────────────────────────────────
              if (isSyncing) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Synchronizing data...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: CrabSenseColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${progress.processedItems}/${progress.totalItems} items',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: CrabSenseColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.progressPercentage,
                    backgroundColor: CrabSenseColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(CrabSenseColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  progress.currentStep,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: CrabSenseColors.textSecondary,
                  ),
                ),
              ] else ...[
                // Idle or completed status card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CrabSenseColors.surfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CrabSenseColors.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            state.hasPendingItems
                                ? Icons.cloud_upload_outlined
                                : Icons.cloud_done_outlined,
                            color: state.hasPendingItems
                                ? CrabSenseColors.warning
                                : CrabSenseColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.hasPendingItems
                                      ? '${state.pendingCount} item(s) pending sync'
                                      : 'All data up to date',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: CrabSenseColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isOffline
                                      ? 'Items will sync automatically when back online'
                                      : 'Ready to sync with server',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: CrabSenseColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Last Sync Timestamp Display ───────────────────────────
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: CrabSenseColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Last synced: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CrabSenseColors.textSecondary,
                    ),
                  ),
                  Text(
                    state.formattedLastSyncTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Manual Sync Trigger Button ────────────────────────────
              ElevatedButton.icon(
                key: const Key('manual_sync_button'),
                onPressed: isSyncing || isOffline
                    ? null
                    : () {
                        context.read<SyncBloc>().add(const SyncManualTriggered());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrabSenseColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: CrabSenseColors.surfaceVariant,
                ),
                icon: isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CrabSenseColors.textSecondary,
                        ),
                      )
                    : const Icon(Icons.sync_rounded),
                label: Text(
                  isSyncing
                      ? 'Syncing...'
                      : isOffline
                          ? 'Offline (Cannot Sync)'
                          : 'Sync Now',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
