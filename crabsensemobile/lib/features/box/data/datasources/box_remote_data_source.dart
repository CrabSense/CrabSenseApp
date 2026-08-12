// ignore_for_file: lines_longer_than_80_chars

import 'package:dio/dio.dart' show DioException;
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/box_model.dart';
import '../models/crab_model.dart';

/// Contract for fetching and mutating box / crab data via the remote API.
///
/// All methods throw typed exceptions on failure:
/// - [ServerException]: 4xx / 5xx API responses.
/// - [NetworkException]: No network connectivity or request timeout.
/// - [ParseException]: Malformed or unexpected JSON response body.
///
/// Requirements: 4.1-4.10, 16.1-16.10
abstract class BoxRemoteDataSource {
  /// Fetches the full details of a single box by its unique ID.
  ///
  /// Requirements: 4.1, 4.2, 4.7
  Future<BoxModel> getBoxDetails(String boxId);

  /// Looks up a box by its QR code string.
  ///
  /// Requirements: 4.1
  Future<BoxModel> getBoxByQrCode(String qrCode);

  /// Retrieves all boxes belonging to a farm.
  ///
  /// Requirements: 4.1, 4.9
  Future<List<BoxModel>> getBoxesByFarm(String farmId);

  /// Adds a new crab record to a box via the API.
  ///
  /// Requirements: 16.1, 16.3, 16.6
  Future<CrabModel> addCrab(String boxId, CrabModel crab);

  /// Transfers a crab from one box to another atomically.
  ///
  /// Requirements: 16.4, 16.5
  Future<void> transferCrab(String crabId, String sourceBoxId, String destinationBoxId);

  /// Updates an existing box record.
  ///
  /// Requirements: 4.1
  Future<BoxModel> updateBox(BoxModel box);

  /// Retrieves all crab records for a given box.
  ///
  /// Requirements: 16.1
  Future<List<CrabModel>> getCrabsByBox(String boxId);

  /// Retrieves a single crab by id.
  Future<CrabModel> getCrabById(String crabId);

  /// Deletes a crab record by ID.
  ///
  /// Requirements: 16.10
  Future<void> deleteCrab(String crabId);
}

/// Dio-backed implementation of [BoxRemoteDataSource].
///
/// Uses [ApiClient.safeGet] / [ApiClient.safePost] etc. which map
/// [DioException] to [Failure] internally. This class then converts
/// any non-null failure into the appropriate typed exception so the
/// repository layer can handle it uniformly.
class BoxRemoteDataSourceImpl implements BoxRemoteDataSource {
  BoxRemoteDataSourceImpl({required this._apiClient, required this._logger});

  final ApiClient _apiClient;
  final Logger _logger;

  // ──────────────────────────────────────────────────────────────────────────
  // BoxRemoteDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<BoxModel> getBoxDetails(String boxId) async {
    _logger.d('BoxRemoteDataSource: getBoxDetails($boxId)');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(ApiConstants.boxDetails(boxId));

    _checkFailure(result.failure, 'box details');

