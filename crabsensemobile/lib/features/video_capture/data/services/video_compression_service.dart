// ignore_for_file: lines_longer_than_80_chars

import 'package:crabsensemobile/core/platform/io_export.dart';

import 'package:logger/logger.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../core/errors/exceptions.dart';

/// Result of a video compression operation.
class CompressionResult {
  const CompressionResult({
    required this.compressedPath,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
  });

  /// Absolute path to the compressed video file on local storage.
  final String compressedPath;

  /// Original uncompressed file size in bytes.
  final int originalSizeBytes;

  /// Compressed file size in bytes.
  final int compressedSizeBytes;

  /// Returns the compression ratio achieved (0.0 – 1.0).
  ///
  /// A value of 0.7 means the file was reduced by 70%.
  double get compressionRatio =>
      originalSizeBytes > 0 ? 1.0 - (compressedSizeBytes / originalSizeBytes) : 0.0;

  /// Returns true if the compressed output is within the 10 MB limit.
  ///
  /// Requirement 5.4
  bool get isWithinSizeLimit => compressedSizeBytes <= _maxFileSizeBytes;

  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
}

/// Service responsible for compressing video files before upload.
///
/// Uses the `video_compress` package (FFmpeg-based) to reduce file sizes
/// by up to 70% without perceptible quality loss.
///
/// - Target output: < 10 MB (Requirement 5.4)
/// - Target reduction: 70% (Requirement 22.7)
/// - Progress callbacks are forwarded to the caller for UI updates.
///
/// Throws [ServerException] if compression fails.
///
/// Requirements: 5.4, 22.7
class VideoCompressionService {
  VideoCompressionService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  /// Compresses the video at [inputPath] and returns a [CompressionResult].
  ///
  /// [onProgress] receives values in [0.0, 1.0] as compression advances.
  ///
  /// The compressed file is written to the application temp directory
  /// alongside the original. The caller is responsible for deleting the
  /// output after a successful upload.
  ///
  /// Throws [ServerException] on any compression error.
  ///
  /// Requirements: 5.4, 22.7
  Future<CompressionResult> compress(
    String inputPath, {
    void Function(double progress)? onProgress,
  }) async {
    _logger.d('VideoCompressionService: starting compression for $inputPath');

    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      throw ServerException(
        message: 'Video file not found at path: $inputPath',
        code: 'FILE_NOT_FOUND',
      );
    }

    final originalSize = await inputFile.length();
    _logger.d(
      'VideoCompressionService: original size '
      '${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    // Subscribe to video_compress progress stream before starting.
    final progressSubscription = VideoCompress.compressProgress$.subscribe((progress) {
      // progress is 0–100; normalise to 0.0–1.0.
      onProgress?.call((progress / 100.0).clamp(0.0, 1.0));
    });

    try {
      final info = await VideoCompress.compressVideo(
        inputPath,
        quality: VideoQuality.MediumQuality,
        includeAudio: false,
      );

      if (info == null || info.path == null) {
        throw ServerException(
          message: 'Compression returned null result for: $inputPath',
          code: 'COMPRESSION_NULL_RESULT',
        );
      }

      final compressedPath = info.path!;
      final compressedSize = info.filesize ?? await File(compressedPath).length();

      _logger.i(
        'VideoCompressionService: compressed '
        '${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB → '
        '${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      final result = CompressionResult(
        compressedPath: compressedPath,
        originalSizeBytes: originalSize,
        compressedSizeBytes: compressedSize,
      );

      if (!result.isWithinSizeLimit) {
        _logger.w(
          'VideoCompressionService: compressed file '
          '(${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB) '
          'still exceeds the 10 MB limit after compression.',
        );
      }

      _logger.d(
        'VideoCompressionService: compression ratio '
        '${(result.compressionRatio * 100).toStringAsFixed(1)}%',
      );

      return result;
    } on ServerException {
      rethrow;
    } catch (e) {
      _logger.e('VideoCompressionService: compression failed', error: e);
      throw ServerException(message: 'Video compression failed: $e', code: 'COMPRESSION_FAILED');
    } finally {
      progressSubscription.unsubscribe();
      // Cancel any in-flight compression so resources are freed.
      // video_compress exposes cancelCompression only as a no-op when
      // compression has already finished, so it is safe to call here.
      try {
        await VideoCompress.cancelCompression();
      } catch (_) {
        // Ignore – compression may have already completed.
      }
    }
  }

  /// Deletes a previously compressed file to free storage.
  ///
  /// Silent on failure (file may have already been deleted).
  Future<void> deleteCompressedFile(String compressedPath) async {
    try {
      final file = File(compressedPath);
      if (file.existsSync()) {
        await file.delete();
        _logger.d('VideoCompressionService: deleted compressed file $compressedPath');
      }
    } catch (e) {
      _logger.w('VideoCompressionService: failed to delete $compressedPath: $e');
    }
  }
}
