import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

class KpiItem {
  const KpiItem({
    required this.label,
    required this.value,
    this.color,
    this.badge,
  });

  final String label;
  final String value;
  final Color? color;
  final String? badge;
}

class StatusSegment {
  const StatusSegment({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class EnvParameter {
  const EnvParameter({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  final IconData icon;
  final String label;
  final String value;
  final ParamStatus status;
}

class AlertItem {
  const AlertItem({required this.message, this.severity = ParamStatus.warning});

  final String message;
  final ParamStatus severity;
}

class MockDashboardData {
  static const healthScore = 92;
  static const alertCount = 5;
  static const devicesOnline = '45/48';

  static const kpiRow1 = [
    KpiItem(label: 'Tổng cua', value: '12.450', badge: '+5%'),
    KpiItem(label: 'Lứa nuôi', value: '08'),
    KpiItem(label: 'Cua khỏe', value: '11.350', color: DashboardColors.healthy),
    KpiItem(
      label: 'Theo dõi',
      value: '540',
      color: DashboardColors.monitoring,
    ),
    KpiItem(label: 'Nguy cơ', value: '120', color: DashboardColors.risk),
    KpiItem(label: 'Lột xác', value: '740', color: DashboardColors.molting),
  ];

  static const kpiRow2 = [
    KpiItem(label: 'Cua chết', value: '86', color: DashboardColors.dead),
    KpiItem(label: 'Thu hoạch', value: '2.150'),
    KpiItem(
      label: 'Tỷ lệ sống',
      value: '97.6%',
      color: DashboardColors.healthy,
    ),
    KpiItem(label: 'Doanh thu', value: '458 triệu'),
    KpiItem(label: 'Health', value: '92/100', color: DashboardColors.cyan),
    KpiItem(label: 'Thiết bị', value: '45/48'),
    KpiItem(
      label: 'Cảnh báo',
      value: '05',
      color: DashboardColors.monitoring,
    ),
  ];

  static const summaryKpis = [
    KpiItem(label: 'Tổng Số Cua', value: '12.450', badge: '+5%'),
    KpiItem(label: 'Lứa Nuôi', value: '08'),
    KpiItem(
      label: 'Tỷ Lệ Sống',
      value: '97.6%',
      color: DashboardColors.healthy,
    ),
    KpiItem(label: 'Doanh Thu (Dự kiến)', value: '458 Tr'),
  ];

  static const statusSegments = [
    StatusSegment(
      label: 'CUA KHỎE',
      count: 11350,
      color: DashboardColors.healthy,
    ),
    StatusSegment(
      label: 'THEO DÕI',
      count: 540,
      color: DashboardColors.monitoring,
    ),
    StatusSegment(
      label: 'LỘT XÁC',
      count: 740,
      color: DashboardColors.molting,
    ),
    StatusSegment(
      label: 'NGUY CƠ',
      count: 120,
      color: DashboardColors.risk,
    ),
    StatusSegment(
      label: 'CUA CHẾT',
      count: 86,
      color: DashboardColors.dead,
    ),
  ];

  static const environmentParams = [
    EnvParameter(
      icon: Icons.thermostat_outlined,
      label: 'Nhiệt độ',
      value: '28.4°C',
      status: ParamStatus.good,
    ),
    EnvParameter(
      icon: Icons.science_outlined,
      label: 'pH',
      value: '7.8',
      status: ParamStatus.excellent,
    ),
    EnvParameter(
      icon: Icons.air_outlined,
      label: 'DO',
      value: '6.4 mg/L',
      status: ParamStatus.good,
    ),
    EnvParameter(
      icon: Icons.waves_outlined,
      label: 'Độ mặn',
      value: '15 ppt',
      status: ParamStatus.good,
    ),
    EnvParameter(
      icon: Icons.bolt_outlined,
      label: 'ORP',
      value: '280 mV',
      status: ParamStatus.excellent,
    ),
    EnvParameter(
      icon: Icons.warning_amber_outlined,
      label: 'NH3',
      value: '0.02 mg/L',
      status: ParamStatus.good,
    ),
    EnvParameter(
      icon: Icons.warning_amber_outlined,
      label: 'NO2',
      value: '0.01 mg/L',
      status: ParamStatus.excellent,
    ),
    EnvParameter(
      icon: Icons.water_drop_outlined,
      label: 'Mực nước',
      value: '95 cm',
      status: ParamStatus.good,
    ),
  ];

  static const alerts = [
    AlertItem(
      message: 'NH3 khu A tăng cao',
      severity: ParamStatus.danger,
    ),
    AlertItem(
      message: 'DO khu C thấp',
      severity: ParamStatus.warning,
    ),
    AlertItem(
      message: 'Thiết bị Sensor-08 mất kết nối',
      severity: ParamStatus.warning,
    ),
    AlertItem(
      message: '3 cá thể cua bỏ ăn > 2 ngày',
      severity: ParamStatus.warning,
    ),
    AlertItem(
      message: 'Khu B chuẩn bị lột xác hàng loạt',
      severity: ParamStatus.good,
    ),
  ];

  static List<double> get ph24h =>
      [7.2, 7.4, 7.5, 7.6, 7.8, 7.9, 7.8, 7.7, 7.8, 7.9, 7.8, 7.8];

  static List<double> get temp24h =>
      [27.8, 28.0, 28.2, 28.4, 28.6, 28.5, 28.4, 28.3, 28.4, 28.5, 28.4, 28.4];

  static List<double> get do24h =>
      [5.8, 6.0, 6.2, 6.1, 6.3, 6.4, 6.5, 6.2, 6.4, 6.3, 6.4, 6.4];

  static List<double> get growthBars =>
      [120, 145, 168, 190, 210, 235, 260, 285];

  static List<double> get batch01Health =>
      [88, 89, 90, 91, 92, 91, 93, 92, 94, 93, 92, 92];

  static List<double> get batch02Health =>
      [85, 86, 87, 88, 89, 88, 90, 89, 91, 90, 89, 90];

  static List<double> get batch03Health =>
      [82, 83, 84, 85, 86, 85, 87, 86, 88, 87, 86, 87];

  static List<double> get farmHealth =>
      [90, 91, 91, 92, 92, 91, 93, 92, 93, 92, 92, 92];

  static const chartLabels = [
    '00:00',
    '02:00',
    '04:00',
    '06:00',
    '08:00',
    '10:00',
    '12:00',
    '14:00',
    '16:00',
    '18:00',
    '20:00',
    '22:00',
  ];

  static String assistantMessage(int healthScore) {
    if (healthScore >= 90) {
      return 'Health Score ổn định.\n\nKhông phát hiện bất thường.\n\nKhuyến nghị:\nTăng oxy khu B thêm 5% trong 30 phút tới.';
    }
    if (healthScore >= 75) {
      return 'Health Score ở mức khá.\n\nTheo dõi DO khu B và NH3 khu A.\n\nKhuyến nghị:\nKiểm tra sensor khu B trong 1 giờ.';
    }
    return 'Health Score cần chú ý.\n\nPhát hiện xu hướng DO giảm.\n\nKhuyến nghị:\nTăng oxy toàn khu B ngay lập tức.';
  }
}
