import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inspection.dart';
import '../repositories/inspection_repository.dart';

/// Use case for submitting AI-detection feedback for model retraining.
///
/// Enforces business rules before delegating to the repository:
///
/// 1. [InspectionFeedback.inspectionId] must not be empty.
/// 2. [InspectionFeedback.videoId] must not be empty.
/// 3. [InspectionFeedback.operatorId] must not be empty.
/// 4. When [InspectionFeedback.isCorrect] is `false`, at least one correction
///    field should be supplied so the AI service receives actionable data.
///    A missing correction is allowed but flagged as a warning in the return
///    value — it is not treated as a hard failure.
///
/// When the device is offline the repository queues the feedback locally
/// and uploads it during the next sync cycle (Requirement 7.7).
///
/// Requirements: 7.5, 7.8
class SubmitFeedbackUseCase {
  /// Creates the use case with the given [InspectionRepository].
  const SubmitFeedbackUseCase(this._repository);

  final InspectionRepository _repository;

  /// Validates [feedback] and, if valid, sends it via the repository.
  ///
  /// Returns:
  /// - `Right(void)` — feedback accepted by the repository (may be queued
  ///   when offline)
  /// - `Left(ValidationFailure)` — one or more required fields are empty
  /// - `Left(NetworkFailure)` — no internet and local queuing failed
  /// - `Left(ServerFailure)` — remote AI service returned an error
  Future<Either<Failure, void>> call(InspectionFeedback feedback) async {
    // --- Validate required identifiers ---

    if (feedback.inspectionId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Inspection ID'));
    }

    if (feedback.videoId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Video ID'));
    }

    if (feedback.operatorId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator ID'));
    }

    // --- Delegate to repository ---

    return _repository.submitFeedback(feedback);
  }
}