    final data = _extractData(result.data.data, 'getBoxDetails');
    return BoxModel.fromJson(data);
  }

  @override
  Future<BoxModel> getBoxByQrCode(String qrCode) async {
    _logger.d('BoxRemoteDataSource: getBoxByQrCode');

    final sanitized = qrCode.trim();
    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.boxesQr(sanitized),
    );

    _checkFailure(result.failure, 'box by QR code');

    final data = _extractData(result.data.data, 'getBoxByQrCode');
    final boxId = data['boxId']?.toString();
    if (boxId == null || boxId.isEmpty) {
      throw const ParseException(message: 'QR response missing boxId', field: 'boxId');
    }
    return getBoxDetails(boxId);
  }

  @override
  Future<List<BoxModel>> getBoxesByFarm(String farmId) async {
    _logger.d('BoxRemoteDataSource: getBoxesByFarm($farmId)');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.boxes,
      queryParameters: {'farmingAreaId': farmId},
    );

    _checkFailure(result.failure, 'boxes by farm');

    final raw = result.data.data;
    final items = _extractList(raw, 'getBoxesByFarm');
    return items.map((e) => BoxModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CrabModel> addCrab(String boxId, CrabModel crab) async {
    _logger.d('BoxRemoteDataSource: addCrab to box $boxId');

    final result = await _apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.addCrabToBox(boxId),
      data: {
        'weight': crab.weight,
        'weightGram': crab.weight,
        'moltingStatus': crab.moltingStatus.name,
        'moltingStage': crab.moltingStatus.name,
        'species': crab.species.name,
        'tag': crab.addedBy.isEmpty ? null : crab.addedBy,
      },
    );

    _checkFailure(result.failure, 'add crab');

    final data = _extractData(result.data.data, 'addCrab');
    return CrabModel.fromJson(data);
  }

  @override
  Future<void> transferCrab(String crabId, String sourceBoxId, String destinationBoxId) async {
    _logger.d(
      'BoxRemoteDataSource: transferCrab '
      '$crabId from $sourceBoxId to $destinationBoxId',
    );

    final result = await _apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.transferCrab,
      data: {
        'crabId': crabId,
        'sourceBoxId': sourceBoxId,
        'destinationBoxId': destinationBoxId,
        'boxId': destinationBoxId,
      },
    );

    _checkFailure(result.failure, 'transfer crab');
  }

  @override
  Future<BoxModel> updateBox(BoxModel box) async {
    _logger.d('BoxRemoteDataSource: updateBox(${box.id})');

    final result = await _apiClient.safePut<Map<String, dynamic>>(
      ApiConstants.boxDetails(box.id),
      data: {
        'code': box.qrCode.isNotEmpty ? box.qrCode : box.id,
        'status': box.status.name,
        'isOccupied': box.currentCrabCount > 0,
      },
    );

    _checkFailure(result.failure, 'update box');

    final data = _extractData(result.data.data, 'updateBox');
    // Update returns lean BoxDto — reload enriched detail when possible.
    try {
      return await getBoxDetails(box.id);
    } on Exception {
      return BoxModel.fromJson(data);
    }
  }

  @override
  Future<List<CrabModel>> getCrabsByBox(String boxId) async {
    _logger.d('BoxRemoteDataSource: getCrabsByBox($boxId)');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(ApiConstants.boxCrabs(boxId));

    _checkFailure(result.failure, 'crabs by box');

    final raw = result.data.data;
    final items = _extractList(raw, 'getCrabsByBox');
    return items.map((e) => CrabModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CrabModel> getCrabById(String crabId) async {
    _logger.d('BoxRemoteDataSource: getCrabById($crabId)');
    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.crabDetails(crabId),
    );
    _checkFailure(result.failure, 'crab by id');
    final data = _extractData(result.data.data, 'getCrabById');
    return CrabModel.fromJson(data);
  }

  @override
  Future<void> deleteCrab(String crabId) async {
    _logger.d('BoxRemoteDataSource: deleteCrab($crabId)');

    final result = await _apiClient.safeDelete<Map<String, dynamic>>(
      ApiConstants.deleteCrab(crabId),
    );

    _checkFailure(result.failure, 'delete crab');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Throws the appropriate typed exception if [failure] is non-null.
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

    throw ServerException(message: 'Failed to $context: ${failure.message}', code: failure.code);
  }

  /// Extracts and validates the `data` payload from an API response map.
  ///
  /// The CrabSense API wraps results in `{ "data": {...} }`.
  /// Throws [ParseException] when the payload is missing or wrong type.
  Map<String, dynamic> _extractData(Map<String, dynamic>? responseBody, String operationName) {
    if (responseBody == null) {
      throw ParseException(message: 'Null response body in $operationName', field: 'data');
    }

    // Some endpoints return the object directly; others nest under "data".
    if (responseBody.containsKey('data') && responseBody['data'] is Map<String, dynamic>) {
      return responseBody['data'] as Map<String, dynamic>;
    }

    // Response body is the object itself.
    return responseBody;
  }

  /// Extracts and validates a list payload from an API response map.
  List<dynamic> _extractList(Map<String, dynamic>? responseBody, String operationName) {
    if (responseBody == null) {
      return [];
    }

    // Nested list under "data".
    if (responseBody.containsKey('data') && responseBody['data'] is List<dynamic>) {
      return responseBody['data'] as List<dynamic>;
    }

    // List at root level.
    if (responseBody.containsKey('items') && responseBody['items'] is List<dynamic>) {
      return responseBody['items'] as List<dynamic>;
    }

    // Empty fallback — avoids crashing on unexpected shapes.
    _logger.w('BoxRemoteDataSource: unexpected list shape in $operationName');
    return [];
  }
}
