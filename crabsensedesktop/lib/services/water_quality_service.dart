import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../data/mock_water_quality_data.dart';
import '../models/auth_models.dart';
import '../models/water_quality.dart';
import 'cloud_api_client.dart';
import '../utils/water_trend_window.dart';

class WaterQualityService extends ChangeNotifier {
  WaterQualityService({
    required AuthSession session,
    CloudApiClient? api,
    String? deviceMac,
  })  : _session = session,
        _api = api ?? CloudApiClient(),
        _mac = CloudApiClient.normalizeMac(
          deviceMac ?? AppEnv.defaultDeviceMac ?? '',
        ) {
    _readings = MockWaterQualityData.randomReadings();
    _seedTrendBuffer();
    _history = MockWaterQualityData.historyRows();
  }

  void _seedTrendBuffer() {
    _trendBuffer
      ..clear()
      ..addAll(MockWaterQualityData.trendForRange(chartRangeMinutesValue));
    _trendPoints = WaterTrendWindow.project(_trendBuffer, chartRangeMinutesValue);
  }

  AuthSession _session;
  final CloudApiClient _api;
  final String _mac;

  void updateSession(AuthSession session) {
    _session = session;
    notifyListeners();
  }

  static const _pollInterval = Duration(seconds: 3);

  static const chartRangeLabels = ['30 phút', '1 giờ', '24 giờ'];
  static const chartRangeMinutes = [30, 60, 24 * 60];

  List<WaterSensorReading> _readings = [];
  List<WaterTrendPoint> _trendPoints = [];
  final List<WaterTrendPoint> _trendBuffer = [];
  List<WaterHistoryRow> _history = [];

  String _area = 'Khu A';
  String _device = 'Sensor-01';
  String _timeRange = '24h';
  String _statusFilter = 'Tất cả';
  int _chartRangeIndex = 0;

  bool _chartLoading = false;
  String? _trendError;

  bool _loading = false;
  bool _cloudLive = false;
  String? _cloudError;
  String? _historyError;
  String? _deviceCode;
  DateTime? _lastRealtimeAt;

  Timer? _pollTimer;
  bool _pollActive = false;
  bool _realtimeBusy = false;
  bool _trendBusy = false;

  List<WaterSensorReading> get readings => List.unmodifiable(_readings);
  String get area => _area;
  String get device => _device;
  String get timeRange => _timeRange;
  String get statusFilter => _statusFilter;
  int get chartRangeIndex => _chartRangeIndex;
  String get chartRangeLabel => chartRangeLabels[_chartRangeIndex];
  int get chartRangeMinutesValue => chartRangeMinutes[_chartRangeIndex];
  bool get isLoading => _loading;
  bool get chartLoading => _chartLoading;
  String? get trendError => _trendError;
  bool get cloudLive => _cloudLive;
  String? get cloudError => _cloudError;
  String? get historyError => _historyError;
  String? get deviceMac => _mac.isEmpty ? null : _mac;
  String? get deviceCode => _deviceCode;
  DateTime? get lastRealtimeAt => _lastRealtimeAt;

  List<WaterSensorReading> get filteredReadings {
    var list = _readings;
    if (_statusFilter == 'Bình thường') {
      list = list
          .where(
            (r) =>
                r.status == WaterSensorStatus.normal ||
                r.status == WaterSensorStatus.good,
          )
          .toList();
    } else if (_statusFilter == 'Cảnh báo') {
      list = list
          .where(
            (r) =>
                r.status == WaterSensorStatus.exceeded ||
                r.status == WaterSensorStatus.danger ||
                r.status == WaterSensorStatus.monitoring,
          )
          .toList();
    } else if (_statusFilter == 'Offline') {
      list = list.where((r) => r.offline).toList();
    }
    return list;
  }

  List<WaterTrendPoint> get trendPoints => _trendPoints;
  List<WaterHistoryRow> get history => _history;

