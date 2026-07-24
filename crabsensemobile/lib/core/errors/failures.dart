import 'package:equatable/equatable.dart';

/// Abstract base class for all failures in the application.
///
/// Failures represent errors that have been handled and transformed into
/// business logic objects. They are returned from repository methods to
/// indicate what went wrong at the domain level.
///
/// All concrete failure classes should extend this class and use Equatable
/// for value equality comparisons.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.code, this.stackTrace});

  /// A user-friendly message describing what went wrong.
  final String message;

  /// Optional error code for categorization and logging.
  final String? code;

  /// Optional stack trace for debugging purposes.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Failure that occurs when there is no internet connection or
/// the device cannot reach the server.
///
/// Use this when:
/// - Device is offline (airplane mode, no WiFi/cellular data)
/// - DNS resolution fails
/// - Connection timeout occurs
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network settings.',
    String? code,
  ]) : super(code: code ?? 'NETWORK_ERROR');

  /// Creates a network failure for connection timeout.
  const NetworkFailure.timeout()
    : super('Connection timeout. Please try again.', code: 'NETWORK_TIMEOUT');

  /// Creates a network failure for DNS resolution failure.
  const NetworkFailure.dnsFailure()
    : super('Unable to reach server. Please check your connection.', code: 'DNS_FAILURE');

  @override
  String toString() => 'NetworkFailure(message: $message, code: $code)';
}

/// Failure that occurs when the server returns an error response.
///
/// Use this when:
/// - Server returns 4xx or 5xx status codes
/// - API returns error response body
/// - Server-side validation fails
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode, String? code, super.stackTrace})
    : super(code: code ?? 'SERVER_ERROR');

  /// Creates a server failure for unauthorized access (401).
  const ServerFailure.unauthorized()
    : statusCode = 401,
      super('Your session has expired. Please login again.', code: 'UNAUTHORIZED');

  /// Creates a server failure for forbidden access (403).
  const ServerFailure.forbidden()
    : statusCode = 403,
      super('You do not have permission to perform this action.', code: 'FORBIDDEN');

  /// Creates a server failure for resource not found (404).
  const ServerFailure.notFound([String? resource])
    : statusCode = 404,
      super(resource != null ? '$resource not found.' : 'Resource not found.', code: 'NOT_FOUND');

  /// Creates a server failure for internal server error (500).
  const ServerFailure.internal()
    : statusCode = 500,
      super(
        'Something went wrong on our end. Please try again later.',
        code: 'INTERNAL_SERVER_ERROR',
      );

  /// Creates a server failure for service unavailable (503).
  const ServerFailure.unavailable()
    : statusCode = 503,
      super(
        'Service temporarily unavailable. Please try again later.',
        code: 'SERVICE_UNAVAILABLE',
      );

  /// HTTP status code returned by the server.
  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];

  @override
  String toString() => 'ServerFailure(message: $message, code: $code, statusCode: $statusCode)';
}

/// Failure that occurs when local cache or storage operations fail.
///
/// Use this when:
/// - Unable to read from local database
/// - Unable to write to local storage
/// - Cache data is corrupted
/// - Storage quota exceeded
class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Failed to load cached data. Please try again.',
    String? code,
  ]) : super(code: code ?? 'CACHE_ERROR');

  /// Creates a cache failure for write operations.
  const CacheFailure.writeError()
    : super('Failed to save data locally. Storage may be full.', code: 'CACHE_WRITE_ERROR');

  /// Creates a cache failure for read operations.
  const CacheFailure.readError()
    : super('Failed to load local data. Please try refreshing.', code: 'CACHE_READ_ERROR');

  /// Creates a cache failure for corrupted data.
  const CacheFailure.corrupted()
    : super('Local data is corrupted. Please clear cache and try again.', code: 'CACHE_CORRUPTED');

  /// Creates a cache failure for storage quota exceeded.
  const CacheFailure.quotaExceeded()
    : super(
        'Device storage is full. Please free up space and try again.',
        code: 'STORAGE_QUOTA_EXCEEDED',
      );

  @override
  String toString() => 'CacheFailure(message: $message, code: $code)';
}

/// Failure that occurs when input validation fails.
///
/// Use this when:
/// - Form field validation fails
/// - Required fields are missing
/// - Input format is incorrect
/// - Business rule validation fails
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors, String? code})
    : super(code: code ?? 'VALIDATION_ERROR');

  /// Creates a validation failure for a single field.
  const ValidationFailure.field({required String error})
    : fieldErrors = const {},
      super('Validation failed', code: 'FIELD_VALIDATION_ERROR');

  /// Creates a validation failure for multiple fields.
  factory ValidationFailure.fields(Map<String, String> errors) => ValidationFailure(
    'Please correct the highlighted fields.',
    fieldErrors: errors,
    code: 'MULTIPLE_VALIDATION_ERRORS',
  );

  /// Creates a validation failure for required field.
  const ValidationFailure.required(String fieldName)
    : fieldErrors = null,
      super('$fieldName is required.', code: 'REQUIRED_FIELD');

  /// Creates a validation failure for invalid format.
  const ValidationFailure.invalidFormat(String fieldName)
    : fieldErrors = null,
      super('Invalid $fieldName format.', code: 'INVALID_FORMAT');

  /// Creates a validation failure for value out of range.
  const ValidationFailure.outOfRange({
    required String fieldName,
    required String min,
    required String max,
  }) : fieldErrors = null,
       super('$fieldName must be between $min and $max.', code: 'OUT_OF_RANGE');

  /// Map of field names to error messages for form validation.
  final Map<String, String>? fieldErrors;

  @override
  List<Object?> get props => [message, code, fieldErrors];

  @override
  String toString() =>
      'ValidationFailure(message: $message, code: $code, fieldErrors: $fieldErrors)';
}

