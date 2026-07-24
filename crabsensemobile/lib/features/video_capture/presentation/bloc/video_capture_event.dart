import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../domain/entities/video.dart' show Video;

import 'bloc.dart' show VideoCaptureBloc;

import 'video_capture_bloc.dart' show VideoCaptureBloc;

/// Base class for all video capture events.
///
/// Events represent user actions or system triggers that cause state
/// changes in the [VideoCaptureBloc]. All events extend this class
/// and use Equatable for value equality comparisons.
///
/// Requirements: 5.1-5.10, 24.1-24.9
abstract class VideoCaptureEvent extends Equatable {
  const VideoCaptureEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered to check and request camera permission.
///
/// Dispatched during screen initialisation, before the camera is opened.
/// The [context] is used to show the in-app rationale dialog before the
/// OS prompt.
///
/// Requirements: 24.1, 24.7
class CameraPermissionRequested extends VideoCaptureEvent {
  const CameraPermissionRequested({this.context});

  /// The [BuildContext] needed to show the rationale dialog.
  final BuildContext? context;

  @override
  List<Object?> get props => [];
}

/// Event triggered when the camera controller has been initialised
/// and the preview is live.
///
/// Requirements: 5.1
class VideoCaptureInitialized extends VideoCaptureEvent {
  const VideoCaptureInitialized();
}

/// Event triggered when the user taps the record button to start recording.
///
/// [boxId] links the recording to the scanned crab box
/// (Requirement 5.10).
///
/// Requirements: 5.2, 5.10
class VideoRecordingStarted extends VideoCaptureEvent {
  const VideoRecordingStarted({required this.boxId});

  /// Identifier of the box being recorded.
  final String boxId;

  @override
  List<Object?> get props => [boxId];
}

/// Internal event emitted every second by the recording timer.
///
/// Requirements: 5.2, 5.3
class VideoRecordingTicked extends VideoCaptureEvent {
  const VideoRecordingTicked({required this.elapsedSeconds});

  /// Total elapsed seconds since recording started.
  final int elapsedSeconds;

  @override
  List<Object?> get props => [elapsedSeconds];
}

/// Internal event emitted when the recording has reached [maxDurationSeconds]
/// and must be stopped automatically.
///
/// Requirements: 5.2
class VideoRecordingAutoStopped extends VideoCaptureEvent {
  const VideoRecordingAutoStopped();
}

/// Event triggered when the user taps the stop button during recording.
///
/// Requirements: 5.3
class VideoRecordingManualStopped extends VideoCaptureEvent {
  const VideoRecordingManualStopped();
}

/// Event triggered when the user toggles between front and rear cameras.
///
/// Requirements: 5.7
class CameraFacingToggled extends VideoCaptureEvent {
  const CameraFacingToggled();
}

/// Event triggered to reset the capture flow back to the ready state.
///
/// Used after a completed capture or error to allow a new recording.
///
/// Requirements: 5.1
class VideoCaptureReset extends VideoCaptureEvent {
  const VideoCaptureReset();
}

/// Event triggered after a recording is saved to start compression.
///
/// The [videoId] and [videoPath] are taken from the saved [Video] entity.
///
/// Requirements: 5.4, 22.7
class VideoCompressionStarted extends VideoCaptureEvent {
  const VideoCompressionStarted({
    required this.videoId,
    required this.videoPath,
    required this.boxId,
    required this.capturedBy,
    required this.durationSeconds,
  });

  final String videoId;
  final String videoPath;
  final String boxId;
  final String capturedBy;
  final int durationSeconds;

  @override
  List<Object?> get props => [videoId, videoPath, boxId, capturedBy, durationSeconds];
}

/// Internal event emitted during compression to relay progress.
///
/// [progress] is in [0.0, 1.0].
///
/// Requirements: 5.4, 22.7
class VideoCompressionProgressed extends VideoCaptureEvent {
  const VideoCompressionProgressed({required this.progress});

  final double progress;

  @override
  List<Object?> get props => [progress];
}

/// Internal event emitted during upload to relay progress.
///
/// [progress] is in [0.0, 1.0].
///
/// Requirements: 5.5
class VideoUploadProgressed extends VideoCaptureEvent {
  const VideoUploadProgressed({required this.progress});

  final double progress;

  @override
  List<Object?> get props => [progress];
}

/// Event triggered when the record button is tapped.
///
/// The BLoC checks storage availability before starting the recording.
/// If storage is sufficient it internally dispatches [VideoRecordingStarted].
/// If insufficient it emits [StorageInsufficient].
/// If the offline queue exceeds 80 % it emits [StorageWarningOfflineQueue].
///
/// Requirements: 5.9
class StorageCheckRequested extends VideoCaptureEvent {
  const StorageCheckRequested({required this.boxId});

  /// Identifier of the box to be recorded.
  final String boxId;

  @override
  List<Object?> get props => [boxId];
}

/// Event triggered by the user to retry a failed upload.
///
/// Requirements: 5.5, 6.10
class VideoUploadRetryRequested extends VideoCaptureEvent {
  const VideoUploadRetryRequested({
    required this.videoId,
    required this.compressedPath,
    required this.boxId,
    required this.capturedBy,
    required this.durationSeconds,
  });

  final String videoId;
  final String compressedPath;
  final String boxId;
  final String capturedBy;
  final int durationSeconds;

  @override
  List<Object?> get props => [videoId, compressedPath, boxId, capturedBy, durationSeconds];
}
