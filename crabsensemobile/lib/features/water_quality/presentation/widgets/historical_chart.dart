import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/entities/water_quality.dart';
import '../../domain/entities/water_quality_thresholds.dart';
import '../../domain/repositories/water_quality_repository.dart';

/// Tham số chất lượng nước dùng cho biểu đồ lịch sử.
enum WaterQualityParameter {
  temperature,
  salinity,
  ph,
  dissolvedOxygen,
  ammonia,
  nitrite,
  kh,
  calcium,
  magnesium,
}

/// Biểu đồ lịch sử chất lượng nước (phong cách hologram).
class HistoricalChart extends StatefulWidget {
  const HistoricalChart({
    required this.readings,
    required this.thresholds,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    super.key,
    this.isLoading = false,
    this.showPeriodSelector = true,
    this.decorate = true,
  });

  final List<WaterQuality> readings;
  final WaterQualityThresholds thresholds;
  final HistoricalPeriod selectedPeriod;
  final void Function(HistoricalPeriod) onPeriodChanged;
  final bool isLoading;
  final bool showPeriodSelector;
  final bool decorate;

  @override
  State<HistoricalChart> createState() => _HistoricalChartState();
}

class _HistoricalChartState extends State<HistoricalChart> {
  WaterQualityParameter _selectedParameter = WaterQualityParameter.ph;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showPeriodSelector) ...[
          _PeriodSelector(
            selected: widget.selectedPeriod,
            onChanged: widget.onPeriodChanged,
          ),
          Divider(height: 1, color: kHomeBorder.withValues(alpha: 0.6)),
        ],
        _ParameterSelector(
          selected: _selectedParameter,
          onChanged: (p) => setState(() => _selectedParameter = p),
        ),
        _ChartBody(
          readings: widget.readings,
          thresholds: widget.thresholds,
          parameter: _selectedParameter,
          period: widget.selectedPeriod,
          isLoading: widget.isLoading,
        ),
      ],
    );
    if (!widget.decorate) return column;
    return Container(
      decoration: homeCardDecoration(radius: 20),
      child: column,
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final HistoricalPeriod selected;
  final void Function(HistoricalPeriod) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _GlowChip(
              label: '24 giờ',
              isSelected: selected == HistoricalPeriod.last24Hours,
              onTap: () => onChanged(HistoricalPeriod.last24Hours),
            ),
            const SizedBox(width: 8),
            _GlowChip(
              label: '7 ngày',
              isSelected: selected == HistoricalPeriod.last7Days,
              onTap: () => onChanged(HistoricalPeriod.last7Days),
            ),
            const SizedBox(width: 8),
            _GlowChip(
              label: '30 ngày',
              isSelected: selected == HistoricalPeriod.last30Days,
              onTap: () => onChanged(HistoricalPeriod.last30Days),
            ),
          ],
        ),
      );
}

class _ParameterSelector extends StatelessWidget {
  const _ParameterSelector({required this.selected, required this.onChanged});

  final WaterQualityParameter selected;
  final void Function(WaterQualityParameter) onChanged;

  @override
  Widget build(BuildContext context) {
    const params = WaterQualityParameter.values;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final param in params)
            _ParamChip(
              icon: _iconFor(param),
              label: _labelFor(param),
              isSelected: selected == param,
              onTap: () => onChanged(param),
            ),
        ],
      ),
    );
  }

  String _labelFor(WaterQualityParameter param) => switch (param) {
        WaterQualityParameter.temperature => 'Nhiệt độ',
        WaterQualityParameter.salinity => 'Độ mặn / TDS',
        WaterQualityParameter.ph => 'pH',
        WaterQualityParameter.dissolvedOxygen => 'O₂',
        WaterQualityParameter.ammonia => 'NH₃',
        WaterQualityParameter.nitrite => 'NO₂',
        WaterQualityParameter.kh => 'KH',
        WaterQualityParameter.calcium => 'Ca',
        WaterQualityParameter.magnesium => 'Mg',
      };

  IconData _iconFor(WaterQualityParameter param) => switch (param) {
        WaterQualityParameter.temperature => Icons.thermostat_outlined,
        WaterQualityParameter.salinity => Icons.waves_rounded,
        WaterQualityParameter.ph => Icons.water_drop_outlined,
        WaterQualityParameter.dissolvedOxygen => Icons.air_rounded,
        WaterQualityParameter.ammonia => Icons.science_outlined,
        WaterQualityParameter.nitrite => Icons.science_outlined,
        WaterQualityParameter.kh => Icons.water_outlined,
        WaterQualityParameter.calcium => Icons.grain_outlined,
        WaterQualityParameter.magnesium => Icons.grain_outlined,
      };
}

