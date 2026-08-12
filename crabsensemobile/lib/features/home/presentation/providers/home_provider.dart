import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/providers/selected_farm_provider.dart';
import '../../../notifications/presentation/providers/unread_notifications_provider.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/models/home_models.dart';
import '../../domain/repositories/home_repository.dart';

/// Provider cho Repository — must use the same FlutterSecureStorage instance
/// as Auth (encryptedSharedPreferences) or Android cannot read the JWT.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(secureStorage: sl<FlutterSecureStorage>()),
);

/// Provider cho Trang chủ Home Command Center State
final homeStateProvider =
    StateNotifierProvider<HomeNotifier, AsyncValue<HomeStateData>>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repository, ref);
});

class HomeNotifier extends StateNotifier<AsyncValue<HomeStateData>> {
  HomeNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _ref.listen<SelectedFarm>(selectedFarmProvider, (prev, next) {
      if (next.id == null || next.id!.isEmpty) return;
      if (!state.hasValue) return;
      if (state.value!.selectedFarmId == next.id) return;
      switchFarm(next.id!);
    });
    loadData();
  }

  final HomeRepository _repository;
  final Ref _ref;

  /// Nạp dữ liệu — ưu tiên trại đang điều hành global.
  Future<void> loadData({bool forceRefresh = false}) async {
    await _ref.read(selectedFarmProvider.notifier).ready;
    final sharedId = _ref.read(selectedFarmProvider).id;
    final currentId = state.hasValue ? state.value!.selectedFarmId : null;
    final farmingAreaId = sharedId ?? currentId;

    if (state.hasValue && !forceRefresh) {
      state = AsyncValue.data(state.value!);
    } else if (!state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _repository.getHomeSummary(
        forceRefresh: forceRefresh,
        farmingAreaId: farmingAreaId,
      );
      state = AsyncValue.data(data);
      await _ref.read(selectedFarmProvider.notifier).select(
            data.selectedFarmId,
            name: data.selectedFarmName,
          );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Pull-to-refresh — giữ farm đang chọn
  Future<void> refresh() async {
    await _ref.read(selectedFarmProvider.notifier).ready;
    final sharedId = _ref.read(selectedFarmProvider).id;
    final currentId = state.hasValue ? state.value!.selectedFarmId : null;
    final farmingAreaId = sharedId ?? currentId;
    _ref.invalidate(unreadNotificationsCountProvider);
    try {
      final data = await _repository.getHomeSummary(
        forceRefresh: true,
        farmingAreaId: farmingAreaId,
      );
      state = AsyncValue.data(data);
      await _ref.read(selectedFarmProvider.notifier).select(
            data.selectedFarmId,
            name: data.selectedFarmName,
          );
    } catch (error, stackTrace) {
      if (state.hasValue) {
        final oldData = state.value!;
        state = AsyncValue.data(HomeStateData(
          operatorName: oldData.operatorName,
          selectedFarmId: oldData.selectedFarmId,
          selectedFarmName: oldData.selectedFarmName,
          availableFarms: oldData.availableFarms,
          isOnline: false,
          unreadNotificationsCount: oldData.unreadNotificationsCount,
          farmSummary: oldData.farmSummary,
          healthScore: oldData.healthScore,
          aiRecommendation: oldData.aiRecommendation,
          topAlerts: oldData.topAlerts,
          waterMetrics: oldData.waterMetrics,
          todayTasks: oldData.todayTasks,
          deviceSummary: oldData.deviceSummary,
          recentActivities: oldData.recentActivities,
          isOfflineCached: true,
          lastSyncedAt: oldData.lastSyncedAt,
        ));
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Đổi khu nuôi — cập nhật global + refetch
  Future<void> switchFarm(String farmId) async {
    if (!state.hasValue) return;
    final current = state.value!;
    if (farmId == current.selectedFarmId) return;

    final farmName = current.availableFarms
        .where((f) => f.id == farmId)
        .map((f) => f.name)
        .firstOrNull;

    // Cập nhật local trước rồi mới broadcast global — tránh listen gọi lại.
    state = AsyncValue.data(HomeStateData(
      operatorName: current.operatorName,
      selectedFarmId: farmId,
      selectedFarmName: farmName ?? current.selectedFarmName,
      availableFarms: current.availableFarms,
      isOnline: current.isOnline,
      unreadNotificationsCount: current.unreadNotificationsCount,
      farmSummary: current.farmSummary,
      healthScore: current.healthScore,
      aiRecommendation: current.aiRecommendation,
      topAlerts: current.topAlerts,
      waterMetrics: current.waterMetrics,
      todayTasks: current.todayTasks,
      deviceSummary: current.deviceSummary,
      recentActivities: current.recentActivities,
      isOfflineCached: current.isOfflineCached,
      lastSyncedAt: current.lastSyncedAt,
    ));

    await _ref.read(selectedFarmProvider.notifier).select(
          farmId,
          name: farmName,
        );

    try {
      final updated = await _repository.switchFarm(farmId);
      state = AsyncValue.data(updated);
      await _ref.read(selectedFarmProvider.notifier).select(
            updated.selectedFarmId,
            name: updated.selectedFarmName,
          );
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }

  Future<void> dismissRecommendation(String id) async {
    if (!state.hasValue) return;
    final current = state.value!;
    try {
      await _repository.dismissRecommendation(id);
      state = AsyncValue.data(HomeStateData(
        operatorName: current.operatorName,
        selectedFarmId: current.selectedFarmId,
        selectedFarmName: current.selectedFarmName,
        availableFarms: current.availableFarms,
        isOnline: current.isOnline,
        unreadNotificationsCount: current.unreadNotificationsCount,
        farmSummary: current.farmSummary,
        healthScore: current.healthScore,
        aiRecommendation: AiRecommendation.empty,
        topAlerts: current.topAlerts,
        waterMetrics: current.waterMetrics,
        todayTasks: current.todayTasks,
        deviceSummary: current.deviceSummary,
        recentActivities: current.recentActivities,
        isOfflineCached: current.isOfflineCached,
        lastSyncedAt: current.lastSyncedAt,
      ));
    } catch (_) {}
  }
}
