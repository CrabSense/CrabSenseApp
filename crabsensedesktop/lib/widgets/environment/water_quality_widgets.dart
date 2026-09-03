import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/water_quality.dart';
import '../../services/water_quality_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';

class WaterGaugeCard extends StatelessWidget {
  const WaterGaugeCard({super.key, required this.reading});

  final WaterSensorReading reading;

  @override
  Widget build(BuildContext context) {
    final status = reading.status;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reading.type.shortLabel,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            width: 100,
            child: CustomPaint(
              painter: _GaugeArcPainter(
                progress: reading.gaugeProgress,
                color: status.color,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _centerValue(reading),
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (reading.unit.isNotEmpty)
                      Text(
                        reading.unit,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reading.type.label,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _centerValue(WaterSensorReading r) {
    if (r.type == WaterSensorType.temperature) {
      return r.value.toStringAsFixed(1);
    }
    if (r.value < 1) return r.value.toStringAsFixed(2);
    if (r.value == r.value.roundToDouble()) {
      return r.value.round().toString();
    }
    return r.value.toStringAsFixed(1);
  }
}

class _GaugeArcPainter extends CustomPainter {
  _GaugeArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final start = math.pi * 0.75;
    final sweep = math.pi * 1.5;

    final track = Paint()
      ..color = DashboardColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, track);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _GaugeArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final WaterSensorStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: GoogleFonts.notoSans(
          color: status.color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class WaterGaugeGrid extends StatelessWidget {
  const WaterGaugeGrid({super.key, required this.readings});

  final List<WaterSensorReading> readings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final count = c.maxWidth > 1100 ? 4 : (c.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: count >= 4 ? 1.35 : 1.2,
          ),
          itemCount: readings.length,
          itemBuilder: (_, i) => WaterGaugeCard(reading: readings[i]),
        );
      },
    );
  }
}

class WaterTrendChartCard extends StatelessWidget {
  const WaterTrendChartCard({
    super.key,
    required this.points,
    required this.rangeIndex,
    required this.rangeLabel,
    required this.rangeMinutes,
    required this.onRangeChanged,
    this.loading = false,
    this.cloudLive = false,
  });

