// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart' as db;
import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_enums.dart';

/// Data Transfer Object (DTO) for the [Alert] entity.
///
/// Handles JSON serialization/deserialization for API responses and
/// Drift row mapping for local database operations. Extends the domain
/// entity so it can be used directly as an [Alert] wherever needed.
///
/// Requirements: 9.1-9.10
class AlertModel extends Alert {
  const AlertModel({
    required super.id,
    required super.type,
    required super.severity,
    required super.title,
    required super.message,
    required super.recommendedActions,
    required super.createdAt,
    required super.status,
    super.sourceId,
    super.sourceType,
    super.acknowledgedAt,
    super.acknowledgedBy,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates an [AlertModel] from a raw API JSON map.
  ///
  /// Accepts both camelCase and snake_case field names for compatibility
  /// with different API response shapes.
  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    id: json['id'] as String,
    type: _parseAlertType(json['type'] as String? ?? ''),
    severity: _parseAlertSeverity(json['severity'] as String? ?? ''),
    title: json['title'] as String? ?? '',
    message: json['message'] as String? ?? '',
    sourceId: json['sourceId'] as String? ?? json['source_id'] as String?,
    sourceType: json['sourceType'] as String? ?? json['source_type'] as String?,
    recommendedActions: _parseActions(
      json['recommendedActions'] ?? json['recommended_actions'],
    ),
    createdAt: _parseDateTime(
      json['createdAt'] as String? ?? json['created_at'] as String?,
    ),
    acknowledgedAt: _parseDateTimeNullable(
      json['acknowledgedAt'] as String? ?? json['acknowledged_at'] as String?,
    ),
    acknowledgedBy:
        json['acknowledgedBy'] as String? ?? json['acknowledged_by'] as String?,
    status: _parseAlertStatus(json['status'] as String? ?? 'unread'),
  );

  /// Creates an [AlertModel] from a Drift-generated [db.Alert] row.
  ///
  /// [db.Alert] is the Drift DataClass generated from the Alerts table
  /// in [db.AppDatabase]. It is aliased via the `db` prefix to avoid
  /// collision with the domain entity Alert.
  factory AlertModel.fromDrift(db.Alert row) => AlertModel(
    id: row.id,
    type: _parseAlertType(row.type),
    severity: _parseAlertSeverity(row.severity),
    title: row.title,
    message: row.message,
    sourceId: row.sourceId,
    sourceType: row.sourceType,
    recommendedActions: _parseActionsFromJson(row.recommendedActions),
    createdAt: row.createdAt,
    acknowledgedAt: row.acknowledgedAt,
    acknowledgedBy: row.acknowledgedBy,
    status: _parseAlertStatus(row.status),
  );

  /// Creates an [AlertModel] from a domain [Alert] entity.
  factory AlertModel.fromEntity(Alert entity) => AlertModel(
    id: entity.id,
    type: entity.type,
    severity: entity.severity,
    title: entity.title,
    message: entity.message,
    sourceId: entity.sourceId,
    sourceType: entity.sourceType,
    recommendedActions: entity.recommendedActions,
    createdAt: entity.createdAt,
    acknowledgedAt: entity.acknowledgedAt,
    acknowledgedBy: entity.acknowledgedBy,
    status: entity.status,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Serialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'title': title,
    'message': message,
    'sourceId': sourceId,
    'sourceType': sourceType,
    'recommendedActions': recommendedActions,
    'createdAt': createdAt.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'acknowledgedBy': acknowledgedBy,
    'status': status.name,
  };

  /// Converts this model to a [db.AlertsCompanion] for Drift inserts/updates.
  db.AlertsCompanion toDriftCompanion({bool isDirty = false}) =>
      db.AlertsCompanion(
        id: Value(id),
        type: Value(type.name),
        severity: Value(severity.name),
        title: Value(title),
        message: Value(message),
        sourceId: Value(sourceId),
        sourceType: Value(sourceType),
        recommendedActions: Value(jsonEncode(recommendedActions)),
        createdAt: Value(createdAt),
        acknowledgedAt: Value(acknowledgedAt),
        acknowledgedBy: Value(acknowledgedBy),
        status: Value(status.name),
        isDirty: Value(isDirty),
      );

  /// Converts this model to the domain [Alert] entity.
  Alert toEntity() => Alert(
    id: id,
    type: type,
    severity: severity,
    title: title,
    message: message,
    sourceId: sourceId,
    sourceType: sourceType,
    recommendedActions: recommendedActions,
    createdAt: createdAt,
    acknowledgedAt: acknowledgedAt,
    acknowledgedBy: acknowledgedBy,
    status: status,
  );

  @override
  AlertModel copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    String? sourceId,
    String? sourceType,
    List<String>? recommendedActions,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    AlertStatus? status,
  }) => AlertModel(
    id: id ?? this.id,
    type: type ?? this.type,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    message: message ?? this.message,
    sourceId: sourceId ?? this.sourceId,
    sourceType: sourceType ?? this.sourceType,
    recommendedActions: recommendedActions ?? this.recommendedActions,
    createdAt: createdAt ?? this.createdAt,
    acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    status: status ?? this.status,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Parses a [recommendedActions] value that may be a List or JSON string.
  static List<String> _parseActions(Object? rawActions) {
    if (rawActions is List) {
      return rawActions.map((e) => e.toString()).toList();
    }
    if (rawActions is String && rawActions.isNotEmpty) {
      return _parseActionsFromJson(rawActions);
    }
    return [];
  }

  /// Decodes a JSON-encoded list of action strings.
  static List<String> _parseActionsFromJson(String rawJson) {
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

  /// Parses an [AlertType] from a string, falling back to [AlertType.system].
  static AlertType _parseAlertType(String value) {
    switch (value) {
      case 'waterQuality':
        return AlertType.waterQuality;
      case 'equipment':
        return AlertType.equipment;
      case 'crabHealth':
        return AlertType.crabHealth;
      case 'maintenance':
        return AlertType.maintenance;
      case 'task':
        return AlertType.task;
      case 'system':
      default:
        return AlertType.system;
    }
  }

  /// Parses an [AlertSeverity] from a string, falling back to [AlertSeverity.info].
  static AlertSeverity _parseAlertSeverity(String value) {
    switch (value) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      case 'info':
      default:
        return AlertSeverity.info;
    }
  }

  /// Parses an [AlertStatus] from a string, falling back to [AlertStatus.unread].
  static AlertStatus _parseAlertStatus(String value) {
    switch (value) {
      case 'read':
        return AlertStatus.read;
      case 'acknowledged':
        return AlertStatus.acknowledged;
      case 'dismissed':
        return AlertStatus.dismissed;
      case 'unread':
      default:
        return AlertStatus.unread;
    }
  }
}
