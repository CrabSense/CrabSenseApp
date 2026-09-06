import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/water_quality.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

class RealtimeMetricGrid extends StatelessWidget {
  const RealtimeMetricGrid({super.key, required this.readings});

  final List<WaterSensorReading> readings;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              Icon(
                Icons.sensors_off,
                color: DashboardColors.textMuted,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                'Chưa có dữ liệu cảm biến',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chỉ hiển thị chỉ số khi ESP32 gửi mẫu thật.',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final count = c.maxWidth > 1100 ? 4 : (c.maxWidth > 700 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: count >= 4 ? 1.55 : 1.7,
          ),
          itemCount: readings.length,
          itemBuilder: (_, i) => _MetricCard(reading: readings[i]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.reading});

  final WaterSensorReading reading;

  @override
  Widget build(BuildContext context) {
    final delta = reading.delta;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: reading.status.color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(reading.type.icon, color: reading.type.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reading.type.label,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _MiniBadge(status: reading.status),
            ],
          ),
          const Spacer(),
          Text(
            reading.displayValue,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: reading.status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                reading.status.label,
                style: GoogleFonts.notoSans(
                  color: reading.status.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (delta != null && delta.abs() >= 0.05) ...[
                const Spacer(),
                Text(
                  '${delta > 0 ? '↑' : '↓'} ${delta.abs().toStringAsFixed(delta.abs() < 1 ? 2 : 1)}'
                  '${reading.type == WaterSensorType.temperature ? '°C' : ''}',
                  style: GoogleFonts.notoSans(
                    color: delta > 0
                        ? DashboardColors.molting
                        : DashboardColors.oceanBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.status});

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

class RealtimeTrendCard extends StatelessWidget {
  const RealtimeTrendCard({
    super.key,
    required this.metric,
    required this.metrics,
    required this.points,
    required this.rangeIndex,
    required this.rangeMinutes,
    required this.onMetricChanged,
    required this.onRangeChanged,
    this.loading = false,
    this.live = false,
  });

  final WaterSensorType? metric;
  final List<WaterSensorType> metrics;
  final List<RealtimeChartPoint> points;
  final int rangeIndex;
  final int rangeMinutes;
  final ValueChanged<WaterSensorType> onMetricChanged;
  final ValueChanged<int> onRangeChanged;
  final bool loading;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final selected = metric;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: DashboardColors.cyan, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected == null
                      ? 'BIỂU ĐỒ THỜI GIAN THỰC'
                      : 'BIỂU ĐỒ ${selected.label.toUpperCase()}',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            live
                ? 'Cửa sổ ${_RangeToggle._labels[rangeIndex.clamp(0, 3)]} · cập nhật 3s'
                : 'Lịch sử cảm biến theo khoảng thời gian',
            style: GoogleFonts.notoSans(
              color: live ? DashboardColors.healthy : DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetricDropdown(
                selected: selected,
                metrics: metrics,
                onChanged: onMetricChanged,
              ),
              _RangeToggle(selected: rangeIndex, onChanged: onRangeChanged),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: points.isEmpty || selected == null
                ? Center(
                    child: Text(
                      loading
                          ? 'Đang tải lịch sử...'
                          : 'Chưa có dữ liệu biểu đồ cho chỉ số này',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                      ),
                    ),
                  )
                : _SeriesChart(
                    points: points,
                    rangeMinutes: rangeMinutes,
                    color: selected.accent,
                    unit: _unitOf(selected),
                  ),
          ),
        ],
      ),
    );
  }

  String _unitOf(WaterSensorType type) => switch (type) {
        WaterSensorType.temperature => '°C',
        WaterSensorType.tds => 'ppm',
        WaterSensorType.salinity => 'ppt',
        WaterSensorType.flow => 'L/min',
        WaterSensorType.waterLevel => '%',
        WaterSensorType.dissolvedOxygen => 'mg/L',
        WaterSensorType.orp => 'mV',
        WaterSensorType.nh3 || WaterSensorType.no2 => 'mg/L',
        WaterSensorType.ph => '',
      };
}

class _MetricDropdown extends StatelessWidget {
  const _MetricDropdown({
    required this.selected,
    required this.metrics,
    required this.onChanged,
  });

  final WaterSensorType? selected;
  final List<WaterSensorType> metrics;
  final ValueChanged<WaterSensorType> onChanged;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return Text(
        'Chưa có cảm biến',
        style: GoogleFonts.notoSans(
          color: DashboardColors.textMuted,
          fontSize: 12,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: DashboardColors.cardBorder.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<WaterSensorType>(
          value: selected ?? metrics.first,
          dropdownColor: DashboardColors.card,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: [
            for (final m in metrics)
              DropdownMenuItem(value: m, child: Text(m.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['1H', '6H', '24H', '7 Ngày'];

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

class _SeriesChart extends StatelessWidget {
  const _SeriesChart({
    required this.points,
    required this.rangeMinutes,
    required this.color,
    required this.unit,
  });

  final List<RealtimeChartPoint> points;
  final int rangeMinutes;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.value).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    if ((maxY - minY).abs() < 0.2) {
      minY -= 0.5;
      maxY += 0.5;
    } else {
      final pad = (maxY - minY) * 0.15;
      minY -= pad;
      maxY += pad;
    }
    final maxX = rangeMinutes.toDouble();
    final interval = rangeMinutes <= 60
        ? 10.0
        : rangeMinutes <= 360
            ? 60.0
            : rangeMinutes <= 1440
                ? 240.0
                : 1440.0;
    final yInterval = ((maxY - minY) / 4).clamp(0.1, 1000.0);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yInterval,
          verticalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: DashboardColors.cardBorder.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: DashboardColors.cardBorder.withValues(alpha: 0.22),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(v.abs() >= 10 ? 0 : 1),
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: interval,
              getTitlesWidget: (v, _) {
                final idx = _nearest(points, v);
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
              return LineTooltipItem(
                '${p.label}\n${p.value.toStringAsFixed(2)} $unit',
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
            spots: [
              for (final p in points) FlSpot(p.xMinutes.clamp(0, maxX), p.value),
            ],
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  static int _nearest(List<RealtimeChartPoint> points, double x) {
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
    return best;
  }
}

class RealtimeLocationSection extends StatelessWidget {
  const RealtimeLocationSection({super.key, required this.groups});

  final List<RealtimeLocationGroup> groups;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, color: DashboardColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text(
                'VỊ TRÍ ĐO',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 900 ? 3 : (c.maxWidth > 560 ? 2 : 1);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                itemCount: groups.length,
                itemBuilder: (_, i) => _LocationCard(group: groups[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.group});

  final RealtimeLocationGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          for (final r in group.readings.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(r.type.icon, size: 14, color: r.type.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.type.label,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    r.displayValue,
                    style: GoogleFonts.notoSans(
                      color: r.status.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class RealtimeAlertSection extends StatelessWidget {
  const RealtimeAlertSection({super.key, required this.alerts});

  final List<RealtimeWaterAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_outlined,
                color: DashboardColors.cyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'CẢNH BÁO HIỆN TẠI',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (alerts.isEmpty)
            Row(
              children: [
                const Icon(Icons.check_circle, color: DashboardColors.healthy, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tất cả thông số đang trong ngưỡng an toàn.',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.healthy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            for (final a in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: a.status.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: a.status.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: GoogleFonts.notoSans(
                          color: a.status.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.detail,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 12,
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
