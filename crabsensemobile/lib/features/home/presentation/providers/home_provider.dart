import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/selected_farm_provider.dart';
import '../../../notifications/presentation/providers/unread_notifications_provider.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/models/home_models.dart';
import '../../domain/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(api: sl<ApiClient>()),
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
      _reloadQuiet(next.id!);
    });
    loadData();
  }

  final HomeRepository _repository;
  final Ref _ref;
  int _generation = 0;
  bool _current(int generation) => mounted && generation == _generation;

  /// Refetch khi tab khác đổi khu — không ghi selectedFarmProvider.
  Future<void> _reloadQuiet(String farmId) async {
    if (!state.hasValue) return;
    final generation = ++_generation;
    try {
      final data = await _repository.getHomeSummary(
        forceRefresh: true,
        farmingAreaId: farmId,
      );
      if (_current(generation) && data.selectedFarmId == farmId &&
          _ref.read(selectedFarmProvider).id == farmId) {
        state = AsyncValue.data(data);
      }
    } catch (_) {}
  }

  /// Nạp dữ liệu — ưu tiên trại đang điều hành global.
  Future<void> loadData({bool forceRefresh = false}) async {
    final generation = ++_generation;
    await _ref.read(selectedFarmProvider.notifier).ready;
    if (!_current(generation)) return;
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
      if (!_current(generation)) return;
      if (farmingAreaId != null && data.selectedFarmId != farmingAreaId) return;
      final keepId = farmingAreaId ?? data.selectedFarmId;
      state = AsyncValue.data(data);
      await _ref.read(selectedFarmProvider.notifier).syncFromLoaded(
            id: keepId,
            name: data.selectedFarmName,
          );
    } catch (error, stackTrace) {
      if (_current(generation)) state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Pull-to-refresh — giữ farm đang chọn
  Future<void> refresh() async {
    final generation = ++_generation;
    await _ref.read(selectedFarmProvider.notifier).ready;
    if (!_current(generation)) return;
    final sharedId = _ref.read(selectedFarmProvider).id;
    final currentId = state.hasValue ? state.value!.selectedFarmId : null;
    final farmingAreaId = sharedId ?? currentId;
    _ref.invalidate(unreadNotificationsCountProvider);
    try {
      final data = await _repository.getHomeSummary(
        forceRefresh: true,
        farmingAreaId: farmingAreaId,
      );
      if (!_current(generation)) return;
      if (farmingAreaId != null && data.selectedFarmId != farmingAreaId) return;
      state = AsyncValue.data(data);
      await _ref.read(selectedFarmProvider.notifier).syncFromLoaded(
            id: farmingAreaId ?? data.selectedFarmId,
            name: data.selectedFarmName,
          );
    } catch (error, stackTrace) {
      if (!_current(generation)) return;
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
          waterMetrics: const [],
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
    final generation = ++_generation;

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
      waterMetrics: const [],
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
      if (!_current(generation)) return;
      final updated = await _repository.switchFarm(farmId);
      if (!_current(generation)) return;
      if (updated.selectedFarmId == farmId) {
        state = AsyncValue.data(updated);
      }
      // Selection was already broadcast before the request; never repin it from a late response.
    } catch (_) {
      // Giữ khu vừa chọn — không kéo về khu trước.
    }
  }

  Future<void> dismissRecommendation(String id) async {
    if (!state.hasValue) return;
    final current = state.value!;
    final generation = _generation;
    try {
      await _repository.dismissRecommendation(id);
      if (!_current(generation) || !identical(state.value, current)) return;
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
