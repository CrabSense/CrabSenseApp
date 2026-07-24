import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ai_detection.dart';
import '../repositories/video_repository.dart';

/// Parameters for [GetAIResultsUseCase].
class GetAIResultsParams {
  const GetAIResultsParams({required this.videoId});

  /// The unique identifier of the video whose AI analysis is requested.
  final String videoId;
}

/// Use case for fetching the AI detection result for a specific video.
///
/// Business rules enforced:
/// 1. [videoId] must not be empty.
/// 2. Delegates to [VideoRepository.getAIResults] which checks the local
///    cache first, then falls back to the AI service endpoint.
/// 3. A low-confidence result (score < 0.70) is surfaced to the caller
///    via [AIDetection.isLowConfidence] so the presentation layer can
///    prompt for manual inspection (Requirement 6.7).
///
/// Note: Waiting for the AI service to complete analysis (up to 60 seconds,
/// Requirement 6.1) is handled at the presentation/polling layer, not here.
/// This use case retrieves a result that is already available.
///
/// Requirements: 6.1-6.10
class GetAIResultsUseCase {
  const GetAIResultsUseCase(this._repository);

  final VideoRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - Right(AIDetection): Detection result for the given [videoId]
  /// - Left(ValidationFailure): [videoId] is empty
  /// - Left(ServerFailure.notFound): No result available yet
  /// - Left(NetworkFailure): No internet and no cached result
  /// - Left(ServerFailure): AI service returned an error
  Future<Either<Failure, AIDetection>> call(GetAIResultsParams params) async {
    if (params.videoId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Video ID'));
    }

    return _repository.getAIResults(params.videoId);
  }
}
