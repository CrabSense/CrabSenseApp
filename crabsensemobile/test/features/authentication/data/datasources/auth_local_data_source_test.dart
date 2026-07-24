import 'package:crabsensemobile/core/errors/exceptions.dart';
import 'package:crabsensemobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:crabsensemobile/features/authentication/data/models/user_model.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock FlutterSecureStorage for testing (in-memory only)
class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _storage = {};

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
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
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
  }) async => _storage[key];

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
    _storage.remove(key);
  }

  void clear() => _storage.clear();
}

void main() {
  late AuthLocalDataSourceImpl dataSource;
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    dataSource = AuthLocalDataSourceImpl(secureStorage: mockSecureStorage);
  });

  tearDown(() => mockSecureStorage.clear());

  // ── saveAccessToken / getAccessToken ─────────────────────────────────────

  group('saveAccessToken', () {
    const tToken = 'test_access_token';

    test('should store access token in secure storage', () async {
      await dataSource.saveAccessToken(tToken);
      final result = await dataSource.getAccessToken();
      expect(result, tToken);
    });
  });

  group('getAccessToken', () {
    const tToken = 'test_access_token';

    test('should return access token from secure storage', () async {
      await dataSource.saveAccessToken(tToken);
      final result = await dataSource.getAccessToken();
      expect(result, tToken);
    });

    test('should throw CacheException when no token stored', () async {
      // Implementation throws CacheException, not returns null
      expect(() => dataSource.getAccessToken(), throwsA(isA<CacheException>()));
    });
  });

  // ── saveRefreshToken / getRefreshToken ───────────────────────────────────

  group('saveRefreshToken', () {
    const tToken = 'test_refresh_token';

    test('should store refresh token in secure storage', () async {
      await dataSource.saveRefreshToken(tToken);
      final result = await dataSource.getRefreshToken();
      expect(result, tToken);
    });
  });

  group('getRefreshToken', () {
    const tToken = 'test_refresh_token';

    test('should return refresh token from secure storage', () async {
      await dataSource.saveRefreshToken(tToken);
      final result = await dataSource.getRefreshToken();
      expect(result, tToken);
    });

    test('should throw CacheException when no token stored', () async {
      expect(() => dataSource.getRefreshToken(), throwsA(isA<CacheException>()));
    });
  });

  // ── cacheUser / getCachedUser ─────────────────────────────────────────────

  group('cacheUser', () {
    final tUserModel = UserModel(
      id: '123',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.fieldOperator,
      assignedFarmIds: const ['farm1'],
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    );

    test('should store user data in secure storage', () async {
      await dataSource.cacheUser(tUserModel);
      final result = await dataSource.getCachedUser();
      expect(result.id, tUserModel.id);
      expect(result.email, tUserModel.email);
    });
  });

  group('getCachedUser', () {
    final tUserModel = UserModel(
      id: '123',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.fieldOperator,
      assignedFarmIds: const ['farm1'],
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    );

    test('should return user data from secure storage', () async {
      await dataSource.cacheUser(tUserModel);
      final result = await dataSource.getCachedUser();
      expect(result.id, tUserModel.id);
      expect(result.email, tUserModel.email);
      expect(result.role, tUserModel.role);
    });

    test('should throw CacheException when no user stored', () async {
      expect(() => dataSource.getCachedUser(), throwsA(isA<CacheException>()));
    });
  });

  // ── isAuthenticated ──────────────────────────────────────────────────────

  group('isAuthenticated', () {
    test('should return false when no token stored', () async {
      final result = await dataSource.isAuthenticated();
      expect(result, isFalse);
    });

    test('should return false when access token stored but no expiry', () async {
      await dataSource.saveAccessToken('some_token');
      final result = await dataSource.isAuthenticated();
      expect(result, isFalse);
    });

    test('should return true when token is stored and not expired', () async {
      await dataSource.saveAccessToken('valid_token');
      await dataSource.saveAccessTokenExpiry(DateTime.now().add(const Duration(hours: 1)));
      final result = await dataSource.isAuthenticated();
      expect(result, isTrue);
    });

    test('should return false when token is stored but expired', () async {
      await dataSource.saveAccessToken('expired_token');
      await dataSource.saveAccessTokenExpiry(DateTime.now().subtract(const Duration(hours: 1)));
      final result = await dataSource.isAuthenticated();
      expect(result, isFalse);
    });
  });

  // ── setBiometricEnabled / isBiometricEnabled ─────────────────────────────

  group('setBiometricEnabled', () {
    test('should store biometric preference as true', () async {
      await dataSource.setBiometricEnabled(true);
      final result = await dataSource.isBiometricEnabled();
      expect(result, isTrue);
    });

    test('should store biometric preference as false', () async {
      await dataSource.setBiometricEnabled(false);
      final result = await dataSource.isBiometricEnabled();
      expect(result, isFalse);
    });
  });

  group('isBiometricEnabled', () {
    test('should return true when enabled', () async {
      await dataSource.setBiometricEnabled(true);
      expect(await dataSource.isBiometricEnabled(), isTrue);
    });

    test('should return false when disabled', () async {
      await dataSource.setBiometricEnabled(false);
      expect(await dataSource.isBiometricEnabled(), isFalse);
    });

    test('should return false by default when not set', () async {
      expect(await dataSource.isBiometricEnabled(), isFalse);
    });
  });

  // ── clearAuthData ─────────────────────────────────────────────────────────

  group('clearAuthData', () {
    test('should clear all stored authentication data', () async {
      final tUserModel = UserModel(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.fieldOperator,
        assignedFarmIds: const ['farm1'],
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );
      await dataSource.saveAccessToken('access_token');
      await dataSource.saveRefreshToken('refresh_token');
      await dataSource.cacheUser(tUserModel);
      await dataSource.setBiometricEnabled(true);

      await dataSource.clearAuthData();

      expect(() => dataSource.getAccessToken(), throwsA(isA<CacheException>()));
      expect(() => dataSource.getRefreshToken(), throwsA(isA<CacheException>()));
      expect(() => dataSource.getCachedUser(), throwsA(isA<CacheException>()));
      // Biometric preference is retained after clearAuthData (by design)
      expect(await dataSource.isBiometricEnabled(), isTrue);
    });
  });
}
