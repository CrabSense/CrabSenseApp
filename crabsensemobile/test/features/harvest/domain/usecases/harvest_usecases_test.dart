import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest_summary.dart';
import 'package:crabsensemobile/features/harvest/domain/repositories/harvest_repository.dart';
import 'package:crabsensemobile/features/harvest/domain/usecases/get_harvest_history_usecase.dart';
import 'package:crabsensemobile/features/harvest/domain/usecases/get_harvest_summary_usecase.dart';
import 'package:crabsensemobile/features/harvest/domain/usecases/record_harvest_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHarvestRepository implements HarvestRepository {
  Either<Failure, Harvest>? recordHarvestResult;
  Either<Failure, List<Harvest>>? getHistoryResult;
  Either<Failure, HarvestSummary>? getSummaryResult;

  Harvest? lastRecordedHarvest;
  String? lastSummaryFarmId;

  @override
  Future<Either<Failure, Harvest>> recordHarvest(Harvest harvest) async {
    lastRecordedHarvest = harvest;
    return recordHarvestResult ?? Right(harvest);
  }

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
    return getHistoryResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, HarvestSummary>> getHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    lastSummaryFarmId = farmId;
    return getSummaryResult ??
        Right(HarvestSummary(
          farmId: farmId,
          startDate: startDate,
          endDate: endDate,
          totalWeight: 100.0,
          totalCrabCount: 200,
          totalHarvestsCount: 10,
        ));
  }

  @override
  Future<Either<Failure, Harvest>> getHarvestById(String id) async {
    return Left(ServerFailure.notFound(id));
  }
}

void main() {
  late MockHarvestRepository mockRepo;
  late RecordHarvestUseCase recordHarvestUseCase;
  late GetHarvestHistoryUseCase getHarvestHistoryUseCase;
  late GetHarvestSummaryUseCase getHarvestSummaryUseCase;

  final validHarvest = Harvest(
    id: 'harvest-001',
    boxId: 'BOX-101',
    farmId: 'FARM-01',
    totalWeight: 12.5,
    crabCount: 25,
    qualityGrade: QualityGrade.gradeA,
    harvestDate: DateTime.now(),
    operatorId: 'user-007',
    operatorName: 'John Operator',
    photoUrls: const ['https://example.com/photo1.jpg'],
    notes: 'Fresh harvest',
  );

  setUp(() {
    mockRepo = MockHarvestRepository();
    recordHarvestUseCase = RecordHarvestUseCase(mockRepo);
    getHarvestHistoryUseCase = GetHarvestHistoryUseCase(mockRepo);
    getHarvestSummaryUseCase = GetHarvestSummaryUseCase(mockRepo);
  });

  group('QualityGrade enum', () {
    test('displayName returns proper labels', () {
      expect(QualityGrade.gradeA.displayName, 'Grade A');
      expect(QualityGrade.gradeB.displayName, 'Grade B');
      expect(QualityGrade.gradeC.displayName, 'Grade C');
    });

    test('fromString parses valid string values correctly', () {
      expect(QualityGrade.fromString('GRADE_A'), QualityGrade.gradeA);
      expect(QualityGrade.fromString('grade b'), QualityGrade.gradeB);
      expect(QualityGrade.fromString('C'), QualityGrade.gradeC);
      expect(QualityGrade.fromString('UNKNOWN'), QualityGrade.gradeA);
    });

    test('toCode returns standardized uppercase codes', () {
      expect(QualityGrade.gradeA.toCode(), 'GRADE_A');
      expect(QualityGrade.gradeB.toCode(), 'GRADE_B');
      expect(QualityGrade.gradeC.toCode(), 'GRADE_C');
    });
  });

  group('Harvest Entity', () {
    test('calculates averageWeightPerCrab correctly', () {
      expect(validHarvest.averageWeightPerCrab, 0.5);
    });

    test('copyWith creates modified copy', () {
      final updated = validHarvest.copyWith(totalWeight: 15.0);
      expect(updated.totalWeight, 15.0);
      expect(updated.crabCount, 25);
      expect(updated.boxId, 'BOX-101');
    });
  });

  group('RecordHarvestUseCase', () {
    test('succeeds when harvest input is valid and user has FieldOperator role', () async {
      final params = RecordHarvestParams(
        harvest: validHarvest,
        userRole: UserRole.fieldOperator,
      );

      final result = await recordHarvestUseCase(params);

      expect(result.isRight(), true);
      expect(mockRepo.lastRecordedHarvest?.id, 'harvest-001');
    });

    test('fails when weight is zero or negative', () async {
      final invalidHarvest = validHarvest.copyWith(totalWeight: 0.0);
      final params = RecordHarvestParams(
        harvest: invalidHarvest,
        userRole: UserRole.fieldOperator,
      );

      final result = await recordHarvestUseCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should fail for zero weight'),
      );
    });

    test('fails when crab count is 0', () async {
      final invalidHarvest = validHarvest.copyWith(crabCount: 0);
      final params = RecordHarvestParams(
        harvest: invalidHarvest,
        userRole: UserRole.fieldOperator,
      );

      final result = await recordHarvestUseCase(params);

      expect(result.isLeft(), true);
    });

    test('fails when boxId is empty', () async {
      final invalidHarvest = validHarvest.copyWith(boxId: '');
      final params = RecordHarvestParams(
        harvest: invalidHarvest,
        userRole: UserRole.fieldOperator,
      );

      final result = await recordHarvestUseCase(params);

      expect(result.isLeft(), true);
    });

    test('fails when harvestDate is in the future', () async {
      final futureHarvest = validHarvest.copyWith(
        harvestDate: DateTime.now().add(const Duration(days: 1)),
      );
      final params = RecordHarvestParams(
        harvest: futureHarvest,
        userRole: UserRole.fieldOperator,
      );

      final result = await recordHarvestUseCase(params);

      expect(result.isLeft(), true);
    });

    test('fails when user role is Viewer (unauthorized)', () async {
      final params = RecordHarvestParams(
        harvest: validHarvest,
        userRole: UserRole.viewer,
      );

      final result = await recordHarvestUseCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('Field Operator role or higher')),
        (_) => fail('Should fail due to permission'),
      );
    });
  });

  group('GetHarvestHistoryUseCase', () {
    test('succeeds with valid parameters', () async {
      final params = GetHarvestHistoryParams(farmId: 'FARM-01');
      final result = await getHarvestHistoryUseCase(params);

      expect(result.isRight(), true);
    });

    test('fails when startDate is after endDate', () async {
      final params = GetHarvestHistoryParams(
        startDate: DateTime.now(),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final result = await getHarvestHistoryUseCase(params);

      expect(result.isLeft(), true);
    });
  });

  group('GetHarvestSummaryUseCase', () {
    test('succeeds and calculates summary per farm', () async {
      final now = DateTime.now();
      final params = GetHarvestSummaryParams(
        farmId: 'FARM-01',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
      );

      final result = await getHarvestSummaryUseCase(params);

      expect(result.isRight(), true);
      expect(mockRepo.lastSummaryFarmId, 'FARM-01');
      result.fold(
        (_) => fail('Should succeed'),
        (summary) {
          expect(summary.totalWeight, 100.0);
          expect(summary.totalCrabCount, 200);
        },
      );
    });

    test('fails when farmId is empty', () async {
      final params = GetHarvestSummaryParams(
        farmId: '',
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      final result = await getHarvestSummaryUseCase(params);

      expect(result.isLeft(), true);
    });
  });
}
