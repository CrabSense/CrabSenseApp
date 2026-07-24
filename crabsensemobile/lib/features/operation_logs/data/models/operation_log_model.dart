// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart' as db;
import '../../domain/entities/operation_log.dart';
import '../../domain/entities/operation_type.dart';

/// Data Transfer Object (DTO) for the [OperationLog] entity.
///
/// Handles JSON serialization/deserialization for API responses and
/// Drift row mapping for local database operations. Extends [OperationLog]
/// so it can be used directly wherever a domain entity is expected.
///
/// Additional data-layer fields [isDirty] and [syncedAt] are included
/// for offline-first sync tracking (Requirements 10.6-10.7).
///
/// Requirements: 10.1-10.10
class OperationLogModel extends OperationLog {
  const OperationLogModel({
    required super.id,
    required super.type,
    required super.boxIds,
    required super.notes,
    required super.photoUrls,
    required super.timestamp,
    required super.operatorId,
    required super.operatorName,
    super.quantity,
    super.unit,
    this.isDirty = false,
    this.syncedAt,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates an [OperationLogModel] from a raw API JSON map.
  ///
  /// Accepts both camelCase and snake_case field names for compatibility
  /// with different API response shapes.
  factory OperationLogModel.fromJson(Map<String, dynamic> json) => OperationLogModel(
    id: json['id'] as String,
    type: _parseOperationType(json['type'] as String? ?? ''),
    boxIds: _parseStringList(json['boxIds'] ?? json['box_ids']),
    quantity: (json['quantity'] as num?)?.toDouble(),
    unit: json['unit'] as String?,
    notes: json['notes'] as String? ?? '',
    photoUrls: _parseStringList(json['photoUrls'] ?? json['photo_urls']),
    timestamp: _parseDateTime(json['timestamp'] as String? ?? json['created_at'] as String?),
    operatorId: json['operatorId'] as String? ?? json['operator_id'] as String? ?? '',
    operatorName: json['operatorName'] as String? ?? json['operator_name'] as String? ?? '',
    isDirty: json['isDirty'] as bool? ?? json['is_dirty'] as bool? ?? false,
    syncedAt: _parseDateTimeNullable(json['syncedAt'] as String? ?? json['synced_at'] as String?),
  );

  /// Creates an [OperationLogModel] from a Drift-generated [db.OperationLog] row.
  factory OperationLogModel.fromDrift(db.OperationLog row) => OperationLogModel(
    id: row.id,
    type: _parseOperationType(row.type),
    boxIds: _parseStringListFromJson(row.boxIds),
    quantity: row.quantity,
    unit: row.unit,
    notes: row.notes,
    photoUrls: _parseStringListFromJson(row.photoUrls),
    timestamp: row.timestamp,
    operatorId: row.operatorId,
    operatorName: row.operatorName,
    isDirty: row.isDirty,
    syncedAt: row.syncedAt,
  );

  /// Creates an [OperationLogModel] from a domain [OperationLog] entity.
  factory OperationLogModel.fromEntity(
    OperationLog entity, {
    bool isDirty = false,
    DateTime? syncedAt,
  }) => OperationLogModel(
    id: entity.id,
    type: entity.type,
    boxIds: entity.boxIds,
    quantity: entity.quantity,
    unit: entity.unit,
    notes: entity.notes,
    photoUrls: entity.photoUrls,
    timestamp: entity.timestamp,
    operatorId: entity.operatorId,
    operatorName: entity.operatorName,
    isDirty: isDirty,
    syncedAt: syncedAt,
  );

  /// True when the record has been modified locally but not yet synced
  /// to the remote API (Requirement 10.6-10.7).
  final bool isDirty;

  /// Timestamp when this record was last successfully synced with the server.
  /// Null if never synced.
  final DateTime? syncedAt;

  // ──────────────────────────────────────────────────────────────────────────
  // Serialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'boxIds': boxIds,
    'quantity': quantity,
    'unit': unit,
    'notes': notes,
    'photoUrls': photoUrls,
    'timestamp': timestamp.toIso8601String(),
    'operatorId': operatorId,
    'operatorName': operatorName,
  };

  /// Converts this model to a [db.OperationLogsCompanion] for Drift
  /// inserts and updates.
  db.OperationLogsCompanion toDriftCompanion() => db.OperationLogsCompanion(
    id: Value(id),
    type: Value(type.name),
    boxIds: Value(jsonEncode(boxIds)),
    quantity: Value(quantity),
    unit: Value(unit),
    notes: Value(notes),
    photoUrls: Value(jsonEncode(photoUrls)),
    timestamp: Value(timestamp),
    operatorId: Value(operatorId),
    operatorName: Value(operatorName),
    isDirty: Value(isDirty),
    syncedAt: Value(syncedAt),
    cachedAt: Value(DateTime.now()),
  );

  /// Converts this model to the pure domain [OperationLog] entity.
  OperationLog toEntity() => OperationLog(
    id: id,
    type: type,
    boxIds: boxIds,
    quantity: quantity,
    unit: unit,
    notes: notes,
    photoUrls: photoUrls,
    timestamp: timestamp,
    operatorId: operatorId,
    operatorName: operatorName,
  );

  @override
  OperationLogModel copyWith({
    String? id,
    OperationType? type,
    List<String>? boxIds,
    double? quantity,
    String? unit,
    String? notes,
    List<String>? photoUrls,
    DateTime? timestamp,
    String? operatorId,
    String? operatorName,
    bool? isDirty,
    DateTime? syncedAt,
  }) => OperationLogModel(
    id: id ?? this.id,
    type: type ?? this.type,
    boxIds: boxIds ?? this.boxIds,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    notes: notes ?? this.notes,
    photoUrls: photoUrls ?? this.photoUrls,
    timestamp: timestamp ?? this.timestamp,
    operatorId: operatorId ?? this.operatorId,
    operatorName: operatorName ?? this.operatorName,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt ?? this.syncedAt,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Parses an [OperationType] from a string, falling back to [OperationType.feeding].
  static OperationType _parseOperationType(String value) {
    switch (value) {
      case 'feeding':
        return OperationType.feeding;
      case 'waterChange':
        return OperationType.waterChange;
      case 'mineralAddition':
        return OperationType.mineralAddition;
      case 'cleaning':
        return OperationType.cleaning;
      case 'medication':
        return OperationType.medication;
      case 'inspection':
        return OperationType.inspection;
      default:
        return OperationType.feeding;
    }
  }

  /// Parses a list of strings from either a [List<dynamic>] or a JSON string.
  static List<String> _parseStringList(Object? raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return _parseStringListFromJson(raw);
    }
    return [];
  }

  /// Decodes a JSON-encoded list of strings.
  static List<String> _parseStringListFromJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } on FormatException {
      return [];
    }
  }

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.parse(value);
  }

  static DateTime? _parseDateTimeNullable(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }
}
