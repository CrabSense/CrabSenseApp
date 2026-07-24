import 'package:crabsensemobile/features/sales/domain/entities/sale.dart';
import 'package:crabsensemobile/features/sales/presentation/utils/sales_csv_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleSales = [
    Sale(
      id: 'SALE-001',
      buyerName: 'Ocean Seafood Co., Ltd.',
      buyerContact: '0901234567',
      quantity: 50.0,
      unitPrice: 30.0,
      totalAmount: 1500.0,
      paymentMethod: PaymentMethod.cash,
      paymentStatus: PaymentStatus.completed,
      saleDate: DateTime(2026, 7, 21, 10, 30),
      farmId: 'FARM-01',
      operatorId: 'OP-100',
      operatorName: 'John Doe',
      notes: 'Bulk purchase, prompt payment',
    ),
    Sale(
      id: 'SALE-002',
      buyerName: 'Delta Crab Market',
      buyerContact: '0987654321',
      quantity: 25.5,
      unitPrice: 35.0,
      totalAmount: 892.5,
      paymentMethod: PaymentMethod.bankTransfer,
      paymentStatus: PaymentStatus.pending,
      saleDate: DateTime(2026, 7, 21, 14, 15),
      farmId: 'FARM-01',
      operatorId: 'OP-101',
      operatorName: 'Jane Smith',
    ),
  ];

  group('SalesCsvExporter', () {
    test('generateCsvString creates correctly structured header and rows', () {
      final csv = SalesCsvExporter.generateCsvString(sampleSales);

      expect(csv, contains('Transaction ID,Sale Date,Farm ID,Buyer Name,Buyer Contact'));
      expect(csv, contains('"Ocean Seafood Co., Ltd."'));
      expect(csv, contains('SALE-001'));
      expect(csv, contains('1500.00'));
      expect(csv, contains('Cash'));
      expect(csv, contains('Completed'));

      expect(csv, contains('SALE-002'));
      expect(csv, contains('Delta Crab Market'));
      expect(csv, contains('892.50'));
      expect(csv, contains('Bank Transfer'));
      expect(csv, contains('Pending'));
    });

    test('generateCsvString handles empty list', () {
      final csv = SalesCsvExporter.generateCsvString([]);
      expect(csv, contains('Transaction ID,Sale Date,Farm ID'));
      expect(csv.split('\n').where((line) => line.trim().isNotEmpty).length, equals(1));
    });
  });
}
