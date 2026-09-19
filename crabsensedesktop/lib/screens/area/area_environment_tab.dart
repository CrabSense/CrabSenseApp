import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/production_models.dart';
import '../../models/water_analysis.dart';
import '../../services/cloud_api_client.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Định nghĩa thông số
// ─────────────────────────────────────────────────────────────────────────────

/// Một thông số môi trường theo dõi trong khu.
class _Param {
  const _Param({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.unit,
    required this.icon,
    required this.sensorKeys,
    required this.labKeys,
    this.refMin,
    this.refMax,
    this.decimals = 1,
  });

  final String key;
  final String label;
  final String shortLabel;
  final String unit;
  final IconData icon;

  /// Từ khoá khớp `sensorType` (lowercase, contains).
  final List<String> sensorKeys;

  /// Từ khoá khớp `code` của kết quả test nước.
  final List<String> labKeys;

  /// Khoảng tham chiếu mặc định — CHỈ dùng khi BE không trả ngưỡng.
  final double? refMin;
  final double? refMax;
  final int decimals;

  bool matchesSensor(String type) {
    final t = type.toLowerCase();
    if (key == 'ph') return t == 'ph' || t.startsWith('ph_') || t.startsWith('ph-');
    if (key == 'do') return t == 'do' || t.contains('oxy') || t.contains('dissolved');
    if (key == 'mg') return t == 'mg' || t.contains('magnes');
    if (key == 'ca') return t == 'ca' || t.contains('calci');
    if (key == 'kh') return t == 'kh' || t.contains('alkal') || t.contains('carbonate');
    return sensorKeys.any(t.contains);
  }

  bool matchesLab(String code) {
    final c = code.toLowerCase();
    return labKeys.any((k) => c == k);
  }

  String fmt(double v) => v.toStringAsFixed(decimals);
}

const _params = <_Param>[
  _Param(key: 'temp', label: 'Nhiệt độ', shortLabel: 'Nhiệt độ', unit: '°C',
      icon: Icons.thermostat_rounded, sensorKeys: ['temp', 'nhiet'], labKeys: ['temp', 'temperature'],
      refMin: 24, refMax: 28),
  _Param(key: 'salinity', label: 'Độ mặn', shortLabel: 'Độ mặn', unit: 'ppt',
      icon: Icons.water_drop_outlined, sensorKeys: ['salin', 'do_man'], labKeys: ['salinity', 'sal'],
      refMin: 10, refMax: 20, decimals: 0),
  _Param(key: 'ph', label: 'pH', shortLabel: 'pH', unit: '',
      icon: Icons.science_outlined, sensorKeys: ['ph'], labKeys: ['ph'],
      refMin: 7.5, refMax: 8.5),
  _Param(key: 'do', label: 'DO', shortLabel: 'DO', unit: 'mg/L',
      icon: Icons.bubble_chart_outlined, sensorKeys: ['do', 'oxy'], labKeys: ['do', 'oxygen'],
      refMin: 5),
  _Param(key: 'nh3', label: 'NH₃/NH₄', shortLabel: 'NH₃/NH₄', unit: 'mg/L',
      icon: Icons.blur_on_rounded, sensorKeys: ['nh3', 'nh4', 'ammon'], labKeys: ['nh3', 'nh4', 'ammonia'],
      refMax: 0.1, decimals: 2),
  _Param(key: 'no2', label: 'NO₂', shortLabel: 'NO₂', unit: 'mg/L',
      icon: Icons.grain_rounded, sensorKeys: ['no2', 'nitrit'], labKeys: ['no2', 'nitrite'],
      refMax: 0.2, decimals: 2),
  _Param(key: 'kh', label: 'KH', shortLabel: 'KH', unit: 'dKH',
      icon: Icons.layers_outlined, sensorKeys: ['kh', 'alkal'], labKeys: ['kh', 'alkalinity'],
      refMin: 7, refMax: 10),
  _Param(key: 'ca', label: 'Ca', shortLabel: 'Ca', unit: 'mg/L',
      icon: Icons.circle_outlined, sensorKeys: ['ca', 'calci'], labKeys: ['ca', 'calcium'],
      refMin: 380, refMax: 460, decimals: 0),
  _Param(key: 'mg', label: 'Mg', shortLabel: 'Mg', unit: 'mg/L',
      icon: Icons.hexagon_outlined, sensorKeys: ['mg', 'magnes'], labKeys: ['mg', 'magnesium'],
      refMin: 1200, refMax: 1400, decimals: 0),
];

enum _Level { noData, stale, normal, watch, alert }

extension on _Level {
  Color get color => switch (this) {
        _Level.noData => kMgmtSlate,
        _Level.stale => const Color(0xFFF59E0B),
        _Level.normal => DashboardColors.brandGreen,
        _Level.watch => kMgmtAmber,
        _Level.alert => DashboardColors.risk,
      };
  int get severity => switch (this) {
        _Level.noData => 0,
        _Level.normal => 1,
        _Level.stale => 2,
        _Level.watch => 3,
        _Level.alert => 4,
      };
}

enum _Source { sensor, lab, none }

/// Giá trị hiện tại của một thông số (từ sensor hoặc test nước).
class _Reading {
  const _Reading({
    required this.param,
    required this.source,
    this.value,
    this.min,
    this.max,
    this.measuredAt,
    this.sensorId,
    this.locationName,
    this.labStatus,
    this.inherited = false,
  });

  final _Param param;
  final _Source source;
  final double? value;
  final double? min;
  final double? max;
  final DateTime? measuredAt;
  final String? sensorId;
  final String? locationName;
  final String? labStatus;

  /// Dãy không có sensor riêng → kế thừa giá trị chung của khu.
  final bool inherited;

  bool get hasThreshold => min != null || max != null;

  String get rangeText {
    final p = param;
    if (min != null && max != null) return '${p.fmt(min!)} – ${p.fmt(max!)} ${p.unit}'.trim();
    if (min != null) return '> ${p.fmt(min!)} ${p.unit}'.trim();
    if (max != null) return '< ${p.fmt(max!)} ${p.unit}'.trim();
    return 'Chưa cấu hình ngưỡng';
  }

  Duration? get age =>
      measuredAt == null ? null : DateTime.now().difference(measuredAt!.toLocal());

