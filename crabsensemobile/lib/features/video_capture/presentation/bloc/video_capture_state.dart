import 'package:equatable/equatable.dart';

import 'bloc.dart' show VideoCaptureBloc, VideoRecordingStarted;

import 'video_capture_bloc.dart' show VideoCaptureBloc;
import 'video_capture_event.dart' show VideoRecordingStarted;

/// Base class for all video capture states.
///
/// States represent the current condition of the video capture feature.
/// All states extend this class and use Equatable for value equality.
///
/// Requirements: 5.1-5.10, 24.1-24.9
abstract class VideoCaptureState extends Equatable {
  const VideoCaptureState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the [VideoCaptureBloc] is first created.
class VideoCaptureInitial extends VideoCaptureState {
  const VideoCaptureInitial();
}

/// State while the camera permission check / request is in progress.
///
/// The screen should show a loading indicator.
///
/// Requirements: 24.1, 24.7
class CameraPermissionChecking extends VideoCaptureState {
  const CameraPermissionChecking();
}

/// State when camera permission has been granted and the camera can be
/// initialised.
///
/// Requirements: 24.7
class CameraPermissionGranted extends VideoCaptureState {
  const CameraPermissionGranted();
}

/// State when camera permission has been denied by the user.
///
/// The screen should prompt the user to grant permission with a retry.
///
/// Requirements: 24.2, 24.6
class CameraPermissionDenied extends VideoCaptureState {
  const CameraPermissionDenied();
}

/// State when camera permission has been permanently denied.
///
/// The app can no longer request the permission; the user must open
/// device settings. Show guidance with an "Open Settings" button.
///
/// Requirements: 24.2, 24.9
class CameraPermissionPermanentlyDenied extends VideoCaptureState {
  const CameraPermissionPermanentlyDenied();
}

/// State when the camera preview is live and the app is ready to record.
///
/// Requirements: 5.1, 5.7
class VideoCaptureReady extends VideoCaptureState {
  const VideoCaptureReady({required this.isFrontCamera});

  /// Whether the front-facing camera is currently active.
  final bool isFrontCamera;

  @override
  List<Object?> get props => [isFrontCamera];
}

/// State when a video recording is actively in progress.
///
/// Requirements: 5.2, 5.3, 5.10
class VideoRecording extends VideoCaptureState {
  const VideoRecording({
    required this.boxId,
    required this.elapsedSeconds,
    required this.maxSeconds,
    required this.isFrontCamera,
  });

  /// Identifier of the box being recorded (Requirement 5.10).
  final String boxId;

  /// Elapsed recording time in seconds.
  final int elapsedSeconds;

  /// Maximum allowed recording duration in seconds (= 10).
  final int maxSeconds;

  /// Whether the front-facing camera is currently active.
  final bool isFrontCamera;

  @override
  List<Object?> get props => [boxId, elapsedSeconds, maxSeconds, isFrontCamera];
}

/// State while the recording is being stopped and the video file is
/// being saved / compressed.
///
/// The screen should show a loading indicator and disable controls.
///
/// Requirements: 5.4
class VideoRecordingStopping extends VideoCaptureState {
  const VideoRecordingStopping();
}

/// State when the recording has been saved locally and is ready for upload.
///
/// Requirements: 5.5, 5.6, 5.10
class VideoCaptureComplete extends VideoCaptureState {
  const VideoCaptureComplete({
    required this.videoPath,
    required this.durationSeconds,
    required this.boxId,
  });

  /// Absolute path to the recorded video file on the device.
  final String videoPath;

  /// Duration of the recording in seconds.
  final int durationSeconds;

  /// Identifier of the box this video was captured for.
  final String boxId;

  @override
  List<Object?> get props => [videoPath, durationSeconds, boxId];
}

/// State when an error has occurred during the capture flow.
///
/// Requirements: 5.9
class VideoCaptureError extends VideoCaptureState {
  const VideoCaptureError({required this.message, this.code});

  /// User-facing error message.
  final String message;

