class AreaEnvironmentMetric {
  const AreaEnvironmentMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.status,
    this.sensorType,
    this.sensorCode,
    this.sensorId,
    this.locationName,
    this.recordedAt,
    this.minThreshold,
    this.maxThreshold,
  });

  final String label;
  final double value;
  final String unit;
  final String icon;
  final String status;
  final String? sensorType;
  final String? sensorCode;
  final String? sensorId;
  final String? locationName;
  final DateTime? recordedAt;
  final double? minThreshold;
  final double? maxThreshold;

  bool get isMissing => recordedAt == null && value == 0;

  factory AreaEnvironmentMetric.fromJson(Map<String, dynamic> json) {
    double? n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
    return AreaEnvironmentMetric(
      label: (json['label'] ?? json['Label'] ?? '').toString(),
      value: n(json['value'] ?? json['Value']) ?? 0,
      unit: (json['unit'] ?? json['Unit'] ?? '').toString(),
      icon: (json['icon'] ?? json['Icon'] ?? 'sensor').toString(),
      status: (json['status'] ?? json['Status'] ?? 'good').toString(),
      sensorType: (json['sensorType'] ?? json['SensorType'])?.toString(),
      sensorCode: (json['sensorCode'] ?? json['SensorCode'])?.toString(),
      sensorId: (json['sensorId'] ?? json['SensorId'])?.toString(),
      locationName: (json['locationName'] ?? json['LocationName'])?.toString(),
      recordedAt: _parseDate(json['recordedAt'] ?? json['RecordedAt']),
      minThreshold: n(json['minThreshold'] ?? json['MinThreshold']),
      maxThreshold: n(json['maxThreshold'] ?? json['MaxThreshold']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

class AreaSensorLatestData {
  const AreaSensorLatestData({
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    required this.scope,
    required this.inheritedByBox,
    required this.metrics,
    this.lastUpdatedAt,
    this.boxId,
    this.boxCode,
  });

  final String areaId;
  final String areaCode;
  final String areaName;
  final String scope;
  final bool inheritedByBox;
  final DateTime? lastUpdatedAt;
  final List<AreaEnvironmentMetric> metrics;
  final String? boxId;
  final String? boxCode;

  bool get isBoxInherited =>
      inheritedByBox && scope == 'box' && (boxId?.isNotEmpty ?? false);

  factory AreaSensorLatestData.fromIotLive({
    required String areaId,
    required List<Map<String, dynamic>> live,
  }) {
    DateTime? latest;
    final metrics = <AreaEnvironmentMetric>[];
    for (final raw in live) {
      final type = (raw['sensorType'] ?? raw['SensorType'] ?? '').toString();
      final value = (raw['latestValue'] ?? raw['LatestValue'] as num?)?.toDouble();
      if (value == null) continue;
      final at = AreaEnvironmentMetric._parseDate(
        raw['latestMeasuredAt'] ?? raw['LatestMeasuredAt'],
      );
      if (at != null && (latest == null || at.isAfter(latest))) latest = at;
      final alarm = raw['alarm'] == true ||
          raw['Alarm'] == true ||
          (raw['alarm'] ?? raw['Alarm'] ?? '').toString().toLowerCase().contains('warn');
      double? n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
      metrics.add(
        AreaEnvironmentMetric(
          label: _liveLabel(type),
          value: value,
          unit: (raw['unit'] ?? raw['Unit'] ?? '').toString(),
          icon: _liveIcon(type),
          status: alarm ? 'warning' : 'good',
          sensorType: type,
          sensorCode: (raw['sensorCode'] ?? raw['SensorCode'])?.toString(),
          sensorId: (raw['sensorId'] ?? raw['SensorId'] ?? raw['id'] ?? raw['Id'])?.toString(),
          locationName: (raw['locationName'] ?? raw['LocationName'] ?? raw['rowName'] ?? raw['RowName'])?.toString(),
          recordedAt: at,
          minThreshold: n(raw['minThreshold'] ?? raw['MinThreshold']),
          maxThreshold: n(raw['maxThreshold'] ?? raw['MaxThreshold']),
        ),
      );
    }
    return AreaSensorLatestData(
      areaId: areaId,
      areaCode: '',
      areaName: '',
      scope: 'area',
      inheritedByBox: true,
      lastUpdatedAt: latest,
      metrics: metrics,
    );
  }

  static String _liveLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('temp')) return 'Nhiệt độ';
    if (t.contains('ph')) return 'pH';
    if (t == 'do' || t.contains('oxygen') || t.contains('oxy')) {
      return 'Oxy hòa tan';
    }
    if (t.contains('tds')) return 'TDS';
    if (t.contains('salin')) return 'Độ mặn';
    if (t.contains('nh3') || t.contains('ammonia')) return 'NH₃';
    if (t.contains('no2') || t.contains('nitrite')) return 'NO₂';
    if (t.contains('flow')) return 'Lưu lượng';
    return type.isEmpty ? 'Cảm biến' : type;
  }

  static String _liveIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('temp')) return 'temp';
    if (t.contains('ph')) return 'ph';
    if (t == 'do' || t.contains('oxygen')) return 'oxygen';
    if (t.contains('tds') || t.contains('salin')) return 'tds';
    if (t.contains('flow')) return 'flow';
    return 'sensor';
  }

  factory AreaSensorLatestData.fromJson(Map<String, dynamic> json) {
    final metricsJson = json['metrics'] ?? json['Metrics'];
    final list = metricsJson is List
        ? metricsJson
            .map((e) => AreaEnvironmentMetric.fromJson(e as Map<String, dynamic>))
            .toList()
        : <AreaEnvironmentMetric>[];

    return AreaSensorLatestData(
      areaId: (json['areaId'] ?? json['AreaId']).toString(),
      areaCode: (json['areaCode'] ?? json['AreaCode'] ?? '').toString(),
      areaName: (json['areaName'] ?? json['AreaName'] ?? '').toString(),
      scope: (json['scope'] ?? json['Scope'] ?? 'area').toString(),
      inheritedByBox: json['inheritedByBox'] ?? json['InheritedByBox'] ?? true,
      lastUpdatedAt: AreaEnvironmentMetric._parseDate(
        json['lastUpdatedAt'] ?? json['LastUpdatedAt'],
      ),
      boxId: (json['boxId'] ?? json['BoxId'])?.toString(),
      boxCode: (json['boxCode'] ?? json['BoxCode'])?.toString(),
      metrics: list,
    );
  }
}

/// Alias tương thích mock cũ.
typedef BoxEnvironmentMetric = AreaEnvironmentMetric;
