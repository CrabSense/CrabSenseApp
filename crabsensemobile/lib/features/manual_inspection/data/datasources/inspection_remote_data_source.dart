// ignore_for_file: lines_longer_than_80_chars

import 'package:dio/dio.dart' show DioException;
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/inspection_model.dart';

/// Contract for remote inspection operations via the REST API.
///
/// All methods throw typed exceptions on failure:
/// - [ServerException]  — 4xx / 5xx API responses
/// - [NetworkException] — no connectivity or request timeout
/// - [ParseException]   — malformed or unexpected JSON response body
///
/// Requirements: 7.1-7.10
abstract class InspectionRemoteDataSource {
  /// Submits a manual inspection record to the server.
  ///
  /// Returns the persisted [InspectionModel] (with server-assigned fields).
  ///
  /// Requirements: 7.4, 7.6
  Future<InspectionModel> submitInspection(InspectionModel inspection);

  /// Sends AI-detection feedback to the AI service for model retraining.
  ///
  /// Requirements: 7.5
  Future<void> submitFeedback(InspectionFeedbackModel feedback);

  /// Retrieves all inspection records for the given box from the server,
  /// ordered from newest to oldest.
  ///
  /// Requirements: 7.10
  Future<List<InspectionModel>> getInspectionHistory(String boxId);

  /// Fetches a single inspection record by its unique ID.
  ///
  /// Requirements: 7.10
  Future<InspectionModel> getInspectionById(String inspectionId);
}

/// Dio-backed implementation of [InspectionRemoteDataSource].
///
/// Uses the shared [ApiClient] helpers (safeGet / safePost) which map
/// [DioException] to [Failure] internally.  This class re-throws those
/// failures as typed exceptions so the repository layer can handle them
/// uniformly.
class InspectionRemoteDataSourceImpl implements InspectionRemoteDataSource {
  InspectionRemoteDataSourceImpl({required this._apiClient, required this._logger});

  final ApiClient _apiClient;
  final Logger _logger;

  // ──────────────────────────────────────────────────────────────────────────
  // InspectionRemoteDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<InspectionModel> submitInspection(InspectionModel inspection) async {
    _logger.d('InspectionRemoteDataSource: submitInspection(${inspection.id})');

    final result = await _apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.submitInspection,
      data: inspection.toJson(),
    );

    _checkFailure(result.failure, 'submit inspection');

    final data = _extractObject(result.data.data, 'submitInspection');
    return InspectionModel.fromJson(data);
  }

  @override
  Future<void> submitFeedback(InspectionFeedbackModel feedback) async {
    _logger.d(
      'InspectionRemoteDataSource: submitFeedback '
      '(inspection=${feedback.inspectionId}, correct=${feedback.isCorrect})',
    );

    final result = await _apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.submitFeedback,
      data: feedback.toJson(),
    );

    _checkFailure(result.failure, 'submit feedback');
  }

  @override
  Future<List<InspectionModel>> getInspectionHistory(String boxId) async {
    _logger.d('InspectionRemoteDataSource: getInspectionHistory($boxId)');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.inspectionsForBox(boxId),
    );

    _checkFailure(result.failure, 'inspection history');

    final items = _extractList(result.data.data, 'getInspectionHistory');
    return items
        .map((e) => InspectionModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<InspectionModel> getInspectionById(String inspectionId) async {
    _logger.d('InspectionRemoteDataSource: getInspectionById($inspectionId)');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.inspectionDetails(inspectionId),
    );

    _checkFailure(result.failure, 'inspection details');

    final data = _extractObject(result.data.data, 'getInspectionById');
    return InspectionModel.fromJson(data);
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

  /// Extracts the object payload from an API response envelope.
  ///
  /// The CrabSense API wraps single-object results in `{ "data": {...} }`.
  /// Throws [ParseException] when the payload is missing or the wrong type.
  Map<String, dynamic> _extractObject(Map<String, dynamic>? body, String operation) {
    if (body == null) {
      throw ParseException(message: 'Null response body in $operation', field: 'data');
    }

    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }

    // Response body is the object itself.
    return body;
  }

  /// Extracts a list payload from an API response envelope.
  List<dynamic> _extractList(Map<String, dynamic>? body, String operation) {
    if (body == null) return const [];

    if (body.containsKey('data') && body['data'] is List) {
      return body['data'] as List;
    }

    if (body.containsKey('items') && body['items'] is List) {
      return body['items'] as List;
    }

    _logger.w('InspectionRemoteDataSource: unexpected list shape in $operation');
    return const [];
  }
}
