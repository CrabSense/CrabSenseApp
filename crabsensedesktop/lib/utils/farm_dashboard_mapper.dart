import 'package:flutter/material.dart';

import '../data/mock_dashboard_data.dart';
import '../models/area_environment_metric.dart';
import '../models/farm_dashboard_overview.dart';
import '../models/water_quality.dart';
import '../theme/dashboard_theme.dart';

Color? kpiColor(String? key) => switch (key) {
      'healthy' => DashboardColors.healthy,
      'monitoring' => DashboardColors.monitoring,
      'risk' => DashboardColors.risk,
      'molting' => DashboardColors.molting,
      'dead' => DashboardColors.dead,
      'cyan' => DashboardColors.cyan,
      _ => null,
    };

Color statusSegmentColor(String key) => kpiColor(key) ?? DashboardColors.textMuted;

KpiItem mapKpi(DashboardKpiDto dto) => KpiItem(
      label: dto.label,
      value: dto.value,
      badge: dto.badge,
      color: kpiColor(dto.colorKey),
    );

StatusSegment mapStatusSegment(DashboardStatusSegmentDto dto) => StatusSegment(
      label: dto.label,
      count: dto.count,
      color: statusSegmentColor(dto.colorKey),
    );

IconData envIcon(String key) => switch (key) {
      'thermostat' => Icons.thermostat_outlined,
      'science' => Icons.science_outlined,
      'air' => Icons.air_outlined,
      'waves' => Icons.waves_outlined,
      'bolt' => Icons.bolt_outlined,
      'water_drop' => Icons.water_drop_outlined,
      'warning' => Icons.warning_amber_outlined,
      _ => Icons.sensors_outlined,
    };

ParamStatus mapEnvStatus(String status) => switch (status.toLowerCase()) {
      'excellent' => ParamStatus.excellent,
      'warning' => ParamStatus.warning,
      'danger' => ParamStatus.danger,
      _ => ParamStatus.good,
    };

EnvParameter mapEnvParam(DashboardEnvParamDto dto) => EnvParameter(
      icon: envIcon(dto.icon),
      label: dto.label,
      value: dto.value,
      status: mapEnvStatus(dto.status),
    );

AlertItem mapAlert(DashboardAlertDto dto) => AlertItem(
      message: dto.message,
      severity: switch (dto.severity.toLowerCase()) {
        'danger' => ParamStatus.danger,
        'good' => ParamStatus.good,
        _ => ParamStatus.warning,
      },
    );

List<EnvParameter> metricsToEnvParams(List<AreaEnvironmentMetric> metrics) =>
    metrics
        .map(
          (m) => EnvParameter(
            icon: envIcon(m.icon),
            label: m.label,
            value: m.unit.isEmpty
                ? m.value.toStringAsFixed(m.value == m.value.roundToDouble() ? 0 : 1)
                : '${m.value.toStringAsFixed(1)}${m.unit}',
            status: mapEnvStatus(m.status),
          ),
        )
        .toList();

/// Mẫu realtime từ sensor-latest (pH, nhiệt, DO).
WaterTrendPoint? metricsToLiveTrendPoint(List<AreaEnvironmentMetric> metrics) {
  double? ph;
  double? temp;
  double? doVal;
  for (final m in metrics) {
    final t = (m.sensorType ?? m.icon).toLowerCase();
    if (t.contains('ph')) ph = m.value;
    if (t.contains('temp')) temp = m.value;
    if (t == 'do' || t.contains('oxygen')) doVal = m.value;
  }
  if (ph == null && temp == null) return null;
  final now = DateTime.now();
  return WaterTrendPoint(
    xMinutes: 0,
    label:
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}',
    timestamp: now,
    ph: ph ?? 7.8,
    temperature: temp ?? 28.0,
    tds: 0,
    flow: 0,
    dissolvedOxygen: doVal ?? 6.4,
  );
}

List<WaterTrendPoint> chartToTrendPoints(DashboardChartsDto charts) {
  final n = charts.ph24h.length;
  if (n == 0) return [];
  final now = DateTime.now();
  final points = <WaterTrendPoint>[];
  for (var i = 0; i < n; i++) {
    final ph = i < charts.ph24h.length ? charts.ph24h[i] : 7.8;
    final temp = i < charts.temp24h.length ? charts.temp24h[i] : 28.0;
    final label = i < charts.labels.length ? charts.labels[i] : '';
    points.add(
      WaterTrendPoint(
        xMinutes: i * 120.0,
        label: label,
        timestamp: now.subtract(Duration(hours: 24 - i * 2)),
        ph: ph,
        temperature: temp,
        tds: 0,
        flow: 0,
        dissolvedOxygen: i < charts.do24h.length ? charts.do24h[i] : 6.4,
      ),
    );
  }
  return points;
}
