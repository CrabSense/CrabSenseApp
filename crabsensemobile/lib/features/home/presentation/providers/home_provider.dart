import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/di/injection.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/models/home_models.dart';
import '../../domain/repositories/home_repository.dart';

/// Provider cho Repository — must use the same FlutterSecureStorage instance
/// as Auth (encryptedSharedPreferences) or Android cannot read the JWT.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(secureStorage: sl<FlutterSecureStorage>()),
);

/// Provider cho Trang chủ Home Command Center State
final homeStateProvider = StateNotifierProvider<HomeNotifier, AsyncValue<HomeStateData>>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repository);
});

class HomeNotifier extends StateNotifier<AsyncValue<HomeStateData>> {
  final HomeRepository _repository;

  HomeNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadData();
  }

  /// Nạp dữ liệu ban đầu hoặc nạp lại (giữ khu đang chọn nếu có).
  Future<void> loadData({bool forceRefresh = false}) async {
    final currentId = state.hasValue ? state.value!.selectedFarmId : null;

    if (state.hasValue && !forceRefresh) {
      state = AsyncValue.data(state.value!);
    } else if (!state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _repository.getHomeSummary(
        forceRefresh: forceRefresh,
        farmingAreaId: currentId,
      );
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Pull-to-refresh — giữ farm đang chọn
  Future<void> refresh() async {
    final currentId = state.hasValue ? state.value!.selectedFarmId : null;
    try {
      final data = await _repository.getHomeSummary(
        forceRefresh: true,
        farmingAreaId: currentId,
      );
      state = AsyncValue.data(data);
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

  /// Đổi khu nuôi — refetch overview/metrics/tasks theo farmId
  Future<void> switchFarm(String farmId) async {
    if (!state.hasValue) return;
    final current = state.value!;
    if (farmId == current.selectedFarmId) return;

    final farmName = current.availableFarms
        .where((f) => f.id == farmId)
        .map((f) => f.name)
        .firstOrNull;
    // Optimistic label while loading scoped data
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

    try {
      final updated = await _repository.switchFarm(farmId);
      state = AsyncValue.data(updated);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }

  /// Bỏ qua khuyến nghị AI
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
