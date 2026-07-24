import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sale.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sales_summary.dart';
import 'package:crabsensemobile/features/sales/domain/repositories/sales_repository.dart';
import 'package:crabsensemobile/features/sales/domain/usecases/get_sales_history_usecase.dart';
import 'package:crabsensemobile/features/sales/domain/usecases/get_sales_summary_usecase.dart';
import 'package:crabsensemobile/features/sales/presentation/bloc/sales_history_bloc.dart';
import 'package:crabsensemobile/features/sales/presentation/bloc/sales_history_event.dart';
import 'package:crabsensemobile/features/sales/presentation/bloc/sales_history_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSalesRepositoryForHistory implements SalesRepository {
  Either<Failure, List<Sale>>? historyResult;
  Either<Failure, SalesSummary>? summaryResult;

  @override
  Future<Either<Failure, Sale>> createSale(Sale sale) async {
    return Right(sale);
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
    return historyResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, SalesSummary>> getSalesSummary({
    String? farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return summaryResult ??
        Right(
          SalesSummary(
            startDate: startDate,
            endDate: endDate,
            totalSalesCount: 2,
            totalQuantity: 75.5,
            totalRevenue: 2392.5,
            paymentMethodBreakdown: const {
              PaymentMethod.cash: 1500.0,
              PaymentMethod.bankTransfer: 892.5,
            },
          ),
        );
  }

  @override
  Future<Either<Failure, Sale>> getSaleById(String id) async {
    return Left(ServerFailure.notFound(id));
  }

  @override
  Future<Either<Failure, double>> getAvailableHarvestedInventory({String? farmId}) async {
    return const Right(100.0);
  }
}

void main() {
  late MockSalesRepositoryForHistory mockRepo;
  late GetSalesHistoryUseCase getSalesHistoryUseCase;
  late GetSalesSummaryUseCase getSalesSummaryUseCase;
  late SalesHistoryBloc bloc;

  final sampleSales = [
    Sale(
      id: 'SALE-001',
      buyerName: 'Ocean Seafood Co.',
      quantity: 50.0,
      unitPrice: 30.0,
      totalAmount: 1500.0,
      paymentMethod: PaymentMethod.cash,
      paymentStatus: PaymentStatus.completed,
      saleDate: DateTime.now(),
      operatorId: 'OP-1',
      operatorName: 'John',
    ),
  ];

  setUp(() {
    mockRepo = MockSalesRepositoryForHistory();
    getSalesHistoryUseCase = GetSalesHistoryUseCase(mockRepo);
    getSalesSummaryUseCase = GetSalesSummaryUseCase(mockRepo);
    bloc = SalesHistoryBloc(
      getSalesHistory: getSalesHistoryUseCase,
      getSalesSummary: getSalesSummaryUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is SalesHistoryInitial', () {
    expect(bloc.state, isA<SalesHistoryInitial>());
  });

  group('LoadSalesHistory', () {
    test('emits [SalesHistoryLoading, SalesHistoryLoaded] on successful fetch', () async {
      mockRepo.historyResult = Right(sampleSales);

      final expectedStates = [
        isA<SalesHistoryLoading>(),
        isA<SalesHistoryLoaded>()
            .having((s) => s.sales.length, 'sales length', 1)
            .having((s) => s.summary?.totalRevenue, 'total revenue', 2392.5),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LoadSalesHistory());
    });

    test('emits [SalesHistoryLoading, SalesHistoryError] when repository fails', () async {
      mockRepo.historyResult = const Left(ServerFailure('Database connection error'));

      final expectedStates = [
        isA<SalesHistoryLoading>(),
        isA<SalesHistoryError>().having((s) => s.message, 'message', contains('Database connection error')),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LoadSalesHistory());
    });
  });

  group('Filters & Export', () {
    test('FilterSalesDateRangeChanged triggers reloading with updated range', () async {
      mockRepo.historyResult = Right(sampleSales);

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));

      bloc.add(FilterSalesDateRangeChanged(startDate: start, endDate: now));

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<SalesHistoryLoaded>().having((s) => s.startDate, 'startDate', start),
        ),
      );
    });

    test('FilterSalesPaymentMethodChanged triggers reloading with updated method', () async {
      mockRepo.historyResult = Right(sampleSales);

      bloc.add(const FilterSalesPaymentMethodChanged(paymentMethod: PaymentMethod.cash));

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<SalesHistoryLoaded>().having((s) => s.paymentMethod, 'paymentMethod', PaymentMethod.cash),
        ),
      );
    });
  });
}
