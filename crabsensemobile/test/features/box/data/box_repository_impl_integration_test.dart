// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crabsensemobile/core/errors/exceptions.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/core/network/network_info.dart';
import 'package:crabsensemobile/features/box/data/datasources/box_local_data_source.dart';
import 'package:crabsensemobile/features/box/data/datasources/box_remote_data_source.dart';
import 'package:crabsensemobile/features/box/data/models/box_model.dart';
import 'package:crabsensemobile/features/box/data/repositories/box_repository_impl.dart';
import 'package:crabsensemobile/features/box/domain/entities/box.dart';
import 'package:crabsensemobile/features/box/domain/entities/box_enums.dart';
import 'package:crabsensemobile/features/box/domain/entities/crab.dart';
import 'package:crabsensemobile/features/box/data/models/crab_model.dart';

// ---------------------------------------------------------------------------
// Network stubs
// ---------------------------------------------------------------------------

class _FakeNetworkOnline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class _FakeNetworkOffline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;
}

// ---------------------------------------------------------------------------
// Test fixture helpers
// ---------------------------------------------------------------------------

/// A minimal [BoxModel] used across tests.
BoxModel _makeBoxModel({String id = 'box-001', String qrCode = 'CRABSENSE:BOX:box-001'}) =>
    BoxModel(
      id: id,
      qrCode: qrCode,
      farmId: 'farm-001',
      location: const Location(latitude: 10, longitude: 20, label: 'Pond A'),
      currentCrabCount: 5,
      capacity: 20,
      species: CrabSpecies.mudCrab,
      averageWeight: 150,
      status: BoxStatus.active,
      createdAt: DateTime.now(),
    );

// ---------------------------------------------------------------------------
// Remote data source stubs
// ---------------------------------------------------------------------------

class _StubRemoteSuccess implements BoxRemoteDataSource {
  _StubRemoteSuccess({BoxModel? model}) : _model = model ?? _makeBoxModel();
  final BoxModel _model;

  @override
  Future<BoxModel> getBoxDetails(String boxId) async => _model;

  @override
  Future<BoxModel> getBoxByQrCode(String qrCode) async => _model;

  @override
  Future<List<BoxModel>> getBoxesByFarm(String farmId) async => [_model];

  @override
  Future<CrabModel> addCrab(String boxId, CrabModel crab) async => crab;

  @override
  Future<void> transferCrab(String crabId, String sourceBoxId, String destinationBoxId) async {}

  @override
  Future<BoxModel> updateBox(BoxModel box) async => box;

  @override
  Future<List<CrabModel>> getCrabsByBox(String boxId) async => [];

  @override
  Future<void> deleteCrab(String crabId) async {}
}

class _StubRemoteServerError implements BoxRemoteDataSource {
  @override
  Future<BoxModel> getBoxDetails(String boxId) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);

  @override
  Future<BoxModel> getBoxByQrCode(String qrCode) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);

  @override
  Future<List<BoxModel>> getBoxesByFarm(String farmId) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);

  @override
  Future<CrabModel> addCrab(String boxId, CrabModel crab) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);

  @override
  Future<void> transferCrab(String crabId, String sourceBoxId, String destinationBoxId) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);

  @override
  Future<BoxModel> updateBox(BoxModel box) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);

  @override
  Future<List<CrabModel>> getCrabsByBox(String boxId) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);

  @override
  Future<void> deleteCrab(String crabId) async =>
      throw const ServerException(message: 'Internal error', statusCode: 500);
}

// ---------------------------------------------------------------------------
// Local data source stubs
// ---------------------------------------------------------------------------

/// Records which boxes/QR codes were cached for assertion.
class _StubLocalCapturing implements BoxLocalDataSource {
  BoxModel? _cachedBox;
  final Map<String, BoxModel> _byId = {};
  final Map<String, BoxModel> _byQr = {};

  BoxModel? get lastCachedBox => _cachedBox;

  @override
  Future<BoxModel> getCachedBox(String boxId) async {
    final found = _byId[boxId];
    if (found == null) {
      throw CacheException(message: 'No cached box: $boxId', code: 'BOX_NOT_FOUND');
    }
    return found;
  }

  @override
  Future<BoxModel> getCachedBoxByQrCode(String qrCode) async {
    final found = _byQr[qrCode];
    if (found == null) {
      throw CacheException(message: 'No cached box for QR: $qrCode', code: 'BOX_NOT_FOUND');
    }
    return found;
  }

  @override
  Future<List<BoxModel>> getCachedBoxesByFarm(String farmId) async =>
      _byId.values.where((b) => b.farmId == farmId).toList();

  @override
  Future<void> cacheBox(Box box, {bool isDirty = false}) async {
    final model = BoxModel.fromEntity(box);
    _cachedBox = model;
    _byId[box.id] = model;
    _byQr[box.qrCode] = model;
  }

  @override
  Future<void> cacheBoxes(List<Box> boxes) async {
    for (final b in boxes) {
      await cacheBox(b);
    }
  }

  @override
  Future<void> cacheCrab(Crab crab, {bool isDirty = false}) async {}

  @override
  Future<List<CrabModel>> getCachedCrabsByBox(String boxId) async => [];

