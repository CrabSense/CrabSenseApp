import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

/// Today Tasks Section — Light theme rebuild.
class TodayTasksSection extends StatelessWidget {
  final List<TodayTaskItem> tasks;
  final VoidCallback onViewAllPressed;

  const TodayTasksSection({
    super.key,
    required this.tasks,
    required this.onViewAllPressed,
  });

  Color _taskTypeColor(ActionPriority priority) {
    switch (priority) {
      case ActionPriority.high:
        return kHomeDanger;
      case ActionPriority.medium:
        return kHomeSecondary;
      case ActionPriority.low:
        return kHomePrimary;
    }
  }

  IconData _taskTypeIcon(ActionPriority priority) {
    switch (priority) {
      case ActionPriority.high:
        return Icons.warning_rounded;
      case ActionPriority.medium:
        return Icons.water_drop_rounded;
      case ActionPriority.low:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _formatDeadline(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Quá hạn';
    if (diff.inMinutes < 60) return 'Còn ${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return 'Hôm nay';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          icon: Icons.task_alt_rounded,
          title: 'Công việc cần làm',
          actionLabel: 'Xem tất cả',
          onAction: onViewAllPressed,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: homeCardDecoration(),
          child: Column(
            children: [
              // Title row with add button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                child: Row(
                  children: [
                    const Text(
                      'Hôm nay',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kHomeTextMain,
                      ),
                    ),
                    const Spacer(),
                    // Add button
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: kHomePrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: kHomeBorder),
              ),
              // Task list or empty
              if (tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.task_alt_rounded,
                            color: kHomePrimary, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Không có công việc hôm nay',
                          style: TextStyle(
                            fontSize: 13,
                            color: kHomeTextSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: tasks.take(4).length,
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: kHomeBorder),
                  ),
                  itemBuilder: (context, i) {
                    final task = tasks.take(4).elementAt(i);
                    final typeColor = _taskTypeColor(task.priority);
                    final typeIcon = _taskTypeIcon(task.priority);
                    return _TaskTile(
                      task: task,
                      typeColor: typeColor,
                      typeIcon: typeIcon,
                      deadlineLabel: _formatDeadline(task.deadline),
                    );
                  },
                ),
              // Footer
              if (tasks.length > 4)
                GestureDetector(
                  onTap: onViewAllPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: kHomeBorder)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Xem thêm ${tasks.length - 4} công việc',
                          style: const TextStyle(
                            color: kHomePrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.expand_more_rounded,
                            color: kHomePrimary, size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.typeColor,
    required this.typeIcon,
    required this.deadlineLabel,
  });

  final TodayTaskItem task;
  final Color typeColor;
  final IconData typeIcon;
  final String deadlineLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Task type icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: typeColor, size: 16),
          ),
          const SizedBox(width: 12),
          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: task.isCompleted
                        ? kHomeTextHint
                        : kHomeTextMain,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.target,
                  style: const TextStyle(
                      fontSize: 11, color: kHomeTextSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Deadline badge + checkbox
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: kHomeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kHomeBorder),
                ),
                child: Text(
                  deadlineLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kHomeTextSub,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                task.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: task.isCompleted ? kHomePrimary : kHomeBorder,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