  bool get isStale {
    final a = age;
    if (a == null) return false;
    return source == _Source.sensor ? a.inHours >= 6 : a.inDays >= 7;
  }

  _Level get level {
    final v = value;
    if (v == null) return _Level.noData;
    if (isStale) return _Level.stale;
    if (source == _Source.lab && labStatus != null) {
      final s = labStatus!.toLowerCase();
      if (s.contains('danger') || s.contains('alert') || s.contains('bad') || s.contains('critical')) {
        return _Level.alert;
      }
      if (s.contains('warn') || s.contains('watch')) return _Level.watch;
      if (s.contains('good') || s.contains('ok') || s.contains('normal')) return _Level.normal;
    }
    if (min != null && v < min!) return _Level.alert;
    if (max != null && v > max!) return _Level.alert;
    // Sát biên 10% khoảng cho phép → Theo dõi.
    final span = (min != null && max != null)
        ? (max! - min!)
        : (min ?? max ?? 0).abs();
    final margin = span * 0.1;
    if (margin > 0) {
      if (min != null && v < min! + margin) return _Level.watch;
      if (max != null && v > max! - margin) return _Level.watch;
    }
    return _Level.normal;
  }

  String get statusLabel {
    final v = value;
    switch (level) {
      case _Level.noData:
        return 'Chưa có dữ liệu';
      case _Level.stale:
        return 'Dữ liệu cũ';
      case _Level.normal:
        return 'Bình thường';
      case _Level.watch:
        return 'Theo dõi';
      case _Level.alert:
        if (v != null && min != null && v < min!) return 'Thấp hơn mức cho phép';
        if (v != null && max != null && v > max!) return 'Cao hơn mức cho phép';
        return 'Vượt ngưỡng';
    }
  }
}

class _Point {
  const _Point(this.at, this.value);
  final DateTime at;
  final double value;
}

class _AlertItem {
  const _AlertItem({
    required this.at,
    required this.paramLabel,
    required this.location,
    required this.valueText,
    required this.statusLabel,
    required this.severity,
    required this.raw,
  });
  final DateTime at;
  final String paramLabel;
  final String location;
  final String valueText;
  final String statusLabel;
  final String severity;
  final Map<String, dynamic> raw;
}

enum _Range { h24, d7, d30 }

