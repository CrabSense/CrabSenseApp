import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/area_environment_metric.dart';
import '../../../models/box_alert.dart';
import '../../../models/production_models.dart';
import '../../../services/area_environment_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../crab/crab_overview_cards.dart';
import '../../shared/mgmt_ui.dart';
import '../../environment/qualified_environment_cards.dart';
import 'box_labels.dart';

enum SensorTrendRange { h24, d7, d30, custom }

extension on SensorTrendRange {
  String get label => switch (this) {
        SensorTrendRange.h24 => '24 giờ',
        SensorTrendRange.d7 => '7 ngày',
        SensorTrendRange.d30 => '30 ngày',
        SensorTrendRange.custom => 'Tùy chỉnh',
      };

}

class SensorHistoryPoint {
  const SensorHistoryPoint(this.at, this.value);
  final DateTime at;
  final double value;
}

class SensorAlertRow {
  const SensorAlertRow({
    required this.at,
    required this.metric,
    required this.valueText,
    required this.threshold,
    required this.status,
  });

  final DateTime at;
  final String metric;
  final String valueText;
  final String threshold;
  final String status;
}

class SensorHistoryRow {
  const SensorHistoryRow({
    required this.at,
    this.ph,
    this.tds,
    this.temp,
    this.dox,
  });

  final DateTime at;
  final double? ph;
  final double? tds;
  final double? temp;
  final double? dox;
}

class BoxSensorTab extends StatefulWidget {
  const BoxSensorTab({
    super.key,
    required this.box,
    required this.service,
    required this.areaId,
    required this.areaName,
    required this.areaCode,
    required this.rowLabel,
    required this.controllerStatus,
    required this.alerts,
    this.alertsLoading = false,
    this.onOpenSource,
    this.onOpenWaterAnalysis,
    this.onOpenAlerts,
  });

  final BoxRecord box;
  final AreaEnvironmentService service;
  final String areaId;
  final String areaName;
  final String areaCode;
  final String rowLabel;
  final String controllerStatus;
  final List<BoxAlert> alerts;
  final bool alertsLoading;
  final VoidCallback? onOpenSource;
  final VoidCallback? onOpenWaterAnalysis;
  final VoidCallback? onOpenAlerts;

  @override
  State<BoxSensorTab> createState() => _BoxSensorTabState();
}

class _BoxSensorTabState extends State<BoxSensorTab> {
  @override
  void initState(){super.initState();widget.service.addListener(_onUpdate);}
  @override
  void didUpdateWidget(covariant BoxSensorTab oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.service!=widget.service){
      oldWidget.service.removeListener(_onUpdate);widget.service.addListener(_onUpdate);
    }
  }
  void _onUpdate(){if(mounted)setState((){});}
  @override
  void dispose(){widget.service.removeListener(_onUpdate);super.dispose();}
  @override
  Widget build(BuildContext context){
    final data=widget.service.dataForBox(widget.areaId,widget.box.id);
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      OverviewCard(icon:Icons.info_outline,title:'Môi trường RAS chung khu',
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Hộp '+widget.box.boxCode+' · '+widget.areaName),
          const Text('Tất cả hộp và dãy cùng khu dùng chung số liệu đại diện từ vòng tuần hoàn. Không đo riêng hộp.'),
          Wrap(spacing:8,children:[
            MgmtOutlineButton(icon:Icons.refresh,label:'Tải lại',onTap:widget.service.refreshCurrent),
            if(widget.onOpenSource!=null)MgmtOutlineButton(label:'Nguồn',onTap:widget.onOpenSource),
            if(widget.onOpenAlerts!=null)MgmtOutlineButton(label:'Cảnh báo',onTap:widget.onOpenAlerts),
          ]),
        ])),
      const SizedBox(height:12),
      if(widget.service.loading)const LinearProgressIndicator(),
      if(widget.service.error!=null)Text(widget.service.error!),
      QualifiedEnvironmentCards(metrics:data?.metrics ?? const []),
      const SizedBox(height:12),
      const Text('Lịch sử và CSV: dùng Giám sát thời gian thực, chọn cảm biến gốc. Không ghép phép đo theo hộp.'),
      if(widget.onOpenWaterAnalysis!=null)MgmtOutlineButton(label:'Phân tích nước WaterBench',onTap:widget.onOpenWaterAnalysis),
    ]);
  }
}

