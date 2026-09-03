import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum WaterSensorStatus {
  normal,
  good,
  monitoring,
  exceeded,
  danger,
  offline;

  String get label => switch (this) {
        WaterSensorStatus.normal => 'Bình thường',
        WaterSensorStatus.good => 'Tốt',
        WaterSensorStatus.monitoring => 'Cần theo dõi',
        WaterSensorStatus.exceeded => 'Vượt ngưỡng',
        WaterSensorStatus.danger => 'Nguy hiểm',
        WaterSensorStatus.offline => 'Mất tín hiệu',
      };

  Color get color => switch (this) {
        WaterSensorStatus.normal => DashboardColors.healthy,
        WaterSensorStatus.good => DashboardColors.healthy,
        WaterSensorStatus.monitoring => DashboardColors.monitoring,
        WaterSensorStatus.exceeded => DashboardColors.molting,
        WaterSensorStatus.danger => DashboardColors.risk,
        WaterSensorStatus.offline => DashboardColors.dead,
      };
}

enum WaterSensorType {
  ph,
  temperature,
  tds,
  flow,
  waterLevel,
  dissolvedOxygen,
  salinity,
  orp,
  nh3,
  no2;

  /// Thứ tự hiển thị: Cloud pins trước, mock sau.
  static const cloudFirst = [
    WaterSensorType.temperature,
    WaterSensorType.ph,
    WaterSensorType.tds,
    WaterSensorType.flow,
    WaterSensorType.waterLevel,
    WaterSensorType.dissolvedOxygen,
    WaterSensorType.salinity,
    WaterSensorType.orp,
    WaterSensorType.nh3,
    WaterSensorType.no2,
  ];

  String get label => switch (this) {
        WaterSensorType.ph => 'pH',
        WaterSensorType.dissolvedOxygen => 'DO',
        WaterSensorType.temperature => 'Nhiệt độ',
        WaterSensorType.tds => 'TDS',
        WaterSensorType.flow => 'Lưu lượng',
        WaterSensorType.salinity => 'Độ mặn',
        WaterSensorType.orp => 'Chỉ số ORP',
        WaterSensorType.nh3 => 'NH3',
        WaterSensorType.no2 => 'NO2',
        WaterSensorType.waterLevel => 'Mực nước',
      };

  String get shortLabel => switch (this) {
        WaterSensorType.dissolvedOxygen => 'Oxy hòa tan',
        WaterSensorType.temperature => 'Nhiệt độ',
        WaterSensorType.tds => 'TDS',
        WaterSensorType.flow => 'Lưu lượng',
        WaterSensorType.salinity => 'Độ mặn',
        WaterSensorType.orp => 'ORP',
        WaterSensorType.nh3 => 'Amonia',
        WaterSensorType.no2 => 'Nitrit',
        WaterSensorType.waterLevel => 'Mực nước',
        WaterSensorType.ph => 'pH',
      };
}

class SensorThreshold {
  const SensorThreshold({
    required this.goodRangeLabel,
    this.min,
    this.max,
    this.minExclusive,
  });

  final String goodRangeLabel;
  final double? min;
  final double? max;
  final double? minExclusive;
}

class WaterSensorReading {
  const WaterSensorReading({
    required this.type,
    required this.value,
    required this.unit,
    required this.status,
    required this.threshold,
    this.offline = false,
  });

  final WaterSensorType type;
  final double value;
  final String unit;
  final WaterSensorStatus status;
  final SensorThreshold threshold;
  final bool offline;

  String get displayValue {
    if (type == WaterSensorType.temperature) {
      return '${value.toStringAsFixed(1)}°C';
    }
    if (type == WaterSensorType.waterLevel && value <= 1) {
      return value >= 1 ? 'Có' : 'Cạn';
    }
    if (value == value.roundToDouble() && type != WaterSensorType.ph) {
      return '${value.round()} $unit';
    }
    return '${value.toStringAsFixed(value < 1 ? 2 : 1)} $unit';
  }

  /// 0.0–1.0 for gauge arc fill
  double get gaugeProgress {
    final min = threshold.min ?? 0;
    final max = threshold.max ?? (value * 1.5).clamp(1, 999);
    if (max <= min) return 0.7;
    return ((value - min) / (max - min)).clamp(0.08, 0.95);
  }
}

class WaterHistoryRow {
  const WaterHistoryRow({
    required this.time,
    required this.values,
  });

  final String time;
  final Map<WaterSensorType, String> values;
}

class WaterTrendPoint {
  const WaterTrendPoint({
    required this.xMinutes,
    required this.label,
    required this.timestamp,
    required this.temperature,
    required this.ph,
    required this.tds,
    required this.flow,
    this.dissolvedOxygen,
  });

  /// Phút tính từ đầu cửa sổ (0 → rangeMinutes).
  final double xMinutes;
  final String label;
  final DateTime timestamp;
  final double temperature;
  final double ph;
  final double tds;
  final double flow;

  /// Chỉ có khi fallback mock (API không có DO).
  final double? dissolvedOxygen;
}
