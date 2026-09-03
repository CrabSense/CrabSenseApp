import '../models/water_quality.dart';
import '../services/water_quality_cloud_merge.dart';

/// Cửa sổ realtime: [now - rangeMinutes, now], trục X = phút từ đầu cửa sổ.
abstract final class WaterTrendWindow {
  static int maxDisplayPoints(int rangeMinutes) => switch (rangeMinutes) {
        <= 30 => 220,
        <= 60 => 280,
        _ => 400,
      };

  static DateTime windowStart(int rangeMinutes, [DateTime? now]) {
    final end = now ?? DateTime.now();
    return end.subtract(Duration(minutes: rangeMinutes));
  }

  static List<WaterTrendPoint> prune(
    List<WaterTrendPoint> points,
    int rangeMinutes, [
    DateTime? now,
  ]) {
    final end = now ?? DateTime.now();
    final start = windowStart(rangeMinutes, end);
    return points
        .where((p) => !p.timestamp.isBefore(start) && !p.timestamp.isAfter(end))
        .toList();
  }

  static List<WaterTrendPoint> project(
    List<WaterTrendPoint> points,
    int rangeMinutes, [
    DateTime? now,
  ]) {
    final end = now ?? DateTime.now();
    final start = windowStart(rangeMinutes, end);
    final pruned = prune(points, rangeMinutes, end)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final projected = pruned
        .map(
          (p) => WaterTrendPoint(
            xMinutes: p.timestamp.difference(start).inSeconds / 60.0,
            label: WaterQualityCloudMerge.axisLabelFor(p.timestamp, rangeMinutes),
            timestamp: p.timestamp,
            temperature: p.temperature,
            ph: p.ph,
            tds: p.tds,
            flow: p.flow,
            dissolvedOxygen: p.dissolvedOxygen,
          ),
        )
        .toList();

    return downsample(projected, maxDisplayPoints(rangeMinutes));
  }

  static List<WaterTrendPoint> downsample(
    List<WaterTrendPoint> points,
    int maxCount,
  ) {
    if (points.length <= maxCount) return points;
    final step = points.length / maxCount;
    final out = <WaterTrendPoint>[];
    for (var i = 0; i < maxCount; i++) {
      out.add(points[(i * step).floor().clamp(0, points.length - 1)]);
    }
    if (out.last != points.last) out[out.length - 1] = points.last;
    return out;
  }
}
