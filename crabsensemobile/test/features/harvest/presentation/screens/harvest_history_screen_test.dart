import 'package:crabsensemobile/core/di/injection.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest_summary.dart';
import 'package:crabsensemobile/features/harvest/domain/repositories/harvest_repository.dart';
import 'package:crabsensemobile/features/harvest/domain/usecases/get_harvest_history_usecase.dart';
import 'package:crabsensemobile/features/harvest/domain/usecases/get_harvest_summary_usecase.dart';
import 'package:crabsensemobile/features/harvest/presentation/bloc/bloc.dart';
import 'package:crabsensemobile/features/harvest/presentation/screens/harvest_history_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockHarvestRepository implements HarvestRepository {
  List<Harvest> historyResult = [];
  HarvestSummary? summaryResult;
  Failure? failureToReturn;

  @override
  Future<Either<Failure, List<Harvest>>> getHarvestHistory({
    String? farmId,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
    int page = 1,
    int pageSize = 50,
  }) async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(historyResult);
  }

  @override
  Future<Either<Failure, HarvestSummary>> getHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(
      summaryResult ??
          HarvestSummary(
            farmId: farmId,
            startDate: startDate,
            endDate: endDate,
            totalWeight: 25.0,
            totalCrabCount: 15,
            totalHarvestsCount: 2,
          ),
    );
  }

  @override
  Future<Either<Failure, Harvest>> recordHarvest(Harvest harvest) async => throw UnimplementedError();

  @override
  Future<Either<Failure, Harvest?>> getHarvestById(String id) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<Harvest>>> getPendingSyncHarvests() async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> syncHarvest(Harvest harvest) async => throw UnimplementedError();
}

void main() {
  late _MockHarvestRepository mockRepository;

  setUp(() async {
    await sl.reset();
    mockRepository = _MockHarvestRepository();

    sl.registerLazySingleton(() => GetHarvestHistoryUseCase(mockRepository));
    sl.registerLazySingleton(() => GetHarvestSummaryUseCase(mockRepository));
    sl.registerFactory(
      () => HarvestHistoryBloc(
        getHarvestHistory: sl(),
        getHarvestSummary: sl(),
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  final testHarvests = [
    Harvest(
      id: 'h-101',
      boxId: 'BOX-101',
      farmId: 'FARM-01',
      totalWeight: 12.5,
      crabCount: 8,
      qualityGrade: QualityGrade.gradeA,
      harvestDate: DateTime(2026, 7, 20, 9, 0),
      operatorId: 'op-1',
      operatorName: 'John Doe',
      createdAt: DateTime(2026, 7, 20, 9, 0),
    ),
  ];

  testWidgets('renders HarvestHistoryScreen with title, summary card, and history item', (tester) async {
    mockRepository.historyResult = testHarvests;

    await tester.pumpWidget(
      const MaterialApp(
        home: HarvestHistoryScreen(initialFarmId: 'FARM-01'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Harvest History & Analytics'), findsOneWidget);
    expect(find.text('Summary Statistics'), findsOneWidget);
    expect(find.text('Box BOX-101'), findsOneWidget);
    expect(find.text('12.50 kg'), findsOneWidget);
    expect(find.text('Grade A'), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
  });

  testWidgets('renders empty state when no harvest records returned', (tester) async {
    mockRepository.historyResult = [];

    await tester.pumpWidget(
      const MaterialApp(
        home: HarvestHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No Harvest Records Found'), findsOneWidget);
    expect(find.text('Try adjusting your date range or filters.'), findsOneWidget);
  });

  testWidgets('renders error view on failure and retries on button press', (tester) async {
    mockRepository.failureToReturn = const ServerFailure('Failed to fetch harvest history');

    await tester.pumpWidget(
      const MaterialApp(
        home: HarvestHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Failed to fetch harvest history'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    mockRepository.failureToReturn = null;
    mockRepository.historyResult = testHarvests;

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Box BOX-101'), findsOneWidget);
  });
}
