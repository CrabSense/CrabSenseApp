import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/alerts_models.dart';
import 'ai_recommended_action_card.dart';
import 'alert_badges.dart';

class AlertTimeline extends StatelessWidget {
  const AlertTimeline({required this.events, super.key});

  final List<AlertTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text(
        'Chưa có lịch sử xử lý',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      );
    }

    final sorted = [...events]..sort((a, b) => b.at.compareTo(a.at));

    return Column(
      children: [
        for (var i = 0; i < sorted.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: sorted[i].status?.color ?? kHomeCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (i != sorted.length - 1)
                    Container(
                      width: 2,
                      height: 36,
                      color: kHomeCyan.withValues(alpha: 0.75),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sorted[i].title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (sorted[i].actorName != null)
                        Text(
                          sorted[i].actorName!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      if (sorted[i].note != null)
                        Text(
                          sorted[i].note!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      Text(
                        _fmt(sorted[i].at),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} $h:$m';
  }
}

Future<void> showAlertQuickActionsSheet({
  required BuildContext context,
  required AlertItem alert,
  required bool canAcknowledge,
  required bool canResolve,
  required bool canAssign,
  required VoidCallback onAcknowledge,
  required VoidCallback onHandle,
  required VoidCallback onAssign,
  required VoidCallback onViewBox,
  required VoidCallback onViewDetail,
  required VoidCallback onHide,
  required ValueChanged<AlertActionDef> onAction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: kHomeNavyLift,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            const HomeCrabWatermark(alpha: 0.05, trayExtent: 28),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kHomeCyan.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      alert.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        AlertSeverityBadge(severity: alert.severity, compact: true),
                        AlertStatusBadge(status: alert.status),
                      ],
                    ),
              const SizedBox(height: 12),
              if (canAcknowledge)
                _sheetTile(Icons.visibility_rounded, 'Xác nhận đã xem', () {
                  Navigator.pop(ctx);
                  onAcknowledge();
                }),
              if (canResolve)
                _sheetTile(Icons.play_circle_outline_rounded, 'Xử lý', () {
                  Navigator.pop(ctx);
                  onHandle();
                }),
              if (canAssign)
                _sheetTile(Icons.person_add_alt_1_rounded, 'Giao việc', () {
                  Navigator.pop(ctx);
                  onAssign();
                }),
              if (alert.boxId != null)
                _sheetTile(Icons.inventory_2_outlined, 'Xem Box', () {
                  Navigator.pop(ctx);
                  onViewBox();
                }),
              _sheetTile(Icons.info_outline_rounded, 'Xem chi tiết', () {
                Navigator.pop(ctx);
                onViewDetail();
              }),
              _sheetTile(Icons.visibility_off_outlined, 'Tạm ẩn', () {
                Navigator.pop(ctx);
                onHide();
              }),
              if (alert.quickActions.isNotEmpty) ...[
                const Divider(color: Colors.white12),
                const Text(
                  'Hành động theo loại',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                for (final a in alert.quickActions)
                  _sheetTile(a.icon, a.label, () async {
                    if (a.requiresConfirmation) {
                      final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          backgroundColor: Colors.transparent,
                          title: const Text(
                            'Xác nhận',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          content: Text(
                            'Bạn chắc chắn muốn thực hiện: ${a.label}?',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('Hủy'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    onAction(a);
                  }),
              ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _sheetTile(IconData icon, String label, VoidCallback onTap) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: kHomeCyan),
    title: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    onTap: onTap,
    minVerticalPadding: 12,
  );
}

Future<void> showAlertAssignmentSheet({
  required BuildContext context,
  required AlertItem alert,
  required void Function({
    required String assigneeId,
    required String assigneeName,
    required String assigneeRole,
    String? note,
  })
  onAssign,
}) {
  String role = 'Operator';
  final nameCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: kHomeNavyLift,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                const HomeCrabWatermark(alpha: 0.05, trayExtent: 28),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.viewInsetsOf(ctx).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giao cảnh báo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                  initialValue: role,
                  dropdownColor: kHomeNavyLift,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Operator',
                      child: Text('Operator'),
                    ),
                    DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                    DropdownMenuItem(
                      value: 'Technician',
                      child: Text('Technician'),
                    ),
                    DropdownMenuItem(
                      value: 'Farm staff',
                      child: Text('Farm staff'),
                    ),
                  ],
                  onChanged: (v) => setModal(() => role = v ?? role),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tên người nhận',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(ctx);
                      onAssign(
                        assigneeId: 'user-${name.hashCode}',
                        assigneeName: name,
                        assigneeRole: role,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: kHomeCyan,
                      foregroundColor: kHomeNavyDeep,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Giao việc'),
                  ),
                ),
              ],
            ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showAlertDetailSheet({
  required BuildContext context,
  required AlertItem alert,
  required bool canAssign,
  required VoidCallback onHandle,
  required VoidCallback onAcknowledge,
  VoidCallback? onAssign,
  VoidCallback? onViewBox,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: kHomeNavyLift,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                const HomeCrabWatermark(alpha: 0.045, trayExtent: 30),
                ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kHomeCyan.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      alert.code,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AlertSeverityBadge(severity: alert.severity),
                  AlertPriorityBadge(priority: alert.priority),
                  AlertStatusBadge(status: alert.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.description,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _detailRow('Vị trí', alert.locationLabel),
              if (alert.threshold != null) ...[
                _detailRow(
                  'Giá trị hiện tại',
                  '${alert.threshold!.currentValue ?? '—'} ${alert.threshold!.unit ?? ''}'
                      .trim(),
                ),
                _detailRow('Ngưỡng', alert.threshold!.allowedRange ?? '—'),
              ],
              _detailRow('Điểm ưu tiên', '${alert.priority.score}'),
              _detailRow('Giải thích điểm', alert.priority.explanation),
              if (alert.possibleCause != null)
                _detailRow('Nguyên nhân có thể', alert.possibleCause!),
              if (alert.impactLevel != null)
                _detailRow('Tác động dự kiến', alert.impactLevel!),
              if (alert.aiRecommendation != null) ...[
                const SizedBox(height: 12),
                AIRecommendedActionCard(
                  recommendation: alert.aiRecommendation!,
                  onExecute: () {
                    Navigator.pop(ctx);
                    onHandle();
                  },
                  onAssign: canAssign && onAssign != null
                      ? () {
                          Navigator.pop(ctx);
                          onAssign();
                        }
                      : null,
                ),
              ],
              if (alert.assignment.isAssigned) ...[
                const SizedBox(height: 14),
                const Text(
                  'Người phụ trách',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${alert.assignment.assigneeName} · ${alert.assignment.assigneeRole}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Timeline xử lý',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              AlertTimeline(events: alert.timeline),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onHandle();
                    },
                    child: const Text('Xử lý ngay'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onAcknowledge();
                    },
                    child: const Text('Xác nhận đã xem'),
                  ),
                  if (onViewBox != null)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onViewBox();
                      },
                      child: const Text('Xem Box'),
                    ),
                ],
              ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
