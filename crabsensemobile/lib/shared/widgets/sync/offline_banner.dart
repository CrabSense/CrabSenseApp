import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../bloc/sync/sync_bloc.dart';
import '../../bloc/sync/sync_event.dart';
import '../../bloc/sync/sync_state.dart';
import 'sync_status_bottom_sheet.dart';

/// Top banner displayed when offline or during active synchronization operations.
///
/// Displays:
/// - Offline network notification banner (Req 13.2)
/// - Active sync progress percentage & item count (Req 13.8)
/// - Manual sync trigger button (Req 13.8)
/// - Last sync timestamp (Req 13.8)
///
/// Requirements: 13.2, 13.8
class OfflineBannerWidget extends StatelessWidget {
  const OfflineBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        if (!state.isOffline && !state.isSyncing && !state.hasPendingItems) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);

        // ── 1. Offline Mode Banner (Req 13.2) ───────────────────────────
        if (state.isOffline) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: CrabSenseColors.warning.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 20,
                  color: CrabSenseColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'You are offline',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: CrabSenseColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        state.hasPendingItems
                            ? '${state.pendingCount} change(s) waiting to sync'
                            : 'Changes will sync automatically when back online',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: CrabSenseColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => SyncStatusBottomSheet.show(context),
                  child: const Text(
                    'Details',
                    style: TextStyle(
                      color: CrabSenseColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ── 2. Syncing Progress Banner (Req 13.8) ───────────────────────
        if (state.isSyncing) {
          final progress = state.progress;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: CrabSenseColors.primary.withValues(alpha: 0.12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CrabSenseColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Syncing (${progress.processedItems}/${progress.totalItems} items)...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: CrabSenseColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress.progressPercentage * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: CrabSenseColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.progressPercentage,
                    backgroundColor: CrabSenseColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(CrabSenseColors.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }

        // ── 3. Online with Pending Items Banner (Req 13.8) ──────────────
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: CrabSenseColors.surfaceVariant.withValues(alpha: 0.5),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 18,
                color: CrabSenseColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${state.pendingCount} item(s) ready to sync',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: CrabSenseColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<SyncBloc>().add(const SyncManualTriggered());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrabSenseColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Sync Now',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
