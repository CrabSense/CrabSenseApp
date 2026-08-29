import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// Concrete implementation of [AuthRepository].
///
/// Orchestrates remote and local data sources to deliver authentication
/// operations that satisfy Clean Architecture requirements:
///
/// - Always stores JWT tokens in [AuthLocalDataSource] (FlutterSecureStorage)
///   per Requirement 1.6 and security requirement 23.4.
/// - Clears all tokens on logout — tokens are NEVER logged.
/// - Maps data-layer exceptions to domain [Failure] types so that callers
///   never depend on infrastructure details.
/// - Detects network availability before remote calls and returns
///   [NetworkFailure] immediately when offline.
///
/// Requirements: 1.1-1.10, 18.6, 18.7, 23.4
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.localAuth,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  /// Platform biometric authenticator (local_auth).
  final LocalAuthentication localAuth;

  // ---------------------------------------------------------------------------
  // AuthRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, User>> login({required String email, required String password}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection. Please check your network.'));
    }

    try {
      final response = await remoteDataSource.login(email: email, password: password);
      await _persistAuthResponse(response);
      return Right(response.user.toEntity());
    } on ServerException catch (e) {
      return Left(_mapServerException(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, e.code));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message, e.field));
    } on CacheException catch (e) {
      // Remote login succeeded but local cache failed — surface cache error.
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithGoogle({String? idToken}) async {
    try {
      final response = await remoteDataSource.loginWithGoogle(idToken: idToken);
      await _persistAuthResponse(response);
      return Right(response.user.toEntity());
    } on ServerException catch (e) {
      return Left(_mapServerException(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, e.code));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message, e.field));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    // Attempt server-side token invalidation; tolerate network failure.
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getAccessToken();
        await remoteDataSource.logout(token);
      } on Exception {
        // Silently ignore — local cleanup always proceeds.
      }
    }

    try {
      await localDataSource.clearAuthData(); // clears tokens per req 23.4
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection. Please check your network.'));
    }

    try {
      final storedRefreshToken = await localDataSource.getRefreshToken();
      final response = await remoteDataSource.refreshToken(storedRefreshToken);
      await _persistAuthResponse(response);
      return Right(response.user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return const Left(AuthenticationFailure.tokenExpired());
      }
      return Left(_mapServerException(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, e.code));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message, e.field));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithBiometric() async {
    if (kIsWeb) {
      return const Left(
        AuthenticationFailure('Biometric authentication is not available on web.'),
      );
    }
    final isEnabled = await localDataSource.isBiometricEnabled();
    if (!isEnabled) {
      return const Left(
        AuthenticationFailure(
          'Biometric authentication is not enabled. '
          'Please enable it in settings.',
        ),
      );
    }

    try {
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        return const Left(
          PermissionFailure(
            'Biometric authentication is not available on this device.',
            permissionType: 'biometric',
          ),
        );
      }

      final authenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to access CrabSense',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (!authenticated) {
        return const Left(AuthenticationFailure.biometricFailed());
      }

      // Biometric confirmed — check whether the cached access token is fresh.
      final isTokenValid = await localDataSource.isAuthenticated();
      if (isTokenValid) {
        final user = await localDataSource.getCachedUser();
        return Right(user.toEntity());
      }
      // Token expired — attempt a silent refresh.
      return refreshToken();
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } on Exception catch (e) {
      return Left(UnexpectedFailure('Biometric authentication error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final isAuth = await localDataSource.isAuthenticated();
      return Right(isAuth);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCachedUser();
      return Right(user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection. Please check your network.'));
    }

    try {
      final accessToken = await localDataSource.getAccessToken();
      await remoteDataSource.changePassword(
        accessToken: accessToken,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } on ServerException catch (e) {
      return Left(_mapServerException(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, void>> setBiometricEnabled(bool enabled) async {
    if (kIsWeb && enabled) {
      return const Left(
        PermissionFailure('Biometric not available on web.', permissionType: 'biometric'),
      );
    }
    try {
      if (enabled) {
        final canCheck = await localAuth.canCheckBiometrics;
        final isSupported = await localAuth.isDeviceSupported();
        if (!canCheck || !isSupported) {
          return const Left(
            PermissionFailure(
              'Biometric authentication is not available on this device.',
              permissionType: 'biometric',
            ),
          );
        }
      }
      await localDataSource.setBiometricEnabled(enabled);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  @override
  Future<Either<Failure, bool>> isBiometricEnabled() async {
    try {
      final isEnabled = await localDataSource.isBiometricEnabled();
      return Right(isEnabled);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Persists all fields from an [AuthResponse] to secure storage.
  ///
  /// Tokens are stored via FlutterSecureStorage (Keychain / Keystore).
  /// Values are NEVER logged — security requirement 23.4.
  Future<void> _persistAuthResponse(AuthResponse response) async {
    await Future.wait([
      localDataSource.cacheUser(response.user),
      localDataSource.saveAccessToken(response.accessToken),
      localDataSource.saveRefreshToken(response.refreshToken),
      localDataSource.saveAccessTokenExpiry(response.accessTokenExpiresAt),
      localDataSource.saveRefreshTokenExpiry(response.refreshTokenExpiresAt),
    ]);
  }

  /// Converts a [ServerException] to the most specific [Failure] subtype.
  Failure _mapServerException(ServerException e) {
    switch (e.statusCode) {
      case 401:
        return const AuthenticationFailure.invalidCredentials();
      case 403:
        return const AuthenticationFailure.accountLocked();
      case 404:
        return const ServerFailure.notFound();
      case 422:
        if (e.details != null) {
          final fields = <String, String>{};
          e.details!.forEach((k, v) => fields[k] = v.toString());
          return ValidationFailure.fields(fields);
        }
        return ValidationFailure(e.message);
      case 500:
      case 502:
      case 503:
        return const ServerFailure.internal();
      default:
        return ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    }
  }
}
