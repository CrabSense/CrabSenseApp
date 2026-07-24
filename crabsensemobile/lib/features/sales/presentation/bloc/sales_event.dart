import 'package:equatable/equatable.dart';

import '../../../authentication/domain/entities/user.dart';
import '../../domain/entities/sale.dart';

/// Base class for all Sales BLoC events.
///
/// Requirements: 12.1–12.10
abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object?> get props => [];
}

/// Loads / initializes the sales recording form.
class LoadSalesForm extends SalesEvent {
  const LoadSalesForm({this.farmId});

  final String? farmId;

  @override
  List<Object?> get props => [farmId];
}

/// Fired when the buyer name input changes.
class SalesBuyerNameChanged extends SalesEvent {
  const SalesBuyerNameChanged({required this.buyerName});

  final String buyerName;

  @override
  List<Object?> get props => [buyerName];
}

/// Fired when the buyer contact input changes.
class SalesBuyerContactChanged extends SalesEvent {
  const SalesBuyerContactChanged({required this.buyerContact});

  final String buyerContact;

  @override
  List<Object?> get props => [buyerContact];
}

/// Fired when the quantity text changes.
class SalesQuantityChanged extends SalesEvent {
  const SalesQuantityChanged({required this.quantityText});

  final String quantityText;

  @override
  List<Object?> get props => [quantityText];
}

/// Fired when the unit price text changes.
class SalesUnitPriceChanged extends SalesEvent {
  const SalesUnitPriceChanged({required this.unitPriceText});

  final String unitPriceText;

  @override
  List<Object?> get props => [unitPriceText];
}

/// Fired when the selected payment method changes.
class SalesPaymentMethodChanged extends SalesEvent {
  const SalesPaymentMethodChanged({required this.paymentMethod});

  final PaymentMethod paymentMethod;

  @override
  List<Object?> get props => [paymentMethod];
}

/// Fired when the sale date changes.
class SalesDateChanged extends SalesEvent {
  const SalesDateChanged({required this.saleDate});

  final DateTime saleDate;

  @override
  List<Object?> get props => [saleDate];
}

/// Fired when notes text changes.
class SalesNotesChanged extends SalesEvent {
  const SalesNotesChanged({required this.notes});

  final String notes;

  @override
  List<Object?> get props => [notes];
}

/// Fired when user submits the sale record.
class SubmitSale extends SalesEvent {
  const SubmitSale({
    required this.operatorId,
    required this.operatorName,
    this.userRole,
  });

  final String operatorId;
  final String operatorName;
  final UserRole? userRole;

  @override
  List<Object?> get props => [operatorId, operatorName, userRole];
}

/// Fired to reset the sales form state.
class ResetSalesForm extends SalesEvent {
  const ResetSalesForm();
}
