import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/di/injection.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

/// Provider for Profile Repository — same secure-storage options as Auth
/// so JWT written at login is readable on Android.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(secureStorage: sl<FlutterSecureStorage>()),
);

/// Provider for Profile Screen Master State
final profileStateProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileStateData>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileStateData>> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadData();
  }

  /// Initial load or reload of profile data
  Future<void> loadData({bool forceRefresh = false}) async {
    if (state.hasValue && !forceRefresh) {
      state = AsyncValue.data(state.value!);
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _repository.getProfileData(forceRefresh: forceRefresh);
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    try {
      final data = await _repository.getProfileData(forceRefresh: true);
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (state.hasValue) {
        final current = state.value!;
        final offline = current.copyWith(
          isOnline: false,
          isOfflineCached: true,
        );
        state = AsyncValue.data(offline);
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Switch current farm
  Future<void> switchFarm(String farmName) async {
    if (!state.hasValue) return;
    final current = state.value!;
    try {
      final updated = await _repository.switchFarm(current, farmName);
      state = AsyncValue.data(updated);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }

  /// Toggle notification
  Future<void> toggleNotification(bool enabled) async {
    if (!state.hasValue) return;
    final current = state.value!;
    final updatedSettings = current.settings.copyWith(notificationsEnabled: enabled);
    state = AsyncValue.data(current.copyWith(settings: updatedSettings));
  }

  /// Toggle biometric
  Future<void> toggleBiometric(bool enabled) async {
    if (!state.hasValue) return;
    final current = state.value!;
    final updatedSecurity = current.security.copyWith(biometricEnabled: enabled);
    state = AsyncValue.data(current.copyWith(security: updatedSecurity));
  }

  /// Trigger sync
  Future<void> triggerSync() async {
    if (!state.hasValue) return;
    final current = state.value!;
    try {
      final syncResult = await _repository.triggerSync();
      state = AsyncValue.data(current.copyWith(
        syncSummary: syncResult,
        lastSyncedAt: syncResult.lastSyncedAt,
        isOfflineCached: false,
        isOnline: true,
      ));
    } catch (_) {}
  }

  /// Reload specific section on section failure
  Future<void> reloadSection(ProfileSection section) async {
    if (!state.hasValue) return;
    final current = state.value!;
    try {
      final updated = await _repository.refreshSection(current, section);
      state = AsyncValue.data(updated);
    } catch (e) {
      state = AsyncValue.data(current.copyWith(sectionError: 'Lỗi tải phần này'));
    }
  }

  /// User Logout
  Future<void> logout() async {
    await _repository.logout();
  }
}
