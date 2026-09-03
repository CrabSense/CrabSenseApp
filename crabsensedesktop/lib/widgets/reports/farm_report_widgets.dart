import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_farm_report_data.dart';
import '../../models/farm_report.dart';
import '../../services/farm_report_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';

class ReportToolbar extends StatelessWidget {
  const ReportToolbar({
    super.key,
    required this.service,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  final FarmReportService service;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;

  static const _batches = ['Tất cả', 'CFM-2026-001', 'CFM-2026-002', 'CFM-2026-003'];
  static const _areas = ['Tất cả', 'Khu A', 'Khu B', 'Khu C'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _timeChip('Hôm nay', ReportTimeRange.today),
              _timeChip('7 ngày', ReportTimeRange.week7),
              _timeChip('30 ngày', ReportTimeRange.days30),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: const Text('Tùy chọn', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              _dropdown(
                value: service.batchFilter,
                items: _batches,
                onChanged: service.setBatchFilter,
              ),
              _dropdown(
                value: service.areaFilter,
                items: _areas,
                onChanged: service.setAreaFilter,
              ),
              _typeDropdown(),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: DashboardColors.cardBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Xuất PDF'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onExportExcel,
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: const Text('Xuất Excel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeChip(String label, ReportTimeRange range) {
    final active = service.timeRange == range;
    return FilterChip(
      label: Text(label, style: GoogleFonts.notoSans(fontSize: 12)),
      selected: active,
      onSelected: (_) => service.setTimeRange(range),
      selectedColor: DashboardColors.purple.withValues(alpha: 0.35),
      checkmarkColor: DashboardColors.cyan,
      side: BorderSide(
        color: active ? DashboardColors.purple : DashboardColors.cardBorder,
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _typeDropdown() {
    final types = ReportType.values;
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<ReportType>(
        initialValue: service.reportType,
        decoration: const InputDecoration(isDense: true),
        items: types
            .map(
              (t) => DropdownMenuItem(
                value: t,
                child: Text(
                  switch (t) {
                    ReportType.overview => 'Báo cáo Tổng quan',
                    ReportType.health => 'Sức khỏe',
                    ReportType.environment => 'Môi trường',
                    ReportType.finance => 'Tài chính',
                    ReportType.devices => 'Thiết bị',
                  },
                  style: GoogleFonts.notoSans(fontSize: 12),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) service.setReportType(v);
        },
      ),
    );
  }
}

class ReportKpiGrid extends StatelessWidget {
  const ReportKpiGrid({super.key, required this.kpi});

  final FarmReportKpi kpi;

  @override
  Widget build(BuildContext context) {
    final row1 = [
      _Kpi(
        title: 'Tỷ lệ sống',
        value: '${kpi.survivalRatePercent}%',
        subtitle: '+${kpi.survivalTrendPercent}% tuần này',
        subtitleColor: DashboardColors.healthy,
      ),
      _Kpi(
        title: 'Tăng trưởng TB',
        value: '+${kpi.avgGrowthPerWeekG.round()}g/t',
        subtitle: 'Ổn định theo kế hoạch',
      ),
      _KpiHealth(score: kpi.avgHealthScore),
      _Kpi(
        title: 'Hiệu suất vận hành',
        value: '${kpi.opsEfficiencyPercent.round()}%',
        subtitle: 'Thiết bị hoạt động tốt',
      ),
    ];
    final row2 = [
      _Kpi(
        title: 'Tổng Doanh thu',
        value: '${MockFarmReportData.formatVndShort(kpi.totalRevenueVnd)} VND',
        subtitle: 'Dự kiến +${kpi.revenueForecastPercent}% vs Q1',
      ),
      _Kpi(
        title: 'Tổng Chi phí',
        value: '${MockFarmReportData.formatVndShort(kpi.totalCostVnd)} VND',
        subtitle: 'Thức ăn chiếm ${kpi.feedCostSharePercent.round()}%',
      ),
      _Kpi(
        title: 'Lợi nhuận ròng',
        value: MockFarmReportData.formatVndFull(kpi.netProfitVnd),
        subtitle: 'ROI hiện tại ${kpi.roiPercent}%',
        highlight: true,
      ),
    ];

    return Column(
      children: [
        _row(row1),
        const SizedBox(height: 10),
        _row(row2),
      ],
    );
  }

  Widget _row(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 800) {
          return Wrap(spacing: 10, runSpacing: 10, children: cards);
        }
        return Row(
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
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

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.title,
    required this.value,
    required this.subtitle,
    this.subtitleColor,
    this.highlight = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color? subtitleColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      highlight: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold),
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

class _KpiHealth extends StatelessWidget {
  const _KpiHealth({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Score',
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            '${score.round()}/100',
            style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: DashboardColors.cardBorder,
              color: DashboardColors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class SurvivalGrowthBarChartCard extends StatelessWidget {
  const SurvivalGrowthBarChartCard({super.key, required this.periods});

  final List<SurvivalGrowthPeriod> periods;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tỷ lệ sống & Tăng trưởng',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: DashboardColors.cardBorder, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= periods.length) return const SizedBox.shrink();
                        return Text(
                          periods[i].label,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < periods.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: periods[i].survivalPercent,
                          color: DashboardColors.purple,
                          width: 14,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: periods[i].growthG * 4,
                          color: DashboardColors.cyan,
                          width: 14,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                      barsSpace: 4,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legend(DashboardColors.purple, 'Tỷ lệ sống %'),
              const SizedBox(width: 16),
              _legend(DashboardColors.cyan, 'Tăng trưởng (×4g)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String l) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(l, style: GoogleFonts.notoSans(fontSize: 10, color: DashboardColors.textMuted)),
      ],
    );
  }
}

class ReportCostPieCard extends StatelessWidget {
  const ReportCostPieCard({
    super.key,
    required this.segments,
    required this.totalLabel,
  });

  final List<CostAllocationSegment> segments;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Phân bổ chi phí',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 188,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxH = constraints.maxHeight;
                final maxW = constraints.maxWidth;
                final chartSide = (maxH < maxW * 0.55 ? maxH : maxW * 0.48)
                    .clamp(96.0, 140.0);
                final pieRadius = chartSide * 0.30;
                final centerRadius = chartSide * 0.36;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: chartSide,
                      height: chartSide,
                      child: ClipRect(
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
                                    totalLabel,
                                    style: GoogleFonts.notoSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Tổng chi phí',
                                  style: GoogleFonts.notoSans(
                                    color: DashboardColors.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                      '${s.label} ${s.percent.round()}%',
                                      style: GoogleFonts.notoSans(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
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

class ReportResourcesCard extends StatelessWidget {
  const ReportResourcesCard({super.key, required this.items});

  final List<ResourceUsageItem> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tiêu thụ Tài nguyên',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(text: item.value),
                              TextSpan(
                                text: ' ${item.unit}',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: DashboardColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.trendLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (item.alert ? DashboardColors.molting : DashboardColors.healthy)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.trendLabel!,
                        style: GoogleFonts.notoSans(
                          color: item.alert ? DashboardColors.molting : DashboardColors.healthy,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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

class ReportDailyTableCard extends StatelessWidget {
  const ReportDailyTableCard({super.key, required this.rows});

  final List<DailyReportRow> rows;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chi tiết: Dữ liệu Theo Ngày',
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'LỌC NHANH',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _head(),
          const SizedBox(height: 8),
          ...rows.map(_dataRow),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Xem thêm báo cáo đầy đủ',
                style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _head() {
    const cols = [
      'NGÀY',
      'LỨA',
      'TỶ LỆ SỐNG',
      'TĂNG TRƯỞNG',
      'HEALTH',
      'CHI PHÍ',
    ];
    return Row(
      children: cols
          .map(
            (c) => Expanded(
              child: Text(
                c,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _dataRow(DailyReportRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(r.date, style: GoogleFonts.notoSans(fontSize: 11))),
          Expanded(child: Text(r.batchId, style: GoogleFonts.notoSans(fontSize: 11))),
          Expanded(child: Text('${r.survivalPercent}%', style: GoogleFonts.notoSans(fontSize: 11))),
          Expanded(
            child: Text(
              '+${r.growthG.round()}g',
              style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 11),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: r.healthScore >= 85
                        ? DashboardColors.healthy
                        : DashboardColors.monitoring,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('${r.healthScore}', style: GoogleFonts.notoSans(fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            child: Text(
              MockFarmReportData.formatVndFull(r.costVnd),
              style: GoogleFonts.notoSans(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportAiPanel extends StatelessWidget {
  const ReportAiPanel({
    super.key,
    required this.summary,
    required this.analysis,
    required this.actions,
    required this.onChat,
  });

  final String summary;
  final List<String> analysis;
  final List<ReportAiAction> actions;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AiAssistantHeader(
            title: 'Crab Assistant',
            subtitle: 'AI ASSISTANT',
            avatarSize: 48,
            compact: true,
          ),
          const SizedBox(height: 12),
          Text(
            'Tóm tắt 30 ngày',
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(summary, style: GoogleFonts.notoSans(fontSize: 10, height: 1.4)),
          const SizedBox(height: 10),
          Text(
            'Phân tích chuyên sâu',
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...analysis.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 10),
                  ),
                  Expanded(
                    child: Text(a, style: GoogleFonts.notoSans(fontSize: 10, height: 1.35)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kiến nghị hành động',
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(a.icon, size: 14, color: DashboardColors.molting),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(a.text, style: GoogleFonts.notoSans(fontSize: 10, height: 1.3)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DashboardColors.cyan, DashboardColors.blue],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: onChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Chat với Trợ lý AI',
                style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