class _ParamChip extends StatelessWidget {
  const _ParamChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD8F3E3) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF8ED4A8) : kHomeBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? kHomePrimaryDark : kHomeTextSub,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? kHomePrimaryDark : kHomeTextSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowChip extends StatelessWidget {
  const _GlowChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? kHomePrimary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? kHomePrimary : kHomeBorder,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kHomeBlue.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : kHomeTextSub,
            ),
          ),
        ),
      );
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({
    required this.readings,
    required this.thresholds,
    required this.parameter,
    required this.period,
    required this.isLoading,
  });

  final List<WaterQuality> readings;
  final WaterQualityThresholds thresholds;
  final WaterQualityParameter parameter;
  final HistoricalPeriod period;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _ChartLoading();
    final forParam = readings.where(_hasValue).toList();
    if (forParam.isEmpty) return const _ChartEmpty();
    return _ChartContent(
      readings: forParam,
      thresholds: thresholds,
      parameter: parameter,
      period: period,
    );
  }

  bool _hasValue(WaterQuality r) => switch (parameter) {
        WaterQualityParameter.temperature => r.temperature != 0,
        WaterQualityParameter.ph => r.ph != 0,
        WaterQualityParameter.dissolvedOxygen => r.dissolvedOxygen != 0,
        WaterQualityParameter.salinity => r.salinity != 0,
        WaterQualityParameter.ammonia => r.ammonia != 0,
        WaterQualityParameter.nitrite => r.nitrite != 0,
        WaterQualityParameter.kh => r.kh != 0,
        WaterQualityParameter.calcium => r.calcium != 0,
        WaterQualityParameter.magnesium => r.magnesium != 0,
      };
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: kHomeBlue, strokeWidth: 2),
        ),
      );
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kHomeBlue.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: kHomeBlue.withValues(alpha: 0.45)),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  size: 26,
                  color: kHomeBlueLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có dữ liệu lịch sử',
                style: TextStyle(
                  color: const Color(0xFF5A7184),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Dữ liệu sẽ xuất hiện sau khi cảm biến ghi nhận.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kHomeTextHint, fontSize: 12),
              ),
            ],
          ),
        ),
      );
}

class _ChartContent extends StatelessWidget {
  const _ChartContent({
    required this.readings,
    required this.thresholds,
    required this.parameter,
    required this.period,
  });

  final List<WaterQuality> readings;
  final WaterQualityThresholds thresholds;
  final WaterQualityParameter parameter;
  final HistoricalPeriod period;

