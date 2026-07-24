import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

class TodayTasksSection extends StatelessWidget {
  final List<TodayTaskItem> tasks;
  final VoidCallback onViewAllPressed;

  const TodayTasksSection({
    super.key,
    required this.tasks,
    required this.onViewAllPressed,
  });

  Color _getPriorityColor(ActionPriority priority) {
    switch (priority) {
      case ActionPriority.high:
        return kHomeOrange;
      case ActionPriority.medium:
        return kHomeCyan;
      case ActionPriority.low:
        return CrabSenseColors.hintText;
    }
  }

  String _formatDeadline(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Quá hạn';
    if (diff.inMinutes < 60) return 'Còn ${diff.inMinutes} phút';
    return 'Còn ${diff.inHours} giờ';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          icon: Icons.task_alt_rounded,
          title: 'CÔNG VIỆC HÔM NAY',
          actionLabel: 'Xem tất cả',
          onAction: onViewAllPressed,
        ),
        const SizedBox(height: 12),

        // Card tiến độ
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: homeCardDecoration(radius: 16, glowAlpha: 0.14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tiến độ hoàn thành',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completedCount/$totalCount công việc',
                    style: const TextStyle(
                      color: kHomeBlueLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: kHomeNavyDeep,
                  valueColor: const AlwaysStoppedAnimation(kHomeBlue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Danh sách công việc
        Column(
          children: tasks.take(3).map((task) {
            final pColor = _getPriorityColor(task.priority);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
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
                  Icon(
                    task.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: task.isCompleted
                        ? kHomeGreen
                        : kHomeBorderBlue,
                    size: 20,
                    shadows: task.isCompleted
                        ? [
                            Shadow(
                              color: kHomeGreen.withValues(alpha: 0.7),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            color: task.isCompleted
                                ? CrabSenseColors.hintText
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.target,
                          style: const TextStyle(
                            color: CrabSenseColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: pColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: pColor.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      _formatDeadline(task.deadline),
                      style: TextStyle(
                        color: pColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
