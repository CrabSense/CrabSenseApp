import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/boxes_models.dart';
import 'box_status_badge.dart';

Future<void> showBoxQuickActionsSheet(
  BuildContext context, {
  required BoxSummary box,
  required bool canPerformActions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: CrabSenseColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CrabSenseColors.hintText.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Thao tác nhanh · ${box.code}',
                style: const TextStyle(
                  color: CrabSenseColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Action(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan QR',
                    enabled: canPerformActions,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(RoutePaths.scanner);
                    },
                  ),
                  _Action(
                    icon: Icons.videocam_rounded,
                    label: 'Quay video AI',
                    enabled: canPerformActions,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(RoutePaths.boxVideo(box.id));
                    },
                  ),
                  _Action(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Detection',
                    enabled: canPerformActions,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(RoutePaths.boxVideo(box.id));
                    },
                  ),
                  _Action(
                    icon: Icons.water_drop_rounded,
                    label: 'Kiểm tra nước',
                    enabled: canPerformActions,
                    onTap: () {
                      Navigator.pop(ctx);
                      final farmId = box.farmId;
                      context.push(
                        farmId.isNotEmpty
                            ? RoutePaths.waterQualityForFarm(farmId)
                            : RoutePaths.waterQuality,
                      );
                    },
                  ),
                  _Action(
                    icon: Icons.agriculture_rounded,
                    label: 'Thu hoạch',
                    enabled: canPerformActions,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(
                        RoutePaths.harvest,
                        extra: {'boxId': box.id, 'farmId': box.farmId},
                      );
                    },
                  ),
                  _Action(
                    icon: Icons.videocam_outlined,
                    label: 'Xem camera',
                    enabled: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(RoutePaths.boxCamera(box.id));
                    },
                  ),
                  _Action(
                    icon: Icons.note_alt_outlined,
                    label: 'Ghi chú',
                    enabled: canPerformActions,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(RoutePaths.operationsForBox(box.id));
                    },
                  ),
                  _Action(
                    icon: Icons.task_alt_rounded,
                    label: 'Tạo công việc',
                    enabled: canPerformActions,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(RoutePaths.operationsForBox(box.id));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showBoxQuickPreviewSheet(
  BuildContext context, {
  required BoxSummary box,
  required bool canPerformActions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: CrabSenseColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CrabSenseColors.hintText.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      box.name,
                      style: const TextStyle(
                        color: CrabSenseColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  BoxStatusBadge(status: box.status),
                ],
              ),
              const SizedBox(height: 12),
              AIHealthBadge(healthScore: box.healthScore),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (box.water.ph != null)
                    _Info('pH', box.water.ph!.toStringAsFixed(1)),
                  if (box.water.temperature != null)
                    _Info(
                      'Nhiệt độ',
                      '${box.water.temperature!.toStringAsFixed(0)}°C',
                    ),
                  _Info('Cua', '${box.crabCount}'),
                ],
              ),
              if (box.aiRecommendation.hasRecommendation) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CrabSenseColors.container,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CrabSenseColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: CrabSenseColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          box.aiRecommendation.title ?? 'Đề xuất AI',
                          style: const TextStyle(
                            color: CrabSenseColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (box.alerts.hasAlerts) ...[
                const SizedBox(height: 8),
                Text(
                  '${box.alerts.count} cảnh báo · ${box.alerts.latestTitle ?? ''}',
                  style: const TextStyle(
                    color: CrabSenseColors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showBoxQuickActionsSheet(
                          context,
                          box: box,
                          canPerformActions: canPerformActions,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CrabSenseColors.primary,
                        side: const BorderSide(color: CrabSenseColors.primary),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Quick Actions'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(RoutePaths.boxDetails(box.id));
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: CrabSenseColors.primary,
                        foregroundColor: CrabSenseColors.background,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Xem chi tiết'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: CrabSenseColors.container,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: CrabSenseColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: CrabSenseColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CrabSenseColors.container,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: CrabSenseColors.hintText,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: CrabSenseColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
