import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sales_summary.dart';

/// Card widget displaying aggregated KPI metrics and summary statistics for sales reports.
///
/// Features:
/// - Total Revenue ($) & Total Quantity Sold (kg)
/// - Total Transactions & Average Sale Value ($)
/// - Payment Method breakdown (Cash, Bank Transfer, Credit)
/// - Custom date period indicator
///
/// Requirements: 12.10
class SalesSummaryCard extends StatelessWidget {
  const SalesSummaryCard({
    required this.summary,
    super.key,
  });

  final SalesSummary summary;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final numberFormatter = NumberFormat('#,##0.0');
    final dateFormat = DateFormat('MMM dd, yyyy');

    final periodLabel =
        '${dateFormat.format(summary.startDate)} - ${dateFormat.format(summary.endDate)}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CrabSenseColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CrabSenseColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Period Title & Farm Context
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: CrabSenseColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Sales Performance',
                    style: TextStyle(
                      color: CrabSenseColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CrabSenseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CrabSenseColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  periodLabel,
                  style: const TextStyle(
                    color: CrabSenseColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Grid KPIs: Total Revenue & Total Quantity
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Revenue',
                  value: currencyFormatter.format(summary.totalRevenue),
                  icon: Icons.attach_money_rounded,
                  accentColor: CrabSenseColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Quantity',
                  value: '${numberFormatter.format(summary.totalQuantity)} kg',
                  icon: Icons.scale_rounded,
                  accentColor: CrabSenseColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Secondary KPIs: Total Sales Count & Average Sale Value
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Transactions',
                  value: '${summary.totalSalesCount}',
                  icon: Icons.receipt_long_rounded,
                  accentColor: CrabSenseColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Avg Sale Value',
                  value: currencyFormatter.format(summary.averageSaleValue),
                  icon: Icons.trending_up_rounded,
                  accentColor: CrabSenseColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Method Revenue Breakdown Section
          if (summary.paymentMethodBreakdown.isNotEmpty) ...[
            const Text(
              'Payment Method Revenue Breakdown',
              style: TextStyle(
                color: CrabSenseColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildPaymentMethodBreakdown(currencyFormatter),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CrabSenseColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CrabSenseColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: CrabSenseColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodBreakdown(NumberFormat currencyFormatter) {
    final Map<PaymentMethod, double> breakdown = summary.paymentMethodBreakdown;
    final double grandTotal = summary.totalRevenue > 0 ? summary.totalRevenue : 1.0;

    return Column(
      children: PaymentMethod.values.map((method) {
        final amount = breakdown[method] ?? 0.0;
        final percentage = (amount / grandTotal * 100).clamp(0.0, 100.0);

        Color methodColor;
        switch (method) {
          case PaymentMethod.cash:
            methodColor = CrabSenseColors.success;
            break;
          case PaymentMethod.bankTransfer:
            methodColor = CrabSenseColors.primary;
            break;
          case PaymentMethod.credit:
            methodColor = CrabSenseColors.warning;
            break;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: methodColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        method.displayName,
                        style: const TextStyle(
                          color: CrabSenseColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${currencyFormatter.format(amount)} (${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      color: CrabSenseColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100.0,
                  backgroundColor: CrabSenseColors.background,
                  color: methodColor,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