  @override
  Future<void> deleteCachedCrab(String crabId) async {}

  @override
  Stream<Box> watchBox(String boxId) => const Stream.empty();
}

/// Local source that always throws [CacheException] on reads.
class _StubLocalEmpty implements BoxLocalDataSource {
  @override
  Future<BoxModel> getCachedBox(String boxId) async =>
      throw CacheException(message: 'No cached box: $boxId', code: 'BOX_NOT_FOUND');

  @override
  Future<BoxModel> getCachedBoxByQrCode(String qrCode) async =>
      throw CacheException(message: 'No cached box for QR: $qrCode', code: 'BOX_NOT_FOUND');

  @override
  Future<List<BoxModel>> getCachedBoxesByFarm(String farmId) async => [];

  @override
  Future<void> cacheBox(Box box, {bool isDirty = false}) async {}

  @override
  Future<void> cacheBoxes(List<Box> boxes) async {}

  @override
  Future<void> cacheCrab(Crab crab, {bool isDirty = false}) async {}

  @override
  Future<List<CrabModel>> getCachedCrabsByBox(String boxId) async => [];

  @override
  Future<void> deleteCachedCrab(String crabId) async {}

  @override
  Stream<Box> watchBox(String boxId) => const Stream.empty();
}

// ---------------------------------------------------------------------------
// Factory helpers
// ---------------------------------------------------------------------------

BoxRepositoryImpl _repo({
  BoxRemoteDataSource? remote,
  BoxLocalDataSource? local,
  NetworkInfo? network,
}) => BoxRepositoryImpl(
  remoteDataSource: remote ?? _StubRemoteSuccess(),
  localDataSource: local ?? _StubLocalCapturing(),
  networkInfo: network ?? _FakeNetworkOnline(),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── getBoxDetails ──────────────────────────────────────────────────────────

  group('BoxRepositoryImpl.getBoxDetails', () {
    test('online load fetches from remote, caches result, returns Right(Box)', () async {
      final local = _StubLocalCapturing();
      final model = _makeBoxModel();
      final repo = _repo(
        remote: _StubRemoteSuccess(model: model),
        local: local,
      );

      final result = await repo.getBoxDetails('box-001');

      expect(result.isRight(), isTrue, reason: 'Expected Right(Box) when online');
      result.fold((_) => fail('Expected Right'), (box) {
        expect(box.id, equals('box-001'));
        expect(box.farmId, equals('farm-001'));
      });
      // Verify the box was written to cache.
      expect(local.lastCachedBox, isNotNull, reason: 'Box should have been cached');
      expect(local.lastCachedBox!.id, equals('box-001'));
    });

    test('offline load serves cached box when available', () async {
      final local = _StubLocalCapturing();
      final model = _makeBoxModel();
      // Pre-populate the local store.
      await local.cacheBox(model);

      final repo = _repo(local: local, network: _FakeNetworkOffline());

      final result = await repo.getBoxDetails('box-001');

      expect(result.isRight(), isTrue, reason: 'Expected cached Box when offline');
      result.fold((_) => fail('Expected Right'), (box) => expect(box.id, equals('box-001')));
    });

    test('offline with no cache returns Left(CacheFailure)', () async {
      final repo = _repo(local: _StubLocalEmpty(), network: _FakeNetworkOffline());

      final result = await repo.getBoxDetails('box-001');

      expect(result.isLeft(), isTrue, reason: 'Expected failure when offline and no cache');
      result.fold((f) => expect(f, isA<CacheFailure>()), (_) => fail('Expected Left'));
    });

    test('remote server error returns Left(ServerFailure)', () async {
      final repo = _repo(remote: _StubRemoteServerError());

      final result = await repo.getBoxDetails('box-001');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left(ServerFailure)'),
      );
    });
  });

  // ── getBoxByQrCode ─────────────────────────────────────────────────────────

  group('BoxRepositoryImpl.getBoxByQrCode', () {
    test('online: fetches from remote, caches result, returns Right(Box)', () async {
      final local = _StubLocalCapturing();
      const qrCode = 'CRABSENSE:BOX:box-001';
      final model = _makeBoxModel();
      final repo = _repo(
        remote: _StubRemoteSuccess(model: model),
        local: local,
      );

      final result = await repo.getBoxByQrCode(qrCode);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (box) {
        expect(box.qrCode, equals(qrCode));
      });
      expect(local.lastCachedBox, isNotNull);
      expect(local.lastCachedBox!.qrCode, equals(qrCode));
    });

    test('offline: serves cached box by QR code when available', () async {
      final local = _StubLocalCapturing();
      const qrCode = 'CRABSENSE:BOX:box-001';
      final model = _makeBoxModel();
      await local.cacheBox(model);

      final repo = _repo(local: local, network: _FakeNetworkOffline());

      final result = await repo.getBoxByQrCode(qrCode);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (box) => expect(box.qrCode, equals(qrCode)));
    });

    test('offline with no cache returns Left(CacheFailure)', () async {
      final repo = _repo(local: _StubLocalEmpty(), network: _FakeNetworkOffline());

      final result = await repo.getBoxByQrCode('CRABSENSE:BOX:unknown');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left(CacheFailure)'),
      );
    });
  });
}
