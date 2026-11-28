import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../authentication/data/datasources/auth_local_data_source.dart';
import '../../../water_quality/data/repositories/scoped_history_service.dart';
import '../../../../core/providers/selected_farm_provider.dart';
import '../../../notifications/presentation/providers/unread_notifications_provider.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/models/home_models.dart';
import '../../domain/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) {
    final session = sl<ScopedHistoryService>();
    final repository = HomeRepositoryImpl(api: sl<ApiClient>(),
      identity: () => readHistoryIdentity(sl<AuthLocalDataSource>()),
      revision: () => session.revision,
      boundUser: session.isBoundUser,
      networkAvailable: () => historyNetworkAvailable(sl<NetworkInfo>()));
    ref.onDispose(repository.invalidate);
    return repository;
  },
);

/// Provider cho Trang chủ Home Command Center State
final homeStateProvider =
    StateNotifierProvider<HomeNotifier, AsyncValue<HomeStateData>>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repository, ref);
});

class HomeNotifier extends StateNotifier<AsyncValue<HomeStateData>> {
  HomeNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _authChanges = sl<ScopedHistoryService>().invalidations.listen((_) {
      _discard('Phiên đăng nhập đã thay đổi. Hãy tải lại.');
    });
    _networkChanges = sl<NetworkInfo>().onNetworkTypesChanged.listen((types) {
      if (!historyTransportAvailable(types)) {
        _discard('Không có kết nối. Hãy tải lại khi có mạng.');
      }
    }, onError: (Object _) => _discard('Chưa xác minh được kết nối.'));
    _ref.listen<SelectedFarm>(selectedFarmProvider, (prev, next) {
      if (_writingSelection || next.id == prev?.id) return;
      loadData(forceRefresh: true);
    });
    loadData();
  }

  final HomeRepository _repository;
  final Ref _ref;
  StreamSubscription<int>? _authChanges;
  StreamSubscription<List<NetworkType>>? _networkChanges;
  int _generation = 0;
  bool _writingSelection = false;
  bool _current(int generation) => mounted && generation == _generation;

  void _discard(String message) {
    ++_generation;
    if (_repository is HomeRepositoryImpl) {
      _repository.invalidate();
    }
    if (mounted) state = AsyncValue.error(StateError(message), StackTrace.current);
  }

  Future<void> loadData({bool forceRefresh = false, String? requestedArea}) async {
    final generation = ++_generation;
    state = const AsyncValue.loading();
    try {
      await _ref.read(selectedFarmProvider.notifier).ready;
      if (!_current(generation)) return;
      final area = requestedArea ?? _ref.read(selectedFarmProvider).id;
      final data = await _repository.getHomeSummary(
        forceRefresh: true, farmingAreaId: area);
      if (!_current(generation)) return;
      if (data.selectedFarmId == null || !data.availableFarms.any(
          (farm) => farm.id == data.selectedFarmId)) {
        throw StateError('Khu nuôi chưa được xác minh.');
      }
      // Persist only the area actually authorized in the fresh response.
      _writingSelection = true;
      late Future<void> selection;
      try {
        selection = _ref.read(selectedFarmProvider.notifier).select(
          data.selectedFarmId, name: data.selectedFarmName);
      } finally { _writingSelection = false; }
      await selection;
      if (!_current(generation)) return;
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (_current(generation)) state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    _ref.invalidate(unreadNotificationsCountProvider);
    await loadData(forceRefresh: true);
  }

  Future<void> switchFarm(String farmId) async {
    if (state.valueOrNull?.selectedFarmId == farmId) return;
    await loadData(forceRefresh: true, requestedArea: farmId);
  }

  @override
  void dispose() {
    ++_generation;
    _authChanges?.cancel();
    _networkChanges?.cancel();
    super.dispose();
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
