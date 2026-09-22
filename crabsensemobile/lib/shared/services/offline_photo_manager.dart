import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/platform/io_export.dart';
import 'sync_queue_item.dart';
import 'sync_service.dart';

/// Stores photo bytes privately and queues only metadata for synchronization.
class OfflinePhotoManager {
  OfflinePhotoManager({
    required this.database,
    required this.syncService,
    this.uuid = const Uuid(),
  });

  final AppDatabase database;
  final SyncService syncService;
  final Uuid uuid;

  Future<PhotoAsset> save({
    required Uint8List bytes,
    required String entityType,
    required String entityId,
    required String photoType,
    String? feedingId,
    String? boxId,
    String? crabId,
  }) async {
    final id = uuid.v4();
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'photos'));
    await directory.create(recursive: true);
    final path = p.join(directory.path, '$id.jpg');
    await File(path).writeAsBytes(bytes, flush: true);
    final now = DateTime.now();

    await database
        .into(database.photoAssets)
        .insert(
          PhotoAssetsCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            photoType: photoType,
            localPath: path,
            feedingId: Value(feedingId),
            boxId: Value(boxId),
            crabId: Value(crabId),
            createdAt: now,
          ),
        );
    await syncService.enqueue(
      entityType: SyncEntityType.photo,
      operationType: 'upload_photo',
      entityId: id,
      payload: <String, dynamic>{
        'photoId': id,
        'entityType': entityType,
        'entityId': entityId,
        'photoType': photoType,
        'feedingId': feedingId,
        'boxId': boxId,
        'crabId': crabId,
        'localPath': path,
      },
      priority: SyncPriority.high,
    );
    return (database.select(
      database.photoAssets,
    )..where((table) => table.id.equals(id))).getSingle();
  }

  /// Deletes only the private file after the server has acknowledged it.
  Future<void> markUploaded(
    String id, {
    required String serverId,
    String? serverUrl,
  }) async {
    final asset = await (database.select(
      database.photoAssets,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (asset == null) return;

    await (database.update(
      database.photoAssets,
    )..where((t) => t.id.equals(id))).write(
      PhotoAssetsCompanion(
        serverId: Value(serverId),
        serverUrl: Value(serverUrl),
        uploadStatus: const Value('synced'),
        uploadedAt: Value(DateTime.now()),
      ),
    );
    final file = File(asset.localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
