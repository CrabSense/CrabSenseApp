import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/boxes_models.dart';
import 'box_status_badge.dart';

String formatRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
}

class BoxCard extends StatelessWidget {
  const BoxCard({
    required this.box,
    required this.onTap,
    required this.onLongPress,
    required this.onMenuSelected,
    this.onExplainHealth,
    super.key,
  });

  final BoxSummary box;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<String> onMenuSelected;
  final VoidCallback? onExplainHealth;

  Color get _accent {
    switch (box.status) {
      case BoxHealthStatus.healthy:
        return kHomeGreen;
      case BoxHealthStatus.warning:
        return kHomeOrange;
      case BoxHealthStatus.critical:
        return Colors.redAccent;
      case BoxHealthStatus.offline:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: box.semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accent.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              box.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              box.location.areaName,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      BoxStatusBadge(status: box.status, compact: true),
                      PopupMenuButton<String>(
                        tooltip: 'Thao tác nhanh',
                        color: kHomeNavy,
                        onSelected: onMenuSelected,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'qr',
                            child: Text(
                              'Quét QR',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'ai',
                            child: Text(
                              'Phát hiện AI',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'water',
                            child: Text(
                              'Kiểm tra nước',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'harvest',
                            child: Text(
                              'Thu hoạch',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'detail',
                            child: Text(
                              'Xem chi tiết',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white.withValues(alpha: 0.45),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AIHealthBadge(
                    healthScore: box.healthScore,
                    compact: true,
                    onExplain: onExplainHealth,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetricChip(
                        icon: Icons.pets_rounded,
                        label: '${box.crabCount} cua',
                      ),
                      if (box.water.temperature != null)
                        _MetricChip(
                          icon: Icons.thermostat_rounded,
                          label:
                              '${box.water.temperature!.toStringAsFixed(0)}°C',
                        ),
                      if (box.water.ph != null)
                        _MetricChip(
                          icon: Icons.science_rounded,
                          label: 'pH ${box.water.ph!.toStringAsFixed(1)}',
                        ),
                      if (box.water.dissolvedOxygen != null)
                        _MetricChip(
                          icon: Icons.air_rounded,
                          label:
                              'DO ${box.water.dissolvedOxygen!.toStringAsFixed(1)}',
                        ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        box.devices.isOnline
                            ? Icons.sensors_rounded
                            : Icons.sensors_off_rounded,
                        size: 14,
                        color: box.devices.isOnline
                            ? kHomeGreen
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        box.devices.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: box.devices.isOnline
                              ? kHomeGreen
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (box.alerts.hasAlerts) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 13,
                          color: kHomeOrange,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${box.alerts.count}',
                          style: const TextStyle(
                            color: kHomeOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        box.healthScore.trend.icon,
                        size: 14,
                        color: box.healthScore.trend.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cập nhật ${formatRelativeTime(box.lastUpdated)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: kHomeNavyDeep.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kHomeCyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
