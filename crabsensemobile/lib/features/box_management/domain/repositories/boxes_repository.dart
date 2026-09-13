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

  /// Hướng đánh số hộp người dùng chọn — giữ trong phiên như [savedViewMode].
  Future<void> saveBoxLayoutOrder(BoxLayoutOrder order);

  BoxLayoutOrder get savedBoxLayoutOrder;

  /// Creates a box on a farming row (Admin/Manager). Returns updated summary.
  Future<BoxesStateData> createBox({
    required String farmingRowId,
    String? code,
  });

  Future<BoxesStateData> updateBox({
    required String id,
    required String code,
    String? status,
    required bool isOccupied,
  });

  Future<BoxesStateData> deleteBox(String id);

  Future<BoxesStateData> createArea({required String name, String? description});

  Future<BoxesStateData> updateArea({
    required String id,
    required String name,
    String? description,
    bool isActive = true,
  });

  /// Xoá khu. Mặc định chỉ xoá được khi khu đã hết dãy.
  /// [cascade] = true: xoá luôn cả dãy, hộp và cua bên trong (không khôi phục được).
  Future<BoxesStateData> deleteArea(String id, {bool cascade = false});

  Future<BoxesStateData> createRow({
    required String farmingAreaId,
    required String name,
    required int capacity,
  });

  Future<BoxesStateData> updateRow({
    required String id,
    required String name,
    required int capacity,
    bool isActive = true,
  });

  Future<BoxesStateData> deleteRow(String id);

  /// Farming rows for create-box picker.
  Future<List<({String id, String name})>> fetchRows(String? farmingAreaId);

  Future<List<FarmRowOption>> fetchRowDetails(String? farmingAreaId);
}
