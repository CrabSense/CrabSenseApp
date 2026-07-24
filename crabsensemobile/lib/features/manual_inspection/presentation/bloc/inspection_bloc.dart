import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../manual_inspection/domain/entities/inspection.dart';
import '../../../manual_inspection/domain/repositories/inspection_repository.dart';
import '../../../manual_inspection/domain/usecases/submit_feedback_use_case.dart';
import '../../../manual_inspection/domain/usecases/submit_inspection_use_case.dart';
import '../../../video_capture/domain/usecases/get_ai_results_usecase.dart';
import 'inspection_event.dart';
import 'inspection_state.dart';

/// Business Logic Component for the manual inspection form.
///
/// Manages all form state: field updates, validation, photo management,
/// AI context loading, inspection submission, AI feedback, and agreement
/// rate tracking.
///
/// State flow:
/// - InspectionInitial
/// - InspectionFormState (main state for all form interactions)
///   - isLoadingContext: true while fetching AI detection
///   - isSubmitting: true while sending inspection to repository
///   - isSubmitted: true after successful submission
///   - aiFeedbackSubmitting/Submitted: feedback lifecycle
///   - agreementRate: AI vs manual agreement percentage (Req 7.8)
/// - InspectionLoadError (if critical context load failure)
///
/// Requirements: 7.1-7.10
class InspectionBloc extends Bloc<InspectionEvent, InspectionState> {
  InspectionBloc({
    required this._submitInspection,
    required this._submitFeedback,
    required this._repository,
    required this._logger,
    this._getAiResults,
  }) : super(const InspectionInitial()) {
    on<LoadInspectionContext>(_onLoadContext);
    on<UpdateMoltingStatus>(_onUpdateMolting);
    on<UpdateHealthStatus>(_onUpdateHealth);
    on<UpdateWeight>(_onUpdateWeight);
    on<UpdateNotes>(_onUpdateNotes);
    on<AddPhoto>(_onAddPhoto);
    on<RemovePhoto>(_onRemovePhoto);
    on<SubmitInspection>(_onSubmit);
    on<SubmitAiFeedback>(_onSubmitFeedback);
    on<LoadAgreementRate>(_onLoadAgreementRate);
    on<ResetInspectionForm>(_onReset);
  }

  final SubmitInspectionUseCase _submitInspection;
  final SubmitFeedbackUseCase _submitFeedback;
  final InspectionRepository _repository;
  final Logger _logger;
  final GetAIResultsUseCase? _getAiResults;

  static const _uuid = Uuid();

  // ── Event Handlers ───────────────────────────────────────────────────────

  /// Loads the AI detection context if a [videoId] was provided.
  ///
  /// Emits [InspectionFormState] with loading indicator while fetching,
  /// then populates [InspectionFormState.aiDetection] on success.
  /// On failure it logs a warning and continues without AI context.
  ///
  /// Requirement 7.1
  Future<void> _onLoadContext(LoadInspectionContext event, Emitter<InspectionState> emit) async {
    final videoId = event.videoId;

    if (videoId == null || videoId.isEmpty || _getAiResults == null) {
      // No video context — open form without AI comparison.
      emit(const InspectionFormState());
      return;
    }

    emit(const InspectionFormState(isLoadingContext: true));

    final result = await _getAiResults(GetAIResultsParams(videoId: videoId));

    result.fold(
      (failure) {
        _logger.w(
          'InspectionBloc: failed to load AI context for video '
          '$videoId — ${failure.message}',
        );
        // Continue without AI context rather than blocking the form.
        emit(const InspectionFormState());
      },
      (detection) {
        emit(InspectionFormState(aiDetection: detection));
      },
    );
  }

  /// Updates the selected molting status.
  ///
  /// Requirement 7.2
  void _onUpdateMolting(UpdateMoltingStatus event, Emitter<InspectionState> emit) {
    final current = _formState;
    if (current == null) return;
    emit(current.copyWith(moltingStatus: event.status));
  }

  /// Updates the selected health condition.
  ///
  /// Requirement 7.2
  void _onUpdateHealth(UpdateHealthStatus event, Emitter<InspectionState> emit) {
    final current = _formState;
    if (current == null) return;
    emit(current.copyWith(healthStatus: event.status));
  }

  /// Updates the weight text and clears any prior validation error.
  ///
  /// Requirement 7.2
  void _onUpdateWeight(UpdateWeight event, Emitter<InspectionState> emit) {
    final current = _formState;
    if (current == null) return;
    emit(current.copyWith(weightText: event.value, clearWeightError: true));
  }

  /// Updates the notes field.
  void _onUpdateNotes(UpdateNotes event, Emitter<InspectionState> emit) {
    final current = _formState;
    if (current == null) return;
    emit(current.copyWith(notes: event.notes));
  }

  /// Appends a new photo path (up to [InspectionFormState.maxPhotos]).
  ///
  /// Requirement 7.3
  void _onAddPhoto(AddPhoto event, Emitter<InspectionState> emit) {
    final current = _formState;
    if (current == null || current.photosAtLimit) return;
    emit(current.copyWith(photoPaths: [...current.photoPaths, event.photoPath]));
  }

  /// Removes the photo at the specified index.
  ///
  /// Requirement 7.3
  void _onRemovePhoto(RemovePhoto event, Emitter<InspectionState> emit) {
    final current = _formState;
    if (current == null) return;
    final updated = List<String>.from(current.photoPaths);
    if (event.index >= 0 && event.index < updated.length) {
      updated.removeAt(event.index);
      emit(current.copyWith(photoPaths: updated));
    }
  }

