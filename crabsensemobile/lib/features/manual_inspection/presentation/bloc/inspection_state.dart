import 'package:equatable/equatable.dart';

import '../../../box/domain/entities/box_enums.dart';
import '../../../video_capture/domain/entities/ai_detection.dart';

/// Base class for all inspection states.
///
/// Requirements: 7.1-7.10
abstract class InspectionState extends Equatable {
  const InspectionState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action has been taken.
class InspectionInitial extends InspectionState {
  const InspectionInitial();
}

/// Primary form state holding all mutable form data.
///
/// This state is emitted on every field change, submission attempt,
/// and feedback action. The UI rebuilds only the widgets that depend
/// on changed fields.
///
/// Requirements: 7.1-7.10
class InspectionFormState extends InspectionState {
  const InspectionFormState({
    this.moltingStatus = MoltingStatus.hardShell,
    this.healthStatus = HealthStatus.unknown,
    this.weightText = '',
    this.notes = '',
    this.photoPaths = const [],
    this.aiDetection,
    this.isLoadingContext = false,
    this.isSubmitting = false,
    this.weightError,
    this.submissionError,
    this.isSubmitted = false,
    this.submittedInspectionId,
    this.aiFeedbackSubmitting = false,
    this.aiFeedbackSubmitted,
    this.aiFeedbackError,
    this.agreementRate,
    this.isLoadingAgreementRate = false,
  });

  // ── Form field values ───────────────────────────────────────────────────

  /// Currently selected molting status.
  final MoltingStatus moltingStatus;

  /// Currently selected health condition.
  final HealthStatus healthStatus;

  /// Raw text content of the weight input field.
  final String weightText;

  /// Text content of the optional notes field.
  final String notes;

  /// Local file-system paths of captured/selected photos.
  final List<String> photoPaths;

  // ── AI context ──────────────────────────────────────────────────────────

  /// AI detection result shown at the top of the form for comparison.
  ///
  /// Null when no video ID was provided or when loading failed.
  ///
  /// Requirement 7.1
  final AIDetection? aiDetection;

  /// True while the AI detection context is being fetched.
  final bool isLoadingContext;

  // ── Submission ──────────────────────────────────────────────────────────

  /// True while the inspection is being submitted.
  final bool isSubmitting;

  /// Validation error message for the weight field, if any.
  final String? weightError;

  /// Error message when inspection submission fails.
  final String? submissionError;

  /// True when the inspection was successfully submitted.
  final bool isSubmitted;

  /// Server-assigned or locally-generated ID of the submitted inspection.
  final String? submittedInspectionId;

  // ── AI feedback ─────────────────────────────────────────────────────────

  /// True while AI feedback is being sent.
  final bool aiFeedbackSubmitting;

  /// Null = not yet given, true = operator said Correct, false = Incorrect.
  ///
  /// Requirement 7.8
  final bool? aiFeedbackSubmitted;

  /// Error message when AI feedback submission fails.
  final String? aiFeedbackError;

  /// AI agreement rate for the box in [0.0, 1.0]; null until loaded.
  ///
  /// Displayed as a percentage after submission (Requirement 7.8).
  final double? agreementRate;

  /// True while the agreement rate is being computed.
  final bool isLoadingAgreementRate;

  // ── Computed helpers ────────────────────────────────────────────────────

  /// True when AI detection context has been loaded.
  bool get hasAiContext => aiDetection != null;

  /// True when the weight text parses to a positive number.
  bool get weightIsValid {
    final parsed = double.tryParse(weightText);
    return parsed != null && parsed > 0;
  }

  /// True when the form is ready to submit (not already submitting,
  /// and required fields are valid).
  bool get canSubmit => !isSubmitting && weightIsValid && !isSubmitted;

  /// Maximum number of photos allowed per inspection.
  static const int maxPhotos = 5;

  /// True when the photo limit has been reached.
  bool get photosAtLimit => photoPaths.length >= maxPhotos;

  // ── copyWith ────────────────────────────────────────────────────────────

  /// Creates a copy with the specified fields replaced.
  InspectionFormState copyWith({
    MoltingStatus? moltingStatus,
    HealthStatus? healthStatus,
    String? weightText,
    String? notes,
    List<String>? photoPaths,
    AIDetection? aiDetection,
    bool clearAiDetection = false,
    bool? isLoadingContext,
    bool? isSubmitting,
    String? weightError,
    bool clearWeightError = false,
    String? submissionError,
    bool clearSubmissionError = false,
    bool? isSubmitted,
    String? submittedInspectionId,
    bool? aiFeedbackSubmitting,
    bool? aiFeedbackSubmitted,
    bool clearAiFeedbackSubmitted = false,
    String? aiFeedbackError,
    bool clearAiFeedbackError = false,
    double? agreementRate,
    bool clearAgreementRate = false,
    bool? isLoadingAgreementRate,
  }) => InspectionFormState(
    moltingStatus: moltingStatus ?? this.moltingStatus,
    healthStatus: healthStatus ?? this.healthStatus,
    weightText: weightText ?? this.weightText,
    notes: notes ?? this.notes,
    photoPaths: photoPaths ?? this.photoPaths,
    aiDetection: clearAiDetection ? null : (aiDetection ?? this.aiDetection),
    isLoadingContext: isLoadingContext ?? this.isLoadingContext,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    weightError: clearWeightError ? null : (weightError ?? this.weightError),
    submissionError: clearSubmissionError ? null : (submissionError ?? this.submissionError),
    isSubmitted: isSubmitted ?? this.isSubmitted,
    submittedInspectionId: submittedInspectionId ?? this.submittedInspectionId,
    aiFeedbackSubmitting: aiFeedbackSubmitting ?? this.aiFeedbackSubmitting,
    aiFeedbackSubmitted: clearAiFeedbackSubmitted
        ? null
        : (aiFeedbackSubmitted ?? this.aiFeedbackSubmitted),
    aiFeedbackError: clearAiFeedbackError ? null : (aiFeedbackError ?? this.aiFeedbackError),
    agreementRate: clearAgreementRate ? null : (agreementRate ?? this.agreementRate),
    isLoadingAgreementRate: isLoadingAgreementRate ?? this.isLoadingAgreementRate,
  );

  @override
  List<Object?> get props => [
    moltingStatus,
    healthStatus,
    weightText,
    notes,
    photoPaths,
    aiDetection,
    isLoadingContext,
    isSubmitting,
    weightError,
    submissionError,
    isSubmitted,
    submittedInspectionId,
    aiFeedbackSubmitting,
    aiFeedbackSubmitted,
    aiFeedbackError,
    agreementRate,
    isLoadingAgreementRate,
  ];
}

/// Error state emitted when loading AI context fails critically.
///
/// Requirement 21.1
class InspectionLoadError extends InspectionState {
  const InspectionLoadError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
