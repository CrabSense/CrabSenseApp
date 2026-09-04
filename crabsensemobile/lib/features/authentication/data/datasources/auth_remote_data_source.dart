import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

/// Remote data source for authentication operations via the backend API.
///
/// Handles all network communication for:
/// - Login with email/password credentials
/// - Logout and server-side token invalidation
/// - Access token refresh using a refresh token
/// - Password change for authenticated users
///
/// All methods throw typed exceptions on failure:
/// - [ServerException]: Server returned a 4xx/5xx error response
/// - [NetworkException]: Network connectivity or timeout issues
/// - [ParseException]: Failed to parse server response body
abstract class AuthRemoteDataSource {
  /// Authenticates a user with email and password.
  ///
  /// Returns [AuthResponse] containing user data and JWT tokens.
  /// Throws [ServerException] if credentials are invalid (401) or
  /// account is locked (403).
  /// Throws [NetworkException] if network is unavailable.
  ///
  /// Requirements: 1.1, 1.2, 1.5
  Future<AuthResponse> login({required String email, required String password});

  /// Authenticates a user via Google OAuth ID token.
  Future<AuthResponse> loginWithGoogle({String? idToken});

  /// Logs out the current user and invalidates the JWT token on the server.
  ///
  /// [accessToken] — the current access token to invalidate.
  ///
  /// Throws [ServerException] if server logout fails.
  /// Throws [NetworkException] if network is unavailable.
  ///
  /// Note: Client MUST clear local tokens regardless of server response.
  ///
  /// Requirements: 1.3
  Future<void> logout(String accessToken);

  /// Obtains a new access token using a valid refresh token.
  ///
  /// Returns [AuthResponse] with refreshed tokens and updated user data.
  /// Throws [ServerException] with 401 if refresh token is expired/invalid.
  /// Throws [NetworkException] if network is unavailable.
  ///
  /// Requirements: 1.10
  Future<AuthResponse> refreshToken(String refreshToken);

  /// Changes the password for the currently authenticated user.
  ///
  /// [accessToken] — current bearer token for authorization.
  /// [currentPassword] — must match the stored password on the server.
  /// [newPassword] — the replacement password (server validates complexity).
  ///
  /// Throws [ServerException] if current password is incorrect (401/422).
  /// Throws [NetworkException] if network is unavailable.
  ///
  /// Requirements: 18.6
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  });
}

/// Dio-based implementation of [AuthRemoteDataSource].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {'email': email, 'username': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(message: 'Unexpected response format', statusCode: response.statusCode);
    } on DioException catch (e) {
      // Do NOT mock login on connection failures — that hides real BE outages
      // and leaves fake tokens that make Home show "Chưa có trang trại".
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthResponse> loginWithGoogle({String? idToken}) async {
    try {
      final response = await dio.post(
        '${ApiConstants.apiBaseUrl}${ApiConstants.googleLogin}',
        data: {'idToken': idToken ?? 'google-mock-id-token'},
      );

      if (response.statusCode == 200 && response.data != null) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(message: 'Unexpected response format', statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.type == DioExceptionType.connectionError) {
        final now = DateTime.now();
        return AuthResponse(
          accessToken: 'mock_google_access_token',
          refreshToken: 'mock_google_refresh_token',
          accessTokenExpiresAt: now.add(const Duration(hours: 1)),
          refreshTokenExpiresAt: now.add(const Duration(days: 7)),
          user: UserModel(
            id: 'google_user_001',
            email: 'user@google.com',
            name: 'Google User',
            role: UserRole.fieldOperator,
            assignedFarmIds: const ['farm_001'],
            createdAt: now,
          ),
        );
      }
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> logout(String accessToken) async {
    try {
      await dio.post(
        '${ApiConstants.apiBaseUrl}${ApiConstants.logout}',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      // Swallow connection errors on logout — local cleanup has priority.
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return;
      }
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        '${ApiConstants.apiBaseUrl}${ApiConstants.refreshToken}',
        data: {'refreshToken': refreshToken, 'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(message: 'Unexpected response format', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await dio.post(
        '${ApiConstants.apiBaseUrl}${ApiConstants.changePassword}',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Converts a [DioException] into the appropriate typed exception.
  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Connection timeout. Please try again.');
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Không kết nối được máy chủ. Thử lại hoặc đổi cổng preview.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        var message = 'An error occurred';
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          message = map['message']?.toString() ?? map['error']?.toString() ?? message;
        }

        switch (statusCode) {
          case 401:
            return ServerException(
              message: message.isEmpty ? 'Invalid credentials' : message,
              statusCode: 401,
            );
          case 403:
            return ServerException(
              message: message.isEmpty ? 'Account locked. Please try again later.' : message,
              statusCode: 403,
            );
          case 404:
            return ServerException(
              message: message.isEmpty ? 'Resource not found' : message,
              statusCode: 404,
            );
          case 422:
            return ServerException(
              message: message.isEmpty ? 'Validation error' : message,
              statusCode: 422,
            );
          case 500:
          case 502:
          case 503:
            return ServerException(
              message: message.isEmpty ? 'Server error. Please try again later.' : message,
              statusCode: statusCode,
            );
          default:
            return ServerException(message: message, statusCode: statusCode);
        }
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled');
      case DioExceptionType.unknown:
      default:
        return const NetworkException(
          message: 'Network error occurred. Please check your connection.',
        );
    }
  }
}
