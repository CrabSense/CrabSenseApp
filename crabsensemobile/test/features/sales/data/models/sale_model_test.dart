import 'package:crabsensemobile/core/database/database.dart' as db;
import 'package:crabsensemobile/features/sales/data/models/sale_model.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sale.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sales_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tSaleDate = DateTime.parse('2026-07-21T10:00:00.000Z');

  final tSaleModel = SaleModel(
    id: 'sale-123',
    buyerName: 'Ocean Catch Ltd',
    buyerContact: '0912345678',
    quantity: 25.0,
    unitPrice: 40.0,
    totalAmount: 1000.0,
    paymentMethod: PaymentMethod.bankTransfer,
    paymentStatus: PaymentStatus.completed,
    saleDate: tSaleDate,
    farmId: 'FARM-01',
    operatorId: 'op-001',
    operatorName: 'Alice Smith',
    notes: 'Paid in full',
    createdAt: tSaleDate,
    isSynced: true,
    isDirty: false,
  );

  group('SaleModel JSON Tests', () {
    test('fromJson parses camelCase and snake_case correctly', () {
      final jsonMap = {
        'id': 'sale-123',
        'buyer_name': 'Ocean Catch Ltd',
        'buyer_contact': '0912345678',
        'quantity': 25.0,
        'unit_price': 40.0,
        'total_amount': 1000.0,
        'payment_method': 'BANK_TRANSFER',
        'payment_status': 'COMPLETED',
        'sale_date': '2026-07-21T10:00:00.000Z',
        'farm_id': 'FARM-01',
        'operator_id': 'op-001',
        'operator_name': 'Alice Smith',
        'notes': 'Paid in full',
        'is_synced': true,
      };

      final result = SaleModel.fromJson(jsonMap);

      expect(result.id, 'sale-123');
      expect(result.buyerName, 'Ocean Catch Ltd');
      expect(result.buyerContact, '0912345678');
      expect(result.quantity, 25.0);
      expect(result.unitPrice, 40.0);
      expect(result.totalAmount, 1000.0);
      expect(result.paymentMethod, PaymentMethod.bankTransfer);
      expect(result.paymentStatus, PaymentStatus.completed);
      expect(result.operatorId, 'op-001');
      expect(result.notes, 'Paid in full');
    });

    test('toJson serializes to Map with correct types', () {
      final jsonMap = tSaleModel.toJson();

      expect(jsonMap['id'], 'sale-123');
      expect(jsonMap['buyerName'], 'Ocean Catch Ltd');
      expect(jsonMap['quantity'], 25.0);
      expect(jsonMap['unitPrice'], 40.0);
      expect(jsonMap['totalAmount'], 1000.0);
      expect(jsonMap['paymentMethod'], 'BANK_TRANSFER');
      expect(jsonMap['paymentStatus'], 'COMPLETED');
      expect(jsonMap['operatorId'], 'op-001');
    });
  });

  group('SaleModel Drift & Entity Mapping Tests', () {
    test('toDriftCompanion creates valid Drift update companion', () {
      final companion = tSaleModel.toDriftCompanion();

      expect(companion.id.value, 'sale-123');
      expect(companion.buyerName.value, 'Ocean Catch Ltd');
      expect(companion.quantity.value, 25.0);
      expect(companion.unitPrice.value, 40.0);
      expect(companion.totalAmount.value, 1000.0);
      expect(companion.paymentMethod.value, 'BANK_TRANSFER');
      expect(companion.paymentStatus.value, 'COMPLETED');
    });

    test('fromDrift maps Drift table row correctly', () {
      final row = db.Sale(
        id: 'sale-123',
        transactionId: 'sale-123',
        buyerName: 'Ocean Catch Ltd',
        buyerContact: '0912345678',
        quantity: 25.0,
        unitPrice: 40.0,
        totalAmount: 1000.0,
        paymentMethod: 'BANK_TRANSFER',
        paymentStatus: 'COMPLETED',
        saleDate: tSaleDate,
        isDirty: false,
        cachedAt: tSaleDate,
      );

      final model = SaleModel.fromDrift(
        row,
        farmId: 'FARM-01',
        operatorId: 'op-001',
        operatorName: 'Alice Smith',
        notes: 'Paid in full',
      );

      expect(model.id, 'sale-123');
      expect(model.buyerName, 'Ocean Catch Ltd');
      expect(model.farmId, 'FARM-01');
      expect(model.operatorName, 'Alice Smith');
      expect(model.paymentMethod, PaymentMethod.bankTransfer);
    });

    test('toEntity and fromEntity convert domain entity seamlessly', () {
      final entity = tSaleModel.toEntity();
      expect(entity, isA<Sale>());
      expect(entity.id, tSaleModel.id);

      final convertedModel = SaleModel.fromEntity(entity, isDirty: false);
      expect(convertedModel.id, tSaleModel.id);
    });
  });

  group('SalesSummaryModel Tests', () {
    test('fromJson & toJson map SalesSummary correctly', () {
      final jsonMap = {
        'farm_id': 'FARM-01',
        'farm_name': 'Main Farm',
        'start_date': '2026-07-14T00:00:00.000Z',
        'end_date': '2026-07-21T00:00:00.000Z',
        'total_sales_count': 10,
        'total_quantity': 150.0,
        'total_revenue': 6000.0,
        'payment_method_breakdown': {
          'CASH': 2000.0,
          'BANK_TRANSFER': 4000.0,
        },
      };

      final summaryModel = SalesSummaryModel.fromJson(jsonMap);

      expect(summaryModel.farmId, 'FARM-01');
      expect(summaryModel.farmName, 'Main Farm');
      expect(summaryModel.totalQuantity, 150.0);
      expect(summaryModel.totalRevenue, 6000.0);
      expect(summaryModel.totalSalesCount, 10);
      expect(summaryModel.paymentMethodBreakdown[PaymentMethod.bankTransfer], 4000.0);

      final serialized = summaryModel.toJson();
      expect(serialized['farmId'], 'FARM-01');
      expect(serialized['totalRevenue'], 6000.0);

      final entity = summaryModel.toEntity();
      expect(entity, isA<SalesSummary>());
      expect(entity.farmId, 'FARM-01');
    });
  });
}
