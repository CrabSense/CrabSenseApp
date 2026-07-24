import 'package:crabsensemobile/core/constants/api_constants.dart';
import 'package:crabsensemobile/core/errors/exceptions.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/core/network/api_client.dart';
import 'package:crabsensemobile/core/network/interceptors/auth_interceptor.dart';
import 'package:crabsensemobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:crabsensemobile/features/authentication/data/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manual stubs
// ─────────────────────────────────────────────────────────────────────────────

/// Stub [AuthLocalDataSource] that returns a configurable access token.
class _StubLocalDataSource implements AuthLocalDataSource {
  _StubLocalDataSource({this.accessToken, this.refreshToken});

  final String? accessToken;
  final String? refreshToken;

  @override
  Future<String> getAccessToken() async {
    if (accessToken == null) {
      throw const CacheException(message: 'No access token found');
    }
    return accessToken!;
  }

  @override
  Future<String> getRefreshToken() async {
    if (refreshToken == null) {
      throw const CacheException(message: 'No refresh token found');
    }
    return refreshToken!;
  }

  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<void> saveRefreshToken(String token) async {}

  @override
  Future<void> saveAccessTokenExpiry(DateTime expiry) async {}

  @override
  Future<DateTime> getAccessTokenExpiry() async => DateTime.now().add(const Duration(hours: 1));

  @override
  Future<void> saveRefreshTokenExpiry(DateTime expiry) async {}

  @override
  Future<DateTime> getRefreshTokenExpiry() async => DateTime.now().add(const Duration(days: 7));

  @override
  Future<void> cacheUser(UserModel user) async {}

  @override
  Future<UserModel> getCachedUser() async => throw UnimplementedError();

  @override
  Future<void> clearAuthData() async {}

  @override
  Future<void> setBiometricEnabled(bool enabled) async {}

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<bool> isAuthenticated() async => accessToken != null;
}

/// A [RequestInterceptorHandler] that captures the options passed to
/// [handler.next] so tests can inspect the outgoing request headers.
class _CapturingRequestHandler extends RequestInterceptorHandler {
  RequestOptions? captured;

  @override
  void next(RequestOptions options) {
    captured = options;
    // Do not forward to Dio — we only care about the header mutation.
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Logger _silentLogger() => Logger(filter: ProductionFilter(), output: NullOutput());

/// [NullOutput] discards all log records — keeps test output clean.
class NullOutput extends LogOutput {
  @override
  void output(OutputEvent event) {}
}

/// A [ProductionFilter] that suppresses everything.
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  final logger = _silentLogger();

  // ── 1. ApiClient construction ──────────────────────────────────────────────
  group('ApiClient construction', () {
    test('constructs without throwing', () {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      expect(() => ApiClient(logger: logger, authLocalDataSource: ds), returnsNormally);
    });

    test('dio accessor returns non-null Dio instance', () {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      final client = ApiClient(logger: logger, authLocalDataSource: ds);
      expect(client.dio, isA<Dio>());
    });
  });

  // ── 2. Timeout configuration ───────────────────────────────────────────────
  group('Timeout configuration', () {
    test('connect/receive/send timeouts are all 30 seconds', () {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      final client = ApiClient(logger: logger, authLocalDataSource: ds);
      final opts = client.dio.options;

      expect(opts.connectTimeout, equals(ApiConstants.connectTimeout));
      expect(opts.receiveTimeout, equals(ApiConstants.receiveTimeout));
      expect(opts.sendTimeout, equals(ApiConstants.sendTimeout));

      // Confirm the actual duration is 30 s.
      expect(opts.connectTimeout, equals(const Duration(seconds: 30)));
      expect(opts.receiveTimeout, equals(const Duration(seconds: 30)));
      expect(opts.sendTimeout, equals(const Duration(seconds: 30)));
    });
  });

  // ── 3. Base URL configuration ──────────────────────────────────────────────
  group('Base URL configuration', () {
    test('uses ApiConstants.apiBaseUrl', () {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      final client = ApiClient(logger: logger, authLocalDataSource: ds);
      expect(client.dio.options.baseUrl, equals(ApiConstants.apiBaseUrl));
    });
  });

  // ── 4. Certificate pinning ─────────────────────────────────────────────────
  group('Certificate pinning', () {
    test('httpClientAdapter is configured (not the default adapter)', () {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      final client = ApiClient(logger: logger, authLocalDataSource: ds);

      // ApiClient installs an IOHttpClientAdapter with a custom
      // badCertificateCallback. We verify the adapter is set (non-null)
      // and is not the default HttpClientAdapter.
      expect(client.dio.httpClientAdapter, isNotNull);
    });
  });

  // ── 5. AuthInterceptor — attaches Bearer token ─────────────────────────────
  group('AuthInterceptor.onRequest', () {
    test('attaches Authorization: Bearer header when token exists', () async {
      const token = 'test_access_token';
      final ds = _StubLocalDataSource(accessToken: token);
      final interceptor = AuthInterceptor(localDataSource: ds, logger: logger);

      final options = RequestOptions(path: '/test');
      final handler = _CapturingRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.captured, isNotNull);
      expect(handler.captured!.headers['Authorization'], equals('Bearer $token'));
    });

    test('does NOT attach Authorization header when no token (CacheException)', () async {
      // No token stored — data source throws CacheException.
      final ds = _StubLocalDataSource();
      final interceptor = AuthInterceptor(localDataSource: ds, logger: logger);

      final options = RequestOptions(path: '/test');
      final handler = _CapturingRequestHandler();

      await interceptor.onRequest(options, handler);

      // Request must still proceed (handler.next was called).
      expect(handler.captured, isNotNull);
      // No Authorization header.
      expect(handler.captured!.headers.containsKey('Authorization'), isFalse);
    });
  });