extension on _Range {
  String get label => switch (this) {
        _Range.h24 => '24 giờ qua',
        _Range.d7 => '7 ngày qua',
        _Range.d30 => '30 ngày qua',
      };
  Duration get duration => switch (this) {
        _Range.h24 => const Duration(hours: 24),
        _Range.d7 => const Duration(days: 7),
        _Range.d30 => const Duration(days: 30),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab widget
// ─────────────────────────────────────────────────────────────────────────────

class AreaEnvironmentTab extends StatefulWidget {
  const AreaEnvironmentTab({
    super.key,
    required this.token,
    required this.areaId,
    required this.areaName,
    required this.rows,
    this.onOpenAlerts,
  });

  final String token;
  final String areaId;
  final String areaName;
  final List<RowRecord> rows;
  final VoidCallback? onOpenAlerts;

  @override
  State<AreaEnvironmentTab> createState() => _AreaEnvironmentTabState();
}

class _AreaEnvironmentTabState extends State<AreaEnvironmentTab> {
  final _api = CloudApiClient();
  Timer? _poll;

  List<Map<String, dynamic>> _live = const [];
  WaterAnalysisSnapshot? _lab;
  List<_AlertItem> _alerts = const [];
  final _history = <String, List<_Point>>{}; // sensorId → điểm (theo _range)
  final _spark = <String, List<_Point>>{}; // sensorId → 7 ngày (sparkline)

  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  _Range _range = _Range.d7;
  String _chartParam = 'temp';
  String _compareParam = 'temp';
  String? _rowFilter;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _loadLive(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  // ── Loading ──────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _loadLive(silent: true);
    await Future.wait([_loadLab(), _loadAlerts()]);
    await _loadSparklines();
    await _loadChartHistory();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _loadLive(silent: true);
    await Future.wait([_loadLab(), _loadAlerts(), _loadChartHistory()]);
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _loadLive({bool silent = false}) async {
    try {
      final live = await _api.fetchIotLive(widget.token, farmingAreaId: widget.areaId);
      if (!mounted) return;
      setState(() {
        _live = live;
        _error = null;
      });
    } catch (e) {
      if (!silent && mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _loadLab() async {
    try {
      final raw = await _api.fetchWaterAnalysis(widget.token, widget.areaId);
      if (mounted) setState(() => _lab = WaterAnalysisSnapshot.fromJson(raw));
    } catch (_) {
      // 404 = khu chưa có trạm phân tích nước → không có dữ liệu test.
      if (mounted) setState(() => _lab = null);
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final raw = await _api.fetchAlertHistory(widget.token,
          farmingAreaId: widget.areaId, days: 30);
      final out = <_AlertItem>[];
      for (final a in raw) {
        final at = DateTime.tryParse((a['createdAt'] ?? a['CreatedAt'] ?? '').toString())
            ?.toLocal();
        if (at == null) continue;
        final type = (a['sensorType'] ?? a['SensorType'] ?? '').toString();
        final category = (a['category'] ?? a['Category'] ?? '').toString().toLowerCase();
        // Chỉ lấy cảnh báo môi trường / cảm biến.
        if (type.isEmpty && !category.contains('water') && !category.contains('env') &&
            !category.contains('sensor')) {
          continue;
        }
        final p = _params.where((p) => p.matchesSensor(type)).firstOrNull;
        final v = a['triggerValue'] ?? a['TriggerValue'];
        final val = v is num ? v.toDouble() : double.tryParse('$v');
        final unit = (a['unit'] ?? a['Unit'] ?? p?.unit ?? '').toString();
        final tMin = a['thresholdMin'] ?? a['ThresholdMin'];
        final tMax = a['thresholdMax'] ?? a['ThresholdMax'];
        final mn = tMin is num ? tMin.toDouble() : null;
        final mx = tMax is num ? tMax.toDouble() : null;
        String status = 'Vượt ngưỡng';
        if (val != null && mn != null && val < mn) status = 'Thấp hơn mức cho phép';
        if (val != null && mx != null && val > mx) status = 'Cao hơn mức cho phép';
        final loc = (a['locationLabel'] ?? a['LocationLabel'] ?? a['sensorCode'] ?? a['SensorCode'] ?? '')
            .toString();
        out.add(_AlertItem(
          at: at,
          paramLabel: p?.label ?? (type.isEmpty ? (a['title'] ?? 'Cảnh báo').toString() : type),
          location: loc,
          valueText: val == null ? '—' : '${p?.fmt(val) ?? val.toStringAsFixed(2)} $unit'.trim(),
          statusLabel: status,
          severity: (a['severity'] ?? a['Severity'] ?? '').toString(),
          raw: a,
        ));
      }
      out.sort((a, b) => b.at.compareTo(a.at));
      if (mounted) setState(() => _alerts = out);
    } catch (_) {}
  }

  Future<List<_Point>> _fetchHistory(String sensorId, Duration back) async {
    try {
      final now = DateTime.now();
      final raw = await _api.fetchSensorHistory(widget.token,
          sensorId: sensorId, from: now.subtract(back), to: now, pageSize: 2000);
      final pts = <_Point>[];
      for (final m in raw) {
        final v = m['value'] ?? m['Value'];
        final at = DateTime.tryParse((m['measuredAt'] ?? m['MeasuredAt'] ?? '').toString());
        if (v is! num || at == null) continue;
        pts.add(_Point(at.toLocal(), v.toDouble()));
      }
      pts.sort((a, b) => a.at.compareTo(b.at));
      return pts;
    } catch (_) {
      return const [];
    }
  }

  /// Sparkline 7 ngày cho sensor "đại diện" của từng thông số.
  Future<void> _loadSparklines() async {
    final ids = <String>{};
    for (final p in _params) {
      final r = _readingFor(p, rowId: null);
      if (r.sensorId != null) ids.add(r.sensorId!);
    }
    for (final id in ids) {
      if (_spark.containsKey(id)) continue;
      final pts = await _fetchHistory(id, const Duration(days: 7));
      if (!mounted) return;
      setState(() => _spark[id] = pts);
    }
  }

  /// Lịch sử cho biểu đồ chính (thông số + khoảng thời gian đang chọn).
  Future<void> _loadChartHistory() async {
    final p = _paramByKey(_chartParam);
    final r = _readingFor(p, rowId: _rowFilter);
    final id = r.sensorId;
    if (id == null) return;
    final pts = await _fetchHistory(id, _range.duration);
    if (!mounted) return;
    setState(() => _history['$id|${_range.name}'] = pts);
  }

  // ── Đọc giá trị ──────────────────────────────────────────────────────────

  _Param _paramByKey(String k) => _params.firstWhere((p) => p.key == k);

  Iterable<Map<String, dynamic>> _sensorsFor(_Param p) => _live.where((s) {
        final type = (s['sensorType'] ?? s['SensorType'] ?? '').toString();
        final active = s['isActive'] ?? s['IsActive'];
        return p.matchesSensor(type) && active != false;
      });

  String _locOf(Map<String, dynamic> s) =>
      (s['locationName'] ?? s['LocationName'] ?? '').toString().trim().toLowerCase();

  /// Cảm biến thuộc dãy: ưu tiên `farmingRowId` (BE gắn trực tiếp), dự phòng khớp tên vị trí.
  bool _sensorMatchesRow(Map<String, dynamic> s, RowRecord row) {
    final rid = (s['farmingRowId'] ?? s['FarmingRowId'])?.toString();
    if (rid != null && rid.isNotEmpty && rid != 'null') return rid == row.id;
    final loc = _locOf(s);
    if (loc.isEmpty) return false;
    return loc == row.rowName.trim().toLowerCase() || loc == row.rowCode.trim().toLowerCase();
  }

  static double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

  _Reading _fromSensor(_Param p, Map<String, dynamic> s, {bool inherited = false}) {
    return _Reading(
      param: p,
      source: _Source.sensor,
      value: _num(s['latestValue'] ?? s['LatestValue']),
      min: _num(s['minThreshold'] ?? s['MinThreshold']) ?? p.refMin,
      max: _num(s['maxThreshold'] ?? s['MaxThreshold']) ?? p.refMax,
      measuredAt: DateTime.tryParse((s['latestMeasuredAt'] ?? s['LatestMeasuredAt'] ?? '').toString()),
      sensorId: (s['sensorId'] ?? s['SensorId'])?.toString(),
      locationName: (s['locationName'] ?? s['LocationName'])?.toString(),
      inherited: inherited,
    );
  }

  /// Giá trị hiện tại của thông số cho khu (rowId == null) hoặc một dãy.
  _Reading _readingFor(_Param p, {required String? rowId}) {
    final sensors = _sensorsFor(p).toList();
    final row = rowId == null ? null : widget.rows.where((r) => r.id == rowId).firstOrNull;

    if (row != null) {
      final own = sensors.where((s) => _sensorMatchesRow(s, row)).toList();
      if (own.isNotEmpty) return _fromSensor(p, _newest(own));
    }
    // Sensor cấp khu: ưu tiên sensor không gắn vị trí, rồi mới tới bất kỳ.
    if (sensors.isNotEmpty) {
      final general = sensors.where((s) => _locOf(s).isEmpty).toList();
      final pick = _newest(general.isNotEmpty ? general : sensors);
      return _fromSensor(p, pick, inherited: row != null);
    }
    // Test nước (kết quả gần nhất của khu).
    final run = _lab?.latest;
    if (run != null) {
      final m = run.metrics.where((m) => p.matchesLab(m.code)).firstOrNull;
      if (m != null) {
        return _Reading(
          param: p,
          source: _Source.lab,
          value: m.value,
          min: p.refMin,
          max: p.refMax,
          measuredAt: run.completedAt ?? run.startedAt,
          labStatus: m.status,
          inherited: row != null,
        );
      }
    }
    return _Reading(param: p, source: _Source.none, min: p.refMin, max: p.refMax);
  }

  Map<String, dynamic> _newest(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final x = DateTime.tryParse((a['latestMeasuredAt'] ?? a['LatestMeasuredAt'] ?? '').toString());
      final y = DateTime.tryParse((b['latestMeasuredAt'] ?? b['LatestMeasuredAt'] ?? '').toString());
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
    return list.first;
  }

  DateTime? get _lastDataAt {
    DateTime? latest;
    for (final p in _params) {
      final at = _readingFor(p, rowId: null).measuredAt?.toLocal();
      if (at != null && (latest == null || at.isAfter(latest))) latest = at;
    }
    return latest;
  }

  bool get _hasSensor => _live.isNotEmpty;

  // ── Actions ──────────────────────────────────────────────────────────────

  void _selectChartParam(String key) {
    if (_chartParam == key) return;
    setState(() => _chartParam = key);
    _loadChartHistory();
  }

  void _selectRange(_Range r) {
    if (_range == r) return;
    setState(() => _range = r);
    _loadChartHistory();
  }

  void _toggleRowFilter(String rowId) {
    setState(() => _rowFilter = _rowFilter == rowId ? null : rowId);
    _loadChartHistory();
  }

  Future<void> _export() async {
    final sb = StringBuffer();
    sb.writeln('CrabSense - Thong so moi truong - ${widget.areaName}');
    sb.writeln('Xuat luc,${fmtDateTimeVn(DateTime.now())}');
    sb.writeln();
    sb.writeln('Thong so,Gia tri,Don vi,Nguon,Ngưỡng min,Ngưỡng max,Trang thai,Thoi diem do');
    for (final p in _params) {
      final r = _readingFor(p, rowId: null);
      sb.writeln([
        p.label,
        r.value == null ? '' : p.fmt(r.value!),
        p.unit,
        switch (r.source) { _Source.sensor => 'Sensor', _Source.lab => 'Test nuoc', _Source.none => '' },
        r.min?.toString() ?? '',
        r.max?.toString() ?? '',
        r.statusLabel,
        r.measuredAt == null ? '' : fmtDateTimeVn(r.measuredAt),
      ].map(_csv).join(','));
    }
    sb.writeln();
    sb.writeln('Theo day');
    sb.writeln(['Day', for (final p in _params) '${p.label} (${p.unit})', 'Trang thai'].map(_csv).join(','));
    for (final row in widget.rows) {
      final rs = [for (final p in _params) _readingFor(p, rowId: row.id)];
      final worst = rs.fold(_Level.noData, (a, r) => r.level.severity > a.severity ? r.level : a);
      sb.writeln([
        row.rowName,
        for (final r in rs) r.value == null ? '' : r.param.fmt(r.value!),
        _levelLabel(worst),
      ].map(_csv).join(','));
    }
    final p = _paramByKey(_chartParam);
    final r = _readingFor(p, rowId: _rowFilter);
    final pts = r.sensorId == null ? const <_Point>[] : (_history['${r.sensorId}|${_range.name}'] ?? const []);
    if (pts.isNotEmpty) {
      sb.writeln();
      sb.writeln('Lich su ${p.label} (${_range.label})');
      sb.writeln('Thoi gian,Gia tri (${p.unit})');
      for (final pt in pts) {
        sb.writeln('${fmtDateTimeVn(pt.at)},${p.fmt(pt.value)}');
      }
    }

    final now = DateTime.now();
    final name =
        'crabsense_moitruong_${widget.areaName.replaceAll(RegExp(r'[^\w]+'), '_')}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất dữ liệu môi trường',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (path == null || !mounted) return;
    try {
      // BOM để Excel mở đúng UTF-8.
      await File(path).writeAsString('\uFEFF${sb.toString()}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không ghi được file: $e')),
      );
    }
  }

  static String _csv(String v) =>
      v.contains(',') || v.contains('"') ? '"${v.replaceAll('"', '""')}"' : v;

  static String _levelLabel(_Level l) => switch (l) {
        _Level.noData => 'Chưa có dữ liệu',
        _Level.stale => 'Dữ liệu cũ',
        _Level.normal => 'Bình thường',
        _Level.watch => 'Theo dõi',
        _Level.alert => 'Vượt ngưỡng',
      };

  void _showAlertDetail(_AlertItem a) {
    final raw = a.raw;
    String s(List<String> keys) {
      for (final k in keys) {
        final v = raw[k];
        if (v != null && '$v'.isNotEmpty) return '$v';
      }
      return '—';
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s(['title', 'Title']),
            style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Thông số', '${a.paramLabel}${a.location.isEmpty ? '' : ' (${a.location})'}'),
              _kv('Giá trị', a.valueText),
              _kv('Trạng thái', a.statusLabel),
              _kv('Mức độ', a.severity),
              _kv('Thời gian', fmtDateTimeVn(a.at)),
              _kv('Nội dung', s(['message', 'Message'])),
              if (s(['aiRecommendation', 'AiRecommendation']) != '—')
                _kv('Gợi ý AI', s(['aiRecommendation', 'AiRecommendation'])),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          if (widget.onOpenAlerts != null)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
              onPressed: () {
                Navigator.pop(ctx);
                widget.onOpenAlerts!();
              },
              child: const Text('Mở Hệ thống cảnh báo'),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
            ),
            Expanded(
              child: Text(v,
                  style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary)),
            ),
          ],
        ),
      );

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final readings = [for (final p in _params) _readingFor(p, rowId: _rowFilter)];
    final filterRow = _rowFilter == null
        ? null
        : widget.rows.where((r) => r.id == _rowFilter).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Thông số môi trường ${widget.areaName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bvText(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: DashboardColors.textPrimary,
                          ),
                        ),
                      ),
                      if (filterRow != null) ...[
                        const SizedBox(width: 10),
                        InputChip(
                          label: Text('Dãy ${filterRow.rowName}',
                              style: bvText(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: DashboardColors.brand)),
                          backgroundColor: DashboardColors.mint,
                          side: BorderSide.none,
                          deleteIconColor: DashboardColors.brand,
                          onDeleted: () => _toggleRowFilter(filterRow.id),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Cập nhật cuối: ${_lastDataAt == null ? '—' : _fmtFull(_lastDataAt!)}',
                        style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _hasSensor ? DashboardColors.brandGreen : kMgmtSlate,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _hasSensor ? 'Dữ liệu trực tuyến' : 'Chưa có cảm biến trực tuyến',
                        style: bvText(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _hasSensor ? DashboardColors.brand : DashboardColors.textMuted,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(width: 12),
                        Text(_error!, style: bvText(fontSize: 12, color: DashboardColors.risk)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 38,
              child: MgmtDropdown<_Range>(
                width: 150,
                leading: Icons.calendar_today_outlined,
                valueLabel: _range.label,
                items: [for (final r in _Range.values) (r, r.label)],
                onSelected: _selectRange,
              ),
            ),
            const SizedBox(width: 8),
            MgmtOutlineButton(
              icon: _refreshing ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
              tooltip: 'Tải lại',
              height: 38,
              onTap: _refreshing ? null : _refresh,
            ),
            const SizedBox(width: 8),
            MgmtPrimaryButton(
              icon: Icons.download_rounded,
              label: 'Xuất dữ liệu',
              height: 38,
              onTap: _export,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 9 parameter cards ──────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 1300 ? 9 : c.maxWidth >= 900 ? 5 : 3;
            const gap = 10.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final r in readings)
                  SizedBox(
                    width: w,
                    child: _ParamCard(
                      reading: r,
                      selected: r.param.key == _chartParam,
                      spark: r.sensorId == null ? const [] : (_spark[r.sensorId] ?? const []),
                      onTap: () => _selectChartParam(r.param.key),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // ── Chart + compare ────────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final chart = _TrendCard(
              param: _paramByKey(_chartParam),
              reading: _readingFor(_paramByKey(_chartParam), rowId: _rowFilter),
              points: () {
                final r = _readingFor(_paramByKey(_chartParam), rowId: _rowFilter);
                return r.sensorId == null
                    ? const <_Point>[]
                    : (_history['${r.sensorId}|${_range.name}'] ?? const <_Point>[]);
              }(),
              range: _range,
              onParam: _selectChartParam,
              onRange: _selectRange,
            );
            final compare = _CompareCard(
              param: _paramByKey(_compareParam),
              rows: widget.rows,
              readingFor: (row) => _readingFor(_paramByKey(_compareParam), rowId: row.id),
              selectedRowId: _rowFilter,
              onParam: (k) => setState(() => _compareParam = k),
              onRow: _toggleRowFilter,
            );
            if (c.maxWidth < 1000) {
              return Column(children: [
                SizedBox(height: 280, child: chart),
                const SizedBox(height: 14),
                SizedBox(height: 280, child: compare),
              ]);
            }
            return SizedBox(
              height: 270,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 65, child: chart),
                  const SizedBox(width: 14),
                  Expanded(flex: 35, child: compare),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // ── Table + alerts ─────────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final table = _RowsTable(
              rows: widget.rows,
              readingFor: (p, rowId) => _readingFor(p, rowId: rowId),
              selectedRowId: _rowFilter,
              onRow: _toggleRowFilter,
            );
            final alerts = _AlertsCard(
              alerts: _alerts,
              onOpenAll: widget.onOpenAlerts,
              onOpen: _showAlertDetail,
            );
            if (c.maxWidth < 1000) {
              return Column(children: [table, const SizedBox(height: 14), alerts]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 66, child: table),
                const SizedBox(width: 14),
                Expanded(flex: 34, child: alerts),
              ],
            );
          },
        ),
      ],
    );
  }
}

