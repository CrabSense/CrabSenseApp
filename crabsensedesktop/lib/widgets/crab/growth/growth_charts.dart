import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/crab_growth_molt.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import '../feeding/feeding_trend_charts.dart';

class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({super.key, required this.points, required this.onAdd});

  final List<GrowthMeasurement> points;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _GrowthChartCard(
      title: 'Biểu đồ cân nặng',
      legend: const [_LegendDot(color: DashboardColors.brand, label: 'Cân nặng (g)')],
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (points.isEmpty) {
      return _ChartNeedData(needTwo: false, onAdd: onAdd);
    }
    if (points.length == 1) {
      return _ChartNeedData(needTwo: true, onAdd: onAdd);
    }
    return _GrowthLineChart(
      axis: [for (final p in points) p.measuredAt],
      series: [
        _Series(
          color: DashboardColors.brand,
          area: DashboardColors.brand.withValues(alpha: 0.10),
          valueAt: (i) => points[i].weightGram,
          unit: 'g',
        ),
      ],
      tooltip: (i) {
        final p = points[i];
        final prev = i == 0 ? null : points[i - 1];
        final delta = prev == null ? null : p.weightGram - prev.weightGram;
        return [
          fmtDateVn(p.measuredAt),
          'Cân nặng: ${fmtGram(p.weightGram)}',
          if (delta != null) '${fmtSignedGram(delta)} so với lần trước',
          'Người ghi: ${p.recorderLabel}',
        ];
      },
    );
  }
}

class ShellSizeTrendChart extends StatelessWidget {
  const ShellSizeTrendChart({super.key, required this.points, required this.onAdd});

  final List<GrowthMeasurement> points;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _GrowthChartCard(
      title: 'Biểu đồ kích thước mai',
      legend: const [
        _LegendDot(color: kGrowthAmber, label: 'Rộng mai (mm)'),
        _LegendDot(color: kGrowthBlue, label: 'Dài mai (mm)'),
      ],
      child: _body(),
    );
  }

  Widget _body() {
    final sized = points.where((p) => p.shellWidthMm != null || p.shellLengthMm != null).toList();
    if (sized.isEmpty) {
      return _ChartNeedData(needTwo: false, onAdd: onAdd);
    }
    if (sized.length == 1) {
      return _ChartNeedData(needTwo: true, onAdd: onAdd);
    }
    return _GrowthLineChart(
      axis: [for (final p in sized) p.measuredAt],
      series: [
        _Series(
          color: kGrowthAmber,
          area: kGrowthAmber.withValues(alpha: 0.08),
          valueAt: (i) => sized[i].shellWidthMm,
          unit: 'mm',
        ),
        _Series(
          color: kGrowthBlue,
          area: kGrowthBlue.withValues(alpha: 0.06),
          valueAt: (i) => sized[i].shellLengthMm,
          unit: 'mm',
        ),
      ],
      tooltip: (i) {
        final p = sized[i];
        return [
          fmtDateVn(p.measuredAt),
          'Rộng mai: ${fmtMm(p.shellWidthMm)}',
          'Dài mai: ${fmtMm(p.shellLengthMm)}',
        ];
      },
    );
  }
}

class _GrowthChartCard extends StatelessWidget {
  const _GrowthChartCard({required this.title, required this.legend, required this.child});

  final String title;
  final List<Widget> legend;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                ),
              ),
              Wrap(spacing: 14, children: legend),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: 240, child: child),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
      ],
    );
  }
}

class _ChartNeedData extends StatelessWidget {
  const _ChartNeedData({required this.needTwo, required this.onAdd});
  final bool needTwo;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded, size: 30, color: DashboardColors.textMuted.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            needTwo ? 'Cần ít nhất 2 lần đo để hiển thị xu hướng.' : 'Chưa có dữ liệu sinh trưởng',
            textAlign: TextAlign.center,
            style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
          ),
          if (!needTwo) ...[
            const SizedBox(height: 4),
            Text(
              'Chưa có đủ dữ liệu cân nặng hoặc kích thước để tạo biểu đồ.',
              textAlign: TextAlign.center,
              style: bvText(fontSize: 12, color: DashboardColors.textMuted),
            ),
            const SizedBox(height: 10),
            MgmtOutlineButton(icon: Icons.add_rounded, label: 'Ghi nhận lần đo đầu tiên', onTap: onAdd, height: 32),
          ],
        ],
      ),
    );
  }
}

