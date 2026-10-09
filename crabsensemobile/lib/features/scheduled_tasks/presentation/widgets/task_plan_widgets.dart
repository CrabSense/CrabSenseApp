import 'package:flutter/material.dart';

import '../../../../core/utils/app_back.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/scheduled_task.dart';

const _navy = Color(0xFF163A2C);
const _sub = Color(0xFF5A7A6C);

DateTime taskDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime weekMonday(DateTime d) {
  final day = taskDay(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

String weekdayShort(int weekday) =>
    const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][weekday - 1];

String weekdayLong(DateTime d) => const [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ][d.weekday - 1];

String hhmm(int minuteOfDay) {
  final h = minuteOfDay ~/ 60;
  final m = minuteOfDay % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

String recurrenceLabel(String type) => switch (type.toLowerCase()) {
      'once' => 'Một lần',
      'weekly' => 'Theo tuần',
      _ => 'Mỗi ngày',
    };

bool taskOccursOn(ScheduledTask task, DateTime day) {
  final d = taskDay(day);
  final start = taskDay(task.startDate);
  if (d.isBefore(start)) return false;
  if (task.endDate != null && d.isAfter(taskDay(task.endDate!))) return false;
  switch (task.recurrenceType.toLowerCase()) {
    case 'once':
      return d == start;
    case 'weekly':
      return task.daysOfWeek.isEmpty || task.daysOfWeek.contains(d.weekday);
    default:
      return true;
  }
}

IconData taskIconFor(ScheduledTask task) {
  final t = '${task.title} ${task.description ?? ''}'.toLowerCase();
  if (t.contains('nước') || t.contains('ph') || t.contains('oxy')) {
    return Icons.water_drop_rounded;
  }
  if (t.contains('hộp') || t.contains('box')) {
    return Icons.grid_view_rounded;
  }
  if (t.contains('muối') || t.contains('khoáng')) {
    return Icons.science_outlined;
  }
  if (t.contains('bảo trì') || t.contains('sửa')) {
    return Icons.build_outlined;
  }
  return Icons.restaurant_outlined;
}

class TaskHeroHeader extends StatelessWidget {
  const TaskHeroHeader({
    required this.onPickDate,
    super.key,
  });

  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            SizedBox(
              height: 168,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/background_chao_user.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.35),
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFFBFE8D4)),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.55, 1.0],
                        colors: [
                          Color(0x33FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0xCCF7FCFA),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 10, 14, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => appBack(context),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Color(0xFF1F6B4A),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4F5C4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: Color(0xFF2F8A4E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kế hoạch việc cần làm',
                                  style: TextStyle(
                                    color: _navy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                Text(
                                  'Quản lý công việc trại cua',
                                  style: TextStyle(
                                    color: _sub,
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: onPickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFD5E8DC),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: Color(0xFF2F8A4E),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 20,
                    bottom: 78,
                    child: Text(
                      'Làm việc đúng kế hoạch\nTrại cua hiệu quả hơn',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 56),
          ],
        ),
      ],
    );
  }
}

class WeeklyTaskCalendar extends StatelessWidget {
  const WeeklyTaskCalendar({
    required this.weekStart,
    required this.selected,
    required this.doneForDay,
    required this.totalForDay,
    required this.onSelect,
    super.key,
  });

