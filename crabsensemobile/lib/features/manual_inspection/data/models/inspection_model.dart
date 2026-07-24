// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

// Hide the Drift-generated `Inspection` row class to avoid colliding with
// the domain entity of the same name.
import '../../../../core/database/database.dart' hide Inspection;
import '../../../box/domain/entities/box_enums.dart';
import '../../domain/entities/inspection.dart';

/// Data Transfer Object (DTO) for the [Inspection] domain entity.
///
/// Handles serialisation and deserialisation of inspection data from:
///   - REST API JSON responses  (via [fromJson] / [toJson])
///   - Drift SQLite rows        (via [fromDrift] / [toDriftCompanion])
///   - Domain entities          (via [fromEntity] / [toEntity])
///
/// The serialisation is hand-rolled (no code-generation) to stay consistent
/// with other DTOs in this project (e.g. BoxModel, CrabModel).
///
/// Requirements: 7.1-7.10
class InspectionModel extends Inspection {
  const InspectionModel({
    required super.id,
    required super.boxId,
    required super.moltingStatus,
    required super.healthStatus,
    required super.weight,
    required super.notes,
    required super.photoUrls,
    required super.timestamp,
    required super.operatorId,
    required super.operatorName,
    required super.syncStatus,
    super.relatedVideoId,
    super.aiAgreement,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates an [InspectionModel] from a raw API JSON map.
  ///
  /// Accepts both camelCase and snake_case key variants to be resilient to
  /// minor API naming inconsistencies.
  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    String asStr(Object? value) => value?.toString() ?? '';
    final rawPhotos = json['photoUrls'] ?? json['photo_urls'];
    final photoUrls = _parseStringList(rawPhotos);

    return InspectionModel(
      id: asStr(json['id']),
      boxId: asStr(json['boxId'] ?? json['box_id']),
      relatedVideoId: () {
        final raw = json['relatedVideoId'] ?? json['related_video_id'];
        final s = asStr(raw);
        return s.isEmpty ? null : s;
      }(),
      moltingStatus: _moltingStatusFromString(
        json['moltingStatus'] as String? ?? json['molting_status'] as String? ?? 'hardShell',
      ),
      healthStatus: _healthStatusFromString(
        json['healthStatus'] as String? ?? json['health_status'] as String? ?? 'unknown',
      ),
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      photoUrls: photoUrls,
      timestamp: _parseDateTime(json['timestamp'] as String? ?? json['created_at'] as String?),
      operatorId: asStr(json['operatorId'] ?? json['operator_id']),
      operatorName: asStr(json['operatorName'] ?? json['operator_name']),
      aiAgreement: json['aiAgreement'] as bool? ?? json['ai_agreement'] as bool?,
      syncStatus: SyncStatus.synced, // Data from API is already synced.
    );
  }

  /// Creates an [InspectionModel] from a Drift database row.
  ///
  /// Uses raw typed parameters rather than the generated Drift row type to
  /// avoid the `Inspection` name collision at call sites.
  factory InspectionModel.fromDrift({
    required String id,
    required String boxId,
    required String? relatedVideoId,
    required String moltingStatus,
    required String healthStatus,
    required double weight,
    required String notes,
    required String photoUrlsJson,
    required DateTime timestamp,
    required String operatorId,
    required String operatorName,
    required bool? aiAgreement,
    required String syncStatus,
  }) => InspectionModel(
    id: id,
    boxId: boxId,
    relatedVideoId: relatedVideoId,
    moltingStatus: _moltingStatusFromString(moltingStatus),
    healthStatus: _healthStatusFromString(healthStatus),
    weight: weight,
    notes: notes,
    photoUrls: _parseStringList(jsonDecode(photoUrlsJson)),
    timestamp: timestamp,
    operatorId: operatorId,
    operatorName: operatorName,
    aiAgreement: aiAgreement,
    syncStatus: _syncStatusFromString(syncStatus),
  );

  /// Creates an [InspectionModel] from a domain [Inspection] entity.
  factory InspectionModel.fromEntity(Inspection inspection) => InspectionModel(
    id: inspection.id,
    boxId: inspection.boxId,
    relatedVideoId: inspection.relatedVideoId,
    moltingStatus: inspection.moltingStatus,
    healthStatus: inspection.healthStatus,
    weight: inspection.weight,
    notes: inspection.notes,
    photoUrls: inspection.photoUrls,
    timestamp: inspection.timestamp,
    operatorId: inspection.operatorId,
    operatorName: inspection.operatorName,
    aiAgreement: inspection.aiAgreement,
    syncStatus: inspection.syncStatus,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Serialisation
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
    'id': id,
    'boxId': boxId,
    'relatedVideoId': relatedVideoId,
    'moltingStatus': _moltingStatusToString(moltingStatus),
    'healthStatus': _healthStatusToString(healthStatus),
    'weight': weight,
    'notes': notes,
    'photoUrls': photoUrls,
    'timestamp': timestamp.toIso8601String(),
    'operatorId': operatorId,
    'operatorName': operatorName,
    'aiAgreement': aiAgreement,
  };

  /// Converts this model to a Drift [InspectionsCompanion] for DB writes.
  InspectionsCompanion toDriftCompanion({bool isDirty = false}) => InspectionsCompanion(
    id: Value(id),
    boxId: Value(boxId),
    relatedVideoId: Value(relatedVideoId),
    moltingStatus: Value(_moltingStatusToString(moltingStatus)),
    healthStatus: Value(_healthStatusToString(healthStatus)),
    weight: Value(weight),
    notes: Value(notes),
    photoUrls: Value(jsonEncode(photoUrls)),
    timestamp: Value(timestamp),
    operatorId: Value(operatorId),
    operatorName: Value(operatorName),
    aiAgreement: Value(aiAgreement),
    syncStatus: Value(_syncStatusToString(syncStatus)),
    isDirty: Value(isDirty),
  );

  /// Converts this model to a domain [Inspection] entity.
  Inspection toEntity() => Inspection(
    id: id,
    boxId: boxId,
    relatedVideoId: relatedVideoId,
    moltingStatus: moltingStatus,
    healthStatus: healthStatus,
    weight: weight,
    notes: notes,
    photoUrls: photoUrls,
    timestamp: timestamp,
    operatorId: operatorId,
    operatorName: operatorName,
    aiAgreement: aiAgreement,
    syncStatus: syncStatus,
  );

  @override
  InspectionModel copyWith({
    String? id,
    String? boxId,
    String? relatedVideoId,
    MoltingStatus? moltingStatus,
    HealthStatus? healthStatus,
    double? weight,
    String? notes,
    List<String>? photoUrls,
    DateTime? timestamp,
    String? operatorId,
    String? operatorName,
    bool? aiAgreement,
    SyncStatus? syncStatus,
    bool clearRelatedVideoId = false,
    bool clearAiAgreement = false,
  }) => InspectionModel(
    id: id ?? this.id,
    boxId: boxId ?? this.boxId,
    relatedVideoId: clearRelatedVideoId ? null : (relatedVideoId ?? this.relatedVideoId),
    moltingStatus: moltingStatus ?? this.moltingStatus,
    healthStatus: healthStatus ?? this.healthStatus,
    weight: weight ?? this.weight,
    notes: notes ?? this.notes,
    photoUrls: photoUrls ?? this.photoUrls,
    timestamp: timestamp ?? this.timestamp,
    operatorId: operatorId ?? this.operatorId,
    operatorName: operatorName ?? this.operatorName,
    aiAgreement: clearAiAgreement ? null : (aiAgreement ?? this.aiAgreement),
    syncStatus: syncStatus ?? this.syncStatus,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers — package-visible for InspectionFeedbackModel
  // ──────────────────────────────────────────────────────────────────────────

  static List<String> _parseStringList(raw) {
    if (raw is List) {
      return raw.whereType<String>().toList(growable: false);
    }
    return const [];
  }

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return DateTime.now().toUtc();
    return DateTime.parse(value);
  }

  // Exposed so InspectionFeedbackModel can reuse them without duplication.

  static MoltingStatus moltingStatusFromString(String value) => _moltingStatusFromString(value);

  static String moltingStatusToString(MoltingStatus status) => _moltingStatusToString(status);

  static HealthStatus healthStatusFromString(String value) => _healthStatusFromString(value);

  static String healthStatusToString(HealthStatus status) => _healthStatusToString(status);

  static MoltingStatus _moltingStatusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'premolt':
      case 'pre_molt':
        return MoltingStatus.preMolt;
      case 'molting':
        return MoltingStatus.molting;
      case 'postmolt':
      case 'post_molt':
        return MoltingStatus.postMolt;
      case 'hardshell':
      case 'hard_shell':
        return MoltingStatus.hardShell;
      default:
        return MoltingStatus.hardShell;
    }
  }

  static String _moltingStatusToString(MoltingStatus status) {
    switch (status) {
      case MoltingStatus.preMolt:
        return 'preMolt';
      case MoltingStatus.molting:
        return 'molting';
      case MoltingStatus.postMolt:
        return 'postMolt';
      case MoltingStatus.hardShell:
        return 'hardShell';
    }
  }

  static HealthStatus _healthStatusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'normal':
        return HealthStatus.normal;
      case 'disease':
        return HealthStatus.disease;
      case 'stress':
        return HealthStatus.stress;
      case 'unknown':
      default:
        return HealthStatus.unknown;
    }
  }

  static String _healthStatusToString(HealthStatus status) {
    switch (status) {
      case HealthStatus.normal:
        return 'normal';
      case HealthStatus.disease:
        return 'disease';
      case HealthStatus.stress:
        return 'stress';
      case HealthStatus.unknown:
        return 'unknown';
    }
  }

  static SyncStatus _syncStatusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      case 'pending':
      default:
        return SyncStatus.pending;
    }
  }

  static String _syncStatusToString(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.failed:
        return 'failed';
    }
  }
}