  final List<WaterTrendPoint> points;
  final int rangeIndex;
  final String rangeLabel;
  final int rangeMinutes;
  final ValueChanged<int> onRangeChanged;
  final bool loading;
  final bool cloudLive;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return GlassCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              loading ? 'Đang tải xu hướng từ Cloud...' : 'Chưa có dữ liệu biểu đồ',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
          ),
        ),
      );
    }

    const leftMaxY = 28.0;
    const rightMaxTds = 600.0;
    const phColor = Color(0xFF2196F3);
    const tempColor = Color(0xFFFF9800);
    const tdsColor = Color(0xFF4CAF50);
    const flowColor = Color(0xFF9C27B0);

    final maxX = rangeMinutes.toDouble();
    double mapTds(double tds) => (tds / rightMaxTds) * leftMaxY;

    final phSpots =
        points.map((p) => FlSpot(p.xMinutes, p.ph.clamp(0, leftMaxY))).toList();
    final tempSpots = points
        .map((p) => FlSpot(p.xMinutes, p.temperature.clamp(0, leftMaxY)))
        .toList();
    final tdsSpots = points
        .map((p) => FlSpot(p.xMinutes, mapTds(p.tds)))
        .toList();
    final flowSpots =
        points.map((p) => FlSpot(p.xMinutes, p.flow.clamp(0, leftMaxY))).toList();

    final bottomInterval = rangeMinutes <= 30
        ? (rangeMinutes / 6).clamp(4.0, 8.0)
        : rangeMinutes <= 60
            ? 10.0
            : 240.0;

    final title = cloudLive
        ? 'Biểu đồ (lịch sử Cloud ~$rangeLabel)'
        : 'Biểu đồ xu hướng · $rangeLabel';
    final liveHint = 'Realtime · cửa sổ $rangeLabel · cập nhật 3s';

    FlLine gridLine({bool vertical = false}) => FlLine(
          color: DashboardColors.cardBorder.withValues(alpha: vertical ? 0.22 : 0.35),
          strokeWidth: 1,
          dashArray: [5, 5],
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      liveHint,
                      style: GoogleFonts.notoSans(
                        color: cloudLive
                            ? DashboardColors.healthy
                            : DashboardColors.cyan,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              _RangeToggle(selected: rangeIndex, onChanged: onRangeChanged),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
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
                        if (!_isAxisTick(v, leftMaxY)) {
                          return const SizedBox.shrink();
                        }
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
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: 7,
                      getTitlesWidget: (v, _) {
                        if (!_isAxisTick(v, leftMaxY)) {
                          return const SizedBox.shrink();
                        }
                        final tdsVal = ((v / leftMaxY) * rightMaxTds).round();
                        return Text(
                          '$tdsVal',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: bottomInterval,
                      getTitlesWidget: (v, _) {
                        final idx = _nearestPointIndex(points, v);
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
                    getTooltipItems: (touched) => touched.map((bar) {
                      final i = bar.spotIndex;
                      if (i < 0 || i >= points.length) return null;
                      final p = points[i];
                      final name = switch (bar.barIndex) {
                        0 => 'pH',
                        1 => 'temp',
                        2 => 'tds',
                        _ => 'flow',
                      };
                      final val = switch (bar.barIndex) {
                        0 => p.ph.toStringAsFixed(2),
                        1 => '${p.temperature.toStringAsFixed(1)}°C',
                        2 => '${p.tds.toStringAsFixed(0)} ppm',
                        _ => p.flow.toStringAsFixed(1),
                      };
                      return LineTooltipItem(
                        '$name: $val',
                        GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: phSpots,
                    isCurved: false,
                    color: phColor,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: tempSpots,
                    isCurved: false,
                    color: tempColor,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: tdsSpots,
                    isCurved: false,
                    color: tdsColor,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: flowSpots,
                    isCurved: false,
                    color: flowColor,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Wrap(
              spacing: 20,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _legend('pH', phColor),
                _legend('temp', tempColor),
                _legend('tds', tdsColor),
                _legend('flow', flowColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _isAxisTick(double v, double max) {
    for (final t in [0.0, 7.0, 14.0, 21.0, max]) {
      if ((v - t).abs() < 0.01) return true;
    }
    return false;
  }

  static int _nearestPointIndex(List<WaterTrendPoint> points, double x) {
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

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['30 phút', '1 giờ', '24 giờ'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_labels.length, (i) {
        final active = i == selected;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: InkWell(
            onTap: () => onChanged(i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? DashboardColors.purple.withValues(alpha: 0.25)
                    : DashboardColors.cardBorder.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active ? DashboardColors.purple : Colors.transparent,
                ),
              ),
              child: Text(
                _labels[i],
                style: GoogleFonts.notoSans(
                  color: active
                      ? DashboardColors.textPrimary
                      : DashboardColors.textMuted,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class CrabAssistantWaterCard extends StatelessWidget {
  const CrabAssistantWaterCard({
    super.key,
    required this.insight,
    required this.recommendations,
  });

  final String insight;
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiAssistantHeader(
            title: 'Crab Assistant',
            avatarSize: 48,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashboardColors.darkNavy.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Text(
              insight,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'KHUYẾN NGHỊ',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...recommendations.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: DashboardColors.cyan)),
                  Expanded(
                    child: Text(
                      r,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.cyan,
                        fontSize: 12,
                        height: 1.4,
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

class WaterStatusTable extends StatelessWidget {
  const WaterStatusTable({super.key, required this.readings});

  final List<WaterSensorReading> readings;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bảng trạng thái cảm biến',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 56,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 12,
              ),
              columns: const [
                DataColumn(label: Text('Thông số')),
                DataColumn(label: Text('Giá trị hiện tại')),
                DataColumn(label: Text('Ngưỡng tốt')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: readings.map((r) {
                return DataRow(
                  cells: [
                    DataCell(Text(r.type.label)),
                    DataCell(Text(r.displayValue.trim())),
                    DataCell(Text(r.threshold.goodRangeLabel)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: r.status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            r.status.label,
                            style: TextStyle(color: r.status.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class WaterHistoryTable extends StatelessWidget {
  const WaterHistoryTable({super.key, required this.rows});

  final List<WaterHistoryRow> rows;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lịch sử dữ liệu',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 11,
              ),
              columns: [
                const DataColumn(label: Text('Thời gian')),
                ...WaterSensorType.cloudFirst.map(
                  (t) => DataColumn(label: Text(t.label)),
                ),
              ],
              rows: rows.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(row.time)),
                    ...WaterSensorType.cloudFirst.map(
                      (t) => DataCell(Text(row.values[t] ?? '—')),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class WaterAlertLegend extends StatelessWidget {
  const WaterAlertLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      WaterSensorStatus.normal,
      WaterSensorStatus.monitoring,
      WaterSensorStatus.exceeded,
      WaterSensorStatus.danger,
      WaterSensorStatus.offline,
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trạng thái cảnh báo',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: items.map((status) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status.label,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class WaterQualityFilterBar extends StatelessWidget {
  const WaterQualityFilterBar({super.key, required this.service});

  final WaterQualityService service;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [
        _filter('Khu nuôi', service.area, MockWaterQualityFilterOptions.areas,
            service.setArea),
        _filter('Thiết bị', service.device, MockWaterQualityFilterOptions.devices,
            service.setDevice),
        _filter('Thời gian', service.timeRange,
            MockWaterQualityFilterOptions.times, service.setTimeRange),
        _filter('Trạng thái', service.statusFilter,
            MockWaterQualityFilterOptions.statuses, service.setStatusFilter),
      ],
    );
  }

  Widget _filter(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : items.first,
            dropdownColor: DashboardColors.card,
            style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 12),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: DashboardColors.darkNavy,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DashboardColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DashboardColors.cardBorder),
              ),
            ),
            items: items
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

/// Filter option lists for UI (mirrors mock data).
abstract final class MockWaterQualityFilterOptions {
  static const areas = ['Tất cả', 'Khu A', 'Khu B', 'Khu C'];
  static const devices = ['Tất cả', 'Sensor-01', 'Sensor-02', 'Sensor-03'];
  static const times = ['24h', '7 ngày', '30 ngày'];
  static const statuses = ['Tất cả', 'Bình thường', 'Cảnh báo', 'Offline'];
}
