import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sale.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sales_summary.dart';
import 'package:crabsensemobile/features/sales/domain/repositories/sales_repository.dart';
import 'package:crabsensemobile/features/sales/domain/usecases/create_sale_usecase.dart';
import 'package:crabsensemobile/features/sales/domain/usecases/get_sales_history_usecase.dart';
import 'package:crabsensemobile/features/sales/domain/usecases/get_sales_summary_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSalesRepository implements SalesRepository {
  Either<Failure, Sale>? createSaleResult;
  Either<Failure, List<Sale>>? getHistoryResult;
  Either<Failure, SalesSummary>? getSummaryResult;
  Either<Failure, double>? getInventoryResult;

  Sale? lastCreatedSale;
  String? lastSummaryFarmId;

  @override
  Future<Either<Failure, Sale>> createSale(Sale sale) async {
    lastCreatedSale = sale;
    return createSaleResult ?? Right(sale);
  }

  @override
  Future<Either<Failure, List<Sale>>> getSalesHistory({
    String? farmId,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int page = 1,
    int pageSize = 50,
  }) async {
    return getHistoryResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, SalesSummary>> getSalesSummary({
    String? farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    lastSummaryFarmId = farmId;
    return getSummaryResult ??
        Right(SalesSummary(
          farmId: farmId,
          startDate: startDate,
          endDate: endDate,
          totalSalesCount: 5,
          totalQuantity: 50.0,
          totalRevenue: 2500.0,
        ));
  }

  @override
  Future<Either<Failure, Sale>> getSaleById(String id) async {
    return Left(ServerFailure.notFound(id));
  }

  @override
  Future<Either<Failure, double>> getAvailableHarvestedInventory({String? farmId}) async {
    return getInventoryResult ?? const Right(100.0);
  }
}

void main() {
  late MockSalesRepository mockRepo;
  late CreateSaleUseCase createSaleUseCase;
  late GetSalesHistoryUseCase getSalesHistoryUseCase;
  late GetSalesSummaryUseCase getSalesSummaryUseCase;

  final validSale = Sale(
    id: 'sale-101',
    buyerName: 'Seafood Corp',
    buyerContact: '0901234567',
    quantity: 20.0,
    unitPrice: 50.0,
    totalAmount: 1000.0,
    paymentMethod: PaymentMethod.cash,
    paymentStatus: PaymentStatus.completed,
    saleDate: DateTime.now(),
    farmId: 'FARM-01',
    operatorId: 'op-001',
    operatorName: 'Alice Operator',
    notes: 'Bulk sale',
  );

  setUp(() {
    mockRepo = MockSalesRepository();
    createSaleUseCase = CreateSaleUseCase(mockRepo);
    getSalesHistoryUseCase = GetSalesHistoryUseCase(mockRepo);
    getSalesSummaryUseCase = GetSalesSummaryUseCase(mockRepo);
  });

  group('PaymentMethod enum', () {
    test('displayName returns proper labels', () {
      expect(PaymentMethod.cash.displayName, 'Cash');
      expect(PaymentMethod.bankTransfer.displayName, 'Bank Transfer');
      expect(PaymentMethod.credit.displayName, 'Credit');
    });

    test('fromString parses valid values correctly', () {
      expect(PaymentMethod.fromString('CASH'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('BANK_TRANSFER'), PaymentMethod.bankTransfer);
      expect(PaymentMethod.fromString('CREDIT'), PaymentMethod.credit);
      expect(PaymentMethod.fromString('UNKNOWN'), PaymentMethod.cash);
    });

    test('toCode returns standardized uppercase codes', () {
      expect(PaymentMethod.cash.toCode(), 'CASH');
      expect(PaymentMethod.bankTransfer.toCode(), 'BANK_TRANSFER');
      expect(PaymentMethod.credit.toCode(), 'CREDIT');
    });
  });

  group('PaymentStatus enum', () {
    test('displayName returns proper labels', () {
      expect(PaymentStatus.pending.displayName, 'Pending');
      expect(PaymentStatus.completed.displayName, 'Completed');
      expect(PaymentStatus.cancelled.displayName, 'Cancelled');
    });

    test('fromString parses valid values correctly', () {
      expect(PaymentStatus.fromString('PENDING'), PaymentStatus.pending);
      expect(PaymentStatus.fromString('COMPLETED'), PaymentStatus.completed);
      expect(PaymentStatus.fromString('CANCELLED'), PaymentStatus.cancelled);
      expect(PaymentStatus.fromString('UNKNOWN'), PaymentStatus.completed);
    });

    test('toCode returns standardized uppercase codes', () {
      expect(PaymentStatus.pending.toCode(), 'PENDING');
      expect(PaymentStatus.completed.toCode(), 'COMPLETED');
      expect(PaymentStatus.cancelled.toCode(), 'CANCELLED');
    });
  });

  group('Sale Entity', () {
    test('calculates calculatedTotal correctly', () {
      expect(validSale.calculatedTotal, 1000.0);
    });

    test('copyWith creates modified copy', () {
      final updated = validSale.copyWith(quantity: 30.0, totalAmount: 1500.0);
      expect(updated.quantity, 30.0);
      expect(updated.totalAmount, 1500.0);
      expect(updated.buyerName, 'Seafood Corp');
    });
  });

  group('SalesSummary Entity', () {
    test('calculates averageSaleValue correctly', () {
      final summary = SalesSummary(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        totalSalesCount: 10,
        totalQuantity: 100.0,
        totalRevenue: 5000.0,
      );
      expect(summary.averageSaleValue, 500.0);
    });
  });

  group('CreateSaleUseCase', () {
    test('succeeds when input is valid and user has Sales role', () async {
      final params = CreateSaleParams(
        sale: validSale,
        userRole: UserRole.sales,
      );

      final result = await createSaleUseCase(params);

      expect(result.isRight(), true);
      expect(mockRepo.lastCreatedSale?.id, 'sale-101');
    });

    test('fails when user role is Viewer (unauthorized)', () async {
      final params = CreateSaleParams(
        sale: validSale,
        userRole: UserRole.viewer,
      );

      final result = await createSaleUseCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('Sales role or higher')),
        (_) => fail('Should fail for viewer role'),
      );
    });

    test('fails when user role is FieldOperator (permission denied)', () async {
      final params = CreateSaleParams(
        sale: validSale,
        userRole: UserRole.fieldOperator,
      );

      final result = await createSaleUseCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Sales role or higher'));
        },
        (_) => fail('Should fail for field operator role'),
      );
    });

    test('succeeds when user role is FarmManager or Admin', () async {
      final paramsManager = CreateSaleParams(
        sale: validSale,
        userRole: UserRole.farmManager,
      );
      final paramsAdmin = CreateSaleParams(
        sale: validSale,
        userRole: UserRole.admin,
      );

      final resultManager = await createSaleUseCase(paramsManager);
      final resultAdmin = await createSaleUseCase(paramsAdmin);

      expect(resultManager.isRight(), true);
      expect(resultAdmin.isRight(), true);
    });

    test('fails when buyerName is empty', () async {
      final invalidSale = validSale.copyWith(buyerName: '');
      final params = CreateSaleParams(
        sale: invalidSale,
        userRole: UserRole.sales,
      );

      final result = await createSaleUseCase(params);

      expect(result.isLeft(), true);
    });

    test('fails when quantity is zero or negative', () async {
      final invalidSale = validSale.copyWith(quantity: 0.0);
      final params = CreateSaleParams(
        sale: invalidSale,
        userRole: UserRole.sales,
      );

      final result = await createSaleUseCase(params);

      expect(result.isLeft(), true);
    });

    test('fails when unitPrice is zero or negative', () async {
      final invalidSale = validSale.copyWith(unitPrice: -5.0);
      final params = CreateSaleParams(
        sale: invalidSale,
        userRole: UserRole.sales,
      );

      final result = await createSaleUseCase(params);

      expect(result.isLeft(), true);
    });

    test('fails when sale quantity exceeds available harvested inventory', () async {
      mockRepo.getInventoryResult = const Right(15.0); // Only 15kg available, sale demands 20kg
      final params = CreateSaleParams(
        sale: validSale,
        userRole: UserRole.sales,
      );

      final result = await createSaleUseCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('exceeds available harvested inventory'));
        },
        (_) => fail('Should fail due to inventory constraint'),
      );
    });
  });

  group('GetSalesHistoryUseCase', () {
    test('succeeds with valid parameters', () async {
      final params = GetSalesHistoryParams(farmId: 'FARM-01');
      final result = await getSalesHistoryUseCase(params);

      expect(result.isRight(), true);
    });

    test('fails when startDate is after endDate', () async {
      final params = GetSalesHistoryParams(
        startDate: DateTime.now(),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final result = await getSalesHistoryUseCase(params);

      expect(result.isLeft(), true);
    });
  });

  group('GetSalesSummaryUseCase', () {
    test('succeeds with valid parameters', () async {
      final now = DateTime.now();
      final params = GetSalesSummaryParams(
        farmId: 'FARM-01',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
      );

      final result = await getSalesSummaryUseCase(params);

      expect(result.isRight(), true);
      expect(mockRepo.lastSummaryFarmId, 'FARM-01');
    });

    test('fails when startDate is after endDate', () async {
      final params = GetSalesSummaryParams(
        startDate: DateTime.now(),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final result = await getSalesSummaryUseCase(params);

      expect(result.isLeft(), true);
    });
  });
}
