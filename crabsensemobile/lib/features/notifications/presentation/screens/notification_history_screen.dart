import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../shared/widgets/errors/error_state_widget.dart';
import '../../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../domain/repositories/notification_history_repository.dart';
import '../../domain/usecases/clear_notification_history_usecase.dart';
import '../../domain/usecases/get_notification_history_usecase.dart';
import '../bloc/notification_history_bloc.dart';
import '../bloc/notification_history_event.dart';
import '../bloc/notification_history_state.dart';
import '../widgets/notification_date_group_header.dart';
import '../widgets/notification_history_item_widget.dart';

/// Notification history screen — the in-app notification centre.
///
/// Shows all received notifications grouped by date with a "Clear all"
/// action. Provides pull-to-refresh for manual reload.
///
/// Requirements: 14.6
class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<NotificationHistoryBloc>(
    create: (_) => NotificationHistoryBloc(
      getHistory: sl<GetNotificationHistoryUseCase>(),
      clearHistory: sl<ClearNotificationHistoryUseCase>(),
      repository: sl<NotificationHistoryRepository>(),
    )..add(const NotificationHistoryLoadRequested()),
    child: const _NotificationHistoryView(),
  );
}

// ── Internal view ─────────────────────────────────────────────────────────────

class _NotificationHistoryView extends StatelessWidget {
  const _NotificationHistoryView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotificationHistoryBloc, NotificationHistoryState>(
        builder: (context, state) {
          final hasItems = state is NotificationHistoryLoaded && !state.isEmpty;

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              title: const Text('Notifications'),
              backgroundColor: const Color(0xFFFFFFFF),
              foregroundColor: CrabSenseColors.textPrimary,
              actions: [
                if (hasItems)
                  TextButton(
                    onPressed: () => _confirmClearAll(context),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        color: CrabSenseColors.error,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      );

  Widget _buildBody(BuildContext context, NotificationHistoryState state) {
    if (state is NotificationHistoryLoading || state is NotificationHistoryInitial) {
      return const _SkeletonList();
    }

    if (state is NotificationHistoryError) {
      return ErrorStateWidget(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: state.message,
        onRetry: () =>
            context.read<NotificationHistoryBloc>().add(const NotificationHistoryLoadRequested()),
      );
    }

    if (state is NotificationHistoryLoaded) {
      if (state.isEmpty) {
        return const _EmptyState();
      }
      return _NotificationList(state: state);
    }

    return const _SkeletonList();
  }

  /// Shows a confirmation dialog before clearing all notifications.
  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text('Clear notifications'),
        content: const Text('All notification history will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Clear all', style: TextStyle(color: CrabSenseColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<NotificationHistoryBloc>().add(const NotificationHistoryClearRequested());
    }
  }
}

// ── Notification list ─────────────────────────────────────────────────────────

/// Scrollable list of notifications grouped by date.
///
/// Requirements: 14.6
class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.state});

  final NotificationHistoryLoaded state;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: CrabSenseColors.primary,
    backgroundColor: const Color(0xFFFFFFFF),
    onRefresh: () async {
      context.read<NotificationHistoryBloc>().add(const NotificationHistoryLoadRequested());
      // Wait for a non-loading state.
      await context.read<NotificationHistoryBloc>().stream.firstWhere(
        (s) => s is NotificationHistoryLoaded || s is NotificationHistoryError,
      );
    },
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: _buildSlivers(context),
    ),
  );

  List<Widget> _buildSlivers(BuildContext context) {
    final slivers = <Widget>[];
    final grouped = state.groupedByDate;

    for (final entry in grouped.entries) {
      // Date group header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NotificationDateGroupHeader(label: entry.key),
          ),
        ),
      );

      // Items in the group
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((ctx, index) {
              final item = entry.value[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NotificationHistoryItemWidget(
                  item: item,
                  onTap: () {
                    // Mark item as read via repository directly
                    // (no separate event needed for single-item read).
                    // Deep-link navigation can be wired here in the
                    // future when NotificationNavigationService is
                    // accessible from the screen.
                  },
                ),
              );
            }, childCount: entry.value.length),
          ),
        ),
      );
    }

    // Bottom padding
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));

    return slivers;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: CrabSenseColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: theme.textTheme.titleMedium?.copyWith(color: CrabSenseColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Your notification history will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
    itemCount: 6,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (_, _) => const SkeletonLoader(height: 80, borderRadius: 16),
  );
}
