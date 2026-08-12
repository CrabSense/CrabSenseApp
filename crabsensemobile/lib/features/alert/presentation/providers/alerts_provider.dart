import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/selected_farm_provider.dart';
import '../../data/repositories/alerts_command_repository_impl.dart';
import '../../domain/models/alerts_models.dart';
import '../../domain/repositories/alerts_command_repository.dart';

final alertsRepositoryProvider = Provider<AlertsCommandRepository>(
  (ref) => AlertsCommandRepositoryImpl(),
);

/// Permission flags applied from AuthBloc via the Alerts screen.
class AlertsPermissionFlags {
  final bool canAcknowledge;
  final bool canResolve;
  final bool canAssign;
  final bool canConfigureThresholds;
  final bool canViewFullHistory;
  final bool canMarkAllRead;

  const AlertsPermissionFlags({
    required this.canAcknowledge,
    required this.canResolve,
    required this.canAssign,
    required this.canConfigureThresholds,
    required this.canViewFullHistory,
    required this.canMarkAllRead,
  });

  static const viewer = AlertsPermissionFlags(
    canAcknowledge: false,
    canResolve: false,
    canAssign: false,
    canConfigureThresholds: false,
    canViewFullHistory: false,
    canMarkAllRead: false,
  );

  static AlertsPermissionFlags fromRoleFlags({
    required bool isAdmin,
    required bool isManager,
    required bool isOperator,
    required bool hasWriteAccess,
  }) {
    return AlertsPermissionFlags(
      canAcknowledge: hasWriteAccess,
      canResolve: isAdmin || isManager || isOperator,
      // Assignment API chưa có trên backend — ẩn UI giao việc.
      canAssign: false,
      canConfigureThresholds: isAdmin,
      canViewFullHistory: isAdmin || isManager || isOperator,
      canMarkAllRead: isAdmin || isManager,
    );
  }
}

final alertsStateProvider =
    StateNotifierProvider<AlertsNotifier, AsyncValue<AlertsStateData>>((ref) {
  final repository = ref.watch(alertsRepositoryProvider);
  return AlertsNotifier(repository, ref);
});

/// Unread/open badge for Bottom Navigation (99+ capped in UI).
final alertsBadgeCountProvider = Provider<int>((ref) {
  final async = ref.watch(alertsStateProvider);
  return async.maybeWhen(
    data: (d) => d.summary.unread > 0 ? d.summary.unread : d.summary.open,
    orElse: () => 0,
  );
});

