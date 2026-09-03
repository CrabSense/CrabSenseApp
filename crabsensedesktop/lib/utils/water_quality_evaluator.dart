import '../models/water_quality.dart';

abstract final class WaterQualityEvaluator {
  static WaterSensorStatus evaluate(WaterSensorType type, double value) {
    return switch (type) {
      WaterSensorType.temperature =>
        _range(value, 27, 30, good: WaterSensorStatus.normal),
      WaterSensorType.ph =>
        _range(value, 7.5, 8.5, good: WaterSensorStatus.normal),
      WaterSensorType.tds =>
        value <= 800 ? WaterSensorStatus.normal : WaterSensorStatus.exceeded,
      WaterSensorType.flow =>
        value > 0 ? WaterSensorStatus.normal : WaterSensorStatus.monitoring,
      WaterSensorType.waterLevel =>
        value >= 1 ? WaterSensorStatus.normal : WaterSensorStatus.danger,
      WaterSensorType.dissolvedOxygen =>
        value > 5 ? WaterSensorStatus.good : WaterSensorStatus.exceeded,
      WaterSensorType.salinity =>
        _range(value, 10, 25, good: WaterSensorStatus.normal),
      WaterSensorType.orp =>
        _range(value, 250, 350, good: WaterSensorStatus.good),
      WaterSensorType.nh3 =>
        value < 0.1 ? WaterSensorStatus.good : WaterSensorStatus.danger,
      WaterSensorType.no2 =>
        value < 0.5 ? WaterSensorStatus.good : WaterSensorStatus.danger,
    };
  }

  static WaterSensorStatus _range(
    double v,
    double min,
    double max, {
    required WaterSensorStatus good,
  }) {
    if (v >= min && v <= max) return good;
    if (v < min - 1 || v > max + 1) return WaterSensorStatus.danger;
    return WaterSensorStatus.exceeded;
  }

  static SensorThreshold thresholdFor(WaterSensorType type) {
    return switch (type) {
      WaterSensorType.temperature => const SensorThreshold(
          goodRangeLabel: '27–30°C',
          min: 25,
          max: 32,
        ),
      WaterSensorType.ph => const SensorThreshold(
          goodRangeLabel: '7.5–8.5',
          min: 7,
          max: 9,
        ),
      WaterSensorType.tds => const SensorThreshold(
          goodRangeLabel: '< 800 ppm',
          min: 0,
          max: 1200,
        ),
      WaterSensorType.flow => const SensorThreshold(
          goodRangeLabel: '> 0 L/min',
          min: 0,
          max: 20,
        ),
      WaterSensorType.dissolvedOxygen => const SensorThreshold(
          goodRangeLabel: '> 5 mg/L',
          min: 0,
          max: 10,
          minExclusive: 5,
        ),
      WaterSensorType.salinity => const SensorThreshold(
          goodRangeLabel: '10–25 ppt',
          min: 5,
          max: 30,
        ),
      WaterSensorType.orp => const SensorThreshold(
          goodRangeLabel: '250–350 mV',
          min: 200,
          max: 400,
        ),
      WaterSensorType.nh3 => const SensorThreshold(
          goodRangeLabel: '< 0.1 ppm',
          min: 0,
          max: 0.2,
        ),
      WaterSensorType.no2 => const SensorThreshold(
          goodRangeLabel: '< 0.5 ppm',
          min: 0,
          max: 0.6,
        ),
      WaterSensorType.waterLevel => const SensorThreshold(
          goodRangeLabel: 'Có nước (1) / cạn (0)',
          min: 0,
          max: 1,
        ),
    };
  }
}
