// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:dio/dio.dart' show DioException, FormData, MultipartFile;
import 'package:logger/logger.dart';
import 'package:path/path.dart' show basename;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/ai_detection.dart';
import '../models/ai_detection_model.dart';
import '../models/video_model.dart';

/// Contract for fetching and uploading video / AI-detection data via the
/// remote API.
///
/// All methods throw typed exceptions on failure:
/// - [ServerException]: 4xx / 5xx API responses.
/// - [NetworkException]: No network connectivity or request timeout.
/// - [ParseException]: Malformed or unexpected JSON response body.
///
/// Requirements: 5.1-5.10, 6.1-6.10
abstract class VideoRemoteDataSource {
  /// Fetches the metadata for a single video by its unique ID.
  ///
  /// Requirements: 5.1
  Future<VideoModel> getVideoById(String videoId);

  /// Retrieves all video records associated with a given box.
  ///
  /// Requirements: 5.10
  Future<List<VideoModel>> getVideosForBox(String boxId);

  /// Uploads the video file at [localPath] to the AI service.
  ///
  /// Reports progress via [onSendProgress] callback in [0.0, 1.0].
  ///
  /// Requirements: 5.5, 5.9
  Future<VideoModel> uploadVideo(
    String videoId,
    String localPath, {
    void Function(double progress)? onSendProgress,
  });

  /// Uploads the video file at [localPath] to the AI service, associating
  /// the recording with the given [boxId].
  ///
  /// The [boxId] is included in the multipart form data so the AI service
  /// can directly link the video to the correct crab box
  /// (Requirement 5.10).
  ///
  /// Reports progress via [onSendProgress] callback in [0.0, 1.0].
  ///
  /// Requirements: 5.5, 5.10
  Future<VideoModel> uploadVideoWithBoxId(
    String videoId,
    String localPath,
    String boxId, {
    void Function(double progress)? onSendProgress,
  });

  /// Retrieves the AI detection result for a specific video.
  ///
  /// Requirements: 6.1, 6.8
  Future<AIDetectionModel> getAIResults(String videoId);

  /// Retrieves all AI detection results for a given box.
  ///
  /// Requirements: 6.8
  Future<List<AIDetectionModel>> getAIResultsByBox(String boxId);

  /// Submits operator feedback on an AI detection result.
  ///
  /// Requirements: 6.9
  Future<AIDetectionModel> submitFeedback(
    String detectionId,
    DetectionFeedbackStatus feedbackStatus,
  );
}

/// Dio-backed implementation of [VideoRemoteDataSource].
///
/// Uses [ApiClient.safeGet] / [ApiClient.safePost] etc. for standard JSON
/// requests and [ApiClient.dio] (raw Dio) for multipart video uploads with
/// progress tracking (Requirement 5.5).
class VideoRemoteDataSourceImpl implements VideoRemoteDataSource {
  VideoRemoteDataSourceImpl({required this._apiClient, required this._logger});

  final ApiClient _apiClient;
  final Logger _logger;

