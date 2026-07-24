import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Debug-only logging interceptor for Dio HTTP requests.
///
/// Logs request and response information to assist with debugging.
/// Sensitive headers (Authorization, Cookie) and body fields
/// (password, token, secret) are masked before logging.
///
/// This interceptor is a no-op in release builds — all log calls are
/// guarded by [kDebugMode] so no sensitive data can leak in production.
///
/// Requirements: 23.5 — never log sensitive data.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this.logger});

  // ignore: unreachable_from_main
  final Logger logger;

  /// Headers that must be masked in logs.
  static const _sensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-auth-token',
  };

  /// Top-level JSON body keys whose values must be masked.
  static const _sensitiveBodyKeys = {
    'password',
    'token',
    'access_token',
    'refresh_token',
    'secret',
    'pin',
    'otp',
    'card_number',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Interceptor overrides
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      logger.d(
        '→ ${options.method} ${options.uri}\n'
        '  Headers: ${_maskHeaders(options.headers)}\n'
        '  Body: ${_maskBody(options.data)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      logger.d(
        '← ${response.statusCode} '
        '${response.requestOptions.method} '
        '${response.requestOptions.uri}\n'
        '  Body: ${_maskBody(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      logger.e(
        '✗ ${err.response?.statusCode ?? 'N/A'} '
        '${err.requestOptions.method} '
        '${err.requestOptions.uri}\n'
        '  Error: ${err.message}\n'
        '  Type: ${err.type}',
      );
    }
    handler.next(err);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a copy of [headers] with sensitive values replaced by '***'.
  Map<String, dynamic> _maskHeaders(Map<String, dynamic> headers) => {
    for (final entry in headers.entries)
      entry.key: _sensitiveHeaders.contains(entry.key.toLowerCase()) ? '***' : entry.value,
  };

  /// Returns [body] with sensitive fields masked.
  ///
  /// Only applies masking when the body is a `Map`; other types
  /// (String, FormData, etc.) are returned as-is because they could be
  /// binary or already-encoded payloads that don't expose key/value pairs.
  dynamic _maskBody(body) {
    if (body is Map<String, dynamic>) {
      return {
        for (final entry in body.entries)
          entry.key: _sensitiveBodyKeys.contains(entry.key.toLowerCase()) ? '***' : entry.value,
      };
    }
    return body;
  }
}
