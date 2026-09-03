import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_health_monitoring_data.dart';
import '../../models/health_monitoring.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';

class HealthKpiStrip extends StatelessWidget {
  const HealthKpiStrip({super.key, required this.profile});

  final HealthMonitoringProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = profile.components;
    final items = [
      _KpiItem.ring(
        label: 'Health Score',
        value: profile.healthScore,
        level: profile.level,
      ),
      _KpiItem.score(
        label: 'Activity Score',
        value: c.activity,
        sub: '+${profile.activityTrendPercent.toStringAsFixed(0)}%',
        icon: Icons.directions_run_outlined,
        color: DashboardColors.cyan,
      ),
      _KpiItem.score(
        label: 'Feeding Score',
        value: c.feeding,
        sub: '+${profile.feedingTrendPercent.toStringAsFixed(0)}%',
        icon: Icons.restaurant_outlined,
        color: DashboardColors.purple,
      ),
      _KpiItem.score(
        label: 'Growth Score',
        value: c.growth,
        sub: profile.growthTrendLabel,
        icon: Icons.show_chart_outlined,
        color: DashboardColors.blue,
      ),
      _KpiItem.score(
        label: 'Water Quality',
        value: c.waterQuality,
        sub: profile.waterQualityLabel,
        icon: Icons.water_drop_outlined,
        color: DashboardColors.healthy,
      ),
      _KpiItem.risk(
        label: 'Disease Risk',
        risk: profile.diseaseRisk,
        icon: Icons.shield_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 1200
            ? 6
            : constraints.maxWidth > 800
                ? 3
                : 2;
        final spacing = 12.0;
        final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((k) => SizedBox(width: w, child: _KpiCard(item: k))).toList(),
        );
      },
    );
  }
}

class _KpiItem {
  _KpiItem._({
    required this.label,
    this.value,
    this.sub,
    this.icon,
    this.color,
    this.level,
    this.risk,
    this.isRing = false,
  });

  factory _KpiItem.ring({
    required String label,
    required double value,
    required HealthLevel level,
  }) =>
      _KpiItem._(label: label, value: value, level: level, isRing: true);

  factory _KpiItem.score({
    required String label,
    required double value,
    required String sub,
    required IconData icon,
    required Color color,
  }) =>
      _KpiItem._(label: label, value: value, sub: sub, icon: icon, color: color);

  factory _KpiItem.risk({
    required String label,
    required DiseaseRiskLevel risk,
    required IconData icon,
  }) =>
      _KpiItem._(label: label, risk: risk, icon: icon);

