import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'crab_hologram_painter.dart';
import 'home_palette.dart';

class AiRecommendationCard extends StatelessWidget {
  final AiRecommendation recommendation;
  final VoidCallback onExecutePressed;
  final VoidCallback onDetailPressed;
  final VoidCallback onDismissPressed;
  final VoidCallback onRemindLaterPressed;
  final VoidCallback onHistoryPressed;

  const AiRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onExecutePressed,
    required this.onDetailPressed,
    required this.onDismissPressed,
    required this.onRemindLaterPressed,
    required this.onHistoryPressed,
  });

  Color _getPriorityColor(ActionPriority priority) {
    switch (priority) {
      case ActionPriority.high:
        return kHomeOrange;
      case ActionPriority.medium:
        return kHomeCyan;
      case ActionPriority.low:
        return kHomeGreen;
    }
  }

  String _getPriorityLabel(ActionPriority priority) {
    switch (priority) {
      case ActionPriority.high:
        return 'Ưu tiên Cao';
      case ActionPriority.medium:
        return 'Ưu tiên Vừa';
      case ActionPriority.low:
        return 'Bình thường';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!recommendation.hasActiveRecommendation) {
      return _buildEmptyRecommendationCard(context);
    }

    final priorityColor = _getPriorityColor(recommendation.priority);

    return Container(
      width: double.infinity,
      decoration: homeCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeBlueLight.withValues(alpha: 0.09),
                  trayExtent: 26,
                ),
              ),
            ),
          ),
          const HomeTopEdgeGlow(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: kHomeBlueLight,
                                shadows: [
                                  Shadow(
                                    color: kHomeBlueLight.withValues(
                                      alpha: 0.8,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'AI RECOMMENDATION',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: kHomeBlueLight,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          fontSize: 13,
                                        ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kHomeGreen.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: kHomeGreen.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              'Tin cậy: ${recommendation.confidencePercentage}%',
                              style: const TextStyle(
                                color: kHomeGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: priorityColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        _getPriorityLabel(recommendation.priority),
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDetailPressed,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: homeTileDecoration(),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kHomeBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kHomeBlue.withValues(alpha: 0.45),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kHomeBlue.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: kHomeBlueLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recommendation.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${recommendation.targetBoxOrArea} — ${recommendation.description}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: CrabSenseColors.textSecondary,
                                        height: 1.35,
                                        fontSize: 12,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: kHomeBlueLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: ElevatedButton(
                        onPressed: onExecutePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kHomeBlue,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: kHomeBlue.withValues(alpha: 0.6),
                          minimumSize: const Size(48, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Thực hiện ngay',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: onDetailPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kHomeBlueLight,
                          side: BorderSide(
                            color: kHomeBorderBlue.withValues(alpha: 0.7),
                          ),
                          minimumSize: const Size(48, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Xem chi tiết'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onRemindLaterPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: CrabSenseColors.hintText,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Nhắc lại sau',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: onDismissPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: CrabSenseColors.hintText,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Bỏ qua',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: homeCardDecoration(accent: kHomeGreen, glowAlpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeBlueLight.withValues(alpha: 0.09),
                  trayExtent: 26,
                ),
              ),
            ),
          ),
          const HomeTopEdgeGlow(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kHomeGreen.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kHomeGreen.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kHomeGreen.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: kHomeGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Không có hành động khẩn cấp',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hệ thống đang hoạt động ổn định. AI tiếp tục giám sát 24/7.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: CrabSenseColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onHistoryPressed,
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('Xem lịch sử AI'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kHomeBlueLight,
                      side: BorderSide(
                        color: kHomeBorderBlue.withValues(alpha: 0.7),
                      ),
                      minimumSize: const Size(130, 38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
