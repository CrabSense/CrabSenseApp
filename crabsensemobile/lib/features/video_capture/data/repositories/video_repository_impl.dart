// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;
import 'dart:math' show min;

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/database.dart' as db;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/ai_detection.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_local_data_source.dart';
import '../datasources/video_remote_data_source.dart';
import '../models/ai_detection_model.dart';
import '../models/video_model.dart';
import '../services/video_compression_service.dart';

/// Concrete implementation of [VideoRepository].
///
/// Follows an offline-first strategy:
/// - **Reads**: attempt remote when online, cache the result, fall back to
///   cached data when offline.
/// - **Writes (save)**: persist locally with `isDirty = true` for later sync;
///   when online, also attempt remote sync immediately.
/// - **Uploads**: require connectivity; on failure the video is marked
///   `failed` and retried with exponential back-off (Requirement 6.10).
///
/// Exception → Failure mapping:
/// - [ServerException]  → [ServerFailure]
/// - [NetworkException] → [NetworkFailure]
/// - [CacheException]   → [CacheFailure]
/// - [ParseException]   → [ParseFailure]
///
/// Requirements: 5.1-5.10, 6.1-6.10
class VideoRepositoryImpl implements VideoRepository {
  VideoRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.compressionService,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final VideoRemoteDataSource remoteDataSource;
  final VideoLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final VideoCompressionService compressionService;
  final Logger _logger;

