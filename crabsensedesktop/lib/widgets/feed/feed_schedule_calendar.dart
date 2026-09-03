import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/feed_management.dart';
import '../../theme/dashboard_theme.dart';

/// Lịch tháng kiểu streak (tham chiếu Duolingo): thanh nối, chấm cam, pin xanh.
class FeedScheduleCalendar extends StatelessWidget {
  const FeedScheduleCalendar({
    super.key,
    required this.month,
    required this.days,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<FeedCalendarDayState> days;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;

  static const _weekLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  static const streakBar = Color(0x66FF9600);
  static const streakOrange = Color(0xFFFF9600);
  static const pinBlue = Color(0xFF84D8FF);
  static const inactive = Color(0xFF4B4B4B);

  @override
  Widget build(BuildContext context) {
    final monthLabel = _monthYearLabel(month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final cellCount = firstWeekday + days.length;
    final rows = (cellCount / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPreviousMonth,
              icon: Icon(Icons.chevron_left, color: DashboardColors.textMuted),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                monthLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              icon: Icon(Icons.chevron_right, color: DashboardColors.textMuted),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: _weekLabels
              .map(
                (l) => Expanded(
                  child: Text(
                    l,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.textMuted,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        ...List.generate(rows, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (col) {
                final index = row * 7 + col - firstWeekday;
                if (index < 0 || index >= days.length) {
                  return const Expanded(child: SizedBox(height: 44));
                }
                final state = days[index];
                return Expanded(
                  child: _CalendarDayCell(
                    state: state,
                    onTap: () => onDaySelected(state.date),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  static String _monthYearLabel(DateTime m) {
    const names = [
      '',
      'THÁNG 1',
      'THÁNG 2',
      'THÁNG 3',
      'THÁNG 4',
      'THÁNG 5',
      'THÁNG 6',
      'THÁNG 7',
      'THÁNG 8',
      'THÁNG 9',
      'THÁNG 10',
      'THÁNG 11',
      'THÁNG 12',
    ];
    return '${names[m.month]} ${m.year}';
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({required this.state, required this.onTap});

  final FeedCalendarDayState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final day = state.date.day;
    final showPin = state.isSelected || state.isToday;
    final showOrangeDot = state.allComplete && !showPin;
    final inStreak = state.streakSegment != 'none';

    Color textColor = FeedScheduleCalendar.inactive;
    if (showPin) {
      textColor = const Color(0xFF1A2830);
    } else if (state.allComplete || state.partial) {
      textColor = FeedScheduleCalendar.streakOrange;
    } else if (state.hasSchedule) {
      textColor = DashboardColors.molting.withValues(alpha: 0.7);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (inStreak) _StreakBar(segment: state.streakSegment),
            if (showPin)
              _PinBubble(
                color: FeedScheduleCalendar.pinBlue,
                child: Text('$day'),
              )
            else if (showOrangeDot)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: FeedScheduleCalendar.streakOrange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1408),
                  ),
                ),
              )
            else
              Text(
                '$day',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            if (state.isMilestone && !showPin)
              const Positioned(
                left: 2,
                top: 10,
                child: Icon(
                  Icons.flag_rounded,
                  size: 12,
                  color: FeedScheduleCalendar.streakOrange,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StreakBar extends StatelessWidget {
  const _StreakBar({required this.segment});

  final String segment;

  @override
  Widget build(BuildContext context) {
    final (radius, left, right) = switch (segment) {
      'start' => (
          const BorderRadius.horizontal(left: Radius.circular(14)),
          6.0,
          0.0,
        ),
      'end' => (
          const BorderRadius.horizontal(right: Radius.circular(14)),
          0.0,
          6.0,
        ),
      'single' => (BorderRadius.circular(14), 8.0, 8.0),
      'middle' => (BorderRadius.zero, 0.0, 0.0),
      _ => (null, null, null),
    };
    if (radius == null) return const SizedBox.shrink();

    return Positioned(
      left: left,
      right: right,
      top: 14,
      bottom: 14,
      child: Container(
        decoration: BoxDecoration(
          color: FeedScheduleCalendar.streakBar,
          borderRadius: radius,
        ),
      ),
    );
  }
}

class _PinBubble extends StatelessWidget {
  const _PinBubble({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PinPainter(color: color),
      child: SizedBox(
        width: 34,
        height: 38,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: DefaultTextStyle(
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2830),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2 - 1;
    final cx = w / 2;
    final cy = h - 10;

    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy - 2), radius: r))
      ..moveTo(cx - 5, cy + r - 4)
      ..lineTo(cx, h - 1)
      ..lineTo(cx + 5, cy + r - 4)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.color != color;
}

/// Hai thẻ streak / mốc phía trên lịch.
class FeedScheduleStreakHeader extends StatelessWidget {
  const FeedScheduleStreakHeader({
    super.key,
    required this.streakDays,
    required this.nextMilestone,
  });

  final int streakDays;
  final int nextMilestone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: FeedScheduleCalendar.streakOrange,
            label: 'Chuỗi cho ăn',
            value: '$streakDays ngày',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.flag_rounded,
            iconColor: FeedScheduleCalendar.streakOrange,
            label: 'Mốc tiếp theo',
            value: '$nextMilestone ngày',
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131F24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    color: DashboardColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
