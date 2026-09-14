import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_dashboard_overview.dart';
import '../../services/dashboard_env_trend_service.dart';
import '../../services/farm_dashboard_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/ph_temp_line_chart.dart';
import 'glass_card.dart';

class ChartsSection extends StatefulWidget {
  const ChartsSection({super.key, required this.dashboardService});

  final FarmDashboardService dashboardService;

  @override
  State<ChartsSection> createState() => _ChartsSectionState();
}

class _ChartsSectionState extends State<ChartsSection> {
  @override
  void initState() {
    super.initState();
    widget.dashboardService.envTrend.addListener(_onTrend);
    widget.dashboardService.addListener(_onTrend);
  }

  @override
  void dispose() {
    widget.dashboardService.envTrend.removeListener(_onTrend);
    widget.dashboardService.removeListener(_onTrend);
    super.dispose();
  }

  void _onTrend() {
    if (mounted) setState(() {});
  }

  FarmDashboardService get svc => widget.dashboardService;
  bool get fromApiLive => svc.envTrend.isLiveApi;

  List<double> get _doData {
    if (svc.liveDoSeries.isNotEmpty) return svc.liveDoSeries;
    final charts = svc.charts;
    if (charts != null && charts.do24h.isNotEmpty) return charts.do24h;
    return const [];
  }

  List<double> get _growthData {
    final charts = svc.charts;
    if (charts != null && charts.growthBars.isNotEmpty) return charts.growthBars;
    return const [];
  }

  List<String> get _chartLabels {
    final charts = svc.charts;
    if (charts != null && charts.labels.isNotEmpty) return charts.labels;
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final trend = svc.envTrend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PhTempChartCard(
                      trend: trend,
                      fromApiLive: fromApiLive,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: DoBarChartCard(data: _doData, isLive: fromApiLive)),
                ],
              );
            }
            return Column(
              children: [
                PhTempChartCard(trend: trend, fromApiLive: fromApiLive),
                const SizedBox(height: 16),
                DoBarChartCard(data: _doData, isLive: fromApiLive),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TempLineChartCard(
                      trend: trend,
                      fromApiLive: fromApiLive,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: GrowthBarChartCard(data: _growthData)),
                ],
              );
            }
            return Column(
              children: [
                TempLineChartCard(trend: trend, fromApiLive: fromApiLive),
                const SizedBox(height: 16),
                GrowthBarChartCard(data: _growthData),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        HealthMultiLineChartCard(charts: svc.charts, chartLabels: _chartLabels),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.legend,
    this.chartHeight = 200,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? legend;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.notoSans(
                color: DashboardColors.healthy,
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (child is PhTempLineChart) child else SizedBox(height: chartHeight, child: child),
          if (legend != null) ...[
            const SizedBox(height: 12),
            Center(child: legend!),
          ],
        ],
      ),
    );
  }
}

class PhTempChartCard extends StatelessWidget {
  const PhTempChartCard({
    super.key,
    required this.trend,
    this.fromApiLive = false,
  });

  final DashboardEnvTrendService trend;
  final bool fromApiLive;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: fromApiLive ? 'Biểu đồ pH & Nhiệt độ (Realtime)' : 'Biểu đồ pH & Nhiệt độ',
      subtitle: fromApiLive
          ? 'Sensor Cloud · cập nhật 3s'
          : 'Realtime · cửa sổ 30 phút',
      chartHeight: 260,
      legend: const PhTempChartLegend(),
      child: PhTempLineChart(
        points: trend.points,
        rangeMinutes: trend.rangeMinutesValue,
      ),
    );
  }
}

class TempLineChartCard extends StatelessWidget {
  const TempLineChartCard({
    super.key,
    required this.trend,
    this.fromApiLive = false,
  });

  final DashboardEnvTrendService trend;
  final bool fromApiLive;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: fromApiLive ? 'Nhiệt độ (Realtime)' : 'Nhiệt độ',
      subtitle: fromApiLive ? 'Sensor Cloud · 3s' : 'Realtime · cập nhật 3s',
      chartHeight: 260,
      legend: const PhTempChartLegend(showPh: false),
      child: PhTempLineChart(
        points: trend.points,
        rangeMinutes: trend.rangeMinutesValue,
        showPh: false,
        showTemp: true,
      ),
    );
  }
}

class DoBarChartCard extends StatelessWidget {
  const DoBarChartCard({super.key, required this.data, this.isLive = false});

  final List<double> data;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty ? 7.0 : (data.reduce((a, b) => a > b ? a : b) + 0.5);
    final minY = data.isEmpty ? 5.0 : (data.reduce((a, b) => a < b ? a : b) - 0.5);

