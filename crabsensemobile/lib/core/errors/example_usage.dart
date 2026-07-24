// ignore_for_file: unused_local_variable, unused_element

/// Example usage of the error handling framework.
///
/// This file demonstrates how to use failures, exceptions, and error mapping
/// across different layers of the application following Clean Architecture.
///
/// NOTE: This example uses the `dartz` package for Either type which is NOT
/// included in the project dependencies. If you want to use Either for
/// functional error handling, add `dartz: ^0.10.1` to pubspec.yaml.
///
/// Alternatively, you can use try-catch with callbacks or return nullable
/// types with separate error state management in BLoC.
///
/// DO NOT import this file in production code - it's for reference only.
library;

import 'package:dio/dio.dart';
// import 'package:dartz/dartz.dart'; // Add dartz package if needed
import 'package:fpdart/fpdart.dart';
import 'errors.dart';

// NOTE: The following examples show the recommended pattern using Either type.
// If not using dartz, adapt the pattern to your error handling strategy.

// ============================================================================
// DATA SOURCE LAYER - Throws Exceptions
// ============================================================================

abstract class BoxRemoteDataSource {
  Future<Map<String, dynamic>> getBox(String id);
}

class BoxRemoteDataSourceImpl implements BoxRemoteDataSource {
  BoxRemoteDataSourceImpl(this.client);
  final Dio client;

  @override
  Future<Map<String, dynamic>> getBox(String id) async {
    try {
      final response = await client.get('/api/boxes/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Convert Dio errors to custom exceptions
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(message: 'Connection timeout', code: 'TIMEOUT');
      }

      if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Server error',
          statusCode: e.response?.statusCode,
          code: e.response?.data['code'],
        );
      }

      throw const NetworkException(message: 'Network error occurred');
    } catch (e) {
      throw ParseException(message: 'Failed to parse response: ${e.toString()}');
    }
  }
}

abstract class BoxLocalDataSource {
  Future<Map<String, dynamic>> getCachedBox(String id);
  Future<void> cacheBox(Map<String, dynamic> box);
}

class BoxLocalDataSourceImpl implements BoxLocalDataSource {
  @override
  Future<Map<String, dynamic>> getCachedBox(String id) async {
    // Simulate cache read
    try {
      // Read from local database
      final data = await _readFromDatabase(id);
      return data;
    } catch (e) {
      throw const CacheException(message: 'Failed to read from cache', code: 'CACHE_READ_ERROR');
    }
  }

  @override
  Future<void> cacheBox(Map<String, dynamic> box) async {
    try {
      // Write to local database
      await _writeToDatabase(box);
    } catch (e) {
      throw const CacheException(message: 'Failed to write to cache', code: 'CACHE_WRITE_ERROR');
    }
  }

  Future<Map<String, dynamic>> _readFromDatabase(String id) async {
    // Simulated database read
    throw Exception('Database error');
  }

  Future<void> _writeToDatabase(Map<String, dynamic> data) async {
    // Simulated database write
  }
}

// ============================================================================
// REPOSITORY LAYER - Catches Exceptions, Returns Failures
// ============================================================================

abstract class BoxRepository {
  Future<Either<Failure, Map<String, dynamic>>> getBox(String id);
}

class BoxRepositoryImpl implements BoxRepository {
  BoxRepositoryImpl({required this.remoteDataSource, required this.localDataSource});
  final BoxRemoteDataSource remoteDataSource;
  final BoxLocalDataSource localDataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBox(String id) async {
    try {
      // Try to fetch from remote
      final boxData = await remoteDataSource.getBox(id);

      // Cache locally for offline access
      try {
        await localDataSource.cacheBox(boxData);
      } catch (e) {
        // Caching failure is not critical, just log it
        print('Warning: Failed to cache box data');
      }

      return Right(boxData);
    } on NetworkException catch (e) {
      // When network fails, try to get from cache
      try {
        final cachedBox = await localDataSource.getCachedBox(id);
        return Right(cachedBox);
      } on CacheException {
        // Both remote and cache failed
        return Left(ErrorMapper.mapExceptionToFailure(e));
      }
    } on ServerException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } on CacheException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e, stackTrace) {
      // Catch any unexpected exceptions
      return Left(ErrorMapper.mapExceptionToFailure(e, stackTrace));
    }
  }
}

// ============================================================================
// DOMAIN LAYER - Use Cases (Pass Through Failures)
// ============================================================================

class GetBoxUseCase {
  GetBoxUseCase(this.repository);
  final BoxRepository repository;

  Future<Either<Failure, Map<String, dynamic>>> call(String id) async {
    // Validate input
    if (id.isEmpty) {
      return const Left(ValidationFailure.required('Box ID'));
    }

    // Call repository
    return repository.getBox(id);
  }
}

