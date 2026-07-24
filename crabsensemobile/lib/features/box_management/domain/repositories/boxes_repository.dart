import '../models/boxes_models.dart';

/// Contract for Boxes tab data (Farm Digital Twin list).
abstract class BoxesRepository {
  /// Loads boxes for [farmingAreaId] (null = all farms / first available).
  Future<BoxesStateData> getBoxesSummary({
    String? farmingAreaId,
    bool forceRefresh = false,
    BoxesViewMode viewMode = BoxesViewMode.grid,
    String searchQuery = '',
    Set<BoxQuickFilter> quickFilters = const {BoxQuickFilter.all},
    BoxFilterState advancedFilter = BoxFilterState.initial,
    bool canCreateBox = false,
    bool canEditBox = false,
    bool canPerformActions = false,
  });

  /// Switches selected farm and reloads.
  Future<BoxesStateData> switchFarm(String farmId);

  /// Applies client-side search / filter / sort on cached list.
  BoxesStateData applyLocalFilters({
    required BoxesStateData current,
    String? searchQuery,
    Set<BoxQuickFilter>? quickFilters,
    BoxFilterState? advancedFilter,
  });

  /// Persists preferred view mode in memory for the session.
  Future<void> saveViewMode(BoxesViewMode mode);

  BoxesViewMode get savedViewMode;

  /// Creates a box on a farming row (Admin/Manager). Returns updated summary.
  Future<BoxesStateData> createBox({
    required String farmingRowId,
    String? code,
  });

  /// Farming rows for create-box picker.
  Future<List<({String id, String name})>> fetchRows(String? farmingAreaId);
}
