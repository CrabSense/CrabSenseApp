/// Custom exception classes for the application.
///
/// Exceptions represent technical errors that occur at the data layer
/// (API calls, database operations, etc.). They are typically caught and
/// transformed into [Failure] objects by repository implementations.
///
/// Exceptions should be thrown from data sources and caught at the
/// repository layer for proper error handling.
library;

import 'failures.dart' show Failure;

/// Base class for all server-related exceptions.
///
/// Thrown when HTTP requests fail or return error responses.
class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode, this.code, this.details});

  /// Error message describing what went wrong.
  final String message;

  /// HTTP status code returned by the server.
  final int? statusCode;

  /// Error code from the API response.
  final String? code;

  /// Additional error details from the server.
  final Map<String, dynamic>? details;

  @override
  String toString() => 'ServerException(message: $message, statusCode: $statusCode, code: $code)';
}

/// Exception thrown when network connection is unavailable.
///
/// Thrown when:
/// - Device is offline (no WiFi/cellular data)
/// - Connection timeout occurs
/// - DNS resolution fails
class NetworkException implements Exception {
  const NetworkException({this.message = 'No internet connection', this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'NetworkException(message: $message, code: $code)';
}

/// Exception thrown when cache operations fail.
///
/// Thrown when:
/// - Unable to read from local database
/// - Unable to write to local storage
/// - Cache data is corrupted
/// - Storage quota is exceeded
class CacheException implements Exception {
  const CacheException({required this.message, this.code, this.innerException});
  final String message;
  final String? code;
  final Exception? innerException;

  @override
  String toString() =>
      'CacheException(message: $message, code: $code, innerException: $innerException)';
}

/// Exception thrown when data parsing or serialization fails.
///
/// Thrown when:
/// - JSON parsing fails
/// - Data format is unexpected
/// - Required fields are missing in API response
class ParseException implements Exception {
  const ParseException({required this.message, this.field, this.sourceData});
  final String message;
  final String? field;
  final dynamic sourceData;

  @override
  String toString() => 'ParseException(message: $message, field: $field, sourceData: $sourceData)';
}

/// Exception thrown when input validation fails.
///
/// Thrown when:
/// - Required fields are missing
/// - Input format is incorrect
/// - Business rule validation fails
class ValidationException implements Exception {
  const ValidationException({required this.message, this.fieldErrors});
  final String message;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => 'ValidationException(message: $message, fieldErrors: $fieldErrors)';
}

/// Exception thrown when authentication fails.
///
/// Thrown when:
/// - Login credentials are invalid
/// - Token is expired or invalid
/// - Session is invalid
/// - Account is locked
class AuthenticationException implements Exception {
  const AuthenticationException({required this.message, this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AuthenticationException(message: $message, code: $code)';
}

/// Exception thrown when permission is denied.
///
/// Thrown when:
/// - Camera permission denied
/// - Storage permission denied
/// - Location permission denied
/// - Notification permission denied
class PermissionException implements Exception {
  const PermissionException({required this.message, required this.permissionType});
  final String message;
  final String permissionType;

  @override
  String toString() => 'PermissionException(message: $message, permissionType: $permissionType)';
}

/// Exception thrown during synchronization operations.
///
/// Thrown when:
/// - Offline sync fails
/// - Data conflict occurs
/// - Upload queue fails
class SyncException implements Exception {
  const SyncException({required this.message, this.code, this.failedItemCount});
  final String message;
  final String? code;
  final int? failedItemCount;

  @override
  String toString() =>
      'SyncException(message: $message, code: $code, failedItemCount: $failedItemCount)';
}

/// Exception thrown during file operations.
///
/// Thrown when:
/// - File read/write fails
/// - File not found
/// - Insufficient storage space
/// - Invalid file format
class FileException implements Exception {
  const FileException({required this.message, this.filePath, this.code});
  final String message;
  final String? filePath;
  final String? code;

  @override
  String toString() => 'FileException(message: $message, filePath: $filePath, code: $code)';
}

/// Exception thrown during media operations.
///
/// Thrown when:
/// - Video compression fails
/// - Image processing fails
/// - Camera initialization fails
/// - Video recording fails
class MediaException implements Exception {
  const MediaException({required this.message, this.mediaType, this.code});
  final String message;
  final String? mediaType; // 'video', 'image', 'camera'
  final String? code;

  @override
  String toString() => 'MediaException(message: $message, mediaType: $mediaType, code: $code)';
}

/// Exception thrown during QR code operations.
///
/// Thrown when:
/// - QR code scanning fails
/// - Invalid QR code format
/// - QR code data is corrupted
class QRException implements Exception {
  const QRException({required this.message, this.code, this.rawData});
  final String message;
  final String? code;
  final String? rawData;

  @override
  String toString() => 'QRException(message: $message, code: $code, rawData: $rawData)';
}
