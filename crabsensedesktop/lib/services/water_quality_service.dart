import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/water_quality.dart';
import '../utils/water_quality_evaluator.dart';
import '../utils/water_trend_window.dart';
import 'cloud_api_client.dart';
import 'water_quality_cloud_merge.dart';

/// Poll `/api/iot/live` — chỉ giữ cảm biến thật, không mock.
class WaterQualityService extends ChangeNotifier {
  WaterQualityService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  void updateSession(AuthSession session) {
    _session = session;
    if (_pollActive) {
      unawaited(_liveCycle(full: true));
    } else {
      notifyListeners();
    }
  }

  static const _pollInterval = Duration(seconds: 3);
  static const _staleAfter = Duration(minutes: 2);

  static const chartRangeLabels = ['1H', '6H', '24H', '7 Ngày', '30 Ngày'];
  static const chartRangeMinutes = [60, 6 * 60, 24 * 60, 7 * 24 * 60, 30 * 24 * 60];

  List<WaterSensorReading> _readings = [];
  List<RealtimeChartPoint> _chartSeries = [];
  List<RealtimeTableRow> _recentRows = [];
  List<RealtimeDeviceLink> _devices = [];
  WaterSensorType? _chartMetric;
  int _chartRangeIndex = 0;
  String? _areaFilterId;
  String? _deviceFilter;
  String _sensorGroup = 'all';
  bool _showThreshold = true;
  DateTime? _lastCloudOkAt;

  bool _loading = false;
  bool _chartLoading = false;
  bool _cloudLive = false;
  String? _cloudError;
  String? _deviceCode;
  DateTime? _lastRealtimeAt;

  Timer? _pollTimer;
  bool _pollActive = false;
  bool _realtimeBusy = false;
  bool _trendBusy = false;

  List<WaterSensorReading> get readings => List.unmodifiable(_scoped(_readings));
  List<WaterSensorReading> get allReadings => List.unmodifiable(_readings);
  List<RealtimeChartPoint> get chartSeries => List.unmodifiable(_chartSeries);
  List<RealtimeTableRow> get recentRows => List.unmodifiable(_recentRows);
  List<RealtimeDeviceLink> get devices => List.unmodifiable(_devices);
  String? get areaFilterId => _areaFilterId ?? _session.selectedFarm.id;
  String? get deviceFilter => _deviceFilter;
  String get sensorGroup => _sensorGroup;
  bool get showThreshold => _showThreshold;
  DateTime? get lastCloudOkAt => _lastCloudOkAt;
  List<WaterSensorType> get availableMetrics =>
      {for (final r in _readings) r.type}.toList()
        ..sort(
          (a, b) => WaterSensorType.cloudFirst
              .indexOf(a)
              .compareTo(WaterSensorType.cloudFirst.indexOf(b)),
        );

  WaterSensorType? get chartMetric => _chartMetric;
  int get chartRangeIndex => _chartRangeIndex;
  String get chartRangeLabel => chartRangeLabels[_chartRangeIndex];
  int get chartRangeMinutesValue => chartRangeMinutes[_chartRangeIndex];
  bool get isLoading => _loading;
  bool get chartLoading => _chartLoading;
  bool get cloudLive => _cloudLive;
  String? get cloudError => _cloudError;
  String? get deviceCode => _deviceCode;
  DateTime? get lastRealtimeAt => _lastRealtimeAt;

  bool get isFresh {
    final at = _lastRealtimeAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < _staleAfter;
  }

  bool get isLive => _cloudLive && isFresh && _readings.isNotEmpty;

  bool get deviceOnline =>
      _devices.any((d) => d.online) || (isFresh && _readings.isNotEmpty);

