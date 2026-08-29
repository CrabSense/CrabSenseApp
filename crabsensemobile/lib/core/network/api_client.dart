import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../features/authentication/data/datasources/auth_local_data_source.dart';
import '../constants/api_constants.dart';
import '../errors/error_mapper.dart';
import '../errors/failures.dart';
import 'certificate_pinning.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/token_refresh_interceptor.dart';

/// Dio-based HTTP client for the CrabSense API.
///
/// Responsibilities:
///   - Base URL & 30-second connect / receive / send timeouts.
///   - JWT Bearer header attachment via [AuthInterceptor].
///   - Transparent token refresh on 401 via [TokenRefreshInterceptor].
///   - Debug-only request/response logging via [LoggingInterceptor].
///   - Certificate pinning via [CertificatePinning] (req 23.2, 23.3).
///   - Mapping [DioException] → typed [Failure] subclasses.
///
/// Usage in a repository:
/// ```dart
/// final result = await apiClient.safeGet<Map<String, dynamic>>(
///   ApiConstants.boxDetails('123'),
/// );
/// result.failure != null
///   ? Left(result.failure!)
///   : Right(result.data.data);
/// ```
///
/// Requirements: 1.1–1.10, 23.1–23.3
class ApiClient {
  ApiClient({required Logger logger, required AuthLocalDataSource authLocalDataSource})
    : _logger = logger {
    _dio = _buildDio(logger, authLocalDataSource);
  }

  final Logger _logger;
  late final Dio _dio;

  // ─────────────────────────────────────────────────────────────────────────
  // Dio factory
  // ─────────────────────────────────────────────────────────────────────────

  Dio _buildDio(Logger logger, AuthLocalDataSource authLocalDataSource) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    // ── Interceptors ─────────────────────────────────────────────────────

    // 1. Auth — attaches `Authorization: Bearer <token>` to every request.
    dio.interceptors.add(AuthInterceptor(localDataSource: authLocalDataSource, logger: logger));

    // 2. Token refresh — handles 401 by refreshing & retrying the request.
    //    Must come AFTER AuthInterceptor so the refresh call itself can
    //    skip header attachment via the `skipAuthInterceptor` extra flag.
    dio.interceptors.add(
      TokenRefreshInterceptor(localDataSource: authLocalDataSource, dio: dio, logger: logger),
    );

    // 3. Logging — debug builds only; masks sensitive headers/body fields.
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor(logger: logger));
    }

    // ── Certificate pinning ───────────────────────────────────────────────
    // Requirements 23.2 (TLS 1.2+) & 23.3 (cert pinning).
    // Active in profile + release builds; bypassed with a warning in debug.
    // Not available on web — browser handles TLS natively.
    if (!kIsWeb) {
      final adapter = CertificatePinning.buildAdapter(logger: logger);
      if (adapter != null) {
        dio.httpClientAdapter = adapter;
      }
    }

    return dio;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public HTTP methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Performs a GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.get<T>(path, queryParameters: queryParameters, options: options);

  /// Performs a POST request.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  /// Performs a PUT request.
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);

  /// Performs a PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);

  /// Performs a DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);

  // ─────────────────────────────────────────────────────────────────────────
  // Safe wrappers — map DioException → Failure
  // ─────────────────────────────────────────────────────────────────────────

  /// Wraps [get] and maps any [DioException] to a [Failure].
  ///
  /// The returned record has either a non-null [Failure] or a valid
  /// [Response]; callers should check `failure != null` first.
  Future<({Response<T> data, Failure? failure})> safeGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await get<T>(path, queryParameters: queryParameters, options: options);
      return (data: response, failure: null);
    } on DioException catch (e, st) {
      return (
        data: Response<T>(requestOptions: e.requestOptions),
        failure: ErrorMapper.mapExceptionToFailure(e, st),
      );
    }
  }

  /// Wraps [post] and maps any [DioException] to a [Failure].
  Future<({Response<T> data, Failure? failure})> safePost<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return (data: response, failure: null);
    } on DioException catch (e, st) {
      return (
        data: Response<T>(requestOptions: e.requestOptions),
        failure: ErrorMapper.mapExceptionToFailure(e, st),
      );
    }
  }

  /// Wraps [put] and maps any [DioException] to a [Failure].
  Future<({Response<T> data, Failure? failure})> safePut<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return (data: response, failure: null);
    } on DioException catch (e, st) {
      return (
        data: Response<T>(requestOptions: e.requestOptions),
        failure: ErrorMapper.mapExceptionToFailure(e, st),
      );
    }
  }

  /// Wraps [patch] and maps any [DioException] to a [Failure].
  Future<({Response<T> data, Failure? failure})> safePatch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return (data: response, failure: null);
    } on DioException catch (e, st) {
      return (
        data: Response<T>(requestOptions: e.requestOptions),
        failure: ErrorMapper.mapExceptionToFailure(e, st),
      );
    }
  }

  /// Wraps [delete] and maps any [DioException] to a [Failure].
  Future<({Response<T> data, Failure? failure})> safeDelete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return (data: response, failure: null);
    } on DioException catch (e, st) {
      return (
        data: Response<T>(requestOptions: e.requestOptions),
        failure: ErrorMapper.mapExceptionToFailure(e, st),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Diagnostics
  // ─────────────────────────────────────────────────────────────────────────

  /// Provides direct access to the underlying [Dio] instance for
  /// advanced use-cases (e.g. file upload with [FormData]).
  Dio get dio => _dio;

  /// Logger for use by consumers that need to emit structured log entries
  /// alongside API calls (e.g. repository classes).
  Logger get logger => _logger;
}
