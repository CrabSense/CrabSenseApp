import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../authentication/data/datasources/auth_local_data_source.dart';
import '../../../water_quality/data/repositories/scoped_history_service.dart';
import '../../../../core/providers/selected_farm_provider.dart';
import '../../data/repositories/boxes_repository_impl.dart';
import '../../domain/models/boxes_models.dart';
import '../../domain/repositories/boxes_repository.dart';

final boxesRepositoryProvider = Provider<BoxesRepository>(
  (ref) {
    final history = sl<ScopedHistoryService>();
    final repository = BoxesRepositoryImpl(api: sl<ApiClient>(),
      identity: () => readHistoryIdentity(sl<AuthLocalDataSource>()),
      revision: () => history.revision,
      boundUser: history.isBoundUser,
      networkAvailable: () => historyNetworkAvailable(sl<NetworkInfo>()));
    final subscription = history.invalidations.listen((_) => repository.invalidate());
    ref.onDispose(() { subscription.cancel(); repository.invalidate(); });
    return repository;
  },
);

/// Permissions snapshot applied into Boxes state (from AuthBloc via UI).
class BoxesPermissionFlags {
  final bool canCreateBox;
  final bool canEditBox;
  final bool canPerformActions;

  const BoxesPermissionFlags({
    required this.canCreateBox,
    required this.canEditBox,
    required this.canPerformActions,
  });

  static const viewer = BoxesPermissionFlags(
    canCreateBox: false,
    canEditBox: false,
    canPerformActions: false,
  );
}

final boxesStateProvider =
    StateNotifierProvider<BoxesNotifier, AsyncValue<BoxesStateData>>((ref) {
  final repository = ref.watch(boxesRepositoryProvider);
  return BoxesNotifier(repository, ref);
});

