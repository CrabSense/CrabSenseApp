import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

/// Parameters for [CaptureVideoUseCase].
class CaptureVideoParams {
  const CaptureVideoParams({
    required this.boxId,
    required this.capturedBy,
    required this.localPath,
    required this.durationSeconds,
    this.fileSizeBytes,
  });

  /// The identifier of the box being recorded (Requirement 5.10).
  final String boxId;

  /// Identifier of the field operator performing the capture.
  final String capturedBy;

  /// Absolute path to the recorded video file on the device.
  final String localPath;

  /// Duration of the recording in seconds.
  ///
  /// Must be between [Video.minDurationSeconds] and
  /// [Video.maxDurationSeconds] (Requirement 5.2).
  final int durationSeconds;

  /// Compressed file size in bytes.
  ///
  /// When provided, must be ≤ [Video.maxFileSizeBytes] (Requirement 5.4).
  final int? fileSizeBytes;
}

/// Use case for persisting a newly captured video to local storage.
///
/// Business rules enforced:
/// 1. [boxId] must not be empty — the video must be linked to a box
///    (Requirement 5.10).
/// 2. [capturedBy] must not be empty — records the operator identity.
/// 3. [localPath] must not be empty — the file must exist on-device.
/// 4. [durationSeconds] must be in the valid 5–10 second range
///    (Requirement 5.2).
/// 5. [fileSizeBytes], if provided, must be ≤ 10 MB (Requirement 5.4).
/// 6. Storage availability is checked before attempting to save
///    (Requirement 5.9).
///
/// The new video is saved locally with [VideoStatus.pending] so the
/// upload use case can pick it up when a network connection is available.
///
/// Requirements: 5.1-5.10
class CaptureVideoUseCase {
  const CaptureVideoUseCase(this._repository);

  final VideoRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - Right(Video): Saved video record with status [VideoStatus.pending]
  /// - Left(ValidationFailure): Input validation failed
  /// - Left(PermissionFailure): Storage permission not granted
  /// - Left(CacheFailure): Failed to persist to local storage
  Future<Either<Failure, Video>> call(CaptureVideoParams params) async {
    // Validate boxId
    if (params.boxId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Box ID'));
    }

    // Validate capturedBy
    if (params.capturedBy.trim().isEmpty) {
      return const Left(ValidationFailure.required('Captured By'));
    }

    // Validate localPath
    if (params.localPath.trim().isEmpty) {
      return const Left(ValidationFailure.required('Local Path'));
    }

    // Validate recording duration (Requirement 5.2)
    if (params.durationSeconds < Video.minDurationSeconds ||
        params.durationSeconds > Video.maxDurationSeconds) {
      return const Left(
        ValidationFailure.outOfRange(
          fieldName: 'Duration',
          min: '${Video.minDurationSeconds}s',
          max: '${Video.maxDurationSeconds}s',
        ),
      );
    }

    // Validate file size if provided (Requirement 5.4)
    if (params.fileSizeBytes != null && params.fileSizeBytes! > Video.maxFileSizeBytes) {
      return const Left(
        ValidationFailure(
          'Video file exceeds maximum allowed size of 10 MB. '
          'Please compress the video before uploading.',
          code: 'VIDEO_FILE_TOO_LARGE',
        ),
      );
    }

    // Check storage availability (Requirement 5.9)
    final storageResult = await _repository.hassufficientStorage();
    final hasStorage = storageResult.fold(
      (failure) => null, // propagate failure below
      (available) => available,
    );
    if (hasStorage == null) {
      return storageResult.map((_) => throw StateError('unreachable'));
    }
    if (!hasStorage) {
      return const Left(CacheFailure.quotaExceeded());
    }

    // Build the Video entity with pending status
    final video = Video(
      id: '', // Server/local DB will assign the real ID
      boxId: params.boxId,
      localPath: params.localPath,
      durationSeconds: params.durationSeconds,
      fileSizeBytes: params.fileSizeBytes,
      status: VideoStatus.pending,
      capturedAt: DateTime.now(),
      capturedBy: params.capturedBy,
    );

    return _repository.saveVideoLocally(video);
  }
}
