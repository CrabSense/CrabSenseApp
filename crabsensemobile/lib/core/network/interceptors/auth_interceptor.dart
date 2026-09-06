import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../features/authentication/data/datasources/auth_local_data_source.dart';
import '../../errors/exceptions.dart';
import 'token_refresh_interceptor.dart' show TokenRefreshInterceptor;

/// Dio interceptor that attaches the JWT `Authorization: Bearer` header
/// to every outgoing request.
///
/// Behaviour:
///   - Reads the current access token from [AuthLocalDataSource]
///     (Keychain on iOS, Keystore on Android).
///   - Skips header attachment when no token is stored (public endpoints,
///     unauthenticated state).
///   - Skips header attachment when the request carries the
///     `extra: {'skipAuthInterceptor': true}` flag — used by the
///     [TokenRefreshInterceptor] to issue the refresh call without
///     attaching a stale token.
///
/// Token refresh on 401 is handled separately by
/// [TokenRefreshInterceptor] to keep each class focused on a single
/// responsibility.
///
/// Requirements: 1.6, 23.4 — JWT read from platform secure storage only.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required AuthLocalDataSource localDataSource,
    required Logger logger,
  })  : _localDataSource = localDataSource,
        _logger = logger;

  final AuthLocalDataSource _localDataSource;

  // Retained for future diagnostic use.
  // ignore: unused_field
  final Logger _logger;

  // ─────────────────────────────────────────────────────────────────────────
  // onRequest — attach Bearer token
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Allow the token-refresh call to bypass header attachment so it
    // never sends a stale access token on the refresh endpoint.
    final skip = options.extra['skipAuthInterceptor'] as bool? ?? false;
    if (skip) {
      handler.next(options);
      return;
    }

    try {
      final token = await _localDataSource.getAccessToken();
      if (token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } on CacheException {
      // No token stored — public endpoint or not yet authenticated.
    } catch (_) {
      // Storage glitch must not drop the request without a header retry.
    }

    handler.next(options);
  }
}