  /// Bật poll realtime mỗi 3s (gọi từ màn Cảm biến môi trường).
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
    await refreshTrend(quiet: !full);
  }

  @override
  void dispose() {
    stopLiveUpdates();
    super.dispose();
  }

  /// [full]: true = realtime + history; false = chỉ realtime (poll).
  Future<void> refresh({bool full = true}) async {
    if (full) {
      _loading = true;
      _cloudError = null;
      _historyError = null;
      notifyListeners();
    } else if (_realtimeBusy) {
      return;
    }

    _realtimeBusy = true;
    try {
      final live = await _api.fetchIotLive(
        _session.token,
        farmingAreaId: _session.selectedFarm.id,
      );
      if (live.isEmpty) {
        _cloudLive = true;
        _cloudError = null;
        _readings = [];
        _lastRealtimeAt = DateTime.now();
      } else {
        _readings = _readingsFromLive(live);
        _device = (live.first['deviceCode'] ?? live.first['DeviceCode'] ?? _device)
            .toString();
        _deviceCode = _device;
        DateTime? latest;
        for (final row in live) {
          final raw = row['latestMeasuredAt'] ?? row['LatestMeasuredAt'];
          final dt = raw == null ? null : DateTime.tryParse(raw.toString());
          if (dt != null && (latest == null || dt.isAfter(latest))) latest = dt;
        }
        _lastRealtimeAt = latest ?? DateTime.now();
        _cloudLive = true;
        _cloudError = null;
        _pushLiveTrendTick(_readings, _lastRealtimeAt!);
      }
      notifyListeners();
    } on CloudApiException catch (e) {
      _cloudLive = false;
      _cloudError = e.message;
      if (full) _applyMockOnly();
      notifyListeners();
    } catch (e) {
      _cloudLive = false;
      _cloudError = 'Realtime: $e';
      if (full) _applyMockOnly();
      notifyListeners();
    } finally {
      _realtimeBusy = false;
    }

    if (!full) return;

    if (full) {
      _loading = false;
      notifyListeners();
    }
  }

  List<WaterSensorReading> _readingsFromLive(List<Map<String, dynamic>> live) {
    return live.map((m) {
      final type = _mapSensorType((m['sensorType'] ?? '').toString());
      final value = (m['latestValue'] as num?)?.toDouble() ?? 0;
      final unit = (m['unit'] ?? m['Unit'] ?? '').toString();
      final alarm = (m['alarm'] ?? m['Alarm'])?.toString();
      final offline = (m['isActive'] == false) ||
          (m['deviceStatus'] ?? '').toString().toLowerCase() == 'offline';
      return WaterSensorReading(
        type: type,
        value: value,
        unit: unit.isEmpty ? _defaultUnit(type) : unit,
        status: offline
            ? WaterSensorStatus.offline
            : (alarm != null && alarm.isNotEmpty)
                ? WaterSensorStatus.exceeded
                : WaterSensorStatus.good,
        threshold: SensorThreshold(
          goodRangeLabel: alarm == null || alarm.isEmpty ? 'OK' : alarm,
        ),
        offline: offline,
      );
    }).toList();
  }

  WaterSensorType _mapSensorType(String raw) {
    final t = raw.toLowerCase();
    if (t.contains('ph')) return WaterSensorType.ph;
    if (t.contains('temp')) return WaterSensorType.temperature;
    if (t.contains('tds')) return WaterSensorType.tds;
    if (t.contains('flow')) return WaterSensorType.flow;
    if (t.contains('level') || t.contains('muc')) return WaterSensorType.waterLevel;
    if (t.contains('do') || t.contains('oxy')) return WaterSensorType.dissolvedOxygen;
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
        WaterSensorType.tds => 'ppm',
        WaterSensorType.flow => 'L/min',
        WaterSensorType.waterLevel => 'cm',
        WaterSensorType.dissolvedOxygen => 'mg/L',
        WaterSensorType.salinity => 'ppt',
        WaterSensorType.orp => 'mV',
        WaterSensorType.nh3 => 'mg/L',
        WaterSensorType.no2 => 'mg/L',
      };

  void _pushLiveTrendTick(List<WaterSensorReading> readings, DateTime at) {
    double v(WaterSensorType t) {
      for (final r in readings) {
        if (r.type == t) return r.value;
      }
      return 0;
    }

    _trendBuffer.add(
      WaterTrendPoint(
        xMinutes: 0,
        label:
            '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
        timestamp: at,
        ph: v(WaterSensorType.ph),
        temperature: v(WaterSensorType.temperature),
        tds: v(WaterSensorType.tds),
        flow: v(WaterSensorType.flow),
        dissolvedOxygen: v(WaterSensorType.dissolvedOxygen),
      ),
    );
    while (_trendBuffer.length > 60) {
      _trendBuffer.removeAt(0);
    }
    _trendPoints = WaterTrendWindow.project(_trendBuffer, chartRangeMinutesValue);
  }

  /// Cửa sổ realtime [now - range, now] — poll mỗi 3s cùng gauge.
  Future<void> refreshTrend({bool quiet = false}) async {
    if (_trendBusy) return;
    _trendBusy = true;

    final range = chartRangeMinutesValue;
    final now = DateTime.now();

    if (!quiet) {
      _chartLoading = true;
      _trendError = null;
      notifyListeners();
    }

    try {
      if (_trendBuffer.isEmpty) {
        _pushMockTrendTick(now, range);
      } else {
        _trendPoints = WaterTrendWindow.project(_trendBuffer, range, now);
        _trendError = null;
      }
    } catch (e) {
      _trendError = '$e';
      _pushMockTrendTick(now, range);
    } finally {
      _trendBusy = false;
      if (!quiet) _chartLoading = false;
      notifyListeners();
    }
  }

  void _pushMockTrendTick(DateTime now, int rangeMinutes) {
    final sample = _trendPointFromReadingsOrMock(now);
    _trendBuffer.add(sample);
    final pruned = WaterTrendWindow.prune(_trendBuffer, rangeMinutes, now);
    _trendBuffer
      ..clear()
      ..addAll(pruned);
    _trendPoints = WaterTrendWindow.project(_trendBuffer, rangeMinutes, now);
  }

  WaterTrendPoint _trendPointFromReadingsOrMock(DateTime now) {
    double? v(WaterSensorType t) {
      for (final r in _readings) {
        if (r.type == t) return r.value;
      }
      return null;
    }

    final mock = MockWaterQualityData.trendLiveSample(now);
    return WaterTrendPoint(
      xMinutes: 0,
      label: mock.label,
      timestamp: now,
      ph: v(WaterSensorType.ph) ?? mock.ph,
      temperature: v(WaterSensorType.temperature) ?? mock.temperature,
      tds: v(WaterSensorType.tds) ?? mock.tds,
      flow: v(WaterSensorType.flow) ?? mock.flow,
      dissolvedOxygen: mock.dissolvedOxygen,
    );
  }

  /// Tải lại biểu đồ (đổi khoảng thời gian).
  Future<void> loadTrendChart() => refreshTrend(quiet: false);

  Future<void> _loadHistoryTable() async {
    _historyError = null;
    _history = const [];
  }

  void _applyMockOnly() {
    _readings = MockWaterQualityData.randomReadings();
    _seedTrendBuffer();
    _history = MockWaterQualityData.historyRows();
  }

  int _minutesForFilterRange(String range) => switch (range) {
        '7 ngày' => 60 * 24 * 7,
        '30 ngày' => 60 * 24 * 30,
        _ => 60 * 24,
      };

  void setArea(String v) {
    _area = v;
    notifyListeners();
  }

  void setDevice(String v) {
    _device = v;
    notifyListeners();
  }

  void setTimeRange(String v) {
    _timeRange = v;
    refresh(full: true);
  }

  void setStatusFilter(String v) {
    _statusFilter = v;
    notifyListeners();
  }

  void setChartRangeIndex(int i) {
    _chartRangeIndex = i.clamp(0, chartRangeLabels.length - 1);
    _seedTrendBuffer();
    refreshTrend(quiet: false);
  }

  String get aiInsight => _cloudLive
      ? 'Realtime Cloud mỗi ${_pollInterval.inSeconds}s — '
          'nhiệt, pH, TDS, lưu lượng, mực nước từ $_mac. '
          'DO/mặn/ORP/NH3/NO2: mock.'
      : MockWaterQualityData.aiInsight;

  List<String> get aiRecommendations => _cloudLive
      ? [
          'Nguồn: ${AppEnv.cloudApiUrl}/api/iot/live',
          if (_lastRealtimeAt != null)
            'Cập nhật gần nhất: $_lastRealtimeAt',
          if (_trendError != null) 'Biểu đồ: $_trendError',
          if (_historyError != null) 'Lịch sử: $_historyError',
          if (_cloudError != null) 'Lỗi: $_cloudError',
          ...MockWaterQualityData.aiRecommendations,
        ]
      : MockWaterQualityData.aiRecommendations;
}
