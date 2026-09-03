class FarmDashboardOverview {
  const FarmDashboardOverview({
    required this.healthScore,
    required this.alertCount,
    required this.devicesOnline,
    this.primaryAreaId,
    required this.summaryKpis,
    required this.kpiRow1,
    required this.kpiRow2,
    required this.statusSegments,
    required this.environmentParams,
    required this.alerts,
    required this.charts,
    required this.assistantHint,
    required this.statusMessage,
  });

  final int healthScore;
  final int alertCount;
  final String devicesOnline;
  final String? primaryAreaId;
  final List<DashboardKpiDto> summaryKpis;
  final List<DashboardKpiDto> kpiRow1;
  final List<DashboardKpiDto> kpiRow2;
  final List<DashboardStatusSegmentDto> statusSegments;
  final List<DashboardEnvParamDto> environmentParams;
  final List<DashboardAlertDto> alerts;
  final DashboardChartsDto charts;
  final String assistantHint;
  final String statusMessage;

  factory FarmDashboardOverview.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) from) {
      final raw = json[key];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => from(Map<String, dynamic>.from(e)))
          .toList();
    }

    return FarmDashboardOverview(
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
      alertCount: (json['alertCount'] as num?)?.toInt() ?? 0,
      devicesOnline: (json['devicesOnline'] ?? '0/0').toString(),
      primaryAreaId: (json['primaryAreaId'] ?? json['PrimaryAreaId'])?.toString(),
      summaryKpis: list('summaryKpis', DashboardKpiDto.fromJson),
      kpiRow1: list('kpiRow1', DashboardKpiDto.fromJson),
      kpiRow2: list('kpiRow2', DashboardKpiDto.fromJson),
      statusSegments: list('statusSegments', DashboardStatusSegmentDto.fromJson),
      environmentParams: list('environmentParams', DashboardEnvParamDto.fromJson),
      alerts: list('alerts', DashboardAlertDto.fromJson),
      charts: DashboardChartsDto.fromJson(
        json['charts'] is Map
            ? Map<String, dynamic>.from(json['charts'] as Map)
            : {},
      ),
      assistantHint: (json['assistantHint'] ?? '').toString(),
      statusMessage: (json['statusMessage'] ?? '').toString(),
    );
  }

  /// Map CrabSenseBE `/api/dashboard/overview` + `/metrics`.
  factory FarmDashboardOverview.fromCrabSense({
    required int totalBoxes,
    required int totalCrabs,
    required int activeBoxes,
    required int openAlerts,
    required double iotOnlinePercentage,
    int healthScore = 0,
    int waterQualityScore = 0,
    int crabHealthScore = 0,
    int deviceStatusScore = 0,
    String statusLabel = '',
    String statusMessage = '',
    String? primaryAreaId,
    List<DashboardEnvParamDto> environmentParams = const [],
    List<DashboardAlertDto> alerts = const [],
  }) {
    kpi(String label, String value, {String? colorKey}) => DashboardKpiDto(
          label: label,
          value: value,
          colorKey: colorKey,
        );
    return FarmDashboardOverview(
      healthScore: healthScore,
      alertCount: openAlerts,
      devicesOnline: '${iotOnlinePercentage.toStringAsFixed(0)}%',
      primaryAreaId: primaryAreaId,
      summaryKpis: [
        kpi('Hộp', '$totalBoxes'),
        kpi('Cua', '$totalCrabs'),
        kpi('Hộp đang nuôi', '$activeBoxes', colorKey: 'healthy'),
        kpi(
          'Cảnh báo',
          '$openAlerts',
          colorKey: openAlerts > 0 ? 'risk' : 'healthy',
        ),
      ],
      kpiRow1: [
        kpi('Tổng hộp', '$totalBoxes'),
        kpi('Cua sống', '$totalCrabs', colorKey: 'healthy'),
        kpi('Health', '$healthScore', colorKey: healthScore >= 70 ? 'healthy' : 'monitoring'),
        kpi('Nước', '$waterQualityScore', colorKey: 'cyan'),
      ],
      kpiRow2: [
        kpi('Cua khỏe', '$crabHealthScore', colorKey: 'healthy'),
        kpi('Thiết bị', '$deviceStatusScore', colorKey: 'cyan'),
        kpi('IoT online', '${iotOnlinePercentage.toStringAsFixed(0)}%', colorKey: 'cyan'),
        kpi(
          'Cảnh báo mở',
          '$openAlerts',
          colorKey: openAlerts > 0 ? 'risk' : 'healthy',
        ),
      ],
      statusSegments: [
        DashboardStatusSegmentDto(
          label: 'Đang nuôi',
          count: activeBoxes,
          colorKey: 'healthy',
        ),
        DashboardStatusSegmentDto(
          label: 'Trống',
          count: (totalBoxes - activeBoxes).clamp(0, totalBoxes),
          colorKey: 'monitoring',
        ),
      ],
      environmentParams: environmentParams,
      alerts: alerts,
      charts: DashboardChartsDto.fromJson(const {}),
      assistantHint: statusLabel.isEmpty
          ? 'Dữ liệu realtime từ CrabSenseBE'
          : statusLabel,
      statusMessage: statusMessage.isEmpty
          ? 'Đã kết nối CrabSenseBE'
          : statusMessage,
    );
  }

  static List<DashboardEnvParamDto> envFromLive(
    List<Map<String, dynamic>> live,
  ) {
    return live.map((m) {
      final type = (m['sensorType'] ?? m['SensorType'] ?? '').toString();
      final code = (m['sensorCode'] ?? m['SensorCode'] ?? type).toString();
      final unit = (m['unit'] ?? m['Unit'] ?? '').toString();
      final value = (m['latestValue'] ?? m['LatestValue']) as num?;
      final alarm = (m['alarm'] ?? m['Alarm'])?.toString();
      final valueText = value == null
          ? '—'
          : '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$unit';
      return DashboardEnvParamDto(
        icon: _liveIcon(type),
        label: code.isEmpty ? type : code,
        value: valueText,
        status: (alarm != null && alarm.isNotEmpty) ? 'warning' : 'good',
      );
    }).toList();
  }

  static String _liveIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('temp')) return 'thermostat';
    if (t.contains('ph')) return 'science';
    if (t.contains('do') || t.contains('oxy')) return 'air';
    if (t.contains('tds') || t.contains('flow')) return 'waves';
    if (t.contains('salt') || t.contains('salin')) return 'water_drop';
    return 'sensors';
  }

  static List<DashboardAlertDto> alertsFromApi(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.map((m) {
      final severity = (m['severity'] ?? m['Severity'] ?? 'warning').toString();
      final mapped = switch (severity.toLowerCase()) {
        'critical' || 'danger' || 'error' => 'danger',
        'info' || 'low' => 'good',
        _ => 'warning',
      };
      return DashboardAlertDto(
        message: (m['title'] ?? m['Title'] ?? m['message'] ?? m['Message'] ?? '')
            .toString(),
        severity: mapped,
      );
    }).toList();
  }
}

