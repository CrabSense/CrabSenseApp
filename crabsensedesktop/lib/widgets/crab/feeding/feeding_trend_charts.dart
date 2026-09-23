import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/crab_feeding_activity.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';

/// Trục X chung cho 2 biểu đồ (để đồng bộ hover): union các bucket có dữ liệu.
List<DateTime> buildSharedAxis(CrabFeedingActivityData data) {
  final set = <DateTime>{
    ...data.feedingTrend.map((p) => p.bucket),
    ...data.activityTrend.map((p) => p.bucket),
  };
  final list = set.toList()..sort();
  return list;
}

String _axisLabel(DateTime t, bool hourly) {
  String two(int v) => v.toString().padLeft(2, '0');
  return hourly ? '${two(t.hour)}:00' : '${two(t.day)}/${two(t.month)}';
}

String _tooltipDate(DateTime t, bool hourly) {
  String two(int v) => v.toString().padLeft(2, '0');
  return hourly
      ? '${two(t.day)}/${two(t.month)} ${two(t.hour)}:00'
      : '${two(t.day)}/${two(t.month)}/${t.year}';
}

/// Khung card chung cho biểu đồ (title + subtitle + body).
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;
  static const height = 260.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: bvText(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          const SizedBox(height: 14),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class ChartEmpty extends StatelessWidget {
  const ChartEmpty({super.key, this.message = 'Chưa đủ dữ liệu để tạo biểu đồ.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded, size: 30, color: DashboardColors.textMuted.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(message, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
        ],
      ),
    );
  }
}

