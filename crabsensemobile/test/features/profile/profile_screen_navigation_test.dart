import 'package:crabsensemobile/app/routes.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:crabsensemobile/features/authentication/domain/usecases/login_usecase.dart';
import 'package:crabsensemobile/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:crabsensemobile/features/authentication/domain/usecases/refresh_token_usecase.dart';
import 'package:crabsensemobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:crabsensemobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:crabsensemobile/core/providers/selected_farm_provider.dart';
import 'package:crabsensemobile/features/profile/data/models/profile_models.dart';
import 'package:crabsensemobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:crabsensemobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:crabsensemobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Every menu entry on the Account tab must open its screen. Before this test
/// all of them called a toast placeholder, so a tap looked like a no-op.
void main() {
  late _FakeAuthRepository authRepository;
  late AuthBloc authBloc;

  setUp(() {
    authRepository = _FakeAuthRepository();
    authBloc = AuthBloc(
      loginUseCase: LoginUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      refreshTokenUseCase: RefreshTokenUseCase(authRepository),
      authRepository: authRepository,
    );
  });

  tearDown(() async => authBloc.close());

  Future<GoRouter> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: RoutePaths.profile,
      routes: [
        GoRoute(
          path: RoutePaths.profile,
          builder: (_, _) => const ProfileScreen(),
        ),
        for (final entry in <(String, String)>[
          (RoutePaths.changePassword, 'change-password'),
          (RoutePaths.notificationSettings, 'notification-settings'),
          (RoutePaths.appSettings, 'app-settings'),
          (RoutePaths.securityPrivacy, 'security-privacy'),
          (RoutePaths.helpSupport, 'help-support'),
          (RoutePaths.appInfo, 'app-info'),
        ])
          GoRoute(
            path: entry.$1,
            builder: (_, _) => Scaffold(body: Text('opened-${entry.$2}')),
          ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
          profileStateProvider.overrideWith(
            (ref) => ProfileNotifier(_FakeProfileRepository()),
          ),
          selectedFarmProvider.overrideWith(
            (ref) => SelectedFarmNotifier(FlutterSecureStorage()),
          ),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  for (final (label, marker) in <(String, String)>[
    ('Đổi mật khẩu', 'change-password'),
    ('Cài đặt thông báo', 'notification-settings'),
    ('Cài đặt ứng dụng', 'app-settings'),
    ('Bảo mật & quyền riêng tư', 'security-privacy'),
    ('Trợ giúp & hỗ trợ', 'help-support'),
    ('Thông tin ứng dụng', 'app-info'),
  ]) {
    testWidgets('"$label" opens its screen', (tester) async {
      await pumpProfile(tester);
      final item = find.text(label);
      await tester.scrollUntilVisible(item, 200);
      await tester.tap(item);
      await tester.pumpAndSettle();
      expect(find.text('opened-$marker'), findsOneWidget);
    });
  }

  testWidgets('logout asks for confirmation and dispatches LogoutRequested', (
    tester,
  ) async {
    await pumpProfile(tester);

    final logoutButton = find.widgetWithText(OutlinedButton, 'Đăng xuất');
    await tester.scrollUntilVisible(logoutButton, 200);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
    expect(authRepository.logoutCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
    await tester.pumpAndSettle();
    // The event is dispatched from a post-frame callback and handled on the
    // real event loop, which widget tests only drain inside runAsync.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(authRepository.logoutCalls, 1);
    expect(authBloc.state, isA<Unauthenticated>());
  });
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<ProfileStateData> getProfileData({
    bool forceRefresh = false,
    String? farmingAreaId,
  }) async => ProfileStateData.sample;

  @override
  Future<ProfileStateData> refreshSection(
    ProfileStateData current,
    ProfileSection section,
  ) async => current;

  @override
  Future<ProfileStateData> switchFarm(
    ProfileStateData current,
    String farmName,
  ) async => current;

  @override
  Future<SettingsSummary> updateNotificationSetting(bool enabled) async =>
      SettingsSummary.sample;

  @override
  Future<SecuritySummary> updateBiometricSetting(bool enabled) async =>
      SecuritySummary.sample;

  @override
  Future<ProfileSummary> updateProfile({
    required String fullName,
    required String email,
    String? phone,
    String? employeeId,
    String? avatarUrl,
  }) async => ProfileSummary.sample;

  @override
  Future<SyncSummary> triggerSync() async => SyncSummary.sample;

  @override
  Future<void> logout() async {}
}

class _FakeAuthRepository implements AuthRepository {
  int logoutCalls = 0;

  @override
  Future<Either<Failure, void>> logout() async {
    logoutCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, User>> loginWithGoogle({String? idToken}) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, User>> refreshToken() => throw UnimplementedError();

  @override
  Future<Either<Failure, User>> loginWithBiometric() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, bool>> isAuthenticated() => throw UnimplementedError();

  @override
  Future<Either<Failure, User>> getCurrentUser() => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> setBiometricEnabled(bool enabled) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, bool>> isBiometricEnabled() =>
      throw UnimplementedError();
}