  @override
  Widget build(BuildContext context) {
    final sorted = [...readings]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (sorted.isEmpty) return const _ChartEmpty();

    var minX = sorted.first.timestamp.millisecondsSinceEpoch.toDouble();
    var maxX = sorted.last.timestamp.millisecondsSinceEpoch.toDouble();
    // Một điểm hoặc cùng timestamp → giãn trục X để interval không = 0.
    if (maxX <= minX) {
      minX -= const Duration(hours: 1).inMilliseconds.toDouble();
      maxX += const Duration(hours: 1).inMilliseconds.toDouble();
    }

    final spots = sorted
        .map(
          (r) => FlSpot(
            r.timestamp.millisecondsSinceEpoch.toDouble(),
            _getValue(r),
          ),
        )
        .toList();

    final values = spots.map((s) => s.y).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final thresholdMinVal = _thresholdMin();
    final thresholdMaxVal = _thresholdMax();

    final allY = [minValue, maxValue, ?thresholdMinVal, ?thresholdMaxVal];
    var yMin = allY.reduce((a, b) => a < b ? a : b) - _yPadding();
    var yMax = allY.reduce((a, b) => a > b ? a : b) + _yPadding();
    if (yMax <= yMin) {
      yMin -= 1;
      yMax += 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: SizedBox(
        height: 220,
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 1,
          maxScale: 5,
          child: LineChart(
            _buildChartData(
              sorted: sorted,
              spots: spots,
              minX: minX,
              maxX: maxX,
              minY: yMin,
              maxY: yMax,
            ),
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData({
    required List<WaterQuality> sorted,
    required List<FlSpot> spots,
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
  }) =>
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          horizontalInterval: _gridInterval(minY, maxY),
          getDrawingHorizontalLine: (_) => FlLine(
            color: kHomeBorderBlue.withValues(alpha: 0.35),
            strokeWidth: 0.8,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: kHomeBorderBlue.withValues(alpha: 0.2),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.45)),
            left: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.45)),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: _xAxisInterval(minX, maxX),
              getTitlesWidget: _xTitle,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: _gridInterval(minY, maxY),
              getTitlesWidget: _yTitle,
            ),
          ),
        ),
        extraLinesData: const ExtraLinesData(horizontalLines: []),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFF0D7A5F),
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final idx = sorted.indexWhere(
                (r) => r.timestamp.millisecondsSinceEpoch.toDouble() == spot.x,
              );
              final ts = idx >= 0 ? sorted[idx].timestamp : null;
              final tsLabel =
                  ts != null ? DateFormat('dd/MM HH:mm').format(ts) : '';
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)}\n$tsLabel',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF1B8A5A),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) {
                final last = index == spots.length - 1;
                if (!last) {
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeColor: Colors.transparent,
                  );
                }
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: const Color(0xFF1B8A5A),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2BB673).withValues(alpha: 0.28),
                  const Color(0xFF2BB673).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _xTitle(double value, TitleMeta meta) {
    final ts = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    final label = switch (period) {
      HistoricalPeriod.last24Hours => DateFormat('HH:mm').format(ts),
      HistoricalPeriod.last7Days ||
      HistoricalPeriod.last30Days =>
        DateFormat('dd/MM').format(ts),
    };
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF5A7184),
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _yTitle(double value, TitleMeta meta) => SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: const Color(0xFF5A7184),
            fontSize: 9,
          ),
        ),
      );

  double _getValue(WaterQuality reading) => switch (parameter) {
        WaterQualityParameter.temperature => reading.temperature,
        WaterQualityParameter.ph => reading.ph,
        WaterQualityParameter.dissolvedOxygen => reading.dissolvedOxygen,
        WaterQualityParameter.salinity => reading.salinity,
        WaterQualityParameter.ammonia => reading.ammonia,
        WaterQualityParameter.nitrite => reading.nitrite,
        WaterQualityParameter.kh => reading.kh,
        WaterQualityParameter.calcium => reading.calcium,
        WaterQualityParameter.magnesium => reading.magnesium,
      };

  double? _thresholdMin() => switch (parameter) {
        WaterQualityParameter.temperature => thresholds.minTemperature,
        WaterQualityParameter.ph => thresholds.minPh,
        WaterQualityParameter.dissolvedOxygen => thresholds.minDissolvedOxygen,
        WaterQualityParameter.salinity => thresholds.minSalinity,
        WaterQualityParameter.ammonia => null,
        WaterQualityParameter.nitrite => null,
        WaterQualityParameter.kh => 7,
        WaterQualityParameter.calcium => 380,
        WaterQualityParameter.magnesium => 1200,
      };

  double? _thresholdMax() => switch (parameter) {
        WaterQualityParameter.temperature => thresholds.maxTemperature,
        WaterQualityParameter.ph => thresholds.maxPh,
        WaterQualityParameter.dissolvedOxygen => null,
        WaterQualityParameter.salinity => thresholds.maxSalinity,
        WaterQualityParameter.ammonia => 0.1,
        WaterQualityParameter.nitrite => 0.2,
        WaterQualityParameter.kh => 10,
        WaterQualityParameter.calcium => 460,
        WaterQualityParameter.magnesium => 1400,
      };

  double _yPadding() => switch (parameter) {
        WaterQualityParameter.temperature => 1,
        WaterQualityParameter.ph => 0.5,
        WaterQualityParameter.dissolvedOxygen => 0.5,
        WaterQualityParameter.salinity => 2,
        WaterQualityParameter.ammonia => 0.02,
        WaterQualityParameter.nitrite => 0.02,
        WaterQualityParameter.kh => 0.5,
        WaterQualityParameter.calcium => 20,
        WaterQualityParameter.magnesium => 40,
      };

  double _gridInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 0) return 1;
    if (range <= 2) return 0.5;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    final interval = (range / 5).roundToDouble();
    return interval == 0 ? 1 : interval;
  }

  double _xAxisInterval(double minX, double maxX) {
    final range = (maxX - minX).abs();
    if (range <= 0) {
      return const Duration(hours: 1).inMilliseconds.toDouble();
    }
    final interval = range / 5;
    return interval == 0
        ? const Duration(minutes: 1).inMilliseconds.toDouble()
        : interval;
  }
}