class AlertsNotifier extends StateNotifier<AsyncValue<AlertsStateData>> {
  AlertsNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _ref.listen<SelectedFarm>(selectedFarmProvider, (prev, next) {
      if (next.id == null || next.id!.isEmpty) return;
      if (!state.hasValue) return;
      if (state.value!.selectedFarmId == next.id) return;
      switchFarm(next.id!);
    });
    loadData();
  }

  final AlertsCommandRepository _repository;
  final Ref _ref;
  Timer? _searchDebounce;
  AlertsPermissionFlags _permissions = AlertsPermissionFlags.viewer;
  String _userId = 'current-user';
  String _userName = 'Operator';

  void updatePermissions(AlertsPermissionFlags flags) {
    _permissions = flags;
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.copyWith(
          canAcknowledge: flags.canAcknowledge,
          canResolve: flags.canResolve,
          canAssign: flags.canAssign,
          canConfigureThresholds: flags.canConfigureThresholds,
          canViewFullHistory: flags.canViewFullHistory,
          canMarkAllRead: flags.canMarkAllRead,
        ),
      );
    }
  }

  void setCurrentUser({required String id, required String name}) {
    _userId = id;
    _userName = name;
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
      final data = await _repository.getAlertsSummary(
        farmingAreaId: sharedId ?? current?.selectedFarmId,
        forceRefresh: forceRefresh,
        searchQuery: current?.searchQuery ?? '',
        quickFilters: current?.quickFilters ?? {AlertQuickFilter.all},
        sortOption: current?.sortOption ?? AlertSortOption.priorityDesc,
        groupBy: current?.groupBy ?? AlertGroupBy.severity,
        showingHistory: current?.showingHistory ?? false,
        historyRange: current?.historyRange ?? AlertHistoryRange.today,
        canAcknowledge: _permissions.canAcknowledge,
        canResolve: _permissions.canResolve,
        canAssign: _permissions.canAssign,
        canConfigureThresholds: _permissions.canConfigureThresholds,
        canViewFullHistory: _permissions.canViewFullHistory,
        canMarkAllRead: _permissions.canMarkAllRead,
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
          canAcknowledge: _permissions.canAcknowledge,
          canResolve: _permissions.canResolve,
          canAssign: _permissions.canAssign,
          canConfigureThresholds: _permissions.canConfigureThresholds,
          canViewFullHistory: _permissions.canViewFullHistory,
          canMarkAllRead: _permissions.canMarkAllRead,
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
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(searchQuery: query));
    }
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!state.hasValue) return;
      state = AsyncValue.data(
        _repository.applyLocalFilters(
          current: state.value!,
          searchQuery: query,
        ),
      );
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    if (!state.hasValue) return;
    state = AsyncValue.data(
      _repository.applyLocalFilters(current: state.value!, searchQuery: ''),
    );
  }

  void toggleQuickFilter(AlertQuickFilter filter) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = Set<AlertQuickFilter>.from(current.quickFilters);

    if (filter == AlertQuickFilter.all) {
      next
        ..clear()
        ..add(AlertQuickFilter.all);
    } else {
      next.remove(AlertQuickFilter.all);
      if (next.contains(filter)) {
        next.remove(filter);
      } else {
        next.add(filter);
      }
      if (next.isEmpty) next.add(AlertQuickFilter.all);
    }

    state = AsyncValue.data(
      _repository.applyLocalFilters(current: current, quickFilters: next),
    );
  }

  void clearFilters() {
    if (!state.hasValue) return;
    state = AsyncValue.data(
      _repository.applyLocalFilters(
        current: state.value!,
        searchQuery: '',
        quickFilters: {AlertQuickFilter.all},
      ),
    );
  }

  void setSort(AlertSortOption sort) {
    if (!state.hasValue) return;
    state = AsyncValue.data(
      _repository.applyLocalFilters(current: state.value!, sortOption: sort),
    );
  }

  void setGroupBy(AlertGroupBy groupBy) {
    if (!state.hasValue) return;
    state = AsyncValue.data(
      _repository.applyLocalFilters(current: state.value!, groupBy: groupBy),
    );
  }

  void setShowingHistory(bool value) {
    if (!state.hasValue) return;
    state = AsyncValue.data(
      _repository.applyLocalFilters(
        current: state.value!,
        showingHistory: value,
      ),
    );
  }

  void setHistoryRange(AlertHistoryRange range) {
    if (!state.hasValue) return;
    state = AsyncValue.data(
      _repository.applyLocalFilters(
        current: state.value!,
        historyRange: range,
        showingHistory: true,
      ),
    );
  }

  void selectAlert(String? id) {
    if (!state.hasValue) return;
    state = AsyncValue.data(
      state.value!.copyWith(
        selectedAlertId: id,
        clearSelectedAlert: id == null,
      ),
    );
  }

  Future<void> acknowledge(String alertId) async {
    if (!_permissions.canAcknowledge || !state.hasValue) return;
    final updated = await _repository.acknowledge(
      alertId,
      userId: _userId,
      userName: _userName,
    );
    _patchItem(updated);
  }

  Future<void> startProgress(String alertId) async {
    if (!_permissions.canResolve || !state.hasValue) return;
    final updated = await _repository.startProgress(
      alertId,
      userId: _userId,
      userName: _userName,
    );
    _patchItem(updated);
  }

  Future<void> resolve(String alertId, {String? note}) async {
    if (!_permissions.canResolve || !state.hasValue) return;
    final updated = await _repository.resolve(
      alertId,
      userId: _userId,
      userName: _userName,
      note: note,
    );
    _patchItem(updated);
  }

  Future<void> dismiss(String alertId) async {
    if (!_permissions.canAcknowledge || !state.hasValue) return;
    final updated = await _repository.dismiss(alertId);
    _patchItem(updated);
  }

  Future<void> assign({
    required String alertId,
    required String assigneeId,
    required String assigneeName,
    required String assigneeRole,
    DateTime? dueAt,
    String? note,
  }) async {
    if (!_permissions.canAssign || !state.hasValue) return;
    final updated = await _repository.assign(
      alertId,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      assigneeRole: assigneeRole,
      dueAt: dueAt,
      note: note,
    );
    _patchItem(updated);
  }

  Future<void> markAllRead() async {
    if (!_permissions.canMarkAllRead || !state.hasValue) return;
    await _repository.markAllRead();
    await loadData(forceRefresh: false);
  }

  Future<void> hideAlert(String alertId) async {
    await _repository.hideAlert(alertId);
    await loadData();
  }

  Future<void> syncPending() async {
    if (!state.hasValue) return;
    state = AsyncValue.data(state.value!.copyWith(isRefreshing: true));
    await _repository.syncPending();
    await loadData(forceRefresh: true);
  }

  void _patchItem(AlertItem? updated) {
    if (updated == null || !state.hasValue) return;
    final current = state.value!;
    final all = current.allAlerts
        .map((a) => a.id == updated.id ? updated : a)
        .toList();
    final patched = current.copyWith(allAlerts: all);
    state = AsyncValue.data(_repository.applyLocalFilters(current: patched));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
