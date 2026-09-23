// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/crab_management_remote_datasource.dart';
import '../../data/models/crab_management_models.dart';

// ── Data source provider ──────────────────────────────────────────────────────

final crabManagementDataSourceProvider =
    Provider<CrabManagementRemoteDataSource>(
      (ref) => CrabManagementRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
    );

// ── Dropdown options state ────────────────────────────────────────────────────

class CrabDropdownOptions {
  const CrabDropdownOptions({
    this.farmAreas = const [],
    this.rows = const [],
    this.boxes = const [],
    this.batches = const [],
    this.loadingFarms = false,
    this.loadingRows = false,
    this.loadingBoxes = false,
  });

  final List<FarmAreaOption> farmAreas;
  final List<RowOption> rows;
  final List<BoxOption> boxes;
  final List<BatchOption> batches;
  final bool loadingFarms;
  final bool loadingRows;
  final bool loadingBoxes;

  CrabDropdownOptions copyWith({
    List<FarmAreaOption>? farmAreas,
    List<RowOption>? rows,
    List<BoxOption>? boxes,
    List<BatchOption>? batches,
    bool? loadingFarms,
    bool? loadingRows,
    bool? loadingBoxes,
  }) {
    return CrabDropdownOptions(
      farmAreas: farmAreas ?? this.farmAreas,
      rows: rows ?? this.rows,
      boxes: boxes ?? this.boxes,
      batches: batches ?? this.batches,
      loadingFarms: loadingFarms ?? this.loadingFarms,
      loadingRows: loadingRows ?? this.loadingRows,
      loadingBoxes: loadingBoxes ?? this.loadingBoxes,
    );
  }
}

// ── Main state ────────────────────────────────────────────────────────────────

class CrabManagementState {
  const CrabManagementState({
    this.kpi = const AsyncValue.loading(),
    this.page = const AsyncValue.loading(),
    this.dropdown = const CrabDropdownOptions(),
    this.filter = const CrabFilterState(),
    this.currentPage = 1,
    this.pageSize = 10,
    this.selectedCrab,
    this.loadingDetail = false,
    this.selectedIds = const {},
    this.actionLoading = false,
    this.sortColumn,
    this.sortAscending = false,
  });

  final AsyncValue<CrabKpiSummary> kpi;
  final AsyncValue<CrabPage> page;
  final CrabDropdownOptions dropdown;
  final CrabFilterState filter;
  final int currentPage;
  final int pageSize;
  final CrabRecord? selectedCrab;
  final bool loadingDetail;
  final Set<String> selectedIds;
  final bool actionLoading;
  final String? sortColumn;
  final bool sortAscending;

