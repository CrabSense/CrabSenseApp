import 'dart:convert';

import '../../data/models/scoped_history_snapshot.dart';
import '../../domain/entities/water_quality.dart';

enum HistoryMetric {
  temperature('Nhiệt độ', '°C'),
  ph('pH', 'pH'),
  oxygen('Oxy hòa tan', 'mg/L'),
  salinity('Độ mặn', 'ppt');

  const HistoryMetric(this.label, this.unit);
  final String label;
  final String unit;

  bool matchesType(String type) => switch (this) {
    temperature => type.toLowerCase() == 'temperature',
    ph => type.toLowerCase() == 'ph',
    oxygen => ['do', 'dissolvedoxygen', 'dissolved_oxygen']
        .contains(type.toLowerCase()),
    salinity => type.toLowerCase() == 'salinity',
  };
}

/// One sensor, one observed location and one known measurement unit.
class HistorySensor {
  const HistorySensor(this.areaId, this.rowId, this.sensorId, this.metric);
  final String areaId;
  final String? rowId;
  final String sensorId;
  final HistoryMetric metric;

  String get key => jsonEncode([areaId, rowId, sensorId, metric.name]);
  String get label => '${metric.label} · ${sensorId.substring(sensorId.length - 8)}';

  ScopedHistoryQuery query(DateTime end, Duration period) => ScopedHistoryQuery(
    areaId: areaId, sensorId: sensorId, rowId: rowId,
    from: end.subtract(period), to: end,
  );
}

List<HistorySensor> historySensors(
  String areaId, String? rowId, List<WaterQuality> readings,
) {
  final candidates = <String, HistorySensor>{};
  if (areaId == 'default' || areaId.isEmpty) return [];
  for (final r in readings) {
    if (r.farmId != areaId || (rowId != null && r.pondId != rowId)) continue;
    final metrics = [
      if (r.temperature?.isFinite == true) HistoryMetric.temperature,
      if (r.ph?.isFinite == true) HistoryMetric.ph,
      if (r.dissolvedOxygen?.isFinite == true) HistoryMetric.oxygen,
      if (r.salinity?.isFinite == true) HistoryMetric.salinity,
    ];
    if (metrics.length != 1) continue;
    final candidate = HistorySensor(r.farmId, r.pondId, r.sensorId, metrics.single);
    try {
      candidate.query(DateTime.utc(2026), const Duration(hours: 1));
      candidates[candidate.key] = candidate;
    } on FormatException {
      // Never guess a sensor or resolve an invalid ID to a default scope.
    }
  }
  // Conflicting observations for the same sensor must not become choices.
  final counts = <String, int>{};
  for (final s in candidates.values) {
    counts[s.sensorId] = (counts[s.sensorId] ?? 0) + 1;
  }
  return candidates.values.where((s) => counts[s.sensorId] == 1).toList()
    ..sort((a, b) => a.label.compareTo(b.label));
}

class HistoryPoint {
  const HistoryPoint(this.at, this.value);
  final DateTime at;
  final double value;
}

class HistorySeries {
  const HistorySeries(this.query, this.asOf, this.metric, this.points);
  final ScopedHistoryQuery query;
  final DateTime asOf;
  final HistoryMetric metric;
  final List<HistoryPoint> points;

  factory HistorySeries.fromSnapshot(
    HistorySensor sensor, ScopedHistorySnapshot snapshot,
  ) {
    final q = snapshot.query;
    final pages = jsonDecode(snapshot.encodedPages) as List;
    final first = pages.first as Map;
    if (q.areaId != sensor.areaId || q.rowId != sensor.rowId ||
        q.sensorId != sensor.sensorId ||
        first['farmingRowId'] != sensor.rowId ||
        first['sensorActive'] != true ||
        first['unit'] != sensor.metric.unit ||
        !sensor.metric.matchesType(first['sensorType'] as String)) {
      throw const FormatException('Sensor history scope or unit changed');
    }
    final points = <HistoryPoint>[
      for (final page in pages)
        for (final item in (page as Map)['items'] as List)
          HistoryPoint(
            DateTime.parse((item as Map)['measuredAt'] as String).toUtc(),
            (item['value'] as num).toDouble(),
          ),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return HistorySeries(q, snapshot.asOf, sensor.metric,
      List<HistoryPoint>.unmodifiable(points));
  }
}
