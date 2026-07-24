import 'package:crabsensemobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:crabsensemobile/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:crabsensemobile/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:crabsensemobile/core/network/network_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

/// Minimal stub for [FlutterSecureStorage] used during structural tests.
class _StubSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

/// Minimal stub for [NetworkInfo].
class _StubNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

/// Integration test: verifies that all authentication data-layer classes
/// can be instantiated with their correct constructor signatures and that
/// they implement the expected interfaces.
///
/// These are compile-time / structural tests — no live network calls are made.
void main() {
  group('Authentication Data Layer Integration', () {
    late Dio dio;
    late _StubSecureStorage secureStorage;
    late AuthRemoteDataSourceImpl remoteDataSource;
    late AuthLocalDataSourceImpl localDataSource;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      secureStorage = _StubSecureStorage();
      remoteDataSource = AuthRemoteDataSourceImpl(dio: dio);
      localDataSource = AuthLocalDataSourceImpl(secureStorage: secureStorage);
    });

    test('AuthRemoteDataSourceImpl implements AuthRemoteDataSource', () {
      expect(remoteDataSource, isA<AuthRemoteDataSource>());
    });

    test('AuthLocalDataSourceImpl implements AuthLocalDataSource', () {
      expect(localDataSource, isA<AuthLocalDataSource>());
    });

    test('AuthRepositoryImpl can be instantiated with required deps', () {
      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        networkInfo: _StubNetworkInfo(),
        localAuth: LocalAuthentication(),
      );
      expect(repository, isA<AuthRepositoryImpl>());
    });

    test('AuthRemoteDataSourceImpl has all required methods', () {
      expect(remoteDataSource.login, isA<Function>());
      expect(remoteDataSource.logout, isA<Function>());
      expect(remoteDataSource.refreshToken, isA<Function>());
      expect(remoteDataSource.changePassword, isA<Function>());
    });

    test('AuthLocalDataSourceImpl has all required methods', () {
      expect(localDataSource.saveAccessToken, isA<Function>());
      expect(localDataSource.getAccessToken, isA<Function>());
      expect(localDataSource.saveRefreshToken, isA<Function>());
      expect(localDataSource.getRefreshToken, isA<Function>());
      // Naming follows the actual implementation (not the old stub names).
      expect(localDataSource.cacheUser, isA<Function>());
      expect(localDataSource.getCachedUser, isA<Function>());
      expect(localDataSource.isAuthenticated, isA<Function>());
      expect(localDataSource.setBiometricEnabled, isA<Function>());
      expect(localDataSource.isBiometricEnabled, isA<Function>());
      expect(localDataSource.clearAuthData, isA<Function>());
    });

    test('AuthRepositoryImpl has all required repository methods', () {
      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        networkInfo: _StubNetworkInfo(),
        localAuth: LocalAuthentication(),
      );
      expect(repository.login, isA<Function>());
      expect(repository.logout, isA<Function>());
      expect(repository.refreshToken, isA<Function>());
      expect(repository.loginWithBiometric, isA<Function>());
      expect(repository.isAuthenticated, isA<Function>());
      expect(repository.getCurrentUser, isA<Function>());
      expect(repository.changePassword, isA<Function>());
      expect(repository.setBiometricEnabled, isA<Function>());
      expect(repository.isBiometricEnabled, isA<Function>());
    });
  });
}