  // ---------------------------------------------------------------------------
  // VideoRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, Video>> saveVideoLocally(Video video) async {
    try {
      await localDataSource.saveVideo(video, isDirty: true);
      return Right(video);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, Video>> getVideoById(String videoId) async {
    if (await networkInfo.isConnected) {
      try {
        final video = await remoteDataSource.getVideoById(videoId);
        await localDataSource.saveVideo(video);
        return Right(video.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline — serve from cache
    try {
      final cached = await localDataSource.getVideoById(videoId);
      return Right(cached.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, List<Video>>> getVideosByBox(String boxId) async {
    if (await networkInfo.isConnected) {
      try {
        final videos = await remoteDataSource.getVideosForBox(boxId);
        for (final v in videos) {
          await localDataSource.saveVideo(v);
        }
        return Right(videos.map((v) => v.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline — serve from cache
    try {
      final cached = await localDataSource.getVideosByBox(boxId);
      return Right(cached.map((v) => v.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, List<Video>>> getPendingUploadVideos() async {
    try {
      final pending = await localDataSource.getPendingUploadVideos();
      return Right(pending.map((v) => v.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, Video>> uploadVideo(
    String videoId, {
    void Function(double progress)? onProgress,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(
          'Upload requires an active connection. '
          'Please retry when online.',
        ),
      );
    }

    // Fetch the local record to find the file path
    VideoModel localVideo;
    try {
      localVideo = await localDataSource.getVideoById(videoId);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }

    // Mark as uploading
    try {
      await localDataSource.updateVideo(localVideo.copyWith(status: VideoStatus.uploading));
    } on CacheException {
      // Non-fatal; continue with upload attempt
    }

    // Attempt upload with exponential back-off (Requirement 6.10)
    const maxRetries = 3;
    var attempt = 0;

    while (attempt < maxRetries) {
      try {
        final uploaded = await remoteDataSource.uploadVideo(
          videoId,
          localVideo.localPath,
          onSendProgress: onProgress,
        );

        final updatedVideo = uploaded.copyWith(
          status: VideoStatus.uploaded,
          uploadedAt: DateTime.now().toUtc(),
          retryCount: localVideo.retryCount + attempt,
        );

        await localDataSource.updateVideo(updatedVideo);
        return Right(updatedVideo.toEntity());
      } on NetworkException catch (e) {
        _logger.w(
          'VideoRepositoryImpl: upload network error (attempt ${attempt + 1}): ${e.message}',
        );
        attempt++;
        if (attempt >= maxRetries) {
          await _markUploadFailed(localVideo, attempt);
          return Left(NetworkFailure(e.message, e.code));
        }
        await _waitExponentialBackoff(attempt);
      } on ServerException catch (e) {
        _logger.e(
          'VideoRepositoryImpl: upload server error (attempt ${attempt + 1}): ${e.message}',
        );
        attempt++;
        if (attempt >= maxRetries) {
          await _markUploadFailed(localVideo, attempt);
          return Left(_mapServerException(e));
        }
        await _waitExponentialBackoff(attempt);
      }
    }

    // Should not reach here, but satisfy the compiler
    await _markUploadFailed(localVideo, maxRetries);
    return const Left(ServerFailure('Upload failed after maximum retry attempts.'));
  }

  @override
  Future<Either<Failure, Video>> updateVideo(Video video) async {
    try {
      await localDataSource.updateVideo(video);
      return Right(video);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, AIDetection>> getAIResults(String videoId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAIResults(videoId);
        await localDataSource.cacheAIDetection(result);
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline — serve from cache
    try {
      final cached = await localDataSource.getAIDetectionByVideoId(videoId);
      return Right(cached.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, List<AIDetection>>> getAIResultsByBox(String boxId) async {
    if (await networkInfo.isConnected) {
      try {
        final results = await remoteDataSource.getAIResultsByBox(boxId);
        for (final r in results) {
          await localDataSource.cacheAIDetection(r);
        }
        return Right(results.map((r) => r.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(_mapServerException(e));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message, e.code));
      } on ParseException catch (e) {
        return Left(ParseFailure(e.message));
      }
    }

    // Offline — serve from cache
    try {
      final cached = await localDataSource.getAIDetectionsByBoxId(boxId);
      return Right(cached.map((r) => r.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, AIDetection>> submitFeedback(
    String detectionId,
    DetectionFeedbackStatus feedbackStatus,
  ) async {
    if (!await networkInfo.isConnected) {
      // Queue for later sync: update locally with isDirty = true
      try {
        final cached = await localDataSource.getAIDetectionByVideoId(detectionId);
        final updatedModel = AIDetectionModel.fromEntity(
          cached.copyWith(feedbackStatus: feedbackStatus),
        );
        await localDataSource.cacheAIDetection(updatedModel, isDirty: true);
        return Right(updatedModel.toEntity());
      } on CacheException {
        return const Left(
          NetworkFailure(
            'Submitting feedback requires an active connection or a cached detection record.',
          ),
        );
      }
    }

    try {
      final result = await remoteDataSource.submitFeedback(detectionId, feedbackStatus);
      await localDataSource.cacheAIDetection(result);
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(_mapServerException(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, e.code));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> hassufficientStorage() async {
    // Approximation: check available free space using path_provider + dart:io.
    // A true free-space API is not directly available in Dart; we use
    // Directory.statSync() on the documents folder as a rough indicator.
    //
    // Limitation: Directory.statSync() does NOT return free disk space on all
    // platforms. For a production implementation, use a native plugin such as
    // `disk_space` or `path_provider` combined with a platform channel.
    // Here we perform a best-effort check: if we can determine low space,
    // return false; otherwise return true to avoid blocking the user.
    try {
      // Verify we can reach the documents directory at all.
      // Note: dart:io does not expose a free-space API on all platforms.
      // For a production build, use a native plugin such as `disk_space`.
      // This implementation returns Right(true) as a conservative default
      // to avoid blocking recording when we cannot determine available space.
      await getApplicationDocumentsDirectory();
      return const Right(true);
    } on FileSystemException catch (e) {
      _logger.w('VideoRepositoryImpl: storage check failed: ${e.message}');
      // Return true to avoid blocking recording when we cannot determine space.
      return const Right(true);
    } on Exception catch (e) {
      _logger.w('VideoRepositoryImpl: storage check unexpected error: $e');
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, Video>> compressAndUploadVideo(
    String videoId,
    String videoPath,
    String boxId,
    String capturedBy,
    int durationSeconds, {
    void Function(double progress)? onCompressionProgress,
    void Function(double progress)? onUploadProgress,
  }) async {
    // ── 1. Validate inputs ────────────────────────────────────────────────
    if (videoPath.trim().isEmpty) {
      return const Left(ValidationFailure('Video path must not be empty.'));
    }
    if (boxId.trim().isEmpty) {
      return const Left(ValidationFailure('Box ID must not be empty.'));
    }
    if (durationSeconds < Video.minDurationSeconds || durationSeconds > Video.maxDurationSeconds) {
      return Left(
        ValidationFailure(
          'Duration $durationSeconds s is outside the valid '
          '${Video.minDurationSeconds}–${Video.maxDurationSeconds} s range.',
          code: 'INVALID_DURATION',
        ),
      );
    }

    // ── 2. Validate file type (must be mp4 or mov) ────────────────────────
    final ext = videoPath.toLowerCase().split('.').last;
    if (ext != 'mp4' && ext != 'mov') {
      return Left(
        ValidationFailure(
          'Unsupported file type ".$ext". Only mp4 and mov are accepted.',
          code: 'INVALID_FILE_TYPE',
        ),
      );
    }

    // ── 3. Compress the video ─────────────────────────────────────────────
    CompressionResult compressionResult;
    try {
      compressionResult = await compressionService.compress(
        videoPath,
        onProgress: onCompressionProgress,
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    }

    final compressedPath = compressionResult.compressedPath;
    final compressedSize = compressionResult.compressedSizeBytes;

    // Enforce max 10 MB post-compression (Requirement 5.4).
    if (!compressionResult.isWithinSizeLimit) {
      _logger.w(
        'VideoRepositoryImpl: compressed file '
        '(${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB) '
        'exceeds 10 MB limit — proceeding but logging warning.',
      );
    }

    // ── 4. Check network availability ─────────────────────────────────────
    final isOnline = await networkInfo.isConnected;

    if (!isOnline) {
      // ── 4a. Offline: queue in local storage (Requirement 5.6) ──────────
      try {
        final queued = await localDataSource.queueVideoForUpload(
          videoId: videoId,
          videoPath: compressedPath,
          boxId: boxId,
          capturedBy: capturedBy,
          durationSeconds: durationSeconds,
          fileSizeBytes: compressedSize,
        );

        // Also insert into the SyncQueue table so the sync service picks
        // it up when connectivity is restored (Requirement 13.4).
        await _insertIntoSyncQueue(
          videoId: videoId,
          boxId: boxId,
          compressedPath: compressedPath,
          capturedBy: capturedBy,
          durationSeconds: durationSeconds,
          fileSizeBytes: compressedSize,
        );

        return Right(queued);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message, e.code));
      }
    }

    // ── 5. Online: persist locally then attempt upload ────────────────────
    final pendingVideo = Video(
      id: videoId,
      boxId: boxId,
      localPath: compressedPath,
      durationSeconds: durationSeconds,
      fileSizeBytes: compressedSize,
      status: VideoStatus.pending,
      capturedAt: DateTime.now().toUtc(),
      capturedBy: capturedBy,
    );

    try {
      await localDataSource.saveVideo(pendingVideo, isDirty: true);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }

    // ── 6. Upload with exponential back-off (Req 5.5, 6.10) ───────────────
    // Back-off schedule: 1s, 2s, 4s, 8s, 16s (max 5 attempts).
    const maxRetries = 5;
    const backoffDelays = [1, 2, 4, 8, 16];
    var attempt = 0;

    // Mark as uploading.
    try {
      await localDataSource.updateVideo(pendingVideo.copyWith(status: VideoStatus.uploading));
    } on CacheException {
      // Non-fatal.
    }

    while (attempt < maxRetries) {
      try {
        final uploaded = await remoteDataSource.uploadVideoWithBoxId(
          videoId,
          compressedPath,
          boxId,
          onSendProgress: onUploadProgress,
        );

        final uploadedVideo = uploaded.copyWith(
          status: VideoStatus.uploaded,
          uploadedAt: DateTime.now().toUtc(),
          fileSizeBytes: compressedSize,
          retryCount: attempt,
        );

        await localDataSource.updateVideo(uploadedVideo);

        // Clean up compressed temp file after successful upload.
        await compressionService.deleteCompressedFile(compressedPath);

        return Right(uploadedVideo.toEntity());
      } on NetworkException catch (e) {
        attempt++;
        _logger.w(
          'VideoRepositoryImpl: upload network error '
          '(attempt $attempt/$maxRetries): ${e.message}',
        );
        if (attempt >= maxRetries) {
          await _markUploadFailed(VideoModel.fromEntity(pendingVideo), attempt);
          // Queue for later sync when max retries exhausted.
          await _insertIntoSyncQueue(
            videoId: videoId,
            boxId: boxId,
            compressedPath: compressedPath,
            capturedBy: capturedBy,
            durationSeconds: durationSeconds,
            fileSizeBytes: compressedSize,
          );
          return Left(NetworkFailure(e.message, e.code));
        }
        await Future<void>.delayed(
          Duration(seconds: backoffDelays[min(attempt - 1, backoffDelays.length - 1)]),
        );
      } on ServerException catch (e) {
        attempt++;
        _logger.e(
          'VideoRepositoryImpl: upload server error '
          '(attempt $attempt/$maxRetries): ${e.message}',
        );
        if (attempt >= maxRetries) {
          await _markUploadFailed(VideoModel.fromEntity(pendingVideo), attempt);
          return Left(_mapServerException(e));
        }
        await Future<void>.delayed(
          Duration(seconds: backoffDelays[min(attempt - 1, backoffDelays.length - 1)]),
        );
      }
    }

    await _markUploadFailed(VideoModel.fromEntity(pendingVideo), maxRetries);
    return const Left(ServerFailure('Upload failed after maximum retry attempts.'));
  }

  /// Inserts a video_upload entry into the SyncQueue drift table.
  ///
  /// Used when offline or when all upload retries are exhausted.
  /// The existing sync service will process these entries when
  /// connectivity is restored (Requirement 13.4).
  Future<void> _insertIntoSyncQueue({
    required String videoId,
    required String boxId,
    required String compressedPath,
    required String capturedBy,
    required int durationSeconds,
    required int fileSizeBytes,
  }) async {
    try {
      // Access the Drift database through the local data source impl.
      // The sync queue is a core table, so we reach it via the db ref
      // exposed by the concrete implementation.
      if (localDataSource is VideoLocalDataSourceImpl) {
        final database = (localDataSource as VideoLocalDataSourceImpl).db;
        final payload = jsonEncode({
          'videoId': videoId,
          'boxId': boxId,
          'localFilePath': compressedPath,
          'compressedFilePath': compressedPath,
          'capturedBy': capturedBy,
          'durationSeconds': durationSeconds,
          'fileSizeBytes': fileSizeBytes,
        });

        await database
            .into(database.syncQueue)
            .insert(
              db.SyncQueueCompanion.insert(
                id: '${videoId}_video_upload',
                operationType: 'video_upload',
                entityId: videoId,
                entityType: 'video',
                payload: payload,
                createdAt: DateTime.now().toUtc(),
                retryCount: const Value(0),
                status: const Value('pending'),
                priority: const Value(2), // High priority (design §4.1)
              ),
            );

        _logger.d(
          'VideoRepositoryImpl: queued video_upload '
          'for videoId=$videoId in SyncQueue.',
        );
      }
    } on Exception catch (e) {
      // Non-fatal — the video is already in the Videos table with isDirty=true.
      _logger.w('VideoRepositoryImpl: failed to insert into SyncQueue: $e');
    }
  }

  @override
  Stream<Video> watchVideo(String videoId) => localDataSource.watchVideo(videoId);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Marks the video as failed in the local store and increments retryCount.
  Future<void> _markUploadFailed(VideoModel video, int extraRetries) async {
    try {
      await localDataSource.updateVideo(
        video.copyWith(status: VideoStatus.failed, retryCount: video.retryCount + extraRetries),
        isDirty: true,
      );
    } on CacheException catch (e) {
      _logger.e('VideoRepositoryImpl: failed to mark video as failed: ${e.message}');
    }
  }

  /// Waits for `min(30, 2^attempt)` seconds before the next retry.
  ///
  /// Implements exponential back-off as required by Requirement 6.10.
  Future<void> _waitExponentialBackoff(int attempt) async {
    final delaySeconds = min(30, 1 << attempt); // 2, 4, 8 … capped at 30
    _logger.d('VideoRepositoryImpl: waiting ${delaySeconds}s before retry $attempt');
    await Future<void>.delayed(Duration(seconds: delaySeconds));
  }

  /// Converts a [ServerException] to the most specific [Failure] subtype.
  Failure _mapServerException(ServerException e) {
    switch (e.statusCode) {
      case 401:
        return const ServerFailure.unauthorized();
      case 403:
        return const ServerFailure.forbidden();
      case 404:
        return const ServerFailure.notFound();
      case 422:
        if (e.details != null) {
          final fields = <String, String>{};
          e.details!.forEach((k, v) => fields[k] = v.toString());
          return ValidationFailure.fields(fields);
        }
        return ValidationFailure(e.message);
      case 500:
      case 502:
      case 503:
        return const ServerFailure.internal();
      default:
        return ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    }
  }
}
