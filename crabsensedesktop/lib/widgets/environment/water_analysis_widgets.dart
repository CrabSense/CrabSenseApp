import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/water_analysis.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';

const kWaBlue = Color(0xFF2495E8);
const kWaAmber = Color(0xFFF5B700);
const kWaRed = Color(0xFFEF4444);
const kWaSlate = Color(0xFF94A3B8);

Color waStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'GOOD':
    case 'NORMAL':
      return status.toUpperCase() == 'GOOD'
          ? DashboardColors.brandGreen
          : kWaBlue;
    case 'MONITORING':
    case 'WATCH':
      return kWaAmber;
    case 'WARNING':
    case 'ALERT':
      return const Color(0xFFF59E0B);
    case 'CRITICAL':
    case 'DANGER':
      return kWaRed;
    default:
      return kWaSlate;
  }
}

String waClock(DateTime? dt, {bool withSeconds = false}) {
  if (dt == null) return '—';
  final l = dt.isUtc ? dt.toLocal() : dt;
  String two(int v) => v.toString().padLeft(2, '0');
  final base =
      '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  return withSeconds ? '$base:${two(l.second)}' : base;
}

String waDuration(Duration? d) {
  if (d == null) return 'Không xác định';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) {
    return m == 0 ? '$h giờ' : '$h giờ ${m.toString().padLeft(2, '0')} phút';
  }
  if (d.inMinutes <= 0) return '$s giây';
  return s == 0 ? '$m phút' : '$m phút $s giây';
}

