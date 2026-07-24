import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/errors/error_state_widget.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_enums.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../domain/usecases/acknowledge_alert_usecase.dart';
import '../../domain/usecases/dismiss_alert_usecase.dart';
import '../../domain/usecases/get_alerts_usecase.dart';
import '../bloc/alert_bloc.dart';
import '../bloc/alert_event.dart';
import '../bloc/alert_state.dart';
import '../widgets/alert_card.dart';

/// Alert management screen.
///
/// Displays the full alert list with:
/// - Severity categorization with colour indicators (Req 9.3)
/// - Filtering by severity, type, and status (Req 9.8)
/// - Alerts sorted by timestamp descending (Req 9.4)
/// - Unread count badge in the AppBar (Req 9.2)
/// - Alert history for the last 30 days (Req 9.9)
/// - Acknowledge and dismiss actions (Req 9.6, 9.7)
/// - Offline indicator when serving cached data (Req 9.10)
///
/// Requirements: 9.1-9.10
class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<AlertBloc>(
    create: (_) => AlertBloc(
      getAlerts: sl<GetAlertsUseCase>(),
      acknowledgeAlert: sl<AcknowledgeAlertUseCase>(),
      dismissAlert: sl<DismissAlertUseCase>(),
      repository: sl<AlertRepository>(),
    )..add(const AlertLoadRequested()),
    child: const _AlertView(),
  );
}

// ── Internal view ─────────────────────────────────────────────────────────────

class _AlertView extends StatelessWidget {
  const _AlertView();

  @override
  Widget build(BuildContext context) => BlocBuilder<AlertBloc, AlertState>(
    builder: (context, state) {
      final unreadCount = _unreadCount(state);
      final activeFilters = _activeFilters(state);

      return Scaffold(
        backgroundColor: CrabSenseColors.background,
        appBar: _buildAppBar(context, unreadCount),
        body: Column(
          children: [
            // ── Filter bar ─────────────────────────────────────────
            _FilterBar(activeFilters: activeFilters),

            // ── Body ───────────────────────────────────────────────
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      );
    },
  );

  AppBar _buildAppBar(BuildContext context, int unreadCount) => AppBar(
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Alerts'),
        if (unreadCount > 0) ...[
          const SizedBox(width: 8),
          _UnreadBadge(count: unreadCount),
        ],
      ],
    ),
    backgroundColor: CrabSenseColors.surface,
    foregroundColor: CrabSenseColors.textPrimary,
  );

  Widget _buildBody(BuildContext context, AlertState state) {
    if (state is AlertLoading) {
      return const _AlertSkeletonList();
    }

    if (state is AlertError) {
      return ErrorStateWidget(
        icon: state.isOffline ? Icons.wifi_off : Icons.error_outline,
        title: state.isOffline ? 'No Connection' : 'Something went wrong',
        message: state.message,
        onRetry: () =>
            context.read<AlertBloc>().add(const AlertLoadRequested()),
      );
    }

    if (state is AlertLoaded) {
      return _AlertListView(
        alerts: state.alerts,
        isOffline: state.isOffline,
        isRefreshing: state.isRefreshing,
      );
    }

    if (state is AlertActionInProgress) {
      return _AlertListView(
        alerts: state.alerts,
        isOffline: false,
        isRefreshing: false,
        processingAlertId: state.processingAlertId,
      );
    }

    // AlertInitial — show skeleton until the first load fires.
    return const _AlertSkeletonList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _unreadCount(AlertState state) {
    if (state is AlertLoaded) return state.unreadCount;
    if (state is AlertActionInProgress) return state.unreadCount;
    return 0;
  }

  AlertActiveFilters _activeFilters(AlertState state) {
    if (state is AlertLoaded) return state.activeFilters;
    if (state is AlertActionInProgress) return state.activeFilters;
    return const AlertActiveFilters();
  }
}

// ── Unread badge ──────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: CrabSenseColors.error,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
      ),
    ),
  );
}

// ── Filter bar ────────────────────────────────────────────────────────────────