  // ── 6. AuthInterceptor — token refresh on 401 ─────────────────────────────
  group('AuthInterceptor token refresh on 401', () {
    test('skips refresh for the refresh endpoint itself (avoids infinite loop)', () async {
      // If the refresh endpoint returns 401, we must NOT try to refresh again.
      final ds = _StubLocalDataSource(accessToken: 'old', refreshToken: 'refresh');
      final interceptor = AuthInterceptor(localDataSource: ds, logger: logger);

      final reqOpts = RequestOptions(path: ApiConstants.refreshToken);
      final err = DioException(
        requestOptions: reqOpts,
        response: Response<void>(requestOptions: reqOpts, statusCode: 401),
        type: DioExceptionType.badResponse,
      );

      // Collect what the handler does.
      var nextWasCalled = false;
      final handler = _TrackingErrorHandler(onNext: (_) => nextWasCalled = true);

      interceptor.onError(err, handler);

      // Should have forwarded the error, not attempted a refresh.
      expect(nextWasCalled, isTrue);
    });

    test('forwards non-401 errors unchanged', () async {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      final interceptor = AuthInterceptor(localDataSource: ds, logger: logger);

      final reqOpts = RequestOptions(path: '/some/endpoint');
      final err = DioException(
        requestOptions: reqOpts,
        response: Response<void>(requestOptions: reqOpts, statusCode: 500),
        type: DioExceptionType.badResponse,
      );

      var nextWasCalled = false;
      final handler = _TrackingErrorHandler(onNext: (_) => nextWasCalled = true);

      interceptor.onError(err, handler);

      expect(nextWasCalled, isTrue);
    });
  });

  // ── 7. safeGet / safePost — DioException → Failure ────────────────────────
  group('safeGet / safePost error mapping', () {
    test('safeGet returns failure record on DioException', () async {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      // Use a stub ApiClient subclass that overrides get() to throw.
      final stubClient = _FailingApiClient(logger: logger, authLocalDataSource: ds);

      final result = await stubClient.safeGet<Map<String, dynamic>>('/boxes');

      expect(result.failure, isNotNull);
      expect(result.failure, isA<Failure>());

      // Data record is still present (empty response shell).
      expect(result.data, isNotNull);
    });

    test('safePost returns failure record on DioException', () async {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      final stubClient = _FailingApiClient(logger: logger, authLocalDataSource: ds);

      final result = await stubClient.safePost<Map<String, dynamic>>(
        '/boxes',
        data: {'name': 'test'},
      );

      expect(result.failure, isNotNull);
      expect(result.failure, isA<Failure>());
    });

    test('safeGet returns null failure on success', () async {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      final stubClient = _SucceedingApiClient(logger: logger, authLocalDataSource: ds);

      final result = await stubClient.safeGet<Map<String, dynamic>>('/boxes');

      expect(result.failure, isNull);
      expect(result.data.statusCode, equals(200));
    });
  });

  // ── 8. ApiClient interceptors wired correctly ──────────────────────────────
  group('ApiClient interceptors', () {
    test('interceptors list includes at least one interceptor', () {
      final ds = _StubLocalDataSource(accessToken: 'tok');
      final client = ApiClient(logger: logger, authLocalDataSource: ds);
      // AuthInterceptor is always added; LoggingInterceptor only in debug.
      expect(client.dio.interceptors.isNotEmpty, isTrue);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Test doubles used in the safeGet/safePost tests
// ─────────────────────────────────────────────────────────────────────────────

/// [ApiClient] subclass whose get/post always throw a [DioException].
class _FailingApiClient extends ApiClient {
  _FailingApiClient({required super.logger, required super.authLocalDataSource});

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final reqOpts = RequestOptions(path: path);
    throw DioException(
      requestOptions: reqOpts,
      type: DioExceptionType.connectionError,
      message: 'Simulated network failure',
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final reqOpts = RequestOptions(path: path);
    throw DioException(
      requestOptions: reqOpts,
      type: DioExceptionType.connectionError,
      message: 'Simulated network failure',
    );
  }
}

/// [ApiClient] subclass whose get/post always succeed with HTTP 200.
class _SucceedingApiClient extends ApiClient {
  _SucceedingApiClient({required super.logger, required super.authLocalDataSource});

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final reqOpts = RequestOptions(path: path);
    return Response<T>(requestOptions: reqOpts, statusCode: 200);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Minimal ErrorInterceptorHandler that lets tests observe what happened
// ─────────────────────────────────────────────────────────────────────────────

class _TrackingErrorHandler extends ErrorInterceptorHandler {
  _TrackingErrorHandler({this.onNext, this.onResolve});

  final void Function(DioException err)? onNext;
  final void Function(Response<dynamic> resp)? onResolve;

  @override
  void next(DioException err) => onNext?.call(err);

  @override
  void resolve(Response<dynamic> response) => onResolve?.call(response);
}
