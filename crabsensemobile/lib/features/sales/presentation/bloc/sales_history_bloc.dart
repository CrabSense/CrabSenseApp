import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sale.dart';
import '../../domain/entities/sales_summary.dart';
import '../../domain/usecases/get_sales_history_usecase.dart';
import '../../domain/usecases/get_sales_summary_usecase.dart';
import '../utils/sales_csv_exporter.dart';
import 'sales_history_event.dart';
import 'sales_history_state.dart';

/// BLoC for managing Sales History & Reports screen state, filtering, aggregation, and CSV export.
///
/// Requirements: 12.10
class SalesHistoryBloc extends Bloc<SalesHistoryEvent, SalesHistoryState> {
  SalesHistoryBloc({
    required GetSalesHistoryUseCase getSalesHistory,
    required GetSalesSummaryUseCase getSalesSummary,
  })  : _getSalesHistory = getSalesHistory,
        _getSalesSummary = getSalesSummary,
        super(const SalesHistoryInitial()) {
    on<LoadSalesHistory>(_onLoadSalesHistory);
    on<FilterSalesDateRangeChanged>(_onFilterDateRangeChanged);
    on<FilterSalesPaymentMethodChanged>(_onFilterPaymentMethodChanged);
    on<ExportSalesToCsv>(_onExportSalesToCsv);
  }

  final GetSalesHistoryUseCase _getSalesHistory;
  final GetSalesSummaryUseCase _getSalesSummary;

  Future<void> _onLoadSalesHistory(
    LoadSalesHistory event,
    Emitter<SalesHistoryState> emit,
  ) async {
    emit(const SalesHistoryLoading());

    final startDate = event.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final endDate = event.endDate ?? DateTime.now();

    final historyResult = await _getSalesHistory(
      GetSalesHistoryParams(
        farmId: event.farmId,
        buyerName: event.buyerName,
        startDate: startDate,
        endDate: endDate,
        paymentMethod: event.paymentMethod,
        paymentStatus: event.paymentStatus,
        page: event.page,
      ),
    );

    await historyResult.fold(
      (failure) async {
        emit(SalesHistoryError(message: failure.message));
      },
      (sales) async {
        // Retrieve or compute summary metrics
        final summaryResult = await _getSalesSummary(
          GetSalesSummaryParams(
            farmId: event.farmId,
            startDate: startDate,
            endDate: endDate,
          ),
        );

        SalesSummary? summary = summaryResult.fold(
          (_) => null,
          (summary) => summary,
        );

        // Fallback: Compute summary from fetched records if summary usecase returned null/empty or fallback needed
        if (summary == null || summary.totalSalesCount == 0 && sales.isNotEmpty) {
          summary = _computeSummaryFromSales(sales, startDate, endDate, event.farmId);
        }

        emit(
          SalesHistoryLoaded(
            sales: sales,
            summary: summary,
            startDate: startDate,
            endDate: endDate,
            farmId: event.farmId,
            paymentMethod: event.paymentMethod,
            paymentStatus: event.paymentStatus,
          ),
        );
      },
    );
  }

  Future<void> _onFilterDateRangeChanged(
    FilterSalesDateRangeChanged event,
    Emitter<SalesHistoryState> emit,
  ) async {
    final currentState = state;
    final farmId = currentState is SalesHistoryLoaded ? currentState.farmId : null;
    final paymentMethod = currentState is SalesHistoryLoaded ? currentState.paymentMethod : null;

    add(
      LoadSalesHistory(
        startDate: event.startDate,
        endDate: event.endDate,
        farmId: farmId,
        paymentMethod: paymentMethod,
      ),
    );
  }

  Future<void> _onFilterPaymentMethodChanged(
    FilterSalesPaymentMethodChanged event,
    Emitter<SalesHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is SalesHistoryLoaded) {
      add(
        LoadSalesHistory(
          startDate: currentState.startDate,
          endDate: currentState.endDate,
          farmId: currentState.farmId,
          paymentMethod: event.paymentMethod,
        ),
      );
    }
  }

  Future<void> _onExportSalesToCsv(
    ExportSalesToCsv event,
    Emitter<SalesHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalesHistoryLoaded) return;

    emit(currentState.copyWith(isExporting: true, clearExportMessage: true));

    try {
      if (currentState.sales.isEmpty) {
        emit(
          currentState.copyWith(
            isExporting: false,
            exportMessage: 'No sales records available to export.',
          ),
        );
        return;
      }

      final file = await SalesCsvExporter.exportToCsvFile(currentState.sales);

      emit(
        currentState.copyWith(
          isExporting: false,
          exportedFilePath: file.path,
          exportMessage: 'Exported ${currentState.sales.length} sales to CSV file successfully.',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isExporting: false,
          exportMessage: 'Failed to export CSV: ${e.toString()}',
        ),
      );
    }
  }

  /// Helper method to compute summary metrics directly from sales list.
  SalesSummary _computeSummaryFromSales(
    List<Sale> sales,
    DateTime startDate,
    DateTime endDate,
    String? farmId,
  ) {
    double totalRevenue = 0.0;
    double totalQuantity = 0.0;
    final paymentMethodBreakdown = <PaymentMethod, double>{};
    final paymentStatusBreakdown = <PaymentStatus, int>{};

    for (final sale in sales) {
      totalRevenue += sale.totalAmount;
      totalQuantity += sale.quantity;

      paymentMethodBreakdown[sale.paymentMethod] =
          (paymentMethodBreakdown[sale.paymentMethod] ?? 0.0) + sale.totalAmount;

      paymentStatusBreakdown[sale.paymentStatus] =
          (paymentStatusBreakdown[sale.paymentStatus] ?? 0) + 1;
    }

    return SalesSummary(
      startDate: startDate,
      endDate: endDate,
      farmId: farmId,
      totalSalesCount: sales.length,
      totalQuantity: totalQuantity,
      totalRevenue: totalRevenue,
      paymentMethodBreakdown: paymentMethodBreakdown,
      paymentStatusBreakdown: paymentStatusBreakdown,
    );
  }
}
