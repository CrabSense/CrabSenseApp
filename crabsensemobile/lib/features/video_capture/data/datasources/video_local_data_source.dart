// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart' show OrderingTerm;

import '../../../../core/database/database.dart' as database;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/ai_detection.dart';
import '../../domain/entities/video.dart';
import '../models/ai_detection_model.dart';
import '../models/video_model.dart';

/// Local data source interface for video and AI-detection cache operations.
///
/// All methods read from and write to the Drift SQLite database.
/// Throws [CacheException] on any storage failure.
///
/// Requirements: 5.1-5.10, 6.1-6.10, 13.3
abstract class VideoLocalDataSource {
  /// Inserts or replaces a video record in the local store.
  ///
  /// Requirements: 5.6, 5.10
  Future<void> saveVideo(Video video, {bool isDirty = false});

  /// Queues a compressed video for upload by persisting a [Video] record
  /// with [VideoStatus.pending], associated with [boxId].
  ///
  /// Stores the compressed [videoPath] and the [boxId] association in the
  /// local database so the upload can be retried later when the network
  /// becomes available (Requirement 5.6).
  ///
  /// [durationSeconds] must be within [Video.minDurationSeconds] –
  /// [Video.maxDurationSeconds].
  /// [fileSizeBytes] is the size of the already-compressed file.
  ///
  /// Returns the persisted [Video] record.
  ///
  /// Requirements: 5.5, 5.6, 13.4
  Future<Video> queueVideoForUpload({
    required String videoId,
    required String videoPath,
    required String boxId,
    required String capturedBy,
    required int durationSeconds,
    required int fileSizeBytes,
  });

  /// Fetches a single video by its ID.
  ///
  /// Throws [CacheException] if no matching row is found.
  ///
  /// Requirements: 5.1
  Future<VideoModel> getVideoById(String videoId);

  /// Fetches all video records for the specified box.
  ///
  /// Returns an empty list when no videos are cached.
  ///
  /// Requirements: 5.10
  Future<List<VideoModel>> getVideosByBox(String boxId);

  /// Fetches all videos with status `pending` or `failed`.
  ///
  /// Requirements: 5.6, 13.4
  Future<List<VideoModel>> getPendingUploadVideos();

  /// Updates an existing video record in the local store.
  ///
  /// Throws [CacheException] on write failure.
  ///
  /// Requirements: 5.4, 5.5
  Future<void> updateVideo(Video video, {bool isDirty = false});

  /// Inserts or replaces an AI detection result in the local cache.
  ///
  /// Requirements: 6.1, 6.8
  Future<void> cacheAIDetection(AIDetection detection, {bool isDirty = false});

  /// Fetches the cached AI detection result for a specific video.
  ///
  /// Throws [CacheException] if no matching row is found.
  ///
  /// Requirements: 6.1, 6.8
  Future<AIDetectionModel> getAIDetectionByVideoId(String videoId);

  /// Fetches all cached AI detection results for a given box.
  ///
  /// Returns an empty list when no results are cached.
  ///
  /// Requirements: 6.8
  Future<List<AIDetectionModel>> getAIDetectionsByBoxId(String boxId);

  /// Returns a live stream of a video row from the local cache.
  ///
  /// Emits the latest [Video] state whenever the row changes.
  ///
  /// Requirements: 5.5, 5.6
  Stream<Video> watchVideo(String videoId);
}

/// Drift-backed implementation of [VideoLocalDataSource].
class VideoLocalDataSourceImpl implements VideoLocalDataSource {
  VideoLocalDataSourceImpl({required this.db});

  final database.AppDatabase db;

