import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/ai_detection.dart';
import '../../domain/usecases/get_ai_results_usecase.dart';
import '../../domain/repositories/video_repository.dart';
import 'ai_results_event.dart';
import 'ai_results_state.dart';

/// Business Logic Component for AI detection results display.
///
/// Manages fetching, polling, and displaying AI analysis results for a
/// captured video. Also handles operator feedback submission (correct /
/// incorrect) for model improvement (Requirement 6.9).
///
/// State flow:
/// - AiResultsInitial
/// - AiResultsLoading  (initial load)
/// - AiResultsPolling  (waiting for AI service to complete analysis)
/// - AiResultsLoaded   (results ready, may include low-confidence flag)
/// - AiResultsError    (load failed — network, server, or timeout)
/// - FeedbackSubmitting → FeedbackSubmitted | FeedbackError
///
/// When the confidence score is below [AIDetection.lowConfidenceThreshold]
/// (0.70 = 70%), [AiResultsLoaded.requiresManualInspection] is set to
/// true so the UI can prompt the operator (Requirement 6.7).
///
/// Requirements: 6.1-6.10
class AiResultsBloc extends Bloc<AiResultsEvent, AiResultsState> {
  AiResultsBloc({
    required this._getAIResultsUseCase,
    required this._videoRepository,
    required this._logger,
  }) : super(const AiResultsInitial()) {
    on<LoadAIResults>(_onLoadAIResults);
    on<RefreshAIResults>(_onRefreshAIResults);
    on<SubmitFeedback>(_onSubmitFeedback);
    on<RetryVideoUpload>(_onRetryVideoUpload);
  }

  final GetAIResultsUseCase _getAIResultsUseCase;
  final VideoRepository _videoRepository;
  final Logger _logger;

  /// Maximum number of polling attempts while waiting for AI analysis.
  ///
  /// At 5-second intervals × 12 attempts = 60 seconds max (Req 6.1).
  static const int _maxPollingAttempts = 12;

  /// Interval between polling attempts while AI analysis is in progress.
  static const Duration _pollingInterval = Duration(seconds: 5);

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  /// Handles [LoadAIResults] — fetches detection results for a video.
  ///
  /// If the analysis is not yet available, enters the polling loop.
  ///
  /// Requirements: 6.1-6.6
  Future<void> _onLoadAIResults(LoadAIResults event, Emitter<AiResultsState> emit) async {
    emit(const AiResultsLoading());
    await _fetchWithPolling(event.videoId, emit);
  }

  /// Handles [RefreshAIResults] — re-polls for updated results.
  ///
  /// Requirement 6.1
  Future<void> _onRefreshAIResults(RefreshAIResults event, Emitter<AiResultsState> emit) async {
    // Preserve the existing loaded detection during refresh if available.
    if (state is! AiResultsLoaded) {
      emit(const AiResultsLoading());
    }
    await _fetchWithPolling(event.videoId, emit);
  }

  /// Handles [SubmitFeedback] — submits correct/incorrect annotation.
  ///
  /// Requirement 6.9
  Future<void> _onSubmitFeedback(SubmitFeedback event, Emitter<AiResultsState> emit) async {
    // Need a loaded detection to proceed.
    final currentState = state;
    final detection = _extractDetection(currentState);
    if (detection == null) {
      _logger.w(
        'SubmitFeedback dispatched with no loaded detection '
        '(state: $currentState)',
      );
      return;
    }

    emit(FeedbackSubmitting(detection: detection));

    final result = await _videoRepository.submitFeedback(event.detectionId, event.feedbackStatus);

    result.fold(
      (failure) {
        _logger.e('Feedback submission failed: ${failure.message}');
        emit(FeedbackError(detection: detection, message: failure.message));
      },
      (updated) {
        _logger.i(
          'Feedback submitted for detection ${updated.id}: '
          '${updated.feedbackStatus?.value}',
        );
        emit(FeedbackSubmitted(detection: updated));
      },
    );
  }

  /// Handles [RetryVideoUpload] — re-queues a failed video upload.
  ///
  /// Requirement 6.10
  Future<void> _onRetryVideoUpload(RetryVideoUpload event, Emitter<AiResultsState> emit) async {
    _logger.i('Retrying upload for video ${event.videoId}');

    final videoResult = await _videoRepository.getVideoById(event.videoId);

    videoResult.fold(
      (failure) {
        emit(AiResultsError(message: failure.message, videoId: event.videoId, code: failure.code));
      },
      (video) {
        // Re-initiate the upload via the repository's offline queue.
        // The actual upload happens in VideoCaptureBloc; here we just
        // reload results once the video is available.
        add(LoadAIResults(videoId: event.videoId));
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Fetches AI results, entering a polling loop when not yet available.
  ///
  /// Polls up to [_maxPollingAttempts] times at [_pollingInterval] intervals
  /// before emitting an error state (Requirement 6.1: up to 60 seconds).
  Future<void> _fetchWithPolling(String videoId, Emitter<AiResultsState> emit) async {
    for (var attempt = 1; attempt <= _maxPollingAttempts; attempt++) {
      if (isClosed) return;

      final result = await _getAIResultsUseCase(GetAIResultsParams(videoId: videoId));

      final shouldContinue = result.fold(
        (failure) {
          // 'not found' means analysis is still in progress — keep polling.
          final isNotFound =
              failure.code == 'NOT_FOUND' ||
              failure.message.toLowerCase().contains('not found') ||
              failure.message.toLowerCase().contains('not available');

          if (isNotFound && attempt < _maxPollingAttempts) {
            if (!isClosed) {
              emit(AiResultsPolling(attemptCount: attempt));
            }
            return true; // continue polling
          }

          if (!isClosed) {
            emit(AiResultsError(message: failure.message, videoId: videoId, code: failure.code));
          }
          return false; // stop
        },
        (detection) {
          if (!isClosed) {
            emit(
              AiResultsLoaded(
                detection: detection,
                requiresManualInspection: detection.isLowConfidence,
              ),
            );
          }
          _logger.i(
            'AI results loaded for video $videoId — '
            'confidence: ${detection.confidencePercent}% '
            '(lowConf: ${detection.isLowConfidence})',
          );
          return false; // stop — success
        },
      );

      if (!shouldContinue) return;

      // Wait before the next attempt, but stop if the bloc is closed.
      await Future<void>.delayed(_pollingInterval);
    }

    // All attempts exhausted.
    if (!isClosed) {
      emit(
        AiResultsError(
          message:
              'AI analysis is taking longer than expected. '
              'Please try again in a few minutes.',
          videoId: videoId,
          code: 'ANALYSIS_TIMEOUT',
        ),
      );
    }
  }

  /// Extracts the [AIDetection] from a state that holds one, or null.
  AIDetection? _extractDetection(AiResultsState currentState) {
    if (currentState is AiResultsLoaded) return currentState.detection;
    if (currentState is FeedbackSubmitting) return currentState.detection;
    if (currentState is FeedbackSubmitted) return currentState.detection;
    if (currentState is FeedbackError) return currentState.detection;
    return null;
  }
}
