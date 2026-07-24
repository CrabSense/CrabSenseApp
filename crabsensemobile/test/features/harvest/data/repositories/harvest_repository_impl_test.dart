import 'package:crabsensemobile/core/errors/exceptions.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/core/network/network_info.dart';
import 'package:crabsensemobile/features/harvest/data/datasources/harvest_local_data_source.dart';
import 'package:crabsensemobile/features/harvest/data/datasources/harvest_remote_data_source.dart';
import 'package:crabsensemobile/features/harvest/data/models/harvest_model.dart';
import 'package:crabsensemobile/features/harvest/data/repositories/harvest_repository_impl.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest.dart';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class MockHarvestRemoteDataSource implements HarvestRemoteDataSource {
  HarvestModel? recordHarvestResult;
  List<HarvestModel>? getHistoryResult;
  HarvestSummaryModel? getSummaryResult;
  HarvestModel? getByIdResult;

  ServerException? serverExceptionToThrow;
  NetworkException? networkExceptionToThrow;

  HarvestModel? lastRecordedModel;

  @override
  Future<HarvestModel> recordHarvest(HarvestModel model) async {
    lastRecordedModel = model;
    if (serverExceptionToThrow != null) throw serverExceptionToThrow!;
    if (networkExceptionToThrow != null) throw networkExceptionToThrow!;
    return recordHarvestResult ?? model;
  }

  @override
  Future<List<HarvestModel>> getHarvestHistory({
    String? farmId,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
    int page = 1,
    int limit = 50,
  }) async {
    if (serverExceptionToThrow != null) throw serverExceptionToThrow!;
    if (networkExceptionToThrow != null) throw networkExceptionToThrow!;
    return getHistoryResult ?? [];
  }

  @override
  Future<HarvestSummaryModel> getHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (serverExceptionToThrow != null) throw serverExceptionToThrow!;
    if (networkExceptionToThrow != null) throw networkExceptionToThrow!;
    return getSummaryResult ??
        HarvestSummaryModel(
          farmId: farmId,
          startDate: startDate,
          endDate: endDate,
          totalWeight: 100.0,
          totalCrabCount: 200,
          totalHarvestsCount: 10,
        );
  }

  @override
  Future<HarvestModel> getHarvestById(String id) async {
    if (serverExceptionToThrow != null) throw serverExceptionToThrow!;
    if (networkExceptionToThrow != null) throw networkExceptionToThrow!;
    if (getByIdResult != null) return getByIdResult!;
    throw const ServerException(message: 'Not found', statusCode: 404);
  }
}

class MockHarvestLocalDataSource implements HarvestLocalDataSource {
  List<HarvestModel> localHistory = [];
  HarvestModel? localById;
  HarvestSummaryModel? localSummary;

  HarvestModel? lastCreatedLocalHarvest;
  String? lastUpdatedBoxId;
  int? lastHarvestedCount;
  String? lastSyncedId;
  String? queuedOperationType;

  @override
  Future<HarvestModel> createLocalHarvest(HarvestModel model) async {
    lastCreatedLocalHarvest = model;
    localHistory.add(model);
    await updateBoxCrabCountAfterHarvest(
      boxId: model.boxId,
      harvestedCount: model.crabCount,
    );
    return model;
  }

  @override
  Future<void> updateBoxCrabCountAfterHarvest({
    required String boxId,
    required int harvestedCount,
  }) async {
    lastUpdatedBoxId = boxId;
    lastHarvestedCount = harvestedCount;
  }

  @override
  Future<void> markAsSynced(String id) async {
    lastSyncedId = id;
  }

  @override
  Future<void> queueHarvestAction({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    queuedOperationType = operationType;
  }

  @override
  Future<void> cacheHarvests(List<Harvest> harvests) async {
    localHistory = harvests.map((h) => HarvestModel.fromEntity(h)).toList();
  }

  @override
  Future<List<HarvestModel>> getCachedHarvestHistory({
    String? farmId,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
    int page = 1,
    int pageSize = 50,
  }) async {
    return localHistory;
  }

  @override
  Future<HarvestModel?> getCachedHarvestById(String id) async {
    return localById;
  }

  @override
  Future<HarvestSummaryModel> getLocalHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return localSummary ??
        HarvestSummaryModel(
          farmId: farmId,
          startDate: startDate,
          endDate: endDate,
          totalWeight: 50.0,
          totalCrabCount: 100,
          totalHarvestsCount: 5,
        );
  }

  @override
  Future<List<HarvestModel>> getUnsyncedHarvests() async {
    return localHistory.where((m) => m.isDirty).toList();
  }
}

