import 'package:bloc_test/bloc_test.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest_summary.dart';
import 'package:crabsensemobile/features/harvest/domain/repositories/harvest_repository.dart';
import 'package:crabsensemobile/features/harvest/domain/usecases/get_harvest_history_usecase.dart';
import 'package:crabsensemobile/features/harvest/domain/usecases/get_harvest_summary_usecase.dart';
import 'package:crabsensemobile/features/harvest/presentation/bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHarvestRepository implements HarvestRepository {
  List<Harvest> historyResult = [];
  HarvestSummary? summaryResult;
  Failure? failureToReturn;

  GetHarvestHistoryParams? lastHistoryParams;
  GetHarvestSummaryParams? lastSummaryParams;

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
    lastHistoryParams = GetHarvestHistoryParams(
      farmId: farmId,
      boxId: boxId,
      startDate: startDate,
      endDate: endDate,
      qualityGrade: qualityGrade,
      page: page,
      pageSize: pageSize,
    );
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(historyResult);
  }

  @override
  Future<Either<Failure, HarvestSummary>> getHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    lastSummaryParams = GetHarvestSummaryParams(
      farmId: farmId,
      startDate: startDate,
      endDate: endDate,
    );
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(
      summaryResult ??
          HarvestSummary(
            farmId: farmId,
            startDate: startDate,
            endDate: endDate,
            totalWeight: 23.5,
            totalCrabCount: 15,
            totalHarvestsCount: 2,
          ),
    );
  }

  @override
  Future<Either<Failure, Harvest>> recordHarvest(Harvest harvest) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Harvest?>> getHarvestById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Harvest>>> getPendingSyncHarvests() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> syncHarvest(Harvest harvest) async {
    throw UnimplementedError();
  }
}

void main() {
  late MockHarvestRepository mockRepository;
  late GetHarvestHistoryUseCase getHarvestHistory;
  late GetHarvestSummaryUseCase getHarvestSummary;
  late HarvestHistoryBloc harvestHistoryBloc;

  final testHarvests = [
    Harvest(
      id: 'h-1',
      boxId: 'BOX-01',
      farmId: 'FARM-01',
      totalWeight: 10.0,
      crabCount: 6,
      qualityGrade: QualityGrade.gradeA,
      harvestDate: DateTime(2026, 7, 15, 10, 0),
      operatorId: 'op-1',
      operatorName: 'Op One',
      createdAt: DateTime(2026, 7, 15, 10, 0),
    ),
    Harvest(
      id: 'h-2',
      boxId: 'BOX-02',
      farmId: 'FARM-01',
      totalWeight: 13.5,
      crabCount: 9,
      qualityGrade: QualityGrade.gradeB,
      harvestDate: DateTime(2026, 7, 16, 11, 0),
      operatorId: 'op-1',
      operatorName: 'Op One',
      createdAt: DateTime(2026, 7, 16, 11, 0),
    ),
  ];

  setUp(() {
    mockRepository = MockHarvestRepository();
    getHarvestHistory = GetHarvestHistoryUseCase(mockRepository);
    getHarvestSummary = GetHarvestSummaryUseCase(mockRepository);
    harvestHistoryBloc = HarvestHistoryBloc(
      getHarvestHistory: getHarvestHistory,
      getHarvestSummary: getHarvestSummary,
    );
  });

  tearDown(() {
    harvestHistoryBloc.close();
  });

  test('initial state is HarvestHistoryInitial', () {
    expect(harvestHistoryBloc.state, equals(const HarvestHistoryInitial()));
  });

  group('LoadHarvestHistory', () {
    blocTest<HarvestHistoryBloc, HarvestHistoryState>(
      'emits [HarvestHistoryLoading, HarvestHistoryLoaded] with weekly cumulative weights when data loaded successfully',
      build: () {
        mockRepository.historyResult = testHarvests;
        return harvestHistoryBloc;
      },
      act: (bloc) => bloc.add(const LoadHarvestHistory(farmId: 'FARM-01')),
      expect: () => [
        const HarvestHistoryLoading(),
        isA<HarvestHistoryLoaded>()
            .having((s) => s.harvests.length, 'harvests length', 2)
            .having((s) => s.weeklyCumulativeWeights.isNotEmpty, 'weeklyCumulativeWeights', true)
            .having((s) => s.summary?.totalWeight, 'totalWeight', 23.5),
      ],
    );

    blocTest<HarvestHistoryBloc, HarvestHistoryState>(
      'emits [HarvestHistoryLoading, HarvestHistoryError] when repository fails',
      build: () {
        mockRepository.failureToReturn = const ServerFailure('Database connection error');
        return harvestHistoryBloc;
      },
      act: (bloc) => bloc.add(const LoadHarvestHistory()),
      expect: () => [
        const HarvestHistoryLoading(),
        const HarvestHistoryError(message: 'Database connection error'),
      ],
    );
  });

  group('Filter Events', () {
    blocTest<HarvestHistoryBloc, HarvestHistoryState>(
      'FilterDateRangeChanged updates date filter and reloads data',
      build: () {
        mockRepository.historyResult = testHarvests;
        return harvestHistoryBloc;
      },
      act: (bloc) => bloc.add(
        FilterDateRangeChanged(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 20),
        ),
      ),
      expect: () => [
        const HarvestHistoryLoading(),
        isA<HarvestHistoryLoaded>()
            .having((s) => s.startDate, 'startDate', DateTime(2026, 7, 1))
            .having((s) => s.endDate, 'endDate', DateTime(2026, 7, 20)),
      ],
    );

    blocTest<HarvestHistoryBloc, HarvestHistoryState>(
      'FilterQualityGradeChanged updates grade filter and reloads data',
      build: () {
        mockRepository.historyResult = testHarvests;
        return harvestHistoryBloc;
      },
      act: (bloc) => bloc.add(
        const FilterQualityGradeChanged(qualityGrade: QualityGrade.gradeA),
      ),
      expect: () => [
        const HarvestHistoryLoading(),
        isA<HarvestHistoryLoaded>()
            .having((s) => s.qualityGrade, 'qualityGrade', QualityGrade.gradeA),
      ],
    );
  });
}
