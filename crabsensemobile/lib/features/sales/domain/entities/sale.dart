/// Payment methods supported for sales transactions.
///
/// Requirement 12.5
enum PaymentMethod {
  /// Cash payment method
  cash,

  /// Bank transfer payment method
  bankTransfer,

  /// Credit payment method
  credit;

  /// Human-readable display label for UI rendering.
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  /// Parses string representation to [PaymentMethod].
  /// Defaults to [PaymentMethod.cash] if unrecognized.
  static PaymentMethod fromString(String val) {
    switch (val.trim().toUpperCase()) {
      case 'CASH':
        return PaymentMethod.cash;
      case 'BANK_TRANSFER':
      case 'BANKTRANSFER':
      case 'BANK TRANSFER':
        return PaymentMethod.bankTransfer;
      case 'CREDIT':
        return PaymentMethod.credit;
      default:
        return PaymentMethod.cash;
    }
  }

  /// Returns string code suitable for API / database serialization.
  String toCode() {
    switch (this) {
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
      case PaymentMethod.credit:
        return 'CREDIT';
    }
  }
}

/// Payment statuses for sales transactions.
///
/// Requirement 12.1-12.10
enum PaymentStatus {
  /// Payment is pending
  pending,

  /// Payment has been completed
  completed,

  /// Payment has been cancelled
  cancelled;

  /// Human-readable display label for UI rendering.
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Parses string representation to [PaymentStatus].
  /// Defaults to [PaymentStatus.completed] if unrecognized.
  static PaymentStatus fromString(String val) {
    switch (val.trim().toUpperCase()) {
      case 'PENDING':
        return PaymentStatus.pending;
      case 'COMPLETED':
        return PaymentStatus.completed;
      case 'CANCELLED':
      case 'CANCELED':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.completed;
    }
  }

  /// Returns string code suitable for API / database serialization.
  String toCode() {
    switch (this) {
      case PaymentStatus.pending:
        return 'PENDING';
      case PaymentStatus.completed:
        return 'COMPLETED';
      case PaymentStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

/// Domain entity representing a sales transaction record in the CrabSense system.
///
/// Captures sale data including buyer details, quantity sold, unit price, total amount,
/// payment method, payment status, sale date, and operator identity.
///
/// Pure domain model with immutable properties.
///
/// Requirements: 12.1-12.10
class Sale {
  const Sale({
    required this.id,
    required this.buyerName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.paymentMethod,
    required this.saleDate,
    required this.operatorId,
    required this.operatorName,
    this.buyerContact,
    this.paymentStatus = PaymentStatus.completed,
    this.farmId,
    this.notes,
    this.createdAt,
    this.isSynced = false,
  });

  /// Unique sale transaction identifier (Requirement 12.6)
  final String id;

  /// Buyer name or customer identity (Requirement 12.1, 12.2)
  final String buyerName;

  /// Optional contact details for buyer (phone/email)
  final String? buyerContact;

  /// Quantity sold in kilograms or units (Requirement 12.2, must be positive)
  final double quantity;

  /// Price per unit in local currency (Requirement 12.2, must be positive)
  final double unitPrice;

  /// Total transaction amount (Requirement 12.2, 12.3)
  final double totalAmount;

  /// Selected payment method (Requirement 12.2, 12.5)
  final PaymentMethod paymentMethod;

  /// Status of the payment transaction
  final PaymentStatus paymentStatus;

  /// Date and time when the sale took place (Requirement 12.2)
  final DateTime saleDate;

  /// Identifier of the farm associated with the harvested crabs
  final String? farmId;

  /// Identifier of the field operator/user recording the sale
  final String operatorId;

  /// Display name of the operator
  final String operatorName;

  /// Optional notes or comments regarding the sale
  final String? notes;

  /// Server timestamp when created
  final DateTime? createdAt;

  /// Offline synchronization indicator (Requirement 12.7, 12.8)
  final bool isSynced;

  /// Automatically calculated total amount based on quantity and unit price.
  double get calculatedTotal => quantity * unitPrice;

  /// Creates a copy of this sale record with updated fields.
  Sale copyWith({
    String? id,
    String? buyerName,
    String? buyerContact,
    double? quantity,
    double? unitPrice,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    DateTime? saleDate,
    String? farmId,
    String? operatorId,
    String? operatorName,
    String? notes,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return Sale(
      id: id ?? this.id,
      buyerName: buyerName ?? this.buyerName,
      buyerContact: buyerContact ?? this.buyerContact,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      saleDate: saleDate ?? this.saleDate,
      farmId: farmId ?? this.farmId,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Sale) return false;
    return other.id == id &&
        other.buyerName == buyerName &&
        other.buyerContact == buyerContact &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice &&
        other.totalAmount == totalAmount &&
        other.paymentMethod == paymentMethod &&
        other.paymentStatus == paymentStatus &&
        other.saleDate == saleDate &&
        other.farmId == farmId &&
        other.operatorId == operatorId &&
        other.operatorName == operatorName &&
        other.notes == notes &&
        other.isSynced == isSynced;
  }

  @override
  int get hashCode => Object.hash(
        id,
        buyerName,
        buyerContact,
        quantity,
        unitPrice,
        totalAmount,
        paymentMethod,
        paymentStatus,
        saleDate,
        farmId,
        operatorId,
        operatorName,
        notes,
        isSynced,
      );

  @override
  String toString() {
    return 'Sale(id: $id, buyerName: $buyerName, quantity: ${quantity}kg, '
        'unitPrice: $unitPrice, totalAmount: $totalAmount, '
        'paymentMethod: ${paymentMethod.displayName}, paymentStatus: ${paymentStatus.displayName}, '
        'saleDate: $saleDate, operatorId: $operatorId, isSynced: $isSynced)';
  }
}
