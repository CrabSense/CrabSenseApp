import 'dart:math' as math;

import '../models/water_quality.dart';
import 'water_trend_window.dart';

/// Tạo lịch sử 30 phút (mỗi 3s) quanh giá trị sensor hiện tại — biểu đồ trượt ngay từ đầu.
List<WaterTrendPoint> buildLiveTrendBootstrap({
  required double ph,
  required double temp,
  double? dissolvedOxygen,
  int rangeMinutes = 30,
  int stepSeconds = 3,
}) {
  final end = DateTime.now();
  final start = end.subtract(Duration(minutes: rangeMinutes));
  final raw = <WaterTrendPoint>[];
  var t = start;
  var i = 0;

  final doBase = dissolvedOxygen ?? 6.4;

  while (!t.isAfter(end)) {
    final w = i * 0.065;
    final phVal = ph +
        math.sin(w) * 0.07 +
        math.sin(w * 2.1 + 0.4) * 0.035 +
        math.sin(w * 4.8) * 0.015;
    final tempVal = temp +
        math.sin(w * 0.42 + 1.1) * 0.4 +
        math.sin(w * 1.6 + 0.2) * 0.18 +
        math.sin(w * 3.3) * 0.08;
    final doVal = doBase +
        math.sin(w * 0.55) * 0.25 +
        math.sin(w * 1.9) * 0.12;

    raw.add(
      WaterTrendPoint(
        xMinutes: 0,
        label: _timeLabel(t, rangeMinutes),
        timestamp: t,
        ph: phVal.clamp(6.8, 8.6),
        temperature: tempVal.clamp(25.5, 30.5),
        tds: 400 + math.sin(w * 0.5) * 40,
        flow: 1.1 + math.sin(w * 0.9) * 0.3,
        dissolvedOxygen: doVal.clamp(5.0, 8.0),
      ),
    );
    t = t.add(Duration(seconds: stepSeconds));
    i++;
  }

  return WaterTrendWindow.project(raw, rangeMinutes, end);
}

/// Buffer đầy đủ (không downsample) để append tiếp.
List<WaterTrendPoint> buildLiveTrendRawBuffer({
  required double ph,
  required double temp,
  double? dissolvedOxygen,
  int rangeMinutes = 30,
  int stepSeconds = 3,
}) {
  final end = DateTime.now();
  final start = end.subtract(Duration(minutes: rangeMinutes));
  final raw = <WaterTrendPoint>[];
  var t = start;
  var i = 0;
  final doBase = dissolvedOxygen ?? 6.4;

  while (!t.isAfter(end)) {
    final w = i * 0.065;
    raw.add(
      WaterTrendPoint(
        xMinutes: t.difference(start).inSeconds / 60.0,
        label: _timeLabel(t, rangeMinutes),
        timestamp: t,
        ph: (ph +
                math.sin(w) * 0.07 +
                math.sin(w * 2.1 + 0.4) * 0.035)
            .clamp(6.8, 8.6),
        temperature: (temp +
                math.sin(w * 0.42 + 1.1) * 0.4 +
                math.sin(w * 1.6 + 0.2) * 0.18)
            .clamp(25.5, 30.5),
        tds: 400,
        flow: 1.1,
        dissolvedOxygen: (doBase + math.sin(w * 0.55) * 0.25).clamp(5.0, 8.0),
      ),
    );
    t = t.add(Duration(seconds: stepSeconds));
    i++;
  }
  return raw;
}

String _timeLabel(DateTime t, int rangeMinutes) {
  if (rangeMinutes <= 30) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// 12 giá trị DO từ buffer để cột biểu đồ.
List<double> doSeriesFromBuffer(List<WaterTrendPoint> buffer, {int count = 12}) {
  if (buffer.isEmpty) return [];
  if (buffer.length <= count) {
    return buffer
        .map((p) => p.dissolvedOxygen ?? 6.4)
        .toList();
  }
  final step = buffer.length / count;
  return List.generate(
    count,
    (i) => buffer[(i * step).floor().clamp(0, buffer.length - 1)]
        .dissolvedOxygen ??
        6.4,
  );
}