  // ──────────────────────────────────────────────────────────────────────────
  // VideoLocalDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveVideo(Video video, {bool isDirty = false}) async {
    try {
      final companion = VideoModel.fromEntity(video).toDriftCompanion(isDirty: isDirty);
      await db.into(db.videos).insertOnConflictUpdate(companion);
    } catch (e) {
      throw CacheException(message: 'Failed to save video: $e', code: 'CACHE_WRITE_ERROR');
    }
  }

  @override
  Future<Video> queueVideoForUpload({
    required String videoId,
    required String videoPath,
    required String boxId,
    required String capturedBy,
    required int durationSeconds,
    required int fileSizeBytes,
  }) async {
    try {
      final video = Video(
        id: videoId,
        boxId: boxId,
        localPath: videoPath,
        durationSeconds: durationSeconds,
        fileSizeBytes: fileSizeBytes,
        status: VideoStatus.pending,
        capturedAt: DateTime.now().toUtc(),
        capturedBy: capturedBy,
      );
      final companion = VideoModel.fromEntity(video).toDriftCompanion(isDirty: true);
      await db.into(db.videos).insertOnConflictUpdate(companion);
      return video;
    } catch (e) {
      throw CacheException(
        message: 'Failed to queue video for upload: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<VideoModel> getVideoById(String videoId) async {
    try {
      final row = await (db.select(
        db.videos,
      )..where((t) => t.id.equals(videoId))).getSingleOrNull();

      if (row == null) {
        throw CacheException(
          message: 'No cached video found with id: $videoId',
          code: 'VIDEO_NOT_FOUND',
        );
      }

      return VideoModel.fromDrift(
        id: row.id,
        boxId: row.boxId,
        localPath: row.localPath,
        durationSeconds: row.durationSeconds,
        fileSizeBytes: row.fileSizeBytes,
        status: row.status,
        capturedAt: row.capturedAt,
        capturedBy: row.capturedBy,
        uploadedAt: row.uploadedAt,
        aiDetectionId: row.aiDetectionId,
        retryCount: row.retryCount,
      );
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read video from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<List<VideoModel>> getVideosByBox(String boxId) async {
    try {
      final rows =
          await (db.select(db.videos)
                ..where((t) => t.boxId.equals(boxId))
                ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
              .get();

      return rows
          .map(
            (row) => VideoModel.fromDrift(
              id: row.id,
              boxId: row.boxId,
              localPath: row.localPath,
              durationSeconds: row.durationSeconds,
              fileSizeBytes: row.fileSizeBytes,
              status: row.status,
              capturedAt: row.capturedAt,
              capturedBy: row.capturedBy,
              uploadedAt: row.uploadedAt,
              aiDetectionId: row.aiDetectionId,
              retryCount: row.retryCount,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read videos by box from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<List<VideoModel>> getPendingUploadVideos() async {
    try {
      final rows = await (db.select(
        db.videos,
      )..where((t) => t.status.isIn(['pending', 'failed']))).get();

      return rows
          .map(
            (row) => VideoModel.fromDrift(
              id: row.id,
              boxId: row.boxId,
              localPath: row.localPath,
              durationSeconds: row.durationSeconds,
              fileSizeBytes: row.fileSizeBytes,
              status: row.status,
              capturedAt: row.capturedAt,
              capturedBy: row.capturedBy,
              uploadedAt: row.uploadedAt,
              aiDetectionId: row.aiDetectionId,
              retryCount: row.retryCount,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read pending upload videos: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> updateVideo(Video video, {bool isDirty = false}) async {
    try {
      final companion = VideoModel.fromEntity(video).toDriftCompanion(isDirty: isDirty);
      await db.into(db.videos).insertOnConflictUpdate(companion);
    } catch (e) {
      throw CacheException(
        message: 'Failed to update video in local cache: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> cacheAIDetection(AIDetection detection, {bool isDirty = false}) async {
    try {
      final companion = AIDetectionModel.fromEntity(detection).toDriftCompanion(isDirty: isDirty);
      await db.into(db.aiDetections).insertOnConflictUpdate(companion);
    } catch (e) {
      throw CacheException(message: 'Failed to cache AI detection: $e', code: 'CACHE_WRITE_ERROR');
    }
  }

  @override
  Future<AIDetectionModel> getAIDetectionByVideoId(String videoId) async {
    try {
      final row = await (db.select(
        db.aiDetections,
      )..where((t) => t.videoId.equals(videoId))).getSingleOrNull();

      if (row == null) {
        throw CacheException(
          message: 'No cached AI detection found for video: $videoId',
          code: 'DETECTION_NOT_FOUND',
        );
      }

      return AIDetectionModel.fromDrift(
        id: row.id,
        videoId: row.videoId,
        boxId: row.boxId,
        moltingStatus: row.moltingStatus,
        healthStatus: row.healthStatus,
        confidenceScore: row.confidenceScore,
        detectedCrabsJson: row.detectedCrabs,
        recommendationsJson: row.recommendations,
        analyzedAt: row.analyzedAt,
        feedbackStatus: row.feedbackStatus,
      );
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read AI detection from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<List<AIDetectionModel>> getAIDetectionsByBoxId(String boxId) async {
    try {
      final rows =
          await (db.select(db.aiDetections)
                ..where((t) => t.boxId.equals(boxId))
                ..orderBy([(t) => OrderingTerm.desc(t.analyzedAt)]))
              .get();

      return rows
          .map(
            (row) => AIDetectionModel.fromDrift(
              id: row.id,
              videoId: row.videoId,
              boxId: row.boxId,
              moltingStatus: row.moltingStatus,
              healthStatus: row.healthStatus,
              confidenceScore: row.confidenceScore,
              detectedCrabsJson: row.detectedCrabs,
              recommendationsJson: row.recommendations,
              analyzedAt: row.analyzedAt,
              feedbackStatus: row.feedbackStatus,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read AI detections by box from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Stream<Video> watchVideo(String videoId) =>
      (db.select(db.videos)..where((t) => t.id.equals(videoId))).watchSingle().map(
        (row) => VideoModel.fromDrift(
          id: row.id,
          boxId: row.boxId,
          localPath: row.localPath,
          durationSeconds: row.durationSeconds,
          fileSizeBytes: row.fileSizeBytes,
          status: row.status,
          capturedAt: row.capturedAt,
          capturedBy: row.capturedBy,
          uploadedAt: row.uploadedAt,
          aiDetectionId: row.aiDetectionId,
          retryCount: row.retryCount,
        ),
      );
}