/// Horizontal scrollable filter bar for severity, type, and status.
///
/// Requirements: 9.8
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.activeFilters});

  final AlertActiveFilters activeFilters;

  @override
  Widget build(BuildContext context) => Container(
    color: CrabSenseColors.surface,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ── Severity filters ─────────────────────────────────────
          _FilterChip(
            label: 'All',
            selected: activeFilters.severity == null,
            color: CrabSenseColors.primary,
            onTap: () => _setSeverity(context, null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Critical',
            selected: activeFilters.severity == AlertSeverity.critical,
            color: CrabSenseColors.error,
            onTap: () => _setSeverity(context, AlertSeverity.critical),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Warning',
            selected: activeFilters.severity == AlertSeverity.warning,
            color: CrabSenseColors.warning,
            onTap: () => _setSeverity(context, AlertSeverity.warning),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Info',
            selected: activeFilters.severity == AlertSeverity.info,
            color: CrabSenseColors.info,
            onTap: () => _setSeverity(context, AlertSeverity.info),
          ),

          // ── Divider ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 1,
            height: 24,
            color: CrabSenseColors.outline,
          ),

          // ── Status filters ───────────────────────────────────────
          _FilterChip(
            label: 'Unread',
            selected: activeFilters.status == AlertStatus.unread,
            color: CrabSenseColors.primary,
            onTap: () => _setStatus(context, AlertStatus.unread),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Read',
            selected: activeFilters.status == AlertStatus.read,
            color: CrabSenseColors.textSecondary,
            onTap: () => _setStatus(context, AlertStatus.read),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Acknowledged',
            selected: activeFilters.status == AlertStatus.acknowledged,
            color: CrabSenseColors.success,
            onTap: () => _setStatus(context, AlertStatus.acknowledged),
          ),

          // ── Divider ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 1,
            height: 24,
            color: CrabSenseColors.outline,
          ),

          // ── Type filters ─────────────────────────────────────────
          for (final type in AlertType.values) ...[
            _FilterChip(
              label: type.displayName,
              selected: activeFilters.type == type,
              color: CrabSenseColors.primary,
              onTap: () => _setType(context, type),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    ),
  );

  void _setSeverity(BuildContext context, AlertSeverity? severity) {
    final current = context.read<AlertBloc>().state;
    var filters = const AlertActiveFilters();
    if (current is AlertLoaded) filters = current.activeFilters;

    context.read<AlertBloc>().add(
      AlertFiltersChanged(
        severity: severity,
        type: filters.type,
        status: filters.status,
      ),
    );
  }

  void _setStatus(BuildContext context, AlertStatus? status) {
    final current = context.read<AlertBloc>().state;
    var filters = const AlertActiveFilters();
    if (current is AlertLoaded) filters = current.activeFilters;

    context.read<AlertBloc>().add(
      AlertFiltersChanged(
        severity: filters.severity,
        type: filters.type,
        status: filters.status == status ? null : status,
      ),
    );
  }

  void _setType(BuildContext context, AlertType? type) {
    final current = context.read<AlertBloc>().state;
    var filters = const AlertActiveFilters();
    if (current is AlertLoaded) filters = current.activeFilters;

    context.read<AlertBloc>().add(
      AlertFiltersChanged(
        severity: filters.severity,
        type: filters.type == type ? null : type,
        status: filters.status,
      ),
    );
  }
}

/// Individual filter chip with selected/unselected styling.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: 0.2)
            : CrabSenseColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : CrabSenseColors.outline,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? color : CrabSenseColors.textSecondary,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          fontFamily: 'Inter',
        ),
      ),
    ),
  );
}

// ── Alert list ────────────────────────────────────────────────────────────────

class _AlertListView extends StatelessWidget {
  const _AlertListView({
    required this.alerts,
    required this.isOffline,
    required this.isRefreshing,
    this.processingAlertId,
  });

  final List<Alert> alerts;
  final bool isOffline;
  final bool isRefreshing;
  final String? processingAlertId;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: CrabSenseColors.primary,
    backgroundColor: CrabSenseColors.surface,
    onRefresh: () async {
      context.read<AlertBloc>().add(const AlertRefreshRequested());
      await context.read<AlertBloc>().stream.firstWhere(
        (s) => s is AlertLoaded && !s.isRefreshing || s is AlertError,
      );
    },
    child: CustomScrollView(
      slivers: [
        // ── Offline banner ──────────────────────────────────────────
        if (isOffline)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _OfflineBanner(),
            ),
          ),

        // ── Empty state ─────────────────────────────────────────────
        if (alerts.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final alert = alerts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AlertCard(
                    alert: alert,
                    isProcessing: processingAlertId == alert.id,
                  ),
                );
              }, childCount: alerts.length),
            ),
          ),
      ],
    ),
  );
}

// ── Offline banner ────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: CrabSenseColors.warning.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: CrabSenseColors.warning.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.wifi_off, size: 16, color: CrabSenseColors.warning),
        const SizedBox(width: 8),
        Text(
          'Showing cached alerts — changes will sync when online',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: CrabSenseColors.warning),
        ),
      ],
    ),
  );
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
              'No alerts',
              style: theme.textTheme.titleMedium?.copyWith(
                color: CrabSenseColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up. No alerts match the current filters.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: CrabSenseColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

class _AlertSkeletonList extends StatelessWidget {
  const _AlertSkeletonList();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
    itemCount: 6,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (_, _) => const SkeletonLoader(height: 110, borderRadius: 16),
  );
}