    return _ChartCard(
      title: isLive ? 'DO (Realtime)' : 'Mức Oxy hòa tan (DO)',
      subtitle: isLive ? 'Cập nhật 3s' : null,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: minY,
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
          titlesData: _titlesData(),
          barGroups: List.generate(data.length, (i) {
            final highlight = i == data.length - 1;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i],
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: highlight
                        ? [DashboardColors.monitoring, DashboardColors.molting]
                        : [DashboardColors.blue, DashboardColors.cyan],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class GrowthBarChartCard extends StatelessWidget {
  const GrowthBarChartCard({super.key, required this.data});

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 300.0
        : (data.reduce((a, b) => a > b ? a : b) * 1.2).clamp(50.0, 500.0).toDouble();

    return _ChartCard(
      title: 'Tăng trưởng cua (cân nặng TB)',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: _axisStyle(),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Text('T${i + 1}', style: _axisStyle());
                },
              ),
            ),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          barGroups: List.generate(
            data.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i],
                  width: 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  gradient: DashboardColors.accentGradient,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthMultiLineChartCard extends StatefulWidget {
  const HealthMultiLineChartCard({
    super.key,
    this.charts,
    required this.chartLabels,
  });

  final DashboardChartsDto? charts;
  final List<String> chartLabels;

  @override
  State<HealthMultiLineChartCard> createState() =>
      _HealthMultiLineChartCardState();
}

class _HealthMultiLineChartCardState extends State<HealthMultiLineChartCard> {
  late List<bool> _visible;

  static const _colors = [
    DashboardColors.cyan,
    DashboardColors.blue,
    DashboardColors.purple,
    DashboardColors.healthy,
  ];

  static const _emptyMeta = <(String, Color)>[];
  static const _emptyDatasets = <List<double>>[];

  @override
  void initState() {
    super.initState();
    _visible = [];
    _syncVisible(_seriesCount);
  }

  @override
  void didUpdateWidget(HealthMultiLineChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncVisible(_seriesCount);
  }

  void _syncVisible(int n) {
    while (_visible.length < n) {
      _visible.add(true);
    }
    if (_visible.length > n) {
      _visible = _visible.sublist(0, n);
    }
  }

  int get _seriesCount => _seriesMeta.length;

  List<(String, Color)> get _seriesMeta {
    final c = widget.charts;
    if (c == null) return _emptyMeta;
    final meta = <(String, Color)>[];
    for (var i = 0; i < c.batchHealth.length; i++) {
      if (c.batchHealth[i].values.isEmpty) continue;
      meta.add((c.batchHealth[i].label, _colors[i % _colors.length]));
    }
    if (c.farmHealth.isNotEmpty) {
      meta.add(('Toàn trại', DashboardColors.healthy));
    }
    return meta.isEmpty ? _emptyMeta : meta;
  }

  List<List<double>> get _datasets {
    final c = widget.charts;
    if (c == null) return _emptyDatasets;
    final list = <List<double>>[
      for (final b in c.batchHealth)
        if (b.values.isNotEmpty) b.values,
      if (c.farmHealth.isNotEmpty) c.farmHealth,
    ];
    return list.isEmpty ? _emptyDatasets : list;
  }

  @override
  Widget build(BuildContext context) {
    final meta = _seriesMeta;
    final datasets = _datasets;
    final n = meta.length < datasets.length ? meta.length : datasets.length;
    _syncVisible(n);

    return _ChartCard(
      title: 'Health Score Theo Thời Gian',
      legend: Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < n; i++)
            _healthLegendChip(
              label: meta[i].$1,
              color: meta[i].$2,
              selected: i < _visible.length && _visible[i],
              onSelected: (v) {
                if (i >= _visible.length) return;
                setState(() => _visible[i] = v);
              },
            ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: 80,
          maxY: 100,
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
          titlesData: _titlesData(widget.chartLabels),
          lineBarsData: [
            for (var i = 0; i < n; i++)
              if (i < _visible.length &&
                  _visible[i] &&
                  datasets[i].isNotEmpty)
                _lineBar(datasets[i], meta[i].$2),
          ],
        ),
      ),
    );
  }
}

Widget _healthLegendChip({
  required String label,
  required Color color,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) {
  return FilterChip(
    label: Text(label, style: GoogleFonts.notoSans(fontSize: 10)),
    selected: selected,
    onSelected: onSelected,
    selectedColor: color.withValues(alpha: 0.25),
    checkmarkColor: color,
    labelStyle: TextStyle(
      color: selected ? color : DashboardColors.textMuted,
    ),
    side: BorderSide(color: color.withValues(alpha: 0.4)),
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

LineChartBarData _lineBar(List<double> data, Color color) {
  return LineChartBarData(
    spots: [
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ],
    isCurved: data.length >= 2,
    color: color,
    barWidth: 3,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.02),
        ],
      ),
    ),
  );
}

FlGridData _gridData() => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => FlLine(
        color: DashboardColors.cardBorder.withValues(alpha: 0.5),
        strokeWidth: 1,
      ),
    );

FlTitlesData _titlesData([List<String>? labels]) => FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          getTitlesWidget: (v, _) => Text(
            v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1),
            style: _axisStyle(),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 2,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            final chartLabels = labels ?? const <String>[];
            if (i < 0 || i >= chartLabels.length) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                chartLabels[i],
                style: _axisStyle(),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
    );

TextStyle _axisStyle() => GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 9,
    );