  // ──────────────────────────────────────────────────────────────────────────
  // VideoRemoteDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<VideoModel> getVideoById(String videoId) async {
    _logger.d('VideoRemoteDataSource: getVideoById($videoId)');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.videoDetails(videoId),
    );

    _checkFailure(result.failure, 'video details');

    final data = _extractData(result.data.data, 'getVideoById');
    return VideoModel.fromJson(data);
  }

  @override
  Future<List<VideoModel>> getVideosForBox(String boxId) async {
    _logger.d('VideoRemoteDataSource: getVideosForBox($boxId)');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(ApiConstants.videosForBox(boxId));

    _checkFailure(result.failure, 'videos for box');

    final items = _extractList(result.data.data, 'getVideosForBox');
    return items.map((e) => VideoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<VideoModel> uploadVideo(
    String videoId,
    String localPath, {
    void Function(double progress)? onSendProgress,
  }) async {
    _logger.d('VideoRemoteDataSource: uploadVideo($videoId) from $localPath');

    final file = File(localPath);
    if (!file.existsSync()) {
      throw ServerException(
        message: 'Video file not found at path: $localPath',
        code: 'FILE_NOT_FOUND',
      );
    }

    try {
      final formData = FormData.fromMap({
        'category': 'video',
        'file': await MultipartFile.fromFile(localPath, filename: basename(localPath)),
      });

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.uploadVideo,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0 && onSendProgress != null) {
            onSendProgress(sent / total);
          }
        },
      );

      final responseData = response.data;
      if (responseData == null) {
        throw const ParseException(message: 'Null response body in uploadVideo', field: 'data');
      }

      final data = _extractData(responseData, 'uploadVideo');
      final video = _videoFromMediaJson(data, fallbackLocalPath: localPath);
      await _triggerAnalyze(mediaId: video.id);
      return video;
    } on DioException catch (e) {
      _logger.e('VideoRemoteDataSource: uploadVideo failed', error: e);
      if (e.type.name.toLowerCase().contains('connect') ||
          e.type.name.toLowerCase().contains('timeout')) {
        throw NetworkException(message: e.message ?? 'Network error during upload');
      }
      throw ServerException(
        message: e.message ?? 'Upload failed',
        statusCode: e.response?.statusCode,
        code: 'UPLOAD_ERROR',
      );
    }
  }

  @override
  Future<VideoModel> uploadVideoWithBoxId(
    String videoId,
    String localPath,
    String boxId, {
    void Function(double progress)? onSendProgress,
  }) async {
    _logger.d('VideoRemoteDataSource: uploadVideoWithBoxId($videoId, boxId=$boxId)');

    final file = File(localPath);
    if (!file.existsSync()) {
      throw ServerException(
        message: 'Video file not found at path: $localPath',
        code: 'FILE_NOT_FOUND',
      );
    }

    if (boxId.trim().isEmpty) {
      throw const ServerException(
        message: 'boxId must not be empty when uploading a video',
        code: 'INVALID_BOX_ID',
      );
    }

    try {
      final formData = FormData.fromMap({
        'category': 'video',
        'boxId': boxId,
        'file': await MultipartFile.fromFile(localPath, filename: basename(localPath)),
      });

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.uploadVideo,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0 && onSendProgress != null) {
            onSendProgress(sent / total);
          }
        },
      );

      final responseData = response.data;
      if (responseData == null) {
        throw const ParseException(
          message: 'Null response body in uploadVideoWithBoxId',
          field: 'data',
        );
      }

      final data = _extractData(responseData, 'uploadVideoWithBoxId');
      final video = _videoFromMediaJson(data, fallbackLocalPath: localPath, boxId: boxId);
      await _triggerAnalyze(mediaId: video.id, boxId: boxId);
      return video;
    } on DioException catch (e) {
      _logger.e('VideoRemoteDataSource: uploadVideoWithBoxId failed', error: e);
      if (e.type.name.toLowerCase().contains('connect') ||
          e.type.name.toLowerCase().contains('timeout')) {
        throw NetworkException(message: e.message ?? 'Network error during upload');
      }
      throw ServerException(
        message: e.message ?? 'Upload failed',
        statusCode: e.response?.statusCode,
        code: 'UPLOAD_ERROR',
      );
    }
  }

  @override
  Future<AIDetectionModel> getAIResults(String videoId) async {
    _logger.d('VideoRemoteDataSource: getAIResults($videoId)');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.aiDetections,
      queryParameters: {'mediaId': videoId, 'videoId': videoId},
    );

    _checkFailure(result.failure, 'AI results');

    final items = _extractList(result.data.data, 'getAIResults');
    if (items.isEmpty) {
      // Trigger analyze then re-fetch.
      await _triggerAnalyze(mediaId: videoId);
      final retry = await _apiClient.safeGet<Map<String, dynamic>>(
        ApiConstants.aiDetections,
        queryParameters: {'mediaId': videoId, 'videoId': videoId},
      );
      _checkFailure(retry.failure, 'AI results retry');
      final retryItems = _extractList(retry.data.data, 'getAIResultsRetry');
      if (retryItems.isEmpty) {
        throw const ParseException(message: 'No AI detection for video', field: 'data');
      }
      return AIDetectionModel.fromJson(retryItems.first as Map<String, dynamic>);
    }
    return AIDetectionModel.fromJson(items.first as Map<String, dynamic>);
  }

  @override
  Future<List<AIDetectionModel>> getAIResultsByBox(String boxId) async {
    _logger.d('VideoRemoteDataSource: getAIResultsByBox($boxId)');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.aiDetections,
      queryParameters: {'boxId': boxId},
    );

    _checkFailure(result.failure, 'AI results by box');

    final items = _extractList(result.data.data, 'getAIResultsByBox');
    return items.map((e) => AIDetectionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AIDetectionModel> submitFeedback(
    String detectionId,
    DetectionFeedbackStatus feedbackStatus,
  ) async {
    _logger.d('VideoRemoteDataSource: submitFeedback($detectionId, ${feedbackStatus.value})');

    final isCorrect = feedbackStatus == DetectionFeedbackStatus.correct;
    final result = await _apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.submitFeedback,
      data: {
        'detectionId': detectionId,
        'aiDetectionId': detectionId,
        'isCorrect': isCorrect,
        'comment': feedbackStatus.value,
      },
    );

    _checkFailure(result.failure, 'submit feedback');

    // Feedback endpoint returns { id } — reload detection if possible.
    try {
      return await getAIResults(detectionId);
    } on Exception {
      return AIDetectionModel.fromJson({
        'id': detectionId,
        'videoId': '',
        'boxId': '',
        'confidence': 0,
        'status': feedbackStatus.value,
        'detectedAt': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<void> _triggerAnalyze({required String mediaId, String? boxId}) async {
    try {
      await _apiClient.safePost<Map<String, dynamic>>(
        ApiConstants.aiAnalyze,
        data: {
          'mediaId': mediaId,
          'videoId': mediaId,
          if (boxId != null && boxId.isNotEmpty) 'boxId': boxId,
        },
      );
    } on Exception catch (e) {
      _logger.w('VideoRemoteDataSource: analyze trigger failed: $e');
    }
  }

  VideoModel _videoFromMediaJson(
    Map<String, dynamic> data, {
    required String fallbackLocalPath,
    String? boxId,
  }) {
    // Prefer Mobile BoxVideoItemDto shape; fall back to MediaAssetDto.
    if (data.containsKey('localPath') || data.containsKey('capturedAt')) {
      return VideoModel.fromJson(data);
    }

    final id = data['id']?.toString() ?? '';
    final resolvedBoxId = data['boxId']?.toString() ?? boxId ?? '';
    final path =
        data['webViewLink']?.toString() ??
        data['shareLink']?.toString() ??
        data['storageKey']?.toString() ??
        fallbackLocalPath;

    return VideoModel.fromJson({
      'id': id,
      'boxId': resolvedBoxId,
      'localPath': path,
      'durationSeconds': 0,
      'fileSizeBytes': data['sizeBytes'],
      'status': 'uploaded',
      'capturedAt': data['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
      'capturedBy': '',
      'uploadedAt': data['createdAt'],
      'retryCount': 0,
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Throws the appropriate typed exception if [failure] is non-null.
  void _checkFailure(Failure? failure, String context) {
    if (failure == null) {
      return;
    }

    if (failure is NetworkFailure) {
      throw NetworkException(message: failure.message, code: failure.code);
    }

    if (failure is ServerFailure) {
      throw ServerException(
        message: failure.message,
        statusCode: failure.statusCode,
        code: failure.code,
      );
    }

    throw ServerException(message: 'Failed to $context: ${failure.message}', code: failure.code);
  }

  /// Extracts and validates the `data` payload from an API response map.
  Map<String, dynamic> _extractData(Map<String, dynamic>? responseBody, String operationName) {
    if (responseBody == null) {
      throw ParseException(message: 'Null response body in $operationName', field: 'data');
    }

    if (responseBody.containsKey('data') && responseBody['data'] is Map<String, dynamic>) {
      return responseBody['data'] as Map<String, dynamic>;
    }

    return responseBody;
  }

  /// Extracts and validates a list payload from an API response map.
  List<dynamic> _extractList(Map<String, dynamic>? responseBody, String operationName) {
    if (responseBody == null) {
      return const [];
    }

    if (responseBody.containsKey('data') && responseBody['data'] is List<dynamic>) {
      return responseBody['data'] as List<dynamic>;
    }

    if (responseBody.containsKey('items') && responseBody['items'] is List<dynamic>) {
      return responseBody['items'] as List<dynamic>;
    }

    _logger.w('VideoRemoteDataSource: unexpected list shape in $operationName');
    return const [];
  }
}
