import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../app/routes.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/alerts_models.dart';
import '../providers/alerts_provider.dart';
import '../widgets/alert_sheets.dart';
import '../widgets/alerts_skeleton.dart';
import '../widgets/alerts_states.dart';

/// Alerts screen — Light theme rebuild.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  UserRole? _lastRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        backgroundColor: kHomePrimary,
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
      onAssign: ({
        required String assigneeId,
        required String assigneeName,
        required String assigneeRole,
        String? note,
      }) {
        ref.read(alertsStateProvider.notifier).assign(
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

  List<AlertItem> _filterByTab(List<AlertItem> alerts, int tabIndex) {
    if (tabIndex == 0) return alerts;
    if (tabIndex == 1) {
      return alerts.where((a) => a.category == AlertCategory.waterQuality).toList();
    }
    return alerts.where((a) => a.category != AlertCategory.waterQuality).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) _syncPermissions(authState.user);

    final async = ref.watch(alertsStateProvider);
    final totalUnread = async.valueOrNull?.summary.open ?? 0;

    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56 + 48),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kHomePrimary, kHomePrimaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Cảnh báo',
                          style: TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (totalUnread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$totalUnread',
                            style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white),
                        onPressed: () =>
                            ref.read(alertsStateProvider.notifier).refresh(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Tất cả'),
                    Tab(text: 'Chất lượng nước'),
                    Tab(text: 'Cua'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const AlertsSkeleton(),
        error: (e, _) => Center(
          child: SectionErrorCard(message: ErrorMapper.userFacingMessage(e),
            onRetry: () =>
                ref.read(alertsStateProvider.notifier).refresh(),
          ),
        ),
        data: (data) => TabBarView(
          controller: _tabController,
          children: List.generate(3, (tabIdx) {
            final filtered = _filterByTab(data.visibleAlerts, tabIdx);
            return _AlertListView(
              alerts: filtered,
              data: data,
              onRefresh: () => ref.read(alertsStateProvider.notifier).refresh(),
              onTap: (a) => _openDetail(a, data),
              onDismiss: (a) {
                ref.read(alertsStateProvider.notifier).hideAlert(a.id);
                _snack('Đã tạm ẩn cảnh báo');
              },
            );
          }),
        ),
      ),
    );
  }
}

// ─── Alert List ───────────────────────────────────────────────────────────────

class _AlertListView extends StatelessWidget {
  const _AlertListView({
    required this.alerts,
    required this.data,
    required this.onRefresh,
    required this.onTap,
    required this.onDismiss,
  });

  final List<AlertItem> alerts;
  final AlertsStateData data;
  final Future<void> Function() onRefresh;
  final void Function(AlertItem) onTap;
  final void Function(AlertItem) onDismiss;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const _EmptyAlertsState();
    }
    return RefreshIndicator(
      color: kHomePrimary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final alert = alerts[i];
          return Dismissible(
            key: Key(alert.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: kHomeDanger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: kHomeDanger),
            ),
            onDismissed: (_) => onDismiss(alert),
            child: _AlertCard(alert: alert, onTap: () => onTap(alert)),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onTap});

  final AlertItem alert;
  final VoidCallback onTap;

  Color _accentColor() {
    switch (alert.severity) {
      case AlertItemSeverity.critical:
        return kHomeDanger;
      case AlertItemSeverity.high:
        return kHomeWarning;
      case AlertItemSeverity.medium:
        return kHomePrimary;
      case AlertItemSeverity.low: return kHomeSecondary; case AlertItemSeverity.resolved: return kHomePrimary; }
  }

  IconData _icon() {
    switch (alert.severity) {
      case AlertItemSeverity.critical:
        return Icons.error_rounded;
      case AlertItemSeverity.high:
        return Icons.warning_rounded;
      case AlertItemSeverity.medium:
        return Icons.info_rounded;
      case AlertItemSeverity.low: return Icons.check_circle_rounded; case AlertItemSeverity.resolved: return Icons.check_circle_outline_rounded; }
  }

  String _timestamp() {
    final diff = DateTime.now().difference(alert.detectedAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kHomeBorder),
          boxShadow: [BoxShadow(color: const Color(0x14000000), blurRadius: 6, offset: const Offset(0, 2))],  
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent border
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon(), color: accent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: accent == kHomeDanger
                                    ? kHomeDanger
                                    : kHomeTextMain,
                              ),
                            ),
                            if (alert.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                alert.description,
                                style: const TextStyle(
                                    fontSize: 12, color: kHomeTextSub),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timestamp(),
                        style: const TextStyle(
                            fontSize: 11, color: kHomeTextHint),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAlertsState extends StatelessWidget {
  const _EmptyAlertsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kHomePrimaryBg,
              shape: BoxShape.circle,
              border: Border.all(color: kHomePrimary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.shield_rounded,
                color: kHomePrimary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có cảnh báo nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kHomeTextMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trang trại hoạt động bình thường 🎉',
            style: TextStyle(fontSize: 13, color: kHomeTextSub),
          ),
        ],
      ),
    );
  }
}