/// Failure that occurs due to permission denial.
///
/// Use this when:
/// - Camera permission denied
/// - Storage permission denied
/// - Location permission denied
/// - Notification permission denied
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {required this.permissionType, String? code})
    : super(code: code ?? 'PERMISSION_DENIED');

  /// Creates a permission failure for camera.
  const PermissionFailure.camera()
    : permissionType = 'camera',
      super(
        'Camera permission is required to capture photos and videos. Please enable it in settings.',
        code: 'CAMERA_PERMISSION_DENIED',
      );

  /// Creates a permission failure for storage.
  const PermissionFailure.storage()
    : permissionType = 'storage',
      super(
        'Storage permission is required to save files. Please enable it in settings.',
        code: 'STORAGE_PERMISSION_DENIED',
      );

  /// Creates a permission failure for location.
  const PermissionFailure.location()
    : permissionType = 'location',
      super(
        'Location permission is required to access farm locations. Please enable it in settings.',
        code: 'LOCATION_PERMISSION_DENIED',
      );

  /// Creates a permission failure for notifications.
  const PermissionFailure.notification()
    : permissionType = 'notification',
      super(
        'Notification permission is required to receive alerts. Please enable it in settings.',
        code: 'NOTIFICATION_PERMISSION_DENIED',
      );

  /// The type of permission that was denied.
  final String permissionType;

  @override
  List<Object?> get props => [message, code, permissionType];

  @override
  String toString() =>
      'PermissionFailure(message: $message, code: $code, permissionType: $permissionType)';
}

/// Failure that occurs during authentication operations.
///
/// Use this when:
/// - Login credentials are invalid
/// - Token is expired
/// - Session is invalid
/// - Account is locked
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {String? code})
    : super(code: code ?? 'AUTHENTICATION_ERROR');

  /// Creates an authentication failure for invalid credentials.
  const AuthenticationFailure.invalidCredentials()
    : super('Invalid email or password. Please try again.', code: 'INVALID_CREDENTIALS');

  /// Creates an authentication failure for expired token.
  const AuthenticationFailure.tokenExpired()
    : super('Your session has expired. Please login again.', code: 'TOKEN_EXPIRED');

  /// Creates an authentication failure for account locked.
  const AuthenticationFailure.accountLocked()
    : super(
        'Your account has been temporarily locked due to multiple failed login attempts. Please try again in 15 minutes.',
        code: 'ACCOUNT_LOCKED',
      );

  /// Creates an authentication failure for biometric authentication.
  const AuthenticationFailure.biometricFailed()
    : super('Biometric authentication failed. Please use your password.', code: 'BIOMETRIC_FAILED');

  @override
  String toString() => 'AuthenticationFailure(message: $message, code: $code)';
}

/// Failure that occurs during data parsing or serialization.
///
/// Use this when:
/// - JSON parsing fails
/// - Data format is unexpected
/// - Required fields are missing in API response
class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Failed to process data. Please try again.', String? code])
    : super(code: code ?? 'PARSE_ERROR');

  /// Creates a parse failure for JSON parsing.
  const ParseFailure.json()
    : super(
        'Invalid data format received. Please contact support if this persists.',
        code: 'JSON_PARSE_ERROR',
      );

  /// Creates a parse failure for missing required field.
  const ParseFailure.missingField(String fieldName)
    : super('Required field "$fieldName" is missing from server response.', code: 'MISSING_FIELD');

  @override
  String toString() => 'ParseFailure(message: $message, code: $code)';
}

/// Failure that occurs with synchronization operations.
///
/// Use this when:
/// - Offline sync fails
/// - Data conflict occurs
/// - Upload queue fails
class SyncFailure extends Failure {
  const SyncFailure(super.message, {this.failedItemCount, String? code})
    : super(code: code ?? 'SYNC_ERROR');

  /// Creates a sync failure for conflict.
  const SyncFailure.conflict()
    : failedItemCount = null,
      super('Data conflict detected. Please review and resolve.', code: 'SYNC_CONFLICT');

  /// Creates a sync failure for upload.
  const SyncFailure.uploadFailed(int count)
    : failedItemCount = count,
      super('Failed to upload $count item(s). Will retry automatically.', code: 'UPLOAD_FAILED');

  /// Number of items that failed to sync.
  final int? failedItemCount;

  @override
  List<Object?> get props => [message, code, failedItemCount];

  @override
  String toString() =>
      'SyncFailure(message: $message, code: $code, failedItemCount: $failedItemCount)';
}

/// Generic failure for unexpected errors that don't fit other categories.
///
/// Use this as a last resort when the error type is unknown or doesn't
/// fit into any specific failure category.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'An unexpected error occurred. Please try again.',
    String? code,
    StackTrace? stackTrace,
  ]) : super(code: code ?? 'UNEXPECTED_ERROR', stackTrace: stackTrace);

  @override
  String toString() => 'UnexpectedFailure(message: $message, code: $code)';
}
