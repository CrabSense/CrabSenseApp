import 'package:equatable/equatable.dart';

import '../../domain/entities/ai_detection.dart';

/// Base class for all AI results events.
///
/// Events represent user actions or system triggers that cause state
/// changes in [AiResultsBloc].
///
/// Requirements: 6.1-6.10
abstract class AiResultsEvent extends Equatable {
  const AiResultsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load AI detection results for a given video.
///
/// Requirement 6.1
class LoadAIResults extends AiResultsEvent {
  const LoadAIResults({required this.videoId});

  /// The video whose AI analysis is requested.
  final String videoId;

  @override
  List<Object?> get props => [videoId];
}

/// Event to refresh AI detection results for a given video.
///
/// Used for polling while the AI service is still processing
/// (up to 60 seconds per Requirement 6.1).
///
/// Requirement 6.1
class RefreshAIResults extends AiResultsEvent {
  const RefreshAIResults({required this.videoId});

  /// The video whose AI analysis is requested.
  final String videoId;

  @override
  List<Object?> get props => [videoId];
}

/// Event to submit operator feedback (correct / incorrect) on an AI result.
///
/// Requirement 6.9
class SubmitFeedback extends AiResultsEvent {
  const SubmitFeedback({required this.detectionId, required this.isCorrect});

  /// The AI detection result being reviewed.
  final String detectionId;

  /// True if the operator confirms the AI result is correct.
  final bool isCorrect;

  @override
  List<Object?> get props => [detectionId, isCorrect];
}

/// Event to retry uploading a video that was queued while offline.
///
/// Requirement 6.10
class RetryVideoUpload extends AiResultsEvent {
  const RetryVideoUpload({required this.videoId});

  /// The locally-queued video to re-attempt upload.
  final String videoId;

  @override
  List<Object?> get props => [videoId];
}

/// Extension on [SubmitFeedback] for deriving the domain feedback status.
extension SubmitFeedbackExtension on SubmitFeedback {
  /// Converts the boolean [isCorrect] flag to [DetectionFeedbackStatus].
  DetectionFeedbackStatus get feedbackStatus =>
      isCorrect ? DetectionFeedbackStatus.correct : DetectionFeedbackStatus.incorrect;
}