class _Series {
  const _Series({required this.color, required this.area, required this.valueAt, required this.unit});
  final Color color;
  final Color area;
  final double? Function(int i) valueAt;
  final String unit;
}

class _GrowthLineChart extends StatelessWidget {
  const _GrowthLineChart({required this.axis, required this.series, required this.tooltip});

  final List<DateTime> axis;
  final List<_Series> series;
  final List<String> Function(int i) tooltip;

  @override
  Widget build(BuildContext context) {
    final values = <double>[];
    for (final s in series) {
      for (var i = 0; i < axis.length; i++) {
        final v = s.valueAt(i);
        if (v != null) values.add(v);
      }
    }
    if (values.isEmpty) return const ChartEmpty();

    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    if ((maxY - minY).abs() < 1) {
      minY = (minY - 8).clamp(0, double.infinity);
      maxY = maxY + 8;
    } else {
      final pad = (maxY - minY) * 0.18;
      minY = (minY - pad).clamp(0, double.infinity);
      maxY = maxY + pad;
    }
    final interval = _niceInterval(maxY - minY);
    minY = (minY / interval).floor() * interval;
    maxY = (maxY / interval).ceil() * interval;
    if (maxY <= minY) maxY = minY + interval;

    final bars = <LineChartBarData>[];
    for (final s in series) {
      final spots = <FlSpot>[
        for (var i = 0; i < axis.length; i++)
          s.valueAt(i) == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), s.valueAt(i)!),
      ];
      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.22,
          preventCurveOverShooting: true,
          color: s.color,
          barWidth: 2.4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.2,
              color: Colors.white,
              strokeWidth: 2,
              strokeColor: s.color,
            ),
          ),
          belowBarData: BarAreaData(show: true, color: s.area),
        ),
      );
    }

    final labelEvery = axis.length <= 8 ? 1 : (axis.length / 6).ceil();
    final maxX = (axis.length - 1).toDouble().clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.none(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
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
              reservedSize: 36,
              interval: interval,
              getTitlesWidget: (v, _) => Text(
                v % 1 == 0 ? '${v.toInt()}' : v.toStringAsFixed(0),
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
                if ((v - i).abs() > 0.01 || i < 0 || i >= axis.length) return const SizedBox.shrink();
                if (i % labelEvery != 0 && i != axis.length - 1) return const SizedBox.shrink();
                final t = axis[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}',
                    style: bvText(fontSize: 10.5, color: DashboardColors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, indexes) => indexes
              .map(
                (_) => TouchedSpotIndicatorData(
                  FlLine(color: DashboardColors.brand.withValues(alpha: 0.3), strokeWidth: 1, dashArray: const [4, 3]),
                  FlDotData(
                    getDotPainter: (spot, __, ___, ____) => FlDotCirclePainter(
                      radius: 5,
                      color: barData.color ?? DashboardColors.brand,
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
            getTooltipItems: (touched) {
              if (touched.isEmpty) return [];
              final i = touched.first.x.round();
              final lines = tooltip(i);
              return [
                for (var t = 0; t < touched.length; t++)
                  t == 0
                      ? LineTooltipItem(
                          lines.first,
                          bvText(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                          textAlign: TextAlign.left,
                          children: [
                            for (final l in lines.skip(1))
                              TextSpan(text: '\n$l', style: bvText(fontSize: 11, color: Colors.white.withValues(alpha: 0.9))),
                          ],
                        )
                      : null,
              ];
            },
          ),
        ),
      ),
    );
  }

  static double _niceInterval(double span) {
    if (span <= 20) return 10;
    if (span <= 40) return 20;
    if (span <= 80) return 20;
    if (span <= 160) return 40;
    return 50;
  }
}