  /// Validates form fields and submits the inspection to the repository.
  ///
  /// Validates weight before submission (Requirement 7.4).
  /// On success emits [isSubmitted: true] (Requirement 7.6, 7.7).
  /// On failure emits the error message (Requirement 21.1).
  ///
  /// Requirements: 7.4-7.7, 7.9
  Future<void> _onSubmit(SubmitInspection event, Emitter<InspectionState> emit) async {
    final current = _formState;
    if (current == null) return;

    // Validate weight field.
    final parsedWeight = double.tryParse(current.weightText);
    if (parsedWeight == null || parsedWeight <= 0) {
      emit(current.copyWith(weightError: 'Please enter a valid weight greater than 0'));
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearSubmissionError: true));

    final inspection = Inspection(
      id: _uuid.v4(),
      boxId: event.boxId,
      relatedVideoId: current.aiDetection?.videoId,
      moltingStatus: current.moltingStatus,
      healthStatus: current.healthStatus,
      weight: parsedWeight,
      notes: current.notes,
      photoUrls: current.photoPaths,
      timestamp: DateTime.now().toUtc(),
      operatorId: event.operatorId,
      operatorName: event.operatorName,
      aiAgreement: current.aiFeedbackSubmitted,
      syncStatus: SyncStatus.pending,
    );

    final result = await _submitInspection(inspection);

    result.fold(
      (failure) {
        _logger.e('InspectionBloc: submission failed — ${failure.message}');
        final formState = _formState;
        if (formState != null) {
          emit(
            formState.copyWith(isSubmitting: false, submissionError: _userFriendlyError(failure)),
          );
        }
      },
      (saved) {
        _logger.i('InspectionBloc: inspection submitted — ${saved.id}');
        final formState = _formState;
        if (formState != null) {
          emit(
            formState.copyWith(
              isSubmitting: false,
              isSubmitted: true,
              submittedInspectionId: saved.id,
              clearSubmissionError: true,
            ),
          );
        }
        // Immediately load the agreement rate so the UI can display it
        // (Requirement 7.8).
        add(LoadAgreementRate(boxId: event.boxId));
      },
    );
  }

  /// Sends AI feedback (Correct/Incorrect) to the AI service.
  ///
  /// When the device is offline the repository queues the feedback in the
  /// SyncQueue table for later upload (Requirements 7.5, 7.7).
  ///
  /// Requirements: 7.5, 7.8
  Future<void> _onSubmitFeedback(SubmitAiFeedback event, Emitter<InspectionState> emit) async {
    final current = _formState;
    if (current == null) return;

    emit(current.copyWith(aiFeedbackSubmitting: true, clearAiFeedbackError: true));

    final feedback = InspectionFeedback(
      inspectionId: event.inspectionId,
      videoId: event.videoId,
      isCorrect: event.isCorrect,
      submittedAt: DateTime.now().toUtc(),
      operatorId: event.operatorId,
      correctedMoltingStatus: event.isCorrect ? null : current.moltingStatus,
      correctedHealthStatus: event.isCorrect ? null : current.healthStatus,
    );

    final result = await _submitFeedback(feedback);

    result.fold(
      (failure) {
        _logger.w(
          'InspectionBloc: AI feedback submission failed — '
          '${failure.message}',
        );
        final formState = _formState;
        if (formState != null) {
          emit(
            formState.copyWith(
              aiFeedbackSubmitting: false,
              aiFeedbackError: _userFriendlyError(failure),
            ),
          );
        }
      },
      (_) {
        _logger.i(
          'InspectionBloc: AI feedback submitted — '
          'correct=${event.isCorrect}',
        );
        final formState = _formState;
        if (formState != null) {
          emit(
            formState.copyWith(
              aiFeedbackSubmitting: false,
              aiFeedbackSubmitted: event.isCorrect,
              clearAiFeedbackError: true,
            ),
          );
        }
      },
    );
  }

  /// Loads the AI vs manual agreement rate for the box.
  ///
  /// Dispatched automatically after a successful inspection submission.
  /// The rate is computed from local inspection history (Requirement 7.8).
  Future<void> _onLoadAgreementRate(LoadAgreementRate event, Emitter<InspectionState> emit) async {
    final current = _formState;
    if (current == null) return;

    emit(current.copyWith(isLoadingAgreementRate: true));

    final result = await _repository.getAgreementRate(event.boxId);

    result.fold(
      (failure) {
        _logger.w(
          'InspectionBloc: failed to load agreement rate — '
          '${failure.message}',
        );
        final formState = _formState;
        if (formState != null) {
          emit(formState.copyWith(isLoadingAgreementRate: false));
        }
      },
      (rate) {
        final formState = _formState;
        if (formState != null) {
          emit(formState.copyWith(agreementRate: rate, isLoadingAgreementRate: false));
        }
      },
    );
  }

  /// Resets the form to its initial state.
  void _onReset(ResetInspectionForm event, Emitter<InspectionState> emit) {
    emit(const InspectionInitial());
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Returns the current state as [InspectionFormState], or null if not set.
  InspectionFormState? get _formState =>
      state is InspectionFormState ? state as InspectionFormState : null;

  /// Converts a [Failure] to a user-friendly message string.
  String _userFriendlyError(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No internet connection. Your data has been saved locally '
          'and will sync automatically when you are back online.';
    }
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is ServerFailure) {
      return 'Server error (${failure.statusCode}). Please try again.';
    }
    return failure.message;
  }
}