class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({super.key, this.height = 260});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _bar(160, 14),
          const SizedBox(height: 8),
          _bar(220, 11),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: height, child: _bar(double.infinity, height)),
        ],
      ),
    );
  }

  Widget _bar(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: DashboardColors.mint,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

// ── Chart mức ăn ──────────────────────────────────────────────────────────

class FeedingTrendChart extends StatelessWidget {
  const FeedingTrendChart({
    super.key,
    required this.data,
    required this.axis,
    required this.hover,
    this.thresholds = FeedingThresholds.defaults,
  });

  final CrabFeedingActivityData data;
  final List<DateTime> axis;
  final ValueNotifier<int?> hover;
  final FeedingThresholds thresholds;

  @override
  Widget build(BuildContext context) {
    final byBucket = {for (final p in data.feedingTrend) p.bucket: p};
    final hasData = data.feedingTrend.where((p) => p.feedingPercent != null).length >= 2;
    return _ChartCard(
      title: 'Mức ăn theo thời gian',
      subtitle: 'Tỷ lệ % thức ăn được ăn theo ${data.hourly ? 'giờ' : 'ngày'} • ${axis.length} mốc',
      child: !hasData
          ? const ChartEmpty()
          : ValueListenableBuilder<int?>(
              valueListenable: hover,
              builder: (_, hoverIdx, __) => _LineChartBase(
                axis: axis,
                hourly: data.hourly,
                color: DashboardColors.brand,
                areaColor: DashboardColors.brand.withValues(alpha: 0.10),
                hoverIndex: hoverIdx,
                onHover: (i) => hover.value = i,
                valueAt: (i) => byBucket[axis[i]]?.feedingPercent?.toDouble(),
                isWarning: (i) {
                  final v = byBucket[axis[i]]?.feedingPercent;
                  return v != null && thresholds.isLowFeeding(v);
                },
                tooltipLines: (i) {
                  final p = byBucket[axis[i]];
                  if (p == null || p.feedingPercent == null) return const [];
                  String g(double? v) => v == null ? '—' : '${v.toStringAsFixed(0)} g';
                  return [
                    _tooltipDate(p.bucket, data.hourly),
                    'Mức ăn: ${p.feedingPercent}%',
                    'Khẩu phần: ${g(p.servedGram)}',
                    'Đã ăn: ${g(p.eatenGram)}',
                    if (thresholds.isLowFeeding(p.feedingPercent!))
                      '⚠ Mức ăn thấp hơn ngưỡng theo dõi.',
                  ];
                },
              ),
            ),
    );
  }
}

// ── Chart vận động ────────────────────────────────────────────────────────

class ActivityTrendChart extends StatelessWidget {
  const ActivityTrendChart({
    super.key,
    required this.data,
    required this.axis,
    required this.hover,
    this.thresholds = FeedingThresholds.defaults,
  });

  final CrabFeedingActivityData data;
  final List<DateTime> axis;
  final ValueNotifier<int?> hover;
  final FeedingThresholds thresholds;

  @override
  Widget build(BuildContext context) {
    final byBucket = {for (final p in data.activityTrend) p.bucket: p};
    final points = data.activityTrend.where((p) => p.score != null).length;
    return _ChartCard(
      title: 'Mức vận động theo thời gian',
      subtitle: 'Điểm vận động 0–100 theo ${data.hourly ? 'giờ' : 'ngày'} (trước/sau khi ăn)',
      child: points == 0
          ? const ChartEmpty(message: 'Chưa có dữ liệu vận động.')
          : points < 2
              ? const ChartEmpty()
              : ValueListenableBuilder<int?>(
                  valueListenable: hover,
                  builder: (_, hoverIdx, __) => _LineChartBase(
                    axis: axis,
                    hourly: data.hourly,
                    color: kFeedingBlue,
                    areaColor: kFeedingBlue.withValues(alpha: 0.10),
                    hoverIndex: hoverIdx,
                    onHover: (i) => hover.value = i,
                    valueAt: (i) => byBucket[axis[i]]?.score?.toDouble(),
                    isWarning: (i) {
                      final v = byBucket[axis[i]]?.score;
                      return v != null && v < thresholds.lowActivity;
                    },
                    tooltipLines: (i) {
                      final p = byBucket[axis[i]];
                      if (p == null || p.score == null) return const [];
                      return [
                        _tooltipDate(p.bucket, data.hourly),
                        'Vận động: ${p.score} / 100 (${thresholds.activityLabel(p.score!)})',
                        '${p.samples} mẫu đo',
                      ];
                    },
                  ),
                ),
    );
  }
}

// ── Base line chart (fl_chart) ────────────────────────────────────────────

class _LineChartBase extends StatelessWidget {
  const _LineChartBase({
    required this.axis,
    required this.hourly,
    required this.color,
    required this.areaColor,
    required this.hoverIndex,
    required this.onHover,
    required this.valueAt,
    required this.isWarning,
    required this.tooltipLines,
  });

  final List<DateTime> axis;
  final bool hourly;
  final Color color;
  final Color areaColor;
  final int? hoverIndex;
  final ValueChanged<int?> onHover;
  final double? Function(int index) valueAt;
  final bool Function(int index) isWarning;
  final List<String> Function(int index) tooltipLines;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < axis.length; i++) {
      final v = valueAt(i);
      spots.add(v == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), v));
    }
    // fl_chart cần ít nhất 1 spot thật để vẽ.
    final realIdx = <int>[
      for (var i = 0; i < spots.length; i++)
        if (!spots[i].isNull()) i,
    ];
    if (realIdx.isEmpty) return const ChartEmpty();

    final maxX = (axis.length - 1).toDouble().clamp(1.0, double.infinity);
    final labelEvery = axis.length <= 8 ? 1 : (axis.length / 7).ceil();

    final bar = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.25,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.4,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, ___) {
          final warn = isWarning(spot.x.round());
          return FlDotCirclePainter(
            radius: warn ? 4.5 : 3,
            color: warn ? DashboardColors.risk : Colors.white,
            strokeWidth: warn ? 1.5 : 2,
            strokeColor: warn ? Colors.white : color,
          );
        },
      ),
      belowBarData: BarAreaData(show: true, color: areaColor),
    );

    final showing = <ShowingTooltipIndicators>[];
    if (hoverIndex != null &&
        hoverIndex! >= 0 &&
        hoverIndex! < spots.length &&
        !spots[hoverIndex!].isNull()) {
      showing.add(ShowingTooltipIndicators([LineBarSpot(bar, 0, spots[hoverIndex!])]));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: 100,
        clipData: const FlClipData.none(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => FlLine(
            color: DashboardColors.cardBorder.withValues(alpha: 0.7),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 25,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: bvText(fontSize: 10.5, color: DashboardColors.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.round();
                if ((v - i).abs() > 0.01 || i < 0 || i >= axis.length) {
                  return const SizedBox.shrink();
                }
                if (i % labelEvery != 0 && i != axis.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _axisLabel(axis[i], hourly),
                    style: bvText(fontSize: 10.5, color: DashboardColors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [bar],
        showingTooltipIndicators: showing,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            final spot = response?.lineBarSpots?.firstOrNull;
            if (event is FlPointerExitEvent || event is FlPanEndEvent || event is FlTapUpEvent) {
              onHover(null);
              return;
            }
            if (spot == null) return;
            onHover(spot.x.round());
          },
          getTouchedSpotIndicator: (barData, indexes) => indexes
              .map(
                (_) => TouchedSpotIndicatorData(
                  FlLine(color: color.withValues(alpha: 0.35), strokeWidth: 1, dashArray: [4, 3]),
                  FlDotData(
                    getDotPainter: (spot, __, ___, ____) => FlDotCirclePainter(
                      radius: 5,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipRoundedRadius: 10,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            getTooltipColor: (_) => const Color(0xFF0F2A24),
            getTooltipItems: (touched) => touched.map((s) {
              final lines = tooltipLines(s.x.round());
              if (lines.isEmpty) return null;
              return LineTooltipItem(
                lines.first,
                bvText(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                textAlign: TextAlign.left,
                children: [
                  for (final l in lines.skip(1))
                    TextSpan(
                      text: '\n$l',
                      style: bvText(
                        fontSize: 11.5,
                        fontWeight: l.startsWith('⚠') ? FontWeight.w700 : FontWeight.w500,
                        color: l.startsWith('⚠') ? const Color(0xFFFFB4A8) : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      duration: Duration.zero,
    );
  }
}