  CrabManagementState copyWith({
    AsyncValue<CrabKpiSummary>? kpi,
    AsyncValue<CrabPage>? page,
    CrabDropdownOptions? dropdown,
    CrabFilterState? filter,
    int? currentPage,
    int? pageSize,
    CrabRecord? selectedCrab,
    bool clearSelectedCrab = false,
    bool? loadingDetail,
    Set<String>? selectedIds,
    bool? actionLoading,
    String? sortColumn,
    bool clearSort = false,
    bool? sortAscending,
  }) {
    return CrabManagementState(
      kpi: kpi ?? this.kpi,
      page: page ?? this.page,
      dropdown: dropdown ?? this.dropdown,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      selectedCrab: clearSelectedCrab
          ? null
          : (selectedCrab ?? this.selectedCrab),
      loadingDetail: loadingDetail ?? this.loadingDetail,
      selectedIds: selectedIds ?? this.selectedIds,
      actionLoading: actionLoading ?? this.actionLoading,
      sortColumn: clearSort ? null : (sortColumn ?? this.sortColumn),
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CrabManagementNotifier extends StateNotifier<CrabManagementState> {
  CrabManagementNotifier(this._ds) : super(const CrabManagementState()) {
    _init();
  }

  final CrabManagementRemoteDataSource _ds;

  Timer? _debounce;

  Future<void> _init() async {
    await Future.wait([_loadDropdowns(), _loadKpi(), _loadPage()]);
  }

  // ── KPI ──────────────────────────────────────────────────────────────────────

  Future<void> _loadKpi() async {
    state = state.copyWith(kpi: const AsyncValue.loading());
    try {
      final kpi = await _ds.getKpiSummary(farmAreaId: state.filter.farmAreaId);
      state = state.copyWith(kpi: AsyncValue.data(kpi));
    } on Exception catch (e, st) {
      state = state.copyWith(kpi: AsyncValue.error(e, st));
    }
  }

  // ── Page ─────────────────────────────────────────────────────────────────────

  Future<void> _loadPage() async {
    state = state.copyWith(page: const AsyncValue.loading());
    try {
      final page = await _ds.getCrabs(
        page: state.currentPage,
        pageSize: state.pageSize,
        filter: state.filter,
      );
      state = state.copyWith(page: AsyncValue.data(page));
    } on Exception catch (e, st) {
      state = state.copyWith(page: AsyncValue.error(e, st));
    }
  }

  // ── Dropdowns ────────────────────────────────────────────────────────────────

  Future<void> _loadDropdowns() async {
    state = state.copyWith(
      dropdown: state.dropdown.copyWith(loadingFarms: true),
    );
    try {
      final farms = await _ds.getFarmAreas();
      final batches = await _ds.getBatches();
      state = state.copyWith(
        dropdown: state.dropdown.copyWith(
          farmAreas: farms,
          batches: batches,
          loadingFarms: false,
        ),
      );
    } on Exception {
      state = state.copyWith(
        dropdown: state.dropdown.copyWith(loadingFarms: false),
      );
    }
  }

  Future<void> onFarmAreaSelected(String? id) async {
    final newFilter = state.filter.copyWith(
      farmAreaId: id,
      rowId: null,
      boxId: null,
    );
    state = state.copyWith(
      filter: newFilter,
      currentPage: 1,
      dropdown: state.dropdown.copyWith(rows: [], boxes: [], loadingRows: true),
    );
    if (id != null) {
      try {
        final rows = await _ds.getRows(farmAreaId: id);
        state = state.copyWith(
          dropdown: state.dropdown.copyWith(rows: rows, loadingRows: false),
        );
      } on Exception {
        state = state.copyWith(
          dropdown: state.dropdown.copyWith(loadingRows: false),
        );
      }
    }
    await Future.wait([_loadKpi(), _loadPage()]);
  }

  Future<void> onRowSelected(String? id) async {
    final newFilter = state.filter.copyWith(rowId: id, boxId: null);
    state = state.copyWith(
      filter: newFilter,
      currentPage: 1,
      dropdown: state.dropdown.copyWith(boxes: [], loadingBoxes: true),
    );
    if (id != null) {
      try {
        final boxes = await _ds.getBoxes(rowId: id);
        state = state.copyWith(
          dropdown: state.dropdown.copyWith(boxes: boxes, loadingBoxes: false),
        );
      } on Exception {
        state = state.copyWith(
          dropdown: state.dropdown.copyWith(loadingBoxes: false),
        );
      }
    }
    await _loadPage();
  }

  Future<void> onBoxSelected(String? id) async {
    state = state.copyWith(
      filter: state.filter.copyWith(boxId: id),
      currentPage: 1,
    );
    await _loadPage();
  }

  Future<void> onBatchSelected(String? id) async {
    state = state.copyWith(
      filter: state.filter.copyWith(batchId: id),
      currentPage: 1,
    );
    await _loadPage();
  }

  // ── Search with debounce ──────────────────────────────────────────────────────

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(
        filter: state.filter.copyWith(searchQuery: query),
        currentPage: 1,
      );
      _loadPage();
    });
  }

  void onSearchSubmit() {
    _debounce?.cancel();
    state = state.copyWith(currentPage: 1);
    _loadPage();
  }

  // ── Filters ──────────────────────────────────────────────────────────────────

  Future<void> onGenderChanged(CrabGender? gender) async {
    state = state.copyWith(
      filter: state.filter.copyWith(gender: gender),
      currentPage: 1,
    );
    await _loadPage();
  }

  Future<void> onLifecycleStatusChanged(CrabLifecycleStatus? status) async {
    state = state.copyWith(
      filter: state.filter.copyWith(lifecycleStatus: status),
      currentPage: 1,
    );
    await _loadPage();
  }

