import 'package:crabsensemobile/core/errors/errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMapper', () {
    group('mapExceptionToFailure', () {
      test('should map ServerException to ServerFailure', () {
        // Arrange
        const exception = ServerException(
          message: 'Server error',
          statusCode: 500,
          code: 'INTERNAL_ERROR',
        );

        // Act
        final result = ErrorMapper.mapExceptionToFailure(exception);

        // Assert
        expect(result, isA<ServerFailure>());
        expect((result as ServerFailure).statusCode, 500);
        // Status code 500 is mapped to internal server error message
        expect(result.message, 'Something went wrong on our end. Please try again later.');
      });

      test('should map NetworkException to NetworkFailure', () {
        // Arrange
        const exception = NetworkException(message: 'No connection', code: 'NO_INTERNET');

        // Act
        final result = ErrorMapper.mapExceptionToFailure(exception);

        // Assert
        expect(result, isA<NetworkFailure>());
        expect(result.message, 'No connection');
      });

      test('should map CacheException to CacheFailure', () {
        // Arrange
        const exception = CacheException(message: 'Cache read failed', code: 'CACHE_ERROR');

        // Act
        final result = ErrorMapper.mapExceptionToFailure(exception);

        // Assert
        expect(result, isA<CacheFailure>());
        expect(result.message, 'Cache read failed');
      });

      test('should map ValidationException to ValidationFailure', () {
        // Arrange
        const exception = ValidationException(
          message: 'Validation failed',
          fieldErrors: {'email': 'Invalid email'},
        );

        // Act
        final result = ErrorMapper.mapExceptionToFailure(exception);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect((result as ValidationFailure).fieldErrors?['email'], 'Invalid email');
      });

      test('should map unknown exception to UnexpectedFailure', () {
        // Arrange
        final exception = Exception('Unknown error');

        // Act
        final result = ErrorMapper.mapExceptionToFailure(exception);

        // Assert
        expect(result, isA<UnexpectedFailure>());
        expect(result.message, contains('Unknown error'));
      });
    });

    group('utility methods', () {
      test('getFailureMessage should return failure message', () {
        // Arrange
        const failure = NetworkFailure('Connection lost');

        // Act
        final message = ErrorMapper.getFailureMessage(failure);

        // Assert
        expect(message, 'Connection lost');
      });

      test('isRecoverable should return true for NetworkFailure', () {
        // Arrange
        const failure = NetworkFailure();

        // Act
        final isRecoverable = ErrorMapper.isRecoverable(failure);

        // Assert
        expect(isRecoverable, isTrue);
      });

      test('isRecoverable should return false for ValidationFailure', () {
        // Arrange
        const failure = ValidationFailure('Invalid input');

        // Act
        final isRecoverable = ErrorMapper.isRecoverable(failure);

        // Assert
        expect(isRecoverable, isFalse);
      });

      test('requiresUserAction should return true for AuthenticationFailure', () {
        // Arrange
        const failure = AuthenticationFailure.invalidCredentials();

        // Act
        final requiresAction = ErrorMapper.requiresUserAction(failure);

        // Assert
        expect(requiresAction, isTrue);
      });

      test('requiresUserAction should return false for NetworkFailure', () {
        // Arrange
        const failure = NetworkFailure();

        // Act
        final requiresAction = ErrorMapper.requiresUserAction(failure);

        // Assert
        expect(requiresAction, isFalse);
      });
    });

    group('factory methods', () {
      test('createServerFailure should create ServerFailure with correct properties', () {
        // Act
        final failure = ErrorMapper.createServerFailure(
          statusCode: 404,
          message: 'Not found',
          code: 'NOT_FOUND',
        );

        // Assert
        expect(failure, isA<ServerFailure>());
        expect(failure.statusCode, 404);
        expect(failure.message, 'Not found');
        expect(failure.code, 'NOT_FOUND');
      });

      test('createValidationFailure should create ValidationFailure with field errors', () {
        // Arrange
        final fieldErrors = {'email': 'Invalid format', 'password': 'Too short'};

        // Act
        final failure = ErrorMapper.createValidationFailure(fieldErrors);

        // Assert
        expect(failure, isA<ValidationFailure>());
        expect(failure.fieldErrors?['email'], 'Invalid format');
        expect(failure.fieldErrors?['password'], 'Too short');
      });
    });
  });
}
