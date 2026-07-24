import 'package:crabsensemobile/core/di/injection.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sale.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sales_summary.dart';
import 'package:crabsensemobile/features/sales/domain/repositories/sales_repository.dart';
import 'package:crabsensemobile/features/sales/domain/usecases/create_sale_usecase.dart';
import 'package:crabsensemobile/features/sales/presentation/bloc/sales_bloc.dart';
import 'package:crabsensemobile/features/sales/presentation/screens/sales_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockSalesRepository implements SalesRepository {
  Either<Failure, Sale>? createSaleResult;
  Either<Failure, double>? availableInventoryResult;

  Sale? lastCreatedSale;

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
        farmId: farmId,
        startDate: startDate,
        endDate: endDate,
        totalSalesCount: 1,
        totalQuantity: 10.0,
        totalRevenue: 200.0,
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
  late _MockSalesRepository mockRepository;

  setUp(() async {
    await sl.reset();
    mockRepository = _MockSalesRepository();

    sl.registerLazySingleton(() => CreateSaleUseCase(mockRepository));
    sl.registerFactory(() => SalesBloc(createSale: sl()));
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('renders SalesScreen with form fields and submit button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesScreen(userRole: UserRole.sales),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Record Quick Sale'), findsNWidgets(2)); // AppBar title + button text
    expect(find.text('Buyer Information'), findsOneWidget);
    expect(find.text('Product Details & Pricing'), findsOneWidget);
    expect(find.text('Payment & Schedule'), findsOneWidget);
    expect(find.text('Notes & Comments'), findsOneWidget);
  });

  testWidgets('displays permission warning banner and disables button when user role is Viewer or FieldOperator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesScreen(userRole: UserRole.fieldOperator),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Sales management permissions required'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('allows inputting buyer name, quantity, unit price and updates total amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SalesScreen(userRole: UserRole.sales),
      ),
    );

    await tester.pumpAndSettle();

    // Enter buyer name
    await tester.enterText(find.widgetWithText(TextFormField, 'Buyer Name *'), 'Fresh Market Co.');

    // Enter quantity
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity (kg) *'), '25');

    // Enter unit price
    await tester.enterText(find.widgetWithText(TextFormField, 'Unit Price (\$) *'), '10');

    await tester.pumpAndSettle();

    // Total should display $250.00
    expect(find.text('\$250.00'), findsOneWidget);
  });
}
