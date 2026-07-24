import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

/// Parameters for [UploadVideoUseCase].
class UploadVideoParams {
  const UploadVideoParams({required this.videoId, this.onProgress});

  /// The unique identifier of the video to upload.
  final String videoId;

  /// Optional progress callback invoked during upload.
  ///
  /// Receives a value in [0.0, 1.0] representing upload completion.
  /// Requirement 5.5.
  final void Function(double progress)? onProgress;
}

/// Use case for uploading a locally stored video to the AI service.
///
/// Business rules enforced:
/// 1. [videoId] must not be empty.
/// 2. Only videos with [VideoStatus.pending] or [VideoStatus.failed] may
///    be uploaded (idempotency guard — prevents re-uploading an already
///    uploaded video).
/// 3. Delegates to [VideoRepository.uploadVideo] which handles:
///    - Network availability detection
///    - Status transitions (pending → uploading → uploaded / failed)
///    - Exponential back-off retry tracking via [Video.retryCount]
///      (Requirement 6.10)
///    - Offline queuing when no network is available (Requirement 5.6)
///
/// The use case returns the updated [Video] entity on success, letting the
/// caller (e.g. a BLoC) drive UI state transitions.
///
/// Requirements: 5.5, 5.6, 5.9, 6.10
class UploadVideoUseCase {
  const UploadVideoUseCase(this._repository);

  final VideoRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - Right(Video): Updated record with [VideoStatus.uploaded]
  /// - Left(ValidationFailure): [videoId] is empty or video is already
  ///   uploaded
  /// - Left(NetworkFailure): No internet connection (video remains queued)
  /// - Left(ServerFailure): AI service returned an error
  /// - Left(CacheFailure): Failed to read/update local record
  Future<Either<Failure, Video>> call(UploadVideoParams params) async {
    // Validate videoId
    if (params.videoId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Video ID'));
    }

    // Fetch the video record to check its current status
    final videoResult = await _repository.getVideoById(params.videoId);
    return videoResult.fold(Left.new, (video) async {
      // Guard: only upload videos that still need uploading
      if (!video.status.needsUpload) {
        return Left(
          ValidationFailure(
            'Video "${params.videoId}" has already been uploaded '
            'and cannot be re-uploaded.',
            code: 'VIDEO_ALREADY_UPLOADED',
          ),
        );
      }

      // Delegate to repository — handles network, progress, retry logic
      return _repository.uploadVideo(params.videoId, onProgress: params.onProgress);
    });
  }
}