class MockNetworkInfo implements NetworkInfo {
  bool isConnectedValue = true;

  @override
  Future<bool> get isConnected async => isConnectedValue;
}

void main() {
  late MockHarvestRemoteDataSource mockRemoteDataSource;
  late MockHarvestLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late Logger logger;
  late HarvestRepositoryImpl repository;

  final tHarvest = Harvest(
    id: 'harvest-001',
    boxId: 'BOX-101',
    farmId: 'FARM-01',
    totalWeight: 10.0,
    crabCount: 20,
    qualityGrade: QualityGrade.gradeA,
    harvestDate: DateTime.parse('2026-07-21T10:00:00Z'),
    operatorId: 'op-01',
    operatorName: 'Op Name',
  );

  setUp(() {
    mockRemoteDataSource = MockHarvestRemoteDataSource();
    mockLocalDataSource = MockHarvestLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    logger = Logger(printer: SimplePrinter());

    repository = HarvestRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      logger: logger,
    );
  });

  group('recordHarvest', () {
    test('returns Left(ValidationFailure) when weight is not positive', () async {
      final invalid = tHarvest.copyWith(totalWeight: 0.0);
      final result = await repository.recordHarvest(invalid);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('returns Left(ValidationFailure) when crabCount is not positive', () async {
      final invalid = tHarvest.copyWith(crabCount: 0);
      final result = await repository.recordHarvest(invalid);

      expect(result.isLeft(), true);
    });

    test('online: creates local record, updates box count, calls remote, and marks synced', () async {
      mockNetworkInfo.isConnectedValue = true;

      final result = await repository.recordHarvest(tHarvest);

      expect(result.isRight(), true);
      expect(mockLocalDataSource.lastCreatedLocalHarvest?.id, 'harvest-001');
      expect(mockLocalDataSource.lastUpdatedBoxId, 'BOX-101');
      expect(mockLocalDataSource.lastHarvestedCount, 20);
      expect(mockRemoteDataSource.lastRecordedModel?.id, 'harvest-001');
      expect(mockLocalDataSource.lastSyncedId, 'harvest-001');
    });

    test('offline: saves locally, updates box count, queues offline action', () async {
      mockNetworkInfo.isConnectedValue = false;

      final result = await repository.recordHarvest(tHarvest);

      expect(result.isRight(), true);
      expect(mockLocalDataSource.lastCreatedLocalHarvest?.id, 'harvest-001');
      expect(mockLocalDataSource.lastUpdatedBoxId, 'BOX-101');
      expect(mockLocalDataSource.queuedOperationType, 'record_harvest');
    });

    test('online: returns Left(ServerFailure) on remote server exception', () async {
      mockNetworkInfo.isConnectedValue = true;
      mockRemoteDataSource.serverExceptionToThrow = const ServerException(
        message: 'Server error',
        statusCode: 500,
      );

      final result = await repository.recordHarvest(tHarvest);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should fail'),
      );
    });
  });

  group('getHarvestHistory', () {
    test('online: fetches remote history and caches locally', () async {
      mockNetworkInfo.isConnectedValue = true;
      mockRemoteDataSource.getHistoryResult = [HarvestModel.fromEntity(tHarvest)];

      final result = await repository.getHarvestHistory(farmId: 'FARM-01');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (list) {
          expect(list.length, 1);
          expect(list.first.id, 'harvest-001');
        },
      );
      expect(mockLocalDataSource.localHistory.length, 1);
    });

    test('offline: serves from local cache', () async {
      mockNetworkInfo.isConnectedValue = false;
      mockLocalDataSource.localHistory = [HarvestModel.fromEntity(tHarvest)];

      final result = await repository.getHarvestHistory(farmId: 'FARM-01');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (list) => expect(list.length, 1),
      );
    });
  });

  group('getHarvestSummary', () {
    test('online: fetches remote summary', () async {
      mockNetworkInfo.isConnectedValue = true;
      final now = DateTime.now();

      final result = await repository.getHarvestSummary(
        farmId: 'FARM-01',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (summary) => expect(summary.totalWeight, 100.0),
      );
    });

    test('offline: calculates local summary', () async {
      mockNetworkInfo.isConnectedValue = false;
      final now = DateTime.now();

      final result = await repository.getHarvestSummary(
        farmId: 'FARM-01',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (summary) => expect(summary.totalWeight, 50.0),
      );
    });
  });

  group('getHarvestById', () {
    test('returns cached harvest when present', () async {
      mockLocalDataSource.localById = HarvestModel.fromEntity(tHarvest);

      final result = await repository.getHarvestById('harvest-001');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (harvest) => expect(harvest.id, 'harvest-001'),
      );
    });
  });
}