String _fmtFull(DateTime dt) {
  final l = dt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}

String _ago(Duration d) {
  if (d.inMinutes < 1) return 'vừa xong';
  if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
  if (d.inHours < 24) return '${d.inHours} giờ trước';
  return '${d.inDays} ngày trước';
}

// ─────────────────────────────────────────────────────────────────────────────
// Parameter card
// ─────────────────────────────────────────────────────────────────────────────

class _ParamCard extends StatelessWidget {
  const _ParamCard({
    required this.reading,
    required this.selected,
    required this.spark,
    required this.onTap,
  });

  final _Reading reading;
  final bool selected;
  final List<_Point> spark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final p = r.param;
    final lvl = r.level;
    final borderColor = lvl == _Level.stale
        ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
        : selected
            ? DashboardColors.brand
            : DashboardColors.cardBorder;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.brand.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tên + nguồn
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: lvl.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: Icon(p.icon, size: 13, color: lvl.color),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                  ),
                  _SourceTag(source: r.source),
                ],
              ),
              const SizedBox(height: 5),
              // Giá trị
              if (r.value == null)
                Text('—',
                    style: bvText(fontSize: 18, fontWeight: FontWeight.w800,
                        color: DashboardColors.textMuted))
              else
                Text.rich(
                  TextSpan(
                    text: p.fmt(r.value!),
                    style: bvText(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                      height: 1.05,
                    ),
                    children: [
                      if (p.unit.isNotEmpty)
                        TextSpan(
                          text: ' ${p.unit}',
                          style: bvText(fontSize: 11, fontWeight: FontWeight.w600,
                              color: DashboardColors.textMuted),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Text(
                r.value == null
                    ? 'Chưa có dữ liệu'
                    : lvl == _Level.stale && r.age != null
                        ? 'Cập nhật ${_ago(r.age!)}'
                        : r.rangeText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bvText(fontSize: 10, color: DashboardColors.textMuted),
              ),
              const SizedBox(height: 5),
              // Badge
              _LevelBadge(level: lvl, label: r.value == null ? 'Chưa có dữ liệu' : r.statusLabel),
              const SizedBox(height: 6),
              // Sparkline
              SizedBox(
                height: 18,
                width: double.infinity,
                child: spark.length >= 2
                    ? CustomPaint(painter: _SparkPainter(spark, lvl.color))
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          r.source == _Source.lab
                              ? (r.measuredAt == null ? '' : 'Test ${fmtDateTimeVn(r.measuredAt)}')
                              : r.source == _Source.none
                                  ? ''
                                  : 'Chưa đủ lịch sử',
                          style: bvText(fontSize: 9.5, color: DashboardColors.textMuted),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.source});
  final _Source source;

  @override
  Widget build(BuildContext context) {
    return switch (source) {
      _Source.sensor => Tooltip(
          message: 'Đo trực tuyến bằng cảm biến',
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: DashboardColors.brandGreen, shape: BoxShape.circle),
            ),
            const SizedBox(width: 3),
            Text('Sensor', style: bvText(fontSize: 9.5, color: DashboardColors.textMuted)),
          ]),
        ),
      _Source.lab => Tooltip(
          message: 'Kết quả test nước gần nhất (không realtime)',
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.science_outlined, size: 11, color: kMgmtBlue),
            const SizedBox(width: 2),
            Text('Test nước', style: bvText(fontSize: 9.5, color: DashboardColors.textMuted)),
          ]),
        ),
      _Source.none => const SizedBox.shrink(),
    };
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.label});
  final _Level level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = level.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (level == _Level.stale)
            Icon(Icons.warning_amber_rounded, size: 10, color: c)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bvText(fontSize: 10, fontWeight: FontWeight.w700, color: c),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points, this.color);
  final List<_Point> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    // Lấy tối đa 40 điểm gần nhất cho gọn.
    final pts = points.length > 40 ? points.sublist(points.length - 40) : points;
    var lo = pts.first.value, hi = pts.first.value;
    for (final p in pts) {
      lo = math.min(lo, p.value);
      hi = math.max(hi, p.value);
    }
    final span = (hi - lo).abs() < 1e-9 ? 1.0 : hi - lo;
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = i / (pts.length - 1) * size.width;
      final y = size.height - ((pts[i].value - lo) / span) * (size.height - 2) - 1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.10));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.points != points || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Trend chart
