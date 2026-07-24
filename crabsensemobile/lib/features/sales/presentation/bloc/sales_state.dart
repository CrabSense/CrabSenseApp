import 'package:equatable/equatable.dart';

import '../../domain/entities/sale.dart';

/// Base state for Sales BLoC.
///
/// Requirements: 12.1–12.10
abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class SalesInitial extends SalesState {
  const SalesInitial();
}

/// Form state for recording sales transaction.
class SalesFormState extends SalesState {
  const SalesFormState({
    required this.buyerName,
    required this.buyerContact,
    required this.quantityText,
    required this.unitPriceText,
    required this.paymentMethod,
    required this.saleDate,
    this.notes = '',
    this.farmId = '',
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.isOffline = false,
    this.buyerNameError,
    this.quantityError,
    this.unitPriceError,
    this.dateError,
    this.submissionError,
    this.createdSale,
    this.availableInventory,
  });

  final String buyerName;
  final String buyerContact;
  final String quantityText;
  final String unitPriceText;
  final PaymentMethod paymentMethod;
  final DateTime saleDate;
  final String notes;
  final String farmId;

  final bool isSubmitting;
  final bool isSubmitted;
  final bool isOffline;

  final String? buyerNameError;
  final String? quantityError;
  final String? unitPriceError;
  final String? dateError;
  final String? submissionError;

  final Sale? createdSale;
  final double? availableInventory;

  /// Parsed double quantity value.
  double get parsedQuantity => double.tryParse(quantityText.replaceAll(',', '.')) ?? 0.0;

  /// Parsed double unit price value.
  double get parsedUnitPrice => double.tryParse(unitPriceText.replaceAll(',', '.')) ?? 0.0;

  /// Requirement 12.3: Total amount calculated automatically from quantity and unit price.
  double get totalAmount => parsedQuantity * parsedUnitPrice;

  /// Creates a copy of this form state with updated fields.
  SalesFormState copyWith({
    String? buyerName,
    String? buyerContact,
    String? quantityText,
    String? unitPriceText,
    PaymentMethod? paymentMethod,
    DateTime? saleDate,
    String? notes,
    String? farmId,
    bool? isSubmitting,
    bool? isSubmitted,
    bool? isOffline,
    String? buyerNameError,
    String? quantityError,
    String? unitPriceError,
    String? dateError,
    String? submissionError,
    Sale? createdSale,
    double? availableInventory,
    bool clearBuyerNameError = false,
    bool clearQuantityError = false,
    bool clearUnitPriceError = false,
    bool clearDateError = false,
    bool clearSubmissionError = false,
  }) {
    return SalesFormState(
      buyerName: buyerName ?? this.buyerName,
      buyerContact: buyerContact ?? this.buyerContact,
      quantityText: quantityText ?? this.quantityText,
      unitPriceText: unitPriceText ?? this.unitPriceText,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleDate: saleDate ?? this.saleDate,
      notes: notes ?? this.notes,
      farmId: farmId ?? this.farmId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isOffline: isOffline ?? this.isOffline,
      buyerNameError: clearBuyerNameError ? null : (buyerNameError ?? this.buyerNameError),
      quantityError: clearQuantityError ? null : (quantityError ?? this.quantityError),
      unitPriceError: clearUnitPriceError ? null : (unitPriceError ?? this.unitPriceError),
      dateError: clearDateError ? null : (dateError ?? this.dateError),
      submissionError: clearSubmissionError ? null : (submissionError ?? this.submissionError),
      createdSale: createdSale ?? this.createdSale,
      availableInventory: availableInventory ?? this.availableInventory,
    );
  }

  @override
  List<Object?> get props => [
        buyerName,
        buyerContact,
        quantityText,
        unitPriceText,
        paymentMethod,
        saleDate,
        notes,
        farmId,
        isSubmitting,
        isSubmitted,
        isOffline,
        buyerNameError,
        quantityError,
        unitPriceError,
        dateError,
        submissionError,
        createdSale,
        availableInventory,
      ];
}
