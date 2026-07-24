import 'package:bloc_test/bloc_test.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sale.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sales_summary.dart';
import 'package:crabsensemobile/features/sales/domain/repositories/sales_repository.dart';
import 'package:crabsensemobile/features/sales/domain/usecases/create_sale_usecase.dart';
import 'package:crabsensemobile/features/sales/presentation/bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSalesRepository implements SalesRepository {
  Either<Failure, Sale>? createSaleResult;
  Either<Failure, double>? availableInventoryResult;

  @override
  Future<Either<Failure, Sale>> createSale(Sale sale) async {
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
    return const Right([]);
  }

  @override
  Future<Either<Failure, SalesSummary>> getSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? farmId,
  }) async {
    return Right(
      SalesSummary(
        farmId: farmId ?? 'default',
        startDate: startDate,
        endDate: endDate,
        totalRevenue: 500.0,
        totalQuantitySold: 25.0,
        totalTransactionsCount: 1,
      ),
    );
  }

  @override
  Future<Either<Failure, Sale>> getSaleById(String id) async {
    return Left(ServerFailure.notFound(id));
  }

  @override
  Future<Either<Failure, double>> getAvailableHarvestedInventory({
    String? farmId,
  }) async {
    return availableInventoryResult ?? const Right(100.0);
  }
}

void main() {
  late MockSalesRepository mockRepo;
  late CreateSaleUseCase createSaleUseCase;

  setUp(() {
    mockRepo = MockSalesRepository();
    createSaleUseCase = CreateSaleUseCase(mockRepo);
  });

  SalesBloc buildBloc() => SalesBloc(createSale: createSaleUseCase);

  group('SalesBloc', () {
    test('initial state is SalesInitial', () {
      expect(buildBloc().state, equals(const SalesInitial()));
    });

    blocTest<SalesBloc, SalesState>(
      'emits SalesFormState initialized on LoadSalesForm',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadSalesForm(farmId: 'farm-101')),
      expect: () => [
        isA<SalesFormState>()
            .having((s) => s.farmId, 'farmId', 'farm-101')
            .having((s) => s.buyerName, 'buyerName', '')
            .having((s) => s.paymentMethod, 'paymentMethod', PaymentMethod.cash),
      ],
    );

    blocTest<SalesBloc, SalesState>(
      'updates buyer name and clears error on SalesBuyerNameChanged',
      build: buildBloc,
      seed: () => const SalesFormState(
        buyerName: '',
        buyerContact: '',
        quantityText: '',
        unitPriceText: '',
        paymentMethod: PaymentMethod.cash,
        saleDate: null ?? DateTime.parse('2026-07-22'),
        buyerNameError: 'Buyer name is required',
      ),
      act: (bloc) => bloc.add(const SalesBuyerNameChanged(buyerName: 'Acme Seafood')),
      expect: () => [
        isA<SalesFormState>()
            .having((s) => s.buyerName, 'buyerName', 'Acme Seafood')
            .having((s) => s.buyerNameError, 'buyerNameError', isNull),
      ],
    );

    blocTest<SalesBloc, SalesState>(
      'auto-calculates total amount from quantity and unit price',
      build: buildBloc,
      seed: () => SalesFormState(
        buyerName: 'Acme Seafood',
        buyerContact: '',
        quantityText: '10',
        unitPriceText: '15',
        paymentMethod: PaymentMethod.cash,
        saleDate: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const SalesUnitPriceChanged(unitPriceText: '20')),
      expect: () => [
        isA<SalesFormState>()
            .having((s) => s.unitPriceText, 'unitPriceText', '20')
            .having((s) => s.totalAmount, 'totalAmount', 200.0),
      ],
    );

    blocTest<SalesBloc, SalesState>(
      'emits validation errors when submitting empty buyer name or invalid quantity/price',
      build: buildBloc,
      seed: () => SalesFormState(
        buyerName: '',
        buyerContact: '',
        quantityText: '0',
        unitPriceText: '-5',
        paymentMethod: PaymentMethod.cash,
        saleDate: DateTime.now(),
      ),
      act: (bloc) => bloc.add(
        const SubmitSale(
          operatorId: 'op-1',
          operatorName: 'John',
          userRole: UserRole.fieldOperator,
        ),
      ),
      expect: () => [
        isA<SalesFormState>()
            .having((s) => s.buyerNameError, 'buyerNameError', 'Buyer name is required')
            .having((s) => s.quantityError, 'quantityError', 'Quantity must be a positive number')
            .having((s) => s.unitPriceError, 'unitPriceError', 'Unit price must be a positive number'),
      ],
    );

    blocTest<SalesBloc, SalesState>(
      'emits isSubmitting then isSubmitted when valid sale submitted successfully',
      build: buildBloc,
      seed: () => SalesFormState(
        buyerName: 'Global Catch Co.',
        buyerContact: '0912345678',
        quantityText: '15.5',
        unitPriceText: '20.0',
        paymentMethod: PaymentMethod.bankTransfer,
        saleDate: DateTime.now(),
      ),
      act: (bloc) => bloc.add(
        const SubmitSale(
          operatorId: 'op-123',
          operatorName: 'Test Operator',
          userRole: UserRole.sales,
        ),
      ),
      expect: () => [
        isA<SalesFormState>().having((s) => s.isSubmitting, 'isSubmitting', true),
        isA<SalesFormState>()
            .having((s) => s.isSubmitting, 'isSubmitting', false)
            .having((s) => s.isSubmitted, 'isSubmitted', true)
            .having((s) => s.createdSale?.buyerName, 'buyerName', 'Global Catch Co.')
            .having((s) => s.createdSale?.totalAmount, 'totalAmount', 310.0),
      ],
    );

    blocTest<SalesBloc, SalesState>(
      'emits offline state when submission fails due to NetworkFailure',
      build: buildBloc,
      setUp: () {
        mockRepo.createSaleResult = const Left(NetworkFailure('No connection'));
      },
      seed: () => SalesFormState(
        buyerName: 'Global Catch Co.',
        buyerContact: '',
        quantityText: '10',
        unitPriceText: '15',
        paymentMethod: PaymentMethod.cash,
        saleDate: DateTime.now(),
      ),
      act: (bloc) => bloc.add(
        const SubmitSale(
          operatorId: 'op-123',
          operatorName: 'Test Operator',
          userRole: UserRole.sales,
        ),
      ),
      expect: () => [
        isA<SalesFormState>().having((s) => s.isSubmitting, 'isSubmitting', true),
        isA<SalesFormState>()
            .having((s) => s.isSubmitting, 'isSubmitting', false)
            .having((s) => s.isSubmitted, 'isSubmitted', true)
            .having((s) => s.isOffline, 'isOffline', true),
      ],
    );
  });
}
