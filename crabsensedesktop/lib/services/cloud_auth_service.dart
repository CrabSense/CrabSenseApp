import '../config/app_env.dart';
import '../models/auth_models.dart';
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
  CloudAuthService({CloudApiClient? client})
      : _api = client ?? CloudApiClient();

  final CloudApiClient _api;

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