// ─────────────────────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.param,
    required this.reading,
    required this.points,
    required this.range,
    required this.onParam,
    required this.onRange,
  });

  final _Param param;
  final _Reading reading;
  final List<_Point> points;
  final _Range range;
  final ValueChanged<String> onParam;
  final ValueChanged<_Range> onRange;

  @override
  Widget build(BuildContext context) {
    final label = param.unit.isEmpty ? param.label : '${param.label} (${param.unit})';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Biểu đồ biến động thông số',
                  style: bvText(fontSize: 14, fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary),
                ),
              ),
              SizedBox(
                height: 32,
                child: MgmtDropdown<String>(
                  width: 150,
                  valueLabel: label,
                  items: [
                    for (final p in _params)
                      (p.key, p.unit.isEmpty ? p.label : '${p.label} (${p.unit})'),
                  ],
                  onSelected: onParam,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: MgmtDropdown<_Range>(
                  width: 130,
                  valueLabel: range.label,
                  items: [for (final r in _Range.values) (r, r.label)],
                  onSelected: onRange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: points.length < 2
                ? _chartEmpty()
                : _LineChart(param: param, points: points, range: range, reading: reading),
          ),
        ],
      ),
    );
  }

  Widget _chartEmpty() {
    final msg = switch (reading.source) {
      _Source.lab =>
        'Thông số này đến từ test nước (không có lịch sử liên tục).\n'
            'Kết quả gần nhất: ${reading.value == null ? '—' : '${param.fmt(reading.value!)} ${param.unit}'}'
            ' · ${fmtDateTimeVn(reading.measuredAt)}',
      _Source.none => 'Khu chưa có cảm biến / kết quả test cho ${param.label}.',
      _Source.sensor => points.isEmpty
          ? 'Chưa có dữ liệu lịch sử trong ${range.label.toLowerCase()}.'
          : 'Chưa đủ dữ liệu để vẽ biểu đồ.',
    };
    return Center(
      child: Text(msg,
          textAlign: TextAlign.center,
          style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.param,
    required this.points,
    required this.range,
    required this.reading,
  });

  final _Param param;
  final List<_Point> points;
  final _Range range;
  final _Reading reading;

  @override
  Widget build(BuildContext context) {
    final t0 = points.first.at.millisecondsSinceEpoch.toDouble();
    final t1 = points.last.at.millisecondsSinceEpoch.toDouble();
    final spanMs = math.max(1.0, t1 - t0);
    final spots = [
      for (final p in points)
        FlSpot((p.at.millisecondsSinceEpoch - t0) / spanMs, p.value),
    ];

    var lo = points.map((p) => p.value).reduce(math.min);
    var hi = points.map((p) => p.value).reduce(math.max);
    if (reading.min != null) lo = math.min(lo, reading.min!);
    if (reading.max != null) hi = math.max(hi, reading.max!);
    final pad = math.max((hi - lo) * 0.15, param.decimals >= 2 ? 0.01 : 0.5);
    final minY = _floorNice(lo - pad, param);
    final maxY = _ceilNice(hi + pad, param);
    final interval = math.max((maxY - minY) / 6, param.decimals >= 2 ? 0.01 : 0.5);

    String xLabel(double x) {
      final ms = t0 + x * spanMs;
      final d = DateTime.fromMillisecondsSinceEpoch(ms.round());
      String two(int v) => v.toString().padLeft(2, '0');
      return range == _Range.h24 ? '${two(d.hour)}:${two(d.minute)}' : '${two(d.day)}/${two(d.month)}';
    }

    final line = DashboardColors.brand;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6),
      child: LineChart(
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
            getDrawingHorizontalLine: (_) =>
                FlLine(color: DashboardColors.cardBorder, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval,
                getTitlesWidget: (v, meta) => Text(
                  param.decimals >= 2 ? v.toStringAsFixed(2) : v.toStringAsFixed(param.decimals == 0 ? 0 : 1),
                  style: bvText(fontSize: 10, color: DashboardColors.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1 / 6,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(xLabel(v),
                      style: bvText(fontSize: 10, color: DashboardColors.textMuted)),
                ),
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (reading.min != null)
                HorizontalLine(
                  y: reading.min!,
                  color: kMgmtAmber.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  dashArray: const [6, 4],
                ),
              if (reading.max != null)
                HorizontalLine(
                  y: reading.max!,
                  color: kMgmtAmber.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  dashArray: const [6, 4],
                ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.white,
              tooltipBorder: BorderSide(color: DashboardColors.cardBorder),
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${fmtDateTimeVn(points[s.spotIndex].at)}\n',
                    bvText(fontSize: 10.5, color: DashboardColors.textMuted),
                    children: [
                      TextSpan(
                        text: '● ${param.label}: ${param.fmt(s.y)} ${param.unit}'.trim(),
                        style: bvText(fontSize: 12, fontWeight: FontWeight.w700,
                            color: DashboardColors.brand),
                      ),
                    ],
                    textAlign: TextAlign.left,
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: line,
              barWidth: 2,
              dotData: FlDotData(
                show: points.length <= 60,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 2.2,
                  color: Colors.white,
                  strokeWidth: 1.6,
                  strokeColor: line,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: DashboardColors.brandGreen.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _step(_Param p) =>
      p.decimals >= 2 ? 0.01 : p.decimals == 1 ? 0.5 : 10.0;

  static double _floorNice(double v, _Param p) =>
      ((v / _step(p)).floor() * _step(p)).toDouble();

  static double _ceilNice(double v, _Param p) =>
      ((v / _step(p)).ceil() * _step(p)).toDouble();
}

// ─────────────────────────────────────────────────────────────────────────────
// Compare by row
// ─────────────────────────────────────────────────────────────────────────────

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.param,
    required this.rows,
    required this.readingFor,
    required this.selectedRowId,
    required this.onParam,
    required this.onRow,
  });

  final _Param param;
  final List<RowRecord> rows;
  final _Reading Function(RowRecord) readingFor;
  final String? selectedRowId;
  final ValueChanged<String> onParam;
  final ValueChanged<String> onRow;

  @override
  Widget build(BuildContext context) {
    final label = param.unit.isEmpty ? param.label : '${param.label} (${param.unit})';
    final readings = [for (final r in rows) (r, readingFor(r))];
    final withValue = readings.where((e) => e.$2.value != null).toList();
    final allInherited = withValue.isNotEmpty && withValue.every((e) => e.$2.inherited);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('So sánh theo dãy',
                    style: bvText(fontSize: 14, fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary)),
              ),
              SizedBox(
                height: 32,
                child: MgmtDropdown<String>(
                  width: 140,
                  valueLabel: label,
                  items: [
                    for (final p in _params)
                      (p.key, p.unit.isEmpty ? p.label : '${p.label} (${p.unit})'),
                  ],
                  onSelected: onParam,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: rows.isEmpty || withValue.isEmpty
                ? Center(
                    child: Text(
                      rows.isEmpty ? 'Khu chưa có dãy.' : 'Chưa có dữ liệu ${param.label} cho các dãy.',
                      textAlign: TextAlign.center,
                      style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                    ),
                  )
                : _Bars(
                    param: param,
                    items: readings,
                    selectedRowId: selectedRowId,
                    onRow: onRow,
                  ),
          ),
          if (allInherited)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Cảm biến đo ở cấp khu — các dãy đang kế thừa cùng giá trị. '
                'Gắn sensor theo dãy để so sánh thật.',
                maxLines: 2,
                style: bvText(fontSize: 10, color: DashboardColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.param,
    required this.items,
    required this.selectedRowId,
    required this.onRow,
  });

  final _Param param;
  final List<(RowRecord, _Reading)> items;
  final String? selectedRowId;
  final ValueChanged<String> onRow;

  @override
  Widget build(BuildContext context) {
    final vals = items.map((e) => e.$2.value).whereType<double>().toList();
    var lo = vals.reduce(math.min), hi = vals.reduce(math.max);
    final anyMin = items.map((e) => e.$2.min).whereType<double>().firstOrNull;
    final anyMax = items.map((e) => e.$2.max).whereType<double>().firstOrNull;
    if (anyMin != null) lo = math.min(lo, anyMin);
    if (anyMax != null) hi = math.max(hi, anyMax);
    final pad = math.max((hi - lo) * 0.2, param.decimals >= 2 ? 0.01 : 0.5);
    final minY = math.max(0.0, lo - pad);
    final maxY = hi + pad;
    final palette = [
      const Color(0xFF14B8A6),
      kMgmtBlue,
      DashboardColors.brand,
      const Color(0xFF86EFAC),
      const Color(0xFF06B6D4),
      DashboardColors.brandGreen,
    ];

    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: math.max((maxY - minY) / 4, 0.01),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: DashboardColors.cardBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (anyMin != null && anyMin >= minY)
              HorizontalLine(y: anyMin, color: kMgmtAmber.withValues(alpha: 0.6),
                  strokeWidth: 1, dashArray: const [6, 4]),
            if (anyMax != null && anyMax <= maxY)
              HorizontalLine(y: anyMax, color: kMgmtAmber.withValues(alpha: 0.6),
                  strokeWidth: 1, dashArray: const [6, 4]),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: math.max((maxY - minY) / 4, 0.01),
              getTitlesWidget: (v, _) => Text(
                param.decimals >= 2 ? v.toStringAsFixed(2) : v.toStringAsFixed(param.decimals == 0 ? 0 : 1),
                style: bvText(fontSize: 10, color: DashboardColors.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                final selected = items[i].$1.id == selectedRowId;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    items[i].$1.rowName,
                    style: bvText(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? DashboardColors.brand : DashboardColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchCallback: (event, resp) {
            if (event is FlTapUpEvent && resp?.spot != null) {
              final i = resp!.spot!.touchedBarGroupIndex;
              if (i >= 0 && i < items.length) onRow(items[i].$1.id);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorder: BorderSide(color: DashboardColors.cardBorder),
            tooltipRoundedRadius: 10,
            getTooltipItem: (group, gi, rod, ri) {
              final (row, r) = items[gi];
              return BarTooltipItem(
                '${row.rowName}\n',
                bvText(fontSize: 10.5, color: DashboardColors.textMuted),
                children: [
                  TextSpan(
                    text: '${param.fmt(rod.toY)} ${param.unit}${r.inherited ? ' (kế thừa khu)' : ''}',
                    style: bvText(fontSize: 12, fontWeight: FontWeight.w700,
                        color: DashboardColors.textPrimary),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < items.length; i++)
            BarChartGroupData(
              x: i,
              showingTooltipIndicators: items[i].$2.value == null ? const [] : const [0],
              barRods: [
                BarChartRodData(
                  toY: items[i].$2.value ?? minY,
                  width: 26,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: () {
                    final lvl = items[i].$2.level;
                    if (lvl == _Level.alert) return DashboardColors.risk;
                    if (lvl == _Level.watch) return kMgmtAmber;
                    final base = palette[i % palette.length];
                    return items[i].$2.inherited ? base.withValues(alpha: 0.55) : base;
                  }(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bảng theo dãy
// ─────────────────────────────────────────────────────────────────────────────

class _RowsTable extends StatelessWidget {
  const _RowsTable({
    required this.rows,
    required this.readingFor,
    required this.selectedRowId,
    required this.onRow,
  });

  final List<RowRecord> rows;
  final _Reading Function(_Param, String? rowId) readingFor;
  final String? selectedRowId;
  final ValueChanged<String> onRow;

  @override
  Widget build(BuildContext context) {
    final head = bvText(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: DashboardColors.textMuted,
      letterSpacing: 0.3,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Thông số theo dãy (hiện tại)',
              style: bvText(fontSize: 14, fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary)),
          const SizedBox(height: 10),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(flex: 8, child: Text('DÃY', style: head)),
                for (final p in _params)
                  Expanded(
                    flex: 9,
                    child: Text(
                      p.unit.isEmpty ? p.shortLabel.toUpperCase() : '${p.shortLabel.toUpperCase()} (${p.unit})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: head,
                    ),
                  ),
                Expanded(flex: 12, child: Text('TRẠNG THÁI', style: head)),
              ],
            ),
          ),
          // Dòng "Cả khu" = giá trị cảm biến chung.
          _ParamRowLine(
            label: 'Cả khu',
            readings: [for (final p in _params) readingFor(p, null)],
            emphasize: true,
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text('Khu chưa có dãy.',
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              ),
            )
          else
            for (final r in rows)
              _ParamRowLine(
                label: r.rowName,
                readings: [for (final p in _params) readingFor(p, r.id)],
                selected: r.id == selectedRowId,
                onTap: () => onRow(r.id),
              ),
        ],
      ),
    );
  }
}

class _ParamRowLine extends StatefulWidget {
  const _ParamRowLine({
    required this.label,
    required this.readings,
    this.emphasize = false,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final List<_Reading> readings;
  final bool emphasize;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_ParamRowLine> createState() => _ParamRowLineState();
}

class _ParamRowLineState extends State<_ParamRowLine> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final rs = widget.readings;
    final worst = rs.fold(_Level.noData, (a, r) => r.level.severity > a.severity ? r.level : a);
    final allInherited = rs.where((r) => r.value != null).isNotEmpty &&
        rs.where((r) => r.value != null).every((r) => r.inherited);
    final statusLabel = worst == _Level.alert
        ? 'Vượt ngưỡng'
        : worst == _Level.watch
            ? 'Theo dõi'
            : worst == _Level.stale
                ? 'Dữ liệu cũ'
                : worst == _Level.noData
                    ? 'Chưa có dữ liệu'
                    : 'Bình thường';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? DashboardColors.mint.withValues(alpha: 0.55)
                : _hover && widget.onTap != null
                    ? DashboardColors.lightMint.withValues(alpha: 0.7)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(color: DashboardColors.cardBorder, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: widget.emphasize
                              ? DashboardColors.textPrimary
                              : DashboardColors.brand,
                        ),
                      ),
                    ),
                    if (allInherited && !widget.emphasize) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Dãy chưa có sensor riêng — kế thừa giá trị khu',
                        child: Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 12, color: DashboardColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              for (final r in rs)
                Expanded(
                  flex: 9,
                  child: Text(
                    r.value == null ? '—' : r.param.fmt(r.value!),
                    style: bvText(
                      fontSize: 12.5,
                      fontWeight: r.level == _Level.alert || r.level == _Level.watch
                          ? FontWeight.w800
                          : widget.emphasize
                              ? FontWeight.w700
                              : FontWeight.w500,
                      color: r.value == null
                          ? DashboardColors.textMuted
                          : r.level == _Level.alert
                              ? DashboardColors.risk
                              : r.level == _Level.watch
                                  ? kMgmtAmber
                                  : r.inherited
                                      ? DashboardColors.textMuted
                                      : DashboardColors.textPrimary,
                    ),
                  ),
                ),
              Expanded(
                flex: 12,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _LevelBadge(level: worst, label: statusLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cảnh báo gần đây
// ─────────────────────────────────────────────────────────────────────────────

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.alerts,
    required this.onOpenAll,
    required this.onOpen,
  });

  final List<_AlertItem> alerts;
  final VoidCallback? onOpenAll;
  final ValueChanged<_AlertItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final head = bvText(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: DashboardColors.textMuted,
      letterSpacing: 0.3,
    );
    final shown = alerts.take(6).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Cảnh báo gần đây',
                    style: bvText(fontSize: 14, fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary)),
              ),
              MgmtOutlineButton(
                label: 'Xem tất cả',
                height: 30,
                onTap: onOpenAll,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(flex: 9, child: Text('THỜI GIAN', style: head)),
                Expanded(flex: 11, child: Text('THÔNG SỐ', style: head)),
                Expanded(flex: 8, child: Text('GIÁ TRỊ', style: head)),
                Expanded(flex: 12, child: Text('TRẠNG THÁI', style: head)),
              ],
            ),
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text('Không có cảnh báo môi trường trong 30 ngày.',
                    textAlign: TextAlign.center,
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              ),
            )
          else
            for (final a in shown) _AlertLine(a: a, onTap: () => onOpen(a)),
        ],
      ),
    );
  }
}

class _AlertLine extends StatelessWidget {
  const _AlertLine({required this.a, required this.onTap});
  final _AlertItem a;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final t = '${two(a.at.day)}/${two(a.at.month)} ${two(a.at.hour)}:${two(a.at.minute)}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: DashboardColors.cardBorder, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 9,
              child: Text(t, style: bvText(fontSize: 11.5, color: DashboardColors.textPrimary)),
            ),
            Expanded(
              flex: 11,
              child: Text(
                a.location.isEmpty ? a.paramLabel : '${a.paramLabel} (${a.location})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary),
              ),
            ),
            Expanded(
              flex: 8,
              child: Text(a.valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700,
                      color: DashboardColors.risk)),
            ),
            Expanded(
              flex: 12,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: DashboardColors.risk, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      a.statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(fontSize: 11, fontWeight: FontWeight.w600,
                          color: DashboardColors.risk),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
