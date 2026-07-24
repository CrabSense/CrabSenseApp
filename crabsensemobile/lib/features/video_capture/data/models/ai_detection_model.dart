// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart' show AiDetectionsCompanion;
import '../../../box/domain/entities/box_enums.dart';
import '../../domain/entities/ai_detection.dart';

/// Data Transfer Object (DTO) for the [AIDetection] and [DetectionBox] entities.
///
/// Handles serialization/deserialization for API responses and Drift rows.
/// JSON list columns (detectedCrabs, recommendations) are stored as JSON strings.
///
/// Requirements: 6.1-6.10
class AIDetectionModel extends AIDetection {
  const AIDetectionModel({
    required super.id,
    required super.videoId,
    required super.boxId,
    required super.moltingStatus,
    required super.healthStatus,
    required super.confidenceScore,
    required super.detectedCrabs,
    required super.recommendations,
    required super.analyzedAt,
    super.feedbackStatus,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates an [AIDetectionModel] from a raw JSON map (API response).
  factory AIDetectionModel.fromJson(Map<String, dynamic> json) {
    String asStr(Object? value) => value?.toString() ?? '';

    // Parse optional ResultJson blob from BE AiDetectionDto.
    Map<String, dynamic> resultMap = const {};
    final rawResult = json['resultJson'] ?? json['result_json'];
    if (rawResult is String && rawResult.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawResult);
        if (decoded is Map<String, dynamic>) resultMap = decoded;
      } on Exception {
        // ignore malformed
      }
    } else if (rawResult is Map<String, dynamic>) {
      resultMap = rawResult;
    }

    final healthRaw =
        json['healthStatus'] as String? ??
        json['health_status'] as String? ??
        resultMap['health'] as String? ??
        'unknown';
    final moltRaw =
        json['moltingStatus'] as String? ??
        json['molting_status'] as String? ??
        (resultMap['moltingLikely'] == true ? 'molting' : null) ??
        'hardShell';

    return AIDetectionModel(
      id: asStr(json['id']),
      videoId: asStr(
        json['videoId'] ?? json['video_id'] ?? json['mediaId'] ?? json['media_id'],
      ),
      boxId: asStr(json['boxId'] ?? json['box_id'] ?? resultMap['boxId']),
      moltingStatus: _moltingStatusFromString(moltRaw),
      healthStatus: _healthStatusFromString(healthRaw),
      confidenceScore:
          (json['confidenceScore'] as num?)?.toDouble() ??
          (json['confidence_score'] as num?)?.toDouble() ??
          (json['confidence'] as num?)?.toDouble() ??
          0.0,
      detectedCrabs: _parseDetectionBoxList(json['detectedCrabs'] ?? json['detected_crabs']),
      recommendations: _parseRecommendationList(json['recommendations']),
      analyzedAt: _parseDateTime(
        json['analyzedAt'] as String? ??
            json['analyzed_at'] as String? ??
            json['detectedAt'] as String? ??
            json['detected_at'] as String?,
      ),
      feedbackStatus: detectionFeedbackStatusFromString(
        json['feedbackStatus'] as String? ??
            json['feedback_status'] as String? ??
            json['status'] as String?,
      ),
    );
  }

  /// Creates an [AIDetectionModel] from Drift row column values (local DB).
  factory AIDetectionModel.fromDrift({
    required String id,
    required String videoId,
    required String boxId,
    required String moltingStatus,
    required String healthStatus,
    required double confidenceScore,
    required String detectedCrabsJson,
    required String recommendationsJson,
    required DateTime analyzedAt,
    required String? feedbackStatus,
  }) => AIDetectionModel(
    id: id,
    videoId: videoId,
    boxId: boxId,
    moltingStatus: _moltingStatusFromString(moltingStatus),
    healthStatus: _healthStatusFromString(healthStatus),
    confidenceScore: confidenceScore,
    detectedCrabs: _parseDetectionBoxListFromJson(detectedCrabsJson),
    recommendations: _parseRecommendationListFromJson(recommendationsJson),
    analyzedAt: analyzedAt,
    feedbackStatus: detectionFeedbackStatusFromString(feedbackStatus),
  );

