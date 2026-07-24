import 'package:crabsensemobile/core/errors/exceptions.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/core/network/network_info.dart';
import 'package:crabsensemobile/features/sales/data/datasources/sales_local_data_source.dart';
import 'package:crabsensemobile/features/sales/data/datasources/sales_remote_data_source.dart';
import 'package:crabsensemobile/features/sales/data/models/sale_model.dart';
import 'package:crabsensemobile/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sale.dart';
import 'package:crabsensemobile/features/sales/domain/entities/sales_summary.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class MockSalesRemoteDataSource implements SalesRemoteDataSource {
  SaleModel? createSaleResult;
  List<SaleModel>? historyResult;
  SalesSummaryModel? summaryResult;
  SaleModel? byIdResult;
  double? inventoryResult;

  Exception? createSaleException;
  Exception? historyException;
  Exception? summaryException;
  Exception? byIdException;
  Exception? inventoryException;

  SaleModel? lastCreatedModel;

  @override
  Future<SaleModel> createSale(SaleModel model) async {
    if (createSaleException != null) throw createSaleException!;
    lastCreatedModel = model;
    return createSaleResult ?? model;
  }

  @override
  Future<List<SaleModel>> getSalesHistory({
    String? farmId,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int page = 1,
    int limit = 50,
  }) async {
    if (historyException != null) throw historyException!;
    return historyResult ?? [];
  }

  @override
  Future<SalesSummaryModel> getSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? farmId,
  }) async {
    if (summaryException != null) throw summaryException!;
    return summaryResult ??
        SalesSummaryModel(
          farmId: farmId,
          startDate: startDate,
          endDate: endDate,
          totalSalesCount: 2,
          totalQuantity: 50.0,
          totalRevenue: 2000.0,
        );
  }

  @override
  Future<SaleModel> getSaleById(String id) async {
    if (byIdException != null) throw byIdException!;
    if (byIdResult != null) return byIdResult!;
    throw const ServerException(message: 'Not found', statusCode: 404);
  }

  @override
  Future<double> getAvailableHarvestedInventory({String? farmId}) async {
    if (inventoryException != null) throw inventoryException!;
    return inventoryResult ?? 100.0;
  }
}

class MockSalesLocalDataSource implements SalesLocalDataSource {
  SaleModel? createLocalResult;
  List<SaleModel>? cachedHistoryResult;
  SaleModel? cachedByIdResult;
  SalesSummaryModel? localSummaryResult;
  double? localInventoryResult;

  bool wasQueued = false;
  bool wasMarkedSynced = false;
  List<Sale>? lastCachedBatch;

  @override
  Future<SaleModel> createLocalSale(SaleModel model) async {
    return createLocalResult ?? model.copyWith(isDirty: true);
  }

  @override
  Future<List<SaleModel>> getCachedSalesHistory({
    String? farmId,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int page = 1,
    int pageSize = 50,
  }) async {
    return cachedHistoryResult ?? [];
  }

  @override
  Future<SaleModel?> getCachedSaleById(String id) async {
    return cachedByIdResult;
  }

  @override
  Future<void> cacheSales(List<Sale> sales) async {
    lastCachedBatch = sales;
  }

  @override
  Future<List<SaleModel>> getUnsyncedSales() async {
    return [];
  }

  @override
  Future<void> markAsSynced(String id) async {
    wasMarkedSynced = true;
  }

  @override
  Future<void> queueSaleAction({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    wasQueued = true;
  }

  @override
  Future<SalesSummaryModel> getLocalSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? farmId,
  }) async {
    return localSummaryResult ??
        SalesSummaryModel(
          farmId: farmId,
          startDate: startDate,
          endDate: endDate,
          totalSalesCount: 1,
          totalQuantity: 20.0,
          totalRevenue: 800.0,
        );
  }

  @override
  Future<double> getLocalAvailableHarvestedInventory({String? farmId}) async {
    return localInventoryResult ?? 80.0;
  }
}

class MockNetworkInfo implements NetworkInfo {
  bool isConnectedValue = true;

