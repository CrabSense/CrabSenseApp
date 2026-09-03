import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/batch_status.dart';
import '../../models/farming_batch_group.dart';
import '../../models/production_models.dart';
import '../../services/batch_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import 'farming_batch_feed_history_tab.dart';

class FarmingBatchDetailTitleRow extends StatelessWidget {
  const FarmingBatchDetailTitleRow({
    super.key,
    required this.group,
    required this.onBack,
    required this.onEdit,
  });

  final FarmingBatchGroup group;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          color: DashboardColors.textMuted,
        ),
        Expanded(
          child: Text(
            'Chi tiết Đợt Nuôi: ${group.batchCode}',
            style: GoogleFonts.notoSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DashboardColors.textPrimary,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Chỉnh sửa'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DashboardColors.textMuted,
            side: BorderSide(color: DashboardColors.cardBorder),
          ),
        ),
      ],
    );
  }
}

class FarmingBatchSummaryRow extends StatelessWidget {
  const FarmingBatchSummaryRow({
    super.key,
    required this.group,
    required this.moltingCount,
    required this.alertCount,
  });

  final FarmingBatchGroup group;
  final int moltingCount;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 1100;
        final cards = [
          _InfoSummaryCard(group: group),
          _SurvivalKpiCard(group: group),
          _QuantityKpiCard(group: group),
          _MoltingKpiCard(count: moltingCount),
          _AlertKpiCard(count: alertCount),
        ];
        if (!wide) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((w) => SizedBox(width: c.maxWidth, child: w))
                .toList(),
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
              const SizedBox(width: 12),
              Expanded(child: cards[4]),
            ],
          ),
        );
      },
    );
  }
}

class _InfoSummaryCard extends StatelessWidget {
  const _InfoSummaryCard({required this.group});

  final FarmingBatchGroup group;

