import '../services/qualified_live_water.dart';
import 'water_quality.dart';

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
    this.receivedAt,
    this.offline = true,
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
  final DateTime? receivedAt;
  final bool offline;

  bool get isMissing => recordedAt == null || !value.isFinite;
  bool get isStale => recordedAt == null || receivedAt == null ||
      DateTime.now().difference(recordedAt!) > const Duration(minutes:5) ||
      DateTime.now().difference(receivedAt!) > const Duration(minutes:5);
  String get assessment => isMissing ? 'Chưa có dữ liệu' : isStale ? 'Dữ liệu cũ' :
      offline ? 'Chưa xác minh hiện trạng' : status == 'warning' ? 'Cảnh báo từ cấu hình' :
      minThreshold == null && maxThreshold == null ? 'Chưa có ngưỡng cấu hình' :
      'Trong giới hạn cấu hình';
  String get thresholdText => minThreshold != null && maxThreshold != null ?
      '$minThreshold – $maxThreshold $unit' : minThreshold != null ? '≥ $minThreshold $unit' :
      maxThreshold != null ? '≤ $maxThreshold $unit' : 'Chưa cấu hình';

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

  /// One shared RAS loop per area. Sensor placement metadata is not a
  /// row/box-specific water measurement. Preserve every source separately.
  factory AreaSensorLatestData.fromIotLive({
    required String areaId,
    required List<Map<String,dynamic>> live,
    String? boxId,
    DateTime? now,
  }) {
    final readings=decodeQualifiedDesktopLive(live,areaId:areaId,now:now??DateTime.now().toUtc());
    final metrics=<AreaEnvironmentMetric>[];
    DateTime? latest;
    for(final r in readings) {
      final at=r.measuredAt!;
      if(latest==null || at.isAfter(latest)) latest=at;
      metrics.add(AreaEnvironmentMetric(label:r.type.label,value:r.value,
        unit:r.unit,icon:switch(r.type) {
          WaterSensorType.temperature=>'temp',WaterSensorType.ph=>'ph',
          WaterSensorType.dissolvedOxygen=>'do',WaterSensorType.salinity=>'sal',
          WaterSensorType.tds=>'tds',WaterSensorType.flow=>'flow',
          WaterSensorType.orp=>'orp',_=>'sensor'},
        status:r.status==WaterSensorStatus.exceeded ? 'warning' :
          r.status==WaterSensorStatus.normal ? 'good' : 'watch',
        sensorType:r.wireSensorType,sensorCode:r.sensorCode,sensorId:r.sensorId,
        locationName:r.location,recordedAt:at,receivedAt:r.receivedAt,
        offline:r.offline,minThreshold:r.threshold.min,maxThreshold:r.threshold.max));
    }
    return AreaSensorLatestData(areaId:areaId,areaCode:'',areaName:'',
      scope:boxId==null ? 'area' : 'box',inheritedByBox:true,
      boxId:boxId,lastUpdatedAt:latest,metrics:List.unmodifiable(metrics));
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