class SensorSlot {
  const SensorSlot({
    required this.key,
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
    required this.decimals,
    required this.thresholdText,
    this.min,
    this.max,
    this.metric,
  });

  final String key;
  final String label;
  final String unit;
  final IconData icon;
  final Color color;
  final int decimals;
  final String thresholdText;
  final double? min;
  final double? max;
  final AreaEnvironmentMetric? metric;
}

class SensorSourceBanner extends StatelessWidget {
  const SensorSourceBanner({
    super.key,
    required this.boxCode,
    required this.areaName,
    required this.areaCode,
    required this.inherited,
    required this.sourceCode,
    required this.sourceNote,
    this.onOpen,
  });

  final String boxCode;
  final String areaName;
  final String areaCode;
  final bool inherited;
  final String sourceCode;
  final String sourceNote;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final khu = areaName.isNotEmpty ? areaName : areaCode;
    final code = areaCode.isNotEmpty ? areaCode : khu;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final stack = c.maxWidth < 720;
          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: DashboardColors.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  inherited
                      ? 'Hộp $boxCode không có cảm biến nước riêng.\nDữ liệu hiện tại được kế thừa từ cảm biến nước chung của $khu${code.isEmpty ? '' : ' ($code)'} — phạm vi đo: toàn khu $code.'
                      : 'Hộp $boxCode đang dùng cảm biến nước gắn trực tiếp với hộp.',
                  style: bvText(fontSize: 13, height: 1.45, color: DashboardColors.textPrimary),
                ),
              ),
            ],
          );
          final source = Column(
            crossAxisAlignment: stack ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text('Nguồn: ${sourceCode == '—' ? 'Chưa xác định' : sourceCode}', style: bvText(fontWeight: FontWeight.w800)),
              Text(sourceNote, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
              OverviewLinkButton(label: 'Xem thông tin nguồn', onTap: onOpen),
            ],
          );
          if (stack) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: 10), source]);
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 16),
              source,
            ],
          );
        },
      ),
    );
  }
}

class RealtimeSensorMetrics extends StatelessWidget {
  const RealtimeSensorMetrics({
    super.key,
    required this.slots,
    required this.loading,
    required this.stale,
    this.error,
    this.updatedAt,
    this.onRefresh,
    this.onRetry,
    this.onCheckSource,
  });

  final List<SensorSlot> slots;
  final bool loading;
  final bool stale;
  final String? error;
  final DateTime? updatedAt;
  final VoidCallback? onRefresh;
  final VoidCallback? onRetry;
  final VoidCallback? onCheckSource;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.sensors_outlined,
      title: 'Chỉ số cảm biến realtime',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (updatedAt != null)
            Text(
              '${_clock(updatedAt!)}${relativeAgo(updatedAt).isEmpty ? '' : '  (${relativeAgo(updatedAt).replaceFirst('Cập nhật ', '')})'}',
              style: bvText(fontSize: 12, color: DashboardColors.textMuted),
            ),
          IconButton(
            onPressed: onRefresh,
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded, size: 18, color: DashboardColors.brand),
          ),
        ],
      ),
      child: loading
          ? LayoutBuilder(
              builder: (context, c) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < 4; i++)
                    SizedBox(
                      width: _cardW(c.maxWidth),
                      child: Container(height: 118, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12))),
                    ),
                ],
              ),
            )
          : error != null && slots.every((s) => s.metric == null)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Không thể tải dữ liệu realtime.', style: bvText(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    MgmtOutlineButton(icon: Icons.refresh_rounded, label: 'Thử lại', height: 34, onTap: onRetry),
                  ],
                )
              : slots.every((s) => s.metric == null || s.metric!.isMissing)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chưa có dữ liệu cảm biến.', style: bvText(color: DashboardColors.textMuted)),
                        const SizedBox(height: 8),
                        MgmtOutlineButton(label: 'Kiểm tra nguồn cảm biến', height: 34, onTap: onCheckSource),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, c) => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in slots)
                            SizedBox(width: _cardW(c.maxWidth), child: SensorMetricCard(slot: s, stale: stale)),
                        ],
                      ),
                    ),
    );
  }

  double _cardW(double max) {
    if (max >= 720) return (max - 24) / 4;
    if (max >= 420) return (max - 8) / 2;
    return max;
  }

  String _clock(DateTime at) {
    final l = at.isUtc ? at.toLocal() : at;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }
}

