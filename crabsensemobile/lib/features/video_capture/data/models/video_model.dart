// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart' show VideosCompanion;
import '../../../box/data/models/box_model.dart' show BoxModel;
import '../../domain/entities/video.dart';

/// Data Transfer Object (DTO) for the [Video] entity with JSON serialization.
///
/// Handles serialization/deserialization of video data from API responses and
/// local Drift rows. Mirrors the [BoxModel] pattern.
///
/// Requirements: 5.1-5.10
class VideoModel extends Video {
  const VideoModel({
    required super.id,
    required super.boxId,
    required super.localPath,
    required super.durationSeconds,
    required super.status,
    required super.capturedAt,
    required super.capturedBy,
    super.fileSizeBytes,
    super.uploadedAt,
    super.aiDetectionId,
    super.retryCount,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a [VideoModel] from a raw JSON map (API response).
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    String asStr(Object? value) => value?.toString() ?? '';
    return VideoModel(
      id: asStr(json['id']),
      boxId: asStr(json['boxId'] ?? json['box_id']),
      localPath: asStr(json['localPath'] ?? json['local_path']),
      durationSeconds:
          (json['durationSeconds'] as num?)?.toInt() ??
          (json['duration_seconds'] as num?)?.toInt() ??
          0,
      fileSizeBytes:
          (json['fileSizeBytes'] as num?)?.toInt() ?? (json['file_size_bytes'] as num?)?.toInt(),
      status: videoStatusFromString(json['status'] as String? ?? 'pending'),
      capturedAt: _parseDateTime(json['capturedAt'] as String? ?? json['captured_at'] as String?),
      capturedBy: asStr(json['capturedBy'] ?? json['captured_by']),
      uploadedAt: _parseDateTimeNullable(
        json['uploadedAt'] as String? ?? json['uploaded_at'] as String?,
      ),
      aiDetectionId: () {
        final raw = json['aiDetectionId'] ?? json['ai_detection_id'];
        final s = asStr(raw);
        return s.isEmpty ? null : s;
      }(),
      retryCount:
          (json['retryCount'] as num?)?.toInt() ?? (json['retry_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Creates a [VideoModel] from Drift row column values (local DB).
  factory VideoModel.fromDrift({
    required String id,
    required String boxId,
    required String localPath,
    required int durationSeconds,
    required int? fileSizeBytes,
    required String status,
    required DateTime capturedAt,
    required String capturedBy,
    required DateTime? uploadedAt,
    required String? aiDetectionId,
    required int retryCount,
  }) => VideoModel(
    id: id,
    boxId: boxId,
    localPath: localPath,
    durationSeconds: durationSeconds,
    fileSizeBytes: fileSizeBytes,
    status: videoStatusFromString(status),
    capturedAt: capturedAt,
    capturedBy: capturedBy,
    uploadedAt: uploadedAt,
    aiDetectionId: aiDetectionId,
    retryCount: retryCount,
  );

  /// Creates a [VideoModel] from a domain [Video] entity.
  factory VideoModel.fromEntity(Video video) => VideoModel(
    id: video.id,
    boxId: video.boxId,
    localPath: video.localPath,
    durationSeconds: video.durationSeconds,
    fileSizeBytes: video.fileSizeBytes,
    status: video.status,
    capturedAt: video.capturedAt,
    capturedBy: video.capturedBy,
    uploadedAt: video.uploadedAt,
    aiDetectionId: video.aiDetectionId,
    retryCount: video.retryCount,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Serialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this [VideoModel] to a JSON map suitable for API requests.
  Map<String, dynamic> toJson() => {
    'id': id,
    'boxId': boxId,
    'localPath': localPath,
    'durationSeconds': durationSeconds,
    'fileSizeBytes': fileSizeBytes,
    'status': _statusToString(status),
    'capturedAt': capturedAt.toIso8601String(),
    'capturedBy': capturedBy,
    'uploadedAt': uploadedAt?.toIso8601String(),
    'aiDetectionId': aiDetectionId,
    'retryCount': retryCount,
  };

  /// Converts this [VideoModel] to a [VideosCompanion] for Drift inserts/updates.
  VideosCompanion toDriftCompanion({bool isDirty = false}) => VideosCompanion(
    id: Value(id),
    boxId: Value(boxId),
    localPath: Value(localPath),
    durationSeconds: Value(durationSeconds),
    fileSizeBytes: Value(fileSizeBytes),
    status: Value(_statusToString(status)),
    capturedAt: Value(capturedAt),
    capturedBy: Value(capturedBy),
    uploadedAt: Value(uploadedAt),
    aiDetectionId: Value(aiDetectionId),
    retryCount: Value(retryCount),
    isDirty: Value(isDirty),
    cachedAt: Value(DateTime.now().toUtc()),
  );

  /// Converts this [VideoModel] to a domain [Video] entity.
  Video toEntity() => Video(
    id: id,
    boxId: boxId,
    localPath: localPath,
    durationSeconds: durationSeconds,
    fileSizeBytes: fileSizeBytes,
    status: status,
    capturedAt: capturedAt,
    capturedBy: capturedBy,
    uploadedAt: uploadedAt,
    aiDetectionId: aiDetectionId,
    retryCount: retryCount,
  );

  @override
  VideoModel copyWith({
    String? id,
    String? boxId,
    String? localPath,
    int? durationSeconds,
    int? fileSizeBytes,
    VideoStatus? status,
    DateTime? capturedAt,
    String? capturedBy,
    DateTime? uploadedAt,
    String? aiDetectionId,
    int? retryCount,
  }) => VideoModel(
    id: id ?? this.id,
    boxId: boxId ?? this.boxId,
    localPath: localPath ?? this.localPath,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    status: status ?? this.status,
    capturedAt: capturedAt ?? this.capturedAt,
    capturedBy: capturedBy ?? this.capturedBy,
    uploadedAt: uploadedAt ?? this.uploadedAt,
    aiDetectionId: aiDetectionId ?? this.aiDetectionId,
    retryCount: retryCount ?? this.retryCount,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  static String _statusToString(VideoStatus status) {
    switch (status) {
      case VideoStatus.pending:
        return 'pending';
      case VideoStatus.uploading:
        return 'uploading';
      case VideoStatus.uploaded:
        return 'uploaded';
      case VideoStatus.failed:
        return 'failed';
    }
  }

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.parse(value);
  }

  static DateTime? _parseDateTimeNullable(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }
}
