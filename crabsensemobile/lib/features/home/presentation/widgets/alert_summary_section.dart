import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

class AlertSummarySection extends StatelessWidget {
  final List<AlertSummaryItem> alerts;
  final VoidCallback onViewAllPressed;

  const AlertSummarySection({
    super.key,
    required this.alerts,
    required this.onViewAllPressed,
  });

  Color _getSeverityColor(AlertSeverityLevel level) {
    switch (level) {
      case AlertSeverityLevel.critical:
        return CrabSenseColors.danger;
      case AlertSeverityLevel.warning:
        return CrabSenseColors.warning;
      case AlertSeverityLevel.info:
        return kHomeCyan;
    }
  }

  String _getSeverityLabel(AlertSeverityLevel level) {
    switch (level) {
      case AlertSeverityLevel.critical:
        return 'Nguy hiểm';
      case AlertSeverityLevel.warning:
        return 'Cảnh báo';
      case AlertSeverityLevel.info:
        return 'Thông tin';
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${diff.inHours} giờ trước';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          icon: Icons.notifications_active_rounded,
          iconColor: CrabSenseColors.warning,
          title: 'CẢNH BÁO QUAN TRỌNG',
          actionLabel: 'Xem tất cả',
          onAction: onViewAllPressed,
        ),
        const SizedBox(height: 12),
        if (alerts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: homeCardDecoration(
              accent: kHomeGreen,
              glowAlpha: 0.1,
              radius: 16,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: kHomeGreen,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Không có cảnh báo nào cần xử lý',
                  style: TextStyle(
                    color: CrabSenseColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: alerts.take(3).map((item) {
              final color = _getSeverityColor(item.severity);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: color),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                          child: Row(
                            children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    inherit: false,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0A3323),
                                    fontSize: 13.5,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Text(
                                  _getSeverityLabel(item.severity),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.location,
                                style: const TextStyle(
                                  color: CrabSenseColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(item.timestamp),
                                style: const TextStyle(
                                  color: kHomeTextHint,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
