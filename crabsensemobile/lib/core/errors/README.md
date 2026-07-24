# Error Handling Framework

This directory contains the core error handling framework for the CrabSense mobile application, following Clean Architecture principles.

## Architecture

The error handling framework consists of three main components:

### 1. Exceptions (`exceptions.dart`)

**Purpose**: Technical errors that occur at the data layer (API calls, database operations, file I/O, etc.).

**Usage**: Thrown from data sources and caught at the repository layer.

**Examples**:
- `ServerException` - HTTP request failures
- `NetworkException` - No internet connection
- `CacheException` - Local storage failures
- `ParseException` - JSON parsing failures
- `ValidationException` - Input validation failures
- `AuthenticationException` - Authentication failures
- `PermissionException` - Permission denied
- `MediaException` - Camera/video operations failures
- `QRException` - QR code scanning failures

### 2. Failures (`failures.dart`)

**Purpose**: Business logic error objects that represent handled errors at the domain level.

**Usage**: Returned from repository methods to indicate what went wrong in a user-friendly way.

**Examples**:
- `NetworkFailure` - Connection issues with user-friendly messages
- `ServerFailure` - Server errors with HTTP status codes
- `CacheFailure` - Local storage issues
- `ValidationFailure` - Form validation errors with field-level details
- `AuthenticationFailure` - Login/session failures
- `PermissionFailure` - Permission denial with guidance
- `SyncFailure` - Offline synchronization failures

### 3. Error Mapper (`error_mapper.dart`)

**Purpose**: Utility class that converts exceptions into failures.

**Usage**: Called in repository catch blocks to transform technical exceptions into domain failures.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│                          (BLoC)                              │
│  - Receives Failures from use cases                         │
│  - Displays user-friendly error messages                    │
│  - Shows retry buttons for recoverable errors               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Either<Failure, Data>
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                      Domain Layer                            │
│                      (Use Cases)                             │
│  - Passes through Failures from repositories                │
│  - No exception handling needed                             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Either<Failure, Data>
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                       Data Layer                             │
│                     (Repositories)                           │
│  - Catches exceptions from data sources                     │
│  - Uses ErrorMapper to convert to Failures                  │
│  - Returns Either<Failure, Data>                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ throws Exception
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                     Data Sources                             │
│              (Remote, Local, Services)                       │
│  - Throws exceptions when operations fail                   │
│  - Does not catch or handle exceptions                      │
└─────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Data Source Layer

```dart
class BoxRemoteDataSourceImpl implements BoxRemoteDataSource {
  final Dio client;

  @override
  Future<BoxDto> getBox(String id) async {
    try {
      final response = await client.get('/api/boxes/$id');
      return BoxDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException(
          message: 'Connection timeout',
          code: 'TIMEOUT',
        );
      }
      throw ServerException(
        message: e.response?.data['message'] ?? 'Server error',
        statusCode: e.response?.statusCode,
      );
    } on SocketException {
      throw const NetworkException(
        message: 'No internet connection',
      );
    } catch (e) {
      throw ParseException(
        message: 'Failed to parse response: ${e.toString()}',
      );
    }
  }
}
```

### Repository Layer

```dart
class BoxRepositoryImpl implements BoxRepository {
  final BoxRemoteDataSource remoteDataSource;
  final BoxLocalDataSource localDataSource;

  @override
  Future<Either<Failure, Box>> getBox(String id) async {
    try {
      // Try remote first
      final boxDto = await remoteDataSource.getBox(id);
      
      // Cache locally
      await localDataSource.cacheBox(boxDto);
      
      return Right(boxDto.toEntity());
    } on ServerException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } on NetworkException catch (e) {
      // Try to get from cache when offline
      try {
        final cachedBox = await localDataSource.getCachedBox(id);
        return Right(cachedBox.toEntity());
      } on CacheException catch (cacheError) {
        return Left(ErrorMapper.mapExceptionToFailure(e));
      }
    } catch (e, stackTrace) {
      return Left(ErrorMapper.mapExceptionToFailure(e, stackTrace));
    }
  }
}
```

### Use Case Layer

```dart
class GetBoxUseCase {
  final BoxRepository repository;

  Future<Either<Failure, Box>> call(String id) async {
    return await repository.getBox(id);
  }
}
```

### Presentation Layer (BLoC)

```dart
class BoxBloc extends Bloc<BoxEvent, BoxState> {
  final GetBoxUseCase getBoxUseCase;

  BoxBloc({required this.getBoxUseCase}) : super(BoxInitial()) {
    on<LoadBoxDetails>(_onLoadBoxDetails);
  }

  Future<void> _onLoadBoxDetails(
    LoadBoxDetails event,
    Emitter<BoxState> emit,
  ) async {
    emit(BoxLoading());

    final result = await getBoxUseCase(event.boxId);

    result.fold(
      (failure) {
        final message = ErrorMapper.getFailureMessage(failure);
        final canRetry = ErrorMapper.isRecoverable(failure);
        emit(BoxError(message, canRetry: canRetry));
      },
      (box) => emit(BoxLoaded(box)),
    );
  }
}
```

