import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/boxes_models.dart';
import 'box_card.dart';
import 'box_status_badge.dart';

class BoxListTileCard extends StatelessWidget {
  const BoxListTileCard({
    required this.box,
    required this.onTap,
    required this.onSwipeAction,
    super.key,
  });

  final BoxSummary box;
  final VoidCallback onTap;
  final ValueChanged<String> onSwipeAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: box.semanticLabel,
      button: true,
      child: Dismissible(
        key: ValueKey('box-list-${box.id}'),
        background: _SwipeBg(
          alignment: Alignment.centerLeft,
          color: CrabSenseColors.primary,
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan QR',
        ),
        secondaryBackground: _SwipeBg(
          alignment: Alignment.centerRight,
          color: CrabSenseColors.success,
          icon: Icons.agriculture_rounded,
          label: 'Harvest',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onSwipeAction('qr');
          } else {
            onSwipeAction('harvest');
          }
          return false;
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kHomeBorderBlue.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: kHomeBlue.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: box.healthScore.scoreColor.withValues(alpha: 0.18),
                      border: Border.all(
                        color: box.healthScore.scoreColor.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Text(
                      '${box.healthScore.score}',
                      style: TextStyle(
                        color: box.healthScore.scoreColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                box.code,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            BoxStatusBadge(status: box.status, compact: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${box.location.areaName} · ${box.crabCount} cua'
                          '${box.water.ph != null ? ' · pH ${box.water.ph!.toStringAsFixed(1)}' : ''}'
                          '${box.water.temperature != null ? ' · ${box.water.temperature!.toStringAsFixed(0)}°C' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (box.alerts.hasAlerts) ...[
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: kHomeOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${box.alerts.count} cảnh báo',
                                style: const TextStyle(
                                  color: kHomeOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              formatRelativeTime(box.lastUpdated),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: CrabSenseColors.hintText,
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

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ] else ...[
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: color),
          ],
        ],
      ),
    );
  }
}
