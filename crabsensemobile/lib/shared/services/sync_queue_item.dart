import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:equatable/equatable.dart';
import '../../core/database/database.dart' as db;

/// Entity types supported by the offline sync queue.
///
/// Requirements: 13.3-13.4
enum SyncEntityType {
  box('box'),
  crab('crab'),
  feeding('feeding'),
  care('care'),
  transfer('transfer'),
  waterReading('water_reading'),
  task('task'),
  photo('photo'),
  harvest('harvest'),
  sale('sale'),
  operationLog('operation_log'),
  inspection('inspection'),
  video('video'),
  alertAck('alert_ack');

  const SyncEntityType(this.code);

  final String code;

  /// Returns [SyncEntityType] from a string code, default to [operationLog] if unknown.
  static SyncEntityType fromCode(String code) {
    return SyncEntityType.values.firstWhere(
      (e) => e.code == code || e.name == code,
      orElse: () => SyncEntityType.operationLog,
    );
  }
}

/// Priority levels for offline queue items.
///
/// Priority 1 (critical) is processed first, down to Priority 4 (low).
/// Order: `critical (1)`, `high (2)`, `medium (3)`, `low (4)`.
///
/// Requirements: 13.3-13.4
enum SyncPriority {
  critical(1),
  high(2),
  medium(3),
  low(4);

  const SyncPriority(this.value);

  final int value;

  static SyncPriority fromValue(int value) {
    return SyncPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => SyncPriority.medium,
    );
  }
}

/// Status of a queue item during its lifecycle.
enum SyncItemStatus {
  pending('pending'),
  processing('processing'),
  failed('failed'),
  completed('completed');

  const SyncItemStatus(this.code);

  final String code;

  static SyncItemStatus fromCode(String code) {
    return SyncItemStatus.values.firstWhere(
      (s) => s.code == code || s.name == code,
      orElse: () => SyncItemStatus.pending,
    );
  }
}

/// Representation of an entry in the local SyncQueue database table.
class SyncQueueItem extends Equatable {
  const SyncQueueItem({
    required this.id,
    required this.operationType,
    required this.entityId,
    required this.entityType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = SyncItemStatus.pending,
    this.priority = SyncPriority.medium,
    this.lastAttemptAt,
    this.errorMessage,
  });

  final String id;
  final String operationType;
  final String entityId;
  final SyncEntityType entityType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final SyncItemStatus status;
  final SyncPriority priority;
  final DateTime? lastAttemptAt;
  final String? errorMessage;

  /// Creates a [SyncQueueItem] from a Drift [db.SyncQueueData] record.
  factory SyncQueueItem.fromDrift(db.SyncQueueData driftData) {
    Map<String, dynamic> decodedPayload;
    try {
      decodedPayload = jsonDecode(driftData.payload) as Map<String, dynamic>;
    } catch (_) {
      decodedPayload = <String, dynamic>{};
    }

    return SyncQueueItem(
      id: driftData.id,
      operationType: driftData.operationType,
      entityId: driftData.entityId,
      entityType: SyncEntityType.fromCode(driftData.entityType),
      payload: decodedPayload,
      createdAt: driftData.createdAt,
      retryCount: driftData.retryCount,
      status: SyncItemStatus.fromCode(driftData.status),
      priority: SyncPriority.fromValue(driftData.priority),
      lastAttemptAt: driftData.lastAttemptAt,
      errorMessage: driftData.errorMessage,
    );
  }

  /// Converts this model to a Drift companion for DB insertion / update.
  db.SyncQueueCompanion toDriftCompanion() {
    return db.SyncQueueCompanion.insert(
      id: id,
      operationType: operationType,
      entityId: entityId,
      entityType: entityType.code,
      payload: jsonEncode(payload),
      createdAt: createdAt,
      retryCount: Value(retryCount),
      status: Value(status.code),
      priority: Value(priority.value),
      lastAttemptAt: Value(lastAttemptAt),
      errorMessage: Value(errorMessage),
    );
  }

  /// Copies this item with updated attributes.
  SyncQueueItem copyWith({
    String? id,
    String? operationType,
    String? entityId,
    SyncEntityType? entityType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    SyncItemStatus? status,
    SyncPriority? priority,
    DateTime? lastAttemptAt,
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    operationType,
    entityId,
    entityType,
    payload,
    createdAt,
    retryCount,
    status,
    priority,
    lastAttemptAt,
    errorMessage,
  ];
}
