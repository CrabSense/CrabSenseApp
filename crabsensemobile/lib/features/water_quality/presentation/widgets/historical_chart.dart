import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/water_quality.dart';
import '../../domain/entities/water_quality_thresholds.dart';
import '../../domain/repositories/water_quality_repository.dart';

/// Water quality parameter selector enum.
///
/// Used by [HistoricalChart] to determine which sensor value to plot.
enum WaterQualityParameter { temperature, ph, dissolvedOxygen, salinity }

/// A historical line chart for water quality parameters.
///
/// Displays time-series data for a selected [WaterQualityParameter] over
/// the chosen [HistoricalPeriod]. Features include threshold lines,
/// alert markers, zoom/pan, and touch tooltips.
///
/// Requirements: 8.5
class HistoricalChart extends StatefulWidget {
  const HistoricalChart({
    required this.readings,
    required this.thresholds,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    super.key,
    this.isLoading = false,
  });

  final List<WaterQuality> readings;
  final WaterQualityThresholds thresholds;
  final HistoricalPeriod selectedPeriod;
  final void Function(HistoricalPeriod) onPeriodChanged;
  final bool isLoading;

  @override
  State<HistoricalChart> createState() => _HistoricalChartState();
}

class _HistoricalChartState extends State<HistoricalChart> {
  WaterQualityParameter _selectedParameter = WaterQualityParameter.temperature;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CrabSenseColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CrabSenseColors.primary.withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PeriodSelector(selected: widget.selectedPeriod, onChanged: widget.onPeriodChanged),
        const Divider(height: 1, color: CrabSenseColors.outline),
        _ParameterSelector(
          selected: _selectedParameter,
          onChanged: (p) => setState(() => _selectedParameter = p),
        ),
        const Divider(height: 1, color: CrabSenseColors.outline),
        _ChartBody(
          readings: widget.readings,
          thresholds: widget.thresholds,
          parameter: _selectedParameter,
          period: widget.selectedPeriod,
          isLoading: widget.isLoading,
        ),
      ],
    ),
  );
}

// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final HistoricalPeriod selected;
  final void Function(HistoricalPeriod) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        _PeriodChip(
          label: '24h',
          isSelected: selected == HistoricalPeriod.last24Hours,
          onTap: () => onChanged(HistoricalPeriod.last24Hours),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: '7d',
          isSelected: selected == HistoricalPeriod.last7Days,
          onTap: () => onChanged(HistoricalPeriod.last7Days),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: '30d',
          isSelected: selected == HistoricalPeriod.last30Days,
          onTap: () => onChanged(HistoricalPeriod.last30Days),
        ),
      ],
    ),
  );
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? CrabSenseColors.primary.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? CrabSenseColors.primary : CrabSenseColors.outline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? CrabSenseColors.primary : CrabSenseColors.textSecondary,
        ),
      ),
    ),
  );
}

// ── Parameter selector ────────────────────────────────────────────────────────

class _ParameterSelector extends StatelessWidget {
  const _ParameterSelector({required this.selected, required this.onChanged});

  final WaterQualityParameter selected;
  final void Function(WaterQualityParameter) onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: WaterQualityParameter.values
          .map(
            (param) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ParameterChip(
                label: _labelFor(param),
                isSelected: selected == param,
                onTap: () => onChanged(param),
              ),
            ),
          )
          .toList(),
    ),
  );

  String _labelFor(WaterQualityParameter param) {
    switch (param) {
      case WaterQualityParameter.temperature:
        return 'Temperature';
      case WaterQualityParameter.ph:
        return 'pH';
      case WaterQualityParameter.dissolvedOxygen:
        return 'DO';
      case WaterQualityParameter.salinity:
        return 'Salinity';
    }
  }
}

class _ParameterChip extends StatelessWidget {
  const _ParameterChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? CrabSenseColors.primary.withValues(alpha: 0.2)
            : CrabSenseColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? CrabSenseColors.primary : CrabSenseColors.outline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? CrabSenseColors.primary : CrabSenseColors.textSecondary,
        ),
      ),
    ),
  );
}

