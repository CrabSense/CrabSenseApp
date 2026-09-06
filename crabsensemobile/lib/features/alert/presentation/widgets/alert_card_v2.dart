import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/alerts_models.dart';
import 'alert_badges.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    required this.alert,
    required this.onTap,
    required this.onMore,
    this.isRefreshing = false,
    super.key,
  });

  final AlertItem alert;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${alert.severity.label} ${alert.title}, ${alert.locationLabel}, priority ${alert.priority.score}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: homeCardDecoration(
              radius: 16,
              glowAlpha: alert.isUnread ? 0.2 : 0.1,
              accent: alert.isUnread
                  ? alert.severity.color
                  : kHomeBorderBlue,
            ),
            child: Stack(
              children: [
                const HomeCrabWatermark(alpha: 0.05, trayExtent: 22),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: alert.category == AlertCategory.waterQuality
                            ? kHomeBlueLight.withValues(alpha: 0.15)
                            : kHomeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        alert.category.icon,
                        color: alert.severity.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (alert.isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(
                                    color: kHomeCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  alert.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: kHomeTextMain,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            alert.locationLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onMore,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AlertSeverityBadge(severity: alert.severity, compact: true),
                    AlertPriorityBadge(priority: alert.priority),
                    AlertStatusBadge(status: alert.status),
                    if (alert.syncStatus == AlertSyncStatus.pending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kHomeOrange.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Pending sync',
                          style: TextStyle(
                            color: kHomeOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (alert.threshold?.currentValue != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${alert.threshold!.currentValue} ${alert.threshold!.unit ?? ''} · Ngưỡng ${alert.threshold!.allowedRange ?? '—'}'
                        .trim(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  alert.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (alert.aiRecommendation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'AI: ${alert.aiRecommendation!.action}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kHomeCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _timeAgo(alert.detectedAt),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    if (alert.assignment.isAssigned) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          alert.assignment.assigneeName ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (isRefreshing)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        'Cập nhật ${_timeAgo(alert.updatedAt)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
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
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
    if (d.inHours < 24) return '${d.inHours} giờ trước';
    return '${d.inDays} ngày trước';
  }
}
