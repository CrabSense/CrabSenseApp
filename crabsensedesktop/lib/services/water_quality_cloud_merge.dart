import '../models/cloud_telemetry.dart';
import '../models/water_quality.dart';
import '../utils/water_quality_evaluator.dart';

/// Gộp pin Cloud — chỉ hiện cảm biến có số liệu thật.
abstract final class WaterQualityCloudMerge {
  static List<WaterSensorReading> mergeReadings(CloudTelemetryRealtime? cloud) {
    final map = <WaterSensorType, WaterSensorReading>{};

    if (cloud != null) {
      _apply(map, WaterSensorType.temperature, cloud.temp, '°C');
      _apply(map, WaterSensorType.ph, cloud.ph, '');
      _apply(map, WaterSensorType.tds, cloud.tds, 'ppm');
      _apply(map, WaterSensorType.flow, cloud.flow, 'L/min');
      if (cloud.water != null) {
        _apply(map, WaterSensorType.waterLevel, cloud.water, '');
      }
    }

    return WaterSensorType.cloudFirst
        .map((t) => map[t])
        .whereType<WaterSensorReading>()
        .toList();
  }

  static void _apply(
    Map<WaterSensorType, WaterSensorReading> map,
    WaterSensorType type,
    double? value,
    String unit,
  ) {
    if (value == null) return;
    final threshold = WaterQualityEvaluator.thresholdFor(type);
    map[type] = WaterSensorReading(
      type: type,
      value: value,
      unit: unit,
      status: WaterQualityEvaluator.evaluate(type, value),
      threshold: threshold,
      offline: false,
    );
  }

  /// Xu hướng từ Cloud history — [rangeMinutes]: 30, 60, 1440.
  static List<WaterTrendPoint> buildTrend(
    List<CloudTelemetryHistoryPoint> history,
    int rangeMinutes,
  ) {
    if (history.isEmpty) {
      return const [];
    }

    final now = DateTime.now().toUtc();
    final from = now.subtract(Duration(minutes: rangeMinutes));
    final filtered = history.where((p) => !p.time.isBefore(from)).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (filtered.isEmpty) {
      return const [];
    }

    // Realtime: giữ độ phân giải ~3s cho 30p/1h; 24h gom bucket lớn hơn.
    if (rangeMinutes <= 60 && filtered.length <= 900) {
      final bySecond = <int, List<CloudTelemetryHistoryPoint>>{};
      for (final p in filtered) {
        final sec = p.time.difference(from).inSeconds.clamp(0, rangeMinutes * 60);
        final key = sec ~/ 3;
        bySecond.putIfAbsent(key, () => []).add(p);
      }
      final keys = bySecond.keys.toList()..sort();
      return keys.map((key) {
        final pts = bySecond[key]!;
        final t = pts[pts.length ~/ 2].time;
        final xMin = t.difference(from).inSeconds / 60.0;

        double avgPin(int pin) {
          final vals =
              pts.where((p) => p.pin == pin).map((p) => p.val).toList();
          if (vals.isEmpty) return 0;
          return vals.reduce((a, b) => a + b) / vals.length;
        }

        return WaterTrendPoint(
          xMinutes: xMin,
          label: axisLabelFor(t, rangeMinutes),
          timestamp: t.toLocal(),
          temperature: avgPin(1),
          ph: avgPin(2),
          tds: avgPin(3),
          flow: avgPin(4),
        );
      }).toList();
    }

    const maxPoints = 400;
    final bucketSize =
        (rangeMinutes * 60 / maxPoints).ceil().clamp(3, 600);

    final buckets = <int, List<CloudTelemetryHistoryPoint>>{};
    for (final p in filtered) {
      final sec = p.time.difference(from).inSeconds.clamp(0, rangeMinutes * 60);
      final key = sec ~/ bucketSize;
      buckets.putIfAbsent(key, () => []).add(p);
    }

    final keys = buckets.keys.toList()..sort();
    return keys.map((key) {
      final pts = buckets[key]!;
      final t = pts[pts.length ~/ 2].time;
      final xMin = t.difference(from).inSeconds / 60.0;

      double avgPin(int pin) {
        final vals =
            pts.where((p) => p.pin == pin).map((p) => p.val).toList();
        if (vals.isEmpty) return 0;
        return vals.reduce((a, b) => a + b) / vals.length;
      }

      return WaterTrendPoint(
        xMinutes: xMin,
        label: axisLabelFor(t, rangeMinutes),
        timestamp: t.toLocal(),
        temperature: avgPin(1),
        ph: avgPin(2),
        tds: avgPin(3),
        flow: avgPin(4),
      );
    }).toList();
  }

  static String axisLabelFor(DateTime t, int rangeMinutes) {
    final local = t.toLocal();
    if (rangeMinutes <= 30) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}:'
          '${local.second.toString().padLeft(2, '0')}';
    }
    if (rangeMinutes <= 360) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }
    if (rangeMinutes <= 1440) {
      return '${local.hour.toString().padLeft(2, '0')}:00';
    }
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }

  static List<WaterHistoryRow> buildHistory(
    List<CloudTelemetryHistoryPoint> history,
  ) {
    if (history.isEmpty) return const [];

    final byTime = <String, Map<WaterSensorType, String>>{};

    for (final p in history) {
      final key = _formatTime(p.time);
      byTime.putIfAbsent(key, () => {});
      final type = _pinToType(p.pin);
      if (type == null) continue;
      byTime[key]![type] = _formatValue(type, p.val);
    }

    return byTime.entries.map((e) {
      final values = Map<WaterSensorType, String>.from(e.value);
      return WaterHistoryRow(time: e.key, values: values);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  static WaterSensorType? _pinToType(int pin) => switch (pin) {
        1 => WaterSensorType.temperature,
        2 => WaterSensorType.ph,
        3 => WaterSensorType.tds,
        4 => WaterSensorType.flow,
        5 => WaterSensorType.waterLevel,
        _ => null,
      };

  static String _formatTime(DateTime t) {
    final local = t.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _formatValue(WaterSensorType type, double val) {
    return switch (type) {
      WaterSensorType.temperature => '${val.toStringAsFixed(1)}°C',
      WaterSensorType.ph => val.toStringAsFixed(1),
      WaterSensorType.tds => '${val.round()} ppm',
      WaterSensorType.flow => '${val.toStringAsFixed(1)} L/min',
      WaterSensorType.waterLevel => val >= 1 ? 'Có nước' : 'Cạn',
      _ => val.toString(),
    };
  }
}
