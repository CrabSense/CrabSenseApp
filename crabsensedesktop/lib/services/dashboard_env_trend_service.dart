import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/water_quality.dart';
import '../utils/live_trend_bootstrap.dart';
import '../utils/water_trend_window.dart';

/// Xu hướng pH & nhiệt độ từ sensor Cloud.
class DashboardEnvTrendService extends ChangeNotifier {
  static const rangeMinutes = 30;
  static const liveWindowMinutes = 30;
  static const pollInterval = Duration(seconds: 3);

  final List<WaterTrendPoint> _buffer = [];
  List<WaterTrendPoint> _points = [];
  WaterTrendPoint? _emaState;
  Timer? _timer;
  bool _active = false;
  bool _liveApi = false;

  List<WaterTrendPoint> get points => _points;
  List<WaterTrendPoint> get rawBuffer => List.unmodifiable(_buffer);
  int get rangeMinutesValue => _liveApi ? liveWindowMinutes : rangeMinutes;
  bool get isLiveApi => _liveApi;

  /// Nạp buffer từ lịch sử Cloud (sensor_readings thật).
  void startLiveFromHistory(List<WaterTrendPoint> history) {
    if (history.isEmpty) return;
    _timer?.cancel();
    _liveApi = true;
    _active = true;
    _emaState = history.last;
    _buffer
      ..clear()
      ..addAll(history);
    _reproject();
    notifyListeners();
  }

  /// Khởi tạo cửa sổ 30 phút quanh giá trị sensor — tránh chỉ 1 chấm trên biểu đồ.
  void startLiveFromAnchor({
    required double ph,
    required double temp,
    double? dissolvedOxygen,
  }) {
    _timer?.cancel();
    _liveApi = true;
    _active = true;
    _emaState = null;
    _buffer
      ..clear()
      ..addAll(
        buildLiveTrendRawBuffer(
          ph: ph,
          temp: temp,
          dissolvedOxygen: dissolvedOxygen,
          rangeMinutes: liveWindowMinutes,
          stepSeconds: pollInterval.inSeconds,
        ),
      );
    _reproject();
    notifyListeners();
  }

  void seedFromApi(List<WaterTrendPoint> points, {bool enableLive = false}) {
    if (enableLive && points.isNotEmpty) {
      final last = points.last;
      startLiveFromAnchor(
        ph: last.ph,
        temp: last.temperature,
        dissolvedOxygen: last.dissolvedOxygen,
      );
      return;
    }
    stop();
    _liveApi = false;
    _emaState = null;
    _buffer
      ..clear()
      ..addAll(points);
    _reproject();
    _active = true;
    notifyListeners();
  }

  void appendLiveSample(WaterTrendPoint raw) {
    if (!_liveApi) return;
    final now = DateTime.now();
    final smoothed = _smoothPoint(raw, now);

    final last = _buffer.isNotEmpty ? _buffer.last : null;
    if (last != null) {
      final dt = now.difference(last.timestamp).inMilliseconds;
      if (dt < 1500) return;
    }

    _buffer.add(smoothed);
    final pruned = WaterTrendWindow.prune(_buffer, liveWindowMinutes, now);
    _buffer
      ..clear()
      ..addAll(pruned);
    _reproject(now);
    notifyListeners();
  }

  void _reproject([DateTime? now]) {
    _points = WaterTrendWindow.project(_buffer, liveWindowMinutes, now);
  }

  void start() {
    if (_active && _liveApi) return;
    if (_active) return;
    _active = true;
    _timer?.cancel();
  }

  void stop() {
    _active = false;
    _liveApi = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void tick() {}

  WaterTrendPoint _smoothPoint(WaterTrendPoint raw, DateTime now) {
    final prev = _emaState;
    final start = WaterTrendWindow.windowStart(liveWindowMinutes, now);
    final xMin = now.difference(start).inSeconds / 60.0;

    if (prev == null) {
      final p = WaterTrendPoint(
        xMinutes: xMin,
        label: _labelAt(now),
        timestamp: now,
        ph: raw.ph,
        temperature: raw.temperature,
        tds: raw.tds,
        flow: raw.flow,
        dissolvedOxygen: raw.dissolvedOxygen,
      );
      _emaState = p;
      return p;
    }

    const a = 0.42;
    final jitterPh = (math.Random().nextDouble() - 0.5) * 0.012;
    final jitterTemp = (math.Random().nextDouble() - 0.5) * 0.06;

    final smoothed = WaterTrendPoint(
      xMinutes: xMin,
      label: _labelAt(now),
      timestamp: now,
      ph: (prev.ph * (1 - a) + raw.ph * a + jitterPh).clamp(6.8, 8.6),
      temperature:
          (prev.temperature * (1 - a) + raw.temperature * a + jitterTemp)
              .clamp(25.5, 30.5),
      tds: raw.tds,
      flow: raw.flow,
      dissolvedOxygen: raw.dissolvedOxygen != null && prev.dissolvedOxygen != null
          ? prev.dissolvedOxygen! * (1 - a) + raw.dissolvedOxygen! * a
          : raw.dissolvedOxygen ?? prev.dissolvedOxygen,
    );
    _emaState = smoothed;
    return smoothed;
  }

  static String _labelAt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';
}
