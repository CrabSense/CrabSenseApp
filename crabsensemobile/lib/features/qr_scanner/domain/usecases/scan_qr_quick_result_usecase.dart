import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/scan_quick_result.dart';
import '../entities/scan_result.dart';
import '../repositories/scanner_repository.dart';

/// Process QR and return enriched quick-result for the bottom sheet.
class ScanQRQuickResultUseCase {
  const ScanQRQuickResultUseCase(this._repository);

  final ScannerRepository _repository;

  Future<Either<Failure, ScanQuickResult>> call({required String rawValue}) async {
    if (rawValue.trim().isEmpty) {
      return const Left(ValidationFailure.required('QR code'));
    }

    final result = await _repository.processQRCodeWithQuickResult(rawValue);
    return result.fold((failure) async {
      if (failure is NetworkFailure) {
        await _repository.queueScan(
          ScanResult(
            rawValue: rawValue,
            boxId: '',
            isValid: true,
            scannedAt: DateTime.now(),
            isSynced: false,
          ),
        );
      }
      return Left(failure);
    }, Right.new);
  }
}