String waMmss(int? seconds) {
  final v = seconds ?? 0;
  final m = (v ~/ 60).toString().padLeft(2, '0');
  final s = (v % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

IconData waStationIcon(String code) => switch (code) {
      'controller' => Icons.memory_outlined,
      'samplePump' => Icons.water_drop_outlined,
      'reagentPump1' => Icons.science_outlined,
      'reagentPump2' => Icons.science,
      'drainValve' => Icons.water,
      'camera' => Icons.photo_camera_outlined,
      'ai' => Icons.auto_awesome_outlined,
      _ => Icons.sensors_outlined,
    };

class WaSectionCard extends StatelessWidget {
  const WaSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
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
                      style: bvText(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: bvText(
                          fontSize: 12,
                          color: DashboardColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class WaSkeletonBox extends StatelessWidget {
  const WaSkeletonBox({super.key, this.height = 88, this.radius = 14});
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
    );
  }
}

class AnalysisResultCard extends StatelessWidget {
  const AnalysisResultCard({super.key, required this.metric});

  final WaterAnalysisMetric metric;

  @override
  Widget build(BuildContext context) {
    final color = waStatusColor(metric.status);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 18, color: DashboardColors.brand),
              const SizedBox(width: 8),
              Text(
                metric.label,
                style: bvText(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                metric.displayValue,
                style: bvText(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                  height: 1,
                ),
              ),
              if (metric.displayUnit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  metric.displayUnit,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          MgmtStatusBadge(label: metric.statusLabel, color: color),
          if (metric.thresholdLabel != null &&
              metric.thresholdLabel!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ngưỡng: ${metric.thresholdLabel}',
              style: bvText(fontSize: 12, color: DashboardColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class AnalyteSelector extends StatelessWidget {
  const AnalyteSelector({
    super.key,
    required this.assays,
    required this.selected,
    required this.onSelected,
    this.allLabel = 'Phân tích tất cả',
    this.selectAll = false,
    this.onSelectAll,
  });

  final List<WaterAnalysisAssay> assays;
  final String selected;
  final ValueChanged<String> onSelected;
  final String allLabel;
  final bool selectAll;
  final VoidCallback? onSelectAll;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in assays)
          _chip(
            label: a.label,
            active: !selectAll && selected.toUpperCase() == a.analyte.toUpperCase(),
            enabled: a.configured,
            onTap: a.configured ? () => onSelected(a.analyte) : null,
          ),
        _chip(
          label: allLabel,
          active: selectAll,
          enabled: false,
          onTap: onSelectAll,
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    final bg = active
        ? DashboardColors.brand
        : enabled
            ? Colors.white
            : DashboardColors.lightMint;
    final fg = active
        ? Colors.white
        : enabled
            ? DashboardColors.textPrimary
            : kWaSlate;
    return Tooltip(
      message: enabled
          ? label
          : 'Chưa cấu hình — module phần cứng chưa sẵn sàng.',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: active
                    ? DashboardColors.brand
                    : DashboardColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                if (!enabled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Chưa cấu hình',
                      style: bvText(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kWaSlate,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnalysisWorkflowStepper extends StatelessWidget {
  const AnalysisWorkflowStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.running,
    this.failed = false,
    this.vertical = false,
  });

  final List<WaterAnalysisStepDef> steps;
  final int currentStep;
  final bool running;
  final bool failed;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final defs = steps.isNotEmpty
        ? steps
        : List.generate(
            WaterAnalysisSteps.labels.length,
            (i) => WaterAnalysisStepDef(
              index: i + 1,
              label: WaterAnalysisSteps.labels[i],
              command: '',
            ),
          );
    if (vertical) {
      return Column(
        children: [
          for (var i = 0; i < defs.length; i++) ...[
            _stepTile(defs[i], i),
            if (i < defs.length - 1)
              Container(
                width: 2,
                height: 16,
                margin: const EdgeInsets.only(left: 13),
                color: _lineColor(defs[i]),
              ),
          ],
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < defs.length; i++) ...[
            _circle(defs[i]),
            if (i < defs.length - 1)
              Container(
                width: 28,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: _lineColor(defs[i]),
              ),
          ],
        ],
      ),
    );
  }

  Color _lineColor(WaterAnalysisStepDef s) {
    final done = running && currentStep > s.index;
    return done ? DashboardColors.brandGreen : const Color(0xFFE2E8F0);
  }

  Widget _circle(WaterAnalysisStepDef s) {
    final done = running && currentStep > s.index;
    final current = running && currentStep == s.index;
    final err = failed && currentStep == s.index;
    final color = err
        ? kWaRed
        : done
            ? DashboardColors.brandGreen
            : current
                ? DashboardColors.brand
                : kWaSlate;
    return Semantics(
      button: true,
      label: 'Bước ${s.index}: ${s.label}',
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done || current || err
                  ? color
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : err
                    ? const Icon(Icons.close, size: 14, color: Colors.white)
                    : Text(
                        '${s.index}',
                        style: bvText(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: current ? Colors.white : color,
                        ),
                      ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              s.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bvText(
                fontSize: 10.5,
                fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                color: current ? DashboardColors.brand : DashboardColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTile(WaterAnalysisStepDef s, int i) {
    final done = running && currentStep > s.index;
    final current = running && currentStep == s.index;
    return Row(
      children: [
        _circle(s),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            s.label,
            style: bvText(
              fontSize: 13,
              fontWeight: current ? FontWeight.w700 : FontWeight.w500,
              color: done || current
                  ? DashboardColors.textPrimary
                  : DashboardColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class AnalysisHistoryTable extends StatelessWidget {
  const AnalysisHistoryTable({
    super.key,
    required this.rows,
    required this.onOpen,
    this.asCards = false,
  });

  final List<WaterAnalysisRun> rows;
  final ValueChanged<WaterAnalysisRun> onOpen;
  final bool asCards;

  @override
  Widget build(BuildContext context) {
    if (asCards) {
      return Column(
        children: [
          for (final r in rows) ...[
            _card(r),
            const SizedBox(height: 8),
          ],
        ],
      );
    }
    return Column(
      children: [
        _head(),
        const SizedBox(height: 6),
        for (final r in rows) _row(r),
      ],
    );
  }

  Widget _head() {
    Widget cell(String t, {int flex = 2}) => Expanded(
          flex: flex,
          child: Text(
            t,
            style: bvText(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          cell('THỜI GIAN', flex: 3),
          cell('CHỈ TIÊU', flex: 2),
          cell('KẾT QUẢ', flex: 2),
          cell('ĐÁNH GIÁ', flex: 2),
          cell('NGƯỜI THỰC HIỆN', flex: 2),
        ],
      ),
    );
  }

  WaterAnalysisMetric? _primary(WaterAnalysisRun r) {
    final code = (r.analyte ?? 'no2').toLowerCase();
    return r.metricOf(code) ??
        r.metrics.where((m) => m.value != null).firstOrNull;
  }

  Widget _row(WaterAnalysisRun r) {
    final m = _primary(r);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onOpen(r),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  waClock(r.completedAt ?? r.startedAt),
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  r.displayAnalyte,
                  style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  m == null
                      ? '—'
                      : '${m.displayValue}${m.unit.isEmpty ? '' : ' ${m.unit}'}',
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: MgmtStatusBadge(
                  label: m?.statusLabel ?? r.status,
                  color: waStatusColor(m?.status ?? r.status),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  r.performedBy ?? '—',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(WaterAnalysisRun r) {
    final m = _primary(r);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onOpen(r),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DashboardColors.lightMint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DashboardColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                waClock(r.completedAt ?? r.startedAt),
                style: bvText(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${r.displayAnalyte}  ${m == null ? '—' : '${m.displayValue} ${m.unit}'}',
                style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
              ),
              const SizedBox(height: 6),
              MgmtStatusBadge(
                label: m?.statusLabel ?? r.status,
                color: waStatusColor(m?.status ?? r.status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalysisTrendChart extends StatelessWidget {
  const AnalysisTrendChart({
    super.key,
    required this.points,
    required this.analyteLabel,
    this.threshold,
  });

  final List<WaterAnalysisTrendPoint> points;
  final String analyteLabel;
  final WaterAnalysisThreshold? threshold;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Chưa đủ dữ liệu xu hướng $analyteLabel trong 7 ngày.',
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
        ),
      );
    }
    final maxY = [
      ...points.map((p) => p.value),
      if (threshold?.max != null) threshold!.max!,
      if (threshold?.warningMax != null) threshold!.warningMax!,
    ].reduce((a, b) => a > b ? a : b);
    final yMax = (maxY * 1.4).clamp(0.1, 1000.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Xu hướng $analyteLabel 7 ngày: '
          '${points.map((p) => '${p.date.day}/${p.date.month}=${p.value}').join(' · ')}',
          style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: yMax.toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: DashboardColors.cardBorder,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(v < 1 ? 2 : 0),
                      style: bvText(fontSize: 10, color: kWaSlate),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final i = v.round();
                      if (i < 0 || i >= points.length) return const SizedBox.shrink();
                      final d = points[i].date.toLocal();
                      return Text(
                        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
                        style: bvText(fontSize: 10, color: kWaSlate),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final i = s.x.round().clamp(0, points.length - 1);
                    final p = points[i];
                    return LineTooltipItem(
                      '${waClock(p.date)}\n$analyteLabel: ${p.value} ${threshold?.unit ?? ''}\n${p.statusLabel}'
                      '${p.testCode == null ? '' : '\n${p.testCode}'}',
                      bvText(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (threshold?.max != null)
                    HorizontalLine(
                      y: threshold!.max!,
                      color: kWaRed.withValues(alpha: 0.55),
                      strokeWidth: 1,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: bvText(fontSize: 10, color: kWaRed),
                        labelResolver: (_) =>
                            'Ngưỡng ${threshold!.max}${threshold!.unit.isEmpty ? '' : ' ${threshold!.unit}'}',
                      ),
                    ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].value),
                  ],
                  isCurved: true,
                  color: DashboardColors.brand,
                  barWidth: 2.4,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) {
                      final i = spot.x.round().clamp(0, points.length - 1);
                      return FlDotCirclePainter(
                        radius: 3.5,
                        color: waStatusColor(points[i].status),
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: DashboardColors.brand.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnalysisPrerequisitePanel extends StatelessWidget {
  const AnalysisPrerequisitePanel({
    super.key,
    required this.blockers,
    required this.onRecheck,
  });

  final List<WaterAnalysisBlocker> blockers;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final busy = blockers.any((b) => b.code == 'busy');
    final color = busy ? kWaAmber : kWaRed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            busy ? '⚠ Hệ thống đang bận.' : '⚠ Chưa thể bắt đầu phân tích',
            style: bvText(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${blockers.length} thành phần chưa sẵn sàng:',
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 8),
          for (final b in blockers)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${b.label}: ${b.reason}',
                style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: MgmtOutlineButton(
              icon: Icons.refresh_rounded,
              label: 'Kiểm tra lại hệ thống',
              onTap: onRecheck,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showSystemDiagnosticDialog({
  required BuildContext context,
  required List<WaterAnalysisStationPart> parts,
  required VoidCallback onRecheck,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Kiểm tra hệ thống phân tích',
          style: bvText(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in parts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        p.ready ? Icons.check_circle : Icons.cancel,
                        size: 18,
                        color: p.ready ? DashboardColors.brandGreen : kWaRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.label,
                          style: bvText(
                            fontSize: 13,
                            color: DashboardColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        p.ready ? 'Phản hồi' : p.stateLabel,
                        style: bvText(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.ready ? DashboardColors.brandGreen : kWaRed,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Không tự chạy hóa chất chỉ để test.',
                style: bvText(fontSize: 12, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: ctx,
                builder: (c2) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text('Test bơm thuốc thử',
                      style: bvText(
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                      )),
                  content: Text(
                    'Thao tác này có thể bơm hóa chất thật. Chỉ chạy khi đã xác nhận buồng thử sẵn sàng.',
                    style: bvText(color: DashboardColors.textPrimary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c2, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c2, true),
                      child: const Text('Xác nhận'),
                    ),
                  ],
                ),
              );
              if (ctx.mounted && ok == true) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Chưa gắn lệnh bơm hóa chất thật — chỉ xác nhận an toàn.',
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Test bơm thuốc thử',
              style: bvText(color: kWaRed, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () {
              onRecheck();
              Navigator.pop(ctx);
            },
            child: const Text('Đóng'),
          ),
        ],
      );
    },
  );
}

// Drawer chi tiết: analysis_detail_drawer.dart

Future<bool> confirmStopAnalysis(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Dừng quy trình?',
        style: bvText(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: DashboardColors.textPrimary,
        ),
      ),
      content: Text(
        'Hệ thống sẽ cố gắng chuyển sang bước xả/làm sạch an toàn. Không dừng đột ngột khi còn hóa chất trong buồng.',
        style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Tiếp tục chạy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Dừng phân tích',
            style: bvText(color: kWaRed, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}

Future<void> showSampleImageLightbox(BuildContext context, String url) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class SampleEditDialog extends StatefulWidget {
  const SampleEditDialog({
    super.key,
    required this.sample,
    required this.sources,
    required this.areaLabel,
  });

  final WaterAnalysisSample sample;
  final List<WaterAnalysisSourceOption> sources;
  final String areaLabel;

  @override
  State<SampleEditDialog> createState() => _SampleEditDialogState();
}

class _SampleEditDialogState extends State<SampleEditDialog> {
  late String _source;
  late final TextEditingController _loc;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _source = widget.sample.sampleSource;
    _loc = TextEditingController(text: widget.sample.sampleLocation ?? '');
    _notes = TextEditingController(text: widget.sample.notes ?? '');
  }

  @override
  void dispose() {
    _loc.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = widget.sources.isNotEmpty
        ? widget.sources
        : const [
            WaterAnalysisSourceOption(code: 'RAS_RETURN', label: 'Nước tuần hoàn RAS'),
          ];
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Chỉnh sửa thông tin mẫu',
        style: bvText(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: DashboardColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Khu vực *',
                style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
            const SizedBox(height: 4),
            Text(
              widget.areaLabel,
              style: bvText(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: DashboardColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text('Nguồn mẫu *',
                style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: sources.any((s) => s.code == _source) ? _source : sources.first.code,
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD8E9E4)),
                ),
              ),
              items: [
                for (final s in sources)
                  DropdownMenuItem(
                    value: s.code,
                    child: Text(
                      s.label,
                      style: bvText(color: DashboardColors.textPrimary),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _source = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loc,
              inputFormatters: [LengthLimitingTextInputFormatter(128)],
              decoration: InputDecoration(
                labelText: 'Vị trí lấy mẫu',
                labelStyle: bvText(color: DashboardColors.textMuted),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: bvText(color: DashboardColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                labelStyle: bvText(color: DashboardColors.textMuted),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: bvText(color: DashboardColors.textPrimary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        MgmtPrimaryButton(
          label: 'Lưu',
          onTap: () => Navigator.pop(context, (
            _source,
            _loc.text.trim(),
            _notes.text.trim(),
          )),
        ),
      ],
    );
  }
}
