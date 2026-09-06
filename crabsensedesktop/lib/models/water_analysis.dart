class WaterAnalysisMetric {
  const WaterAnalysisMetric({
    required this.code,
    required this.label,
    this.value,
    required this.unit,
    required this.status,
    required this.statusLabel,
  });

  final String code;
  final String label;
  final double? value;
  final String unit;
  final String status;
  final String statusLabel;

  factory WaterAnalysisMetric.fromJson(Map<String, dynamic> json) {
    final raw = json['value'] ?? json['Value'];
    return WaterAnalysisMetric(
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      label: (json['label'] ?? json['Label'] ?? '').toString(),
      value: raw is num ? raw.toDouble() : null,
      unit: (json['unit'] ?? json['Unit'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? 'pending').toString(),
      statusLabel: (json['statusLabel'] ?? json['StatusLabel'] ?? '').toString(),
    );
  }

  String get displayValue {
    if (value == null) return '—';
    if (code == 'ph') return value!.toStringAsFixed(1);
    if (code == 'no3') return value!.toStringAsFixed(0);
    return value!.toStringAsFixed(value! < 1 ? 2 : 2);
  }
}

class WaterAnalysisStationPart {
  const WaterAnalysisStationPart({
    required this.code,
    required this.label,
    required this.ready,
    required this.stateLabel,
  });

  final String code;
  final String label;
  final bool ready;
  final String stateLabel;

  factory WaterAnalysisStationPart.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisStationPart(
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      label: (json['label'] ?? json['Label'] ?? '').toString(),
      ready: json['ready'] == true || json['Ready'] == true,
      stateLabel: (json['stateLabel'] ?? json['StateLabel'] ?? '').toString(),
    );
  }
}

class WaterAnalysisRun {
  const WaterAnalysisRun({
    required this.id,
    required this.status,
    required this.currentStep,
    required this.stepLabel,
    required this.startedAt,
    this.completedAt,
    required this.metrics,
    this.error,
  });

  final String id;
  final String status;
  final int currentStep;
  final String stepLabel;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<WaterAnalysisMetric> metrics;
  final String? error;

  bool get isRunning => status.toLowerCase() == 'running';
  bool get isCompleted => status.toLowerCase() == 'completed';

  factory WaterAnalysisRun.fromJson(Map<String, dynamic> json) {
    final raw = json['metrics'] ?? json['Metrics'];
    return WaterAnalysisRun(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      currentStep: (json['currentStep'] ?? json['CurrentStep'] as num?)?.toInt() ?? 1,
      stepLabel: (json['stepLabel'] ?? json['StepLabel'] ?? '').toString(),
      startedAt: DateTime.tryParse(
            (json['startedAt'] ?? json['StartedAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      completedAt: DateTime.tryParse(
        (json['completedAt'] ?? json['CompletedAt'] ?? '').toString(),
      ),
      metrics: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => WaterAnalysisMetric.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      error: (json['error'] ?? json['Error'])?.toString(),
    );
  }
}

class WaterAnalysisSnapshot {
  const WaterAnalysisSnapshot({
    this.latest,
    this.active,
    required this.station,
  });

  final WaterAnalysisRun? latest;
  final WaterAnalysisRun? active;
  final List<WaterAnalysisStationPart> station;

  factory WaterAnalysisSnapshot.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;
    final stationRaw = json['station'] ?? json['Station'];
    return WaterAnalysisSnapshot(
      latest: asMap(json['latest'] ?? json['Latest']) is Map
          ? WaterAnalysisRun.fromJson(asMap(json['latest'] ?? json['Latest'])!)
          : null,
      active: asMap(json['active'] ?? json['Active']) is Map
          ? WaterAnalysisRun.fromJson(asMap(json['active'] ?? json['Active'])!)
          : null,
      station: stationRaw is List
          ? stationRaw
              .whereType<Map>()
              .map((e) =>
                  WaterAnalysisStationPart.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

abstract final class WaterAnalysisSteps {
  static const labels = [
    'Lấy mẫu nước',
    'Bơm thuốc thử',
    'Chờ phản ứng',
    'Camera chụp màu',
    'AI phân tích',
    'Lưu kết quả',
  ];
}
