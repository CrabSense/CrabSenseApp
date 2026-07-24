import 'package:bloc_test/bloc_test.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/operation_logs/domain/entities/operation_log.dart';
import 'package:crabsensemobile/features/operation_logs/domain/entities/operation_type.dart';
import 'package:crabsensemobile/features/operation_logs/domain/repositories/operation_repository.dart';
import 'package:crabsensemobile/features/operation_logs/domain/usecases/create_operation_log_usecase.dart';
import 'package:crabsensemobile/features/operation_logs/domain/usecases/update_operation_log_usecase.dart';
import 'package:crabsensemobile/features/operation_logs/presentation/bloc/operation_bloc.dart';
import 'package:crabsensemobile/features/operation_logs/presentation/bloc/operation_event.dart';
import 'package:crabsensemobile/features/operation_logs/presentation/bloc/operation_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockOperationRepository implements OperationRepository {
  Either<Failure, OperationLog>? createResult;
  Either<Failure, OperationLog>? updateResult;

  @override
  Future<Either<Failure, OperationLog>> createOperationLog(OperationLog log) async {
    return createResult ?? Right(log);
  }

  @override
  Future<Either<Failure, OperationLog>> updateOperationLog(OperationLog log) async {
    return updateResult ?? Right(log);
  }

  @override
  Future<Either<Failure, OperationLog>> getOperationById(String id) async {
    return Left(ServerFailure.notFound(id));
  }

  @override
  Future<Either<Failure, List<OperationLog>>> getOperationHistory({
    required String boxId,
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
    int page = 1,
    int pageSize = 50,
  }) async {
    return const Right([]);
  }
}

void main() {
  late MockOperationRepository mockRepo;
  late CreateOperationLogUseCase createUseCase;
  late UpdateOperationLogUseCase updateUseCase;

  setUp(() {
    mockRepo = MockOperationRepository();
    createUseCase = CreateOperationLogUseCase(mockRepo);
    updateUseCase = UpdateOperationLogUseCase(mockRepo);
  });

  OperationBloc buildBloc() => OperationBloc(
        createOperationLog: createUseCase,
        updateOperationLog: updateUseCase,
      );

  group('OperationBloc', () {
    test('initial state is OperationInitial', () {
      expect(buildBloc().state, isA<OperationInitial>());
    });

    blocTest<OperationBloc, OperationState>(
      'emits OperationFormState on LoadOperationForm for create mode',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadOperationForm()),
      expect: () => [
        isA<OperationFormState>().having((s) => s.isEditMode, 'isEditMode', false),
      ],
    );

    blocTest<OperationBloc, OperationState>(
      'emits OperationError on LoadOperationForm when edit window (24h) has expired',
      build: buildBloc,
      act: (bloc) {
        final expiredLog = OperationLog(
          id: 'op-old',
          type: OperationType.feeding,
          boxIds: const ['BOX-001'],
          notes: '',
          photoUrls: const [],
          timestamp: DateTime.now().subtract(const Duration(hours: 25)),
          operatorId: 'user-1',
          operatorName: 'User 1',
        );
        bloc.add(LoadOperationForm(existingLog: expiredLog));
      },
      expect: () => [
        isA<OperationError>().having(
          (e) => e.message,
          'message',
          contains('24-hour window has expired'),
        ),
      ],
    );

    blocTest<OperationBloc, OperationState>(
      'submits successfully when online and valid',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const LoadOperationForm());
        bloc.add(const OperationBoxIdsChanged(rawInput: 'BOX-101'));
        bloc.add(const SubmitOperationLog(
          operatorId: 'op-1',
          operatorName: 'Operator One',
          userRole: UserRole.fieldOperator,
        ));
      },
      expect: () => [
        isA<OperationFormState>(),
        isA<OperationFormState>().having((s) => s.rawBoxInput, 'rawBoxInput', 'BOX-101'),
        isA<OperationFormState>().having((s) => s.isSubmitting, 'isSubmitting', true),
        isA<OperationFormState>().having((s) => s.isSubmitted, 'isSubmitted', true),
      ],
    );

    blocTest<OperationBloc, OperationState>(
      'handles offline submission by setting isOffline: true',
      build: buildBloc,
      setUp: () {
        mockRepo.createResult = const Left(NetworkFailure());
      },
      act: (bloc) {
        bloc.add(const LoadOperationForm());
        bloc.add(const OperationBoxIdsChanged(rawInput: 'BOX-102'));
        bloc.add(const SubmitOperationLog(
          operatorId: 'op-1',
          operatorName: 'Operator One',
          userRole: UserRole.fieldOperator,
        ));
      },
      expect: () => [
        isA<OperationFormState>(),
        isA<OperationFormState>().having((s) => s.rawBoxInput, 'rawBoxInput', 'BOX-102'),
        isA<OperationFormState>().having((s) => s.isSubmitting, 'isSubmitting', true),
        isA<OperationFormState>()
            .having((s) => s.isSubmitted, 'isSubmitted', true)
            .having((s) => s.isOffline, 'isOffline', true),
      ],
    );

    blocTest<OperationBloc, OperationState>(
      'fails submission when user role is unauthorized (Viewer)',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const LoadOperationForm());
        bloc.add(const OperationBoxIdsChanged(rawInput: 'BOX-103'));
        bloc.add(const SubmitOperationLog(
          operatorId: 'op-1',
          operatorName: 'Operator One',
          userRole: UserRole.viewer,
        ));
      },
      expect: () => [
        isA<OperationFormState>(),
        isA<OperationFormState>().having((s) => s.rawBoxInput, 'rawBoxInput', 'BOX-103'),
        isA<OperationFormState>().having((s) => s.isSubmitting, 'isSubmitting', true),
        isA<OperationFormState>().having(
          (s) => s.submissionError,
          'submissionError',
          contains('Field Operator role or higher'),
        ),
      ],
    );
  });
}