  /// Creates an [AIDetectionModel] from a domain [AIDetection] entity.
  factory AIDetectionModel.fromEntity(AIDetection detection) => AIDetectionModel(
    id: detection.id,
    videoId: detection.videoId,
    boxId: detection.boxId,
    moltingStatus: detection.moltingStatus,
    healthStatus: detection.healthStatus,
    confidenceScore: detection.confidenceScore,
    detectedCrabs: detection.detectedCrabs,
    recommendations: detection.recommendations,
    analyzedAt: detection.analyzedAt,
    feedbackStatus: detection.feedbackStatus,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Serialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this model to a JSON map suitable for API requests.
  Map<String, dynamic> toJson() => {
    'id': id,
    'videoId': videoId,
    'boxId': boxId,
    'moltingStatus': _moltingStatusToString(moltingStatus),
    'healthStatus': _healthStatusToString(healthStatus),
    'confidenceScore': confidenceScore,
    'detectedCrabs': detectedCrabs.map(_detectionBoxToJson).toList(),
    'recommendations': recommendations.map(_recommendationToString).toList(),
    'analyzedAt': analyzedAt.toIso8601String(),
    'feedbackStatus': feedbackStatus?.value,
  };

  /// Converts this model to an [AiDetectionsCompanion] for Drift inserts/updates.
  AiDetectionsCompanion toDriftCompanion({bool isDirty = false}) => AiDetectionsCompanion(
    id: Value(id),
    videoId: Value(videoId),
    boxId: Value(boxId),
    moltingStatus: Value(_moltingStatusToString(moltingStatus)),
    healthStatus: Value(_healthStatusToString(healthStatus)),
    confidenceScore: Value(confidenceScore),
    detectedCrabs: Value(jsonEncode(detectedCrabs.map(_detectionBoxToJson).toList())),
    recommendations: Value(jsonEncode(recommendations.map(_recommendationToString).toList())),
    analyzedAt: Value(analyzedAt),
    feedbackStatus: Value(feedbackStatus?.value),
    isDirty: Value(isDirty),
    cachedAt: Value(DateTime.now().toUtc()),
  );

  /// Converts this model to a domain [AIDetection] entity.
  AIDetection toEntity() => AIDetection(
    id: id,
    videoId: videoId,
    boxId: boxId,
    moltingStatus: moltingStatus,
    healthStatus: healthStatus,
    confidenceScore: confidenceScore,
    detectedCrabs: detectedCrabs,
    recommendations: recommendations,
    analyzedAt: analyzedAt,
    feedbackStatus: feedbackStatus,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers — enum parsing
  // ──────────────────────────────────────────────────────────────────────────

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

  static AIRecommendation _recommendationFromString(String value) {
    switch (value.toLowerCase()) {
      case 'continuemonitoring':
      case 'continue_monitoring':
        return AIRecommendation.continueMonitoring;
      case 'harvestready':
      case 'harvest_ready':
        return AIRecommendation.harvestReady;
      case 'treatdisease':
      case 'treat_disease':
        return AIRecommendation.treatDisease;
      case 'manualinspectionrequired':
      case 'manual_inspection_required':
        return AIRecommendation.manualInspectionRequired;
      default:
        return AIRecommendation.continueMonitoring;
    }
  }

  static String _recommendationToString(AIRecommendation rec) {
    switch (rec) {
      case AIRecommendation.continueMonitoring:
        return 'continueMonitoring';
      case AIRecommendation.harvestReady:
        return 'harvestReady';
      case AIRecommendation.treatDisease:
        return 'treatDisease';
      case AIRecommendation.manualInspectionRequired:
        return 'manualInspectionRequired';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers — DetectionBox parsing
  // ──────────────────────────────────────────────────────────────────────────

  static List<DetectionBox> _parseDetectionBoxList(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is String) {
      return _parseDetectionBoxListFromJson(raw);
    }
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(_detectionBoxFromJson)
          .toList(growable: false);
    }
    return const [];
  }

  static List<DetectionBox> _parseDetectionBoxListFromJson(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(_detectionBoxFromJson)
            .toList(growable: false);
      }
    } on Exception {
      // Fall through to empty list
    }
    return const [];
  }

  static DetectionBox _detectionBoxFromJson(Map<String, dynamic> json) => DetectionBox(
    x: (json['x'] as num?)?.toDouble() ?? 0.0,
    y: (json['y'] as num?)?.toDouble() ?? 0.0,
    width: (json['width'] as num?)?.toDouble() ?? 0.0,
    height: (json['height'] as num?)?.toDouble() ?? 0.0,
    label: json['label'] as String? ?? '',
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
  );

  static Map<String, dynamic> _detectionBoxToJson(DetectionBox box) => {
    'x': box.x,
    'y': box.y,
    'width': box.width,
    'height': box.height,
    'label': box.label,
    'confidence': box.confidence,
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers — Recommendations parsing
  // ──────────────────────────────────────────────────────────────────────────

  static List<AIRecommendation> _parseRecommendationList(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is String) {
      return _parseRecommendationListFromJson(raw);
    }
    if (raw is List) {
      return raw.whereType<String>().map(_recommendationFromString).toList(growable: false);
    }
    return const [];
  }

  static List<AIRecommendation> _parseRecommendationListFromJson(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.whereType<String>().map(_recommendationFromString).toList(growable: false);
      }
    } on Exception {
      // Fall through to empty list
    }
    return const [];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers — DateTime parsing
  // ──────────────────────────────────────────────────────────────────────────

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.parse(value);
  }
}
