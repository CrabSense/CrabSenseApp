import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/selected_farm_provider.dart';
import '../../data/repositories/boxes_repository_impl.dart';
import '../../domain/models/boxes_models.dart';
import '../../domain/repositories/boxes_repository.dart';

final boxesRepositoryProvider = Provider<BoxesRepository>(
  (ref) => BoxesRepositoryImpl(api: sl<ApiClient>()),
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
    _ref.listen<SelectedFarm>(selectedFarmProvider, (prev, next) {
      if (next.id == null || next.id!.isEmpty) return;
      if (!state.hasValue) return;
      if (state.value!.selectedFarmId == next.id) return;
      switchFarm(next.id!);
    });
    loadData();
  }

  final BoxesRepository _repository;
  final Ref _ref;
  Timer? _searchDebounce;
  BoxesPermissionFlags _permissions = BoxesPermissionFlags.viewer;

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

  Future<void> loadData({bool forceRefresh = false}) async {
    await _ref.read(selectedFarmProvider.notifier).ready;
    final current = state.hasValue ? state.value : null;
    final sharedId = _ref.read(selectedFarmProvider).id;

    if (!state.hasValue) {
      state = const AsyncValue.loading();
    } else if (forceRefresh) {
      state = AsyncValue.data(current!.copyWith(isRefreshing: true));
    }

    try {
      final data = await _repository.getBoxesSummary(
        farmingAreaId: sharedId ?? current?.selectedFarmId,
        forceRefresh: forceRefresh,
        viewMode: current?.viewMode ?? _repository.savedViewMode,
        searchQuery: current?.searchQuery ?? '',
        quickFilters: current?.quickFilters ?? {BoxQuickFilter.all},
        advancedFilter: current?.advancedFilter ?? BoxFilterState.initial,
        canCreateBox: _permissions.canCreateBox,
        canEditBox: _permissions.canEditBox,
        canPerformActions: _permissions.canPerformActions,
      );
      state = AsyncValue.data(data.copyWith(isRefreshing: false));
      await _ref.read(selectedFarmProvider.notifier).select(
            data.selectedFarmId,
            name: data.selectedFarmName,
          );
    } catch (error, stackTrace) {
      if (current != null) {
        state = AsyncValue.data(
          current.copyWith(
            isOnline: false,
            isOfflineCached: true,
            isRefreshing: false,
            sectionError: error.toString(),
          ),
        );
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> refresh() => loadData(forceRefresh: true);

  Future<void> switchFarm(String farmId) async {
    if (!state.hasValue) return;
    final current = state.value!;
    if (farmId == current.selectedFarmId) return;

    final farmName = current.availableFarms
        .where((f) => f.id == farmId)
        .map((f) => f.name)
        .firstOrNull;

    // Local trước, global sau — tránh listen gọi lại switchFarm.
    state = AsyncValue.data(
      current.copyWith(
        selectedFarmId: farmId,
        selectedFarmName: farmName ?? current.selectedFarmName,
        isRefreshing: true,
      ),
    );

    await _ref.read(selectedFarmProvider.notifier).select(
          farmId,
          name: farmName,
        );

    try {
      final updated = await _repository.switchFarm(farmId);
      state = AsyncValue.data(
        updated.copyWith(
          canCreateBox: _permissions.canCreateBox,
          canEditBox: _permissions.canEditBox,
          canPerformActions: _permissions.canPerformActions,
          isRefreshing: false,
        ),
      );
      await _ref.read(selectedFarmProvider.notifier).select(
            updated.selectedFarmId,
            name: updated.selectedFarmName,
          );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isRefreshing: false));
    }
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
    state = AsyncValue.data(state.value!.copyWith(viewMode: mode));
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
    try {
      final updated = await action();
      if (!mounted) return;
      state = AsyncValue.data(
        updated.copyWith(
          canCreateBox: _permissions.canCreateBox,
          canEditBox: _permissions.canEditBox,
          canPerformActions: _permissions.canPerformActions,
        ),
      );
    } catch (error, stackTrace) {
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.copyWith(sectionError: error.toString()),
        );
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
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
    super.dispose();
  }
}
