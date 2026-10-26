import '../../data/models/profile_models.dart';

/// Profile Section Identifier Enum for Section-Level Error & Refresh
enum ProfileSection {
  header,
  accountInfo,
  farmManagement,
  deviceIot,
  aiCenter,
  reports,
  offlineSync,
  settings,
  security,
  helpSupport,
  appInfo,
}

abstract class ProfileRepository {
  /// Fetch complete profile summary data.
  ///
  /// [farmingAreaId] scopes the box/device counters to the farm currently
  /// pinned in `selectedFarmProvider` so the tab matches Boxes/Home.
  Future<ProfileStateData> getProfileData({
    bool forceRefresh = false,
    String? farmingAreaId,
  });

  /// Refresh specific section independently without blocking whole screen
  Future<ProfileStateData> refreshSection(
    ProfileStateData current,
    ProfileSection section,
  );

  /// Switch active farm
  Future<ProfileStateData> switchFarm(
    ProfileStateData current,
    String farmName,
  );

  /// Toggle notification setting
  Future<SettingsSummary> updateNotificationSetting(bool enabled);

  /// Toggle biometric setting
  Future<SecuritySummary> updateBiometricSetting(bool enabled);

  /// Update profile fields (PUT /auth/me)
  Future<ProfileSummary> updateProfile({
    required String fullName,
    required String email,
    String? phone,
    String? employeeId,
    String? avatarUrl,
  });

  /// Trigger manual offline sync
  Future<SyncSummary> triggerSync();

  /// Execute user logout and clean secure session
  Future<void> logout();
}
