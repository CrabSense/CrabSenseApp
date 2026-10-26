import 'dart:async';

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
  Timer? _poll;
  UserRole? _lastRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(alertsStateProvider.notifier).refresh();
    });
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) ref.read(alertsStateProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
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

  List<AlertItem> _filterByTab(List<AlertItem> alerts, int tabIndex) {
    if (tabIndex == 0) return alerts;
    if (tabIndex == 1) {
      return alerts
          .where((a) => a.category == AlertCategory.waterQuality)
          .toList();
    }
    return alerts
        .where(
          (a) =>
              a.category == AlertCategory.device ||
              a.category == AlertCategory.system,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) _syncPermissions(authState.user);

    final async = ref.watch(alertsStateProvider);
    final data = async.valueOrNull;

    return Scaffold(
      backgroundColor: kHomeBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _header(data),
            ),
            if (data != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _AlertFilterPills(
                  controller: _tabController,
                  alerts: data.visibleAlerts,
                ),
              ),
            Expanded(
              child: async.when(
                loading: () => const AlertsSkeleton(),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SectionErrorCard(
                      message: ErrorMapper.userFacingMessage(e),
                      onRetry: () =>
                          ref.read(alertsStateProvider.notifier).refresh(),
                    ),
                  ),
                ),
                data: (data) => TabBarView(
                  controller: _tabController,
                  children: List.generate(3, (tabIdx) {
                    final filtered = _filterByTab(data.visibleAlerts, tabIdx);
                    return _AlertListView(
                      alerts: filtered,
                      data: data,
                      onRefresh: () =>
                          ref.read(alertsStateProvider.notifier).refresh(),
                      onTap: (a) => _openDetail(a, data),
                      onDismiss: (a) {
                        ref.read(alertsStateProvider.notifier).hideAlert(a.id);
                        _snack('Đã tạm ẩn cảnh báo');
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header đồng bộ tab Hộp nuôi / Home: icon phát sáng, tiêu đề in hoa,
  /// chip trạng thái, nút làm mới dạng ô vuông.
  Widget _header(AlertsStateData? data) {
    final open = data?.summary.open ?? 0;
    final online = data != null && data.isOnline && !data.isOfflineCached;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications_active_rounded,
              size: 20,
              color: kHomeBlueLight,
              shadows: [
                Shadow(
                  color: kHomeBlueLight.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'CẢNH BÁO',
                  style: TextStyle(
                    color: kHomePrimaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _OnlineChip(online: online),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => ref.read(alertsStateProvider.notifier).refresh(),
              tooltip: 'Làm mới',
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
                color: kHomeBlueLight,
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: kHomeBg.withValues(alpha: 0.75),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: kHomeBorderBlue.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          data == null
              ? 'Đang tải cảnh báo…'
              : '$open cảnh báo chưa xử lý · ${data.selectedFarmName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: kHomeTextSub, fontSize: 12),
        ),
      ],
    );
  }
}

// ─── Header chips ─────────────────────────────────────────────────────────────

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? kHomePrimaryDark : kHomeWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            online ? 'Online' : 'Offline',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill lọc theo nhóm cảnh báo — thay [TabBar] gạch chân cũ.
class _AlertFilterPills extends StatelessWidget {
  const _AlertFilterPills({required this.controller, required this.alerts});

  final TabController controller;
  final List<AlertItem> alerts;

  static const _labels = ['Tất cả', 'Nước', 'Thiết bị & bể'];
  static const _colors = [kHomePrimaryDark, kHomeInfo, kHomeWarning];

  int _countFor(int index) {
    if (index == 0) return alerts.length;
    if (index == 1) {
      return alerts
          .where((a) => a.category == AlertCategory.waterQuality)
          .length;
    }
    return alerts
        .where(
          (a) =>
              a.category == AlertCategory.device ||
              a.category == AlertCategory.system,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final active = controller.index;
        return Row(
          children: [
            for (var i = 0; i < _labels.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => controller.animateTo(i),
                    child: Container(
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _colors[i].withValues(
                          alpha: active == i ? 0.22 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _colors[i], width: 1.2),
                      ),
                      child: Text(
                        '${_labels[i]} ${_countFor(i)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: _colors[i],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
              child: const Icon(
                Icons.delete_outline_rounded,
                color: kHomeDanger,
              ),
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
      case AlertItemSeverity.low:
        return kHomeSecondary;
      case AlertItemSeverity.resolved:
        return kHomePrimary;
    }
  }

  IconData _icon() {
    final text = '${alert.title} ${alert.description}'.toLowerCase();
    if (text.contains('tràn')) return Icons.water_rounded;
    if (text.contains('cạn')) return Icons.water_drop_outlined;
    if (text.contains('bật') || text.contains('tắt'))
      return Icons.power_settings_new_rounded;
    switch (alert.severity) {
      case AlertItemSeverity.critical:
        return Icons.error_rounded;
      case AlertItemSeverity.high:
        return Icons.warning_rounded;
      case AlertItemSeverity.medium:
        return Icons.info_rounded;
      case AlertItemSeverity.low:
        return Icons.check_circle_rounded;
      case AlertItemSeverity.resolved:
        return Icons.check_circle_outline_rounded;
    }
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
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: homeCardDecoration(radius: 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon(), color: accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kHomeTextMain,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SeverityPill(
                            label: alert.severity.labelVi,
                            color: accent,
                          ),
                        ],
                      ),
                      if (alert.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          alert.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kHomeTextSub,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: kHomeTextHint,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _timestamp(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: kHomeTextHint,
                              ),
                            ),
                          ),
                          if (alert.category == AlertCategory.waterQuality) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.water_drop_rounded,
                              size: 12,
                              color: kHomeTextHint,
                            ),
                            const SizedBox(width: 3),
                            const Flexible(
                              child: Text(
                                'Môi trường nước',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: kHomeTextHint,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
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
            child: const Icon(
              Icons.shield_rounded,
              color: kHomePrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có thông báo tắt máy hoặc mực bể',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kHomeTextMain,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Khi thiết bị tắt, hoặc bể chuyển sang cạn hay tràn, thông báo hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kHomeTextSub, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
