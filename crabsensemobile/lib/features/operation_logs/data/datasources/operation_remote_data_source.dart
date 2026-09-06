// ignore_for_file: lines_longer_than_80_chars

import 'package:crabsensemobile/core/platform/io_export.dart';

import 'package:dio/dio.dart' show DioException, FormData, MultipartFile;
import 'package:logger/logger.dart';
import 'package:path/path.dart' show basename;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/operation_type.dart';
import '../models/operation_log_model.dart';

/// Contract for fetching and mutating operation log data on the remote API.
///
/// All methods throw typed exceptions on failure:
/// - [ServerException]: 4xx / 5xx API responses.
/// - [NetworkException]: No connectivity or request timeout.
/// - [ParseException]: Malformed or unexpected JSON response body.
///
/// Requirements: 10.1-10.10
abstract class OperationRemoteDataSource {
  /// Fetches operation logs for a specific box.
  ///
  /// Results are sorted by timestamp descending (newest first).
  ///
  /// Requirements: 10.4, 10.8
  Future<List<OperationLogModel>> getOperationLogs(String boxId);

  /// Creates a new operation log on the server.
  ///
  /// Returns the created model with a server-assigned ID.
  ///
  /// Requirements: 10.1-10.7, 10.10
  Future<OperationLogModel> createOperationLog(OperationLogModel model);

  /// Updates an existing operation log on the server.
  ///
  /// Returns the updated model. Throws [ServerException] with status 404
  /// if the log with [id] does not exist.
  ///
  /// Requirements: 10.9
  Future<OperationLogModel> updateOperationLog(String id, OperationLogModel model);

  /// Fetches a paginated, optionally filtered operation history for a box.
  ///
  /// [page] is 1-based. [limit] controls page size (default 50).
  ///
  /// Requirements: 10.8
  Future<List<OperationLogModel>> getOperationHistory({
    required String boxId,
    int page = 1,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
  });

  /// Fetches all farm operations across every box, paginated.
  ///
  /// Backed by `GET /operations`. Used by the operation history screen.
  Future<List<OperationLogModel>> getAllOperations({
    int page = 1,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
  });
}

/// Dio-backed implementation of [OperationRemoteDataSource].
///
/// Uses [ApiClient.safeGet] / [ApiClient.safePost] / [ApiClient.safePut]
/// which map [DioException] to domain [Failure] objects. Failures are
/// re-raised as typed exceptions so the repository layer can handle them
/// uniformly — matching the alert remote data source pattern.
class OperationRemoteDataSourceImpl implements OperationRemoteDataSource {
  OperationRemoteDataSourceImpl({required this.apiClient, required this.logger});

  final ApiClient apiClient;
  final Logger logger;

  // ──────────────────────────────────────────────────────────────────────────
  // OperationRemoteDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<OperationLogModel>> getOperationLogs(String boxId) async {
    logger.d('OperationRemote: getOperationLogs boxId=$boxId');

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.operationsForBox(boxId),
    );

    _checkFailure(result.failure, 'operation logs for box $boxId');

    final items = _extractList(result.data.data, 'getOperationLogs');
    return items
        .map((e) => OperationLogModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<OperationLogModel> createOperationLog(OperationLogModel model) async {
    logger.d('OperationRemote: createOperationLog type=${model.type.name}');

    final photoUrls = await _uploadLocalPhotos(model.photoUrls, model.boxIds);
    final payload = model.copyWith(photoUrls: photoUrls);

    final result = await apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.operations,
      data: payload.toJson(),
    );

    _checkFailure(result.failure, 'create operation log');

    final body = result.data.data;
    if (body == null) {
      throw const ServerException(
        message: 'Empty response from create operation endpoint',
        code: 'PARSE_ERROR',
      );
    }

    return OperationLogModel.fromJson(_unwrapData(body));
  }

  Future<List<String>> _uploadLocalPhotos(List<String> paths, List<String> boxIds) async {
    final urls = <String>[];
    for (final path in paths) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        urls.add(path);
        continue;
      }
      final file = File(path);
      if (!file.existsSync()) continue;
      try {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(path, filename: basename(path)),
          if (boxIds.isNotEmpty) 'boxId': boxIds.first,
        });
        final response = await apiClient.dio.post<Map<String, dynamic>>(
          ApiConstants.uploadOperationPhoto,
          data: form,
        );
        final body = response.data;
        if (body == null) continue;
        final data = body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : body;
        final url = data['url']?.toString();
        if (url != null && url.isNotEmpty) urls.add(url);
      } on DioException catch (e) {
        logger.w('OperationRemote: photo upload failed — ${e.message}');
      }
    }
    return urls;
  }

  @override
  Future<OperationLogModel> updateOperationLog(String id, OperationLogModel model) async {
    logger.d('OperationRemote: updateOperationLog id=$id');

    final result = await apiClient.safePut<Map<String, dynamic>>(
      ApiConstants.operationDetails(id),
      data: model.toJson(),
    );

    _checkFailure(result.failure, 'update operation log $id');

    final body = result.data.data;
    if (body == null) {
      throw ServerException(
        message: 'Empty response from update operation endpoint for id=$id',
        code: 'PARSE_ERROR',
      );
    }

    return OperationLogModel.fromJson(_unwrapData(body));
  }

  @override
  Future<List<OperationLogModel>> getOperationHistory({
    required String boxId,
    int page = 1,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
  }) async {
    logger.d('OperationRemote: getOperationHistory boxId=$boxId page=$page limit=$limit');

    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (type != null) {
      queryParams['type'] = type.name;
    }

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.operationsForBox(boxId),
      queryParameters: queryParams,
    );

    _checkFailure(result.failure, 'operation history for box $boxId');

    final items = _extractList(result.data.data, 'getOperationHistory');
    return items
        .map((e) => OperationLogModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<OperationLogModel>> getAllOperations({
    int page = 1,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    OperationType? type,
  }) async {
    logger.d('OperationRemote: getAllOperations page=$page limit=$limit');

    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (type != null) {
      queryParams['type'] = type.name;
    }

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.operations,
      queryParameters: queryParams,
    );

    _checkFailure(result.failure, 'all operations');

    final items = _extractList(result.data.data, 'getAllOperations');
    return items
        .map((e) => OperationLogModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Throws the appropriate typed exception when [failure] is non-null.
  void _checkFailure(Failure? failure, String context) {
    if (failure == null) return;

    if (failure is NetworkFailure) {
      throw NetworkException(message: failure.message, code: failure.code);
    }

    if (failure is ServerFailure) {
      throw ServerException(
        message: failure.message,
        statusCode: failure.statusCode,
        code: failure.code,
      );
    }

    throw ServerException(
      message: 'Failed to fetch $context: ${failure.message}',
      code: failure.code,
    );
  }

  /// Extracts a list payload from the API response body.
  ///
  /// The CrabSense API may wrap results in `{ "data": [...] }` or
  /// return the list directly.
  List<dynamic> _extractList(Map<String, dynamic>? body, String operationName) {
    if (body == null) return [];

    if (body.containsKey('data') && body['data'] is List<dynamic>) {
      return body['data'] as List<dynamic>;
    }

    if (body.containsKey('items') && body['items'] is List<dynamic>) {
      return body['items'] as List<dynamic>;
    }

    logger.w('OperationRemote: unexpected response shape in $operationName');
    return [];
  }

  /// Unwraps a `{ "data": {...} }` envelope, or returns the map directly.
  Map<String, dynamic> _unwrapData(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body;
  }
}
