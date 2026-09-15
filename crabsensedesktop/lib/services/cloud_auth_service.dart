import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../models/auth_models.dart';
import 'auth_session_store.dart';
import 'cloud_api_client.dart';

class CloudAuthResult {
  const CloudAuthResult._({
    required this.success,
    this.token,
    this.refreshToken,
    this.user,
    this.errorMessage,
  });

  factory CloudAuthResult.success({
    required String token,
    required AuthUser user,
    String? refreshToken,
  }) =>
      CloudAuthResult._(
        success: true,
        token: token,
        refreshToken: refreshToken,
        user: user,
      );

  factory CloudAuthResult.failure(String message) =>
      CloudAuthResult._(success: false, errorMessage: message);

  final bool success;
  final String? token;
  final String? refreshToken;
  final AuthUser? user;
  final String? errorMessage;
}

class CloudAuthService {
  CloudAuthService({CloudApiClient? client, AuthSessionStore? store})
      : _api = client ?? CloudApiClient(),
        _store = store ?? AuthSessionStore();

  final CloudApiClient _api;
  final AuthSessionStore _store;

  Future<CloudAuthResult> signIn({
    required String username,
    required String password,
  }) async {
    final userTrim = username.trim();
    if (userTrim.isEmpty) {
      return CloudAuthResult.failure('Vui lòng nhập tên đăng nhập.');
    }
    if (password.isEmpty) {
      return CloudAuthResult.failure('Vui lòng nhập mật khẩu.');
    }

    try {
      final reachable = await _api.healthCheck();
      if (!reachable) {
        return CloudAuthResult.failure(
          'Không kết nối CrabSenseBE tại ${AppEnv.cloudApiUrl}. Kiểm tra .env và API.',
        );
      }

      final login = await _api.login(username: userTrim, password: password);
      if (!login.user.isFarmOwner) {
        return CloudAuthResult.failure(
          'Desktop hiện chỉ có trang chủ trại. Role "${login.user.role}" '
          '(${login.user.displayName}) không được vào. '
          'Dùng tài khoản FarmOwner (vd. owner / Owner@123).',
        );
      }
      return CloudAuthResult.success(
        token: login.token,
        refreshToken: login.refreshToken,
        user: login.user,
      );
    } on CloudApiException catch (e) {
      return CloudAuthResult.failure(e.message);
    } catch (e) {
      return CloudAuthResult.failure('Lỗi mạng: $e');
    }
  }

  Future<AuthMePayload> fetchMe(String token) async {
    return _api.authMe(token);
  }

  bool canSwitchFarms(AuthMePayload me) =>
      me.canViewAllFarms || me.farms.length > 1;

  Future<String?> loadRememberedUsername() => _store.loadUsername();

  Future<void> persistSession(AuthSession session, {String? username}) =>
      _store.save(session, username: username);

  Future<void> persistSessionIfRemembered(AuthSession session) =>
      _store.saveIfPersisted(session);

  Future<void> clearSession({bool keepUsername = true}) {
    return keepUsername ? _store.clearTokensKeepUsername() : _store.clear();
  }

  Future<void> logoutRemote(String token) => _api.logout(token);

  /// Khôi phục phiên đã lưu. Access token hết hạn (1h) thì refresh (7 ngày).
  /// API tắt / lỗi mạng → vẫn vào bằng session cache, nhưng CHỈ khi token còn
  /// hạn: token chết mà vẫn vào thì mọi API trả 401 và app chỉ toàn lỗi kết nối.
  Future<AuthSession?> restorePersistedSession() async {
    final stored = await _store.load();
    if (stored == null) return null;

    var session = stored.session;
    try {
      final me = await _api.authMe(session.token);
      return _mergeMe(session, me, stored.username);
    } on CloudApiException catch (e) {
      if (e.statusCode != 401) {
        return _offlineFallback(session);
      }
      final refresh = session.refreshToken?.trim();
      if (refresh == null || refresh.isEmpty) {
        await _store.clearTokensKeepUsername();
        return null;
      }
      try {
        final next = await _api.refresh(refresh);
        session = session.copyWith(
          token: next.token,
          refreshToken: next.refreshToken ?? refresh,
          user: next.user ?? session.user,
        );
        final me = await _api.authMe(session.token);
        return _mergeMe(session, me, stored.username);
      } catch (_) {
        await _store.clearTokensKeepUsername();
        return null;
      }
    } catch (_) {
      return _offlineFallback(session);
    }
  }

  /// Không gọi được API (BE tắt / mất mạng). Chỉ dùng cache khi token còn hạn;
  /// token hết hạn thì trả null để AuthGate đưa về màn đăng nhập.
  Future<AuthSession?> _offlineFallback(AuthSession session) async {
    if (!tokenExpired(session.token)) return session;
    await _store.clearTokensKeepUsername();
    return null;
  }

  /// Đọc claim `exp` của JWT, không cần gọi mạng. Token hỏng / thiếu `exp`
  /// cũng coi là hết hạn — thà bắt đăng nhập lại hơn là chạy bằng token chết.
  @visibleForTesting
  static bool tokenExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is! num) return true;
      return DateTime.now().millisecondsSinceEpoch >= exp.toInt() * 1000;
    } catch (_) {
      return true;
    }
  }

  Future<AuthSession> _mergeMe(
    AuthSession session,
    AuthMePayload me,
    String? username,
  ) async {
    final farms = me.farms.isEmpty ? const [FarmSummary.unassigned] : me.farms;
    final selected = farms.any((f) => f.id == session.selectedFarm.id)
        ? farms.firstWhere((f) => f.id == session.selectedFarm.id)
        : (resolveDefaultFarm(farms, me) ?? farms.first);
    final next = AuthSession(
      token: session.token,
      refreshToken: session.refreshToken,
      user: me.user,
      farms: farms,
      selectedFarm: selected,
      isOrgAdmin: me.isOrgAdmin,
    );
    await _store.save(next, username: username);
    return next;
  }

  FarmSummary? resolveDefaultFarm(List<FarmSummary> farms, AuthMePayload me) {
    if (farms.isEmpty) return FarmSummary.unassigned;
    final candidates = [
      AppEnv.defaultFarmId,
      me.defaultFarmId,
    ];
    for (final id in candidates) {
      if (id == null) continue;
      for (final f in farms) {
        if (f.id.toLowerCase() == id.toLowerCase()) return f;
      }
    }
    return farms.first;
  }
}
