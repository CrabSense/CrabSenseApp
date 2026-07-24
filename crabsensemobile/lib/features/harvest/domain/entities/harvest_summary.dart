import 'harvest.dart';

/// Domain entity representing aggregated harvest metrics for a farm within a date range.
///
/// Requirement 11.10
class HarvestSummary {
  const HarvestSummary({
    required this.farmId,
    required this.startDate,
    required this.endDate,
    required this.totalWeight,
    required this.totalCrabCount,
    required this.totalHarvestsCount,
    this.farmName,
    this.gradeBreakdown = const {},
  });

  /// Farm identifier
  final String farmId;

  /// Optional farm name
  final String? farmName;

  /// Start of summary period
  final DateTime startDate;

  /// End of summary period
  final DateTime endDate;

  /// Cumulative harvest weight in kilograms (Requirement 11.10)
  final double totalWeight;

  /// Total count of crabs harvested
  final int totalCrabCount;

  /// Total number of harvest operations performed
  final int totalHarvestsCount;

  /// Harvest weight breakdown per quality grade
  final Map<QualityGrade, double> gradeBreakdown;

  /// Average weight per harvest operation in kg.
  double get averageWeightPerHarvest =>
      totalHarvestsCount > 0 ? totalWeight / totalHarvestsCount : 0.0;

  /// Average weight per crab in kg.
  double get averageWeightPerCrab =>
      totalCrabCount > 0 ? totalWeight / totalCrabCount : 0.0;

  /// Creates a copy of [HarvestSummary] with updated fields.
  HarvestSummary copyWith({
    String? farmId,
    String? farmName,
    DateTime? startDate,
    DateTime? endDate,
    double? totalWeight,
    int? totalCrabCount,
    int? totalHarvestsCount,
    Map<QualityGrade, double>? gradeBreakdown,
  }) {
    return HarvestSummary(
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalWeight: totalWeight ?? this.totalWeight,
      totalCrabCount: totalCrabCount ?? this.totalCrabCount,
      totalHarvestsCount: totalHarvestsCount ?? this.totalHarvestsCount,
      gradeBreakdown: gradeBreakdown ?? this.gradeBreakdown,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HarvestSummary) return false;
    return other.farmId == farmId &&
        other.farmName == farmName &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.totalWeight == totalWeight &&
        other.totalCrabCount == totalCrabCount &&
        other.totalHarvestsCount == totalHarvestsCount;
  }

  @override
  int get hashCode => Object.hash(
        farmId,
        farmName,
        startDate,
        endDate,
        totalWeight,
        totalCrabCount,
        totalHarvestsCount,
      );

  @override
  String toString() {
    return 'HarvestSummary(farmId: $farmId, farmName: $farmName, '
        'period: $startDate - $endDate, totalWeight: ${totalWeight}kg, '
        'totalCrabCount: $totalCrabCount, totalHarvestsCount: $totalHarvestsCount)';
  }
}
