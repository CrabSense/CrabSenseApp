import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Local data source for authentication data storage.
///
/// Handles secure storage of JWT tokens and user data using
/// FlutterSecureStorage which uses:
/// - Keychain on iOS
/// - Keystore on Android
///
/// All methods throw [CacheException] on storage operation failures.
abstract class AuthLocalDataSource {
  /// Saves user data to secure storage.
  ///
  /// Throws [CacheException] if write operation fails.
  Future<void> cacheUser(UserModel user);

  /// Retrieves cached user data from secure storage.
  ///
  /// Returns [UserModel] if data exists and is valid.
  /// Throws [CacheException] if no data found or parsing fails.
  Future<UserModel> getCachedUser();

  /// Saves JWT access token to secure storage.
  ///
  /// Throws [CacheException] if write operation fails.
  ///
  /// Requirements: 1.6
  Future<void> saveAccessToken(String token);

  /// Retrieves JWT access token from secure storage.
  ///
  /// Returns token string if exists.
  /// Throws [CacheException] if no token found.
  ///
  /// Requirements: 1.6
  Future<String> getAccessToken();

  /// Saves JWT refresh token to secure storage.
  ///
  /// Throws [CacheException] if write operation fails.
  ///
  /// Requirements: 1.6
  Future<void> saveRefreshToken(String token);

  /// Retrieves JWT refresh token from secure storage.
  ///
  /// Returns token string if exists.
  /// Throws [CacheException] if no token found.
  ///
  /// Requirements: 1.6
  Future<String> getRefreshToken();

  /// Saves access token expiry timestamp to secure storage.
  ///
  /// Throws [CacheException] if write operation fails.
  Future<void> saveAccessTokenExpiry(DateTime expiry);

  /// Retrieves access token expiry timestamp from secure storage.
  ///
  /// Returns [DateTime] if exists.
  /// Throws [CacheException] if no expiry found.
  Future<DateTime> getAccessTokenExpiry();

  /// Saves refresh token expiry timestamp to secure storage.
  ///
  /// Throws [CacheException] if write operation fails.
  Future<void> saveRefreshTokenExpiry(DateTime expiry);

  /// Retrieves refresh token expiry timestamp from secure storage.
  ///
  /// Returns [DateTime] if exists.
  /// Throws [CacheException] if no expiry found.
  Future<DateTime> getRefreshTokenExpiry();

  /// Clears all authentication data from secure storage.
  ///
  /// This includes:
  /// - User data
  /// - Access token and expiry
  /// - Refresh token and expiry
  /// - Biometric preference
  ///
  /// Used during logout.
  ///
  /// Throws [CacheException] if clear operation fails.
  Future<void> clearAuthData();

  /// Removes leftover mock_* tokens from the old offline-login stub.
  /// Returns true if a mock session was cleared. Call at app startup
  /// before NotificationService / sync hit the API.
  Future<bool> purgeMockSessionIfPresent();

  /// Saves biometric authentication preference.
  ///
  /// Throws [CacheException] if write operation fails.
  ///
  /// Requirements: 1.9, 18.7
  Future<void> setBiometricEnabled(bool enabled);

  /// Retrieves biometric authentication preference.
  ///
  /// Returns true if enabled, false otherwise.
  /// Returns false by default if no preference is set.
  ///
  /// Requirements: 1.9, 18.7
  Future<bool> isBiometricEnabled();

  /// Checks if user is authenticated by verifying token exists and is not
  /// expired.
  ///
  /// Returns true if valid token exists, false otherwise.
  ///
  /// Requirements: 1.8
  Future<bool> isAuthenticated();
}