/// DTO for the [InspectionFeedback] entity.
///
/// Handles serialisation for submitting operator feedback on AI results
/// to the remote AI service (Requirement 7.5).
class InspectionFeedbackModel extends InspectionFeedback {
  const InspectionFeedbackModel({
    required super.inspectionId,
    required super.videoId,
    required super.isCorrect,
    required super.submittedAt,
    required super.operatorId,
    super.correctedMoltingStatus,
    super.correctedHealthStatus,
  });

  /// Creates an [InspectionFeedbackModel] from a raw API JSON map.
  factory InspectionFeedbackModel.fromJson(Map<String, dynamic> json) => InspectionFeedbackModel(
    inspectionId: json['inspectionId'] as String? ?? json['inspection_id'] as String? ?? '',
    videoId: json['videoId'] as String? ?? json['video_id'] as String? ?? '',
    isCorrect: json['isCorrect'] as bool? ?? json['is_correct'] as bool? ?? true,
    correctedMoltingStatus: json['correctedMoltingStatus'] != null
        ? InspectionModel.moltingStatusFromString(json['correctedMoltingStatus'] as String)
        : null,
    correctedHealthStatus: json['correctedHealthStatus'] != null
        ? InspectionModel.healthStatusFromString(json['correctedHealthStatus'] as String)
        : null,
    submittedAt: DateTime.parse(
      json['submittedAt'] as String? ??
          json['submitted_at'] as String? ??
          DateTime.now().toIso8601String(),
    ),
    operatorId: json['operatorId'] as String? ?? json['operator_id'] as String? ?? '',
  );

