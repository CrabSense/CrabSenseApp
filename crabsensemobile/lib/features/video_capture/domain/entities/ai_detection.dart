/// AI detection result entities for crab health video analysis.
///
/// Contains the overall molting/health classification, a confidence score,
/// bounding boxes around detected individual crabs, and actionable
/// recommendations for the field operator.
///
/// This is a pure domain entity with no external dependencies.
/// All fields are immutable (final); use [copyWith] to create modified copies.
///
/// MoltingStatus and HealthStatus enums are shared with the box domain
/// (features/box/domain/entities/box_enums.dart) to ensure consistent
/// classification values across the application.
///
/// Requirements: 6.1-6.10
library;

import '../../../box/domain/entities/box_enums.dart';

/// Recommendation produced by the AI service based on detection results.
///
/// Requirement 6.5.
enum AIRecommendation {
  /// No action required; continue normal monitoring schedule.
  continueMonitoring,

  /// Crabs are ready for harvest.
  harvestReady,

  /// Disease detected; treatment should be initiated.
  treatDisease,

  /// Requires manual inspection to confirm AI findings.
  manualInspectionRequired,
}

/// Extension on [AIRecommendation] for display helpers.
extension AIRecommendationExtension on AIRecommendation {
  /// Returns the human-readable display label.
  String get displayName {
    switch (this) {
      case AIRecommendation.continueMonitoring:
        return 'Continue Monitoring';
      case AIRecommendation.harvestReady:
        return 'Harvest Ready';
      case AIRecommendation.treatDisease:
        return 'Treat Disease';
      case AIRecommendation.manualInspectionRequired:
        return 'Manual Inspection Required';
    }
  }
}

/// Bounding box for a single crab detected in a video frame.
///
/// All coordinates are normalised to [0.0, 1.0] relative to the frame
/// dimensions, matching the format returned by the AI service.
///
/// Requirement 6.6.
class DetectionBox {
  const DetectionBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
  });

  /// Normalised x-coordinate of the top-left corner.
  final double x;

  /// Normalised y-coordinate of the top-left corner.
  final double y;

  /// Normalised width of the bounding box.
  final double width;

  /// Normalised height of the bounding box.
  final double height;

  /// Classification label for this detected crab (e.g. "molting").
  final String label;

  /// Confidence score for this specific detection in [0.0, 1.0].
  final double confidence;

  /// Creates a copy with the given fields replaced.
  DetectionBox copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? label,
    double? confidence,
  }) => DetectionBox(
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    label: label ?? this.label,
    confidence: confidence ?? this.confidence,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectionBox &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.label == label &&
        other.confidence == confidence;
  }

  @override
  int get hashCode => Object.hash(x, y, width, height, label, confidence);

  @override
  String toString() =>
      'DetectionBox(x: $x, y: $y, width: $width, height: $height, '
      'label: $label, confidence: $confidence)';
}

/// Feedback status that the operator can submit on an AI detection result.
///
/// Requirement 6.9.
enum DetectionFeedbackStatus {
  /// Operator confirmed the AI result is correct.
  correct,

  /// Operator flagged the AI result as incorrect.
  incorrect,
}

/// Extension on [DetectionFeedbackStatus] for display helpers.
extension DetectionFeedbackStatusExtension on DetectionFeedbackStatus {
  /// Returns the API/persistence value for this status.
  String get value {
    switch (this) {
      case DetectionFeedbackStatus.correct:
        return 'correct';
      case DetectionFeedbackStatus.incorrect:
        return 'incorrect';
    }
  }
}

/// Parses a raw feedback string into a [DetectionFeedbackStatus].
///
/// Returns null if the value is not recognised (no feedback yet).
DetectionFeedbackStatus? detectionFeedbackStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'correct':
      return DetectionFeedbackStatus.correct;
    case 'incorrect':
      return DetectionFeedbackStatus.incorrect;
    default:
      return null;
  }
}

/// AI detection result for a single video analysis.
///
/// The overall [confidenceScore] is in the range [0.0, 1.0].
/// When the score is below [lowConfidenceThreshold] (0.70), the app
/// should prompt the operator for manual inspection (Requirement 6.7).
///
/// Requirements: 6.1-6.10
class AIDetection {
  const AIDetection({
    required this.id,
    required this.videoId,
    required this.boxId,
    required this.moltingStatus,
    required this.healthStatus,
    required this.confidenceScore,
    required this.detectedCrabs,
    required this.recommendations,
    required this.analyzedAt,
    this.feedbackStatus,
  });

  /// Unique identifier for this detection result.
  final String id;

