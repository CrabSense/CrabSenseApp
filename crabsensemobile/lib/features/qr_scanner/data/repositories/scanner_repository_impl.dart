import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/scan_quick_result.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../../domain/usecases/validate_qr_code_usecase.dart';
import '../datasources/scanner_local_data_source.dart';
import '../datasources/scanner_remote_data_source.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  const ScannerRepositoryImpl({
    required ScannerRemoteDataSource remoteDataSource,
    required ScannerLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remote = remoteDataSource,
       _local = localDataSource,
       _network = networkInfo;

  final ScannerRemoteDataSource _remote;
  final ScannerLocalDataSource _local;
  final NetworkInfo _network;

  static const _validator = ValidateQRCodeUseCase();

  @override
  Future<Either<Failure, ScanResult>> processQRCode(String rawValue) async {
    final validationResult = _validator(rawValue: rawValue.trim());
    if (validationResult.isLeft()) {
      return validationResult.fold(Left.new, (_) => throw StateError('unreachable'));
    }

    final boxId = validationResult.getOrElse(() => '');
    final isConnected = await _network.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final serverBoxId = await _remote.fetchBoxId(rawValue.trim());
      return Right(
        ScanResult(
          rawValue: rawValue,
          boxId: serverBoxId,
          isValid: true,
          scannedAt: DateTime.now(),
          isSynced: true,
        ),
      );
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        return Left(ServerFailure.notFound('Box with ID "$boxId"'));
      }
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure('Unexpected error processing QR: $e'));
    }
  }

  @override
  Future<Either<Failure, ScanQuickResult>> processQRCodeWithQuickResult(
    String rawValue,
  ) async {
    final validationResult = _validator(rawValue: rawValue.trim());
    if (validationResult.isLeft()) {
      return validationResult.fold(Left.new, (_) => throw StateError('unreachable'));
    }

    final isConnected = await _network.isConnected;
    if (!isConnected) {
      // Offline: try cache by extracted id / raw
      final lookup = validationResult.getOrElse(() => rawValue.trim());
      final cached = await _local.getCachedQuickResult(lookup);
      if (cached != null) {
        return Right(cached.copyWith(isOffline: true, rawValue: rawValue));
      }
      return const Left(NetworkFailure());
    }

    try {
      final quick = await _remote.fetchQuickResultByQr(rawValue.trim());
      await _local.cacheQuickResult(quick);
      await _local.saveScanHistory(
        ScanHistoryEntry(
          boxId: quick.boxId,
          code: quick.code,
          scannedAt: quick.scannedAt,
          rawValue: rawValue,
        ),
      );
      return Right(quick);
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        return Left(
          ServerFailure(
            e.message.isNotEmpty
                ? e.message
                : 'QR không thuộc hệ thống CrabSense.',
            statusCode: 404,
          ),
        );
      }
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure('Unexpected error processing QR: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> queueScan(ScanResult scanResult) async {
    try {
      await _local.queueScan(scanResult);
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure.writeError());
    } on Exception catch (e) {
      return Left(UnexpectedFailure('Failed to queue scan: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ScanResult>>> getPendingScans() async {
    try {
      final scans = await _local.getPendingScans();
      return Right(scans);
    } on CacheException {
      return const Left(CacheFailure.readError());
    } on Exception catch (e) {
      return Left(UnexpectedFailure('Failed to read pending scans: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markScanSynced(String scanId) async {
    if (scanId.trim().isEmpty) {
      return const Left(ValidationFailure.required('scanId'));
    }
    try {
      await _local.markScanSynced(scanId);
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure.writeError());
    } on Exception catch (e) {
      return Left(UnexpectedFailure('Failed to mark scan as synced: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ScanHistoryEntry>>> getScanHistory() async {
    try {
      return Right(await _local.getScanHistory());
    } on Exception catch (e) {
      return Left(UnexpectedFailure('Failed to read scan history: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveScanHistory(ScanHistoryEntry entry) async {
    try {
      await _local.saveScanHistory(entry);
      return const Right(null);
    } on Exception catch (e) {
      return Left(UnexpectedFailure('Failed to save scan history: $e'));
    }
  }
}
