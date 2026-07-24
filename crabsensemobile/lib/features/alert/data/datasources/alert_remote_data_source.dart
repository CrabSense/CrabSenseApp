// ignore_for_file: lines_longer_than_80_chars

import 'package:dio/dio.dart' show DioException;
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/alert_repository.dart' show AlertFilters;
import '../models/alert_model.dart';

/// Contract for fetching alert data from the remote API.
///
/// All methods throw typed exceptions on failure:
/// - [ServerException]: 4xx / 5xx API responses.
/// - [NetworkException]: No connectivity or request timeout.
/// - [ParseException]: Malformed or unexpected JSON response body.
///
/// Requirements: 9.1-9.10
abstract class AlertRemoteDataSource {
  /// Fetches alerts from the server, optionally filtered.
  ///
  /// Results are sorted by createdAt descending (newest first).
  ///
  /// Requirements: 9.4, 9.5, 9.8
  Future<List<AlertModel>> getAlerts({AlertFilters? filters});

  /// Fetches a single alert by its unique identifier.
  ///
  /// Throws [ServerException] with status 404 if not found.
  ///
  /// Requirements: 9.5
  Future<AlertModel> getAlertById(String alertId);

  /// Acknowledges the specified alert on the server.
  ///
  /// Returns the updated [AlertModel] with acknowledged status.
  ///
  /// Requirements: 9.6, 9.7
  Future<AlertModel> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
  });

  /// Dismisses the specified alert on the server.
  ///
  /// Returns the updated [AlertModel] with dismissed status.
  ///
  /// Requirements: 9.6
  Future<AlertModel> dismissAlert(String alertId);

  /// Returns the current count of unread alerts.
  ///
  /// Requirements: 9.2
  Future<int> getUnreadCount();
}

/// Dio-backed implementation of [AlertRemoteDataSource].
///
/// Uses [ApiClient.safeGet] / [ApiClient.safePost] which map
/// [DioException] to domain [Failure] objects. Failures are
/// converted back to typed exceptions here so the repository layer
/// can handle them uniformly — the same pattern as the water quality
/// remote data source.
class AlertRemoteDataSourceImpl implements AlertRemoteDataSource {
  AlertRemoteDataSourceImpl({required this._apiClient, required this._logger});

  final ApiClient _apiClient;
  final Logger _logger;

  // ──────────────────────────────────────────────────────────────────────────
  // AlertRemoteDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<AlertModel>> getAlerts({AlertFilters? filters}) async {
    _logger.d('AlertRemote: getAlerts filters=$filters');

    final queryParams = <String, dynamic>{};
    if (filters != null) {
      if (filters.severity != null) {
        queryParams['severity'] = filters.severity!.name;
      }
      if (filters.type != null) {
        queryParams['type'] = filters.type!.name;
      }
      if (filters.status != null) {
        queryParams['status'] = filters.status!.name;
      }
    }

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.alerts,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    _checkFailure(result.failure, 'alerts list');

    final items = _extractList(result.data.data, 'getAlerts');
    return items
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<AlertModel> getAlertById(String alertId) async {
    _logger.d('AlertRemote: getAlertById alertId=$alertId');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.alertDetails(alertId),
    );

    _checkFailure(result.failure, 'alert $alertId');

    final body = result.data.data;
    if (body == null) {
      throw ServerException(
        message: 'Empty response for alert $alertId',
        statusCode: 404,
        code: 'NOT_FOUND',
      );
    }

    // Response may be wrapped in { "data": {...} } or returned directly.
    final Map<String, dynamic> alertJson;
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      alertJson = body['data'] as Map<String, dynamic>;
    } else {
      alertJson = body;
    }

    return AlertModel.fromJson(alertJson);
  }

  @override
  Future<AlertModel> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
  }) async {
    _logger.d(
      'AlertRemote: acknowledgeAlert alertId=$alertId acknowledgedBy=[redacted]',
    );

    final result = await _apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.acknowledgeAlert(alertId),
      data: {'userId': acknowledgedBy, 'acknowledgedBy': acknowledgedBy},
    );

    _checkFailure(result.failure, 'acknowledge alert $alertId');

    final body = result.data.data;
    if (body == null) {
      throw const ServerException(
        message: 'Empty response from acknowledge endpoint',
        code: 'PARSE_ERROR',
      );
    }

    final Map<String, dynamic> alertJson;
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      alertJson = body['data'] as Map<String, dynamic>;
    } else {
      alertJson = body;
    }

    return AlertModel.fromJson(alertJson);
  }

  @override
  Future<AlertModel> dismissAlert(String alertId) async {
    _logger.d('AlertRemote: dismissAlert alertId=$alertId');

    final result = await _apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.dismissAlert(alertId),
    );

    _checkFailure(result.failure, 'dismiss alert $alertId');

    final body = result.data.data;
    if (body == null) {
      throw const ServerException(
        message: 'Empty response from dismiss endpoint',
        code: 'PARSE_ERROR',
      );
    }

    final Map<String, dynamic> alertJson;
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      alertJson = body['data'] as Map<String, dynamic>;
    } else {
      alertJson = body;
    }

    return AlertModel.fromJson(alertJson);
  }

  @override
  Future<int> getUnreadCount() async {
    _logger.d('AlertRemote: getUnreadCount');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.unreadAlertCount,
    );

    _checkFailure(result.failure, 'unread alert count');

    final body = result.data.data;
    if (body == null) {
      return 0;
    }

    // API may return { "count": N } or { "data": { "count": N } }.
    final data =
        body.containsKey('data') && body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;

    return data['count'] as int? ??
        data['unreadCount'] as int? ??
        data['unread_count'] as int? ??
        0;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Throws the appropriate typed exception when [failure] is non-null.
  void _checkFailure(Failure? failure, String context) {
    if (failure == null) {
      return;
    }

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
    if (body == null) {
      return [];
    }

    if (body.containsKey('data') && body['data'] is List<dynamic>) {
      return body['data'] as List<dynamic>;
    }

    if (body.containsKey('items') && body['items'] is List<dynamic>) {
      return body['items'] as List<dynamic>;
    }

    _logger.w('AlertRemote: unexpected response shape in $operationName');
    return [];
  }
}
