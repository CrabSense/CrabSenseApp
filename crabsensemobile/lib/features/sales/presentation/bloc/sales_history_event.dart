import 'package:equatable/equatable.dart';

import '../../domain/entities/sale.dart';

/// Base class for Sales History & Reports BLoC events.
///
/// Requirements: 12.10
abstract class SalesHistoryEvent extends Equatable {
  const SalesHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load sales history records and summary metrics.
class LoadSalesHistory extends SalesHistoryEvent {
  const LoadSalesHistory({
    this.farmId,
    this.buyerName,
    this.startDate,
    this.endDate,
    this.paymentMethod,
    this.paymentStatus,
    this.page = 1,
  });

  final String? farmId;
  final String? buyerName;
  final DateTime? startDate;
  final DateTime? endDate;
  final PaymentMethod? paymentMethod;
  final PaymentStatus? paymentStatus;
  final int page;

  @override
  List<Object?> get props => [
        farmId,
        buyerName,
        startDate,
        endDate,
        paymentMethod,
        paymentStatus,
        page,
      ];
}

/// Event fired when date range filter is changed.
class FilterSalesDateRangeChanged extends SalesHistoryEvent {
  const FilterSalesDateRangeChanged({
    this.startDate,
    this.endDate,
  });

  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event fired when payment method filter is changed.
class FilterSalesPaymentMethodChanged extends SalesHistoryEvent {
  const FilterSalesPaymentMethodChanged({this.paymentMethod});

  final PaymentMethod? paymentMethod;

  @override
  List<Object?> get props => [paymentMethod];
}

/// Event to trigger CSV export of current filtered sales list.
class ExportSalesToCsv extends SalesHistoryEvent {
  const ExportSalesToCsv();
}
