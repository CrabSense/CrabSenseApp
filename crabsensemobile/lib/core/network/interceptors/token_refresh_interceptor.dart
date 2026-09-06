import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../features/authentication/data/datasources/auth_local_data_source.dart';
import '../../../features/authentication/presentation/bloc/auth_bloc.dart' show AuthBloc;
import '../../../features/authentication/presentation/bloc/bloc.dart' show AuthBloc;
import '../../constants/api_constants.dart';
import '../../errors/exceptions.dart';
import 'auth_interceptor.dart' show AuthInterceptor;

/// Dio interceptor that handles transparent JWT token refresh on 401.
///
/// When a request receives a 401 Unauthorized response this interceptor:
///   1. Acquires a soft lock so only **one** refresh runs at a time.
///   2. Calls [ApiConstants.refreshToken] with the stored refresh token.
///   3. Persists the new access (and optionally refresh) token via
///      [AuthLocalDataSource].
///   4. Retries **all queued** 401 requests with the new token.
///   5. On refresh failure it rejects every queued request and propagates
///      the error to the caller (typically causing the [AuthBloc] / router
///      guard to redirect the user to the login screen).
///
/// This interceptor is intentionally separated from [AuthInterceptor] so
/// that each class has a single responsibility:
///   - [AuthInterceptor] — attaches the `Authorization` header.
///   - [TokenRefreshInterceptor] — handles 401 recovery.
///
/// Add it **after** [AuthInterceptor] in the Dio interceptor list so that
/// the auth header is already present when the refresh request is issued.
///
/// Requirements: 1.3, 1.10, 23.4
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required AuthLocalDataSource localDataSource,
    required Dio dio,
    required Logger logger,
  })  : _localDataSource = localDataSource,
        _dio = dio,
        _logger = logger;

  final AuthLocalDataSource _localDataSource;

  /// Shared [Dio] instance — used to issue the refresh request **outside**
  /// of the normal interceptor chain (avoids triggering this interceptor
  /// recursively).
  final Dio _dio;

  final Logger _logger;

  /// Prevents multiple simultaneous token-refresh calls.
  bool _isRefreshing = false;

  /// Requests that arrived while a refresh was already in flight.
  /// Each [Completer] is resolved with the new access token on success, or
  /// completed with an error on refresh failure.
  final List<Completer<String>> _pendingQueue = [];

  // ─────────────────────────────────────────────────────────────────────────
  // Interceptor override
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final request = err.requestOptions;

    // Only handle 401 responses. Pass through anything else, and also
    // pass through 401s on the refresh endpoint itself to avoid an
    // infinite loop.
    final isUnauthorized = response?.statusCode == 401;
    final isRefreshEndpoint = request.path.contains(ApiConstants.refreshToken);

    final authHeader =
        request.headers['Authorization'] ?? request.headers['authorization'];
    final hasBearer = authHeader?.toString().startsWith('Bearer ') ?? false;

    // No JWT was sent — refreshing cannot help (and CacheException here
    // used to surface as a generic "Không thể thực hiện" on Boxes).
    if (!isUnauthorized || isRefreshEndpoint || !hasBearer) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      // Queue this request — it will be retried once the in-flight
      // refresh completes.
      final completer = Completer<String>();
      _pendingQueue.add(completer);

      try {
        final newToken = await completer.future;
        final retried = await _retryWithToken(request, newToken);
        handler.resolve(retried);
      } on DioException catch (queuedErr) {
        handler.next(queuedErr);
      }
      return;
    }

    // ── Kick off a fresh token refresh ────────────────────────────────────
    _isRefreshing = true;

    try {
      final newAccessToken = await _doRefresh();

      // Resolve queued requests.
      for (final c in _pendingQueue) {
        c.complete(newAccessToken);
      }
      _pendingQueue.clear();

      // Retry the original failing request.
      final retried = await _retryWithToken(request, newAccessToken);
      handler.resolve(retried);
    } on DioException catch (refreshErr) {
      // Refresh failed — reject every queued request.
      for (final c in _pendingQueue) {
        c.completeError(refreshErr);
      }
      _pendingQueue.clear();

      // Propagate so the caller (e.g. AuthBloc) can react.
      handler.next(refreshErr);
    } finally {
      _isRefreshing = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Calls the refresh endpoint and persists the new tokens.
  ///
  /// Throws a [DioException] when:
  ///   - No refresh token is stored (user must log in again).
  ///   - The server rejects the refresh token (expired / revoked).
  ///   - Network error occurs during the refresh request.
  Future<String> _doRefresh() async {
    try {
      final refreshToken = await _localDataSource.getRefreshToken();

      if (refreshToken.startsWith('mock_')) {
        await _localDataSource.clearAuthData();
        throw DioException(
          requestOptions: RequestOptions(path: ApiConstants.refreshToken),
          message: 'Mock session cleared — please log in again.',
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.refreshToken),
            statusCode: 401,
          ),
        );
      }

      // Issue the refresh request directly on the shared Dio instance,
      // bypassing the interceptor list to avoid triggering ourselves
      // or re-attaching a (possibly stale) Authorization header.
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(
          // Signal to AuthInterceptor that this request should skip
          // automatic header attachment.
          extra: const {'skipAuthInterceptor': true},
        ),
      );

      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: RequestOptions(path: ApiConstants.refreshToken),
          message: 'Empty body in refresh response',
        );
      }

      // BE wraps payloads: { success, data: { accessToken, refreshToken, expiresAt, user } }
      final payload = (data['data'] is Map)
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;

      final newAccess =
          payload['accessToken']?.toString() ?? payload['access_token']?.toString();
      final newRefresh =
          payload['refreshToken']?.toString() ?? payload['refresh_token']?.toString();

      if (newAccess == null || newAccess.isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: ApiConstants.refreshToken),
          message: 'Missing accessToken in refresh response',
        );
      }

      // Persist to Keychain / Keystore — never log the value (req 23.5).
      await _localDataSource.saveAccessToken(newAccess);

      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _localDataSource.saveRefreshToken(newRefresh);
      }

      final expiresAtRaw = payload['expiresAt'] ?? payload['accessTokenExpiresAt'];
      if (expiresAtRaw != null) {
        final expiry = DateTime.tryParse(expiresAtRaw.toString());
        if (expiry != null) {
          await _localDataSource.saveAccessTokenExpiry(expiry);
        }
      } else {
        final expiresIn = payload['expiresIn'] as int?;
        if (expiresIn != null) {
          final expiry = DateTime.now().add(Duration(seconds: expiresIn));
          await _localDataSource.saveAccessTokenExpiry(expiry);
        }
      }

      _logger.d('TokenRefreshInterceptor: token refreshed successfully');
      return newAccess;
    } on CacheException catch (e) {
      // No refresh token in secure storage — session is gone.
      throw DioException(
        requestOptions: RequestOptions(path: ApiConstants.refreshToken),
        message: 'No refresh token available: ${e.message}',
      );
    }
  }

  /// Retries [original] with [newToken] in the Authorization header.
  Future<Response<dynamic>> _retryWithToken(RequestOptions original, String newToken) {
    final updated = original.copyWith(
      headers: {...original.headers, 'Authorization': 'Bearer $newToken'},
    );
    return _dio.fetch<dynamic>(updated);
  }
}
