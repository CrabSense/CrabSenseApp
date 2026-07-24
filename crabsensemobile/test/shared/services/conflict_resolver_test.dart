import 'package:crabsensemobile/shared/services/conflict_resolver.dart';
import 'package:crabsensemobile/shared/services/sync_conflict.dart';
import 'package:crabsensemobile/shared/services/sync_queue_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  late Logger logger;
  late ConflictResolverServiceImpl conflictResolver;

  setUp(() {
    logger = Logger(printer: PrettyPrinter(enabled: false));
    conflictResolver = ConflictResolverServiceImpl(logger: logger);
  });

  tearDown(() {
    conflictResolver.dispose();
  });

  group('Timestamp Comparison & Last-Write-Wins (Requirement 13.9)', () {
    test('Server timestamp > local timestamp (diff > 1s) -> server wins', () {
      final localTime = DateTime(2026, 7, 22, 10, 0, 0);
      final serverTime = DateTime(2026, 7, 22, 10, 0, 5); // 5s newer

      final winner = conflictResolver.evaluateTimestamps(
        localTimestamp: localTime,
        serverTimestamp: serverTime,
      );

      expect(winner, ConflictWinner.server);
    });

    test('Local timestamp > server timestamp (diff > 1s) -> local wins', () {
      final localTime = DateTime(2026, 7, 22, 10, 0, 10); // 10s newer
      final serverTime = DateTime(2026, 7, 22, 10, 0, 0);

      final winner = conflictResolver.evaluateTimestamps(
        localTimestamp: localTime,
        serverTimestamp: serverTime,
      );

      expect(winner, ConflictWinner.local);
    });

    test('Simultaneous edits (identical or diff <= 1s) -> manual prompt', () {
      final localTime = DateTime(2026, 7, 22, 10, 0, 0);
      final serverTime = DateTime(2026, 7, 22, 10, 0, 0); // Identical

      final winner1 = conflictResolver.evaluateTimestamps(
        localTimestamp: localTime,
        serverTimestamp: serverTime,
      );
      expect(winner1, ConflictWinner.manualPrompt);

      final nearServerTime = DateTime(2026, 7, 22, 10, 0, 0, 500); // 500ms diff
      final winner2 = conflictResolver.evaluateTimestamps(
        localTimestamp: localTime,
        serverTimestamp: nearServerTime,
      );
      expect(winner2, ConflictWinner.manualPrompt);
    });
  });

  group('Conflict Preservation & Registration', () {
    test('processIncomingEntityChange registers conflict on simultaneous edit', () async {
      final time = DateTime(2026, 7, 22, 12, 0, 0);
      final localPayload = {'weight': 15.5, 'grade': 'A'};
      final serverPayload = {'weight': 18.0, 'grade': 'A+'};

      final conflict = await conflictResolver.processIncomingEntityChange(
        entityType: SyncEntityType.harvest,
        entityId: 'h-100',
        localVersion: localPayload,
        localTimestamp: time,
        serverVersion: serverPayload,
        serverTimestamp: time,
      );

      expect(conflict, isNotNull);
      expect(conflict!.entityType, SyncEntityType.harvest);
      expect(conflict.entityId, 'h-100');
      expect(conflict.hasConflict, isTrue);
      expect(conflict.status, ConflictStatus.pending);
      expect(conflict.localVersion, localPayload);
      expect(conflict.serverVersion, serverPayload);

      final pendingList = await conflictResolver.getPendingConflicts();
      expect(pendingList.length, 1);
      expect(pendingList.first.id, conflict.id);
    });

    test('processIncomingEntityChange returns null when server or local wins automatically', () async {
      final localTime = DateTime(2026, 7, 22, 12, 0, 0);
      final serverTime = DateTime(2026, 7, 22, 12, 0, 10);

      final conflict = await conflictResolver.processIncomingEntityChange(
        entityType: SyncEntityType.sale,
        entityId: 's-200',
        localVersion: const {'amount': 100},
        localTimestamp: localTime,
        serverVersion: const {'amount': 200},
        serverTimestamp: serverTime,
      );

      expect(conflict, isNull);
      final pendingList = await conflictResolver.getPendingConflicts();
      expect(pendingList, isEmpty);
    });
  });

  group('Manual Conflict Resolution', () {
    late SyncConflict initialConflict;

    setUp(() async {
      final time = DateTime(2026, 7, 22, 12, 0, 0);
      initialConflict = await conflictResolver.registerConflict(
        entityType: SyncEntityType.harvest,
        entityId: 'h-300',
        localVersion: const {'operator': 'Operator A'},
        localTimestamp: time,
        serverVersion: const {'operator': 'Operator B'},
        serverTimestamp: time,
      );
    });

    test('Resolving with server version updates status and hasConflict flag', () async {
      final resolved = await conflictResolver.resolveConflict(
        initialConflict.id,
        ConflictResolutionChoice.useServer,
      );

      expect(resolved.hasConflict, isFalse);
      expect(resolved.status, ConflictStatus.resolvedServer);
      expect(resolved.resolvedVersion, const {'operator': 'Operator B'});
      expect(resolved.resolvedAt, isNotNull);

      final pendingList = await conflictResolver.getPendingConflicts();
      expect(pendingList, isEmpty);
    });

    test('Resolving with local version updates status and hasConflict flag', () async {
      final resolved = await conflictResolver.resolveConflict(
        initialConflict.id,
        ConflictResolutionChoice.useLocal,
      );

      expect(resolved.hasConflict, isFalse);
      expect(resolved.status, ConflictStatus.resolvedLocal);
      expect(resolved.resolvedVersion, const {'operator': 'Operator A'});
    });

    test('Resolving with custom merge payload updates status and hasConflict flag', () async {
      final mergedPayload = {'operator': 'Operator A & B Merged'};

      final resolved = await conflictResolver.resolveConflict(
        initialConflict.id,
        ConflictResolutionChoice.customMerge,
        customPayload: mergedPayload,
      );

      expect(resolved.hasConflict, isFalse);
      expect(resolved.status, ConflictStatus.resolvedMerged);
      expect(resolved.resolvedVersion, mergedPayload);
    });
  });
}
