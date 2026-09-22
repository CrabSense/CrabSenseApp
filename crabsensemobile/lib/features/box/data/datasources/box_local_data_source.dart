// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart' as database;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/box.dart';
import '../../domain/entities/crab.dart' as domain show Crab;
import '../models/box_model.dart';
import '../models/crab_model.dart';

/// Local data source interface for box and crab cache operations.
///
/// All methods read from and write to the Drift SQLite database.
/// Throws [CacheException] on any storage failure.
///
/// Requirements: 4.1-4.10, 13.3, 16.1-16.10
abstract class BoxLocalDataSource {
  /// Fetches a cached box by its ID.
  ///
  /// Throws [CacheException] if no matching row is found.
  Future<BoxModel> getCachedBox(String boxId);

  /// Fetches a cached box by its QR code.
  ///
  /// Throws [CacheException] if no matching row is found.
  Future<BoxModel> getCachedBoxByQrCode(String qrCode);

  /// Fetches all cached boxes belonging to a farm.
  ///
  /// Returns an empty list when no boxes are cached for the farm.
  Future<List<BoxModel>> getCachedBoxesByFarm(String farmId);

  /// Inserts or replaces a box in the local cache.
  ///
  /// Throws [CacheException] on write failure.
  Future<void> cacheBox(Box box, {bool isDirty = false});

  /// Inserts or replaces multiple boxes in the local cache.
  ///
  /// Throws [CacheException] on write failure.
  Future<void> cacheBoxes(List<Box> boxes);

  /// Inserts or replaces a crab record in the local cache.
  ///
  /// Throws [CacheException] on write failure.
  Future<void> cacheCrab(domain.Crab crab, {bool isDirty = false});

  /// Fetches all cached crab records for the specified box.
  ///
  /// Returns an empty list when no crabs are cached.
  Future<List<CrabModel>> getCachedCrabsByBox(String boxId);

  /// Removes a crab record from the local cache.
  ///
  /// Throws [CacheException] on write failure.
  Future<void> deleteCachedCrab(String crabId);

  /// Moves a cached crab to another box without waiting for the server.
  Future<void> moveCachedCrab(String crabId, String destinationBoxId) =>
      throw const CacheException(
        message: 'Moving cached crabs is not supported by this data source.',
        code: 'CACHE_WRITE_ERROR',
      );

  /// Returns a live stream of a box row from the local cache.
  ///
  /// Emits the latest [Box] state whenever the row changes.
  ///
  /// Requirements: 4.1, 4.7
  Stream<Box> watchBox(String boxId);
}

/// Drift-based implementation of [BoxLocalDataSource].
class BoxLocalDataSourceImpl implements BoxLocalDataSource {
  BoxLocalDataSourceImpl({required this.db});

  final database.AppDatabase db;

  // ---------------------------------------------------------------------------
  // BoxLocalDataSource implementation
  // ---------------------------------------------------------------------------

