// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter_test/flutter_test.dart';

import 'package:crabsensemobile/core/errors/exceptions.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/core/network/network_info.dart';
import 'package:crabsensemobile/features/qr_scanner/data/datasources/scanner_local_data_source.dart';
import 'package:crabsensemobile/features/qr_scanner/data/datasources/scanner_remote_data_source.dart';
import 'package:crabsensemobile/features/qr_scanner/data/repositories/scanner_repository_impl.dart';
import 'package:crabsensemobile/features/qr_scanner/domain/entities/scan_quick_result.dart';
import 'package:crabsensemobile/features/qr_scanner/domain/entities/scan_result.dart';

// ---------------------------------------------------------------------------
// Minimal test doubles (no mockito/mocktail to keep dependencies lean)
// ---------------------------------------------------------------------------

class _FakeNetworkOnline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class _FakeNetworkOffline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;
}

class _StubRemoteSuccess implements ScannerRemoteDataSource {
  _StubRemoteSuccess(this.returnBoxId);
  final String returnBoxId;

  @override
  Future<String> fetchBoxId(String qrCode) async => returnBoxId;

  @override
  Future<ScanQuickResult> fetchQuickResult({
    required String boxId,
    required String rawValue,
  }) async =>
      ScanQuickResult(
        boxId: boxId,
        code: boxId,
        rawValue: rawValue,
        scannedAt: DateTime.now(),
      );

  @override
  Future<ScanQuickResult> fetchQuickResultByQr(String rawValue) async =>
      ScanQuickResult(
        boxId: returnBoxId,
        code: returnBoxId,
        rawValue: rawValue,
        scannedAt: DateTime.now(),
      );
}

class _StubRemoteNotFound implements ScannerRemoteDataSource {
  @override
  Future<String> fetchBoxId(String qrCode) async =>
      throw const ServerException(message: 'Not found', statusCode: 404);

  @override
  Future<ScanQuickResult> fetchQuickResult({
    required String boxId,
    required String rawValue,
  }) async =>
      throw const ServerException(message: 'Not found', statusCode: 404);

  @override
  Future<ScanQuickResult> fetchQuickResultByQr(String rawValue) async =>
      throw const ServerException(message: 'Not found', statusCode: 404);
}

class _StubRemoteServerError implements ScannerRemoteDataSource {
  @override
  Future<String> fetchBoxId(String qrCode) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);

  @override
  Future<ScanQuickResult> fetchQuickResult({
    required String boxId,
    required String rawValue,
  }) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);

  @override
  Future<ScanQuickResult> fetchQuickResultByQr(String rawValue) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);
}

class _StubLocalSuccess implements ScannerLocalDataSource {
  final List<ScanResult> _queued = [];

  @override
  Future<void> queueScan(ScanResult scanResult) async {
    _queued.add(scanResult);
  }

  @override
  Future<List<ScanResult>> getPendingScans() async => List.unmodifiable(_queued);

  @override
  Future<void> markScanSynced(String scanId) async {
    _queued.removeWhere((s) => s.id == scanId);
  }

  @override
  Future<List<ScanHistoryEntry>> getScanHistory() async => const [];

  @override
  Future<void> saveScanHistory(ScanHistoryEntry entry) async {}

  @override
  Future<void> cacheQuickResult(ScanQuickResult result) async {}

  @override
  Future<ScanQuickResult?> getCachedQuickResult(String boxId) async => null;

  List<ScanResult> get queued => _queued;
}

class _StubLocalWriteError implements ScannerLocalDataSource {
  @override
  Future<void> queueScan(ScanResult scanResult) async =>
      throw const CacheException(message: 'Write error');

  @override
  Future<List<ScanResult>> getPendingScans() async => [];

  @override
  Future<void> markScanSynced(String scanId) async {}

  @override
  Future<List<ScanHistoryEntry>> getScanHistory() async => const [];

  @override
  Future<void> saveScanHistory(ScanHistoryEntry entry) async {}

  @override
  Future<void> cacheQuickResult(ScanQuickResult result) async {}

  @override
  Future<ScanQuickResult?> getCachedQuickResult(String boxId) async => null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A valid CrabSense QR value that passes client-side validation.
const validQr = 'CRABSENSE:BOX:ABC123';

/// An invalid QR value (plain text, no CRABSENSE prefix).
const invalidQr = 'random-barcode-12345';

ScannerRepositoryImpl _repo({
  ScannerRemoteDataSource? remote,
  ScannerLocalDataSource? local,
  NetworkInfo? network,
}) => ScannerRepositoryImpl(
  remoteDataSource: remote ?? _StubRemoteSuccess('ABC123'),
  localDataSource: local ?? _StubLocalSuccess(),
  networkInfo: network ?? _FakeNetworkOnline(),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ScannerRepositoryImpl.processQRCode', () {
    test('returns ValidationFailure for empty raw value', () async {
      final result = await _repo().processQRCode('');
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('expected failure'));
    });