// ============================================================================
// PRESENTATION LAYER - BLoC (Handle Failures, Update UI)
// ============================================================================

// Events
abstract class BoxEvent {}

class LoadBoxDetails extends BoxEvent {
  LoadBoxDetails(this.boxId);
  final String boxId;
}

// States
abstract class BoxState {}

class BoxInitial extends BoxState {}

class BoxLoading extends BoxState {}

class BoxLoaded extends BoxState {
  BoxLoaded(this.box);
  final Map<String, dynamic> box;
}

class BoxError extends BoxState {
  BoxError(this.message, {this.canRetry = false});
  final String message;
  final bool canRetry;
}

// BLoC
class BoxBloc {
  BoxBloc({required this.getBoxUseCase});
  final GetBoxUseCase getBoxUseCase;

  Future<void> _onLoadBoxDetails(LoadBoxDetails event) async {
    // emit(BoxLoading());

    final result = await getBoxUseCase(event.boxId);

    result.fold(
      (failure) {
        // Extract user-friendly message
        final message = ErrorMapper.getFailureMessage(failure);

        // Check if error is recoverable
        final canRetry = ErrorMapper.isRecoverable(failure);

        // Check if user action is required
        final requiresAction = ErrorMapper.requiresUserAction(failure);

        if (requiresAction) {
          // Navigate to appropriate screen (login, permissions, etc.)
          _handleUserActionRequired(failure);
        }

        // emit(BoxError(message, canRetry: canRetry));
      },
      (box) {
        // emit(BoxLoaded(box));
      },
    );
  }

  void _handleUserActionRequired(Failure failure) {
    if (failure is AuthenticationFailure) {
      // Navigate to login screen
      print('Navigate to login');
    } else if (failure is PermissionFailure) {
      // Show permission settings dialog
      print('Show permission dialog');
    } else if (failure is ValidationFailure) {
      // Show form validation errors
      print('Show validation errors');
    }
  }
}

// ============================================================================
// UTILITY EXAMPLES
// ============================================================================

void demonstrateFailureCreation() {
  // Creating specific failures
  const networkFailure = NetworkFailure();
  const timeoutFailure = NetworkFailure.timeout();

  const serverFailure = ServerFailure('Internal server error', statusCode: 500);
  const unauthorizedFailure = ServerFailure.unauthorized();

  const cacheFailure = CacheFailure();
  const cacheWriteFailure = CacheFailure.writeError();

  final validationFailure = ValidationFailure.fields(const {
    'email': 'Invalid email format',
    'password': 'Password must be at least 8 characters',
  });

  const permissionFailure = PermissionFailure.camera();
  const authFailure = AuthenticationFailure.invalidCredentials();
}

void demonstrateExceptionHandling() {
  // Example of throwing exceptions from data source
  Future<void> riskyOperation() async {
    throw const ServerException(message: 'Resource not found', statusCode: 404, code: 'NOT_FOUND');
  }

  // Example of catching and mapping in repository
  Future<Either<Failure, String>> safeOperation() async {
    try {
      await riskyOperation();
      return const Right('Success');
    } catch (e, stackTrace) {
      return Left(ErrorMapper.mapExceptionToFailure(e, stackTrace));
    }
  }
}

void demonstrateErrorMapperUtilities() {
  const failure = NetworkFailure();

  // Get user-friendly message
  final message = ErrorMapper.getFailureMessage(failure);
  print(message); // "No internet connection. Please check your network settings."

  // Check if recoverable (can retry)
  final canRetry = ErrorMapper.isRecoverable(failure);
  print(canRetry); // true

  // Check if requires user action
  final requiresAction = ErrorMapper.requiresUserAction(failure);
  print(requiresAction); // false

  // Create specific failures
  final serverFailure = ErrorMapper.createServerFailure(
    statusCode: 500,
    message: 'Internal server error',
    code: 'INTERNAL_ERROR',
  );

  final validationFailure = ErrorMapper.createValidationFailure({
    'email': 'Required',
    'password': 'Too short',
  });
}

// ============================================================================
// TESTING EXAMPLES
// ============================================================================

void demonstrateTestingFailures() {
  // Test failure equality
  const failure1 = NetworkFailure();
  const failure2 = NetworkFailure();
  print(failure1 == failure2); // true (thanks to Equatable)

  // Test failure properties
  const serverFailure = ServerFailure('Error', statusCode: 404);
  print(serverFailure.message); // "Error"
  print(serverFailure.statusCode); // 404
  print(serverFailure.code); // "SERVER_ERROR"
}
