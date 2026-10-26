import 'package:crabsensemobile/core/providers/selected_farm_provider.dart';
import 'package:crabsensemobile/features/profile/data/models/profile_models.dart';
import 'package:crabsensemobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:crabsensemobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:crabsensemobile/features/profile/presentation/screens/app_settings_screen.dart';
import 'package:crabsensemobile/features/profile/presentation/screens/help_support_screen.dart';
import 'package:crabsensemobile/features/profile/presentation/screens/legal_document_screen.dart';
import 'package:crabsensemobile/features/profile/presentation/screens/security_privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Các màn con của Tài khoản dùng chung [ProfileHubScaffold]; test này khoá lại
/// việc chúng render được trên nền sáng (chữ không còn trắng-trên-trắng) và
/// không ném exception layout.
void main() {
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => screen),
        for (final path in <String>[
          '/profile/change-password',
          '/profile/notification-settings',
          '/security',
        ])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Text('route:$path')),
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
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  final screens = <String, Widget>{
    'Cài đặt ứng dụng': const AppSettingsScreen(),
    'Bảo mật & quyền riêng tư': const SecurityPrivacyScreen(),
    'Trợ giúp & hỗ trợ': const HelpSupportScreen(),
    'Thông tin ứng dụng': const AppInfoScreen(),
    'Điều khoản dịch vụ': const LegalDocumentScreen(
      args: LegalDocumentArgs.terms,
    ),
  };

  screens.forEach((title, screen) {
    testWidgets('$title renders without layout/theme exceptions', (
      tester,
    ) async {
      await pumpScreen(tester, screen);
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
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
