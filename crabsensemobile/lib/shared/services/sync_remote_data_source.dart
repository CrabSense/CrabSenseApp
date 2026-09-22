import 'package:logger/logger.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import 'sync_queue_item.dart';

/// Contract for remote operations during offline-first sync.
abstract class SyncRemoteDataSource {
  /// Batch uploads offline queue items to the remote API.
  ///
  /// Requirements: 13.5, 22.9
  Future<Map<String, dynamic>> uploadBatch(List<SyncQueueItem> items);

  /// Downloads server changes since [since] timestamp.
  ///
  /// Requirements: 13.5
  Future<Map<String, dynamic>> downloadServerChanges({DateTime? since});
}

/// Implementation of [SyncRemoteDataSource] using [ApiClient].
class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  SyncRemoteDataSourceImpl({required this.apiClient, required this.logger});

  final ApiClient apiClient;
  final Logger logger;

  @override
  Future<Map<String, dynamic>> uploadBatch(List<SyncQueueItem> items) async {
    if (items.isEmpty) {
      return <String, dynamic>{'success': true, 'processedCount': 0};
    }

    try {
      final payloadList = items
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'entityType': item.entityType.code,
              'operationType': item.operationType,
              'entityId': item.entityId,
              'payload': item.payload,
              'idempotencyKey': item.id,
              'baseVersion': item.payload['baseVersion'],
              'clientUpdatedAt':
                  item.payload['clientUpdatedAt'] ??
                  item.createdAt.toIso8601String(),
              'createdAt': item.createdAt.toIso8601String(),
              'priority': item.priority.value,
              'retryCount': item.retryCount,
            },
          )
          .toList();

      final response = await apiClient.post<Map<String, dynamic>>(
        ApiConstants.uploadBatch,
        data: <String, dynamic>{'items': payloadList},
      );

      return _unwrap(response.data);
    } on Exception catch (e) {
      logger.e('SyncRemoteDataSource: Batch upload failed: $e');
      throw ServerException(
        message: 'Failed to upload batch sync items: $e',
        code: 'SYNC_UPLOAD_ERROR',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> downloadServerChanges({DateTime? since}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (since != null) {
        queryParams['since'] = since.toIso8601String();
      }

      final response = await apiClient.get<Map<String, dynamic>>(
        ApiConstants.syncPull,
        queryParameters: queryParams,
      );

      return _unwrap(response.data);
    } on Exception catch (e) {
      logger.e('SyncRemoteDataSource: Download server changes failed: $e');
      throw ServerException(
        message: 'Failed to download server changes: $e',
        code: 'SYNC_DOWNLOAD_ERROR',
      );
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? raw) {
    final map = raw ?? <String, dynamic>{};
    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    return map;
  }
}
