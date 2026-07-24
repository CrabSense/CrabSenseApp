import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../domain/models/alerts_models.dart';
import '../providers/alerts_provider.dart';
import '../widgets/alert_card_v2.dart';
import '../widgets/alert_filter_chips.dart';
import '../widgets/alert_overview_summary.dart';
import '../widgets/alert_search_bar.dart';
import '../widgets/alert_sheets.dart';
import '../widgets/alerts_header.dart';
import '../widgets/alerts_skeleton.dart';
import '../widgets/alerts_states.dart';
import '../widgets/priority_alert_card.dart';

/// Smart Alert Command Center tab.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _showSearch = false;
  UserRole? _lastRole;

  void _syncPermissions(User user) {
    final role = user.role;
    if (_lastRole == role) return;
    _lastRole = role;

    final flags = AlertsPermissionFlags.fromRoleFlags(
      isAdmin: role.isAdmin,
      isManager: role.canManageUsers,
      isOperator: role.canPerformFieldOperations,
      hasWriteAccess: role.hasWriteAccess,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(alertsStateProvider.notifier);
      notifier.updatePermissions(flags);
      notifier.setCurrentUser(id: user.id, name: user.name);
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CrabSenseColors.container,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openDetail(AlertItem alert, AlertsStateData data) async {
    ref.read(alertsStateProvider.notifier).selectAlert(alert.id);
    await showAlertDetailSheet(
      context: context,
      alert: alert,
      canAssign: data.canAssign,
      onHandle: () => _handleNow(alert, data),
      onAcknowledge: () {
        if (!data.canAcknowledge) {
          _snack('Bạn không có quyền xác nhận cảnh báo');
          return;
        }
        ref.read(alertsStateProvider.notifier).acknowledge(alert.id);
      },
      onAssign: data.canAssign ? () => _assign(alert) : null,
      onViewBox: alert.boxId == null
          ? null
          : () => context.push(RoutePaths.boxDetails(alert.boxId!)),
    );
  }

  Future<void> _handleNow(AlertItem alert, AlertsStateData data) async {
    if (!data.canResolve) {
      _snack('Bạn không có quyền xử lý cảnh báo');
      return;
    }
    final notifier = ref.read(alertsStateProvider.notifier);
    if (alert.status == AlertLifecycleStatus.newly) {
      await notifier.acknowledge(alert.id);
    }
    await notifier.startProgress(alert.id);
    _snack('Đã bắt đầu xử lý: ${alert.title}');
  }

  Future<void> _assign(AlertItem alert) async {
    await showAlertAssignmentSheet(
      context: context,
      alert: alert,
      onAssign:
          ({
            required String assigneeId,
            required String assigneeName,
            required String assigneeRole,
            String? note,
          }) {
            ref
                .read(alertsStateProvider.notifier)
                .assign(
                  alertId: alert.id,
                  assigneeId: assigneeId,
                  assigneeName: assigneeName,
                  assigneeRole: assigneeRole,
                  note: note,
                );
            _snack('Đã giao cho $assigneeName');
          },
    );
  }

  Future<void> _openMore(AlertItem alert, AlertsStateData data) async {
    await showAlertQuickActionsSheet(
      context: context,
      alert: alert,
      canAcknowledge: data.canAcknowledge,
      canResolve: data.canResolve,
      canAssign: data.canAssign,
      onAcknowledge: () {
        ref.read(alertsStateProvider.notifier).acknowledge(alert.id);
        _snack('Đã xác nhận xem');
      },
      onHandle: () => _handleNow(alert, data),
      onAssign: () => _assign(alert),
      onViewBox: () {
        if (alert.boxId != null) {
          context.push(RoutePaths.boxDetails(alert.boxId!));
        }
      },
      onViewDetail: () => _openDetail(alert, data),
      onHide: () {
        ref.read(alertsStateProvider.notifier).hideAlert(alert.id);
        _snack('Đã tạm ẩn cảnh báo');
      },
      onAction: (action) {
        if (action.id == 'complete' || action.id == 'log_result') {
          ref
              .read(alertsStateProvider.notifier)
              .resolve(alert.id, note: action.label);
          _snack('Đã đánh dấu hoàn thành');
          return;
        }
        _snack('Đã ghi nhận: ${action.label}');
      },
    );
  }

  void _showSortGroupSheet(AlertsStateData data) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CrabSenseColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sắp xếp & nhóm',
                  style: TextStyle(
                    color: CrabSenseColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sắp xếp',
                  style: TextStyle(color: CrabSenseColors.hintText),
                ),
                for (final s in AlertSortOption.values)
                  RadioListTile<AlertSortOption>(
                    value: s,
                    groupValue: data.sortOption,
                    activeColor: CrabSenseColors.primary,
                    title: Text(
                      switch (s) {
                        AlertSortOption.priorityDesc => 'Priority cao → thấp',
                        AlertSortOption.newest => 'Mới nhất',
                        AlertSortOption.oldest => 'Cũ nhất',
                        AlertSortOption.severity => 'Theo mức độ',
                      },
                      style: const TextStyle(
                        color: CrabSenseColors.textPrimary,
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(alertsStateProvider.notifier).setSort(v);
                      Navigator.pop(ctx);
                    },
                  ),
                const Text(
                  'Nhóm theo',
                  style: TextStyle(color: CrabSenseColors.hintText),
                ),
                for (final g in AlertGroupBy.values)
                  RadioListTile<AlertGroupBy>(
                    value: g,
                    groupValue: data.groupBy,
                    activeColor: CrabSenseColors.primary,
                    title: Text(
                      switch (g) {
                        AlertGroupBy.severity => 'Mức độ',
                        AlertGroupBy.date => 'Ngày',
                        AlertGroupBy.category => 'Loại cảnh báo',
                        AlertGroupBy.status => 'Trạng thái',
                        AlertGroupBy.box => 'Box',
                        AlertGroupBy.none => 'Không nhóm',
                      },
                      style: const TextStyle(
                        color: CrabSenseColors.textPrimary,
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(alertsStateProvider.notifier).setGroupBy(v);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHistoryRangeSheet(AlertsStateData data) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CrabSenseColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in AlertHistoryRange.values)
                ListTile(
                  title: Text(
                    switch (r) {
                      AlertHistoryRange.today => 'Hôm nay',
                      AlertHistoryRange.days7 => '7 ngày',
                      AlertHistoryRange.days30 => '30 ngày',
                      AlertHistoryRange.custom => 'Tùy chỉnh (30 ngày)',
                    },
                    style: TextStyle(
                      color: data.historyRange == r
                          ? CrabSenseColors.primary
                          : CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    ref.read(alertsStateProvider.notifier).setHistoryRange(r);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      _syncPermissions(authState.user);
    }

    final async = ref.watch(alertsStateProvider);
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 700 ? 720.0 : double.infinity;

    return Scaffold(
      backgroundColor: CrabSenseColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: async.when(
              loading: () => const AlertsSkeleton(),
              error: (e, _) => Center(
                child: SectionErrorCard(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(alertsStateProvider.notifier).refresh(),
                ),
              ),
              data: _buildContent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AlertsStateData data) {
    final notifier = ref.read(alertsStateProvider.notifier);

    return RefreshIndicator(
      color: CrabSenseColors.primary,
      backgroundColor: CrabSenseColors.surface,
      onRefresh: () => notifier.refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: AlertsHeader(
                data: data,
                onFarmSwitched: notifier.switchFarm,
                onSearchPressed: () =>
                    setState(() => _showSearch = !_showSearch),
                onFilterPressed: () => _showSortGroupSheet(data),
                onHistoryPressed: () {
                  if (data.showingHistory) {
                    notifier.setShowingHistory(false);
                  } else {
                    notifier.setShowingHistory(true);
                    _showHistoryRangeSheet(data);
                  }
                },
                onMarkAllRead: data.canMarkAllRead
                    ? () async {
                        await notifier.markAllRead();
                        _snack('Đã đánh dấu tất cả đã xem');
                      }
                    : null,
                onNotificationSettings: () => context.go(RoutePaths.profile),
              ),
            ),
          ),
          if (data.isOfflineCached || !data.isOnline)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: AlertsOfflineBanner(
                  lastSyncedAt: data.lastSyncedAt,
                  pendingCount: data.pendingSyncCount,
                  onRetrySync: () => notifier.syncPending(),
                ),
              ),
            ),
          if (data.sectionError != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SectionErrorCard(
                  message: data.sectionError!,
                  onRetry: () => notifier.refresh(),
                ),
              ),
            ),
          if (_showSearch)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: AlertSearchBar(
                  initialValue: data.searchQuery,
                  onChanged: notifier.setSearchQuery,
                  onClear: notifier.clearSearch,
                ),
              ),
            ),
          if (!data.showingHistory)
            ..._activeSections(data, notifier)
          else
            ..._historySections(data, notifier),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  List<Widget> _activeSections(
    AlertsStateData data,
    AlertsNotifier notifier,
  ) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverToBoxAdapter(
          child: AlertOverviewSummary(
            summary: data.summary,
            onTapSeverity: notifier.toggleQuickFilter,
          ),
        ),
      ),
      if (data.priorityAlert != null)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: PriorityAlertCard(
              alert: data.priorityAlert!,
              onHandleNow: () => _handleNow(data.priorityAlert!, data),
              onViewBox: () {
                final id = data.priorityAlert!.boxId;
                if (id != null) context.push(RoutePaths.boxDetails(id));
              },
              onAcknowledge: () {
                if (!data.canAcknowledge) return;
                notifier.acknowledge(data.priorityAlert!.id);
              },
              onViewDetail: () => _openDetail(data.priorityAlert!, data),
              onAssign: data.canAssign
                  ? () => _assign(data.priorityAlert!)
                  : null,
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverToBoxAdapter(
          child: AlertFilterChips(
            activeFilters: data.quickFilters,
            onToggle: notifier.toggleQuickFilter,
            onClear: notifier.clearFilters,
          ),
        ),
      ),
      if (data.visibleAlerts.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: data.hasActiveFilters
              ? AlertsFilterEmptyState(onClear: notifier.clearFilters)
              : AlertsEmptyState(
                  onRefresh: () => notifier.refresh(),
                  onHistory: () => notifier.setShowingHistory(true),
                ),
        )
      else
        ..._groupedList(data),
    ];
  }

  List<Widget> _historySections(AlertsStateData data, AlertsNotifier notifier) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Lịch sử cảnh báo',
                  style: TextStyle(
                    color: CrabSenseColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showHistoryRangeSheet(data),
                child: Text(switch (data.historyRange) {
                  AlertHistoryRange.today => 'Hôm nay',
                  AlertHistoryRange.days7 => '7 ngày',
                  AlertHistoryRange.days30 => '30 ngày',
                  AlertHistoryRange.custom => 'Tùy chỉnh',
                }),
              ),
              TextButton(
                onPressed: () => notifier.setShowingHistory(false),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverToBoxAdapter(
          child: AlertFilterChips(
            activeFilters: data.quickFilters,
            onToggle: notifier.toggleQuickFilter,
            onClear: notifier.clearFilters,
          ),
        ),
      ),
      if (data.visibleAlerts.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'Không có lịch sử trong khoảng thời gian này',
              style: TextStyle(color: CrabSenseColors.hintText),
            ),
          ),
        )
      else
        ..._groupedList(data),
    ];
  }

  List<Widget> _groupedList(AlertsStateData data) {
    final widgets = <Widget>[];
    for (final section in data.groupedAlerts) {
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${section.title} (${section.items.length})',
              style: const TextStyle(
                color: CrabSenseColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      );
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final alert = section.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RepaintBoundary(
                  child: AlertCard(
                    alert: alert,
                    onTap: () => _openDetail(alert, data),
                    onMore: () => _openMore(alert, data),
                  ),
                ),
              );
            }, childCount: section.items.length),
          ),
        ),
      );
    }
    return widgets;
  }
}
