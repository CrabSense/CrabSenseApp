import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/feed_management.dart';
import '../../services/feed_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';
import 'feed_schedule_calendar.dart';

class FeedKpiStrip extends StatelessWidget {
  const FeedKpiStrip({super.key, required this.kpi});

  final FeedKpi kpi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cards = [
          _KpiCard(
            title: 'Tổng tồn kho',
            value: '${kpi.totalStockKg.round()} kg',
            subtitle: '+${kpi.stockTrendPercent.round()}% vs tháng trước',
            subtitleColor: DashboardColors.healthy,
          ),
          _KpiCard(
            title: 'Tiêu thụ hôm nay',
            value: '${kpi.consumedTodayKg.round()} kg',
            subtitle: 'TB tuần: ${kpi.weeklyAvgKg} kg',
          ),
          _KpiCard(
            title: 'FCR trung bình',
            value: kpi.avgFcr.toStringAsFixed(2),
            subtitle: 'Mục tiêu < ${kpi.fcrTarget}',
            badge: 'TỐT',
          ),
          _KpiCard(
            title: 'Lịch cho ăn',
            value: '${kpi.feedingsPerDay} lần / ngày',
            subtitle: 'Đã hoàn thành: ${kpi.feedingsCompleted}/${kpi.feedingsPerDay}',
          ),
        ];
        if (c.maxWidth < 800) {
          return Wrap(spacing: 10, runSpacing: 10, children: cards);
        }
        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.subtitleColor,
    this.badge,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color? subtitleColor;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.notoSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: DashboardColors.purple.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.purple,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.notoSans(
              color: subtitleColor ?? DashboardColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class FeedInventoryCard extends StatelessWidget {
  const FeedInventoryCard({
    super.key,
    required this.items,
    required this.onImport,
    required this.onExport,
  });

  final List<FeedInventoryItem> items;
  final VoidCallback onImport;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: DashboardColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Kho thức ăn',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const Spacer(),
              OutlinedButton(onPressed: onExport, child: const Text('Xuất kho')),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: DashboardColors.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: onImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Nhập kho'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: GoogleFonts.notoSans(fontSize: 12),
              columns: const [
                DataColumn(label: Text('Mã lô')),
                DataColumn(label: Text('Loại thức ăn')),
                DataColumn(label: Text('Tồn kho')),
                DataColumn(label: Text('Trạng thái')),
                DataColumn(label: Text('Hạn dùng')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.code)),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            item.typeLabel,
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text('${item.stockKg.round()} ${item.unit}')),
                    DataCell(_StatusDot(status: item.status)),
                    DataCell(Text(item.expiryDate)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final FeedStockStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(status.label, style: TextStyle(color: status.color, fontSize: 11)),
      ],
    );
  }
}

class FeedConsumptionCard extends StatelessWidget {
  const FeedConsumptionCard({super.key, required this.service});