  @override
  Widget build(BuildContext context) {
    final b = group.primary.batch;
    final statusColor = FarmingBatchStatusUi.color(group.status);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MÃ ĐỢT NUÔI',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  FarmingBatchStatusUi.label(group.status).toUpperCase(),
                  style: GoogleFonts.notoSans(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            group.batchCode,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _meta(Icons.landscape_outlined, 'Khu', group.areaCode),
          _meta(Icons.view_week_outlined, 'Số hộp', '${group.boxCount} hộp'),
          _meta(Icons.inventory_2_outlined, 'Hộp', group.boxSummary),
          _meta(Icons.calendar_today_outlined, 'Ngày bắt đầu', _fmt(b.startDate)),
          _meta(
            Icons.event_outlined,
            'Dự kiến thu hoạch',
            b.expectedHarvestDate != null
                ? _fmt(b.expectedHarvestDate!)
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: DashboardColors.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 12,
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

class _SurvivalKpiCard extends StatelessWidget {
  const _SurvivalKpiCard({required this.group});

  final FarmingBatchGroup group;

  @override
  Widget build(BuildContext context) {
    final rate = group.survivalPercent;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TỶ LỆ SỐNG',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: DashboardColors.seaGreen),
              const SizedBox(width: 4),
              Text(
                '+1.2%',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.seaGreen,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: LineChart(
              LineChartData(
                minY: rate - 5,
                maxY: 100,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 98),
                      const FlSpot(1, 97),
                      const FlSpot(2, 96),
                      FlSpot(3, rate),
                    ],
                    isCurved: true,
                    color: DashboardColors.cyan,
                    barWidth: 2,
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

class _QuantityKpiCard extends StatelessWidget {
  const _QuantityKpiCard({required this.group});

  final FarmingBatchGroup group;

  @override
  Widget build(BuildContext context) {
    final dead = (group.totalInitial - group.totalCurrent)
        .clamp(0, group.totalInitial);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SL HIỆN TẠI',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${group.totalCurrent} / ${group.totalInitial}',
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Số cua chết: $dead',
            style: GoogleFonts.notoSans(
              color: DashboardColors.risk,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoltingKpiCard extends StatelessWidget {
  const _MoltingKpiCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ĐANG LỘT XÁC',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$count',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.purple,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.cyclone, color: DashboardColors.purple.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cần theo dõi sát',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertKpiCard extends StatelessWidget {
  const _AlertKpiCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DashboardColors.risk.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CẢNH BÁO AI',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  count.toString().padLeft(2, '0'),
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.risk,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.warning_amber_rounded, color: DashboardColors.risk),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'High priority',
              style: GoogleFonts.notoSans(
                color: DashboardColors.risk,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FarmingBatchGrowthSurvivalChart extends StatelessWidget {
  const FarmingBatchGrowthSurvivalChart({
    super.key,
    required this.group,
    required this.days,
    required this.onDaysChanged,
  });

  final FarmingBatchGroup group;
  final int days;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    final rate = group.survivalPercent;
    final growth = List.generate(6, (i) => 20.0 + i * 35);
    final survival = [100.0, 99.0, 97.5, 96.0, 95.0, rate];
    final labels = ['T5', 'T6', 'T7', 'T8', 'T9', 'Hôm nay'];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tăng trưởng & Tỷ lệ sống',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _PeriodChip(
                label: '7 Ngày',
                selected: days == 7,
                onTap: () => onDaysChanged(7),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: '30 Ngày',
                selected: days == 30,
                onTap: () => onDaysChanged(30),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legend(DashboardColors.purple, 'Tăng trưởng'),
              const SizedBox(width: 16),
              _legend(DashboardColors.cyan, 'Tỷ lệ sống'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    maxY: growth.last * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: DashboardColors.cardBorder.withValues(alpha: 0.4),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}',
                            style: _axis(),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= labels.length) {
                              return const SizedBox();
                            }
                            return Text(labels[i], style: _axis());
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                    ),
                    barGroups: List.generate(
                      growth.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: growth[i],
                            color: DashboardColors.purple.withValues(alpha: 0.7),
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          survival.length,
                          (i) => FlSpot(i.toDouble(), survival[i]),
                        ),
                        isCurved: true,
                        color: DashboardColors.cyan,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: true),
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

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: c),
        const SizedBox(width: 6),
        Text(label, style: _axis()),
      ],
    );
  }

  TextStyle _axis() => GoogleFonts.notoSans(
        color: DashboardColors.textMuted,
        fontSize: 10,
      );
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DashboardColors.purple.withValues(alpha: 0.25)
          : DashboardColors.darkNavy,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.notoSans(
              color: selected
                  ? DashboardColors.textPrimary
                  : DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class FarmingBatchFeedGaugeCard extends StatelessWidget {
  const FarmingBatchFeedGaugeCard({
    super.key,
    required this.currentKg,
    required this.targetKg,
  });

  final double currentKg;
  final double targetKg;

  @override
  Widget build(BuildContext context) {
    final pct = targetKg <= 0 ? 0.0 : (currentKg / targetKg).clamp(0.0, 1.0);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 300,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tổng lượng thức ăn',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 10,
                    backgroundColor: DashboardColors.cardBorder,
                    valueColor: const AlwaysStoppedAnimation(
                      DashboardColors.oceanBlue,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currentKg.toStringAsFixed(1)} KG',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/ ${targetKg.toStringAsFixed(0)}KG',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Lịch sử'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Cho ăn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.oceanBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

class FarmingBatchDetailTabs extends StatelessWidget {
  const FarmingBatchDetailTabs({
    super.key,
    required this.controller,
    required this.group,
    required this.crabSearch,
    required this.onCrabSearchChanged,
    required this.loadingCrabs,
    required this.crabError,
    required this.crabs,
    required this.totalCrabs,
    required this.onRetryCrabs,
  });

  final TabController controller;
  final FarmingBatchGroup group;
  final TextEditingController crabSearch;
  final VoidCallback onCrabSearchChanged;
  final bool loadingCrabs;
  final String? crabError;
  final List<BatchCrabWithBox> crabs;
  final int totalCrabs;
  final VoidCallback onRetryCrabs;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: controller,
            isScrollable: true,
            labelColor: DashboardColors.cyan,
            unselectedLabelColor: DashboardColors.textMuted,
            indicatorColor: DashboardColors.seaGreen,
            tabs: const [
              Tab(text: 'Hộp & Cua'),
              Tab(text: 'Lịch sử cho ăn'),
              Tab(text: 'Chỉ số môi trường'),
              Tab(text: 'Lịch sử sức khỏe'),
              Tab(text: 'Cảnh báo'),
              Tab(text: 'Thu hoạch'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 520,
            child: TabBarView(
              controller: controller,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Danh sách hộp (${group.boxCount})',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 2,
                      child: FarmingBatchBoxTable(group: group),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Danh sách cua',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 280,
                          child: TextField(
                            controller: crabSearch,
                            onChanged: (_) => onCrabSearchChanged(),
                            decoration: InputDecoration(
                              hintText: 'Tìm theo ID hoặc Hộp...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              filled: true,
                              fillColor: DashboardColors.darkNavy,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 3,
                      child: loadingCrabs
                          ? const Center(child: CircularProgressIndicator())
                          : crabError != null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        crabError!,
                                        style: GoogleFonts.notoSans(
                                          color: DashboardColors.risk,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: onRetryCrabs,
                                        child: const Text('Thử lại'),
                                      ),
                                    ],
                                  ),
                                )
                              : FarmingBatchCrabTable(crabs: crabs),
                    ),
                  ],
                ),
                FarmingBatchFeedHistoryTab(group: group),
                const FarmingBatchTabPlaceholder(
                  title: 'Chỉ số môi trường',
                  icon: Icons.water_outlined,
                ),
                const FarmingBatchTabPlaceholder(
                  title: 'Lịch sử sức khỏe',
                  icon: Icons.favorite_outline,
                ),
                const FarmingBatchTabPlaceholder(
                  title: 'Cảnh báo',
                  icon: Icons.warning_amber_outlined,
                ),
                const FarmingBatchTabPlaceholder(
                  title: 'Thu hoạch',
                  icon: Icons.agriculture_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FarmingBatchBoxTable extends StatelessWidget {
  const FarmingBatchBoxTable({super.key, required this.group});

  final FarmingBatchGroup group;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columns: [
          DataColumn(label: Text('HỘP', style: _h())),
          DataColumn(label: Text('SL BĐ', style: _h()), numeric: true),
          DataColumn(label: Text('SL HT', style: _h()), numeric: true),
          DataColumn(label: Text('TỶ LỆ SỐNG', style: _h())),
          DataColumn(label: Text('TRẠNG THÁI', style: _h())),
        ],
        rows: group.members.map((m) {
          final pct = m.survivalPercent;
          final col = FarmingBatchStatusUi.color(m.batch.status);
          return DataRow(
            cells: [
              DataCell(Text(
                m.boxCode,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              )),
              DataCell(Text('${m.batch.initialQuantity}')),
              DataCell(Text('${m.batch.currentQuantity}')),
              DataCell(Text('${pct.round()}%')),
              DataCell(Text(
                FarmingBatchStatusUi.label(m.batch.status),
                style: TextStyle(color: col, fontSize: 12),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  TextStyle _h() => GoogleFonts.notoSans(
        color: DashboardColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      );
}

class FarmingBatchCrabTable extends StatelessWidget {
  const FarmingBatchCrabTable({super.key, required this.crabs});

  final List<BatchCrabWithBox> crabs;

  @override
  Widget build(BuildContext context) {
    if (crabs.isEmpty) {
      return Center(
        child: Text(
          'Chưa có cua trong đợt này.',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 64,
          columnSpacing: 24,
          columns: [
            DataColumn(label: Text('HỘP', style: _h())),
            DataColumn(label: Text('MÃ CUA', style: _h())),
            DataColumn(label: Text('LOẠI', style: _h())),
            DataColumn(label: Text('TRỌNG LƯỢNG', style: _h()), numeric: true),
            DataColumn(label: Text('SỨC KHỎE', style: _h())),
            DataColumn(label: Text('HÀNH ĐỘNG', style: _h())),
          ],
          rows: crabs.map((row) {
            final c = row.crab;
            final health = _healthUi(c.status);
            return DataRow(
              cells: [
                DataCell(Text(row.boxCode)),
                DataCell(Text(
                  c.crabCode,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                )),
                DataCell(Text(_crabType(row))),
                DataCell(Text(
                  c.weight != null ? '${c.weight!.toStringAsFixed(0)}g' : '—',
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: health.$1,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(health.$2),
                  ],
                )),
                DataCell(
                  TextButton(
                    onPressed: () {},
                    child: const Text('Chi tiết'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  (Color, String) _healthUi(String status) {
    final s = status.toLowerCase();
    if (s.contains('molt')) {
      return (DashboardColors.oceanBlue, 'Đang lột');
    }
    if (s.contains('warn') || s.contains('risk')) {
      return (DashboardColors.risk, 'Cảnh báo');
    }
    return (DashboardColors.seaGreen, 'Ổn định');
  }

  String _crabType(BatchCrabWithBox row) => _crabTypeFrom(row.crab);

  String _crabTypeFrom(BatchCrabRecord c) {
    if (c.gender.toLowerCase().contains('female')) return 'Cua gạch (cái)';
    if (c.gender.toLowerCase().contains('male')) return 'Cua gạch (đực)';
    return 'Cua gạch';
  }

  TextStyle _h() => GoogleFonts.notoSans(
        color: DashboardColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      );
}

class FarmingBatchTabPlaceholder extends StatelessWidget {
  const FarmingBatchTabPlaceholder({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: DashboardColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Dữ liệu IoT / nhật ký sẽ hiển thị tại đây.',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
