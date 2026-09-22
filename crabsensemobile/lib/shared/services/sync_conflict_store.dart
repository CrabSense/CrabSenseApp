import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import 'sync_queue_item.dart';

/// Persists server/local versions so a conflict is never silently discarded.
class SyncConflictStore {
  SyncConflictStore(this.database);

  final AppDatabase database;
  static const _uuid = Uuid();

  Future<void> save({
    required SyncQueueItem item,
    required Map<String, dynamic> serverVersion,
  }) {
    return database
        .into(database.syncConflicts)
        .insert(
          SyncConflictsCompanion.insert(
            id: _uuid.v4(),
            entityType: item.entityType.code,
            entityId: item.entityId,
            localPayload: jsonEncode(item.payload),
            serverPayload: jsonEncode(serverVersion),
            localVersion: Value(
              (item.payload['baseVersion'] as num?)?.toInt() ?? 0,
            ),
            serverVersion: Value(
              (serverVersion['version'] as num?)?.toInt() ?? 0,
            ),
            createdAt: DateTime.now(),
          ),
        );
  }
}
