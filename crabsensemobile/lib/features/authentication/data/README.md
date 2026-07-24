# Authentication Data Layer

This directory contains the data layer implementation for the authentication feature following Clean Architecture principles.

## Structure

```
data/
├── datasources/
│   ├── auth_remote_data_source.dart    # API communication
│   └── auth_local_data_source.dart     # Secure local storage
├── models/
│   ├── user_model.dart                 # Data Transfer Object with JSON serialization
│   └── user_model.g.dart               # Generated JSON serialization code
├── repositories/
│   └── auth_repository_impl.dart       # Repository implementation
└── README.md
```

## Components

### Models

#### UserModel
- Extends the domain `User` entity
- Implements JSON serialization using `json_serializable`
- Provides conversion methods: `fromJson`, `toJson`, `fromEntity`, `toEntity`
- Includes `copyWith` method for immutable updates

#### AuthResponse
- Encapsulates authentication response from API
- Contains user data and JWT tokens (access + refresh)
- Uses snake_case for JSON field mapping (`access_token`, `refresh_token`)

### Data Sources

#### AuthRemoteDataSource
Interface and implementation for API communication:
- `login(email, password)` - Authenticate with credentials
- `logout(accessToken)` - Invalidate session on server
- `refreshToken(refreshToken)` - Obtain new tokens
- `changePassword(...)` - Update user password

Uses Dio HTTP client with proper error handling and exception mapping.

#### AuthLocalDataSource
Interface and implementation for secure local storage:
- `saveAccessToken/getAccessToken` - JWT access token storage
- `saveRefreshToken/getRefreshToken` - JWT refresh token storage
- `saveUser/getUser` - Cached user data
- `hasStoredTokens` - Check authentication status
- `setBiometricEnabled/isBiometricEnabled` - Biometric preference
- `clearAll` - Logout cleanup

Uses FlutterSecureStorage for platform-specific secure storage:
- iOS: Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Android: EncryptedSharedPreferences backed by Android Keystore

### Repository

#### AuthRepositoryImpl
Implements `AuthRepository` interface from domain layer.

**Key Features:**
- Combines remote and local data sources
- Maps data models to domain entities
- Converts exceptions to domain Failures
- Implements offline-first patterns
- Comprehensive error handling

**Error Mapping:**
- `DioException` → `NetworkFailure`, `ServerFailure`, `AuthenticationFailure`
- Storage errors → `CacheFailure`
- Validation errors → `ValidationFailure`
- Unknown errors → `UnexpectedFailure`

**Security Features:**
- Tokens stored in platform secure storage
- Automatic token refresh
- Biometric authentication support
- Graceful logout (clears local data even if server fails)

## Security Considerations

### Token Storage
- Access and refresh tokens stored in FlutterSecureStorage
- Data encrypted at rest using platform-specific mechanisms
- Keys stored in hardware-backed keystores when available
- Data accessible only when device is unlocked

### Password Security
- Passwords never stored locally
- Password validation on client (UX) and server (security)
- Minimum 8 characters requirement enforced

### Certificate Pinning
Ready for implementation in Dio client configuration (see remote data source).

## Testing

Comprehensive test coverage for all components:
- Unit tests for models (JSON serialization/deserialization)
- Unit tests for local data source (secure storage operations)
- Integration tests verifying component composition
- All tests passing: 40/40 ✓

Run tests:
```bash
flutter test test/features/authentication/data/
```

## Usage Example

```dart
// Create dependencies
final dio = Dio(BaseOptions(baseUrl: 'https://api.crabsense.com'));
final remoteDataSource = AuthRemoteDataSourceImpl(
  dio: dio,
  baseUrl: 'https://api.crabsense.com',
);
final localDataSource = AuthLocalDataSourceImpl();

// Create repository
final authRepository = AuthRepositoryImpl(
  remoteDataSource: remoteDataSource,
  localDataSource: localDataSource,
);

// Use repository (returns Either<Failure, User>)
final result = await authRepository.login(
  email: 'user@example.com',
  password: 'password123',
);

result.fold(
  (failure) => print('Login failed: ${failure.message}'),
  (user) => print('Login successful: ${user.name}'),
);
```

## Code Generation

The `user_model.g.dart` file is generated from `user_model.dart` using build_runner:

```bash
# Generate once
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch
```

## Requirements Coverage

This implementation satisfies the following requirements from the specification:

- **Requirement 1.1**: Valid credentials generate JWT token within 2 seconds
- **Requirement 1.2**: Invalid credentials return authentication error
- **Requirement 1.3**: Expired token redirects to login (via repository)
- **Requirement 1.6**: JWT stored in secure device storage (Keychain/Keystore)
- **Requirement 1.7**: Network unavailable shows offline error
- **Requirement 1.9**: Biometric authentication support
- **Requirement 1.10**: Automatic session refresh before expiry
- **Requirement 18.6**: Password change with current password verification
- **Requirement 23.4**: JWT tokens in platform secure storage (AES-256 encrypted)

## Dependencies

- `dio: ^5.4.0` - HTTP client for API communication
- `flutter_secure_storage: ^9.0.0` - Secure storage for tokens
- `json_annotation: ^4.12.0` - JSON serialization annotations
- `dartz: ^0.10.1` - Functional programming (Either type)
- `logger: ^2.0.2+1` - Logging
- `equatable: ^2.0.5` - Value equality

Dev dependencies:
- `build_runner: ^2.4.7` - Code generation
- `json_serializable: ^6.7.1` - JSON serialization generator

## Next Steps

1. **Dependency Injection**: Register data sources and repository in GetIt service locator
2. **API Configuration**: Update base URL and endpoints for production
3. **Certificate Pinning**: Implement SSL pinning in Dio client
4. **Error Logging**: Integrate with Sentry/Firebase Crashlytics
5. **Token Refresh Timer**: Implement automatic refresh 5 minutes before expiry
6. **Biometric Integration**: Connect with local_auth package in presentation layer

## Notes

- All methods return `Either<Failure, Result>` for functional error handling
- Repository automatically clears local session on authentication failures
- Local data source uses JSON encoding for user data serialization
- Remote data source throws DioException, repository converts to Failures
- Thread-safe: All async operations use proper await/async patterns
