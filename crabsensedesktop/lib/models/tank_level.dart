const tankLevelKeys = [
  'lowFloat',
  'lowWhen',
  'highFloat',
  'highWhen',
  'normalFloat',
  'normalWhen',
];

/// A tank has two floats: cạn and tràn. Bình thường is neither condition.
/// Returns null when no float is assigned. Tràn wins over cạn.
String? tankLevelLabel(Map<String, dynamic> map, double? Function(String code) reading) {
  bool hit(String floatKey, String whenKey) {
    final sensor = map[floatKey]?.toString().trim() ?? '';
    if (sensor.isEmpty) return false;
    final value = reading(sensor);
    if (value == null) return false;
    final on = value >= 0.5;
    final wantOn = map[whenKey]?.toString() != 'off';
    return on == wantOn;
  }

  bool assigned(String floatKey) => (map[floatKey]?.toString().trim() ?? '').isNotEmpty;
  if (!assigned('lowFloat') && !assigned('highFloat')) return null;
  if (hit('highFloat', 'highWhen')) return 'Tràn';
  if (hit('lowFloat', 'lowWhen')) return 'Cạn';

  bool missing(String floatKey) {
    final sensor = map[floatKey]?.toString().trim() ?? '';
    return sensor.isNotEmpty && reading(sensor) == null;
  }

  if (missing('lowFloat') || missing('highFloat')) return 'Chưa có phao';
  return 'Bình thường';
}
