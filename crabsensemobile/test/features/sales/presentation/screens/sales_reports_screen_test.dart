import 'package:crabsensemobile/core/di/injection.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sale.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sales_summary.dart';
import 'package:crabsensemobile/features/sales/presentation/bloc/sales_history_bloc.dart';
import 'package:crabsensemobile/features/sales/presentation/bloc/sales_history_event.dart';
import 'package:crabsensemobile/features/sales/presentation/bloc/sales_history_state.dart';
import 'package:crabsensemobile/features/sales/presentation/screens/sales_reports_screen.dart';
import 'package:crabsensemobile/features/sales/presentation/widgets/sales_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSalesHistoryBloc extends Bloc<SalesHistoryEvent, SalesHistoryState>
    implements SalesHistoryBloc {
  FakeSalesHistoryBloc(SalesHistoryState initialState) : super(initialState) {
    on<LoadSalesHistory>((event, emit) {});
    on<FilterSalesDateRangeChanged>((event, emit) {});
    on<FilterSalesPaymentMethodChanged>((event, emit) {});
    on<ExportSalesToCsv>((event, emit) {});
  }
}

void main() {
  final sampleSale = Sale(
    id: 'SALE-101',
    buyerName: 'Global Crab Exporters',
    buyerContact: '09011122233',
    quantity: 100.0,
    unitPrice: 25.0,
    totalAmount: 2500.0,
    paymentMethod: PaymentMethod.cash,
    paymentStatus: PaymentStatus.completed,
    saleDate: DateTime(2026, 7, 21, 9, 0),
    operatorId: 'OP-01',
    operatorName: 'Operator Bob',
  );

  final sampleSummary = SalesSummary(
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 21),
    totalSalesCount: 1,
    totalQuantity: 100.0,
    totalRevenue: 2500.0,
    paymentMethodBreakdown: const {PaymentMethod.cash: 2500.0},
  );

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('SalesReportsScreen renders loading indicator when loading', (tester) async {
    final fakeBloc = FakeSalesHistoryBloc(const SalesHistoryLoading());
    sl.registerFactory<SalesHistoryBloc>(() => fakeBloc);

    await tester.pumpWidget(
      const MaterialApp(
        home: SalesReportsScreen(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sales Summary & Reports'), findsOneWidget);
  });

  testWidgets('SalesReportsScreen renders summary card and sales list when loaded', (tester) async {
    final loadedState = SalesHistoryLoaded(
      sales: [sampleSale],
      summary: sampleSummary,
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 21),
    );

    final fakeBloc = FakeSalesHistoryBloc(loadedState);
    sl.registerFactory<SalesHistoryBloc>(() => fakeBloc);

    await tester.pumpWidget(
      const MaterialApp(
        home: SalesReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sales Summary & Reports'), findsOneWidget);
    expect(find.byType(SalesSummaryCard), findsOneWidget);
    expect(find.text('Global Crab Exporters'), findsOneWidget);
    expect(find.text('Filter Date Range'), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
  });
}
