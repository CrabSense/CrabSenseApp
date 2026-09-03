import 'dart:math' as math;

import '../models/water_quality.dart';
import '../utils/water_quality_evaluator.dart';

abstract final class MockWaterQualityData {
  static final _rng = math.Random();

  static const areaOptions = ['Tất cả', 'Khu A', 'Khu B', 'Khu C'];
  static const deviceOptions = ['Tất cả', 'Sensor-01', 'Sensor-02', 'Sensor-03'];
  static const timeOptions = ['24h', '7 ngày', '30 ngày'];
  static const statusOptions = ['Tất cả', 'Bình thường', 'Cảnh báo', 'Offline'];

  static double _rand(double min, double max) =>
      min + _rng.nextDouble() * (max - min);

  /// Chỉ số cảm biến dao động ngẫu nhiên trong ngưỡng nuôi cua (demo / mock).
  static List<WaterSensorReading> randomReadings() {
    final raw = {
      WaterSensorType.ph: (_rand(7.0, 8.4), ''),
      WaterSensorType.temperature: (_rand(26.0, 29.5), '°C'),
      WaterSensorType.tds: (_rand(280.0, 520.0), 'ppm'),
      WaterSensorType.flow: (_rand(0.4, 2.8), 'L/min'),
      WaterSensorType.waterLevel: (_rand(0.75, 1.15), ''),
      WaterSensorType.dissolvedOxygen: (_rand(5.2, 7.2), 'mg/L'),
      WaterSensorType.salinity: (_rand(12.0, 18.0), 'ppt'),
      WaterSensorType.orp: (_rand(240.0, 340.0), 'mV'),
      WaterSensorType.nh3: (_rand(0.01, 0.07), 'ppm'),
      WaterSensorType.no2: (_rand(0.005, 0.045), 'ppm'),
    };

    return WaterSensorType.cloudFirst.map((type) {
      final r = raw[type]!;
      final threshold = WaterQualityEvaluator.thresholdFor(type);
      return WaterSensorReading(
        type: type,
        value: r.$1,
        unit: r.$2,
        status: WaterQualityEvaluator.evaluate(type, r.$1),
        threshold: threshold,
        offline: _rng.nextDouble() < 0.03,
      );
    }).toList();
  }

  static List<WaterSensorReading> currentReadings() {
    const raw = {
      WaterSensorType.ph: (7.8, ''),
      WaterSensorType.temperature: (28.4, '°C'),
      WaterSensorType.tds: (450.0, 'ppm'),
      WaterSensorType.flow: (1.2, 'L/min'),
      WaterSensorType.waterLevel: (1.0, ''),
      WaterSensorType.dissolvedOxygen: (6.3, 'mg/L'),
      WaterSensorType.salinity: (15.0, 'ppt'),
      WaterSensorType.orp: (280.0, 'mV'),
      WaterSensorType.nh3: (0.02, 'ppm'),
      WaterSensorType.no2: (0.01, 'ppm'),
    };

    return WaterSensorType.cloudFirst.map((type) {
      final r = raw[type]!;
      final threshold = WaterQualityEvaluator.thresholdFor(type);
      return WaterSensorReading(
        type: type,
        value: r.$1,
        unit: r.$2,
        status: WaterQualityEvaluator.evaluate(type, r.$1),
        threshold: threshold,
      );
    }).toList();
  }

  /// Dữ liệu dày kiểu Cloud (~30 phút) — dao động nhanh như biểu đồ thật.
  /// Một mẫu realtime tại [at] (dùng cho poll 3s).
  static WaterTrendPoint trendLiveSample(DateTime at) {
    final readings = randomReadings();
    double pick(WaterSensorType t) {
      return readings.firstWhere((r) => r.type == t).value;
    }

    return WaterTrendPoint(
      xMinutes: 0,
      label: '${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}:'
          '${at.second.toString().padLeft(2, '0')}',
      timestamp: at,
      ph: pick(WaterSensorType.ph),
      temperature: pick(WaterSensorType.temperature),
      tds: pick(WaterSensorType.tds),
      flow: pick(WaterSensorType.flow),
      dissolvedOxygen: pick(WaterSensorType.dissolvedOxygen),
    );
  }