  Future<void> onHealthStatusChanged(CrabHealthStatus? status) async {
    state = state.copyWith(
      filter: state.filter.copyWith(healthStatus: status),
      currentPage: 1,
    );
    await _loadPage();
  }

  Future<void> onQuickStatusSelected(CrabLifecycleStatus? status) async {
    state = state.copyWith(
      filter: state.filter.copyWith(quickStatus: status),
      currentPage: 1,
    );
    await _loadPage();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      filter: const CrabFilterState(),
      currentPage: 1,
      dropdown: state.dropdown.copyWith(rows: [], boxes: []),
    );
    await Future.wait([_loadKpi(), _loadPage()]);
  }

  // ── Pagination ────────────────────────────────────────────────────────────────

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    state = state.copyWith(currentPage: page);
    await _loadPage();
  }

  Future<void> setPageSize(int size) async {
    state = state.copyWith(pageSize: size, currentPage: 1);
    await _loadPage();
  }

  // ── Row selection ─────────────────────────────────────────────────────────────

  void toggleSelectRow(String id) {
    final ids = Set<String>.from(state.selectedIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = state.copyWith(selectedIds: ids);
  }

  void toggleSelectAll(List<String> allIds) {
    if (state.selectedIds.length == allIds.length) {
      state = state.copyWith(selectedIds: {});
    } else {
      state = state.copyWith(selectedIds: Set.from(allIds));
    }
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  // ── Detail panel ─────────────────────────────────────────────────────────────

  Future<void> selectCrab(CrabRecord crab) async {
    state = state.copyWith(selectedCrab: crab);
    // Optionally re-fetch full detail
    try {
      state = state.copyWith(loadingDetail: true);
      final detail = await _ds.getCrabById(crab.id);
      state = state.copyWith(selectedCrab: detail, loadingDetail: false);
    } on Exception {
      state = state.copyWith(loadingDetail: false);
    }
  }

  void closeDetail() {
    state = state.copyWith(clearSelectedCrab: true);
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> markMolting({
    required String crabId,
    required DateTime detectedAt,
    String? note,
  }) async {
    state = state.copyWith(actionLoading: true);
    try {
      await _ds.markMolting(crabId: crabId, detectedAt: detectedAt, note: note);
      await Future.wait([_loadKpi(), _loadPage()]);
      // Refresh detail if this crab is selected
      if (state.selectedCrab?.id == crabId) {
        final updated = await _ds.getCrabById(crabId);
        state = state.copyWith(selectedCrab: updated);
      }
    } finally {
      state = state.copyWith(actionLoading: false);
    }
  }

  Future<void> markDead({
    required String crabId,
    required DateTime detectedAt,
    required DeathReason reason,
    String? note,
  }) async {
    state = state.copyWith(actionLoading: true);
    try {
      await _ds.markDead(
        crabId: crabId,
        detectedAt: detectedAt,
        reason: reason,
        note: note,
      );
      await Future.wait([_loadKpi(), _loadPage()]);
      if (state.selectedCrab?.id == crabId) {
        state = state.copyWith(clearSelectedCrab: true);
      }
    } finally {
      state = state.copyWith(actionLoading: false);
    }
  }

  Future<void> transferCrab({
    required String crabId,
    required String toBoxId,
    String? note,
  }) async {
    state = state.copyWith(actionLoading: true);
    try {
      await _ds.transferCrab(crabId: crabId, toBoxId: toBoxId, note: note);
      await Future.wait([_loadKpi(), _loadPage()]);
      if (state.selectedCrab?.id == crabId) {
        final updated = await _ds.getCrabById(crabId);
        state = state.copyWith(selectedCrab: updated);
      }
    } finally {
      state = state.copyWith(actionLoading: false);
    }
  }

  Future<void> refresh() async {
    await Future.wait([_loadKpi(), _loadPage()]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final crabManagementProvider =
    StateNotifierProvider<CrabManagementNotifier, CrabManagementState>(
      (ref) =>
          CrabManagementNotifier(ref.watch(crabManagementDataSourceProvider)),
    );