  final FeedService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tiêu thụ & FCR',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _SegmentToggle(
            left: 'Theo lứa',
            right: 'Theo tuần',
            isLeft: service.fcrByBatch,
            onLeft: () => service.setFcrView(true),
            onRight: () => service.setFcrView(false),
          ),
          const SizedBox(height: 16),
          if (service.fcrByBatch) ...[
            ...service.batchConsumption.map(_FcrBar.new),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _miniStat('TB Tiêu thụ lứa 01', '12.5 kg/ngày')),
                const SizedBox(width: 10),
                Expanded(child: _miniStat('TB Tiêu thụ lứa 02', '15.8 kg/ngày')),
              ],
            ),
          ] else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 10,
                ),
                columns: const [
                  DataColumn(label: Text('Ngày')),
                  DataColumn(label: Text('Sáng')),
                  DataColumn(label: Text('Trưa')),
                  DataColumn(label: Text('Chiều')),
                  DataColumn(label: Text('Tổng')),
                  DataColumn(label: Text('Tỷ lệ ăn')),
                ],
                rows: service.dailyConsumption.map((d) {
                  return DataRow(
                    cells: [
                      DataCell(Text(d.date)),
                      DataCell(Text('${d.morningKg} kg')),
                      DataCell(Text('${d.noonKg} kg')),
                      DataCell(Text('${d.eveningKg} kg')),
                      DataCell(Text('${d.totalKg} kg')),
                      DataCell(Text('${d.eatRatePercent}%')),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(fontSize: 9, color: DashboardColors.textMuted)),
          Text(value, style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FcrBar extends StatelessWidget {
  const _FcrBar(this.data);

  final BatchFeedConsumption data;

  @override
  Widget build(BuildContext context) {
    final progress = (2.8 - data.fcr) / 1.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(data.batchId, style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 12)),
              const Spacer(),
              Text(
                'FCR: ${data.fcr.toStringAsFixed(2)}',
                style: GoogleFonts.notoSans(
                  color: data.rating == FcrRating.monitoring
                      ? DashboardColors.molting
                      : DashboardColors.healthy,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.1, 1.0),
              minHeight: 8,
              backgroundColor: DashboardColors.cardBorder,
              color: data.fcr < 1.9 ? DashboardColors.healthy : DashboardColors.molting,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  const _SegmentToggle({
    required this.left,
    required this.right,
    required this.isLeft,
    required this.onLeft,
    required this.onRight,
  });

  final String left;
  final String right;
  final bool isLeft;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: _seg(left, isLeft, onLeft)),
          Expanded(child: _seg(right, !isLeft, onRight)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? DashboardColors.purple.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class FeedAssistantCard extends StatelessWidget {
  const FeedAssistantCard({
    super.key,
    required this.insight,
    required this.recommendation,
  });

  final String insight;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AiAssistantHeader(
            title: 'Crab Assistant',
            subtitle: 'AI Khuyến nghị thời gian thực',
            avatarSize: 52,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashboardColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DashboardColors.purple.withValues(alpha: 0.25)),
            ),
            child: Text(
              insight,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            recommendation,
            style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: DashboardColors.accentGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text('Áp dụng ngay'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: () {}, child: const Text('Chi tiết')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FeedScheduleCard extends StatelessWidget {
  const FeedScheduleCard({
    super.key,
    required this.schedule,
    required this.service,
    required this.onCreateSchedule,
  });

  final List<FeedingScheduleItem> schedule;
  final FeedService service;
  final VoidCallback onCreateSchedule;

  @override
  Widget build(BuildContext context) {
    final selected = service.selectedDay;
    final dateLabel =
        '${selected.day.toString().padLeft(2, '0')}/'
        '${selected.month.toString().padLeft(2, '0')}';
    final calendarDays = service.calendarDaysForFocusedMonth();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch cho ăn',
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onCreateSchedule,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tạo lịch', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FeedScheduleStreakHeader(
            streakDays: service.feedingStreak,
            nextMilestone: service.nextMilestone,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131F24),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: FeedScheduleCalendar(
              month: service.focusedMonth,
              days: calendarDays,
              onPreviousMonth: service.previousMonth,
              onNextMonth: service.nextMonth,
              onDaySelected: service.selectDay,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chi tiết — $dateLabel',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: DashboardColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (schedule.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có lịch cho ngày này. Nhấn «Tạo lịch» để thêm.',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: DashboardColors.textMuted,
                ),
              ),
            )
          else
            ...schedule.map(
              (item) => _ScheduleTile(
                item: item,
                service: service,
                onEditSchedule: onCreateSchedule,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.item,
    required this.service,
    required this.onEditSchedule,
  });

  final FeedingScheduleItem item;
  final FeedService service;
  final VoidCallback onEditSchedule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.completed
                      ? DashboardColors.healthy
                      : DashboardColors.molting,
                  shape: BoxShape.circle,
                  border: Border.all(color: DashboardColors.cardBorder, width: 2),
                ),
              ),
              Container(width: 2, height: 48, color: DashboardColors.cardBorder),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.time,
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.completed)
                      Icon(Icons.check_circle, color: DashboardColors.healthy, size: 16)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DashboardColors.molting.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SẮP ĐẾN',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.molting,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '${item.area} — ${item.batchId}',
                  style: GoogleFonts.notoSans(fontSize: 11, color: DashboardColors.textMuted),
                ),
                Text(
                  '${item.feedName} (${item.portionKg.round()}kg)',
                  style: GoogleFonts.notoSans(fontSize: 12),
                ),
                if (item.completed && item.completedAt != null)
                  Text(
                    'Hoàn thành lúc ${item.completedAt}',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.healthy,
                      fontSize: 10,
                    ),
                  ),
                if (!item.completed) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () async => service.feedNow(item.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: DashboardColors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Cho ăn ngay', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: onEditSchedule,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Chỉnh lịch', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
