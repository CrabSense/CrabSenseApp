import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/scan_result.dart';
import '../repositories/scanner_repository.dart';

/// Use case for processing a scanned QR code.
///
/// This use case encapsulates the business logic for QR scanning:
/// 1. Validates that the raw value is not empty
/// 2. Delegates to the repository to process the QR code
/// 3. On network failure, queues the scan for offline sync and
///    returns a ScanResult with isSynced: false
///
/// Requirements: 3.2, 3.3, 3.6, 3.7
class ScanQRCodeUseCase {
  const ScanQRCodeUseCase(this._repository);

  final ScannerRepository _repository;

  /// Executes the scan QR code use case with the provided raw value.
  ///
  /// Parameters:
  /// - [rawValue]: The raw string decoded from the QR code scanner
  ///
  /// Returns:
  /// - Right(ScanResult): Successfully processed or queued scan result
  /// - Left(ValidationFailure.required): rawValue is empty
  /// - Left(ServerFailure.notFound): Box identifier not found on server
  /// - Left(ServerFailure): Server error during processing
  /// - Left(CacheFailure): Error queuing scan offline (network path)
  ///
  /// Requirements: 3.2, 3.3, 3.7
  Future<Either<Failure, ScanResult>> call({required String rawValue}) async {
    // Validate rawValue is not empty
    if (rawValue.trim().isEmpty) {
      return const Left(ValidationFailure.required('QR code'));
    }

    // Delegate to repository for processing
    final result = await _repository.processQRCode(rawValue);

    return result.fold((failure) async {
      // On network failure, queue for offline sync
      if (failure is NetworkFailure) {
        return _handleOfflineScan(rawValue);
      }
      // For other failures, propagate the error
      return Left(failure);
    }, Right.new);
  }

  /// Handles the offline scenario by queuing the scan locally.
  ///
  /// Creates a ScanResult with isSynced: false and stores it in the
  /// local queue for later sync when connectivity returns.
  Future<Either<Failure, ScanResult>> _handleOfflineScan(
    String rawValue,
  ) async {
    final boxId = _extractBoxIdFromRaw(rawValue);

    final offlineScanResult = ScanResult(
      rawValue: rawValue,
      boxId: boxId,
      isValid: true,
      scannedAt: DateTime.now(),
    );

    final queueResult = await _repository.queueScan(offlineScanResult);

    return queueResult.fold(Left.new, (_) => Right(offlineScanResult));
  }

  /// Attempts to extract a box ID from the raw QR value.
  ///
  /// Uses the `CRABSENSE:BOX:<boxId>` format. Returns the raw value
  /// as fallback if the format does not match.
  String _extractBoxIdFromRaw(String rawValue) {
    final parts = rawValue.split(':');
    if (parts.length == 3 &&
        parts[0].toUpperCase() == 'CRABSENSE' &&
        parts[1].toUpperCase() == 'BOX' &&
        parts[2].isNotEmpty) {
      return parts[2];
    }
    return rawValue;
  }
}
