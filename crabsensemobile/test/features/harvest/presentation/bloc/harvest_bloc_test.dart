import 'package:bloc_test/bloc_test.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest_summary.dart';
import 'package:crabsensemobile/features/harvest/domain/repositories/harvest_repository.dart';
import 'package:crabsensemobile/features/harvest/domain/usecases/record_harvest_usecase.dart';
import 'package:crabsensemobile/features/harvest/presentation/bloc/harvest_bloc.dart';
import 'package:crabsensemobile/features/harvest/presentation/bloc/harvest_event.dart';
import 'package:crabsensemobile/features/harvest/presentation/bloc/harvest_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHarvestRepository implements HarvestRepository {
  Either<Failure, Harvest>? recordHarvestResult;

  @override
  Future<Either<Failure, Harvest>> recordHarvest(Harvest harvest) async {
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
    return const Right([]);
  }

  @override
  Future<Either<Failure, HarvestSummary>> getHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return Right(HarvestSummary(
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

  setUp(() {
    mockRepo = MockHarvestRepository();
    recordHarvestUseCase = RecordHarvestUseCase(mockRepo);
  });

  HarvestBloc buildBloc() => HarvestBloc(recordHarvest: recordHarvestUseCase);

  group('HarvestBloc', () {
    test('initial state is HarvestInitial', () {
      expect(buildBloc().state, equals(const HarvestInitial()));
    });

    blocTest<HarvestBloc, HarvestState>(
      'emits HarvestFormState on LoadHarvestForm with defaults',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadHarvestForm(boxId: 'BOX-101', farmId: 'FARM-01')),
      expect: () => [
        isA<HarvestFormState>()
            .having((s) => s.boxId, 'boxId', 'BOX-101')
            .having((s) => s.farmId, 'farmId', 'FARM-01')
            .having((s) => s.qualityGrade, 'qualityGrade', QualityGrade.gradeA),
      ],
    );

    blocTest<HarvestBloc, HarvestState>(
      'updates form state fields on change events',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const LoadHarvestForm());
        bloc.add(const HarvestBoxIdChanged(boxId: 'BOX-202'));
        bloc.add(const HarvestWeightChanged(weightText: '15.5'));
        bloc.add(const HarvestCrabCountChanged(crabCountText: '30'));
        bloc.add(const HarvestQualityGradeChanged(qualityGrade: QualityGrade.gradeB));
        bloc.add(const HarvestNotesChanged(notes: 'Good quality'));
      },
      expect: () => [
        isA<HarvestFormState>(),
        isA<HarvestFormState>().having((s) => s.boxId, 'boxId', 'BOX-202'),
        isA<HarvestFormState>().having((s) => s.totalWeightText, 'totalWeightText', '15.5'),
        isA<HarvestFormState>().having((s) => s.crabCountText, 'crabCountText', '30'),
        isA<HarvestFormState>().having((s) => s.qualityGrade, 'qualityGrade', QualityGrade.gradeB),
        isA<HarvestFormState>().having((s) => s.notes, 'notes', 'Good quality'),
      ],
    );

    blocTest<HarvestBloc, HarvestState>(
      'handles photo addition and removal',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const LoadHarvestForm());
        bloc.add(const AddHarvestPhoto(photoPath: '/tmp/photo1.jpg'));
        bloc.add(const RemoveHarvestPhoto(index: 0));
      },
      expect: () => [
        isA<HarvestFormState>(),
        isA<HarvestFormState>().having((s) => s.photoPaths, 'photoPaths', ['/tmp/photo1.jpg']),
        isA<HarvestFormState>().having((s) => s.photoPaths, 'photoPaths', isEmpty),
      ],
    );

    blocTest<HarvestBloc, HarvestState>(
      'fails submission validation when required fields are missing/invalid',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const LoadHarvestForm());
        bloc.add(const SubmitHarvest(operatorId: 'op-1', operatorName: 'Op 1'));
      },
      expect: () => [
        isA<HarvestFormState>(),
        isA<HarvestFormState>()
            .having((s) => s.boxIdError, 'boxIdError', isNotNull)
            .having((s) => s.weightError, 'weightError', isNotNull)
            .having((s) => s.crabCountError, 'crabCountError', isNotNull),
      ],
    );

    blocTest<HarvestBloc, HarvestState>(
      'submits successfully when form inputs are valid',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const LoadHarvestForm());
        bloc.add(const HarvestBoxIdChanged(boxId: 'BOX-101'));
        bloc.add(const HarvestFarmIdChanged(farmId: 'FARM-01'));
        bloc.add(const HarvestWeightChanged(weightText: '10.0'));
        bloc.add(const HarvestCrabCountChanged(crabCountText: '20'));
        bloc.add(const SubmitHarvest(
          operatorId: 'user-007',
          operatorName: 'John Operator',
          userRole: UserRole.fieldOperator,
        ));
      },
      expect: () => [
        isA<HarvestFormState>(),
        isA<HarvestFormState>().having((s) => s.boxId, 'boxId', 'BOX-101'),
        isA<HarvestFormState>().having((s) => s.farmId, 'farmId', 'FARM-01'),
        isA<HarvestFormState>().having((s) => s.totalWeightText, 'totalWeightText', '10.0'),
        isA<HarvestFormState>().having((s) => s.crabCountText, 'crabCountText', '20'),
        isA<HarvestFormState>().having((s) => s.isSubmitting, 'isSubmitting', true),
        isA<HarvestFormState>()
            .having((s) => s.isSubmitting, 'isSubmitting', false)
            .having((s) => s.isSubmitted, 'isSubmitted', true)
            .having((s) => s.createdHarvest, 'createdHarvest', isNotNull),
      ],
    );

    blocTest<HarvestBloc, HarvestState>(
      'handles offline submit via NetworkFailure',
      build: buildBloc,
      act: (bloc) {
        mockRepo.recordHarvestResult = const Left(NetworkFailure('Offline queue saved'));
        bloc.add(const LoadHarvestForm());
        bloc.add(const HarvestBoxIdChanged(boxId: 'BOX-101'));
        bloc.add(const HarvestWeightChanged(weightText: '10.0'));
        bloc.add(const HarvestCrabCountChanged(crabCountText: '20'));
        bloc.add(const SubmitHarvest(
          operatorId: 'user-007',
          operatorName: 'John Operator',
          userRole: UserRole.fieldOperator,
        ));
      },
      expect: () => [
        isA<HarvestFormState>(),
        isA<HarvestFormState>().having((s) => s.boxId, 'boxId', 'BOX-101'),
        isA<HarvestFormState>().having((s) => s.totalWeightText, 'totalWeightText', '10.0'),
        isA<HarvestFormState>().having((s) => s.crabCountText, 'crabCountText', '20'),
        isA<HarvestFormState>().having((s) => s.isSubmitting, 'isSubmitting', true),
        isA<HarvestFormState>()
            .having((s) => s.isSubmitting, 'isSubmitting', false)
            .having((s) => s.isSubmitted, 'isSubmitted', true)
            .having((s) => s.isOffline, 'isOffline', true),
      ],
    );
  });
}
