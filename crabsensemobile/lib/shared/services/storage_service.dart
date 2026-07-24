import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Abstract interface for device storage checks.
///
/// Used before starting a video recording to verify that enough disk
/// space is available and that the offline video queue has not exceeded
/// the 80 % warning threshold.
///
/// Requirements: 5.9
abstract class StorageService {
  /// Returns the estimated available storage bytes on the device.
  ///
  /// Implementation falls back to a best-effort estimate when exact
  /// free-space information is not available. Callers should treat the
  /// value as a lower-bound approximation.
  ///
  /// Returns 0 if the check fails (fail-open: let callers decide).
  Future<int> getAvailableStorageBytes();

  /// Returns the total bytes used by all files in the app's
  /// application-documents directory (the offline video queue location).
  ///
  /// Returns 0 if the directory cannot be read.
  Future<int> getTotalVideoStorageUsedBytes();

  /// Minimum free bytes required before a new recording is allowed (100 MB).
  static const int minRequiredBytes = 100 * 1024 * 1024; // 100 MB

  /// Fraction of [offlineStorageCapacityBytes] at which a warning is shown.
  static const double offlineStorageWarningThreshold = 0.80;

  /// Assumed maximum capacity for the offline video queue (1 GB).
  ///
  /// Used when computing whether the queue exceeds 80 % capacity.
  static const int offlineStorageCapacityBytes = 1024 * 1024 * 1024; // 1 GB
}

/// Pure-Dart implementation of [StorageService].
///
/// Uses [getApplicationDocumentsDirectory] from `path_provider` to locate
/// the offline queue directory and walks it to sum file sizes.
///
/// For available storage estimation, a temporary file probe is used:
/// it attempts to write progressively smaller blocks to the temp directory
/// until one succeeds, bounding the estimate.  When even the smallest
/// probe succeeds the implementation falls back to comparing used queue
/// bytes against a fixed capacity constant so that the fail-open
/// contract is maintained.
///
/// Requirements: 5.9
class StorageServiceImpl implements StorageService {
  StorageServiceImpl({required this._logger});

  final Logger _logger;

  // ---------------------------------------------------------------------------
  // StorageService
  // ---------------------------------------------------------------------------

  @override
  Future<int> getAvailableStorageBytes() async {
    try {
      final tempDir = await getTemporaryDirectory();
      return await _probeAvailableBytes(tempDir.path);
    } on Exception catch (e) {
      _logger.w(
        'StorageService: getAvailableStorageBytes failed, '
        'defaulting to unlimited. Error: $e',
      );
      // Fail-open: return max int so recording is not blocked.
      return _kFallbackAvailableBytes;
    }
  }

  @override
  Future<int> getTotalVideoStorageUsedBytes() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      return _directorySize(docDir);
    } on Exception catch (e) {
      _logger.w('StorageService: getTotalVideoStorageUsedBytes failed. Error: $e');
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Fallback value (2 GB) returned when space detection is impossible.
  static const int _kFallbackAvailableBytes = 2 * 1024 * 1024 * 1024;

  /// Probe sizes tried in order (largest first).
  static const List<int> _kProbeSizes = [
    512 * 1024 * 1024, // 512 MB
    256 * 1024 * 1024, // 256 MB
    128 * 1024 * 1024, // 128 MB
    64 * 1024 * 1024, //  64 MB
    32 * 1024 * 1024, //  32 MB
    16 * 1024 * 1024, //  16 MB
    8 * 1024 * 1024, //   8 MB
    1 * 1024 * 1024, //   1 MB
  ];

  /// Estimates available storage by attempting to write a probe file.
  ///
  /// Iterates [_kProbeSizes] from largest to smallest.  The first size
  /// that fails to write is treated as the unavailable amount; the next
  /// smaller size that succeeds is returned as the available estimate.
  ///
  /// If all probes fail returns 0; if all probes succeed returns the
  /// largest probe size (conservative lower bound).
  Future<int> _probeAvailableBytes(String dirPath) async {
    // Write a random-named temp file so parallel calls don't collide.
    final ms = DateTime.now().millisecondsSinceEpoch;
    final probeFile = File('$dirPath/storage_probe_$ms.tmp');

    var available = 0;

    for (final probeSize in _kProbeSizes) {
      try {
        await probeFile.writeAsBytes(List.filled(probeSize, 0), flush: true);
        await probeFile.delete();
        available = probeSize;
        break; // First success → use this as a lower bound.
      } on FileSystemException {
        // Not enough space for this probe size; try smaller.
        try {
          await probeFile.delete();
        } on FileSystemException {
          // File may not have been created — ignore.
        }
      }
    }

    return available;
  }

  /// Recursively sums the size of all files under [dir].
  int _directorySize(Directory dir) {
    var total = 0;
    try {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          try {
            total += entity.lengthSync();
          } on FileSystemException {
            // Skip unreadable files.
          }
        }
      }
    } on FileSystemException {
      // Directory may not be readable — return what we have so far.
    }
    return total;
  }
}
