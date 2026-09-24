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
import 'box_labels.dart';

enum SensorTrendRange { h24, d7, d30, custom }

extension on SensorTrendRange {
  String get label => switch (this) {
        SensorTrendRange.h24 => '24 giờ',
        SensorTrendRange.d7 => '7 ngày',
        SensorTrendRange.d30 => '30 ngày',
        SensorTrendRange.custom => 'Tùy chỉnh',
      };

  Duration? get duration => switch (this) {
        SensorTrendRange.h24 => const Duration(hours: 24),
        SensorTrendRange.d7 => const Duration(days: 7),
        SensorTrendRange.d30 => const Duration(days: 30),
        SensorTrendRange.custom => null,
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
  SensorTrendRange _range = SensorTrendRange.h24;
  DateTimeRange? _custom;
  final _history = <String, List<SensorHistoryPoint>>{};
  var _chartLoading = false;
  String? _chartError;
  String _chartSig = '';
  List<SensorAlertRow> _sensorAlerts = const [];
  var _alertLoading = false;

  AreaEnvironmentService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onSvc);
    _loadCharts();
    _loadAlerts();
  }

  @override
  void didUpdateWidget(covariant BoxSensorTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.box.id != widget.box.id) {
      _history.clear();
      _chartSig = '';
      _loadCharts();
      _loadAlerts();
    }
  }

  @override
  void dispose() {
    _svc.removeListener(_onSvc);
    super.dispose();
  }

  void _onSvc() {
    if (!mounted) return;
    setState(() {});
    final sig = _slots().map((s) => s.metric?.sensorId ?? '').join('|');
    if (sig.isNotEmpty && sig != _chartSig) {
      _chartSig = sig;
      _loadCharts();
    }
  }

  String get _rangeKey {
    if (_range == SensorTrendRange.custom && _custom != null) {
      return 'custom-${_custom!.start.millisecondsSinceEpoch}-${_custom!.end.millisecondsSinceEpoch}';
    }
    return _range.name;
  }

  Future<void> _refresh() => _svc.refreshCurrent();

  Future<void> _loadCharts() async {
    final slots = _slots().where((s) => s.metric?.sensorId != null && s.metric!.sensorId!.isNotEmpty);
    if (slots.isEmpty) {
      setState(() {
        _chartLoading = false;
        _chartError = null;
      });
      return;
    }
    setState(() {
      _chartLoading = true;
      _chartError = null;
    });
    final now = DateTime.now();
    final from = _range == SensorTrendRange.custom && _custom != null
        ? _custom!.start
        : now.subtract(_range.duration ?? const Duration(hours: 24));
    final to = _range == SensorTrendRange.custom && _custom != null ? _custom!.end : now;
    try {
      for (final s in slots) {
        final id = s.metric!.sensorId!;
        final key = '$id|$_rangeKey';
        if (_history.containsKey(key)) continue;
        final pts = await _svc.fetchSensorHistory(id, from: from, to: to);
        _history[key] = _downsample([
          for (final p in pts) SensorHistoryPoint(p.at, _maybePh(s.key, p.value)),
        ]);
      }
      if (mounted) setState(() => _chartLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartLoading = false;
          _chartError = '$e';
        });
      }
    }
  }

  Future<void> _loadAlerts() async {
    setState(() => _alertLoading = true);
    final rows = <SensorAlertRow>[];
    try {
      final raw = await _svc.fetchAlertHistory(farmingAreaId: widget.areaId);
      for (final a in raw) {
        final parsed = _alertFromJson(a);
        if (parsed != null) rows.add(parsed);
      }
    } catch (_) {}
    for (final a in widget.alerts) {
      if (!_looksSensor(a.message) || a.occurredAt == null) continue;
      rows.add(SensorAlertRow(
        at: a.occurredAt!,
        metric: _metricFromMessage(a.message),
        valueText: '—',
        threshold: '—',
        status: a.statusLabel,
      ));
    }
    rows.sort((a, b) => b.at.compareTo(a.at));
    final seen = <String>{};
    final uniq = <SensorAlertRow>[];
    for (final r in rows) {
      final k = '${r.at.millisecondsSinceEpoch}|${r.metric}|${r.valueText}';
      if (seen.add(k)) uniq.add(r);
    }
    if (mounted) {
      setState(() {
        _sensorAlerts = uniq;
        _alertLoading = false;
      });
    }
  }

  SensorAlertRow? _alertFromJson(Map<String, dynamic> a) {
    final at = DateTime.tryParse((a['createdAt'] ?? a['CreatedAt'] ?? '').toString());
    if (at == null) return null;
    final type = (a['sensorType'] ?? a['SensorType'] ?? a['category'] ?? a['Category'] ?? '').toString();
    final title = (a['title'] ?? a['Title'] ?? a['message'] ?? a['Message'] ?? '').toString();
    if (!_looksSensor('$type $title')) return null;
    final v = a['triggerValue'] ?? a['TriggerValue'];
    final val = v is num ? v.toDouble() : double.tryParse('$v');
    final tMin = a['thresholdMin'] ?? a['ThresholdMin'];
    final tMax = a['thresholdMax'] ?? a['ThresholdMax'];
    final mn = tMin is num ? tMin.toDouble() : double.tryParse('$tMin');
    final mx = tMax is num ? tMax.toDouble() : double.tryParse('$tMax');
    final slot = _slotForType(type.isEmpty ? title : type);
    String threshold = '—';
    if (mn != null && mx != null) {
      threshold = '${_fmt(slot, mn)} – ${_fmt(slot, mx)}${slot.unit.isEmpty ? '' : ' ${slot.unit}'}';
    } else if (mx != null) {
      threshold = '> ${_fmt(slot, mx)}${slot.unit.isEmpty ? '' : ' ${slot.unit}'}';
    } else if (mn != null) {
      threshold = '< ${_fmt(slot, mn)}${slot.unit.isEmpty ? '' : ' ${slot.unit}'}';
    }
    return SensorAlertRow(
      at: at.isUtc ? at.toLocal() : at,
      metric: slot.label,
      valueText: val == null ? '—' : '${_fmt(slot, val)}${slot.unit.isEmpty ? '' : ' ${slot.unit}'}',
      threshold: threshold,
      status: _alertStatus((a['status'] ?? a['Status'] ?? '').toString()),
    );
  }

  bool _looksSensor(String raw) {
    final s = raw.toLowerCase();
    return s.contains('ph') ||
        s.contains('tds') ||
        s.contains('temp') ||
        s.contains('nhiệt') ||
        s.contains('do') ||
        s.contains('oxy') ||
        s.contains('salin') ||
        s.contains('sensor') ||
        s.contains('cảm biến') ||
        s.contains('nước') ||
        s.contains('water');
  }

  String _metricFromMessage(String msg) {
    final s = msg.toLowerCase();
    if (s.contains('ph')) return 'pH';
    if (s.contains('tds')) return 'TDS';
    if (s.contains('salin') || s.contains('mặn')) return 'Độ mặn';
    if (s.contains('temp') || s.contains('nhiệt')) return 'Nhiệt độ';
    if (s.contains('do') || s.contains('oxy')) return 'DO';
    return 'Sensor';
  }

  String _alertStatus(String raw) {
    final s = raw.toLowerCase();
    return switch (s) {
      'open' || 'active' => 'Đang mở',
      'acknowledged' || 'ack' => 'Đã xác nhận',
      'resolved' => 'Đã xử lý',
      'recovered' => 'Đã khôi phục',
      'closed' => 'Đã xử lý',
      _ => raw.isEmpty ? 'Đang mở' : raw,
    };
  }

  AreaEnvironmentMetric? _pick(bool Function(AreaEnvironmentMetric) test) {
    for (final m in _svc.metrics) {
      if (test(m)) return m;
    }
    return null;
  }

  List<SensorSlot> _slots() {
    final ph = _pick((m) => (m.sensorType ?? m.label).toLowerCase().contains('ph'));
    final sal = _pick((m) => (m.sensorType ?? m.label).toLowerCase().contains('salin'));
    final tds = _pick((m) => (m.sensorType ?? m.label).toLowerCase().contains('tds'));
    final temp = _pick((m) {
      final t = (m.sensorType ?? m.label).toLowerCase();
      return t.contains('temp') || t.contains('nhiệt');
    });
    final dox = _pick((m) {
      final t = (m.sensorType ?? m.label).toLowerCase();
      return t == 'do' || t.contains('oxygen') || t.contains('oxy');
    });
    return [
      SensorSlot(
        key: 'ph',
        label: 'pH',
        unit: '',
        icon: Icons.science_outlined,
        color: DashboardColors.brand,
        decimals: 2,
        min: ph?.minThreshold ?? 7.5,
        max: ph?.maxThreshold ?? 8.5,
        metric: ph,
        thresholdText: '7.5 – 8.5',
      ),
      if (sal != null)
        SensorSlot(
          key: 'salinity',
          label: 'Độ mặn',
          unit: 'ppt',
          icon: Icons.water_drop_outlined,
          color: const Color(0xFF2495E8),
          decimals: 1,
          min: sal.minThreshold ?? 10,
          max: sal.maxThreshold ?? 20,
          metric: sal,
          thresholdText: '${(sal.minThreshold ?? 10).toStringAsFixed(0)} – ${(sal.maxThreshold ?? 20).toStringAsFixed(0)} ppt',
        )
      else
        SensorSlot(
          key: 'tds',
          label: 'TDS',
          unit: 'ppm',
          icon: Icons.grain_rounded,
          color: const Color(0xFF2495E8),
          decimals: 0,
          min: null,
          max: tds?.maxThreshold ?? 1000,
          metric: tds,
          thresholdText: '< 1,000 ppm',
        ),
      SensorSlot(
        key: 'temp',
        label: 'Nhiệt độ',
        unit: '°C',
        icon: Icons.thermostat_rounded,
        color: const Color(0xFFF5B700),
        decimals: 1,
        min: temp?.minThreshold ?? 26,
        max: temp?.maxThreshold ?? 30,
        metric: temp,
        thresholdText: '26 – 30 °C',
      ),
      SensorSlot(
        key: 'do',
        label: 'DO',
        unit: 'mg/L',
        icon: Icons.bubble_chart_outlined,
        color: const Color(0xFF2495E8),
        decimals: 1,
        min: dox?.minThreshold ?? 5,
        max: dox?.maxThreshold ?? 8,
        metric: dox,
        thresholdText: '5 – 8 mg/L',
      ),
    ];
  }

  SensorSlot _slotForType(String raw) {
    final t = raw.toLowerCase();
    for (final s in _slots()) {
      if (t.contains(s.key) || t.contains(s.label.toLowerCase())) return s;
    }
    if (t.contains('ph')) return _slots().first;
    return _slots().first;
  }

  double _maybePh(String key, double v) => key == 'ph' ? (sanitizePh(v) ?? v) : v;

  String _fmt(SensorSlot s, double v) {
    final n = s.key == 'ph' ? (sanitizePh(v) ?? v) : v;
    return n.toStringAsFixed(s.decimals);
  }

  List<SensorHistoryPoint> _pointsFor(SensorSlot s) {
    final id = s.metric?.sensorId;
    if (id == null) return const [];
    return _history['$id|$_rangeKey'] ?? const [];
  }

  List<SensorHistoryPoint> _downsample(List<SensorHistoryPoint> pts, {int max = 120}) {
    if (pts.length <= max) return pts;
    final step = pts.length / max;
    final out = <SensorHistoryPoint>[];
    for (var i = 0; i < max; i++) {
      out.add(pts[(i * step).floor().clamp(0, pts.length - 1)]);
    }
    if (out.last.at != pts.last.at) out.add(pts.last);
    return out;
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 180)),
      lastDate: now,
      initialDateRange: _custom ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked == null) return;
    setState(() {
      _range = SensorTrendRange.custom;
      _custom = picked;
    });
    await _loadCharts();
  }

  Future<void> _setRange(SensorTrendRange r) async {
    if (r == SensorTrendRange.custom) {
      await _pickCustom();
      return;
    }
    setState(() => _range = r);
    await _loadCharts();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final desktop = w >= 1100;
        final tablet = w >= 760;
        final slots = _slots();
        final realtime = RealtimeSensorMetrics(
          slots: slots,
          loading: _svc.loading && _svc.metrics.isEmpty,
          error: _svc.error,
          updatedAt: _svc.data?.lastUpdatedAt ?? _svc.lastRefreshedAt,
          stale: isSensorStale(_svc.data?.lastUpdatedAt ?? _svc.lastRefreshedAt),
          onRefresh: _refresh,
          onRetry: _refresh,
          onCheckSource: widget.onOpenSource,
        );
        final status = SensorSystemStatus(
          sensorStatus: _sensorOnline,
          controllerStatus: widget.controllerStatus,
          lastReceivedAt: _svc.data?.lastUpdatedAt ?? _svc.lastRefreshedAt,
        );
        final charts = SensorTrendSection(
          range: _range,
          custom: _custom,
          slots: slots,
          pointsOf: _pointsFor,
          loading: _chartLoading,
          error: _chartError,
          onRange: _setRange,
          onOpenDetail: widget.onOpenWaterAnalysis,
        );
        final alerts = RecentSensorAlerts(
          rows: _sensorAlerts,
          loading: _alertLoading || widget.alertsLoading,
          onOpenAll: widget.onOpenAlerts,
        );
        final history = RecentSensorHistory(
          rows: _historyRows(slots),
          loading: _chartLoading,
          onOpen: widget.onOpenWaterAnalysis,
        );

        return Column(
          children: [
            SensorSourceBanner(
              boxCode: widget.box.boxCode,
              areaName: widget.areaName,
              areaCode: widget.areaCode,
              inherited: _svc.data?.inheritedByBox ?? true,
              sourceCode: _sourceCode,
              sourceNote: _sourceNote,
              onOpen: widget.onOpenSource,
            ),
            const SizedBox(height: 12),
            if (desktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 76, child: realtime),
                  const SizedBox(width: 12),
                  Expanded(flex: 24, child: status),
                ],
              )
            else if (tablet)
              Column(children: [realtime, const SizedBox(height: 12), status])
            else
              Column(children: [realtime, const SizedBox(height: 12), status]),
            const SizedBox(height: 12),
            charts,
            const SizedBox(height: 12),
            if (desktop || tablet)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: alerts),
                  const SizedBox(width: 12),
                  Expanded(child: history),
                ],
              )
            else
              Column(children: [alerts, const SizedBox(height: 12), history]),
          ],
        );
      },
    );
  }

  String get _sourceCode {
    for (final m in _svc.metrics) {
      final c = (m.sensorCode ?? '').trim();
      if (c.isNotEmpty) return c;
    }
    return '—';
  }

  String get _sourceNote {
    if (widget.areaName.isNotEmpty || widget.areaCode.isNotEmpty) {
      return 'Nước tuần hoàn chung khu';
    }
    return widget.rowLabel.isEmpty ? 'Nước tuần hoàn của khu vực.' : 'Nước tuần hoàn dãy ${widget.rowLabel}';
  }

  String get _sensorOnline {
    if (_svc.error != null && _svc.metrics.isEmpty) return 'offline';
    if (_svc.metrics.isEmpty) return 'offline';
    if (isSensorStale(_svc.data?.lastUpdatedAt ?? _svc.lastRefreshedAt)) return 'degraded';
    return 'online';
  }

  List<SensorHistoryRow> _historyRows(List<SensorSlot> slots) {
    SensorSlot? of(String k) => slots.where((s) => s.key == k).firstOrNull;
    final ph = _pointsFor(of('ph') ?? slots.first);
    final tds = _pointsFor(of('tds') ?? of('salinity') ?? slots.first);
    final temp = _pointsFor(of('temp') ?? slots.first);
    final dox = _pointsFor(of('do') ?? slots.first);
    final times = <DateTime>{
      ...ph.map((e) => e.at),
      ...tds.map((e) => e.at),
      ...temp.map((e) => e.at),
      ...dox.map((e) => e.at),
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    double? near(List<SensorHistoryPoint> pts, DateTime at) {
      SensorHistoryPoint? best;
      for (final p in pts) {
        final d = p.at.difference(at).inSeconds.abs();
        if (d > 15) continue;
        if (best == null || d < best.at.difference(at).inSeconds.abs()) best = p;
      }
      return best?.value;
    }

    return [
      for (final t in times.take(8))
        SensorHistoryRow(
          at: t,
          ph: of('ph') == null ? null : near(ph, t),
          tds: of('tds') == null && of('salinity') == null ? null : near(tds, t),
          temp: of('temp') == null ? null : near(temp, t),
          dox: of('do') == null ? null : near(dox, t),
        ),
    ];
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
