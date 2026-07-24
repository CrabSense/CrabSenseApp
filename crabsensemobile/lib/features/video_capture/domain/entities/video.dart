/// Video entity representing a recorded video for AI crab health analysis.
///
/// A video is captured by a field operator against a specific crab box,
/// compressed, then uploaded to the AI service for detection. When the
/// device is offline the video is queued locally and uploaded later.
///
/// This is a pure domain entity with no external dependencies.
/// All fields are immutable (final); use [copyWith] to create modified copies.
///
/// Requirements: 5.1-5.10
library;

/// Upload / processing status of a [Video].
enum VideoStatus {
  /// Recorded locally; waiting to be uploaded.
  pending,

  /// Currently being uploaded to the AI service.
  uploading,

  /// Successfully uploaded; AI analysis may be in progress.
  uploaded,

  /// Upload failed (will be retried with exponential backoff).
  failed,
}

/// Extension on [VideoStatus] for display helpers.
extension VideoStatusExtension on VideoStatus {
  /// Returns the human-readable display name.
  String get displayName {
    switch (this) {
      case VideoStatus.pending:
        return 'Pending';
      case VideoStatus.uploading:
        return 'Uploading';
      case VideoStatus.uploaded:
        return 'Uploaded';
      case VideoStatus.failed:
        return 'Failed';
    }
  }

  /// Returns true if the video still needs to be uploaded.
  bool get needsUpload => this == VideoStatus.pending || this == VideoStatus.failed;

  /// Returns true if the upload is complete.
  bool get isUploaded => this == VideoStatus.uploaded;
}

/// Parses a raw status string into a [VideoStatus].
///
/// Returns [VideoStatus.pending] if the value is not recognised.
VideoStatus videoStatusFromString(String value) {
  switch (value.toLowerCase()) {
    case 'uploading':
      return VideoStatus.uploading;
    case 'uploaded':
      return VideoStatus.uploaded;
    case 'failed':
      return VideoStatus.failed;
    default:
      return VideoStatus.pending;
  }
}

/// Video entity for crab health AI analysis.
///
/// Duration is constrained to 5–10 seconds and the compressed file
/// must be under 10 MB before upload (Requirements 5.2, 5.4).
///
/// Requirements: 5.1-5.10
class Video {
  const Video({
    required this.id,
    required this.boxId,
    required this.localPath,
    required this.durationSeconds,
    required this.status,
    required this.capturedAt,
    required this.capturedBy,
    this.fileSizeBytes,
    this.uploadedAt,
    this.aiDetectionId,
    this.retryCount = 0,
  });

  /// Unique identifier for the video record.
  final String id;

  /// Identifier of the box this video was captured for.
  ///
  /// Links the recording back to the scanned box (Requirement 5.10).
  final String boxId;

  /// Absolute path to the video file on the device's local storage.
  ///
  /// Empty string when the record has been synced and the local file
  /// has been cleaned up.
  final String localPath;

  /// Duration of the recording in seconds.
  ///
  /// Must be between [minDurationSeconds] and [maxDurationSeconds]
  /// (Requirement 5.2).
  final int durationSeconds;

  /// Compressed file size in bytes.
  ///
  /// Must be ≤ [maxFileSizeBytes] (10 MB) before upload
  /// (Requirement 5.4). Null until compression is complete.
  final int? fileSizeBytes;

  /// Current upload / processing status.
  final VideoStatus status;

  /// Timestamp when the video was recorded.
  final DateTime capturedAt;

  /// Identifier of the field operator who recorded this video.
  final String capturedBy;

  /// Timestamp when the upload to the AI service completed.
  ///
  /// Null until [status] becomes [VideoStatus.uploaded].
  final DateTime? uploadedAt;

  /// Identifier of the [AIDetection] result associated with this video.
  ///
  /// Null until the AI service has returned its analysis.
  final String? aiDetectionId;

  /// Number of upload retry attempts (used for exponential back-off).
  ///
  /// Requirement 6.10.
  final int retryCount;

  // ── Business-rule constants ──────────────────────────────────────────────

  /// Minimum valid recording duration in seconds (Requirement 5.2).
  static const int minDurationSeconds = 5;

  /// Maximum valid recording duration in seconds (Requirement 5.2).
  static const int maxDurationSeconds = 10;

  /// Maximum allowed compressed file size in bytes (10 MB).
  ///
  /// Requirement 5.4.
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  // ── Computed properties ─────────────────────────────────────────────────

  /// Returns true if the recording duration is within the valid range.
  bool get hasValidDuration =>
      durationSeconds >= minDurationSeconds && durationSeconds <= maxDurationSeconds;

  /// Returns true if the compressed file meets the size requirement.
  ///
  /// Returns false when [fileSizeBytes] is null (not yet compressed).
  bool get isWithinSizeLimit => fileSizeBytes != null && fileSizeBytes! <= maxFileSizeBytes;

  /// Returns true when this video has an associated AI detection result.
  bool get hasAiResult => aiDetectionId != null;

  // ── copyWith ────────────────────────────────────────────────────────────

  /// Creates a copy of this video with the given fields replaced.
  Video copyWith({
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
  }) => Video(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Video &&
        other.id == id &&
        other.boxId == boxId &&
        other.localPath == localPath &&
        other.durationSeconds == durationSeconds &&
        other.fileSizeBytes == fileSizeBytes &&
        other.status == status &&
        other.capturedAt == capturedAt &&
        other.capturedBy == capturedBy &&
        other.uploadedAt == uploadedAt &&
        other.aiDetectionId == aiDetectionId &&
        other.retryCount == retryCount;
  }

  @override
  int get hashCode => Object.hash(
    id,
    boxId,
    localPath,
    durationSeconds,
    fileSizeBytes,
    status,
    capturedAt,
    capturedBy,
    uploadedAt,
    aiDetectionId,
    retryCount,
  );

  @override
  String toString() =>
      'Video(id: $id, boxId: $boxId, '
      'durationSeconds: $durationSeconds, '
      'fileSizeBytes: $fileSizeBytes, '
      'status: ${status.displayName}, '
      'capturedAt: $capturedAt, capturedBy: $capturedBy, '
      'uploadedAt: $uploadedAt, aiDetectionId: $aiDetectionId, '
      'retryCount: $retryCount)';
}
