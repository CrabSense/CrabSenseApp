import 'package:crabsensemobile/core/database/database.dart';
import 'package:crabsensemobile/shared/services/sync_queue_item.dart';
import 'package:crabsensemobile/shared/services/sync_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  late AppDatabase db;
  late Logger logger;
  late SyncService syncService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    logger = Logger(printer: PrettyPrinter(enabled: false));
    syncService = SyncServiceImpl(database: db, logger: logger);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncService & SyncQueueItem', () {
    test('enqueue creates a queue item with correct entity type, payload, and default priority', () async {
      final item = await syncService.enqueue(
        entityType: SyncEntityType.harvest,
        operationType: 'create_harvest',
        entityId: 'harvest-001',
        payload: {'boxId': 'box-101', 'weight': 15.5},
      );

      expect(item.id, isNotEmpty);
      expect(item.entityType, SyncEntityType.harvest);
      expect(item.operationType, 'create_harvest');
      expect(item.entityId, 'harvest-001');
      expect(item.payload['weight'], 15.5);
      expect(item.priority, SyncPriority.medium);
      expect(item.status, SyncItemStatus.pending);
      expect(item.retryCount, 0);

      final count = await syncService.getPendingCount();
      expect(count, 1);
    });

    test('enqueue supports all required entity types', () async {
      final types = [
        SyncEntityType.harvest,
        SyncEntityType.sale,
        SyncEntityType.operationLog,
        SyncEntityType.inspection,
        SyncEntityType.video,
        SyncEntityType.alertAck,
      ];

      for (var i = 0; i < types.length; i++) {
        await syncService.enqueue(
          entityType: types[i],
          operationType: 'op_${types[i].code}',
          entityId: 'entity-$i',
          payload: {'index': i},
        );
      }

      final pending = await syncService.getPendingItems();
      expect(pending.length, types.length);
      final enqueuedTypes = pending.map((e) => e.entityType).toSet();
      expect(enqueuedTypes.length, types.length);
    });

    test('getPendingItems orders by priority ASC (1 critical -> 4 low) and createdAt ASC', () async {
      // Enqueue items out of priority order
      await syncService.enqueue(
        entityType: SyncEntityType.operationLog,
        operationType: 'log',
        entityId: 'id-low',
        payload: {},
        priority: SyncPriority.low, // 4
      );

      await syncService.enqueue(
        entityType: SyncEntityType.alertAck,
        operationType: 'ack',
        entityId: 'id-critical',
        payload: {},
        priority: SyncPriority.critical, // 1
      );

      await syncService.enqueue(
        entityType: SyncEntityType.harvest,
        operationType: 'harvest',
        entityId: 'id-high',
        payload: {},
        priority: SyncPriority.high, // 2
      );

      await syncService.enqueue(
        entityType: SyncEntityType.inspection,
        operationType: 'inspect',
        entityId: 'id-medium',
        payload: {},
        priority: SyncPriority.medium, // 3
      );

      final items = await syncService.getPendingItems();
      expect(items.length, 4);
      expect(items[0].entityId, 'id-critical');
      expect(items[0].priority, SyncPriority.critical);

      expect(items[1].entityId, 'id-high');
      expect(items[1].priority, SyncPriority.high);

      expect(items[2].entityId, 'id-medium');
      expect(items[2].priority, SyncPriority.medium);

      expect(items[3].entityId, 'id-low');
      expect(items[3].priority, SyncPriority.low);
    });

    test('markProcessing updates item status to processing and updates lastAttemptAt', () async {
      final item = await syncService.enqueue(
        entityType: SyncEntityType.sale,
        operationType: 'create_sale',
        entityId: 'sale-001',
        payload: {'total': 100},
      );

      await syncService.markProcessing(item.id);

      final rows = await (db.select(db.syncQueue)..where((t) => t.id.equals(item.id))).get();
      expect(rows.first.status, 'processing');
      expect(rows.first.lastAttemptAt, isNotNull);
    });

    test('markCompleted deletes item from queue', () async {
      final item = await syncService.enqueue(
        entityType: SyncEntityType.video,
        operationType: 'upload_video',
        entityId: 'vid-001',
        payload: {},
      );

      expect(await syncService.getPendingCount(), 1);

      await syncService.markCompleted(item.id);

      expect(await syncService.getPendingCount(), 0);
    });

    test('markFailed increments retryCount, records errorMessage, and sets status to failed', () async {
      final item = await syncService.enqueue(
        entityType: SyncEntityType.inspection,
        operationType: 'submit_inspection',
        entityId: 'inspect-001',
        payload: {},
      );

      await syncService.markFailed(item.id, 'Network timeout connecting to server');

      final pending = await syncService.getPendingItems();
      expect(pending.length, 1);
      final failedItem = pending.first;
      expect(failedItem.status, SyncItemStatus.failed);
      expect(failedItem.retryCount, 1);
      expect(failedItem.errorMessage, 'Network timeout connecting to server');
      expect(failedItem.lastAttemptAt, isNotNull);

      // Repeat failure
      await syncService.markFailed(item.id, '500 Internal Server Error');
      final secondPending = await syncService.getPendingItems();
      expect(secondPending.first.retryCount, 2);
      expect(secondPending.first.errorMessage, '500 Internal Server Error');
    });

    test('remove deletes single item from queue', () async {
      final item1 = await syncService.enqueue(
        entityType: SyncEntityType.harvest,
        operationType: 'op1',
        entityId: 'h1',
        payload: {},
      );
      final item2 = await syncService.enqueue(
        entityType: SyncEntityType.harvest,
        operationType: 'op2',
        entityId: 'h2',
        payload: {},
      );

      expect(await syncService.getPendingCount(), 2);

      await syncService.remove(item1.id);

      final items = await syncService.getPendingItems();
      expect(items.length, 1);
      expect(items.first.id, item2.id);
    });

    test('clearQueue removes all queue items', () async {
      await syncService.enqueue(
        entityType: SyncEntityType.harvest,
        operationType: 'op1',
        entityId: 'h1',
        payload: {},
      );
      await syncService.enqueue(
        entityType: SyncEntityType.sale,
        operationType: 'op2',
        entityId: 's1',
        payload: {},
      );

      expect(await syncService.getPendingCount(), 2);

      await syncService.clearQueue();

      expect(await syncService.getPendingCount(), 0);
    });

    test('watchPendingCount emits reactive updates when items are added and completed', () async {
      expectLater(
        syncService.watchPendingCount(),
        emitsInOrder([0, 1, 2, 1]),
      );

      final item1 = await syncService.enqueue(
        entityType: SyncEntityType.harvest,
        operationType: 'op1',
        entityId: 'h1',
        payload: {},
      );
      await syncService.enqueue(
        entityType: SyncEntityType.sale,
        operationType: 'op2',
        entityId: 's1',
        payload: {},
      );
      await syncService.markCompleted(item1.id);
    });
  });
}
