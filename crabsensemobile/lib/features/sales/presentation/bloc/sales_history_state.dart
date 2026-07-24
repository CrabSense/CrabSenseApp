import 'package:equatable/equatable.dart';

import '../../domain/entities/sale.dart';
import '../../domain/entities/sales_summary.dart';

/// Base state for Sales History & Reports BLoC.
///
/// Requirements: 12.10
abstract class SalesHistoryState extends Equatable {
  const SalesHistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class SalesHistoryInitial extends SalesHistoryState {
  const SalesHistoryInitial();
}

/// Loading state while fetching history records or summary data.
class SalesHistoryLoading extends SalesHistoryState {
  const SalesHistoryLoading();
}

/// Loaded state containing sales list, summary stats, active filters, and export status.
class SalesHistoryLoaded extends SalesHistoryState {
  const SalesHistoryLoaded({
    required this.sales,
    this.summary,
    this.startDate,
    this.endDate,
    this.farmId,
    this.paymentMethod,
    this.paymentStatus,
    this.isExporting = false,
    this.exportMessage,
    this.exportedFilePath,
  });

  final List<Sale> sales;
  final SalesSummary? summary;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? farmId;
  final PaymentMethod? paymentMethod;
  final PaymentStatus? paymentStatus;
  final bool isExporting;
  final String? exportMessage;
  final String? exportedFilePath;

  /// Creates a copy of [SalesHistoryLoaded] with optional parameter updates.
  SalesHistoryLoaded copyWith({
    List<Sale>? sales,
    SalesSummary? summary,
    DateTime? startDate,
    DateTime? endDate,
    String? farmId,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    bool? isExporting,
    String? exportMessage,
    String? exportedFilePath,
    bool clearExportMessage = false,
    bool clearExportedFilePath = false,
  }) {
    return SalesHistoryLoaded(
      sales: sales ?? this.sales,
      summary: summary ?? this.summary,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      farmId: farmId ?? this.farmId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isExporting: isExporting ?? this.isExporting,
      exportMessage: clearExportMessage ? null : (exportMessage ?? this.exportMessage),
      exportedFilePath: clearExportedFilePath ? null : (exportedFilePath ?? this.exportedFilePath),
    );
  }

  @override
  List<Object?> get props => [
        sales,
        summary,
        startDate,
        endDate,
        farmId,
        paymentMethod,
        paymentStatus,
        isExporting,
        exportMessage,
        exportedFilePath,
      ];
}

/// Error state when fetching sales history or summary fails.
class SalesHistoryError extends SalesHistoryState {
  const SalesHistoryError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
