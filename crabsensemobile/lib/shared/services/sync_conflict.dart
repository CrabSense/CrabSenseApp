import 'sync_queue_item.dart';

/// Strategy outcome evaluation from timestamp comparison.
enum ConflictWinner {
  /// Server timestamp is newer than local timestamp -> Server wins.
  server,

  /// Local timestamp is newer than server timestamp -> Local wins.
  local,

  /// Timestamps are equal or simultaneous -> Prompt user for manual resolution.
  manualPrompt,
}

/// Status of a conflict record.
enum ConflictStatus {
  /// Unresolved conflict awaiting manual resolution or review.
  pending,

  /// Resolved by applying server version.
  resolvedServer,

  /// Resolved by applying local version.
  resolvedLocal,

  /// Resolved by applying custom merged version.
  resolvedMerged,
}

/// User choice when resolving a manual conflict.
enum ConflictResolutionChoice {
  /// Keep and apply the server version.
  useServer,

  /// Keep and apply the local version.
  useLocal,

  /// Apply custom merged payload.
  customMerge,
}

/// Model representing a synchronization data conflict.
///
/// Preserves both [localVersion] and [serverVersion] payloads with [hasConflict] flag
/// for review and resolution.
///
/// Requirements: 13.9
class SyncConflict {
  const SyncConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localVersion,
    required this.localTimestamp,
    required this.serverVersion,
    required this.serverTimestamp,
    this.status = ConflictStatus.pending,
    this.hasConflict = true,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedVersion,
  });

  /// Unique conflict identifier.
  final String id;

  /// Entity type (harvest, sale, operation_log, inspection, video, alert_ack).
  final SyncEntityType entityType;

  /// Unique identifier of the affected entity.
  final String entityId;

  /// JSON payload of local edit.
  final Map<String, dynamic> localVersion;

  /// Timestamp of local write/edit.
  final DateTime localTimestamp;

  /// JSON payload of server edit.
  final Map<String, dynamic> serverVersion;

  /// Timestamp of server write/edit.
  final DateTime serverTimestamp;

  /// Current resolution status of this conflict.
  final ConflictStatus status;

  /// Flag indicating that this entity has an active unresolved conflict requiring review.
  final bool hasConflict;

  /// When this conflict record was created.
  final DateTime createdAt;

  /// When this conflict was resolved (null if pending).
  final DateTime? resolvedAt;

  /// Final resolved payload (null if pending).
  final Map<String, dynamic>? resolvedVersion;

  /// Creates a copy of this [SyncConflict] with optional field updates.
  SyncConflict copyWith({
    String? id,
    SyncEntityType? entityType,
    String? entityId,
    Map<String, dynamic>? localVersion,
    DateTime? localTimestamp,
    Map<String, dynamic>? serverVersion,
    DateTime? serverTimestamp,
    ConflictStatus? status,
    bool? hasConflict,
    DateTime? createdAt,
    DateTime? resolvedAt,
    Map<String, dynamic>? resolvedVersion,
  }) {
    return SyncConflict(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localVersion: localVersion ?? this.localVersion,
      localTimestamp: localTimestamp ?? this.localTimestamp,
      serverVersion: serverVersion ?? this.serverVersion,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      status: status ?? this.status,
      hasConflict: hasConflict ?? this.hasConflict,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedVersion: resolvedVersion ?? this.resolvedVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'entityType': entityType.code,
      'entityId': entityId,
      'localVersion': localVersion,
      'localTimestamp': localTimestamp.toIso8601String(),
      'serverVersion': serverVersion,
      'serverTimestamp': serverTimestamp.toIso8601String(),
      'status': status.name,
      'hasConflict': hasConflict,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedVersion': resolvedVersion,
    };
  }

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'] as String,
      entityType: SyncEntityType.fromCode(json['entityType'] as String),
      entityId: json['entityId'] as String,
      localVersion: Map<String, dynamic>.from(json['localVersion'] as Map),
      localTimestamp: DateTime.parse(json['localTimestamp'] as String),
      serverVersion: Map<String, dynamic>.from(json['serverVersion'] as Map),
      serverTimestamp: DateTime.parse(json['serverTimestamp'] as String),
      status: ConflictStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConflictStatus.pending,
      ),
      hasConflict: json['hasConflict'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolvedVersion: json['resolvedVersion'] != null
          ? Map<String, dynamic>.from(json['resolvedVersion'] as Map)
          : null,
    );
  }
}
