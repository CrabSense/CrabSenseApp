import 'package:equatable/equatable.dart';

import '../../domain/entities/ai_detection.dart';

/// Base class for all AI results states.
///
/// States represent the current condition of the AI detection results
/// feature. All states extend this class and use Equatable for value
/// equality comparisons.
///
/// Requirements: 6.1-6.10
abstract class AiResultsState extends Equatable {
  const AiResultsState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the [AiResultsBloc] is first created.
class AiResultsInitial extends AiResultsState {
  const AiResultsInitial();
}

/// State while the AI detection results are being fetched from the
/// repository or AI service.
///
/// The screen should display a loading skeleton.
///
/// Requirement 6.1
class AiResultsLoading extends AiResultsState {
  const AiResultsLoading();
}

/// State while polling for AI analysis that is still in progress.
///
/// The AI service may take up to 60 seconds to complete analysis
/// (Requirement 6.1). This state is emitted between polling attempts
/// so the UI can display a relevant message.
///
/// Requirement 6.1
class AiResultsPolling extends AiResultsState {
  const AiResultsPolling({required this.attemptCount});

  /// How many polling attempts have been made so far.
  final int attemptCount;

  @override
  List<Object?> get props => [attemptCount];
}

/// State when AI detection results have been successfully loaded.
///
/// When [requiresManualInspection] is true (confidence < 70%),
/// the UI must display a prominent banner prompting the operator
/// to confirm manually (Requirement 6.7).
///
/// Requirements: 6.2-6.6
class AiResultsLoaded extends AiResultsState {
  const AiResultsLoaded({required this.detection, this.requiresManualInspection = false});

  /// The AI detection result containing molting status, health
  /// indicators, confidence score, bounding boxes, and recommendations.
  final AIDetection detection;

  /// True when the detection confidence score is below 70%.
  ///
  /// When true the screen shows a banner prompting the operator to
  /// navigate to the manual inspection screen (Requirement 6.7).
  final bool requiresManualInspection;

  @override
  List<Object?> get props => [detection, requiresManualInspection];
}

/// State when an error occurred while loading AI results.
///
/// Requirement 21.1-21.3
class AiResultsError extends AiResultsState {
  const AiResultsError({required this.message, this.videoId, this.code});

  /// User-facing error message.
  final String message;

  /// Optional machine-readable error code for retry logic.
  final String? code;

  /// The video ID that failed, used to retry the request.
  final String? videoId;

  @override
  List<Object?> get props => [message, code, videoId];
}

/// State while operator feedback (correct / incorrect) is being
/// submitted to the repository.
///
/// The feedback buttons should appear as loading / disabled.
///
/// Requirement 6.9
class FeedbackSubmitting extends AiResultsState {
  const FeedbackSubmitting({required this.detection});

  /// The detection being reviewed so the rest of the UI stays populated.
  final AIDetection detection;

  @override
  List<Object?> get props => [detection];
}

/// State when operator feedback was submitted successfully.
///
/// The updated [detection] now has [AIDetection.feedbackStatus] set.
///
/// Requirement 6.9
class FeedbackSubmitted extends AiResultsState {
  const FeedbackSubmitted({required this.detection});

  /// The updated detection result including the submitted feedback.
  final AIDetection detection;

  @override
  List<Object?> get props => [detection];
}

/// State when feedback submission failed.
///
/// The screen should show an error snackbar and keep the previous
/// loaded state visible.
///
/// Requirement 6.9
class FeedbackError extends AiResultsState {
  const FeedbackError({required this.detection, required this.message});

  /// The original detection result (unchanged after failure).
  final AIDetection detection;

  /// User-facing error message.
  final String message;

  @override
  List<Object?> get props => [detection, message];
}