class DashboardKpiDto {
  const DashboardKpiDto({
    required this.label,
    required this.value,
    this.badge,
    this.colorKey,
  });

  final String label;
  final String value;
  final String? badge;
  final String? colorKey;

  factory DashboardKpiDto.fromJson(Map<String, dynamic> json) => DashboardKpiDto(
        label: (json['label'] ?? '').toString(),
        value: (json['value'] ?? '').toString(),
        badge: json['badge']?.toString(),
        colorKey: json['colorKey']?.toString(),
      );
}

class DashboardStatusSegmentDto {
  const DashboardStatusSegmentDto({
    required this.label,
    required this.count,
    required this.colorKey,
  });

  final String label;
  final int count;
  final String colorKey;

  factory DashboardStatusSegmentDto.fromJson(Map<String, dynamic> json) =>
      DashboardStatusSegmentDto(
        label: (json['label'] ?? '').toString(),
        count: (json['count'] as num?)?.toInt() ?? 0,
        colorKey: (json['colorKey'] ?? 'healthy').toString(),
      );
}

class DashboardEnvParamDto {
  const DashboardEnvParamDto({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  final String icon;
  final String label;
  final String value;
  final String status;

  factory DashboardEnvParamDto.fromJson(Map<String, dynamic> json) =>
      DashboardEnvParamDto(
        icon: (json['icon'] ?? 'sensors').toString(),
        label: (json['label'] ?? '').toString(),
        value: (json['value'] ?? '').toString(),
        status: (json['status'] ?? 'good').toString(),
      );
}

class DashboardAlertDto {
  const DashboardAlertDto({required this.message, required this.severity});

  final String message;
  final String severity;

  factory DashboardAlertDto.fromJson(Map<String, dynamic> json) =>
      DashboardAlertDto(
        message: (json['message'] ?? '').toString(),
        severity: (json['severity'] ?? 'warning').toString(),
      );
}

class DashboardChartsDto {
  const DashboardChartsDto({
    required this.labels,
    required this.ph24h,
    required this.temp24h,
    required this.do24h,
    required this.growthBars,
    required this.batchHealth,
    required this.farmHealth,
  });

  final List<String> labels;
  final List<double> ph24h;
  final List<double> temp24h;
  final List<double> do24h;
  final List<double> growthBars;
  final List<DashboardBatchHealthSeriesDto> batchHealth;
  final List<double> farmHealth;

  factory DashboardChartsDto.fromJson(Map<String, dynamic> json) {
    List<double> nums(String key) {
      final raw = json[key];
      if (raw is! List) return [];
      return raw.map((e) => (e as num).toDouble()).toList();
    }

    final batchRaw = json['batchHealth'];
    final batches = batchRaw is List
        ? batchRaw
            .whereType<Map>()
            .map((e) => DashboardBatchHealthSeriesDto.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <DashboardBatchHealthSeriesDto>[];

    final labelsRaw = json['labels'];
    final labels = labelsRaw is List
        ? labelsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return DashboardChartsDto(
      labels: labels,
      ph24h: nums('ph24h'),
      temp24h: nums('temp24h'),
      do24h: nums('do24h'),
      growthBars: nums('growthBars'),
      batchHealth: batches,
      farmHealth: nums('farmHealth'),
    );
  }
}

class DashboardBatchHealthSeriesDto {
  const DashboardBatchHealthSeriesDto({required this.label, required this.values});

  final String label;
  final List<double> values;

  factory DashboardBatchHealthSeriesDto.fromJson(Map<String, dynamic> json) {
    final raw = json['values'];
    return DashboardBatchHealthSeriesDto(
      label: (json['label'] ?? '').toString(),
      values: raw is List ? raw.map((e) => (e as num).toDouble()).toList() : [],
    );
  }
}