// ── Chart body ────────────────────────────────────────────────────────────────

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
    if (isLoading) {
      return const _ChartLoading();
    }

    if (readings.isEmpty) {
      return const _ChartEmpty();
    }

    return _ChartContent(
      readings: readings,
      thresholds: thresholds,
      parameter: parameter,
      period: period,
    );
  }
}

// ── Loading state ─────────────────────────────────────────────────────────────

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 220,
    child: Center(child: CircularProgressIndicator(color: CrabSenseColors.primary, strokeWidth: 2)),
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.show_chart, size: 36, color: CrabSenseColors.textDisabled),
            const SizedBox(height: 8),
            Text(
              'No historical data available',
              style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart content ─────────────────────────────────────────────────────────────

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

    if (sorted.isEmpty) {
      return const _ChartEmpty();
    }

    final minX = sorted.first.timestamp.millisecondsSinceEpoch.toDouble();
    final maxX = sorted.last.timestamp.millisecondsSinceEpoch.toDouble();

    final spots = sorted
        .map((r) => FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), _getValue(r)))
        .toList();

    final values = spots.map((s) => s.y).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final thresholdMinVal = _thresholdMin();
    final thresholdMaxVal = _thresholdMax();

    // Expand Y range to always include thresholds + padding.
    final allY = [minValue, maxValue, ?thresholdMinVal, ?thresholdMaxVal];
    final yMin = allY.reduce((a, b) => a < b ? a : b) - _yPadding();
    final yMax = allY.reduce((a, b) => a > b ? a : b) + _yPadding();

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
  }) => LineChartData(
    minX: minX,
    maxX: maxX,
    minY: minY,
    maxY: maxY,
    clipData: const FlClipData.all(),
    gridData: FlGridData(
      horizontalInterval: _gridInterval(minY, maxY),
      getDrawingHorizontalLine: (_) =>
          FlLine(color: CrabSenseColors.outline.withValues(alpha: 0.5), strokeWidth: 0.8),
      getDrawingVerticalLine: (_) =>
          FlLine(color: CrabSenseColors.outline.withValues(alpha: 0.3), strokeWidth: 0.5),
    ),
    borderData: FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: CrabSenseColors.outline.withValues(alpha: 0.6)),
        left: BorderSide(color: CrabSenseColors.outline.withValues(alpha: 0.6)),
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
    extraLinesData: ExtraLinesData(horizontalLines: _buildThresholdLines()),
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: CrabSenseColors.surfaceVariant.withValues(alpha: 0.95),
        tooltipRoundedRadius: 8,
        getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
          final idx = sorted.indexWhere(
            (r) => r.timestamp.millisecondsSinceEpoch.toDouble() == spot.x,
          );
          final ts = idx >= 0 ? sorted[idx].timestamp : null;
          final tsLabel = ts != null ? DateFormat('dd/MM HH:mm').format(ts) : '';
          return LineTooltipItem(
            '${spot.y.toStringAsFixed(2)} ${_unit()}\n$tsLabel',
            const TextStyle(color: CrabSenseColors.textPrimary, fontSize: 11, height: 1.5),
          );
        }).toList(),
      ),
    ),
    lineBarsData: [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: CrabSenseColors.primary,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          getDotPainter: (spot, percent, bar, index) {
            final reading = index < sorted.length ? sorted[index] : null;
            final isAlert = reading?.isAlertTriggered ?? false;
            if (isAlert) {
              return FlDotCirclePainter(
                radius: 5,
                color: CrabSenseColors.error,
                strokeWidth: 1.5,
                strokeColor: CrabSenseColors.error.withValues(alpha: 0.6),
              );
            }
            // Transparent dot for non-alert points: clean look.
            return FlDotCirclePainter(
              radius: 0,
              color: Colors.transparent,
              strokeColor: Colors.transparent,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CrabSenseColors.primary.withValues(alpha: 0.25),
              CrabSenseColors.primary.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    ],
  );

  // ── Axis label helpers ──────────────────────────────────────────────────

  Widget _xTitle(double value, TitleMeta meta) {
    final ts = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    String label;
    switch (period) {
      case HistoricalPeriod.last24Hours:
        label = DateFormat('HH:mm').format(ts);
      case HistoricalPeriod.last7Days:
      case HistoricalPeriod.last30Days:
        label = DateFormat('dd/MM').format(ts);
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: Text(label, style: const TextStyle(color: CrabSenseColors.textDisabled, fontSize: 9)),
    );
  }

  Widget _yTitle(double value, TitleMeta meta) => SideTitleWidget(
    axisSide: meta.axisSide,
    space: 4,
    child: Text(
      value.toStringAsFixed(1),
      style: const TextStyle(color: CrabSenseColors.textDisabled, fontSize: 9),
    ),
  );

  // ── Threshold lines ─────────────────────────────────────────────────────

  List<HorizontalLine> _buildThresholdLines() {
    final lines = <HorizontalLine>[];
    final minVal = _thresholdMin();
    final maxVal = _thresholdMax();

    if (minVal != null) {
      lines.add(
        HorizontalLine(
          y: minVal,
          color: CrabSenseColors.warning.withValues(alpha: 0.8),
          strokeWidth: 1.5,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            style: const TextStyle(color: CrabSenseColors.warning, fontSize: 9),
            labelResolver: (line) => 'min ${line.y.toStringAsFixed(1)}',
          ),
        ),
      );
    }

    if (maxVal != null) {
      lines.add(
        HorizontalLine(
          y: maxVal,
          color: CrabSenseColors.warning.withValues(alpha: 0.8),
          strokeWidth: 1.5,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            style: const TextStyle(color: CrabSenseColors.warning, fontSize: 9),
            labelResolver: (line) => 'max ${line.y.toStringAsFixed(1)}',
          ),
        ),
      );
    }

    return lines;
  }

  // ── Value extraction ────────────────────────────────────────────────────

  double _getValue(WaterQuality reading) {
    switch (parameter) {
      case WaterQualityParameter.temperature:
        return reading.temperature;
      case WaterQualityParameter.ph:
        return reading.ph;
      case WaterQualityParameter.dissolvedOxygen:
        return reading.dissolvedOxygen;
      case WaterQualityParameter.salinity:
        return reading.salinity;
    }
  }

  double? _thresholdMin() {
    switch (parameter) {
      case WaterQualityParameter.temperature:
        return thresholds.minTemperature;
      case WaterQualityParameter.ph:
        return thresholds.minPh;
      case WaterQualityParameter.dissolvedOxygen:
        return thresholds.minDissolvedOxygen;
      case WaterQualityParameter.salinity:
        return thresholds.minSalinity;
    }
  }

  double? _thresholdMax() {
    switch (parameter) {
      case WaterQualityParameter.temperature:
        return thresholds.maxTemperature;
      case WaterQualityParameter.ph:
        return thresholds.maxPh;
      case WaterQualityParameter.dissolvedOxygen:
        return null; // DO has min threshold only
      case WaterQualityParameter.salinity:
        return thresholds.maxSalinity;
    }
  }

  String _unit() {
    switch (parameter) {
      case WaterQualityParameter.temperature:
        return '°C';
      case WaterQualityParameter.ph:
        return 'pH';
      case WaterQualityParameter.dissolvedOxygen:
        return 'mg/L';
      case WaterQualityParameter.salinity:
        return 'ppt';
    }
  }

  // ── Interval helpers ────────────────────────────────────────────────────

  double _yPadding() {
    switch (parameter) {
      case WaterQualityParameter.temperature:
        return 1;
      case WaterQualityParameter.ph:
        return 0.5;
      case WaterQualityParameter.dissolvedOxygen:
        return 0.5;
      case WaterQualityParameter.salinity:
        return 2;
    }
  }

  double _gridInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 2) return 0.5;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    return (range / 5).roundToDouble();
  }

  double _xAxisInterval(double minX, double maxX) {
    // Aim for ~5 x-axis labels.
    return (maxX - minX) / 5;
  }
}
