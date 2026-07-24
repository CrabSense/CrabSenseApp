import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../bloc/sync/sync_bloc.dart';
import '../../bloc/sync/sync_state.dart';
import 'sync_status_bottom_sheet.dart';

/// An AppBar action widget displaying network offline state, sync status, and item counts.
///
/// Features:
/// - Displays prominent offline badge when network is unavailable (Req 13.2)
/// - Displays animated spinning sync indicator when synchronizing (Req 13.8)
/// - Displays pending items count badge when queue is non-empty (Req 13.8)
/// - Opens [SyncStatusBottomSheet] on tap for details & manual sync trigger (Req 13.8)
///
/// Requirements: 13.2, 13.8
class SyncAppBarAction extends StatefulWidget {
  const SyncAppBarAction({super.key});

  @override
  State<SyncAppBarAction> createState() => _SyncAppBarActionState();
}

class _SyncAppBarActionState extends State<SyncAppBarAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        if (state.isSyncing) {
          if (!_spinController.isAnimating) {
            _spinController.repeat();
          }
        } else {
          if (_spinController.isAnimating) {
            _spinController.stop();
            _spinController.reset();
          }
        }

        // ── 1. Offline Indicator in App Bar (Req 13.2) ───────────────────
        if (state.isOffline) {
          return InkWell(
            key: const Key('appbar_offline_indicator'),
            onTap: () => SyncStatusBottomSheet.show(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              decoration: BoxDecoration(
                color: CrabSenseColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CrabSenseColors.warning.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 14,
                    color: CrabSenseColors.warning,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CrabSenseColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── 2. Syncing or Pending Items Badge (Req 13.8) ────────────────
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              key: const Key('appbar_sync_button'),
              tooltip: state.isSyncing
                  ? 'Syncing data...'
                  : state.hasPendingItems
                      ? '${state.pendingCount} pending items'
                      : 'Sync status',
              icon: RotationTransition(
                turns: _spinController,
                child: Icon(
                  state.isSyncing ? Icons.sync_rounded : Icons.cloud_done_outlined,
                  color: state.isSyncing
                      ? CrabSenseColors.primary
                      : state.hasPendingItems
                          ? CrabSenseColors.warning
                          : CrabSenseColors.textSecondary,
                ),
              ),
              onPressed: () => SyncStatusBottomSheet.show(context),
            ),
            if (state.hasPendingItems && !state.isSyncing)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: CrabSenseColors.warning,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${state.pendingCount}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
