class CloudTelemetryRealtime {
  const CloudTelemetryRealtime({
    required this.mac,
    required this.readings,
    this.deviceCode,
    this.lastRecordedAt,
  });

  final String mac;
  final String? deviceCode;
  final Map<String, double> readings;
  final DateTime? lastRecordedAt;

  double? get temp => _pick('temp');
  double? get ph => _pick('pH') ?? _pick('ph');
  double? get tds => _pick('tds');
  double? get flow => _pick('flow');
  double? get water => _pick('water');

  double? _pick(String key) => readings[key];
}

class CloudTelemetryHistoryPoint {
  const CloudTelemetryHistoryPoint({
    required this.time,
    required this.pin,
    required this.val,
    required this.label,
  });

  final DateTime time;
  final int pin;
  final double val;
  final String label;
}
