import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_harvest_sales_data.dart';
import '../../models/harvest_sales.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';

class HarvestKpiStrip extends StatelessWidget {
  const HarvestKpiStrip({super.key, required this.kpi});

  final HarvestSalesKpi kpi;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Kpi(
        title: 'Doanh thu tháng',
        value: MockHarvestSalesData.formatVndShort(kpi.monthlyRevenueVnd),
        trend: '+${kpi.revenueTrendPercent.round()}%',
        trendUp: true,
      ),
      _Kpi(
        title: 'Lợi nhuận',
        value: MockHarvestSalesData.formatVndShort(kpi.monthlyProfitVnd),
        trend: '+${kpi.profitTrendPercent.round()}%',
        trendUp: true,
      ),
      _Kpi(
        title: 'Đơn hàng',
        value: '${kpi.orderCount}',
        subtitle: 'Trong tháng',
      ),
      _Kpi(
        title: 'Cua đạt chuẩn',
        value: _fmtCount(kpi.qualifiedCrabCount),
        subtitle: 'con',
      ),
      _Kpi(
        title: 'Sản lượng',
        value: '${kpi.yieldKg.round()}kg',
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) {
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

  static String _fmtCount(int n) {
    final s = n.toString();
    if (n < 1000) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.title,
    required this.value,
    this.trend,
    this.trendUp = false,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? trend;
  final bool trendUp;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (trend != null) ...[
                const SizedBox(width: 8),
                Icon(
                  trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: DashboardColors.healthy,
                ),
                Text(
                  trend!,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.healthy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class HarvestRevenueChartCard extends StatelessWidget {
  const HarvestRevenueChartCard({super.key, required this.points});

  final List<MonthlyFinancePoint> points;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Doanh thu & Lợi nhuận theo tháng',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legend(DashboardColors.purple, 'Doanh thu'),
              const SizedBox(width: 16),
              _legend(DashboardColors.cyan, 'Lợi nhuận'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: DashboardColors.cardBorder,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}M',
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
                        if (i < 0 || i >= points.length) return const SizedBox.shrink();
                        return Text(
                          points[i].month,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 85,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].revenueM),
                    ],
                    isCurved: true,
                    color: DashboardColors.purple,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: DashboardColors.purple.withValues(alpha: 0.12),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].profitM),
                    ],
                    isCurved: true,
                    color: DashboardColors.cyan,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: DashboardColors.cyan.withValues(alpha: 0.08),
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

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.notoSans(fontSize: 10, color: DashboardColors.textMuted)),
      ],
    );
  }
}

class HarvestSizePieCard extends StatelessWidget {
  const HarvestSizePieCard({super.key, required this.segments, required this.totalCount});

  final List<CrabSizeSegment> segments;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Phân loại kích cỡ cua',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 52,
                      sections: segments
                          .map(
                            (s) => PieChartSectionData(
                              value: s.percent,
                              color: s.color,
                              radius: 40,
                              showTitle: false,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(totalCount / 1000).toStringAsFixed(1)}k',
                        style: GoogleFonts.notoSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tổng con',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...segments.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${s.size.label} ${s.percent.round()}%',
                                style: GoogleFonts.notoSans(fontSize: 10, color: DashboardColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class QualifiedCrabsTableCard extends StatelessWidget {
  const QualifiedCrabsTableCard({
    super.key,
    required this.crabs,
    this.onViewAll,
  });

  final List<QualifiedCrab> crabs;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final rows = crabs.take(5).toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tableHeader('Danh sách cua đạt chuẩn', onViewAll),
          const SizedBox(height: 12),
          _headRow(['MÃ CUA', 'TRỌNG LƯỢNG', 'KÍCH CỠ', 'HEALTH']),
          const SizedBox(height: 8),
          ...rows.map(_crabRow),
        ],
      ),
    );
  }

  Widget _crabRow(QualifiedCrab c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(c.code, style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text('${c.weightG}g', style: GoogleFonts.notoSans(fontSize: 12))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: DashboardColors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                c.size.label,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${c.healthScore}',
              style: GoogleFonts.notoSans(color: DashboardColors.healthy, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentOrdersTableCard extends StatelessWidget {
  const RecentOrdersTableCard({
    super.key,
    required this.orders,
    required this.onOrderTap,
    this.onFilter,
  });

  final List<SalesOrder> orders;
  final ValueChanged<SalesOrder> onOrderTap;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    final rows = orders.take(5).toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tableHeader('Đơn bán hàng gần đây', onFilter, linkLabel: 'Bộ lọc'),
          const SizedBox(height: 12),
          _headRow(['MÃ ĐƠN', 'KHÁCH HÀNG', 'TỔNG TIỀN', 'TT']),
          const SizedBox(height: 8),
          ...rows.map((o) => _orderRow(context, o)),
        ],
      ),
    );
  }

  Widget _orderRow(BuildContext context, SalesOrder o) {
    return InkWell(
      onTap: () => onOrderTap(o),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '#${o.code}',
                style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                o.customerName,
                style: GoogleFonts.notoSans(fontSize: 11, color: DashboardColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                MockHarvestSalesData.formatVndShort(o.revenueVnd),
                style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: o.status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  o.status.label,
                  style: GoogleFonts.notoSans(color: o.status.color, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HarvestBatchProfitCard extends StatelessWidget {
  const HarvestBatchProfitCard({super.key, required this.points});

  final List<BatchProfitPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxP = points.map((p) => p.profitM).reduce((a, b) => a > b ? a : b);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lợi nhuận theo lứa',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.batchId,
                        style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${p.profitM}M',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.profitM / maxP,
                      minHeight: 6,
                      backgroundColor: DashboardColors.cardBorder,
                      color: DashboardColors.purple,
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

class HarvestAssistantPanel extends StatelessWidget {
  const HarvestAssistantPanel({
    super.key,
    required this.insight,
    required this.recommendation,
    required this.market,
    required this.onCreateHarvest,
  });

  final String insight;
  final String recommendation;
  final MarketInfo market;
  final VoidCallback onCreateHarvest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AiAssistantHeader(
                title: 'Crab Assistant — AI Insight',
                avatarSize: 48,
                compact: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DashboardColors.darkNavy.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: Text(
                  insight,
                  style: GoogleFonts.notoSans(fontSize: 12, height: 1.45),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Khuyến nghị:',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recommendation,
                style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.cyan),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DashboardColors.cyan, DashboardColors.blue],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton.icon(
                  onPressed: onCreateHarvest,
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Tạo phiếu thu hoạch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Thông tin thị trường',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _marketTile(
                market.priceLabel,
                '${MockHarvestSalesData.formatVndFull(market.pricePerKg)}/kg',
                '+${market.priceTrendPercent.round()}%',
              ),
              const SizedBox(height: 10),
              _marketTile(
                'Tồn kho đông lạnh',
                '${market.frozenStockKg} kg',
                null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _marketTile(String title, String value, String? trend) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (trend != null)
            Text(
              trend,
              style: GoogleFonts.notoSans(color: DashboardColors.healthy, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

Widget _tableHeader(String title, VoidCallback? onAction, {String linkLabel = 'Xem tất cả'}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      if (onAction != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            linkLabel,
            style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 11),
          ),
        ),
    ],
  );
}

Widget _headRow(List<String> cols) {
  return Row(
    children: cols
        .map(
          (c) => Expanded(
            flex: c == 'MÃ CUA' || c == 'MÃ ĐƠN' ? 2 : 1,
            child: Text(
              c,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        )
        .toList(),
  );
}