  /// Creates an [InspectionFeedbackModel] from a domain [InspectionFeedback].
  factory InspectionFeedbackModel.fromEntity(InspectionFeedback feedback) =>
      InspectionFeedbackModel(
        inspectionId: feedback.inspectionId,
        videoId: feedback.videoId,
        isCorrect: feedback.isCorrect,
        correctedMoltingStatus: feedback.correctedMoltingStatus,
        correctedHealthStatus: feedback.correctedHealthStatus,
        submittedAt: feedback.submittedAt,
        operatorId: feedback.operatorId,
      );

  /// Converts this model to a JSON map for the AI service API request.
  Map<String, dynamic> toJson() => {
    // BE AiFeedbackRequest expects detection id + isCorrect (+ optional label/comment).
    'detectionId': inspectionId,
    'aiDetectionId': inspectionId,
    'isCorrect': isCorrect,
    'aiAgreement': isCorrect,
    'correctLabel': correctedMoltingStatus != null
        ? InspectionModel.moltingStatusToString(correctedMoltingStatus!)
        : null,
    'comment': [
      if (videoId.isNotEmpty) 'videoId=$videoId',
      if (correctedHealthStatus != null)
        'health=${InspectionModel.healthStatusToString(correctedHealthStatus!)}',
    ].join('; '),
    'submittedAt': submittedAt.toIso8601String(),
    'operatorId': operatorId,
  };

  /// Converts this model to a domain [InspectionFeedback] entity.
  InspectionFeedback toEntity() => InspectionFeedback(
    inspectionId: inspectionId,
    videoId: videoId,
    isCorrect: isCorrect,
    correctedMoltingStatus: correctedMoltingStatus,
    correctedHealthStatus: correctedHealthStatus,
    submittedAt: submittedAt,
    operatorId: operatorId,
  );
}