    test('returns ValidationFailure for whitespace-only raw value', () async {
      final result = await _repo().processQRCode('   ');
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('expected failure'));
    });

    test('allows non-prefixed codes for server resolution', () async {
      final result = await _repo().processQRCode(invalidQr);
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected success'), (scan) {
        expect(scan.boxId, equals('ABC123'));
        expect(scan.isValid, isTrue);
      });
    });

    test('returns NetworkFailure when device is offline', () async {
      final result = await _repo(network: _FakeNetworkOffline()).processQRCode(validQr);
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('expected failure'));
    });

    test('returns ScanResult with correct boxId on success', () async {
      final stub = _StubRemoteSuccess('BOX-777');
      final result = await _repo(remote: stub).processQRCode('CRABSENSE:BOX:BOX-777');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected success'), (scan) {
        expect(scan.boxId, equals('BOX-777'));
        expect(scan.isValid, isTrue);
        expect(scan.isSynced, isTrue);
      });
    });

    test('returns ServerFailure.notFound when box not found on server', () async {
      final result = await _repo(remote: _StubRemoteNotFound()).processQRCode(validQr);
      expect(result.isLeft(), isTrue);
      result.fold((f) {
        expect(f, isA<ServerFailure>());
        final sf = f as ServerFailure;
        expect(sf.statusCode, equals(404));
      }, (_) => fail('expected failure'));
    });

    test('returns ServerFailure on 5xx server error', () async {
      final result = await _repo(remote: _StubRemoteServerError()).processQRCode(validQr);
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('expected failure'));
    });
  });

  group('ScannerRepositoryImpl.queueScan', () {
    test('stores scan in local data source', () async {
      final local = _StubLocalSuccess();
      final repo = _repo(local: local);

      final scan = ScanResult(
        rawValue: validQr,
        boxId: 'ABC123',
        isValid: true,
        scannedAt: DateTime.now(),
      );

      final result = await repo.queueScan(scan);
      expect(result.isRight(), isTrue);
      expect(local.queued, hasLength(1));
      expect(local.queued.first.boxId, equals('ABC123'));
    });

    test('returns CacheFailure when local write fails', () async {
      final repo = _repo(local: _StubLocalWriteError());
      final scan = ScanResult(
        rawValue: validQr,
        boxId: 'ABC123',
        isValid: true,
        scannedAt: DateTime.now(),
      );

      final result = await repo.queueScan(scan);
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<CacheFailure>()), (_) => fail('expected failure'));
    });
  });

  group('ScannerRepositoryImpl.getPendingScans', () {
    test('returns empty list when queue is empty', () async {
      final result = await _repo().getPendingScans();
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected success'), (scans) => expect(scans, isEmpty));
    });

    test('returns queued scans', () async {
      final local = _StubLocalSuccess();
      final repo = _repo(local: local);

      await local.queueScan(
        ScanResult(rawValue: validQr, boxId: 'ID1', isValid: true, scannedAt: DateTime.now()),
      );

      final result = await repo.getPendingScans();
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected success'), (scans) => expect(scans, hasLength(1)));
    });
  });

  group('ScannerRepositoryImpl.markScanSynced', () {
    test('returns ValidationFailure for empty scanId', () async {
      final result = await _repo().markScanSynced('');
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('expected failure'));
    });

    test('returns Right(null) on success', () async {
      final result = await _repo().markScanSynced('some-scan-id');
      expect(result.isRight(), isTrue);
    });
  });

  group('ScanQRCodeUseCase offline queuing integration', () {
    /// This group tests the full flow: processQRCode → NetworkFailure
    /// → use case queues the scan. The actual ScanQRCodeUseCase lives
    /// in the domain layer; here we test the repository behaviour that
    /// feeds into it (returning NetworkFailure when offline so the use
    /// case knows to queue).
    test('processQRCode returns NetworkFailure for offline device with valid QR', () async {
      final result = await _repo(
        network: _FakeNetworkOffline(),
        remote: _StubRemoteSuccess('ABC123'),
      ).processQRCode(validQr);

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('expected NetworkFailure'));
    });
  });

  group('ValidateQRCodeUseCase format enforcement', () {
    // These delegate to the domain use case via the repository's client-side
    // validation step, so they validate end-to-end QR format rules (Req 3.2, 3.3).

    final validFormats = [
      'CRABSENSE:BOX:ABC123',
      'crabsense:box:abc-123',
      'CRABSENSE:BOX:box_0001',
      'crabsense:BOX:X',
    ];

    final invalidFormats = [
      '',
      '   ',
      'ABC123',
      'BOX:ABC123',
      'CRABSENSE:ABC123',
      'CRABSENSE:BOX:',
      'CRABSENSE:BOX: ',
      'RANDOM:BOX:ABC123',
      'CRABSENSE:CRAB:ABC123',
    ];

    for (final qr in validFormats) {
      test('valid format passes: "$qr"', () async {
        final result = await _repo(remote: _StubRemoteSuccess('X')).processQRCode(qr);
        // Should reach the network stage, not fail on validation
        expect(
          result.fold((f) => f is ValidationFailure, (_) => false),
          isFalse,
          reason: '"$qr" should not produce a ValidationFailure',
        );
      });
    }

    for (final qr in invalidFormats) {
      test('invalid format rejected: "${qr.isEmpty ? "<empty>" : qr}"', () async {
        final result = await _repo().processQRCode(qr);
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(
            f,
            isA<ValidationFailure>(),
            reason: '"$qr" should produce a ValidationFailure',
          ),
          (_) => fail('expected ValidationFailure for "$qr"'),
        );
      });
    }
  });
}