  @override
  Future<BoxModel> getCachedBox(String boxId) async {
    try {
      final row = await (db.select(
        db.boxes,
      )..where((t) => t.id.equals(boxId))).getSingleOrNull();

      if (row == null) {
        throw CacheException(
          message: 'No cached box found with id: $boxId',
          code: 'BOX_NOT_FOUND',
        );
      }

      return BoxModel.fromDrift(
        id: row.id,
        qrCode: row.qrCode,
        farmId: row.farmId,
        pondId: row.pondId,
        locationJson: row.location,
        currentCrabCount: row.currentCrabCount,
        capacity: row.capacity,
        species: row.species,
        averageWeight: row.averageWeight,
        status: row.status,
        createdAt: row.createdAt,
        lastVideoAt: row.lastVideoAt,
      );
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read box from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<BoxModel> getCachedBoxByQrCode(String qrCode) async {
    try {
      final row = await (db.select(
        db.boxes,
      )..where((t) => t.qrCode.equals(qrCode))).getSingleOrNull();

      if (row == null) {
        throw CacheException(
          message: 'No cached box found with QR code: $qrCode',
          code: 'BOX_NOT_FOUND',
        );
      }

      return BoxModel.fromDrift(
        id: row.id,
        qrCode: row.qrCode,
        farmId: row.farmId,
        pondId: row.pondId,
        locationJson: row.location,
        currentCrabCount: row.currentCrabCount,
        capacity: row.capacity,
        species: row.species,
        averageWeight: row.averageWeight,
        status: row.status,
        createdAt: row.createdAt,
        lastVideoAt: row.lastVideoAt,
      );
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read box by QR code from cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<List<BoxModel>> getCachedBoxesByFarm(String farmId) async {
    try {
      final rows = await (db.select(
        db.boxes,
      )..where((t) => t.farmId.equals(farmId))).get();

      return rows
          .map(
            (row) => BoxModel.fromDrift(
              id: row.id,
              qrCode: row.qrCode,
              farmId: row.farmId,
              pondId: row.pondId,
              locationJson: row.location,
              currentCrabCount: row.currentCrabCount,
              capacity: row.capacity,
              species: row.species,
              averageWeight: row.averageWeight,
              status: row.status,
              createdAt: row.createdAt,
              lastVideoAt: row.lastVideoAt,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read boxes from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> cacheBox(Box box, {bool isDirty = false}) async {
    try {
      final companion = BoxModel.fromEntity(
        box,
      ).toDriftCompanion(isDirty: isDirty);
      await db.into(db.boxes).insertOnConflictUpdate(companion);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache box: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> cacheBoxes(List<Box> boxes) async {
    try {
      await db.transaction(() async {
        for (final box in boxes) {
          final companion = BoxModel.fromEntity(box).toDriftCompanion();
          await db.into(db.boxes).insertOnConflictUpdate(companion);
        }
      });
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache boxes: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> cacheCrab(domain.Crab crab, {bool isDirty = false}) async {
    try {
      final companion = CrabModel.fromEntity(
        crab,
      ).toDriftCompanion(isDirty: isDirty);
      await db.into(db.crabs).insertOnConflictUpdate(companion);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache crab: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<List<CrabModel>> getCachedCrabsByBox(String boxId) async {
    try {
      final rows = await (db.select(
        db.crabs,
      )..where((t) => t.boxId.equals(boxId))).get();

      return rows
          .map(
            (row) => CrabModel.fromDrift(
              id: row.id,
              boxId: row.boxId,
              species: row.species,
              weight: row.weight,
              moltingStatus: row.moltingStatus,
              healthStatus: row.healthStatus,
              source: row.source,
              addedAt: row.addedAt,
              addedBy: row.addedBy,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read crabs from local cache: $e',
        code: 'CACHE_READ_ERROR',
      );
    }
  }

  @override
  Future<void> deleteCachedCrab(String crabId) async {
    try {
      await (db.delete(db.crabs)..where((t) => t.id.equals(crabId))).go();
    } catch (e) {
      throw CacheException(
        message: 'Failed to delete crab from local cache: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Future<void> moveCachedCrab(String crabId, String destinationBoxId) async {
    try {
      await (db.update(db.crabs)..where((t) => t.id.equals(crabId))).write(
        database.CrabsCompanion(boxId: Value(destinationBoxId)),
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to move crab in local cache: $e',
        code: 'CACHE_WRITE_ERROR',
      );
    }
  }

  @override
  Stream<Box> watchBox(String boxId) =>
      (db.select(db.boxes)..where((t) => t.id.equals(boxId))).watchSingle().map(
        (row) => BoxModel.fromDrift(
          id: row.id,
          qrCode: row.qrCode,
          farmId: row.farmId,
          pondId: row.pondId,
          locationJson: row.location,
          currentCrabCount: row.currentCrabCount,
          capacity: row.capacity,
          species: row.species,
          averageWeight: row.averageWeight,
          status: row.status,
          createdAt: row.createdAt,
          lastVideoAt: row.lastVideoAt,
        ),
      );
}