  String get lastUpdateLabel {
    final at = _lastRealtimeAt;
    if (at == null) return 'Chưa có dữ liệu';
    final ago = DateTime.now().difference(at);
    if (ago.inSeconds < 15) return 'Vừa xong';
    if (ago.inMinutes < 1) return '${ago.inSeconds} giây trước';
    if (ago.inMinutes < 60) return '${ago.inMinutes} phút trước';
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}:'
        '${at.second.toString().padLeft(2, '0')}';
  }

  String get lastUpdateClock {
    final at = _lastRealtimeAt;
    if (at == null) return '—';
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}:'
        '${at.second.toString().padLeft(2, '0')}';
  }

  List<RealtimeLocationGroup> get locationGroups {
    final byLoc = <String, List<WaterSensorReading>>{};
    for (final r in _readings) {
      final key = (r.location ?? '').trim();
      if (key.isEmpty) continue;
      byLoc.putIfAbsent(key, () => []).add(r);
    }
    if (byLoc.length < 2) return const [];
    return byLoc.entries
        .map((e) => RealtimeLocationGroup(name: e.key, readings: e.value))
        .toList();
  }

  List<RealtimeWaterAlert> get thresholdAlerts {
    return _readings
        .where(
          (r) =>
              r.status == WaterSensorStatus.exceeded ||
              r.status == WaterSensorStatus.danger ||
              r.status == WaterSensorStatus.offline,
        )
        .map(
          (r) => RealtimeWaterAlert(
            title: r.status == WaterSensorStatus.offline
                ? '${r.type.label} mất tín hiệu'
                : '${r.type.label} ${r.status.label.toLowerCase()}',
            detail: r.offline ? 'Không nhận được mẫu' : 'Hiện tại: ${r.displayValue}',
            status: r.status,
          ),
        )
        .toList();
  }

  void startLiveUpdates() {
    if (_pollActive) return;
    _pollActive = true;
    _pollTimer?.cancel();
    unawaited(_liveCycle(full: true));
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_liveCycle(full: false));
    });
  }

  void stopLiveUpdates() {
    _pollActive = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _liveCycle({required bool full}) async {
    await refresh(full: full);
    if (full || _chartSeries.isEmpty) {
      await refreshTrend(quiet: !full);
    }
  }

  @override
  void dispose() {
    stopLiveUpdates();
    super.dispose();
  }

  Future<void> refresh({bool full = true}) async {
    if (full) {
      _loading = true;
      _cloudError = null;
      notifyListeners();
    } else if (_realtimeBusy) {
      return;
    }

    _realtimeBusy = true;
    try {
      final live = await _api.fetchIotLive(
        _session.token,
        farmingAreaId: areaFilterId,
      );
      _cloudLive = true;
      _cloudError = null;
      _lastCloudOkAt = DateTime.now();
      _readings = _readingsFromLive(live);
      _devices = _devicesFromLive(live);
      _deviceCode = _devices.isEmpty ? null : _devices.first.code;
      if (_deviceFilter == null && _deviceCode != null) {
        _deviceFilter = _deviceCode;
      }

      DateTime? latest;
      for (final r in _readings) {
        final dt = r.measuredAt;
        if (dt != null && (latest == null || dt.isAfter(latest))) latest = dt;
      }
      _lastRealtimeAt = latest;

      _ensureChartMetric();
      _appendLiveTick();
      if (full) unawaited(refreshRecent());
      notifyListeners();
    } on CloudApiException catch (e) {
      _cloudLive = false;
      _cloudError = e.message;
      if (full) {
        _readings = [];
        _devices = [];
        _chartSeries = [];
      }
      notifyListeners();
    } catch (e) {
      _cloudLive = false;
      _cloudError = 'Realtime: $e';
      if (full) {
        _readings = [];
        _devices = [];
        _chartSeries = [];
      }
      notifyListeners();
    } finally {
      _realtimeBusy = false;
      if (full) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  List<RealtimeDeviceLink> _devicesFromLive(List<Map<String, dynamic>> live) {
    final map = <String, RealtimeDeviceLink>{};
    for (final row in live) {
      final code = (row['deviceCode'] ?? row['DeviceCode'] ?? '').toString();
      if (code.isEmpty) continue;
      final status =
          (row['deviceStatus'] ?? row['DeviceStatus'] ?? '').toString();
      final seen = DateTime.tryParse(
        (row['sensorLastSeenAt'] ??
                row['SensorLastSeenAt'] ??
                row['latestMeasuredAt'] ??
                row['LatestMeasuredAt'] ??
                '')
            .toString(),
      );
      final online = status.toLowerCase() == 'online' ||
          (seen != null && DateTime.now().difference(seen) < _staleAfter);
      final prev = map[code];
      if (prev == null || (online && !prev.online)) {
        map[code] = RealtimeDeviceLink(
          code: code,
          online: online,
          lastSeen: seen ?? prev?.lastSeen,
        );
      }
    }
    return map.values.toList();
  }

  List<WaterSensorReading> _readingsFromLive(List<Map<String, dynamic>> live) {
    final prevById = {for (final r in _readings) if (r.sensorId != null) r.sensorId!: r};
    final out = <WaterSensorReading>[];
    for (final m in live) {
      final rawVal = m['latestValue'] ?? m['LatestValue'];
      if (rawVal is! num) continue;
      final type = _mapSensorType((m['sensorType'] ?? m['SensorType'] ?? '').toString());
      final id = (m['sensorId'] ?? m['SensorId'] ?? '').toString();
      final unit = (m['unit'] ?? m['Unit'] ?? '').toString();
      final alarm = (m['alarm'] ?? m['Alarm'])?.toString();
      final deviceStatus =
          (m['deviceStatus'] ?? m['DeviceStatus'] ?? '').toString();
      final offline = (m['isActive'] == false) ||
          deviceStatus.toLowerCase() == 'offline';
      final min = (m['minThreshold'] ?? m['MinThreshold'] as num?)?.toDouble();
      final max = (m['maxThreshold'] ?? m['MaxThreshold'] as num?)?.toDouble();
      final fallback = WaterQualityEvaluator.thresholdFor(type);
      final threshold = SensorThreshold(
        goodRangeLabel: (alarm == null || alarm.isEmpty)
            ? fallback.goodRangeLabel
            : alarm,
        min: min ?? fallback.min,
        max: max ?? fallback.max,
      );
      WaterSensorStatus status;
      if (offline) {
        status = WaterSensorStatus.offline;
      } else if (alarm != null && alarm.isNotEmpty) {
        status = alarm.contains('below') || alarm.contains('above')
            ? WaterSensorStatus.exceeded
            : WaterSensorStatus.exceeded;
      } else {
        status = WaterQualityEvaluator.evaluate(type, rawVal.toDouble());
      }
      final measured = DateTime.tryParse(
        (m['latestMeasuredAt'] ?? m['LatestMeasuredAt'] ?? '').toString(),
      );
      out.add(
        WaterSensorReading(
          type: type,
          value: rawVal.toDouble(),
          unit: unit.isEmpty ? _defaultUnit(type) : unit,
          status: status,
          threshold: threshold,
          offline: offline,
          sensorId: id.isEmpty ? null : id,
          location: (m['locationName'] ?? m['LocationName'] ?? '').toString(),
          previousValue: prevById[id]?.value,
          deviceCode: (m['deviceCode'] ?? m['DeviceCode'])?.toString(),
          deviceStatus: deviceStatus,
          measuredAt: measured,
        ),
      );
    }
    out.sort(
      (a, b) => WaterSensorType.cloudFirst
          .indexOf(a.type)
          .compareTo(WaterSensorType.cloudFirst.indexOf(b.type)),
    );
    return out;
  }

  WaterSensorType _mapSensorType(String raw) {
    final t = raw.toLowerCase();
    if (t.contains('ph')) return WaterSensorType.ph;
    if (t.contains('temp')) return WaterSensorType.temperature;
    if (t.contains('tds')) return WaterSensorType.tds;
    if (t.contains('flow')) return WaterSensorType.flow;
    if (t.contains('level') || t.contains('muc')) {
      return WaterSensorType.waterLevel;
    }
    if (t.contains('do') || t.contains('oxy')) {
      return WaterSensorType.dissolvedOxygen;
    }
    if (t.contains('salin') || t.contains('salt') || t.contains('man')) {
      return WaterSensorType.salinity;
    }
    if (t.contains('orp')) return WaterSensorType.orp;
    if (t.contains('nh3') || t.contains('ammon')) return WaterSensorType.nh3;
    if (t.contains('no2') || t.contains('nitrit')) return WaterSensorType.no2;
    return WaterSensorType.temperature;
  }

  String _defaultUnit(WaterSensorType type) => switch (type) {
        WaterSensorType.ph => '',
        WaterSensorType.temperature => '°C',
        WaterSensorType.tds => 'ppt',
        WaterSensorType.flow => 'L/min',
        WaterSensorType.waterLevel => '%',
        WaterSensorType.dissolvedOxygen => 'mg/L',
        WaterSensorType.salinity => 'ppt',
        WaterSensorType.orp => 'mV',
        WaterSensorType.nh3 => 'mg/L',
        WaterSensorType.no2 => 'mg/L',
      };

  void _ensureChartMetric() {
    final available = availableMetrics;
    if (available.isEmpty) {
      _chartMetric = null;
      return;
    }
    if (_chartMetric == null || !available.contains(_chartMetric)) {
      _chartMetric = available.contains(WaterSensorType.temperature)
          ? WaterSensorType.temperature
          : available.first;
    }
  }

  WaterSensorReading? get _selectedReading {
    final metric = _chartMetric;
    if (metric == null) return null;
    for (final r in readings) {
      if (r.type == metric) return r;
    }
    return null;
  }

  void _appendLiveTick() {
    final reading = _selectedReading;
    final at = reading?.measuredAt ?? _lastRealtimeAt;
    if (reading == null || at == null) return;
    final start = WaterTrendWindow.windowStart(chartRangeMinutesValue);
    if (at.isBefore(start)) return;
    _chartSeries = [
      ..._chartSeries.where((p) => !p.timestamp.isBefore(start)),
      RealtimeChartPoint(
        xMinutes: at.difference(start).inSeconds / 60.0,
        label: WaterQualityCloudMerge.axisLabelFor(at, chartRangeMinutesValue),
        timestamp: at,
        value: reading.value,
      ),
    ];
    _chartSeries = _downsample(_chartSeries, chartRangeMinutesValue);
  }

  Future<void> refreshTrend({bool quiet = false}) async {
    if (_trendBusy) return;
    final reading = _selectedReading;
    if (reading?.sensorId == null) {
      _chartSeries = [];
      if (!quiet) notifyListeners();
      return;
    }

    _trendBusy = true;
    if (!quiet) {
      _chartLoading = true;
      notifyListeners();
    }

    try {
      final range = chartRangeMinutesValue;
      final now = DateTime.now();
      final from = now.subtract(Duration(minutes: range));
      final rows = await _api.fetchSensorHistory(
        _session.token,
        sensorId: reading!.sensorId!,
        from: from,
        to: now,
      );
      final points = <RealtimeChartPoint>[];
      for (final row in rows) {
        final val = row['value'] ?? row['Value'];
        final rawAt = row['measuredAt'] ?? row['MeasuredAt'];
        if (val is! num || rawAt == null) continue;
        final at = DateTime.tryParse(rawAt.toString());
        if (at == null) continue;
        points.add(
          RealtimeChartPoint(
            xMinutes: at.difference(from).inSeconds / 60.0,
            label: WaterQualityCloudMerge.axisLabelFor(at, range),
            timestamp: at.toLocal(),
            value: val.toDouble(),
          ),
        );
      }
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _chartSeries = _downsample(points, range);
    } catch (_) {
      _appendLiveTick();
    } finally {
      _trendBusy = false;
      if (!quiet) _chartLoading = false;
      notifyListeners();
    }
  }

  List<RealtimeChartPoint> _downsample(
    List<RealtimeChartPoint> points,
    int rangeMinutes,
  ) {
    final max = WaterTrendWindow.maxDisplayPoints(rangeMinutes);
    if (points.length <= max) return points;
    final step = points.length / max;
    final out = <RealtimeChartPoint>[];
    for (var i = 0; i < max; i++) {
      out.add(points[(i * step).floor().clamp(0, points.length - 1)]);
    }
    if (out.isNotEmpty && out.last.timestamp != points.last.timestamp) {
      out[out.length - 1] = points.last;
    }
    return out;
  }

  String get area => _session.selectedFarm.name;
  String get device => _deviceCode ?? '';
  String get timeRange => chartRangeLabel;
  String get statusFilter => 'Tất cả';
  List<WaterSensorReading> get filteredReadings => readings;
  List<WaterTrendPoint> get trendPoints => const [];
  List<WaterHistoryRow> get history => const [];
  String get aiInsight => '';
  List<String> get aiRecommendations => const [];
  void setArea(String v) {}
  void setDevice(String v) {}
  void setTimeRange(String v) => refresh(full: true);
  void setStatusFilter(String v) {}

  List<WaterSensorReading> _scoped(List<WaterSensorReading> src) {
    var list = src;
    final device = _deviceFilter;
    if (device != null && device.isNotEmpty) {
      list = list.where((r) => (r.deviceCode ?? '') == device).toList();
    }
    switch (_sensorGroup) {
      case 'water':
        list = list
            .where((r) =>
                r.type == WaterSensorType.ph ||
                r.type == WaterSensorType.tds ||
                r.type == WaterSensorType.salinity ||
                r.type == WaterSensorType.dissolvedOxygen)
            .toList();
      case 'temp':
        list = list.where((r) => r.type == WaterSensorType.temperature).toList();
      case 'other':
        list = list
            .where((r) =>
                r.type != WaterSensorType.temperature &&
                r.type != WaterSensorType.ph &&
                r.type != WaterSensorType.tds)
            .toList();
    }
    return list;
  }

  WaterSensorReading? readingOf(WaterSensorType type) {
    for (final r in readings) {
      if (r.type == type) return r;
    }
    return null;
  }

  void setAreaId(String? id) {
    final next = (id == null || id.isEmpty) ? _session.selectedFarm.id : id;
    if (next == areaFilterId) return;
    _areaFilterId = next;
    _deviceFilter = null;
    unawaited(_liveCycle(full: true));
  }

  void setDeviceCode(String? code) {
    final next = (code == null || code.isEmpty) ? null : code;
    if (next == _deviceFilter) return;
    _deviceFilter = next;
    _chartSeries = [];
    notifyListeners();
    unawaited(refreshTrend(quiet: false));
    unawaited(refreshRecent());
  }

  void setSensorGroup(String group) {
    if (_sensorGroup == group) return;
    _sensorGroup = group;
    notifyListeners();
  }

  void setShowThreshold(bool v) {
    if (_showThreshold == v) return;
    _showThreshold = v;
    notifyListeners();
  }

  List<List<RealtimeChartPoint>> get chartSegments {
    if (_chartSeries.isEmpty) return const [];
    final gap = _gapThreshold;
    final segs = <List<RealtimeChartPoint>>[];
    var cur = <RealtimeChartPoint>[_chartSeries.first];
    for (var i = 1; i < _chartSeries.length; i++) {
      final dt = _chartSeries[i].timestamp.difference(_chartSeries[i - 1].timestamp);
      if (dt > gap) {
        segs.add(cur);
        cur = [_chartSeries[i]];
      } else {
        cur.add(_chartSeries[i]);
      }
    }
    segs.add(cur);
    return segs;
  }

  Duration get _gapThreshold {
    final m = chartRangeMinutesValue;
    if (m <= 60) return const Duration(seconds: 90);
    if (m <= 360) return const Duration(minutes: 8);
    if (m <= 1440) return const Duration(minutes: 20);
    return const Duration(hours: 3);
  }

  Future<void> refreshRecent() async {
    final temp = readingOf(WaterSensorType.temperature);
    final ph = readingOf(WaterSensorType.ph);
    final tds = readingOf(WaterSensorType.tds);
    final ids = [temp?.sensorId, ph?.sensorId, tds?.sensorId]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();
    if (ids.isEmpty) {
      _recentRows = [];
      notifyListeners();
      return;
    }
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(hours: 1));
      final buckets = <int, RealtimeTableRow>{};
      void put(int key, DateTime at, {double? temperature, double? ph, double? tds}) {
        final prev = buckets[key];
        buckets[key] = RealtimeTableRow(
          at: at,
          temperature: temperature ?? prev?.temperature,
          ph: ph ?? prev?.ph,
          tds: tds ?? prev?.tds,
        );
      }

      Future<void> ingest(String? sensorId, void Function(int key, DateTime at, double v) apply) async {
        if (sensorId == null) return;
        final rows = await _api.fetchSensorHistory(
          _session.token,
          sensorId: sensorId,
          from: from,
          to: now,
          pageSize: 80,
        );
        for (final row in rows) {
          final val = row['value'] ?? row['Value'];
          final rawAt = row['measuredAt'] ?? row['MeasuredAt'];
          if (val is! num || rawAt == null) continue;
          final at = DateTime.tryParse(rawAt.toString())?.toLocal();
          if (at == null) continue;
          apply(at.millisecondsSinceEpoch ~/ 5000, at, val.toDouble());
        }
      }

      await ingest(temp?.sensorId, (key, at, v) => put(key, at, temperature: v));
      await ingest(ph?.sensorId, (key, at, v) => put(key, at, ph: v));
      await ingest(tds?.sensorId, (key, at, v) => put(key, at, tds: v));

      final list = buckets.values.toList()
        ..sort((a, b) => b.at.compareTo(a.at));
      _recentRows = list.take(20).map((r) {
        final tMin = temp?.threshold.min;
        final tMax = temp?.threshold.max;
        final pMin = ph?.threshold.min;
        final pMax = ph?.threshold.max;
        final dMin = tds?.threshold.min;
        final dMax = tds?.threshold.max;
        var out = false;
        if (r.temperature != null && tMin != null && tMax != null) {
          out = out || r.temperature! < tMin || r.temperature! > tMax;
        }
        if (r.ph != null && pMin != null && pMax != null) {
          out = out || r.ph! < pMin || r.ph! > pMax;
        }
        if (r.tds != null && dMin != null && dMax != null) {
          out = out || r.tds! < dMin || r.tds! > dMax;
        }
        return RealtimeTableRow(
          at: r.at,
          temperature: r.temperature,
          ph: r.ph,
          tds: r.tds,
          status: out ? 'Vượt ngưỡng' : 'Bình thường',
          outOfRange: out,
        );
      }).toList();
    } catch (_) {
      // giữ bảng cũ
    }
    notifyListeners();
  }

  String exportRecentCsv() {
    final buf = StringBuffer('Thoi gian,Nhiet do,pH,TDS,Trang thai\n');
    for (final r in _recentRows) {
      buf.writeln(
        '${r.at.toIso8601String()},'
        '${r.temperature?.toString() ?? ''},'
        '${r.ph?.toString() ?? ''},'
        '${r.tds?.toString() ?? ''},'
        '${r.status}',
      );
    }
    return buf.toString();
  }

  void setChartMetric(WaterSensorType type) {
    if (_chartMetric == type) return;
    _chartMetric = type;
    _chartSeries = [];
    notifyListeners();
    unawaited(refreshTrend(quiet: false));
  }

  void setChartRangeIndex(int i) {
    _chartRangeIndex = i.clamp(0, chartRangeLabels.length - 1);
    _chartSeries = [];
    notifyListeners();
    unawaited(refreshTrend(quiet: false));
  }
}
