import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

class RecentActivitySection extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final VoidCallback? onViewAllPressed;

  const RecentActivitySection({
    super.key,
    required this.activities,
    this.onViewAllPressed,
  });

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.qrScan:
        return Icons.qr_code_scanner_rounded;
      case ActivityType.sensorUpdate:
        return Icons.sensors_rounded;
      case ActivityType.aiDetection:
        return Icons.auto_awesome_rounded;
      case ActivityType.harvest:
        return Icons.inventory_2_rounded;
      case ActivityType.sync:
        return Icons.sync_rounded;
      case ActivityType.alertHandled:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.qrScan:
        return kHomeBlue;
      case ActivityType.sensorUpdate:
        return kHomeCyan;
      case ActivityType.aiDetection:
        return kHomePurple;
      case ActivityType.harvest:
        return kHomeGreen;
      case ActivityType.sync:
        return kHomeBlueLight;
      case ActivityType.alertHandled:
        return kHomeOrange;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${diff.inHours} giờ trước';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          icon: Icons.history_rounded,
          title: 'NHẬT KÝ HOẠT ĐỘNG GẦN ĐÂY',
          actionLabel: onViewAllPressed != null ? 'Xem tất cả' : null,
          onAction: onViewAllPressed,
        ),
        const SizedBox(height: 12),
        Column(
          children: activities.take(4).map((activity) {
            final color = _getActivityColor(activity.type);
            final icon = _getActivityIcon(activity.type);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
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
                    color: kHomeBlue.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity.description,
                          style: const TextStyle(
                            color: CrabSenseColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeAgo(activity.timestamp),
                    style: const TextStyle(
                      color: CrabSenseColors.hintText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