  static List<WaterTrendPoint> trendForRange(int rangeMinutes) {
    final count = rangeMinutes <= 30
        ? 72
        : rangeMinutes <= 60
            ? 48
            : 24;
    final step = rangeMinutes / (count - 1).clamp(1, 999);
    final end = DateTime.now();

    return List.generate(count, (i) {
      final x = i * step;
      final t = end.subtract(Duration(minutes: (rangeMinutes - x).round()));
      final w = i * 0.65;
      final ph = 7.2 +
          math.sin(w) * 0.55 +
          math.sin(w * 2.4) * 0.25 +
          math.sin(w * 5.1) * 0.12;
      final temp = 26.5 +
          math.sin(w * 0.45 + 1) * 1.2 +
          math.sin(w * 1.8) * 0.35;
      final tds = 420 +
          math.sin(w * 0.55 + 2) * 95 +
          math.sin(w * 2.1) * 55 +
          math.sin(w * 4.3) * 30;
      final flow = 8 +
          math.sin(w * 0.9 + 0.5) * 6 +
          math.sin(w * 3.2) * 4 +
          (i % 7 == 0 ? 5.0 : 0);

      String label;
      if (rangeMinutes <= 30) {
        label =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
      } else if (rangeMinutes <= 60) {
        label =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      } else {
        label = '${t.hour.toString().padLeft(2, '0')}:00';
      }

      return WaterTrendPoint(
        xMinutes: x,
        label: label,
        timestamp: t,
        ph: ph.clamp(6.5, 8.5),
        temperature: temp.clamp(24.0, 29.0),
        tds: tds.clamp(180.0, 580.0),
        flow: flow.clamp(0.0, 26.0),
        dissolvedOxygen: 6.0 + math.sin(w) * 0.4,
      );
    });
  }

  static List<WaterTrendPoint> trend24h() {
    final base = DateTime.now().subtract(const Duration(hours: 24));
    const samples = [
      (0.0, 7.7, 28.0, 420.0, 1.0),
      (240.0, 7.8, 28.2, 440.0, 1.1),
      (480.0, 7.8, 28.4, 450.0, 1.2),
      (720.0, 7.9, 28.6, 455.0, 1.0),
      (960.0, 7.7, 28.5, 445.0, 1.1),
      (1200.0, 7.8, 28.3, 448.0, 1.2),
      (1440.0, 7.8, 28.4, 450.0, 1.1),
    ];
    return samples.map((s) {
      final t = base.add(Duration(minutes: s.$1.round()));
      return WaterTrendPoint(
        xMinutes: s.$1,
        label: '${t.hour.toString().padLeft(2, '0')}:00',
        timestamp: t,
        ph: s.$2,
        temperature: s.$3,
        tds: s.$4,
        flow: s.$5,
        dissolvedOxygen: 6.3,
      );
    }).toList();
  }

  static List<WaterHistoryRow> historyRows() => [
        _historyRow('08:00', 7.8, 6.3, 28.4, 15, 280, 0.02, 0.01, 95),
        _historyRow('09:00', 7.9, 6.2, 28.6, 15, 282, 0.02, 0.01, 95),
        _historyRow('10:00', 7.7, 6.1, 28.8, 16, 279, 0.03, 0.01, 94),
        _historyRow('11:00', 7.8, 6.2, 28.5, 15, 281, 0.02, 0.01, 95),
        _historyRow('12:00', 7.8, 6.3, 28.4, 15, 280, 0.02, 0.01, 95),
      ];

  static WaterHistoryRow _historyRow(
    String time,
    double ph,
    double doVal,
    double temp,
    double sal,
    double orp,
    double nh3,
    double no2,
    double level,
  ) {
    return WaterHistoryRow(
      time: time,
      values: {
        WaterSensorType.ph: ph.toStringAsFixed(1),
        WaterSensorType.dissolvedOxygen: '$doVal mg/L',
        WaterSensorType.temperature: '${temp.toStringAsFixed(1)}°C',
        WaterSensorType.salinity: sal.round().toString(),
        WaterSensorType.orp: orp.round().toString(),
        WaterSensorType.nh3: nh3.toStringAsFixed(2),
        WaterSensorType.no2: no2.toStringAsFixed(2),
        WaterSensorType.waterLevel: '${level.round()}cm',
      },
    );
  }

  static String aiInsight = 'Chất lượng nước hiện tại ổn định. '
      'pH, DO và nhiệt độ đều nằm trong ngưỡng tốt. '
      'NH3 và NO2 đang ở mức an toàn.';

  static const aiRecommendations = [
    'Tiếp tục duy trì lưu lượng lọc hiện tại.',
    'Kiểm tra lại cảm biến DO sau 6 giờ.',
  ];
}
