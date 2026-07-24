import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/scan_quick_result.dart';
import '../entities/scan_result.dart';

/// Repository contract for QR scan + quick-result enrichment.
abstract class ScannerRepository {
  Future<Either<Failure, ScanResult>> processQRCode(String rawValue);

  /// Resolves QR → boxId then loads enriched quick-result payload.
  Future<Either<Failure, ScanQuickResult>> processQRCodeWithQuickResult(
    String rawValue,
  );

  Future<Either<Failure, void>> queueScan(ScanResult scanResult);

  Future<Either<Failure, List<ScanResult>>> getPendingScans();

  Future<Either<Failure, void>> markScanSynced(String scanId);

  Future<Either<Failure, List<ScanHistoryEntry>>> getScanHistory();

  Future<Either<Failure, void>> saveScanHistory(ScanHistoryEntry entry);
}
