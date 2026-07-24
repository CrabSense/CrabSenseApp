import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/create_sale_usecase.dart';
import 'sales_event.dart';
import 'sales_state.dart';

/// BLoC for managing sales recording form state and submission logic.
///
/// Event → State transitions:
/// - [LoadSalesForm]          → [SalesFormState] (initialized with default/initial values)
/// - [SalesBuyerNameChanged]   → [SalesFormState] (buyerName updated, buyerNameError cleared)
/// - [SalesBuyerContactChanged]→ [SalesFormState] (buyerContact updated)
/// - [SalesQuantityChanged]    → [SalesFormState] (quantityText updated, totalAmount updated, quantityError cleared)
/// - [SalesUnitPriceChanged]   → [SalesFormState] (unitPriceText updated, totalAmount updated, unitPriceError cleared)
/// - [SalesPaymentMethodChanged]→ [SalesFormState] (paymentMethod updated)
/// - [SalesDateChanged]        → [SalesFormState] (saleDate updated, dateError cleared)
/// - [SalesNotesChanged]       → [SalesFormState] (notes updated)
/// - [SubmitSale]             → [SalesFormState](isSubmitting: true)
///                                → [SalesFormState](isSubmitted: true) on success or offline queue
///                                → [SalesFormState](submissionError) on failure
/// - [ResetSalesForm]          → [SalesFormState] (reset to default form)
///
/// Requirements: 12.1–12.10
class SalesBloc extends Bloc<SalesEvent, SalesState> {
  SalesBloc({
    required CreateSaleUseCase createSale,
  })  : _createSale = createSale,
        super(const SalesInitial()) {
    on<LoadSalesForm>(_onLoadForm);
    on<SalesBuyerNameChanged>(_onBuyerNameChanged);
    on<SalesBuyerContactChanged>(_onBuyerContactChanged);
    on<SalesQuantityChanged>(_onQuantityChanged);
    on<SalesUnitPriceChanged>(_onUnitPriceChanged);
    on<SalesPaymentMethodChanged>(_onPaymentMethodChanged);
    on<SalesDateChanged>(_onDateChanged);
    on<SalesNotesChanged>(_onNotesChanged);
    on<SubmitSale>(_onSubmit);
    on<ResetSalesForm>(_onResetForm);
  }

  final CreateSaleUseCase _createSale;
  static const _uuid = Uuid();

  // ── Load Form ─────────────────────────────────────────────────────────────

  void _onLoadForm(LoadSalesForm event, Emitter<SalesState> emit) {
    emit(
      SalesFormState(
        buyerName: '',
        buyerContact: '',
        quantityText: '',
        unitPriceText: '',
        paymentMethod: PaymentMethod.cash,
        saleDate: DateTime.now(),
        notes: '',
        farmId: event.farmId ?? '',
      ),
    );
  }

  // ── Field Updates ─────────────────────────────────────────────────────────

  void _onBuyerNameChanged(SalesBuyerNameChanged event, Emitter<SalesState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(buyerName: event.buyerName, clearBuyerNameError: true));
  }

  void _onBuyerContactChanged(SalesBuyerContactChanged event, Emitter<SalesState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(buyerContact: event.buyerContact));
  }

  void _onQuantityChanged(SalesQuantityChanged event, Emitter<SalesState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(quantityText: event.quantityText, clearQuantityError: true));
  }

  void _onUnitPriceChanged(SalesUnitPriceChanged event, Emitter<SalesState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(unitPriceText: event.unitPriceText, clearUnitPriceError: true));
  }

  void _onPaymentMethodChanged(SalesPaymentMethodChanged event, Emitter<SalesState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(paymentMethod: event.paymentMethod));
  }

  void _onDateChanged(SalesDateChanged event, Emitter<SalesState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(saleDate: event.saleDate, clearDateError: true));
  }

  void _onNotesChanged(SalesNotesChanged event, Emitter<SalesState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(notes: event.notes));
  }

  // ── Form Submission ───────────────────────────────────────────────────────

  Future<void> _onSubmit(SubmitSale event, Emitter<SalesState> emit) async {
    final s = _formState;
    if (s == null) return;

    bool hasError = false;
    String? buyerNameErr;
    String? quantityErr;
    String? unitPriceErr;
    String? dateErr;

    // Validate buyer name (Requirement 12.2)
    if (s.buyerName.trim().isEmpty) {
      buyerNameErr = 'Buyer name is required';
      hasError = true;
    }

    // Validate positive quantity (Requirement 12.2)
    final quantity = s.parsedQuantity;
    if (quantity <= 0) {
      quantityErr = 'Quantity must be a positive number';
      hasError = true;
    }

    // Validate positive unit price (Requirement 12.2)
    final unitPrice = s.parsedUnitPrice;
    if (unitPrice <= 0) {
      unitPriceErr = 'Unit price must be a positive number';
      hasError = true;
    }

    // Validate sale date not in future (Requirement 12.2)
    if (s.saleDate.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      dateErr = 'Sale date cannot be in the future';
      hasError = true;
    }

    if (hasError) {
      emit(
        s.copyWith(
          buyerNameError: buyerNameErr,
          quantityError: quantityErr,
          unitPriceError: unitPriceErr,
          dateError: dateErr,
        ),
      );
      return;
    }

    // Generate unique transaction identifier (Requirement 12.6)
    final sale = Sale(
      id: 'sale-${_uuid.v4()}',
      buyerName: s.buyerName.trim(),
      buyerContact: s.buyerContact.trim().isEmpty ? null : s.buyerContact.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: s.totalAmount, // Requirement 12.3: Automatically calculated
      paymentMethod: s.paymentMethod, // Requirement 12.5
      paymentStatus: PaymentStatus.completed,
      saleDate: s.saleDate, // Requirement 12.2
      farmId: s.farmId.trim().isEmpty ? null : s.farmId.trim(),
      operatorId: event.operatorId,
      operatorName: event.operatorName,
      notes: s.notes.trim().isEmpty ? null : s.notes.trim(),
      createdAt: DateTime.now(),
    );

    emit(s.copyWith(isSubmitting: true, clearSubmissionError: true));

    final result = await _createSale(
      CreateSaleParams(
        sale: sale,
        userRole: event.userRole,
      ),
    );

    result.fold(
      (failure) {
        if (failure is NetworkFailure) {
          // Requirement 12.8: Saved locally when offline
          emit(
            s.copyWith(
              isSubmitting: false,
              isSubmitted: true,
              isOffline: true,
              createdSale: sale,
            ),
          );
        } else {
          emit(
            s.copyWith(
              isSubmitting: false,
              submissionError: failure.message,
            ),
          );
        }
      },
      (savedSale) {
        // Requirement 12.7: Synchronized
        emit(
          s.copyWith(
            isSubmitting: false,
            isSubmitted: true,
            createdSale: savedSale,
          ),
        );
      },
    );
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _onResetForm(ResetSalesForm event, Emitter<SalesState> emit) {
    emit(
      SalesFormState(
        buyerName: '',
        buyerContact: '',
        quantityText: '',
        unitPriceText: '',
        paymentMethod: PaymentMethod.cash,
        saleDate: DateTime.now(),
        notes: '',
      ),
    );
  }

  /// Helper getter to access current state as [SalesFormState], or null.
  SalesFormState? get _formState =>
      state is SalesFormState ? state as SalesFormState : null;
}