  final DateTime weekStart;
  final DateTime selected;
  final int Function(DateTime day) doneForDay;
  final int Function(DateTime day) totalForDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: homeCardDecoration(radius: 18),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = weekStart.add(Duration(days: i));
                  return _TaskDayCard(
                    day: day,
                    selected: taskDay(day) == taskDay(selected),
                    done: doneForDay(day),
                    total: totalForDay(day),
                    onTap: () => onSelect(day),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskDayCard extends StatelessWidget {
  const _TaskDayCard({
    required this.day,
    required this.selected,
    required this.done,
    required this.total,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final int done;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : _navy;
    final progress = total == 0 ? 0.0 : done / total;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2F8A4E), Color(0xFF7BC67A)],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE4F0E8),
          ),
        ),
        child: Column(
          children: [
            Text(
              weekdayShort(day.weekday),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : _sub,
              ),
            ),
            Text(
              '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: selected
                    ? Colors.white.withValues(alpha: 0.35)
                    : const Color(0xFFE8F3EC),
                color: selected ? Colors.white : kHomePrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$done/$total',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _sub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayProgressHeader extends StatelessWidget {
  const TodayProgressHeader({
    required this.date,
    required this.done,
    required this.total,
    super.key,
  });

  final DateTime date;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isToday = taskDay(date) == taskDay(DateTime.now());
    final ratio = total == 0 ? 0.0 : done / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                children: [
                  Text(
                    isToday ? 'Hôm nay' : 'Ngày chọn',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${weekdayLong(date)}, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                      style: const TextStyle(fontSize: 12, color: _sub),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$done/$total đã hoàn thành',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F8A4E),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 110,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8F3EC),
                      color: kHomePrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

enum TaskPlanFilter { all, pending, doing, done }

class TaskSummarySection extends StatelessWidget {
  const TaskSummarySection({
    required this.total,
    required this.pending,
    required this.doing,
    required this.done,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final int total;
  final int pending;
  final int doing;
  final int done;
  final TaskPlanFilter selected;
  final ValueChanged<TaskPlanFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (TaskPlanFilter.all, Icons.segment_rounded, 'Tất cả', total),
      (TaskPlanFilter.pending, Icons.schedule_rounded, 'Chưa làm', pending),
      (TaskPlanFilter.doing, Icons.play_circle_outline, 'Đang làm', doing),
      (TaskPlanFilter.done, Icons.check_circle_rounded, 'Đã xong', done),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final tight = c.maxWidth < 360;
        final children = [
          for (final t in tiles)
            _SummaryTile(
              selected: selected == t.$1,
              icon: t.$2,
              label: t.$3,
              value: t.$4,
              onTap: () => onSelect(t.$1),
            ),
        ];
        if (tight) {
          return Column(
            children: [
              Row(children: [children[0], const SizedBox(width: 8), children[1]]),
              const SizedBox(height: 8),
              Row(children: [children[2], const SizedBox(width: 8), children[3]]),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              children[i],
            ],
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE7F7E8) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? kHomePrimary : const Color(0xFFE8EEE9),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: kHomePrimaryDark),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _sub,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskPlanCard extends StatelessWidget {
  const TaskPlanCard({
    required this.task,
    required this.completed,
    required this.completedAt,
    required this.onToggleDone,
    required this.onDelete,
    super.key,
  });

  final ScheduledTask task;
  final bool completed;
  final DateTime? completedAt;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, Color, Color)>[
      (
        recurrenceLabel(task.recurrenceType),
        const Color(0xFFE7F6EA),
        const Color(0xFF2F8A4E),
      ),
      if ((task.description ?? '').trim().isNotEmpty)
        (
          task.description!.trim(),
          const Color(0xFFE8F3F8),
          const Color(0xFF2A7A9B),
        )
      else
        (
          task.farmingAreaId == null || task.farmingAreaId!.isEmpty
              ? 'Tất cả hộp'
              : 'Khu nuôi',
          const Color(0xFFE8F3F8),
          const Color(0xFF2A7A9B),
        ),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: homeCardDecoration(radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE7F6EA),
            child: Icon(taskIconFor(task), color: kHomePrimaryDark, size: 22),
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
                        task.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (v) {
                        if (v == 'done') onToggleDone();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'done',
                          child: Text(
                            completed
                                ? 'Bỏ hoàn thành'
                                : 'Đánh dấu hoàn thành',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa'),
                        ),
                      ],
                      child: const Icon(Icons.more_vert_rounded, color: _sub),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: _sub),
                    const SizedBox(width: 4),
                    Text(
                      '${recurrenceLabel(task.recurrenceType)} • ${hhmm(task.reminderMinuteOfDay)}',
                      style: const TextStyle(fontSize: 12, color: _sub),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in chips)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: c.$2,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          c.$1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.$3,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onToggleDone,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: completed
                            ? const Color(0xFFE7F6EA)
                            : const Color(0xFFF3F5F4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                completed
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 14,
                                color: completed
                                    ? kHomePrimaryDark
                                    : _sub,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                completed ? 'Đã hoàn thành' : 'Chưa làm',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: completed
                                      ? kHomePrimaryDark
                                      : _sub,
                                ),
                              ),
                            ],
                          ),
                          if (completed && completedAt != null)
                            Text(
                              'Hoàn thành ${hhmm(completedAt!.hour * 60 + completedAt!.minute)}',
                              style: const TextStyle(fontSize: 10, color: _sub),
                            ),
                        ],
                      ),
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

class DailyCompletionCard extends StatelessWidget {
  const DailyCompletionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF8E8), Color(0xFFF7FCF6)],
        ),
        border: Border.all(color: const Color(0xFFD5EBD6)),
      ),
      child: const Row(
        children: [
          Icon(Icons.eco_rounded, color: Color(0xFF2F8A4E)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tất cả công việc hôm nay đã hoàn thành!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tiếp tục duy trì để trại cua luôn hiệu quả.',
                  style: TextStyle(fontSize: 12, color: _sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskEmptyState extends StatelessWidget {
  const TaskEmptyState({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: homeCardDecoration(radius: 22),
      child: Column(
        children: [
          Image.asset(
            'assets/images/background_chao_user.png',
            height: 72,
            width: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.assignment_outlined,
              size: 40,
              color: kHomePrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có việc cần làm',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy thêm công việc đầu tiên để bắt đầu quản lý trại nuôi hiệu quả hơn!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _sub),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(backgroundColor: kHomePrimaryDark),
            icon: const Icon(Icons.add),
            label: const Text('Thêm việc'),
          ),
        ],
      ),
    );
  }
}

class TaskPlanSkeleton extends StatelessWidget {
  const TaskPlanSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget box({double h = 72, double r = 16}) => Container(
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F3EC),
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return Column(
      children: [
        box(h: 96, r: 22),
        const SizedBox(height: 16),
        box(h: 48, r: 12),
        const SizedBox(height: 12),
        box(h: 64, r: 16),
        const SizedBox(height: 12),
        box(h: 110, r: 22),
        const SizedBox(height: 12),
        box(h: 110, r: 22),
      ],
    );
  }
}

class TaskPlanErrorCard extends StatelessWidget {
  const TaskPlanErrorCard({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: homeCardDecoration(radius: 18),
      child: Column(
        children: [
          const Text(
            'Không thể tải kế hoạch',
            style: TextStyle(fontWeight: FontWeight.w800, color: _navy),
          ),
          const SizedBox(height: 4),
          const Text('Vui lòng thử lại.', style: TextStyle(color: _sub)),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
