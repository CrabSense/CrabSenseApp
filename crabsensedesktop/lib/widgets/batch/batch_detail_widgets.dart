import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_batch_data.dart';
import '../../models/crab_batch.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

class BatchInfoCard extends StatelessWidget {
  const BatchInfoCard({super.key, required this.batch});

  final CrabBatch batch;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: DashboardColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Thông tin tổng quan',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow('Mã lứa', batch.id),
          _infoRow('Ngày thả', _fmt(batch.releaseDate)),
          _infoRow('Nguồn giống', batch.source),
          _infoRow('Số lượng ban đầu', '${batch.initialQuantity}'),
          _infoRow('Số lượng còn sống', '${batch.aliveCount}',
              valueColor: DashboardColors.cyan),
          _infoRow('Số lượng chết', '${batch.deadCount}',
              valueColor: DashboardColors.risk),
          _infoRow('Trọng lượng ban đầu', '${batch.initialWeightGram.toStringAsFixed(0)}g'),
          _infoRow('Trọng lượng TB hiện tại',
              '${batch.avgWeightGram.toStringAsFixed(0)}g'),
          const SizedBox(height: 20),
          Text(
            'Chu kỳ nuôi: ${(batch.cycleProgress * 100).toStringAsFixed(0)}% hoàn thành',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: batch.cycleProgress,
              minHeight: 8,
              backgroundColor: DashboardColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation(DashboardColors.purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.notoSans(
                color: valueColor ?? DashboardColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class BatchDetailKpiRow extends StatelessWidget {
  const BatchDetailKpiRow({super.key, required this.batch});

  final CrabBatch batch;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('TỶ LỆ SỐNG', '${batch.survivalRate.toStringAsFixed(0)}%', DashboardColors.cyan),
      ('HEALTHSCORE', '${batch.healthScore}', DashboardColors.purple),
      ('SẮP THU HOẠCH', '${batch.daysToHarvest} ngày', DashboardColors.textPrimary),
      ('DOANH THU', '${batch.revenueMillion.toStringAsFixed(0)} tr', DashboardColors.cyan),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 900 ? 4 : 2;
        final w = (c.maxWidth - 12 * (cols - 1)) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (e) => SizedBox(
                  width: w,
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.$1,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.$2,
                          style: GoogleFonts.notoSans(
                            color: e.$3,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class WeightGrowthChart extends StatelessWidget {
  const WeightGrowthChart({super.key, required this.batch});

  final CrabBatch batch;

  @override
  Widget build(BuildContext context) {
    final actual = MockBatchData.weightGrowthGrams(batch);
    final expected = MockBatchData.expectedWeightGrowth(batch);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biểu đồ Tăng trưởng (Weight Growth)',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legend(DashboardColors.blue, 'Thực tế'),
              const SizedBox(width: 16),
              _legend(DashboardColors.textMuted, 'Dự kiến', dashed: true),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: _grid(),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}g',
                        style: _axis(),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text('T${v.toInt() + 1}', style: _axis()),
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      actual.length,
                      (i) => FlSpot(i.toDouble(), actual[i]),
                    ),
                    isCurved: true,
                    color: DashboardColors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      expected.length,
                      (i) => FlSpot(i.toDouble(), expected[i]),
                    ),
                    isCurved: true,
                    color: DashboardColors.textMuted,
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SurvivalChart extends StatelessWidget {
  const SurvivalChart({super.key, required this.batch});

  final CrabBatch batch;

  @override
  Widget build(BuildContext context) {
    final data = MockBatchData.survivalHistory(batch);
    final labels = MockBatchData.survivalLabels(batch);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tỷ lệ sống theo thời gian',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '30 ngày qua',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: data.reduce((a, b) => a < b ? a : b) - 2,
                maxY: 100,
                gridData: _grid(),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) =>
                          Text('${v.toInt()}%', style: _axis()),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(labels[i], style: _axis());
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      data.length,
                      (i) => FlSpot(i.toDouble(), data[i]),
                    ),
                    isCurved: true,
                    color: DashboardColors.cyan,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DashboardColors.cyan.withValues(alpha: 0.3),
                          DashboardColors.cyan.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CrabDistributionChart extends StatelessWidget {
  const CrabDistributionChart({super.key, required this.batch});

  final CrabBatch batch;

  @override
  Widget build(BuildContext context) {
    final segments = MockBatchData.crabDistribution(batch);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bố tình trạng cua',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 168,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Cột hẹp (~300px): donut nhỏ để legend không bị xuống dòng từng chữ.
                final chartSide = [
                  constraints.maxHeight * 0.88,
                  constraints.maxWidth * 0.36,
                ].reduce((a, b) => a < b ? a : b).clamp(88.0, 112.0);
                final pieRadius = chartSide * 0.30;
                final centerRadius = chartSide * 0.40;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: chartSide,
                      height: chartSide,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: centerRadius,
                              sections: segments
                                  .map(
                                    (s) => PieChartSectionData(
                                      value: s.percent,
                                      color: s.color,
                                      radius: pieRadius,
                                      showTitle: false,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${batch.initialQuantity}',
                                  style: GoogleFonts.notoSans(
                                    color: DashboardColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              Text(
                                'TỔNG THỂ',
                                style: GoogleFonts.notoSans(
                                  color: DashboardColors.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final s in segments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: s.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.notoSans(
                                        color: DashboardColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${s.percent.round()}%',
                                    style: GoogleFonts.notoSans(
                                      color: DashboardColors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BatchTimelineWidget extends StatelessWidget {
  const BatchTimelineWidget({super.key, required this.batch});

  final CrabBatch batch;

  @override
  Widget build(BuildContext context) {
    final events = MockBatchData.timeline(batch);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline Lứa Nuôi',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...events.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final isLast = i == events.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: e.isFuture
                            ? DashboardColors.cardBorder
                            : DashboardColors.purple.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: e.isFuture
                              ? DashboardColors.textMuted
                              : DashboardColors.purple,
                        ),
                      ),
                      child: Icon(
                        e.icon,
                        size: 16,
                        color: e.isFuture
                            ? DashboardColors.textMuted
                            : DashboardColors.cyan,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: DashboardColors.cardBorder,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          e.subtitle,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${e.date.day}/${e.date.month}/${e.date.year}',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

Widget _legend(Color color, String label, {bool dashed = false}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 16,
        height: dashed ? 0 : 3,
        decoration: BoxDecoration(
          color: dashed ? null : color,
          border: dashed ? Border(bottom: BorderSide(color: color, width: 2)) : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10)),
    ],
  );
}

FlGridData _grid() => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => FlLine(
        color: DashboardColors.cardBorder.withValues(alpha: 0.5),
        strokeWidth: 1,
      ),
    );

TextStyle _axis() =>
    GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 9);
