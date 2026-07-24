import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/operation_logs/domain/entities/operation_log.dart';
import 'package:crabsensemobile/features/operation_logs/domain/entities/operation_type.dart';
import 'package:crabsensemobile/features/operation_logs/domain/repositories/operation_repository.dart';
import 'package:crabsensemobile/features/operation_logs/domain/usecases/create_operation_log_usecase.dart';
import 'package:crabsensemobile/features/operation_logs/domain/usecases/update_operation_log_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockOperationRepository implements OperationRepository {
  Either<Failure, OperationLog>? createResult;
  Either<Failure, OperationLog>? updateResult;
  OperationLog? lastCreatedLog;
  OperationLog? lastUpdatedLog;

  @override
  Future<Either<Failure, OperationLog>> createOperationLog(OperationLog log) async {
    lastCreatedLog = log;
    return createResult ?? Right(log);
  }

  @override
  Future<Either<Failure, OperationLog>> updateOperationLog(OperationLog log) async {
    lastUpdatedLog = log;
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

  @override
  Future<Either<Failure, List<OperationLog>>> getAllOperationLogs({
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

  final validLog = OperationLog(
    id: 'op-123',
    type: OperationType.feeding,
    boxIds: const ['BOX-001'],
    notes: 'Feeding time',
    photoUrls: const [],
    timestamp: DateTime.now(),
    operatorId: 'op-user-1',
    operatorName: 'John Operator',
    quantity: 2.5,
    unit: 'kg',
  );

  setUp(() {
    mockRepo = MockOperationRepository();
    createUseCase = CreateOperationLogUseCase(mockRepo);
    updateUseCase = UpdateOperationLogUseCase(mockRepo);
  });

  group('CreateOperationLogUseCase', () {
    test('succeeds when log is valid and user has FieldOperator role', () async {
      final params = CreateOperationLogParams(
        log: validLog,
        userRole: UserRole.fieldOperator,
      );

      final result = await createUseCase(params);

      expect(result.isRight(), true);
      expect(mockRepo.lastCreatedLog?.id, 'op-123');
    });

    test('fails when boxIds is empty', () async {
      final invalidLog = validLog.copyWith(boxIds: []);
      final params = CreateOperationLogParams(
        log: invalidLog,
        userRole: UserRole.fieldOperator,
      );

      final result = await createUseCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should not succeed'),
      );
    });

    test('fails when timestamp is in future', () async {
      final futureLog = validLog.copyWith(
        timestamp: DateTime.now().add(const Duration(days: 1)),
      );
      final params = CreateOperationLogParams(
        log: futureLog,
        userRole: UserRole.fieldOperator,
      );

      final result = await createUseCase(params);

      expect(result.isLeft(), true);
    });

    test('fails when userRole is Viewer (unauthorized)', () async {
      final params = CreateOperationLogParams(
        log: validLog,
        userRole: UserRole.viewer,
      );

      final result = await createUseCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Field Operator role or higher'));
        },
        (_) => fail('Should fail due to permission'),
      );
    });
  });

  group('UpdateOperationLogUseCase', () {
    test('succeeds when editing within 24 hours with valid role', () async {
      final params = UpdateOperationLogParams(
        log: validLog,
        userRole: UserRole.farmManager,
      );

      final result = await updateUseCase(params);

      expect(result.isRight(), true);
      expect(mockRepo.lastUpdatedLog?.id, 'op-123');
    });

    test('fails when 24-hour editing window has expired', () async {
      final expiredLog = validLog.copyWith(
        timestamp: DateTime.now().subtract(const Duration(hours: 25)),
      );
      final params = UpdateOperationLogParams(
        log: expiredLog,
        userRole: UserRole.admin,
      );

      final result = await updateUseCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('24 hours'));
        },
        (_) => fail('Should fail due to 24h window expiration'),
      );
    });

    test('fails when user role is Sales (unauthorized)', () async {
      final params = UpdateOperationLogParams(
        log: validLog,
        userRole: UserRole.sales,
      );

      final result = await updateUseCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('Field Operator role or higher')),
        (_) => fail('Should fail due to permissions'),
      );
    });
  });
}
