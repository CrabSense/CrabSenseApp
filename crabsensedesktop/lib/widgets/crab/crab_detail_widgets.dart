import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_formatters.dart';
import '../../models/crab_individual.dart';
import '../../models/crab_status.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import 'crab_auth_image.dart';
import 'crab_status_badge.dart';

class CrabPhotoCard extends StatelessWidget {
  const CrabPhotoCard({super.key, required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets, size: 48, color: DashboardColors.cyan.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'Ảnh cua — mở tab Camera AI trong Quản lý cua',
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class CrabInfoCard extends StatelessWidget {
  const CrabInfoCard({super.key, required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Mã cua', crab.id, highlight: true),
          _row('Mã hộp', 'Hộp ${crab.boxId}', highlight: true),
          _row('Mã lứa', crab.batchId),
          _row('Giới tính', crab.gender.label),
          _row('Ngày thả', formatDate(crab.releaseDate)),
          _row('Tuổi nuôi', '${crab.ageDays} ngày'),
          _row(
            'Cân nặng',
            crab.weightGram > 0 ? '${crab.weightGram.toStringAsFixed(0)} g' : '—',
          ),
          _row(
            'Bề ngang mai',
            crab.carapaceLengthMm > 0 ? '${crab.carapaceLengthMm} mm' : '—',
          ),
          _row(
            'Bề rộng mai',
            crab.shellSizeCm > 0 ? '${crab.shellSizeCm} mm' : '—',
          ),
          _row('Lột xác cuối', crab.lastMoltDate == null ? '—' : formatDate(crab.lastMoltDate!)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.notoSans(
                color: highlight ? DashboardColors.cyan : DashboardColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CrabQuickNoteCard extends StatelessWidget {
  const CrabQuickNoteCard({super.key, required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    if (crab.quickNote.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: DashboardColors.cyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ghi chú nhanh',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  crab.quickNote,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                    height: 1.45,
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

class CrabDetailKpiRow extends StatelessWidget {
  const CrabDetailKpiRow({super.key, required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 700;
        final growth = _MetricCard(
          icon: Icons.trending_up,
          label: 'Tăng trưởng',
          value: '+${crab.growthLast7Days.toStringAsFixed(0)}g',
          sub: '7 ngày qua',
          color: DashboardColors.healthy,
        );
        final feeding = _MetricCard(
          icon: Icons.restaurant_outlined,
          label: 'Cho ăn',
          value: '${crab.avgFeedingGram.toStringAsFixed(0)}g',
          sub: 'Mức ăn/ngày',
          color: DashboardColors.cyan,
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _HealthRing(score: crab.healthScore)),
              const SizedBox(width: 12),
              Expanded(child: growth),
              const SizedBox(width: 12),
              Expanded(child: feeding),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HealthRing(score: crab.healthScore),
            const SizedBox(height: 12),
            growth,
            const SizedBox(height: 12),
            feeding,
          ],
        );
      },
    );
  }
}

class _HealthRing extends StatelessWidget {
  const _HealthRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'HEALTH SCORE',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
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
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor: DashboardColors.cardBorder,
                    valueColor: const AlwaysStoppedAnimation(DashboardColors.cyan),
                  ),
                ),
                Text(
                  '$score',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.cyan,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11)),
              Text(
                value,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(sub, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class CrabWeightChart extends StatelessWidget {
  const CrabWeightChart({super.key, required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    final points = crab.weightHistory;
    if (points.isEmpty) return const SizedBox.shrink();

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weightGram))
        .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Biểu đồ Tăng trưởng trọng lượng',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${crab.weightGram.toStringAsFixed(0)}g',
                  style: GoogleFonts.notoSans(color: DashboardColors.purple, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
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
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= points.length) return const SizedBox.shrink();
                        return Text(
                          formatDate(points[i].date).substring(0, 5),
                          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 8),
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
                    color: DashboardColors.purple,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: DashboardColors.purple.withValues(alpha: 0.12),
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

class CrabFeedingTable extends StatelessWidget {
  const CrabFeedingTable({super.key, required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử ăn uống',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (crab.feedings.isEmpty)
            Text('Chưa có dữ liệu', style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12))
          else
            ...crab.feedings.reversed.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        formatDate(f.date),
                        style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: f.foodType.contains('viên')
                            ? DashboardColors.molting
                            : DashboardColors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f.foodType, style: GoogleFonts.notoSans(fontSize: 12))),
                    Text('${f.amountGram.toStringAsFixed(0)}g', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                    if (f.note != null) ...[
                      const SizedBox(width: 8),
                      Text(f.note!, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CrabMoltTimeline extends StatelessWidget {
  const CrabMoltTimeline({super.key, required this.crab, this.token});

  final CrabIndividual crab;
  final String? token;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lịch sử lột xác',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${crab.moltCount} LẦN',
                  style: GoogleFonts.notoSans(color: DashboardColors.purple, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...crab.molts.reversed.map(_moltItem),
        ],
      ),
    );
  }

  Widget _moltItem(CrabMoltRecord m) {
    final color = switch (m.condition) {
      MoltCondition.normal => DashboardColors.healthy,
      MoltCondition.weak => DashboardColors.monitoring,
      MoltCondition.needsWatch => DashboardColors.monitoring,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lần ${m.number}',
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m.condition.label.toUpperCase(),
                        style: GoogleFonts.notoSans(color: color, fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                Text(
                  formatDate(m.date),
                  style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10),
                ),
                if (m.note != null)
                  Text(m.note!, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11)),
                if (m.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < m.photoUrls.length; i++)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CrabAuthImage(
                            crabId: crab.id,
                            index: i,
                            token: token ?? '',
                            fallbackUrl: m.photoUrls[i],
                            proxyUrl: (m.id ?? '').isNotEmpty
                                ? CrabAuthImage.moltProxyUrl(m.id!, i)
                                : null,
                            width: 48,
                            height: 48,
                          ),
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

class CrabDiseaseList extends StatelessWidget {
  const CrabDiseaseList({super.key, required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử bệnh',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (crab.diseases.isEmpty)
            Text('Không có bệnh án', style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12))
          else
            ...crab.diseases.reversed.map((d) {
              final live = d.status == DiseaseRecordStatus.monitoring;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatDate(d.date)} | ${d.name}',
                            style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            d.status.label,
                            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    if (live)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DashboardColors.risk.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LIVE',
                          style: GoogleFonts.notoSans(color: DashboardColors.risk, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      const Icon(Icons.check_circle_outline, color: DashboardColors.healthy, size: 18),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class CrabEnvironmentCard extends StatelessWidget {
  const CrabEnvironmentCard({super.key, required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Môi trường tại Hộp ${crab.boxId}',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _envTile(Icons.thermostat_outlined, 'Nhiệt độ', '${crab.envTempC}°C'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _envTile(Icons.water_drop_outlined, 'Độ mặn', '${crab.envSalinityPpt.toStringAsFixed(0)} ppt'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _envTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DashboardColors.cyan, size: 20),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10)),
          Text(value, style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class CrabHealthHeaderBadge extends StatelessWidget {
  const CrabHealthHeaderBadge({super.key, required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CrabHealthBadge(status: crab.healthStatus),
        const SizedBox(width: 12),
        CrabLifeBadge(status: crab.lifeStatus),
      ],
    );
  }
}