class BoxesNotifier extends StateNotifier<AsyncValue<BoxesStateData>> {
  BoxesNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _authChanges = sl<ScopedHistoryService>().invalidations.listen((_) {
      _permissions = BoxesPermissionFlags.viewer;
      _discard('Phiên đăng nhập đã thay đổi. Hãy tải lại.');
    });
    _networkChanges = sl<NetworkInfo>().onNetworkTypesChanged.listen((types) {
      if (!historyTransportAvailable(types)) {
        _discard('Không có kết nối. Hãy tải lại khi có mạng.');
      }
    }, onError: (Object _) => _discard('Chưa xác minh được kết nối.'));
    _ref.listen<SelectedFarm>(selectedFarmProvider, (prev, next) {
      if (_writingSelection || next.id == null || next.id!.isEmpty ||
          next.id == prev?.id) return;
      if (state.valueOrNull?.selectedFarmId == next.id) return;
      loadData(forceRefresh: true);
    });
    loadData();
  }

  final BoxesRepository _repository;
  final Ref _ref;
  Timer? _searchDebounce;
  StreamSubscription<int>? _authChanges;
  StreamSubscription<List<NetworkType>>? _networkChanges;
  BoxesPermissionFlags _permissions = BoxesPermissionFlags.viewer;
  var _loadGen = 0;
  bool _writingSelection = false;

  void _discard(String message) {
    ++_loadGen;
    _searchDebounce?.cancel();
    if (_repository is BoxesRepositoryImpl) {
      (_repository as BoxesRepositoryImpl).invalidate();
    }
    if (mounted) state = AsyncValue.error(StateError(message), StackTrace.current);
  }

  bool _current(int gen) => mounted && gen == _loadGen;

  void updatePermissions(BoxesPermissionFlags flags) {
    _permissions = flags;
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.copyWith(
          canCreateBox: flags.canCreateBox,
          canEditBox: flags.canEditBox,
          canPerformActions: flags.canPerformActions,
        ),
      );
    }
  }

  Future<void> loadData({bool forceRefresh = false, String? requestedArea}) async {
    final gen = ++_loadGen;
    final current = state.valueOrNull;
    _searchDebounce?.cancel();
    state = const AsyncValue.loading();
    try {
      await _ref.read(selectedFarmProvider.notifier).ready;
      if (!_current(gen)) return;
      final sharedId = requestedArea ?? _ref.read(selectedFarmProvider).id;
      final data = await _repository.getBoxesSummary(
        farmingAreaId: sharedId,
        forceRefresh: true,
        viewMode: current?.viewMode ?? _repository.savedViewMode,
        searchQuery: current?.searchQuery ?? '',
        quickFilters: current?.quickFilters ?? {BoxQuickFilter.all},
        advancedFilter: current?.advancedFilter ?? BoxFilterState.initial,
        canCreateBox: _permissions.canCreateBox,
        canEditBox: _permissions.canEditBox,
        canPerformActions: _permissions.canPerformActions,
      );
      if (!_current(gen)) return;
      // Never relabel a response with the requested (possibly revoked) area.
      if (data.selectedFarmId != null) {
        _writingSelection = true;
        late Future<void> selection;
        try {
          selection = _ref.read(selectedFarmProvider.notifier).select(
            data.selectedFarmId, name: data.selectedFarmName);
        } finally { _writingSelection = false; }
        await selection;
      }
      if (!_current(gen)) return;
      state = AsyncValue.data(data.copyWith(
        canCreateBox: _permissions.canCreateBox,
        canEditBox: _permissions.canEditBox,
        canPerformActions: _permissions.canPerformActions));
    } catch (error, stackTrace) {
      if (_current(gen)) state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() => loadData(forceRefresh: true);

  Future<void> switchFarm(String farmId) async {
    if (state.valueOrNull?.selectedFarmId == farmId) return;
    await loadData(forceRefresh: true, requestedArea: farmId);
  }

  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!state.hasValue) return;
      final current = state.value!;
      final filtered = _repository.applyLocalFilters(
        current: current,
        searchQuery: query,
      );
      state = AsyncValue.data(filtered);
    });

    // Optimistic query text for the input field
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(searchQuery: query));
    }
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    if (!state.hasValue) return;
    state = AsyncValue.data(
      _repository.applyLocalFilters(current: state.value!, searchQuery: ''),
    );
  }

  void toggleQuickFilter(BoxQuickFilter filter) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = Set<BoxQuickFilter>.from(current.quickFilters);

    if (filter == BoxQuickFilter.all) {
      next
        ..clear()
        ..add(BoxQuickFilter.all);
    } else {
      next.remove(BoxQuickFilter.all);
      if (next.contains(filter)) {
        next.remove(filter);
      } else {
        next.add(filter);
      }
      if (next.isEmpty) next.add(BoxQuickFilter.all);
    }

    state = AsyncValue.data(
      _repository.applyLocalFilters(current: current, quickFilters: next),
    );
  }

  void clearFilters() {
    if (!state.hasValue) return;
    final current = state.value!;
    state = AsyncValue.data(
      _repository.applyLocalFilters(
        current: current,
        searchQuery: '',
        quickFilters: {BoxQuickFilter.all},
        advancedFilter: BoxFilterState.initial,
      ),
    );
  }

  void applyAdvancedFilter(BoxFilterState filter) {
    if (!state.hasValue) return;
    state = AsyncValue.data(
      _repository.applyLocalFilters(
        current: state.value!,
        advancedFilter: filter,
      ),
    );
  }

  Future<void> setViewMode(BoxesViewMode mode) async {
    if (!state.hasValue) return;
    await _repository.saveViewMode(mode);
    if (mounted && state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(viewMode: mode));
    }
  }

  /// Đổi hướng đánh số hộp trên lưới (giữ trong phiên, như chế độ xem).
  Future<void> setBoxLayoutOrder(BoxLayoutOrder order) async {
    if (!state.hasValue) return;
    await _repository.saveBoxLayoutOrder(order);
    if (mounted && state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(boxLayoutOrder: order));
    }
  }

  void selectBox(String? boxId) {
    if (!state.hasValue) return;
    if (boxId == null) {
      state = AsyncValue.data(state.value!.copyWith(clearSelectedBox: true));
    } else {
      state = AsyncValue.data(state.value!.copyWith(selectedBoxId: boxId));
    }
  }

  int previewFilterCount(BoxFilterState filter) {
    if (!state.hasValue) return 0;
    return _repository
        .applyLocalFilters(current: state.value!, advancedFilter: filter)
        .visibleBoxes
        .length;
  }

  Future<List<({String id, String name})>> fetchRows() {
    final farmId = state.hasValue ? state.value!.selectedFarmId : null;
    return _repository.fetchRows(farmId);
  }

  Future<List<FarmRowOption>> fetchRowDetails() {
    final farmId = state.hasValue ? state.value!.selectedFarmId : null;
    return _repository.fetchRowDetails(farmId);
  }

  Future<void> _applyMutation(Future<BoxesStateData> Function() action) async {
    final gen = ++_loadGen;
    state = const AsyncValue.loading();
    try {
      final updated = await action();
      if (!_current(gen)) return;
      state = AsyncValue.data(updated.copyWith(
        canCreateBox: _permissions.canCreateBox,
        canEditBox: _permissions.canEditBox,
        canPerformActions: _permissions.canPerformActions,
      ));
    } catch (error, stackTrace) {
      if (_current(gen)) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> createArea({required String name, String? description}) =>
      _applyMutation(() => _repository.createArea(name: name, description: description));

  Future<void> updateArea({
    required String id,
    required String name,
    String? description,
    bool isActive = true,
  }) =>
      _applyMutation(
        () => _repository.updateArea(
          id: id,
          name: name,
          description: description,
          isActive: isActive,
        ),
      );

  Future<void> deleteArea(String id, {bool cascade = false}) =>
      _applyMutation(() => _repository.deleteArea(id, cascade: cascade));

  Future<void> createRow({
    required String farmingAreaId,
    required String name,
    required int capacity,
  }) =>
      _applyMutation(
        () => _repository.createRow(
          farmingAreaId: farmingAreaId,
          name: name,
          capacity: capacity,
        ),
      );

  Future<void> updateRow({
    required String id,
    required String name,
    required int capacity,
    bool isActive = true,
  }) =>
      _applyMutation(
        () => _repository.updateRow(
          id: id,
          name: name,
          capacity: capacity,
          isActive: isActive,
        ),
      );

  Future<void> deleteRow(String id) =>
      _applyMutation(() => _repository.deleteRow(id));

  Future<void> updateBox({
    required String id,
    required String code,
    String? status,
    required bool isOccupied,
  }) =>
      _applyMutation(
        () => _repository.updateBox(
          id: id,
          code: code,
          status: status,
          isOccupied: isOccupied,
        ),
      );

  Future<void> deleteBox(String id) =>
      _applyMutation(() => _repository.deleteBox(id));

  Future<void> createBox({required String farmingRowId, String? code}) =>
      _applyMutation(
        () => _repository.createBox(farmingRowId: farmingRowId, code: code),
      );

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _authChanges?.cancel();
    _networkChanges?.cancel();
    ++_loadGen;
    super.dispose();
  }
}