### UI Layer (Widget)

```dart
class BoxDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoxBloc, BoxState>(
      builder: (context, state) {
        if (state is BoxLoading) {
          return const CircularProgressIndicator();
        }

        if (state is BoxError) {
          return ErrorStateWidget(
            message: state.message,
            onRetry: state.canRetry
                ? () => context.read<BoxBloc>().add(LoadBoxDetails(boxId))
                : null,
          );
        }

        if (state is BoxLoaded) {
          return BoxDetailsView(box: state.box);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
```

## Error Message Guidelines

### User-Friendly Messages

All failure messages should:
- Be clear and concise (avoid technical jargon)
- Explain what went wrong in simple terms
- Provide actionable next steps when possible
- Be empathetic to the user's situation

### Examples

✅ Good:
- "No internet connection. Please check your network settings."
- "Your session has expired. Please login again."
- "Unable to save data. Device storage may be full."

❌ Bad:
- "SocketException: Connection refused"
- "HTTP 401 Unauthorized"
- "NullPointerException at line 42"

## Error Categorization

### Recoverable Errors (Can Retry)
- `NetworkFailure` - User can retry when connection is restored
- `ServerFailure` (5xx) - Temporary server issues, retry with backoff
- `SyncFailure` - Automatic retry with exponential backoff

### Non-Recoverable Errors (Require User Action)
- `AuthenticationFailure` - User must login again
- `PermissionFailure` - User must grant permissions in settings
- `ValidationFailure` - User must correct form inputs
- `ServerFailure` (4xx) - User action needed (e.g., forbidden, not found)

### Critical Errors (Log and Report)
- `UnexpectedFailure` - Unknown errors that should be reported
- `ParseFailure` - Data format issues that should be logged
- `CacheFailure.corrupted` - Data corruption requiring investigation

## Best Practices

1. **Always use ErrorMapper in repositories** - Don't manually create failures
2. **Never show raw exceptions to users** - Convert to user-friendly messages
3. **Provide retry options for recoverable errors** - NetworkFailure, ServerFailure
4. **Log all unexpected errors** - Use logger or crash reporting service
5. **Include context in error messages** - Field names, resource types, etc.
6. **Test error handling paths** - Write unit tests for all failure scenarios
7. **Use specific failure types** - Don't overuse UnexpectedFailure
8. **Never log sensitive data** - Passwords, tokens, PII should not appear in logs

## Testing

### Unit Testing Failures

```dart
test('NetworkFailure should have correct message and code', () {
  const failure = NetworkFailure();
  expect(failure.message, contains('No internet connection'));
  expect(failure.code, 'NETWORK_ERROR');
});
```

### Testing Error Mapping

```dart
test('ErrorMapper should convert ServerException to ServerFailure', () {
  final exception = ServerException(
    message: 'Not found',
    statusCode: 404,
  );
  
  final failure = ErrorMapper.mapExceptionToFailure(exception);
  
  expect(failure, isA<ServerFailure>());
  expect((failure as ServerFailure).statusCode, 404);
});
```

### Testing Repository Error Handling

```dart
test('getBox should return NetworkFailure when network is unavailable', () async {
  // Arrange
  when(mockRemoteDataSource.getBox(any))
      .thenThrow(const NetworkException());
  when(mockLocalDataSource.getCachedBox(any))
      .thenThrow(const CacheException(message: 'No cache'));

  // Act
  final result = await repository.getBox('123');

  // Assert
  expect(result.isLeft(), true);
  result.fold(
    (failure) => expect(failure, isA<NetworkFailure>()),
    (_) => fail('Should not succeed'),
  );
});
```

## Extending the Framework

### Adding New Failure Types

1. Create a new class extending `Failure` in `failures.dart`
2. Add documentation explaining when to use it
3. Implement factory constructors for common scenarios
4. Update `ErrorMapper` to handle related exceptions

### Adding New Exception Types

1. Create a new class implementing `Exception` in `exceptions.dart`
2. Add documentation explaining when it should be thrown
3. Update `ErrorMapper.mapExceptionToFailure()` to handle it
4. Throw from appropriate data sources

## Dependencies

- `equatable` - For value equality in Failure objects
- `dio` - HTTP client with error handling support

## See Also

- [Clean Architecture Error Handling](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [Either Type for Error Handling](https://pub.dev/packages/dartz)
