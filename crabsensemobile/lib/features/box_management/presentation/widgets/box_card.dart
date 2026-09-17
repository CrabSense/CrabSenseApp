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

  /// Màu nhấn của thẻ — lấy thẳng từ [BoxStatus] để không lệch với huy hiệu
  /// trạng thái và app desktop.
  Color get _accent => box.status.color;

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
              color: kHomeSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kHomeBorder),
              boxShadow: const [
                BoxShadow(
                  color: kHomeShadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 4, color: _accent),
                  Padding(
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
                                color: kHomeTextMain,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              box.location.areaName,
                              style: const TextStyle(
                                color: kHomeTextSub,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      BoxStatusBadge(status: box.status, compact: true),
                      PopupMenuButton<String>(
                        tooltip: 'Thao tác nhanh',
                        color: kHomeBg,
                        onSelected: onMenuSelected,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'qr',
                            child: Text(
                              'Quét QR',
                              style: TextStyle(
                                color: const Color(0xFF5A7184),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'ai',
                            child: Text(
                              'Phát hiện AI',
                              style: TextStyle(
                                color: const Color(0xFF5A7184),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'water',
                            child: Text(
                              'Kiểm tra nước',
                              style: TextStyle(
                                color: const Color(0xFF5A7184),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'harvest',
                            child: Text(
                              'Thu hoạch',
                              style: TextStyle(
                                color: const Color(0xFF5A7184),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'detail',
                            child: Text(
                              'Xem chi tiết',
                              style: TextStyle(
                                color: const Color(0xFF5A7184),
                              ),
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: const Color(0xFF5A7184),
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
                            : const Color(0xFF5A7184),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        box.devices.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: box.devices.isOnline
                              ? kHomeGreen
                              : const Color(0xFF5A7184),
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
                    style: const TextStyle(
                      color: kHomeTextSub,
                      fontSize: 10,
                    ),
                  ),
                ],
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
        color: kHomeBg.withValues(alpha: 0.7),
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
            style: const TextStyle(
              color: kHomeTextSub,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
