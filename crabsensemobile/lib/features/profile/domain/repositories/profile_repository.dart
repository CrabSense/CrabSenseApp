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
  /// Fetch complete profile summary data
  Future<ProfileStateData> getProfileData({bool forceRefresh = false});

  /// Refresh specific section independently without blocking whole screen
  Future<ProfileStateData> refreshSection(ProfileStateData current, ProfileSection section);

  /// Switch active farm
  Future<ProfileStateData> switchFarm(ProfileStateData current, String farmName);

  /// Toggle notification setting
  Future<SettingsSummary> updateNotificationSetting(bool enabled);

  /// Toggle biometric setting
  Future<SecuritySummary> updateBiometricSetting(bool enabled);

  /// Trigger manual offline sync
  Future<SyncSummary> triggerSync();

  /// Execute user logout and clean secure session
  Future<void> logout();
}