  @override
  Future<bool> get isConnected async => isConnectedValue;
}

void main() {
  late SalesRepositoryImpl repository;
  late MockSalesRemoteDataSource remoteDataSource;
  late MockSalesLocalDataSource localDataSource;
  late MockNetworkInfo networkInfo;

  final tDate = DateTime.parse('2026-07-21T10:00:00.000Z');

  final tSale = Sale(
    id: 'sale-001',
    buyerName: 'Global Foods',
    quantity: 20.0,
    unitPrice: 50.0,
    totalAmount: 1000.0,
    paymentMethod: PaymentMethod.cash,
    paymentStatus: PaymentStatus.completed,
    saleDate: tDate,
    farmId: 'FARM-01',
    operatorId: 'op-001',
    operatorName: 'John Doe',
  );

  setUp(() {
    remoteDataSource = MockSalesRemoteDataSource();
    localDataSource = MockSalesLocalDataSource();
    networkInfo = MockNetworkInfo();
    repository = SalesRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      networkInfo: networkInfo,
      logger: Logger(printer: SimplePrinter()),
    );
  });

  group('createSale', () {
    test('succeeds and marks synced when online', () async {
      networkInfo.isConnectedValue = true;

      final result = await repository.createSale(tSale);

      expect(result.isRight(), true);
      expect(localDataSource.wasMarkedSynced, true);
      expect(localDataSource.wasQueued, false);
    });

    test('persists locally and queues offline when offline', () async {
      networkInfo.isConnectedValue = false;

      final result = await repository.createSale(tSale);

      expect(result.isRight(), true);
      expect(localDataSource.wasQueued, true);
      expect(localDataSource.wasMarkedSynced, false);
    });

    test('fails validation when quantity <= 0', () async {
      final invalid = tSale.copyWith(quantity: 0.0);
      final result = await repository.createSale(invalid);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should fail'),
      );
    });
  });

  group('getSalesHistory', () {
    test('fetches from remote and caches locally when online', () async {
      networkInfo.isConnectedValue = true;
      final model = SaleModel.fromEntity(tSale);
      remoteDataSource.historyResult = [model];

      final result = await repository.getSalesHistory(farmId: 'FARM-01');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (list) {
          expect(list.length, 1);
          expect(list.first.id, 'sale-001');
        },
      );
      expect(localDataSource.lastCachedBatch?.length, 1);
    });

    test('falls back to local cache when offline', () async {
      networkInfo.isConnectedValue = false;
      final model = SaleModel.fromEntity(tSale);
      localDataSource.cachedHistoryResult = [model];

      final result = await repository.getSalesHistory(farmId: 'FARM-01');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (list) => expect(list.first.id, 'sale-001'),
      );
    });
  });

  group('getSalesSummary', () {
    test('fetches from remote when online', () async {
      networkInfo.isConnectedValue = true;

      final result = await repository.getSalesSummary(
        farmId: 'FARM-01',
        startDate: tDate.subtract(const Duration(days: 7)),
        endDate: tDate,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (summary) => expect(summary.totalSalesCount, 2),
      );
    });

    test('calculates locally when offline', () async {
      networkInfo.isConnectedValue = false;

      final result = await repository.getSalesSummary(
        farmId: 'FARM-01',
        startDate: tDate.subtract(const Duration(days: 7)),
        endDate: tDate,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (summary) => expect(summary.totalSalesCount, 1),
      );
    });
  });

  group('getAvailableHarvestedInventory', () {
    test('fetches from remote when online', () async {
      networkInfo.isConnectedValue = true;
      remoteDataSource.inventoryResult = 150.0;

      final result = await repository.getAvailableHarvestedInventory(farmId: 'FARM-01');

      expect(result, const Right(150.0));
    });

    test('falls back to local calculation when offline', () async {
      networkInfo.isConnectedValue = false;
      localDataSource.localInventoryResult = 75.0;

      final result = await repository.getAvailableHarvestedInventory(farmId: 'FARM-01');

      expect(result, const Right(75.0));
    });
  });
}