class SensorMetricCard extends StatelessWidget {
  const SensorMetricCard({super.key, required this.slot, required this.stale});

  final SensorSlot slot;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final m = slot.metric;
    final missing = m == null || m.isMissing;
    final value = missing ? null : (slot.key == 'ph' ? sanitizePh(m.value) ?? m.value : m.value);
    final status = missing
        ? 'no_data'
        : stale
            ? 'stale'
            : _status(slot, value, m.status);
    final color = sensorSemanticColor(status == 'stale' ? 'watch' : status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(slot.icon, size: 16, color: slot.color),
              const SizedBox(width: 6),
              Text(slot.label, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            missing ? '—' : '${value!.toStringAsFixed(slot.decimals)}${slot.unit.isEmpty ? '' : ' ${slot.unit}'}',
            style: bvText(fontSize: missing ? 16 : 22, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: sensorSemanticFill(status == 'stale' ? 'watch' : status), borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status == 'stale' || status == 'warning' ? Icons.warning_amber_rounded : Icons.circle, size: status == 'stale' || status == 'warning' ? 12 : 6, color: color),
                const SizedBox(width: 5),
                Text(
                  status == 'stale' ? 'Dữ liệu đã cũ' : sensorSemanticLabel(status),
                  style: bvText(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Ngưỡng: ${slot.thresholdText}', style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
          Text(
            missing
                ? 'Chưa có dữ liệu.'
                : stale
                    ? 'Giá trị cuối cùng: ${_clock(m.recordedAt ?? updatedFallback(m))}'
                    : 'Cập nhật: ${_clock(m.recordedAt)}',
            style: bvText(fontSize: 11, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  DateTime? updatedFallback(AreaEnvironmentMetric m) => m.recordedAt;

  String _status(SensorSlot s, double? v, String raw) {
    if (v == null) return 'no_data';
    final r = raw.toLowerCase();
    if (r.contains('warn') || r.contains('alert') || r.contains('crit')) return 'warning';
    if (s.min != null && v < s.min!) return 'warning';
    if (s.max != null && v > s.max!) return 'warning';
    return 'good';
  }

  String _clock(DateTime? at) {
    if (at == null) return '—';
    final l = at.isUtc ? at.toLocal() : at;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }
}

class SensorSystemStatus extends StatelessWidget {
  const SensorSystemStatus({
    super.key,
    required this.sensorStatus,
    required this.controllerStatus,
    this.lastReceivedAt,
  });

  final String sensorStatus;
  final String controllerStatus;
  final DateTime? lastReceivedAt;

  @override
  Widget build(BuildContext context) {
    final latency = lastReceivedAt == null ? null : DateTime.now().difference(lastReceivedAt!.isUtc ? lastReceivedAt!.toLocal() : lastReceivedAt!);
    final stale = isSensorStale(lastReceivedAt);
    final ok = sensorStatus == 'online' && controllerStatus == 'online' && !stale;
    return OverviewCard(
      icon: Icons.cell_tower_rounded,
      title: 'Trạng thái cảm biến',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dot('Sensor', deviceStatusLabel(sensorStatus), deviceStatusColor(sensorStatus)),
          _dot('Controller', deviceStatusLabel(controllerStatus), deviceStatusColor(controllerStatus)),
          _row('Độ trễ dữ liệu', latency == null ? '—' : _latency(latency)),
          _row('Lần nhận data', lastReceivedAt == null ? '—' : _clock(lastReceivedAt!)),
          _row('Chất lượng tín hiệu', stale ? 'Dữ liệu đã cũ' : (ok ? 'Tốt' : 'Không ổn định')),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ok ? const Color(0xFFF3FBF8) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded, size: 16, color: ok ? DashboardColors.brand : const Color(0xFFF5B700)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ok
                        ? 'Hệ thống cảm biến hoạt động bình thường.'
                        : (latency != null && stale
                            ? 'Đã ${_latency(latency)} chưa nhận dữ liệu mới.'
                            : 'Cảm biến chưa ổn định hoặc mất kết nối.'),
                    style: bvText(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(String k, String v, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
            Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  String _latency(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds} giây';
    if (d.inMinutes < 60) return '${d.inMinutes} phút';
    return '${d.inHours} giờ';
  }

  String _clock(DateTime at) {
    final l = at.isUtc ? at.toLocal() : at;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }
}

class SensorTrendSection extends StatelessWidget {
  const SensorTrendSection({
    super.key,
    required this.range,
    required this.slots,
    required this.pointsOf,
    required this.loading,
    required this.onRange,
    this.custom,
    this.error,
    this.onOpenDetail,
  });

  final SensorTrendRange range;
  final DateTimeRange? custom;
  final List<SensorSlot> slots;
  final List<SensorHistoryPoint> Function(SensorSlot slot) pointsOf;
  final bool loading;
  final String? error;
  final ValueChanged<SensorTrendRange> onRange;
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.show_chart_rounded,
      title: 'Biểu đồ xu hướng',
      trailing: Wrap(
        spacing: 6,
        children: [
          for (final r in SensorTrendRange.values)
            _RangeChip(
              label: r == SensorTrendRange.custom && custom != null
                  ? '${fmtDateVn(custom!.start)} – ${fmtDateVn(custom!.end)}'
                  : r.label,
              active: range == r,
              onTap: () => onRange(r),
            ),
        ],
      ),
      child: Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Không tải được biểu đồ xu hướng.', style: bvText(color: const Color(0xFFEF4444))),
            ),
          LayoutBuilder(
            builder: (context, c) {
              final two = c.maxWidth >= 760;
              final charts = [
                for (final s in slots)
                  SensorTrendChart(
                    slot: s,
                    points: pointsOf(s),
                    range: range,
                    loading: loading,
                  ),
              ];
              if (!two) return Column(children: [for (final ch in charts) Padding(padding: const EdgeInsets.only(bottom: 10), child: ch)]);
              return Column(
                children: [
                  Row(children: [Expanded(child: charts[0]), const SizedBox(width: 10), Expanded(child: charts[1])]),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: charts[2]), const SizedBox(width: 10), Expanded(child: charts[3])]),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OverviewLinkButton(label: 'Xem chi tiết', onTap: onOpenDetail),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? DashboardColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? DashboardColors.brand : DashboardColors.cardBorder),
          ),
          child: Text(label, style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? Colors.white : DashboardColors.textMuted)),
        ),
      ),
    );
  }
}

class SensorTrendChart extends StatelessWidget {
  const SensorTrendChart({
    super.key,
    required this.slot,
    required this.points,
    required this.range,
    required this.loading,
  });

  final SensorSlot slot;
  final List<SensorHistoryPoint> points;
  final SensorTrendRange range;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final vals = points.map((e) => e.value);
    final minV = vals.isEmpty ? null : vals.reduce(math.min);
    final maxV = vals.isEmpty ? null : vals.reduce(math.max);
    final avg = vals.isEmpty ? null : vals.reduce((a, b) => a + b) / points.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.unit.isEmpty ? slot.label : '${slot.label} (${slot.unit})',
            style: bvText(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: loading && points.isEmpty
                ? Container(decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(10)))
                : points.length < 2
                    ? Center(child: Text('Chưa có dữ liệu lịch sử.', style: bvText(fontSize: 12, color: DashboardColors.textMuted)))
                    : _Chart(slot: slot, points: points, range: range),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _stat('Min', minV),
              _stat('TB', avg),
              _stat('Max', maxV),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String k, double? v) => Expanded(
        child: Text(
          '$k: ${v == null ? '—' : v.toStringAsFixed(slot.decimals)}',
          style: bvText(fontSize: 11, color: DashboardColors.textMuted),
        ),
      );
}

class _Chart extends StatelessWidget {
  const _Chart({required this.slot, required this.points, required this.range});
  final SensorSlot slot;
  final List<SensorHistoryPoint> points;
  final SensorTrendRange range;