  final String label;
  final double? value;
  final String? sub;
  final IconData? icon;
  final Color? color;
  final HealthLevel? level;
  final DiseaseRiskLevel? risk;
  final bool isRing;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: item.isRing
          ? Column(
              children: [
                Text(
                  item.label.toUpperCase(),
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: (item.value! / 100).clamp(0, 1),
                          strokeWidth: 6,
                          backgroundColor: DashboardColors.cardBorder,
                          valueColor: AlwaysStoppedAnimation(item.level!.color),
                        ),
                      ),
                      Text(
                        '${item.value!.round()}',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '/100',
                  style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.level!.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.level!.label,
                    style: GoogleFonts.notoSans(
                      color: item.level!.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : item.risk != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label.toUpperCase(),
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(item.icon, color: DashboardColors.healthy, size: 22),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.risk!.label,
                      style: GoogleFonts.notoSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DashboardColors.healthy.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Safe',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.healthy,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label.toUpperCase(),
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(item.icon, color: item.color!.withValues(alpha: 0.5), size: 22),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.value!.round()}/100',
                      style: GoogleFonts.notoSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.sub!,
                      style: GoogleFonts.notoSans(
                        color: item.sub!.contains('+')
                            ? DashboardColors.healthy
                            : DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class IndexContributionChart extends StatelessWidget {
  const IndexContributionChart({super.key, required this.profile});

  final HealthMonitoringProfile profile;

  @override
  Widget build(BuildContext context) {
    final max = profile.contributions.map((c) => c.value).reduce((a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đóng góp Chỉ số',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...profile.contributions.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      c.label,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : c.value / max,
                        minHeight: 10,
                        backgroundColor: DashboardColors.cardBorder,
                        valueColor: AlwaysStoppedAnimation(c.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      c.value.toStringAsFixed(1),
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
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

class HealthTrendChart extends StatelessWidget {
  const HealthTrendChart({super.key, required this.profile});

  final HealthMonitoringProfile profile;

  @override
  Widget build(BuildContext context) {
    final spots = profile.trend
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score))
        .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xu hướng Sức khỏe (5 ngày)',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 75,
                maxY: 95,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: DashboardColors.cardBorder.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
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
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= profile.trend.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          MockHealthMonitoringData.formatDate(profile.trend[i].date)
                              .substring(0, 5),
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: DashboardColors.cyan,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: DashboardColors.cyan.withValues(alpha: 0.1),
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

class CrabAssistantPanel extends StatelessWidget {
  const CrabAssistantPanel({super.key, required this.profile});

  final HealthMonitoringProfile profile;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AiAssistantAvatar(size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crab Assistant',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'ACTIVE INSIGHT',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.cyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.aiInsight,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Khuyến nghị:',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.aiRecommendation,
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            child: Text(
              'Chi tiết phân tích AI →',
              style: GoogleFonts.notoSans(color: DashboardColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitorRow {
  const _MonitorRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;
}

class MonitorDetailCards extends StatelessWidget {
  const MonitorDetailCards({super.key, required this.profile});

  final HealthMonitoringProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final cards = [
      _DetailCard(
        title: 'Molting Monitor',
        icon: Icons.sync_outlined,
        rows: [
          _MonitorRow('Lần lột xác', '${p.molting.moltCount}'),
          _MonitorRow('Gần nhất', MockHealthMonitoringData.formatDate(p.molting.lastMoltDate)),
          _MonitorRow('Chu kỳ', '${p.molting.cycleDays} ngày'),
          _MonitorRow('Hồi phục', '${p.molting.recoveryHours} giờ'),
          _MonitorRow('Trạng thái', p.molting.status.label),
        ],
        statusColor: DashboardColors.healthy,
      ),
      _DetailCard(
        title: 'Activity Analytics',
        icon: Icons.sensors_outlined,
        rows: [
          _MonitorRow('Di chuyển', '${p.activity.movementPercent.toStringAsFixed(0)}%'),
          _MonitorRow('Tần suất', '${p.activity.frequencyPerHour} lần/giờ'),
          _MonitorRow('Nghỉ', '${p.activity.restHoursPerDay} giờ/ngày'),
          _MonitorRow('Phản ứng ăn', p.activity.feedingReaction),
          _MonitorRow('Trạng thái', p.activity.statusLabel),
        ],
        statusColor: DashboardColors.cyan,
      ),
      _DetailCard(
        title: 'Feeding Track',
        icon: Icons.restaurant_outlined,
        rows: [
          _MonitorRow('Cấp', '${p.feeding.suppliedGram.toStringAsFixed(0)}g/ngày'),
          _MonitorRow('Thừa', '${p.feeding.leftoverGram.toStringAsFixed(0)}g', highlight: true),
          _MonitorRow('Tỷ lệ ăn', '${p.feeding.eatingRatePercent.toStringAsFixed(0)}%'),
          _MonitorRow('FCR', '${p.feeding.fcr}'),
          _MonitorRow('Trạng thái', p.feeding.statusLabel),
        ],
        statusColor: DashboardColors.purple,
      ),
      _DetailCard(
        title: 'Growth Metrics',
        icon: Icons.trending_up,
        rows: [
          _MonitorRow('Trọng lượng', '${p.growth.currentWeightGram.toStringAsFixed(0)}g'),
          _MonitorRow('Tuần', '+${p.growth.weeklyGainGram.toStringAsFixed(0)}g', highlight: true),
          _MonitorRow('ADG', '${p.growth.adgGram}g/ngày'),
          _MonitorRow('Tỷ lệ', '${p.growth.growthRatePercent}%'),
          _MonitorRow('Trạng thái', p.growth.statusLabel),
        ],
        statusColor: DashboardColors.healthy,
      ),
      _DetailCard(
        title: 'Disease Surveillance',
        icon: Icons.biotech_outlined,
        rows: p.diseaseSurveillance
            .map((d) => _MonitorRow(d.name, d.result))
            .toList(),
        badge: 'ALL CLEAN',
        statusColor: DashboardColors.healthy,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1100 ? 5 : c.maxWidth > 700 ? 3 : 1;
        final spacing = 12.0;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) => SizedBox(width: w, child: card)).toList(),
        );
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.rows,
    this.badge,
    this.statusColor,
  });

  final String title;
  final IconData icon;
  final List<_MonitorRow> rows;
  final String? badge;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DashboardColors.cyan, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DashboardColors.healthy.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.healthy,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.label,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    r.value,
                    style: GoogleFonts.notoSans(
                      color: r.highlight ? DashboardColors.risk : DashboardColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

class HealthScoreBreakdownCard extends StatelessWidget {
  const HealthScoreBreakdownCard({super.key, required this.profile});

  final HealthMonitoringProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = profile.components;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.crabId,
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Hộp ${profile.boxId} | Lứa ${profile.batchId}',
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text(
            'Health Score: ${profile.healthScore.toStringAsFixed(1)}/100',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _levelBadge(profile.level),
          const SizedBox(height: 16),
          _contribRow('Activity Contribution', c.activityContribution),
          _contribRow('Feeding Contribution', c.feedingContribution),
          _contribRow('Growth Contribution', c.growthContribution),
          _contribRow('Water Contribution', c.waterContribution),
          _contribRow('Disease Contribution', c.diseaseContribution),
        ],
      ),
    );
  }

  Widget _levelBadge(HealthLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        level.label,
        style: GoogleFonts.notoSans(color: level.color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _contribRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} điểm',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