  /// Identifier of the video this result belongs to.
  final String videoId;

  /// Identifier of the box from which the video was recorded.
  final String boxId;

  /// Overall molting stage classification for this video.
  ///
  /// Requirement 6.2.
  final MoltingStatus moltingStatus;

  /// Overall health status classification for this video.
  ///
  /// Requirement 6.4.
  final HealthStatus healthStatus;

  /// Overall confidence score in [0.0, 1.0] for the detection result.
  ///
  /// Displayed as a percentage (x 100) in the UI (Requirement 6.3).
  final double confidenceScore;

  /// Bounding boxes and labels for each crab detected in the video frame.
  ///
  /// Requirement 6.6.
  final List<DetectionBox> detectedCrabs;

  /// Actionable recommendations produced by the AI service.
  ///
  /// Requirement 6.5.
  final List<AIRecommendation> recommendations;

  /// Timestamp when the AI analysis was completed.
  final DateTime analyzedAt;

  /// Optional operator feedback on the accuracy of this result.
  ///
  /// Null until the operator has submitted feedback (Requirement 6.9).
  final DetectionFeedbackStatus? feedbackStatus;

  // ── Business-rule constants ──────────────────────────────────────────────

  /// Confidence score below which a manual inspection should be prompted.
  ///
  /// Requirement 6.7.
  static const double lowConfidenceThreshold = 0.70;

  // ── Computed properties ─────────────────────────────────────────────────

  /// Returns true when the confidence score is below the threshold.
  ///
  /// When true, the app should prompt the operator for manual inspection
  /// (Requirement 6.7).
  bool get isLowConfidence => confidenceScore < lowConfidenceThreshold;

  /// Returns the confidence score as a percentage integer (0-100).
  ///
  /// Requirement 6.3.
  int get confidencePercent => (confidenceScore * 100).round();

  /// Returns true if operator feedback has been submitted.
  bool get hasFeedback => feedbackStatus != null;

  /// Returns true if the detection result indicates the crabs need attention.
  bool get requiresAttention => healthStatus.requiresAttention;

  // ── copyWith ────────────────────────────────────────────────────────────

  /// Creates a copy of this detection with the given fields replaced.
  AIDetection copyWith({
    String? id,
    String? videoId,
    String? boxId,
    MoltingStatus? moltingStatus,
    HealthStatus? healthStatus,
    double? confidenceScore,
    List<DetectionBox>? detectedCrabs,
    List<AIRecommendation>? recommendations,
    DateTime? analyzedAt,
    DetectionFeedbackStatus? feedbackStatus,
  }) => AIDetection(
    id: id ?? this.id,
    videoId: videoId ?? this.videoId,
    boxId: boxId ?? this.boxId,
    moltingStatus: moltingStatus ?? this.moltingStatus,
    healthStatus: healthStatus ?? this.healthStatus,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    detectedCrabs: detectedCrabs ?? this.detectedCrabs,
    recommendations: recommendations ?? this.recommendations,
    analyzedAt: analyzedAt ?? this.analyzedAt,
    feedbackStatus: feedbackStatus ?? this.feedbackStatus,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AIDetection) return false;
    if (other.id != id ||
        other.videoId != videoId ||
        other.boxId != boxId ||
        other.moltingStatus != moltingStatus ||
        other.healthStatus != healthStatus ||
        other.confidenceScore != confidenceScore ||
        other.analyzedAt != analyzedAt ||
        other.feedbackStatus != feedbackStatus) {
      return false;
    }
    if (other.detectedCrabs.length != detectedCrabs.length) {
      return false;
    }
    for (var i = 0; i < detectedCrabs.length; i++) {
      if (other.detectedCrabs[i] != detectedCrabs[i]) return false;
    }
    if (other.recommendations.length != recommendations.length) {
      return false;
    }
    for (var i = 0; i < recommendations.length; i++) {
      if (other.recommendations[i] != recommendations[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    videoId,
    boxId,
    moltingStatus,
    healthStatus,
    confidenceScore,
    Object.hashAll(detectedCrabs),
    Object.hashAll(recommendations),
    analyzedAt,
    feedbackStatus,
  );

  @override
  String toString() =>
      'AIDetection(id: $id, videoId: $videoId, boxId: $boxId, '
      'moltingStatus: ${moltingStatus.displayName}, '
      'healthStatus: ${healthStatus.displayName}, '
      'confidenceScore: $confidenceScore, '
      'detectedCrabs: ${detectedCrabs.length}, '
      'recommendations: ${recommendations.length}, '
      'analyzedAt: $analyzedAt, '
      'feedbackStatus: ${feedbackStatus?.value})';
}
