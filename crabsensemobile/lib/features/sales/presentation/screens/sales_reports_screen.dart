import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/sale.dart';
import '../bloc/sales_history_bloc.dart';
import '../bloc/sales_history_event.dart';
import '../bloc/sales_history_state.dart';
import '../widgets/sales_summary_card.dart';

/// Screen displaying Sales Summary reports, daily/weekly aggregated revenue metrics,
/// payment method breakdowns, filterable date ranges, and CSV export functionality.
///
/// Requirements: 12.10
class SalesReportsScreen extends StatelessWidget {
  const SalesReportsScreen({
    this.initialFarmId,
    this.initialStartDate,
    this.initialEndDate,
    super.key,
  });

  final String? initialFarmId;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SalesHistoryBloc>(
      create: (_) => sl<SalesHistoryBloc>()
        ..add(
          LoadSalesHistory(
            farmId: initialFarmId,
            startDate: initialStartDate,
            endDate: initialEndDate,
          ),
        ),
      child: const _SalesReportsView(),
    );
  }
}

class _SalesReportsView extends StatefulWidget {
  const _SalesReportsView();

  @override
  State<_SalesReportsView> createState() => _SalesReportsViewState();
}

class _SalesReportsViewState extends State<_SalesReportsView> {
  bool _showSummary = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrabSenseColors.background,
      appBar: AppBar(
        title: const Text(
          'Sales Summary & Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: CrabSenseColors.surface,
        foregroundColor: CrabSenseColors.textPrimary,
        elevation: 0,
        actions: [
          BlocConsumer<SalesHistoryBloc, SalesHistoryState>(
            listener: (context, state) {
              if (state is SalesHistoryLoaded) {
                if (state.exportMessage != null) {
                  final isError = state.exportMessage!.startsWith('Failed');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.exportMessage!),
                      backgroundColor: isError ? CrabSenseColors.error : CrabSenseColors.success,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              final isExporting = state is SalesHistoryLoaded && state.isExporting;
              return IconButton(
                icon: isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CrabSenseColors.primary,
                        ),
                      )
                    : const Icon(Icons.download_rounded, color: CrabSenseColors.primary),
                tooltip: 'Export CSV',
                onPressed: isExporting
                    ? null
                    : () {
                        context.read<SalesHistoryBloc>().add(const ExportSalesToCsv());
                      },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SalesHistoryBloc, SalesHistoryState>(
        builder: (context, state) {
          if (state is SalesHistoryLoading || state is SalesHistoryInitial) {
            return const Center(
              child: CircularProgressIndicator(color: CrabSenseColors.primary),
            );
          }

          if (state is SalesHistoryError) {
            return _buildErrorView(context, state.message);
          }

          if (state is SalesHistoryLoaded) {
            return Column(
              children: [
                _buildFilterBar(context, state),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<SalesHistoryBloc>().add(
                            LoadSalesHistory(
                              startDate: state.startDate,
                              endDate: state.endDate,
                              farmId: state.farmId,
                              paymentMethod: state.paymentMethod,
                            ),
                          );
                    },
                    color: CrabSenseColors.primary,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toggle Summary / KPI Card section
                          if (state.summary != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Daily & Weekly Summary',
                                  style: TextStyle(
                                    color: CrabSenseColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showSummary = !_showSummary;
                                    });
                                  },
                                  icon: Icon(
                                    _showSummary ? Icons.expand_less : Icons.expand_more,
                                    size: 18,
                                    color: CrabSenseColors.primary,
                                  ),
                                  label: Text(
                                    _showSummary ? 'Hide Summary' : 'Show Summary',
                                    style: const TextStyle(color: CrabSenseColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            if (_showSummary) ...[
                              const SizedBox(height: 8),
                              SalesSummaryCard(summary: state.summary!),
                              const SizedBox(height: 20),
                            ],
                          ],

                          // Sales Transactions History Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sales Transactions (${state.sales.length})',
                                style: const TextStyle(
                                  color: CrabSenseColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (state.sales.isNotEmpty)
                                const Text(
                                  'Showing latest',
                                  style: TextStyle(
                                    color: CrabSenseColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (state.sales.isEmpty)
                            _buildEmptyState(context)
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.sales.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _buildSaleCard(context, state.sales[index]);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── Filter Bar Component ──────────────────────────────────────────────────

  Widget _buildFilterBar(BuildContext context, SalesHistoryLoaded state) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final hasDateFilter = state.startDate != null || state.endDate != null;
    final dateRangeLabel = hasDateFilter
        ? '${state.startDate != null ? dateFormat.format(state.startDate!) : "Start"} - ${state.endDate != null ? dateFormat.format(state.endDate!) : "Now"}'
        : 'Filter Date Range';

    return Container(
      color: CrabSenseColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Date Range Filter Chip
            ActionChip(
              avatar: Icon(
                Icons.date_range_rounded,
                size: 16,
                color: hasDateFilter ? CrabSenseColors.primary : CrabSenseColors.textSecondary,
              ),
              label: Text(
                dateRangeLabel,
                style: TextStyle(
                  color: hasDateFilter ? CrabSenseColors.primary : CrabSenseColors.textPrimary,
                  fontSize: 12,
                  fontWeight: hasDateFilter ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              backgroundColor: hasDateFilter
                  ? CrabSenseColors.primary.withValues(alpha: 0.1)
                  : CrabSenseColors.background,
              side: BorderSide(
                color: hasDateFilter ? CrabSenseColors.primary : CrabSenseColors.border,
              ),
              onPressed: () => _selectDateRange(context, state),
            ),
            const SizedBox(width: 8),

            // Payment Method Dropdown Filter
            DropdownButton<PaymentMethod?>(
              value: state.paymentMethod,
              hint: const Text(
                'All Payment Methods',
                style: TextStyle(color: CrabSenseColors.textSecondary, fontSize: 12),
              ),
              dropdownColor: CrabSenseColors.surface,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: CrabSenseColors.textSecondary),
              items: [
                const DropdownMenuItem<PaymentMethod?>(
                  value: null,
                  child: Text('All Methods', style: TextStyle(color: CrabSenseColors.textPrimary, fontSize: 12)),
                ),
                ...PaymentMethod.values.map(
                  (method) => DropdownMenuItem<PaymentMethod?>(
                    value: method,
                    child: Text(
                      method.displayName,
                      style: const TextStyle(color: CrabSenseColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ),
              ],
              onChanged: (method) {
                context
                    .read<SalesHistoryBloc>()
                    .add(FilterSalesPaymentMethodChanged(paymentMethod: method));
              },
            ),
            const SizedBox(width: 8),

            // Reset Filters Chip
            if (hasDateFilter || state.paymentMethod != null || state.farmId != null)
              ActionChip(
                avatar: const Icon(Icons.close_rounded, size: 14, color: CrabSenseColors.error),
                label: const Text(
                  'Reset',
                  style: TextStyle(color: CrabSenseColors.error, fontSize: 12),
                ),
                backgroundColor: CrabSenseColors.error.withValues(alpha: 0.1),
                side: const BorderSide(color: CrabSenseColors.error),
                onPressed: () {
                  context.read<SalesHistoryBloc>().add(const LoadSalesHistory());
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, SalesHistoryLoaded state) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: CrabSenseColors.primary,
              onPrimary: Colors.black,
              surface: CrabSenseColors.surface,
              onSurface: CrabSenseColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      context.read<SalesHistoryBloc>().add(
            FilterSalesDateRangeChanged(
              startDate: picked.start,
              endDate: picked.end,
            ),
          );
    }
  }

  // ── Sale Item Card Widget ──────────────────────────────────────────────────

  Widget _buildSaleCard(BuildContext context, Sale sale) {
    final dateFormat = DateFormat('MMM dd, yyyy · HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final statusColor = _getStatusColor(sale.paymentStatus);

    return Container(
      decoration: BoxDecoration(
        color: CrabSenseColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.border),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Buyer Name & Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 18, color: CrabSenseColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    sale.buyerName,
                    style: const TextStyle(
                      color: CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  sale.paymentStatus.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mini Details Row
          Row(
            children: [
              Expanded(
                child: _buildMiniDetail('Total Revenue', currencyFormat.format(sale.totalAmount)),
              ),
              Expanded(
                child: _buildMiniDetail('Quantity', '${sale.quantity.toStringAsFixed(1)} kg'),
              ),
              Expanded(
                child: _buildMiniDetail('Unit Price', currencyFormat.format(sale.unitPrice)),
              ),
              Expanded(
                child: _buildMiniDetail('Payment', sale.paymentMethod.displayName),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Footer: Date & Operator Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(sale.saleDate),
                style: const TextStyle(
                  color: CrabSenseColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                'By: ${sale.operatorName}',
                style: const TextStyle(
                  color: CrabSenseColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Note: ${sale.notes}',
              style: const TextStyle(
                color: CrabSenseColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CrabSenseColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: CrabSenseColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return CrabSenseColors.success;
      case PaymentStatus.pending:
        return CrabSenseColors.warning;
      case PaymentStatus.cancelled:
        return CrabSenseColors.error;
    }
  }

  // ── Empty & Error States ─────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: CrabSenseColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 48, color: CrabSenseColors.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'No Sales Records Found',
            style: TextStyle(
              color: CrabSenseColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your date range or payment method filters.',
            style: TextStyle(color: CrabSenseColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<SalesHistoryBloc>().add(const LoadSalesHistory());
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CrabSenseColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: CrabSenseColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: CrabSenseColors.textPrimary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<SalesHistoryBloc>().add(const LoadSalesHistory());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CrabSenseColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
