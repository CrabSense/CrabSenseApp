import 'package:fl_chart/fl_chart.dart';

/// Làm mượt đường biểu đồ — tránh gấp khúc / bậc thang khi poll 3s.
abstract final class ChartLineSmooth {
  /// EMA trên chuỗi giá trị.
  static List<double> ema(List<double> values, {double alpha = 0.22}) {
    if (values.isEmpty) return values;
    final out = <double>[values.first];
    for (var i = 1; i < values.length; i++) {
      out.add(out.last * (1 - alpha) + values[i] * alpha);
    }
    return out;
  }

  /// Chèn điểm trung gian (smoothstep) giữa mỗi cặp.
  static List<FlSpot> densifySpots(
    List<FlSpot> spots, {
    int segmentsPerGap = 6,
  }) {
    if (spots.length < 2) return spots;
    final sorted = List<FlSpot>.from(spots)
      ..sort((a, b) => a.x.compareTo(b.x));
    final out = <FlSpot>[sorted.first];

    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      for (var s = 1; s < segmentsPerGap; s++) {
        final t = s / segmentsPerGap;
        final ease = _smoothStep(t);
        out.add(FlSpot(
          a.x + (b.x - a.x) * t,
          a.y + (b.y - a.y) * ease,
        ));
      }
    }
    out.add(sorted.last);
    return out;
  }

  static double _smoothStep(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static List<FlSpot> fromSeries(
    List<FlSpot> raw, {
    double emaAlpha = 0.22,
    int segmentsPerGap = 6,
  }) {
    if (raw.length < 2) return raw;
    final ys = ema(raw.map((s) => s.y).toList(), alpha: emaAlpha);
    final smoothed = List<FlSpot>.generate(
      raw.length,
      (i) => FlSpot(raw[i].x, ys[i]),
    );
    return densifySpots(smoothed, segmentsPerGap: segmentsPerGap);
  }
}