  @override
  Widget build(BuildContext context) {
    final t0 = points.first.at.millisecondsSinceEpoch.toDouble();
    final t1 = points.last.at.millisecondsSinceEpoch.toDouble();
    final span = math.max(1.0, t1 - t0);
    final spots = [for (final p in points) FlSpot((p.at.millisecondsSinceEpoch - t0) / span, p.value)];
    var lo = points.map((p) => p.value).reduce(math.min);
    var hi = points.map((p) => p.value).reduce(math.max);
    if (slot.min != null) lo = math.min(lo, slot.min!);
    if (slot.max != null) hi = math.max(hi, slot.max!);
    final pad = math.max((hi - lo) * 0.15, slot.decimals >= 2 ? 0.05 : 0.4);
    final minY = lo - pad;
    final maxY = hi + pad;
    final interval = math.max((maxY - minY) / 4, slot.decimals >= 2 ? 0.2 : 0.5);
    String xLabel(double x) {
      final d = DateTime.fromMillisecondsSinceEpoch((t0 + x * span).round());
      String two(int v) => v.toString().padLeft(2, '0');
      return range == SensorTrendRange.h24 ? '${two(d.hour)}:${two(d.minute)}' : '${two(d.day)}/${two(d.month)}';
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 1,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(color: DashboardColors.cardBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: interval,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(slot.decimals == 0 ? 0 : (slot.decimals >= 2 ? 1 : 1)), style: bvText(fontSize: 10, color: DashboardColors.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: 1 / 4,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(xLabel(v), style: bvText(fontSize: 10, color: DashboardColors.textMuted)),
              ),
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (slot.min != null)
              HorizontalLine(y: slot.min!, color: const Color(0xFFF5B700).withValues(alpha: 0.55), strokeWidth: 1, dashArray: const [6, 4]),
            if (slot.max != null)
              HorizontalLine(y: slot.max!, color: const Color(0xFFF5B700).withValues(alpha: 0.55), strokeWidth: 1, dashArray: const [6, 4]),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorder: BorderSide(color: DashboardColors.cardBorder),
            tooltipRoundedRadius: 10,
            getTooltipItems: (hit) => [
              for (final s in hit)
                LineTooltipItem(
                  '${fmtDateTimeVn(points[s.spotIndex.clamp(0, points.length - 1)].at)}\n'
                  '${slot.label}: ${s.y.toStringAsFixed(slot.decimals)}${slot.unit.isEmpty ? '' : ' ${slot.unit}'}\n'
                  'Trạng thái: ${_pointStatus(s.y)}',
                  bvText(fontSize: 11, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.18,
            preventCurveOverShooting: true,
            color: slot.color,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (s, _) {
                if (slot.min != null && s.y < slot.min!) return true;
                if (slot.max != null && s.y > slot.max!) return true;
                return points.length <= 40;
              },
              getDotPainter: (s, _, __, ___) {
                final warn = (slot.min != null && s.y < slot.min!) || (slot.max != null && s.y > slot.max!);
                return FlDotCirclePainter(
                  radius: warn ? 3.2 : 2,
                  color: warn ? const Color(0xFFF5B700) : Colors.white,
                  strokeWidth: 1.5,
                  strokeColor: warn ? const Color(0xFFF5B700) : slot.color,
                );
              },
            ),
            belowBarData: BarAreaData(show: true, color: slot.color.withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }

  String _pointStatus(double v) {
    if (slot.min != null && v < slot.min!) return 'Cảnh báo';
    if (slot.max != null && v > slot.max!) return 'Cảnh báo';
    return 'Tốt';
  }
}

class RecentSensorAlerts extends StatelessWidget {
  const RecentSensorAlerts({
    super.key,
    required this.rows,
    required this.loading,
    this.onOpenAll,
  });

  final List<SensorAlertRow> rows;
  final bool loading;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.notifications_none_rounded,
      title: 'Cảnh báo cảm biến gần đây',
      trailing: OverviewLinkButton(label: 'Xem tất cả', onTap: onOpenAll),
      child: loading
          ? Column(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(height: 36, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(8))))])
          : rows.isEmpty
              ? Text('Không có cảnh báo cảm biến gần đây.', style: bvText(color: DashboardColors.textMuted))
              : LayoutBuilder(
                  builder: (context, c) {
                    if (c.maxWidth < 520) {
                      return Column(
                        children: [
                          for (final r in rows.take(6))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fmtDateTimeVn(r.at), style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                                  Text('${r.metric}  ${r.valueText}  ·  ${r.threshold}', style: bvText(fontWeight: FontWeight.w700)),
                                  Text(r.status, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                                ],
                              ),
                            ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _head(),
                        for (final r in rows.take(6))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                _c(fmtDateTimeVn(r.at), 128, muted: true),
                                _c(r.metric, 88, bold: true),
                                _c(r.valueText, 72),
                                _c(r.threshold, 88),
                                Expanded(child: Text(r.status, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700))),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _head() => Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        decoration: BoxDecoration(color: const Color(0xFFF3FBF8), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            _c('THỜI GIAN', 128, header: true),
            _c('CHỈ SỐ', 88, header: true),
            _c('GIÁ TRỊ', 72, header: true),
            _c('NGƯỠNG', 88, header: true),
            Expanded(child: Text('TRẠNG THÁI', style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted))),
          ],
        ),
      );

  Widget _c(String t, double w, {bool muted = false, bool bold = false, bool header = false}) => SizedBox(
        width: w,
        child: Text(
          t,
          style: bvText(
            fontSize: header ? 11 : 12.5,
            fontWeight: bold || header ? FontWeight.w700 : FontWeight.w500,
            color: header || muted ? DashboardColors.textMuted : DashboardColors.textPrimary,
          ),
        ),
      );
}

class RecentSensorHistory extends StatelessWidget {
  const RecentSensorHistory({
    super.key,
    required this.rows,
    required this.loading,
    this.onOpen,
  });

  final List<SensorHistoryRow> rows;
  final bool loading;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.table_rows_outlined,
      title: 'Lịch sử dữ liệu gần đây',
      trailing: OverviewLinkButton(label: 'Xem chi tiết', onTap: onOpen),
      child: loading && rows.isEmpty
          ? Column(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(height: 36, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(8))))])
          : rows.isEmpty
              ? Text('Chưa có lịch sử dữ liệu cảm biến.', style: bvText(color: DashboardColors.textMuted))
              : Column(
                  children: [
                    _head(),
                    for (final r in rows.take(6))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Expanded(flex: 4, child: Text(fmtDateTimeVn(r.at), style: bvText(fontSize: 12, color: DashboardColors.textMuted))),
                            Expanded(child: Text(_n(r.ph, 2), style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700))),
                            Expanded(child: Text(_n(r.tds, 0), style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700))),
                            Expanded(child: Text(_n(r.temp, 1), style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700))),
                            Expanded(child: Text(_n(r.dox, 1), style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _head() => Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        decoration: BoxDecoration(color: const Color(0xFFF3FBF8), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text('THỜI GIAN', style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted))),
            Expanded(child: Text('pH', style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted))),
            Expanded(child: Text('TDS', style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted))),
            Expanded(child: Text('NHIỆT ĐỘ', style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted))),
            Expanded(child: Text('DO', style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted))),
          ],
        ),
      );

  String _n(double? v, int d) => v == null ? '—' : v.toStringAsFixed(d);
}
