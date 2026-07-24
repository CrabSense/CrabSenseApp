import 'dart:io';

import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Utility class for mapping exceptions to failures.
///
/// This class provides static methods to convert low-level exceptions
/// thrown from data sources into user-friendly failure objects that
/// can be presented in the UI layer.
///
/// Usage:
/// ```dart
/// try {
///   final data = await remoteDataSource.getData();
///   return Right(data);
/// } catch (e) {
///   return Left(ErrorMapper.mapExceptionToFailure(e));
/// }
/// ```
class ErrorMapper {
  ErrorMapper._(); // Private constructor to prevent instantiation

  /// Maps any exception to an appropriate [Failure] object.
  ///
  /// This is the main method that should be used in repositories to
  /// convert exceptions into failures.
  static Failure mapExceptionToFailure(exception, [StackTrace? stackTrace]) {
    // Handle custom application exceptions
    if (exception is ServerException) {
      return _mapServerException(exception);
    }

    if (exception is NetworkException) {
      return NetworkFailure(exception.message, exception.code);
    }

    if (exception is CacheException) {
      return CacheFailure(exception.message, exception.code);
    }

    if (exception is ParseException) {
      return ParseFailure(exception.message);
    }

    if (exception is ValidationException) {
      return ValidationFailure(exception.message, fieldErrors: exception.fieldErrors);
    }

    if (exception is AuthenticationException) {
      return AuthenticationFailure(exception.message, code: exception.code);
    }

    if (exception is PermissionException) {
      return PermissionFailure(exception.message, permissionType: exception.permissionType);
    }

    if (exception is SyncException) {
      return SyncFailure(
        exception.message,
        failedItemCount: exception.failedItemCount,
        code: exception.code,
      );
    }

    // Handle Dio exceptions (HTTP client)
    if (exception is DioException) {
      return _mapDioException(exception);
    }

    // Handle platform exceptions
    if (exception is SocketException) {
      return const NetworkFailure(
        'Unable to connect to server. Please check your internet connection.',
        'SOCKET_ERROR',
      );
    }

    if (exception is HttpException) {
      return ServerFailure(exception.message, code: 'HTTP_ERROR');
    }

    if (exception is FormatException) {
      return ParseFailure(exception.message, 'FORMAT_ERROR');
    }

    // Handle any other exception as unexpected failure
    return UnexpectedFailure(exception.toString(), 'UNKNOWN_ERROR', stackTrace);
  }

  /// Maps [ServerException] to appropriate [ServerFailure].
  static ServerFailure _mapServerException(ServerException exception) {
    final statusCode = exception.statusCode;

    // Map common HTTP status codes to specific failures
    switch (statusCode) {
      case 401:
        return const ServerFailure.unauthorized();
      case 403:
        return const ServerFailure.forbidden();
      case 404:
        return const ServerFailure.notFound();
      case 500:
      case 502:
        return const ServerFailure.internal();
      case 503:
        return const ServerFailure.unavailable();
      default:
        return ServerFailure(exception.message, statusCode: statusCode, code: exception.code);
    }
  }

  /// Maps [DioException] to appropriate [Failure].
  static Failure _mapDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure.timeout();

      case DioExceptionType.badResponse:
        return _mapBadResponse(exception);

      case DioExceptionType.cancel:
        return const UnexpectedFailure('Request was cancelled');

      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'Connection error. Please check your internet connection.',
          'CONNECTION_ERROR',
        );

      case DioExceptionType.unknown:
        // Check if it's a socket exception (no internet)
        if (exception.error is SocketException) {
          return const NetworkFailure();
        }
        return UnexpectedFailure(
          exception.message ?? 'An unknown error occurred',
          'UNKNOWN_DIO_ERROR',
        );

      default:
        return UnexpectedFailure(exception.message ?? 'An error occurred', 'DIO_ERROR');
    }
  }

  /// Maps bad HTTP responses to appropriate failures.
  static Failure _mapBadResponse(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final responseData = exception.response?.data;

    // Try to extract error message from response
    var message = 'An error occurred';
    String? code;

    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ?? responseData['error'] as String? ?? message;
      code = responseData['code'] as String?;
    }

    // Map status codes to specific failures
    switch (statusCode) {
      case 400:
        // Bad request - could be validation error
        if (responseData is Map<String, dynamic> && responseData.containsKey('errors')) {
          final errors = responseData['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            return ValidationFailure.fields(
              errors.map((key, value) => MapEntry(key, value.toString())),
            );
          }
        }
        return ServerFailure(message, statusCode: statusCode, code: code);

      case 401:
        return const ServerFailure.unauthorized();

      case 403:
        return const ServerFailure.forbidden();

      case 404:
        return const ServerFailure.notFound();

      case 422:
        // Unprocessable entity - validation error
        return ValidationFailure(message, code: code);

      case 429:
        return ServerFailure(
          'Too many requests. Please try again later.',
          statusCode: statusCode,
          code: 'RATE_LIMIT_EXCEEDED',
        );

      case 500:
      case 502:
      case 503:
        return const ServerFailure.internal();

      default:
        return ServerFailure(message, statusCode: statusCode, code: code);
    }
  }

  /// Creates a [NetworkFailure] for connectivity issues.
  static NetworkFailure createNetworkFailure() => const NetworkFailure();

  /// Creates a [ServerFailure] from status code and message.
  static ServerFailure createServerFailure({
    required int statusCode,
    required String message,
    String? code,
  }) => ServerFailure(message, statusCode: statusCode, code: code);

  /// Creates a [CacheFailure] with a custom message.
  static CacheFailure createCacheFailure([String? message]) =>
      CacheFailure(message ?? 'Failed to load cached data. Please try again.');

  /// Creates a [ValidationFailure] for form validation errors.
  static ValidationFailure createValidationFailure(Map<String, String> fieldErrors) =>
      ValidationFailure.fields(fieldErrors);

  /// Creates an [AuthenticationFailure] with a custom message.
  static AuthenticationFailure createAuthFailure([String? message]) =>
      AuthenticationFailure(message ?? 'Authentication failed. Please try again.');

  /// Creates a [PermissionFailure] for a specific permission type.
  static PermissionFailure createPermissionFailure({
    required String permissionType,
    String? message,
  }) => PermissionFailure(
    message ?? 'Permission denied for $permissionType',
    permissionType: permissionType,
  );

  /// Extracts user-friendly message from a [Failure].
  ///
  /// This method can be used in the UI layer to display error messages
  /// to the user.
  static String getFailureMessage(Failure failure) => failure.message;

  /// Checks if a failure is recoverable (can be retried).
  static bool isRecoverable(Failure failure) =>
      failure is NetworkFailure || failure is ServerFailure || failure is SyncFailure;

  /// Checks if a failure requires user action (e.g., login).
  static bool requiresUserAction(Failure failure) =>
      failure is AuthenticationFailure ||
      failure is PermissionFailure ||
      failure is ValidationFailure;
}
