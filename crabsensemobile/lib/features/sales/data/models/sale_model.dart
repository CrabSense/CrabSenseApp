// ignore_for_file: lines_longer_than_80_chars

import '../../../../core/database/database.dart' as db;
import 'package:drift/drift.dart' show Value;
import '../../domain/entities/sale.dart';
import '../../domain/entities/sales_summary.dart';

/// Data Transfer Object (DTO) for the [Sale] entity.
///
/// Handles JSON serialization/deserialization for API responses and
/// Drift row mapping for local database operations. Extends [Sale]
/// so it can be used directly wherever a domain entity is expected.
///
/// Includes data-layer fields [isDirty] and [syncedAt] for offline-first
/// sync tracking (Requirements 12.7-12.8).
///
/// Requirements: 12.1-12.10
class SaleModel extends Sale {
  const SaleModel({
    required super.id,
    required super.buyerName,
    required super.quantity,
    required super.unitPrice,
    required super.totalAmount,
    required super.paymentMethod,
    required super.saleDate,
    required super.operatorId,
    required super.operatorName,
    super.buyerContact,
    super.paymentStatus = PaymentStatus.completed,
    super.farmId,
    super.notes,
    super.createdAt,
    super.isSynced = false,
    this.isDirty = false,
    this.syncedAt,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a [SaleModel] from a raw API JSON map.
  ///
  /// Supports both camelCase and snake_case field names for API compatibility.
  factory SaleModel.fromJson(Map<String, dynamic> json) => SaleModel(
        id: json['id'] as String? ?? json['transactionId'] as String? ?? json['transaction_id'] as String? ?? '',
        buyerName: json['buyerName'] as String? ?? json['buyer_name'] as String? ?? '',
        buyerContact: json['buyerContact'] as String? ?? json['buyer_contact'] as String?,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unitPrice: (json['unitPrice'] ?? json['unit_price'] as num?)?.toDouble() ?? 0.0,
        totalAmount: (json['totalAmount'] ?? json['total_amount'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: PaymentMethod.fromString(
          json['paymentMethod'] as String? ?? json['payment_method'] as String? ?? 'CASH',
        ),
        paymentStatus: PaymentStatus.fromString(
          json['paymentStatus'] as String? ?? json['payment_status'] as String? ?? 'COMPLETED',
        ),
        saleDate: _parseDateTime(
          json['saleDate'] as String? ?? json['sale_date'] as String? ?? json['createdAt'] as String? ?? json['created_at'] as String?,
        ),
        farmId: json['farmId'] as String? ?? json['farm_id'] as String?,
        operatorId: json['operatorId'] as String? ?? json['operator_id'] as String? ?? json['recordedBy'] as String? ?? json['recorded_by'] as String? ?? '',
        operatorName: json['operatorName'] as String? ?? json['operator_name'] as String? ?? '',
        notes: json['notes'] as String?,
        createdAt: _parseDateTimeNullable(json['createdAt'] as String? ?? json['created_at'] as String?),
        isSynced: json['isSynced'] as bool? ?? json['is_synced'] as bool? ?? true,
        isDirty: json['isDirty'] as bool? ?? json['is_dirty'] as bool? ?? false,
        syncedAt: _parseDateTimeNullable(json['syncedAt'] as String? ?? json['synced_at'] as String?),
      );

  /// Creates a [SaleModel] from a Drift-generated [db.Sale] row.
  factory SaleModel.fromDrift(
    db.Sale row, {
    String? farmId,
    String? operatorId,
    String? operatorName,
    String? notes,
  }) =>
      SaleModel(
        id: row.id,
        buyerName: row.buyerName,
        buyerContact: row.buyerContact,
        quantity: row.quantity,
        unitPrice: row.unitPrice,
        totalAmount: row.totalAmount,
        paymentMethod: PaymentMethod.fromString(row.paymentMethod),
        paymentStatus: PaymentStatus.fromString(row.paymentStatus),
        saleDate: row.saleDate,
        farmId: farmId,
        operatorId: operatorId ?? '',
        operatorName: operatorName ?? '',
        notes: notes,
        createdAt: row.cachedAt,
        isSynced: !row.isDirty,
        isDirty: row.isDirty,
        syncedAt: row.syncedAt,
      );

  /// Creates a [SaleModel] from a domain [Sale] entity.
  factory SaleModel.fromEntity(
    Sale entity, {
    bool isDirty = false,
    DateTime? syncedAt,
  }) =>
      SaleModel(
        id: entity.id,
        buyerName: entity.buyerName,
        buyerContact: entity.buyerContact,
        quantity: entity.quantity,
        unitPrice: entity.unitPrice,
        totalAmount: entity.totalAmount,
        paymentMethod: entity.paymentMethod,
        paymentStatus: entity.paymentStatus,
        saleDate: entity.saleDate,
        farmId: entity.farmId,
        operatorId: entity.operatorId,
        operatorName: entity.operatorName,
        notes: entity.notes,
        createdAt: entity.createdAt,
        isSynced: entity.isSynced,
        isDirty: isDirty,
        syncedAt: syncedAt,
      );

  /// True when local changes have not yet been synced to remote API.
  final bool isDirty;

  /// Server synchronization timestamp.
  final DateTime? syncedAt;

  // ──────────────────────────────────────────────────────────────────────────
  // Serialization & Conversion
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
        'id': id,
        'buyerName': buyerName,
        if (buyerContact != null) 'buyerContact': buyerContact,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod.toCode(),
        'paymentStatus': paymentStatus.toCode(),
        'saleDate': saleDate.toIso8601String(),
        if (farmId != null) 'farmId': farmId,
        'operatorId': operatorId,
        'operatorName': operatorName,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        'isSynced': isSynced,
      };

  /// Converts this model to a [db.SalesCompanion] for Drift inserts/updates.
  db.SalesCompanion toDriftCompanion() => db.SalesCompanion(
        id: Value(id),
        transactionId: Value(id),
        buyerName: Value(buyerName),
        buyerContact: Value(buyerContact),
        quantity: Value(quantity),
        unitPrice: Value(unitPrice),
        totalAmount: Value(totalAmount),
        paymentMethod: Value(paymentMethod.toCode()),
        paymentStatus: Value(paymentStatus.toCode()),
        saleDate: Value(saleDate),
        isDirty: Value(isDirty),
        syncedAt: Value(syncedAt),
        cachedAt: Value(DateTime.now()),
      );

  /// Converts this model to the pure domain [Sale] entity.
  Sale toEntity() => Sale(
        id: id,
        buyerName: buyerName,
        buyerContact: buyerContact,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        saleDate: saleDate,
        farmId: farmId,
        operatorId: operatorId,
        operatorName: operatorName,
        notes: notes,
        createdAt: createdAt,
        isSynced: !isDirty && isSynced,
      );

  @override
  SaleModel copyWith({
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
    bool? isDirty,
    DateTime? syncedAt,
  }) =>
      SaleModel(
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
        isDirty: isDirty ?? this.isDirty,
        syncedAt: syncedAt ?? this.syncedAt,
      );

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.parse(value);
  }

  static DateTime? _parseDateTimeNullable(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }
}

/// JSON-serializable DTO for [SalesSummary].
///
/// Requirement 12.10
class SalesSummaryModel extends SalesSummary {
  const SalesSummaryModel({
    required super.startDate,
    required super.endDate,
    required super.totalSalesCount,
    required super.totalQuantity,
    required super.totalRevenue,
    super.farmId,
    super.farmName,
    super.paymentMethodBreakdown = const {},
  });

  /// Factory constructor to parse [SalesSummaryModel] from JSON.
  factory SalesSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['paymentMethodBreakdown'] as Map<String, dynamic>? ??
        json['payment_method_breakdown'] as Map<String, dynamic>? ??
        {};
    final breakdown = <PaymentMethod, double>{};
    rawBreakdown.forEach((key, val) {
      final method = PaymentMethod.fromString(key);
      final revenue = (val as num?)?.toDouble() ?? 0.0;
      breakdown[method] = revenue;
    });

    return SalesSummaryModel(
      farmId: json['farmId'] as String? ?? json['farm_id'] as String?,
      farmName: json['farmName'] as String? ?? json['farm_name'] as String?,
      startDate: _parseDateTime(json['startDate'] as String? ?? json['start_date'] as String?),
      endDate: _parseDateTime(json['endDate'] as String? ?? json['end_date'] as String?),
      totalSalesCount: (json['totalSalesCount'] ?? json['total_sales_count'] as num?)?.toInt() ?? 0,
      totalQuantity: (json['totalQuantity'] ?? json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['totalRevenue'] ?? json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      paymentMethodBreakdown: breakdown,
    );
  }

  /// Factory constructor to convert domain [SalesSummary] entity to model.
  factory SalesSummaryModel.fromEntity(SalesSummary entity) => SalesSummaryModel(
        farmId: entity.farmId,
        farmName: entity.farmName,
        startDate: entity.startDate,
        endDate: entity.endDate,
        totalSalesCount: entity.totalSalesCount,
        totalQuantity: entity.totalQuantity,
        totalRevenue: entity.totalRevenue,
        paymentMethodBreakdown: entity.paymentMethodBreakdown,
      );

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    final breakdownMap = <String, double>{};
    paymentMethodBreakdown.forEach((method, revenue) {
      breakdownMap[method.toCode()] = revenue;
    });

    return {
      if (farmId != null) 'farmId': farmId,
      if (farmName != null) 'farmName': farmName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalSalesCount': totalSalesCount,
      'totalQuantity': totalQuantity,
      'totalRevenue': totalRevenue,
      'paymentMethodBreakdown': breakdownMap,
    };
  }

  /// Converts this model to domain [SalesSummary] entity.
  SalesSummary toEntity() => SalesSummary(
        farmId: farmId,
        farmName: farmName,
        startDate: startDate,
        endDate: endDate,
        totalSalesCount: totalSalesCount,
        totalQuantity: totalQuantity,
        totalRevenue: totalRevenue,
        paymentMethodBreakdown: paymentMethodBreakdown,
      );

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.parse(value);
  }
}