  /// Optional machine-readable error code.
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

// ── Compression states ───────────────────────────────────────────────────────

/// State while video compression is running.
///
/// Requirements: 5.4, 22.7
class VideoCompressing extends VideoCaptureState {
  const VideoCompressing({required this.progress, required this.boxId});

  /// Compression progress in [0.0, 1.0].
  final double progress;

  /// Box this video is associated with.
  final String boxId;

  @override
  List<Object?> get props => [progress, boxId];
}

// ── Upload states ────────────────────────────────────────────────────────────

/// State while the video is being uploaded to the AI service.
///
/// Requirements: 5.5
class VideoUploading extends VideoCaptureState {
  const VideoUploading({
    required this.progress,
    required this.boxId,
    required this.videoId,
    this.currentAttempt = 1,
    this.maxAttempts = 5,
  });

  /// Upload progress in [0.0, 1.0].
  final double progress;

  /// Box this video is associated with.
  final String boxId;

  /// Video being uploaded.
  final String videoId;

  /// Current retry attempt number (1 = first attempt).
  final int currentAttempt;

  /// Maximum number of upload attempts.
  final int maxAttempts;

  @override
  List<Object?> get props => [progress, boxId, videoId, currentAttempt, maxAttempts];
}

/// State when video was uploaded successfully.
///
/// Requirements: 5.5
class VideoUploaded extends VideoCaptureState {
  const VideoUploaded({required this.boxId, required this.videoId});

  final String boxId;
  final String videoId;

  @override
  List<Object?> get props => [boxId, videoId];
}

/// State when the device is offline and the video has been queued.
///
/// Requirements: 5.6
class VideoQueued extends VideoCaptureState {
  const VideoQueued({required this.boxId, required this.videoId});

  /// Box this video is associated with.
  final String boxId;

  /// Local video identifier in the queue.
  final String videoId;

  @override
  List<Object?> get props => [boxId, videoId];
}

// ── Storage states ───────────────────────────────────────────────────────────

/// State when device storage is insufficient to record a new video.
///
/// Recording is BLOCKED. The UI should show an error dialog and offer
/// guidance on how to free up space.
///
/// Requirements: 5.9
class StorageInsufficient extends VideoCaptureState {
  const StorageInsufficient({required this.availableBytes, required this.requiredBytes});

  /// Bytes currently available on the device.
  final int availableBytes;

  /// Minimum bytes required before recording is allowed.
  final int requiredBytes;

  @override
  List<Object?> get props => [availableBytes, requiredBytes];
}

/// State when the offline video queue is above the 80 % warning threshold.
///
/// Recording is ALLOWED but the user should be warned to sync first.
/// The [boxId] is carried through so the UI can dispatch
/// [VideoRecordingStarted] if the user chooses to continue.
///
/// Requirements: 5.9
class StorageWarningOfflineQueue extends VideoCaptureState {
  const StorageWarningOfflineQueue({
    required this.usedBytes,
    required this.totalBytes,
    required this.boxId,
  });

  /// Bytes currently used by the offline video queue directory.
  final int usedBytes;

  /// Total assumed capacity of the offline queue (1 GB by default).
  final int totalBytes;

  /// Box identifier passed through so recording can still proceed.
  final String boxId;

  @override
  List<Object?> get props => [usedBytes, totalBytes, boxId];
}

/// State when all upload retries are exhausted.
///
/// Provides enough information for the UI to show a retry button.
///
/// Requirements: 5.5, 6.10
class VideoUploadFailed extends VideoCaptureState {
  const VideoUploadFailed({
    required this.message,
    required this.videoId,
    required this.compressedPath,
    required this.boxId,
    required this.capturedBy,
    required this.durationSeconds,
    this.code,
  });

  /// User-facing error message.
  final String message;

  /// Optional machine-readable error code.
  final String? code;

  final String videoId;
  final String compressedPath;
  final String boxId;
  final String capturedBy;
  final int durationSeconds;

  @override
  List<Object?> get props => [
    message,
    code,
    videoId,
    compressedPath,
    boxId,
    capturedBy,
    durationSeconds,
  ];
}
