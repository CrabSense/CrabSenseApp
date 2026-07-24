import '../../../box/domain/entities/box_enums.dart';

/// Sync state of an inspection record with the remote server.
///
/// Used to support offline-first behaviour (Requirement 7.7, 13.3-13.10).
enum SyncStatus {
  /// Record has been created locally and is waiting to be uploaded.
  pending,

  /// Record has been successfully synchronised with the server.
  synced,

  /// The last synchronisation attempt failed; will be retried.
  failed,
}

/// Extension on SyncStatus for display helpers.
extension SyncStatusExtension on SyncStatus {
  /// Returns the human-readable display name for the sync status.
  String get displayName {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
    }
  }

  /// Returns true if the record still needs to be sent to the server.
  bool get needsSync => this == SyncStatus.pending || this == SyncStatus.failed;
}

/// Domain entity representing a manual inspection of a crab box.
///
/// A manual inspection is performed by a Field Operator (or higher) to
/// verify or correct AI detection results.  All field inputs are captured
/// at submission time and stored locally when offline.
///
/// This is a pure domain entity — no Flutter or platform dependencies.
/// All fields are immutable (final); use [copyWith] to produce updated copies.
///
/// Requirements: 7.1-7.10
class Inspection {
  /// Creates an immutable [Inspection] entity.
  const Inspection({
    required this.id,
    required this.boxId,
    required this.moltingStatus,
    required this.healthStatus,
    required this.weight,
    required this.notes,
    required this.photoUrls,
    required this.timestamp,
    required this.operatorId,
    required this.operatorName,
    required this.syncStatus,
    this.relatedVideoId,
    this.aiAgreement,
  });

  /// Unique identifier for this inspection record.
  final String id;

  /// Identifier of the box that was inspected (Requirement 7.6).
  final String boxId;

  /// Optional identifier of the AI-analysis video this inspection relates to.
  ///
  /// When set, the operator compared their manual findings against the AI
  /// result from this video (Requirement 7.1).
  final String? relatedVideoId;

  /// Molting stage recorded during manual inspection (Requirement 7.2).
  final MoltingStatus moltingStatus;

  /// Health condition recorded during manual inspection (Requirement 7.2).
  final HealthStatus healthStatus;

  /// Crab weight recorded in grams — must be a positive value (Requirement 7.2).
  final double weight;

  /// Optional free-text observations made by the operator.
  final String notes;

  /// URLs of photos captured during the inspection (Requirement 7.3).
  final List<String> photoUrls;

  /// Date and time at which the inspection was submitted (Requirement 7.10).
  final DateTime timestamp;

  /// Identifier of the operator who performed the inspection (Requirement 7.9).
  final String operatorId;

  /// Display name of the operator (Requirement 7.10).
  final String operatorName;

  /// Whether the operator agreed with the AI detection result.
  ///
  /// - `null`  — no AI result was available to compare against
  /// - `true`  — operator confirmed the AI result was correct
  /// - `false` — operator disagreed with the AI result
  ///
  /// Used to track the agreement rate (Requirement 7.8).
  final bool? aiAgreement;

  /// Current synchronisation state of this record (Requirement 7.7).
  final SyncStatus syncStatus;

  /// Returns `true` if the weight is a positive value.
  ///
  /// Required validation before submission (Requirement 7.4).
  bool get hasValidWeight => weight > 0;

  /// Returns `true` when this record still needs to reach the server.
  bool get needsSync => syncStatus.needsSync;

  /// Creates a copy of this inspection with the specified fields replaced.
  Inspection copyWith({
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
  }) => Inspection(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Inspection) return false;
    return other.id == id &&
        other.boxId == boxId &&
        other.relatedVideoId == relatedVideoId &&
        other.moltingStatus == moltingStatus &&
        other.healthStatus == healthStatus &&
        other.weight == weight &&
        other.notes == notes &&
        other.photoUrls.length == photoUrls.length &&
        other.timestamp == timestamp &&
        other.operatorId == operatorId &&
        other.operatorName == operatorName &&
        other.aiAgreement == aiAgreement &&
        other.syncStatus == syncStatus;
  }

  @override
  int get hashCode => Object.hash(
    id,
    boxId,
    relatedVideoId,
    moltingStatus,
    healthStatus,
    weight,
    notes,
    Object.hashAll(photoUrls),
    timestamp,
    operatorId,
    operatorName,
    aiAgreement,
    syncStatus,
  );

  @override
  String toString() =>
      'Inspection(id: $id, boxId: $boxId, '
      'relatedVideoId: $relatedVideoId, '
      'moltingStatus: ${moltingStatus.displayName}, '
      'healthStatus: ${healthStatus.displayName}, '
      'weight: $weight, notes: $notes, '
      'photoUrls: $photoUrls, timestamp: $timestamp, '
      'operatorId: $operatorId, operatorName: $operatorName, '
      'aiAgreement: $aiAgreement, syncStatus: ${syncStatus.displayName})';
}

