import '../models/water_quality.dart';

/// Strict scoped wire projection. No fallback unit, unknown-type coercion,
/// synthetic chemistry, threshold or receipt.
List<WaterSensorReading> decodeQualifiedDesktopLive(
  List<Map<String,dynamic>> rows, {
  required String areaId, required DateTime now,
}) {
  if (areaId.isEmpty || areaId == 'default') return [];
  final out = <WaterSensorReading>[];
  double? number(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
  DateTime? timestamp(Object? v) {
    if (v is! String) return null;
    final t = DateTime.tryParse(v);
    return t != null && t.isUtc && !t.isAfter(now.add(const Duration(seconds: 1))) ? t : null;
  }
  for (final row in rows) {
    final id = row['sensorId'];
    if (row['farmingAreaId'] != areaId || id is! String || id.isEmpty ||
        row['isActive'] != true || row['dataQuality'] != 'Realtime') continue;
    final value = number(row['latestValue']);
    final at = timestamp(row['latestMeasuredAt']);
    final received = timestamp(row['lastReceivedAt']);
    if (value == null || at == null || received == null || received.isBefore(at)) continue;
    final type = switch (row['sensorType']?.toString().toLowerCase()) {
      'temperature' => WaterSensorType.temperature,
      'ph' => WaterSensorType.ph,
      'do' || 'dissolvedoxygen' || 'dissolved_oxygen' => WaterSensorType.dissolvedOxygen,
      'salinity' => WaterSensorType.salinity,
      'tds' => WaterSensorType.tds,
      'flow' => WaterSensorType.flow,
      'orp' => WaterSensorType.orp,
      _ => null,
    };
    final unit = row['unit'];
    final validUnit = switch (type) {
      WaterSensorType.temperature => unit == '°C',
      WaterSensorType.ph => unit == null || unit == '' || unit == 'pH',
      WaterSensorType.dissolvedOxygen => unit == 'mg/L',
      WaterSensorType.salinity => unit == 'ppt',
      WaterSensorType.tds => unit == 'ppm' || unit == 'mg/L',
      WaterSensorType.flow => unit == 'L/min',
      WaterSensorType.orp => unit == 'mV',
      _ => false,
    };
    if (type == null || !validUnit) continue;
    final displayUnit = type == WaterSensorType.ph ? 'pH' : unit as String;
    final lo = number(row['minThreshold']), hi = number(row['maxThreshold']);
    final rangeValid = (row['minThreshold'] == null || lo != null) &&
        (row['maxThreshold'] == null || hi != null) &&
        (lo == null || hi == null || lo < hi);
    final min = rangeValid ? lo : null, max = rangeValid ? hi : null;
    final range = min != null && max != null ? '$min – $max $displayUnit'
        : min != null ? '≥ $min $displayUnit' : max != null ? '≤ $max $displayUnit'
        : 'Chưa cấu hình';
    final alarm = row['alarm'];
    final offline = row['status'] != 'Online';
    final stale = now.difference(at) > const Duration(minutes: 5) ||
        now.difference(received) > const Duration(minutes: 5);
    final outOfRange = (min != null && value < min) || (max != null && value > max) ||
        (alarm is String && alarm.isNotEmpty);
    final status = stale || offline ? WaterSensorStatus.monitoring
        : outOfRange ? WaterSensorStatus.exceeded
        : min == null && max == null ? WaterSensorStatus.monitoring
        : WaterSensorStatus.normal;
    out.add(WaterSensorReading(type:type,value:value,unit:displayUnit,status:status,
      threshold:SensorThreshold(goodRangeLabel:range,min:min,max:max),
      offline:offline,sensorId:id,sensorCode:row['sensorCode']?.toString() ?? id,
      location:row['locationName']?.toString(),deviceCode:row['deviceCode']?.toString(),
      deviceStatus:row['deviceStatus']?.toString(),measuredAt:at,receivedAt:received));
  }
  final counts = <String,int>{};
  for (final r in out) { counts[r.sensorId!] = (counts[r.sensorId!] ?? 0)+1; }
  return out.where((r)=>counts[r.sensorId]==1).toList()
    ..sort((a,b) { final kind=a.type.index.compareTo(b.type.index);
      return kind==0 ? a.sensorId!.compareTo(b.sensorId!) : kind; });
}
