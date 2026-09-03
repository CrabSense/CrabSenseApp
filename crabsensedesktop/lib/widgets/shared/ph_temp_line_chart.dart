import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/water_quality.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/chart_line_smooth.dart';

/// Biểu đồ pH (xanh dương) + nhiệt độ (cam) — trục Y 0–28, giống Cloud ~30 phút.
class PhTempLineChart extends StatelessWidget {
  const PhTempLineChart({
    super.key,
    required this.points,
    required this.rangeMinutes,
    this.showPh = true,
    this.showTemp = true,
    this.height = 260,
  });

  final List<WaterTrendPoint> points;
  final int rangeMinutes;
  final bool showPh;
  final bool showTemp;
  final double height;

  static const leftMaxY = 28.0;
  static const phColor = Color(0xFF2196F3);
  static const tempColor = Color(0xFFFF9800);

  /// Spline mượt — không dùng preventCurveOverShooting (gây đường bậc thang).
  static const _curveSmoothness = 0.22;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Đang tải dữ liệu...',
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
          ),
        ),
      );
    }

    final maxX = rangeMinutes.toDouble();
    final phSpots = showPh
        ? ChartLineSmooth.fromSeries(
            points
                .map((p) => FlSpot(p.xMinutes, p.ph.clamp(0, leftMaxY)))
                .toList(),
            emaAlpha: 0.18,
            segmentsPerGap: 8,
          )
        : <FlSpot>[];
    final tempSpots = showTemp
        ? ChartLineSmooth.fromSeries(
            points
                .map((p) => FlSpot(p.xMinutes, p.temperature.clamp(0, leftMaxY)))
                .toList(),
            emaAlpha: 0.18,
            segmentsPerGap: 8,
          )
        : <FlSpot>[];

    final bottomInterval = rangeMinutes <= 30
        ? (rangeMinutes / 6).clamp(4.0, 8.0)
        : rangeMinutes <= 60
            ? 10.0
            : 240.0;

    FlLine gridLine({bool vertical = false}) => FlLine(
          color: DashboardColors.cardBorder.withValues(alpha: vertical ? 0.22 : 0.35),
          strokeWidth: 1,
          dashArray: [5, 5],
        );

    final bars = <LineChartBarData>[
      if (showPh && phSpots.isNotEmpty)
        LineChartBarData(
          spots: phSpots,
          isCurved: true,
          curveSmoothness: _curveSmoothness,
          color: phColor,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      if (showTemp && tempSpots.isNotEmpty)
        LineChartBarData(
          spots: tempSpots,
          isCurved: true,
          curveSmoothness: _curveSmoothness,
          color: tempColor,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: leftMaxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 7,
            verticalInterval: bottomInterval,
            getDrawingHorizontalLine: (_) => gridLine(),
            getDrawingVerticalLine: (_) => gridLine(vertical: true),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 7,
                getTitlesWidget: (v, _) {
                  if (!_isTick(v, leftMaxY)) return const SizedBox.shrink();
                  return Text(
                    v.toInt().toString(),
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: bottomInterval,
                getTitlesWidget: (v, _) {
                  final idx = _nearestIndex(points, v);
                  if (idx < 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[idx].label,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: DashboardColors.cardBorder.withValues(alpha: 0.35),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched.map((t) {
                final i = t.spotIndex;
                if (i < 0 || i >= points.length) return null;
                final p = points[i];
                final isPh = showPh && (!showTemp || t.barIndex == 0);
                final text = isPh
                    ? 'pH: ${p.ph.toStringAsFixed(2)}'
                    : 'temp: ${p.temperature.toStringAsFixed(1)}°C';
                return LineTooltipItem(
                  text,
                  GoogleFonts.notoSans(fontSize: 11),
                );
              }).toList(),
            ),
          ),
          lineBarsData: bars,
        ),
      ),
    );
  }

  static bool _isTick(double v, double max) {
    for (final t in [0.0, 7.0, 14.0, 21.0, max]) {
      if ((v - t).abs() < 0.01) return true;
    }
    return false;
  }

  static int _nearestIndex(List<WaterTrendPoint> points, double x) {
    if (points.isEmpty) return -1;
    var best = 0;
    var bestDist = (points[0].xMinutes - x).abs();
    for (var i = 1; i < points.length; i++) {
      final d = (points[i].xMinutes - x).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    final span = points.last.xMinutes - points.first.xMinutes;
    final threshold = (span / 8).clamp(2.0, 12.0);
    return bestDist <= threshold ? best : -1;
  }
}

class PhTempChartLegend extends StatelessWidget {
  const PhTempChartLegend({super.key, this.showPh = true, this.showTemp = true});

  final bool showPh;
  final bool showTemp;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        if (showPh) _item('pH', PhTempLineChart.phColor),
        if (showTemp) _item('temp', PhTempLineChart.tempColor),
      ],
    );
  }

  Widget _item(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
