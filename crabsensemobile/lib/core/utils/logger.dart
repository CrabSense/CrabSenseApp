import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Structured logging utility for CrabSense Mobile Application
///
/// This logger provides different log levels and ensures sensitive data
/// is never logged in production builds.
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Log levels
  static const String _levelDebug = 'DEBUG';
  static const String _levelInfo = 'INFO';
  static const String _levelWarning = 'WARNING';
  static const String _levelError = 'ERROR';
  static const String _levelCritical = 'CRITICAL';

  // ===========================================================================
  // Debug Logging
  // ===========================================================================

  /// Logs debug messages (only in debug mode)
  ///
  /// Use for detailed technical information useful during development
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      _log(level: _levelDebug, message: message, tag: tag, data: data);
    }
  }

  // ===========================================================================
  // Info Logging
  // ===========================================================================

  /// Logs informational messages
  ///
  /// Use for general application flow information
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(level: _levelInfo, message: message, tag: tag, data: data);
  }

  // ===========================================================================
  // Warning Logging
  // ===========================================================================

  /// Logs warning messages
  ///
  /// Use for potentially harmful situations that don't prevent normal operation
  static void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(level: _levelWarning, message: message, tag: tag, data: data);
  }

  // ===========================================================================
  // Error Logging
  // ===========================================================================

  /// Logs error messages
  ///
  /// Use for error events that might still allow the application to continue
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      level: _levelError,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  // ===========================================================================
  // Critical Logging
  // ===========================================================================

  /// Logs critical messages
  ///
  /// Use for severe error events that will likely lead to application abort
  static void critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      level: _levelCritical,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  // ===========================================================================
  // Network Logging
  // ===========================================================================

  /// Logs HTTP request details
  static void logRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    body,
  }) {
    if (kDebugMode) {
      debug(
        'HTTP Request: $method $url',
        tag: 'Network',
        data: {
          'method': method,
          'url': url,
          'headers': _sanitizeHeaders(headers),
          'body': _sanitizeBody(body),
        },
      );
    }
  }

  /// Logs HTTP response details
  static void logResponse({
    required String method,
    required String url,
    required int statusCode,
    body,
    Duration? duration,
  }) {
    if (kDebugMode) {
      debug(
        'HTTP Response: $method $url - $statusCode',
        tag: 'Network',
        data: {
          'method': method,
          'url': url,
          'statusCode': statusCode,
          'body': _sanitizeBody(body),
          if (duration != null) 'duration': '${duration.inMilliseconds}ms',
        },
      );
    }
  }

  /// Logs network errors
  static void logNetworkError({
    required String method,
    required String url,
    required Object error,
    StackTrace? stackTrace,
  }) {
    AppLogger.error(
      'Network Error: $method $url',
      tag: 'Network',
      error: error,
      stackTrace: stackTrace,
      data: {'method': method, 'url': url},
    );
  }

  // ===========================================================================
  // Database Logging
  // ===========================================================================

  /// Logs database operations
  static void logDatabaseOperation({
    required String operation,
    required String table,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      debug('Database: $operation on $table', tag: 'Database', data: data);
    }
  }

  /// Logs database errors
  static void logDatabaseError({
    required String operation,
    required String table,
    required Object error,
    StackTrace? stackTrace,
  }) {
    AppLogger.error(
      'Database Error: $operation on $table',
      tag: 'Database',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ===========================================================================
  // Authentication Logging
  // ===========================================================================

  /// Logs authentication events
  static void logAuthEvent({required String event, String? userId, Map<String, dynamic>? data}) {
    info('Auth: $event', tag: 'Authentication', data: {'userId': ?userId, ...?data});
  }

  /// Logs authentication failures
  static void logAuthFailure({required String reason, Map<String, dynamic>? data}) {
    warning('Auth Failure: $reason', tag: 'Authentication', data: data);
  }

  // ===========================================================================
  // Sync Logging
  // ===========================================================================

  /// Logs sync operations
  static void logSyncEvent({required String event, int? itemCount, Map<String, dynamic>? data}) {
    info('Sync: $event', tag: 'Sync', data: {'itemCount': ?itemCount, ...?data});
  }

  /// Logs sync errors
  static void logSyncError({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    AppLogger.error(
      'Sync Error: $operation',
      tag: 'Sync',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  // ===========================================================================
  // AI/Video Logging
  // ===========================================================================

  /// Logs AI analysis events
  static void logAIEvent({required String event, String? videoId, Map<String, dynamic>? data}) {
    info('AI: $event', tag: 'AI', data: {'videoId': ?videoId, ...?data});
  }

  /// Logs video operations
  static void logVideoEvent({
    required String event,
    String? videoId,
    int? fileSizeBytes,
    Map<String, dynamic>? data,
  }) {
    info(
      'Video: $event',
      tag: 'Video',
      data: {'videoId': ?videoId, 'fileSizeBytes': ?fileSizeBytes, ...?data},
    );
  }

  // ===========================================================================
  // Performance Logging
  // ===========================================================================

  /// Logs performance metrics
  static void logPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      debug(
        'Performance: $operation took ${duration.inMilliseconds}ms',
        tag: 'Performance',
        data: {'operation': operation, 'durationMs': duration.inMilliseconds, ...?data},
      );
    }
  }

  // ===========================================================================
  // Private Helper Methods
  // ===========================================================================

  /// Core logging function
  static void _log({
    required String level,
    required String message,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final logMessage = '[$timestamp] [$level] $tagPrefix$message';

    // Use developer.log for better integration with Flutter DevTools
    developer.log(
      message,
      time: DateTime.now(),
      level: _getLevelValue(level),
      name: tag ?? 'App',
      error: error,
      stackTrace: stackTrace,
    );

    // Also print to console for visibility during development
    if (kDebugMode) {
      debugPrint(logMessage);

      if (data != null && data.isNotEmpty) {
        debugPrint('  Data: ${_formatData(data)}');
      }

      if (error != null) {
        debugPrint('  Error: $error');
      }

      if (stackTrace != null) {
        debugPrint('  StackTrace: $stackTrace');
      }
    }
  }

  /// Gets numeric log level for developer.log
  static int _getLevelValue(String level) {
    switch (level) {
      case _levelDebug:
        return 500; // Fine level
      case _levelInfo:
        return 800; // Info level
      case _levelWarning:
        return 900; // Warning level
      case _levelError:
        return 1000; // Severe level
      case _levelCritical:
        return 1200; // Shout level
      default:
        return 800;
    }
  }

  /// Formats data map for logging
  static String _formatData(Map<String, dynamic> data) =>
      data.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ');

  /// Sanitizes HTTP headers by removing sensitive data
  static Map<String, dynamic>? _sanitizeHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return null;

    final sanitized = Map<String, dynamic>.from(headers);
    final sensitiveKeys = ['authorization', 'cookie', 'x-api-key', 'api-key'];

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key.toLowerCase())) {
        sanitized[key] = '***REDACTED***';
      }
    }

    return sanitized;
  }

  /// Sanitizes request/response body by removing sensitive data
  static dynamic _sanitizeBody(body) {
    if (body == null) return null;

    // Don't log large bodies in production
    if (kReleaseMode) {
      return '***HIDDEN IN PRODUCTION***';
    }

    // If body is a Map, sanitize sensitive fields
    if (body is Map) {
      final sanitized = Map<String, dynamic>.from(body as Map<String, dynamic>);
      final sensitiveFields = [
        'password',
        'token',
        'refresh_token',
        'access_token',
        'secret',
        'api_key',
        'credit_card',
      ];

      for (final field in sensitiveFields) {
        if (sanitized.containsKey(field)) {
          sanitized[field] = '***REDACTED***';
        }
      }

      return sanitized;
    }

    return body;
  }

  // ===========================================================================
  // Development Utilities
  // ===========================================================================

  /// Measures and logs execution time of a function
  static Future<T> measureAsync<T>({
    required String operation,
    required Future<T> Function() function,
    String? tag,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      logPerformance(operation: operation, duration: stopwatch.elapsed);
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      error(
        'Error during $operation',
        tag: tag ?? 'Performance',
        error: e,
        stackTrace: stackTrace,
        data: {'duration': '${stopwatch.elapsedMilliseconds}ms'},
      );
      rethrow;
    }
  }

  /// Measures and logs execution time of a synchronous function
  static T measure<T>({required String operation, required T Function() function, String? tag}) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = function();
      stopwatch.stop();
      logPerformance(operation: operation, duration: stopwatch.elapsed);
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      error(
        'Error during $operation',
        tag: tag ?? 'Performance',
        error: e,
        stackTrace: stackTrace,
        data: {'duration': '${stopwatch.elapsedMilliseconds}ms'},
      );
      rethrow;
    }
  }
}
