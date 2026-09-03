import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_batch_feed_data.dart';
import '../../models/batch_feed_history.dart';
import '../../models/farming_batch_group.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

class FarmingBatchFeedHistoryTab extends StatelessWidget {
  const FarmingBatchFeedHistoryTab({super.key, required this.group});

  final FarmingBatchGroup group;

  @override
  Widget build(BuildContext context) {
    final summary = MockBatchFeedData.summaryFor(group);
    final logs = MockBatchFeedData.logsFor(group);
    final ai = MockBatchFeedData.aiInsightFor(group);
    final fcr = MockBatchFeedData.fcrLast7Days();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(group: group),
          const SizedBox(height: 16),
          _KpiRow(summary: summary),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 900;
              final log = _FeedLogCard(logs: logs);
              final side = Column(
                children: [
                  _AiAssistantCard(insight: ai),
                  const SizedBox(height: 12),
                  _FcrTrendCard(values: fcr),
                ],
              );
              if (!wide) {
                return Column(
                  children: [log, const SizedBox(height: 12), side],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: log),
                    const SizedBox(width: 16),
                    SizedBox(width: 300, child: side),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.group});

  final FarmingBatchGroup group;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Text(
        'Batch#${group.batchCode}',
        style: GoogleFonts.notoSans(
          color: DashboardColors.textMuted,
          fontSize: 12,
        ),
      ),
    );
    final actions = Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('Cài đặt máy cho ăn tự động'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DashboardColors.textMuted,
            side: BorderSide(color: DashboardColors.cardBorder),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ghi nhận cho ăn — đang phát triển'),
              ),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ghi nhận cho ăn'),
          style: FilledButton.styleFrom(
            backgroundColor: DashboardColors.oceanBlue,
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Lịch sử cho ăn',
                    style: GoogleFonts.notoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  badge,
                ],
              ),
              const SizedBox(height: 10),
              actions,
            ],
          );
        }
        return Row(
          children: [
            Text(
              'Lịch sử cho ăn',
              style: GoogleFonts.notoSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DashboardColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            badge,
            const Spacer(),
            actions,
          ],
        );
      },
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.summary});

  final BatchFeedHistorySummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cards = [
          _KpiCard(
            title: 'Tổng lượng thức ăn',
            value: '${summary.totalFeedKg.toStringAsFixed(1)} kg',
            badge: '+${summary.totalTrendPercent.toInt()}%',
            badgeColor: DashboardColors.seaGreen,
          ),
          _KpiCard(
            title: 'Tiêu thụ hôm nay',
            value: '${summary.todayKg.toStringAsFixed(1)} kg',
          ),
          _KpiCard(
            title: 'FCR trung bình',
            value: summary.avgFcr.toStringAsFixed(2),
            badge: 'Tốt',
            badgeColor: DashboardColors.seaGreen,
          ),
          _KpiCard(
            title: 'Lần cho ăn tiếp theo',
            value: summary.nextFeedingTime,
            subtitle: summary.nextFeedingSubtitle,
          ),
        ];
        if (c.maxWidth < 800) {
          return Wrap(spacing: 12, runSpacing: 12, children: cards);
        }
        return Row(
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: card,
                  ),
                ),
              )
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
    this.subtitle,
    this.badge,
    this.badgeColor,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.notoSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? DashboardColors.purple)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.notoSans(
                      color: badgeColor ?? DashboardColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedLogCard extends StatelessWidget {
  const _FeedLogCard({required this.logs});

  final List<BatchFeedingLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Nhật ký chi tiết',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.filter_list, color: DashboardColors.textMuted),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.download_outlined, color: DashboardColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columnSpacing: 28,
              columns: [
                DataColumn(label: Text('THỜI GIAN', style: _h())),
                DataColumn(label: Text('LOẠI THỨC ĂN', style: _h())),
                DataColumn(label: Text('KHỐI LƯỢNG', style: _h()), numeric: true),
                DataColumn(label: Text('PHƯƠNG THỨC', style: _h())),
                DataColumn(label: Text('TRẠNG THÁI', style: _h())),
              ],
              rows: logs.map(_row).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Xem tất cả lịch sử',
                style: GoogleFonts.notoSans(color: DashboardColors.oceanBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _row(BatchFeedingLogEntry e) {
    final time = _fmtTime(e.at);
    final date = '${e.at.day.toString().padLeft(2, '0')}/'
        '${e.at.month.toString().padLeft(2, '0')}';
    final day = e.dayLabel ?? '';
    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                time,
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                [if (day.isNotEmpty) day, date].join(', '),
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(e.feedType, style: GoogleFonts.notoSans(fontSize: 12))),
        DataCell(Text('${e.weightKg.toStringAsFixed(1)} kg')),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(e.method.icon, size: 16, color: DashboardColors.textMuted),
            const SizedBox(width: 6),
            Text(e.method.label),
          ],
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(e.status.icon, size: 16, color: e.status.color),
            const SizedBox(width: 6),
            Text(
              e.status.label,
              style: TextStyle(color: e.status.color, fontSize: 12),
            ),
          ],
        )),
      ],
    );
  }

  String _fmtTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  TextStyle _h() => GoogleFonts.notoSans(
        color: DashboardColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      );
}

class _AiAssistantCard extends StatelessWidget {
  const _AiAssistantCard({required this.insight});

  final BatchFeedAiInsight insight;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DashboardColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.smart_toy_outlined, color: DashboardColors.purple),
              ),
              const SizedBox(width: 10),
              Text(
                'Crab Assistant',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DashboardColors.seaGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AI MONITORING',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.seaGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.message,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LIVE METRICS',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _metricBar('Chỉ số Oxy (DO)', '${insight.doMgL}mg/L', insight.doMgL / 8, DashboardColors.cyan),
          const SizedBox(height: 8),
          _metricBar('Nhiệt độ', '${insight.temperatureC}°C', insight.temperatureC / 35, DashboardColors.oceanBlue),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Áp dụng khuyến nghị AI'),
          ),
        ],
      ),
    );
  }

  Widget _metricBar(String label, String value, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.notoSans(fontSize: 11)),
            const Spacer(),
            Text(value, style: GoogleFonts.notoSans(fontSize: 11, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0, 1),
            minHeight: 6,
            backgroundColor: DashboardColors.cardBorder,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _FcrTrendCard extends StatelessWidget {
  const _FcrTrendCard({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xu hướng FCR',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Biểu đồ 7 ngày gần nhất',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: values.reduce((a, b) => a > b ? a : b) + 0.1,
                minY: values.reduce((a, b) => a < b ? a : b) - 0.1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: DashboardColors.cardBorder.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        'T${v.toInt() + 1}',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ),
                barGroups: List.generate(
                  values.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: DashboardColors.purple.withValues(alpha: 0.85),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
