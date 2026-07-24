import 'sale.dart';

/// Domain entity representing aggregated sales metrics for daily or weekly reports.
///
/// Requirement 12.10
class SalesSummary {
  const SalesSummary({
    required this.startDate,
    required this.endDate,
    required this.totalSalesCount,
    required this.totalQuantity,
    required this.totalRevenue,
    this.farmId,
    this.farmName,
    this.paymentMethodBreakdown = const {},
    this.paymentStatusBreakdown = const {},
  });

  /// Optional farm identifier filter
  final String? farmId;

  /// Optional farm name
  final String? farmName;

  /// Start of summary period
  final DateTime startDate;

  /// End of summary period
  final DateTime endDate;

  /// Total number of sales transactions recorded
  final int totalSalesCount;

  /// Cumulative quantity sold in kilograms/units
  final double totalQuantity;

  /// Total revenue generated across all transactions
  final double totalRevenue;

  /// Revenue breakdown per payment method
  final Map<PaymentMethod, double> paymentMethodBreakdown;

  /// Transaction count breakdown per payment status
  final Map<PaymentStatus, int> paymentStatusBreakdown;

  /// Average revenue per sales transaction.
  double get averageSaleValue =>
      totalSalesCount > 0 ? totalRevenue / totalSalesCount : 0.0;

  /// Creates a copy of [SalesSummary] with updated fields.
  SalesSummary copyWith({
    String? farmId,
    String? farmName,
    DateTime? startDate,
    DateTime? endDate,
    int? totalSalesCount,
    double? totalQuantity,
    double? totalRevenue,
    Map<PaymentMethod, double>? paymentMethodBreakdown,
    Map<PaymentStatus, int>? paymentStatusBreakdown,
  }) {
    return SalesSummary(
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalSalesCount: totalSalesCount ?? this.totalSalesCount,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      paymentMethodBreakdown:
          paymentMethodBreakdown ?? this.paymentMethodBreakdown,
      paymentStatusBreakdown:
          paymentStatusBreakdown ?? this.paymentStatusBreakdown,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SalesSummary) return false;
    return other.farmId == farmId &&
        other.farmName == farmName &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.totalSalesCount == totalSalesCount &&
        other.totalQuantity == totalQuantity &&
        other.totalRevenue == totalRevenue;
  }

  @override
  int get hashCode => Object.hash(
        farmId,
        farmName,
        startDate,
        endDate,
        totalSalesCount,
        totalQuantity,
        totalRevenue,
      );

  @override
  String toString() {
    return 'SalesSummary(farmId: $farmId, period: $startDate - $endDate, '
        'totalSalesCount: $totalSalesCount, totalQuantity: ${totalQuantity}kg, '
        'totalRevenue: $totalRevenue)';
  }
}