/// Implementation of [AuthLocalDataSource] using FlutterSecureStorage.
/// On Web: falls back to localStorage (no Keychain/Keystore available).
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({required this.secureStorage});
  final FlutterSecureStorage secureStorage;

  // Web IndexedDB can lag behind writes; keep tokens in RAM so Dio
  // attaches JWT immediately after login.
  String? _memAccessToken;
  String? _memRefreshToken;

  // Storage keys
  static const String _keyUser = 'auth_user';
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyAccessTokenExpiry = 'auth_access_token_expiry';
  static const String _keyRefreshTokenExpiry = 'auth_refresh_token_expiry';
  static const String _keyBiometricEnabled = 'auth_biometric_enabled';

  // ── Web-safe storage helpers ─────────────────────────────────────────
  Future<void> _write(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }

  Future<String?> _read(String key) async {
    return secureStorage.read(key: key);
  }

  Future<void> _delete(String key) async {
    await secureStorage.delete(key: key);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _write(_keyUser, userJson);
    } catch (e) {
      throw CacheException(message: 'Failed to cache user data: $e');
    }
  }

  @override
  Future<UserModel> getCachedUser() async {
    try {
      final userJson = await _read(_keyUser);
      if (userJson == null) {
        throw const CacheException(message: 'No cached user data found');
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: 'Failed to retrieve cached user: $e');
    }
  }

  @override
  Future<void> saveAccessToken(String token) async {
    _memAccessToken = token;
    try {
      await _write(_keyAccessToken, token);
    } catch (e) {
      throw CacheException(message: 'Failed to save access token: $e');
    }
  }

  @override
  Future<String> getAccessToken() async {
    final mem = _memAccessToken;
    if (mem != null && mem.isNotEmpty) return mem;
    try {
      final token = await _read(_keyAccessToken);
      if (token == null || token.isEmpty) {
        throw const CacheException(message: 'No access token found');
      }
      _memAccessToken = token;
      return token;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: 'Failed to retrieve access token: $e');
    }
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _memRefreshToken = token;
    try {
      await _write(_keyRefreshToken, token);
    } catch (e) {
      throw CacheException(message: 'Failed to save refresh token: $e');
    }
  }

  @override
  Future<String> getRefreshToken() async {
    final mem = _memRefreshToken;
    if (mem != null && mem.isNotEmpty) return mem;
    try {
      final token = await _read(_keyRefreshToken);
      if (token == null || token.isEmpty) {
        throw const CacheException(message: 'No refresh token found');
      }
      _memRefreshToken = token;
      return token;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: 'Failed to retrieve refresh token: $e');
    }
  }

  @override
  Future<void> saveAccessTokenExpiry(DateTime expiry) async {
    try {
      await _write(_keyAccessTokenExpiry, expiry.toIso8601String());
    } catch (e) {
      throw CacheException(message: 'Failed to save access token expiry: $e');
    }
  }

  @override
  Future<DateTime> getAccessTokenExpiry() async {
    try {
      final expiryStr = await _read(_keyAccessTokenExpiry);
      if (expiryStr == null) {
        throw const CacheException(message: 'No access token expiry found');
      }
      return DateTime.parse(expiryStr);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: 'Failed to retrieve access token expiry: $e');
    }
  }

  @override
  Future<void> saveRefreshTokenExpiry(DateTime expiry) async {
    try {
      await _write(_keyRefreshTokenExpiry, expiry.toIso8601String());
    } catch (e) {
      throw CacheException(message: 'Failed to save refresh token expiry: $e');
    }
  }

  @override
  Future<DateTime> getRefreshTokenExpiry() async {
    try {
      final expiryStr = await _read(_keyRefreshTokenExpiry);
      if (expiryStr == null) {
        throw const CacheException(message: 'No refresh token expiry found');
      }
      return DateTime.parse(expiryStr);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: 'Failed to retrieve refresh token expiry: $e');
    }
  }

  @override
  Future<void> clearAuthData() async {
    _memAccessToken = null;
    _memRefreshToken = null;
    try {
      await Future.wait([
        _delete(_keyUser),
        _delete(_keyAccessToken),
        _delete(_keyRefreshToken),
        _delete(_keyAccessTokenExpiry),
        _delete(_keyRefreshTokenExpiry),
        // Note: Keep biometric preference - user choice persists across logins
      ]);
    } catch (e) {
      throw CacheException(message: 'Failed to clear auth data: $e');
    }
  }

  @override
  Future<bool> purgeMockSessionIfPresent() async {
    try {
      final token = await _read(_keyAccessToken);
      final refresh = await _read(_keyRefreshToken);
      if (_isMockToken(token) || _isMockToken(refresh)) {
        await clearAuthData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _write(_keyBiometricEnabled, enabled.toString());
    } catch (e) {
      throw CacheException(message: 'Failed to save biometric preference: $e');
    }
  }

  @override
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _read(_keyBiometricEnabled);
      return value == 'true';
    } catch (e) {
      // Return false by default if preference is not set
      return false;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await _read(_keyAccessToken);
      final refresh = await _read(_keyRefreshToken);

      // Discard leftover mock session from old offline-login stub.
      if (_isMockToken(token) || _isMockToken(refresh)) {
        await clearAuthData();
        return false;
      }

      if (token == null || token.isEmpty) {
        return false;
      }

      final expiryStr = await _read(_keyAccessTokenExpiry);
      if (expiryStr == null) {
        return false;
      }

      final expiry = DateTime.parse(expiryStr);
      return !DateTime.now().isAfter(expiry);
    } catch (e) {
      return false;
    }
  }

  static bool _isMockToken(String? token) =>
      token != null && token.startsWith('mock_');
}
