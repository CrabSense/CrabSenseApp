import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ai_detection.dart';
import '../entities/video.dart';

/// Repository interface for video capture and AI analysis operations.
///
/// Defines the contract for all video-related data operations following
/// Clean Architecture principles. The domain layer depends only on this
/// abstraction; concrete implementations live in the data layer.
///
/// Implementations must handle:
/// - Remote upload to the AI service via REST API
/// - Local persistence via SQLite (drift) for offline-first support
/// - Offline-first: store video locally when offline, upload when online
/// - Error mapping to domain [Failure] types
///
/// All methods return `Either<Failure, T>`:
/// - `Left(Failure)` — operation failed with a specific failure reason
/// - `Right(T)` — operation succeeded with the result data
///
/// Requirements: 5.1-5.10, 6.1-6.10
abstract class VideoRepository {
  /// Persists a new [Video] record locally after recording.
  ///
  /// The local path is stored so the video can be uploaded later when
  /// a network connection is available (Requirement 5.6).
  ///
  /// Returns:
  /// - Right(Video): Saved record (with local ID)
  /// - Left(CacheFailure): Failed to write to local storage
  /// - Left(ValidationFailure): Video data failed domain validation
  ///
  /// Requirements: 5.6, 5.10
  Future<Either<Failure, Video>> saveVideoLocally(Video video);

  /// Retrieves a single video by its unique identifier.
  ///
  /// Returns:
  /// - Right(Video): Video record found
  /// - Left(ServerFailure.notFound): Video with [videoId] does not exist
  /// - Left(CacheFailure): Failed to read from local storage
  ///
  /// Requirements: 5.1
  Future<Either<Failure, Video>> getVideoById(String videoId);

  /// Retrieves all video records associated with a given box.
  ///
  /// Results are ordered by [Video.capturedAt] descending (newest first).
  ///
  /// Returns:
  /// - Right(List): Video records for the box (may be empty)
  /// - Left(NetworkFailure): No internet and no cached data
  /// - Left(CacheFailure): Failed to read from local storage
  ///
  /// Requirements: 5.10, 6.8
  Future<Either<Failure, List<Video>>> getVideosByBox(String boxId);

  /// Retrieves all videos that are pending upload.
  ///
  /// Used by the sync service to process the offline queue
  /// (Requirements 5.6, 13.4).
  ///
  /// Returns:
  /// - Right(List): Videos with status [VideoStatus.pending] or
  ///   [VideoStatus.failed] (may be empty)
  /// - Left(CacheFailure): Failed to read from local storage
  ///
  /// Requirements: 5.6, 13.4
  Future<Either<Failure, List<Video>>> getPendingUploadVideos();

  /// Uploads a video file to the AI service and updates its status.
  ///
  /// The repository implementation is responsible for:
  /// - Sending the compressed file to the AI upload endpoint
  /// - Updating the local record's [VideoStatus] to [VideoStatus.uploading]
  ///   then [VideoStatus.uploaded] on success
  /// - Incrementing [Video.retryCount] and marking [VideoStatus.failed] on
  ///   error (retry with exponential back-off, Requirement 6.10)
  ///
  /// Returns:
  /// - Right(Video): Updated record with [VideoStatus.uploaded] status
  /// - Left(NetworkFailure): No internet connection
  /// - Left(ServerFailure): AI service returned an error
  /// - Left(CacheFailure): Failed to update local record
  ///
  /// Requirements: 5.5, 5.6, 5.9, 6.10
  Future<Either<Failure, Video>> uploadVideo(
    String videoId, {
    void Function(double progress)? onProgress,
  });

  /// Updates a video record (e.g. after compression or status change).
  ///
  /// Returns:
  /// - Right(Video): Updated record
  /// - Left(CacheFailure): Failed to update local storage
  /// - Left(ServerFailure.notFound): Video does not exist
  ///
  /// Requirements: 5.4
  Future<Either<Failure, Video>> updateVideo(Video video);

  /// Retrieves the AI detection result for a specific video.
  ///
  /// Checks local cache first; falls back to the AI service endpoint.
  ///
  /// Returns:
  /// - Right(AIDetection): Detection result found
  /// - Left(ServerFailure.notFound): No result available yet
  /// - Left(NetworkFailure): No internet and no cached result
  /// - Left(ServerFailure): AI service returned an error
  ///
  /// Requirements: 6.1, 6.8
  Future<Either<Failure, AIDetection>> getAIResults(String videoId);

  /// Retrieves all AI detection results for a given box.
  ///
  /// Results are ordered by [AIDetection.analyzedAt] descending.
  ///
  /// Returns:
  /// - Right(List): Detection history (may be empty)
  /// - Left(NetworkFailure): No internet and no cached data
  /// - Left(CacheFailure): Failed to read from local storage
  ///
  /// Requirements: 6.8
  Future<Either<Failure, List<AIDetection>>> getAIResultsByBox(String boxId);

  /// Submits operator feedback on an AI detection result.
  ///
  /// The feedback is sent to the AI service for model retraining and stored
  /// locally. When offline the update is queued for later sync.
  ///
  /// Returns:
  /// - Right(AIDetection): Updated detection with the feedback status set
  /// - Left(ServerFailure.notFound): Detection result does not exist
  /// - Left(NetworkFailure): No internet (queued for sync)
  ///
  /// Requirements: 6.9
  Future<Either<Failure, AIDetection>> submitFeedback(
    String detectionId,
    DetectionFeedbackStatus feedbackStatus,
  );

  /// Checks whether the device has enough free storage to record a video.
  ///
  /// Returns:
  /// - Right(true): Sufficient storage available
  /// - Right(false): Insufficient storage
  /// - Left(PermissionFailure): Storage permission not granted
  ///
  /// Requirement 5.9
  Future<Either<Failure, bool>> hassufficientStorage();

  /// Compresses and uploads a video, handling the offline queue case.
  ///
  /// The operation proceeds as follows:
  /// 1. Compresses the video at [videoPath] to under 10 MB (Req 5.4).
  /// 2. Associates the result with [boxId] (Req 5.10).
  /// 3. If online: uploads with progress tracking and exponential back-off
  ///    on failure (max 4 attempts; delays 1s, 2s, 4s, 8s).
  /// 4. If offline: queues the compressed video in local storage for later
  ///    synchronisation (Req 5.6).
  ///
  /// [onCompressionProgress] receives values in [0.0, 1.0] during compression.
  /// [onUploadProgress] receives values in [0.0, 1.0] during upload.
  ///
  /// Returns:
  /// - Right(Video): Uploaded record (status = uploaded) when online and
  ///   upload succeeded.
  /// - Right(Video): Queued record (status = pending) when offline or when
  ///   video was queued for later sync.
  /// - Left(ServerFailure): Compression failed.
  /// - Left(NetworkFailure): Upload failed after all retries.
  /// - Left(CacheFailure): Failed to persist video locally.
  ///
  /// Requirements: 5.4, 5.5, 5.6, 5.10, 22.7
  Future<Either<Failure, Video>> compressAndUploadVideo(
    String videoId,
    String videoPath,
    String boxId,
    String capturedBy,
    int durationSeconds, {
    void Function(double progress)? onCompressionProgress,
    void Function(double progress)? onUploadProgress,
  });

  /// Returns a stream that emits an updated [Video] whenever its state
  /// changes (e.g. status transitions from uploading → uploaded).
  ///
  /// The stream emits the latest cached value immediately on subscription.
  ///
  /// Requirements: 5.5, 5.6
  Stream<Video> watchVideo(String videoId);
}