/// Domain entity representing feedback submitted about an AI detection result.
///
/// When an operator indicates that the AI result was correct or incorrect,
/// this entity captures their correction so the AI_Service can use it for
/// model retraining (Requirement 7.5).
///
/// This is a pure domain entity — no Flutter or platform dependencies.
/// All fields are immutable (final); use [copyWith] to produce updated copies.
///
/// Requirements: 7.5, 7.8
class InspectionFeedback {
  /// Creates an immutable [InspectionFeedback] entity.
  const InspectionFeedback({
    required this.inspectionId,
    required this.videoId,
    required this.isCorrect,
    required this.submittedAt,
    required this.operatorId,
    this.correctedMoltingStatus,
    this.correctedHealthStatus,
  });

  /// Identifier of the [Inspection] this feedback is attached to.
  final String inspectionId;

  /// Identifier of the AI-analysis video being reviewed.
  final String videoId;

  /// Whether the operator confirmed the AI result was correct.
  ///
  /// - `true`  — AI result was correct; no corrections needed
  /// - `false` — AI result was wrong; see [correctedMoltingStatus] /
  ///             [correctedHealthStatus] for the operator's corrections
  final bool isCorrect;

  /// Operator's corrected molting status (only set when [isCorrect] is false).
  final MoltingStatus? correctedMoltingStatus;

  /// Operator's corrected health status (only set when [isCorrect] is false).
  final HealthStatus? correctedHealthStatus;

  /// Date and time at which this feedback was submitted.
  final DateTime submittedAt;

  /// Identifier of the operator who provided the feedback (Requirement 7.9).
  final String operatorId;

  /// Returns `true` when corrections have been provided alongside a rejection.
  ///
  /// At least one corrected field should be supplied when [isCorrect] is
  /// false; the repository/use-case layers enforce this rule.
  bool get hasCorrections => correctedMoltingStatus != null || correctedHealthStatus != null;

  /// Creates a copy of this feedback with the specified fields replaced.
  InspectionFeedback copyWith({
    String? inspectionId,
    String? videoId,
    bool? isCorrect,
    MoltingStatus? correctedMoltingStatus,
    HealthStatus? correctedHealthStatus,
    DateTime? submittedAt,
    String? operatorId,
    bool clearCorrectedMoltingStatus = false,
    bool clearCorrectedHealthStatus = false,
  }) => InspectionFeedback(
    inspectionId: inspectionId ?? this.inspectionId,
    videoId: videoId ?? this.videoId,
    isCorrect: isCorrect ?? this.isCorrect,
    correctedMoltingStatus: clearCorrectedMoltingStatus
        ? null
        : (correctedMoltingStatus ?? this.correctedMoltingStatus),
    correctedHealthStatus: clearCorrectedHealthStatus
        ? null
        : (correctedHealthStatus ?? this.correctedHealthStatus),
    submittedAt: submittedAt ?? this.submittedAt,
    operatorId: operatorId ?? this.operatorId,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InspectionFeedback) return false;
    return other.inspectionId == inspectionId &&
        other.videoId == videoId &&
        other.isCorrect == isCorrect &&
        other.correctedMoltingStatus == correctedMoltingStatus &&
        other.correctedHealthStatus == correctedHealthStatus &&
        other.submittedAt == submittedAt &&
        other.operatorId == operatorId;
  }

  @override
  int get hashCode => Object.hash(
    inspectionId,
    videoId,
    isCorrect,
    correctedMoltingStatus,
    correctedHealthStatus,
    submittedAt,
    operatorId,
  );

  @override
  String toString() =>
      'InspectionFeedback(inspectionId: $inspectionId, '
      'videoId: $videoId, isCorrect: $isCorrect, '
      'correctedMoltingStatus: $correctedMoltingStatus, '
      'correctedHealthStatus: $correctedHealthStatus, '
      'submittedAt: $submittedAt, operatorId: $operatorId)';
}
