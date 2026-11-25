import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/crab_lot_status.dart';
import '../models/production_models.dart';
import 'cloud_api_client.dart';

class CrabLotInboundKpis {
  const CrabLotInboundKpis({
    required this.totalLots,
    required this.totalCrabs,
    required this.placedCrabs,
    required this.pendingCrabs,
    required this.rejectedCrabs,
    required this.supplierCount,
    required this.lotsThisMonth,
    required this.crabsThisMonth,
  });

  final int totalLots;
  final int totalCrabs;
  final int placedCrabs;
  final int pendingCrabs;
  final int rejectedCrabs;
  final int supplierCount;
  final int lotsThisMonth;
  final int crabsThisMonth;

  int get placedPct => totalCrabs <= 0 ? 0 : ((placedCrabs / totalCrabs) * 100).round();
  int get pendingPct => totalCrabs <= 0 ? 0 : ((pendingCrabs / totalCrabs) * 100).round();
  int get rejectedPct => totalCrabs <= 0 ? 0 : ((rejectedCrabs / totalCrabs) * 100).round();
}

class CrabLotInboundService extends ChangeNotifier {
  CrabLotInboundService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;
  int _generation = 0;
  String get areaId => _session.selectedFarm.id;
  bool canManageLot(FarmingBatchRecord lot) => _session.user.role == UserRoles.farmManager && areaId.isNotEmpty && !lot.isPartialScope && lot.farmingAreaIds.contains(areaId) && lot.farmingAreaIds.every((id) => _session.farms.any((f) => f.id == id));
  bool canCloseLot(FarmingBatchRecord lot) => canManageLot(lot) && !lot.isClosed && lot.stockedAt != null && lot.workflowStatus != CrabLotWorkflowStatus.cancelled;
  bool canDeleteLot(FarmingBatchRecord lot) => canManageLot(lot) && !lot.isClosed && lot.placedCount == 0;
  bool _guard(String id) {
    final lot = findById(id);
    if (lot != null && canManageLot(lot) && !lot.isClosed) return true;
    _error = 'Lô không thuộc phạm vi quản lý đầy đủ của khu hiện tại.';
    notifyListeners();
    return false;
  }

  List<FarmingBatchRecord> _lots = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  CrabLotWorkflowStatus? _statusFilter;
  DateTime? _from;
  DateTime? _to;
  String _supplierFilter = '';
  CrabLotSort _sort = CrabLotSort.newest;
  CrabLotProgressBand _progressBand = CrabLotProgressBand.all;
  int? _qtyMin;
  int? _qtyMax;
  int _pageSize = 10;
  int _page = 0;

  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  CrabLotWorkflowStatus? get statusFilter => _statusFilter;
  DateTime? get from => _from;
  DateTime? get to => _to;
  String get supplierFilter => _supplierFilter;
  CrabLotSort get sort => _sort;
  CrabLotProgressBand get progressBand => _progressBand;
  int? get qtyMin => _qtyMin;
  int? get qtyMax => _qtyMax;
  int get currentPage => _page;
  int get pageSize => _pageSize;
  List<FarmingBatchRecord> get lots => List.unmodifiable(_lots);

  String get token => _session.token;

  bool get hasActiveFilters =>
      _search.trim().isNotEmpty ||
      _statusFilter != null ||
      _from != null ||
      _to != null ||
      _supplierFilter.isNotEmpty ||
      _progressBand != CrabLotProgressBand.all ||
      _qtyMin != null ||
      _qtyMax != null;

  void updateSession(AuthSession session) {
    ++_generation;
    _loading = false;
    _error = null;
    _session = session;
    _lots = [];
    _page = 0;
    notifyListeners();
  }

  List<String> get supplierOptions {
    final names = _lots
        .map((l) => l.supplierName?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return names;
  }

  CrabLotInboundKpis get kpis {
    final now = DateTime.now();
    var lotsThisMonth = 0;
    var crabsThisMonth = 0;
    var totalCrabs = 0;
    var placed = 0;
    var pending = 0;
    var rejected = 0;
    final suppliers = <String>{};

    for (final lot in _lots) {
      totalCrabs += lot.initialQuantity;
      placed += lot.placedCount;
      pending += lot.remainingCount;
      rejected += lot.rejectedCount;
      final s = lot.supplierName?.trim();
      if (s != null && s.isNotEmpty) suppliers.add(s);
      if (lot.startDate.year == now.year && lot.startDate.month == now.month) {
        lotsThisMonth++;
        crabsThisMonth += lot.initialQuantity;
      }
    }

    return CrabLotInboundKpis(
      totalLots: _lots.length,
      totalCrabs: totalCrabs,
      placedCrabs: placed,
      pendingCrabs: pending,
      rejectedCrabs: rejected,
      supplierCount: suppliers.length,
      lotsThisMonth: lotsThisMonth,
      crabsThisMonth: crabsThisMonth,
    );
  }

  List<FarmingBatchRecord> get filtered {
    final q = _search.trim().toLowerCase();
    final list = _lots.where((lot) {
      if (_statusFilter != null && lot.workflowStatus != _statusFilter) {
        return false;
      }
      if (_supplierFilter.isNotEmpty &&
          (lot.supplierName ?? '').trim() != _supplierFilter) {
        return false;
      }
      if (_from != null) {
        final d = DateTime(lot.startDate.year, lot.startDate.month, lot.startDate.day);
        final f = DateTime(_from!.year, _from!.month, _from!.day);
        if (d.isBefore(f)) return false;
      }
      if (_to != null) {
        final d = DateTime(lot.startDate.year, lot.startDate.month, lot.startDate.day);
        final t = DateTime(_to!.year, _to!.month, _to!.day);
        if (d.isAfter(t)) return false;
      }
      if (_qtyMin != null && lot.initialQuantity < _qtyMin!) return false;
      if (_qtyMax != null && lot.initialQuantity > _qtyMax!) return false;
      if (!_progressBand.matches(lot.allocationPercent)) return false;
      if (q.isEmpty) return true;
      return lot.batchCode.toLowerCase().contains(q) ||
          (lot.name ?? '').toLowerCase().contains(q) ||
          (lot.supplierName ?? '').toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case CrabLotSort.newest:
          return b.startDate.compareTo(a.startDate);
        case CrabLotSort.oldest:
          return a.startDate.compareTo(b.startDate);
        case CrabLotSort.qtyHigh:
          return b.initialQuantity.compareTo(a.initialQuantity);
        case CrabLotSort.qtyLow:
          return a.initialQuantity.compareTo(b.initialQuantity);
        case CrabLotSort.progress:
          return b.allocationPercent.compareTo(a.allocationPercent);
      }
    });
    return list;
  }

  int get filteredCount => filtered.length;

  int get totalPages =>
      filteredCount == 0 ? 1 : (filteredCount / _pageSize).ceil().clamp(1, 999);

  List<FarmingBatchRecord> get paged {
    final list = filtered;
    final start = _page * _pageSize;
    if (start >= list.length) return [];
    return list.sublist(start, (start + _pageSize).clamp(0, list.length));
  }

  FarmingBatchRecord? findById(String id) {
    for (final lot in _lots) {
      if (lot.id == id) return lot;
    }
    return null;
  }

  void setSearch(String value) {
    _search = value;
    _page = 0;
    notifyListeners();
  }

  void setStatusFilter(CrabLotWorkflowStatus? value) {
    _statusFilter = value;
    _page = 0;
    notifyListeners();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _from = from;
    _to = to;
    _page = 0;
    notifyListeners();
  }

  void setSupplierFilter(String value) {
    _supplierFilter = value;
    _page = 0;
    notifyListeners();
  }

  void setSort(CrabLotSort value) {
    _sort = value;
    _page = 0;
    notifyListeners();
  }

  void setProgressBand(CrabLotProgressBand value) {
    _progressBand = value;
    _page = 0;
    notifyListeners();
  }

  void setQtyRange(int? min, int? max) {
    _qtyMin = min;
    _qtyMax = max;
    _page = 0;
    notifyListeners();
  }

  void setPageSize(int value) {
    _pageSize = value;
    _page = 0;
    notifyListeners();
  }

  void goToPage(int page) {
    _page = page.clamp(0, totalPages - 1);
    notifyListeners();
  }

  void clearFilters() {
    _search = '';
    _statusFilter = null;
    _from = null;
    _to = null;
    _supplierFilter = '';
    _progressBand = CrabLotProgressBand.all;
    _qtyMin = null;
    _qtyMax = null;
    _page = 0;
    notifyListeners();
  }

  Future<void> load() async {
    if (areaId.isEmpty) return;
    final generation = ++_generation;
    final area = areaId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _api.fetchCrabLots(token);
      if (generation != _generation) return;
      _lots = rows.where((l) => l.farmingAreaIds.contains(area)).toList();
      _error = null;
    } on CloudApiException catch (e) {
      if (generation != _generation) return;
      _error = e.message;
    } catch (e) {
      if (generation != _generation) return;
      _error = '$e';
    } finally {
      if (generation == _generation) { _loading = false; notifyListeners(); }
    }
  }

  Future<FarmingBatchRecord?> refreshOne(String id) async {
    if (areaId.isEmpty) return null;
    final generation = _generation;
    final area = areaId;
    try {
      final lot = await _api.fetchCrabLot(token, id);
      if (generation != _generation || !lot.farmingAreaIds.contains(area)) return null;
      _lots = [lot, ..._lots.where((l) => l.id != id)];
      notifyListeners();
      return lot;
    } on CloudApiException catch (e) {
      if (generation != _generation) return null;
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<void> upsert(FarmingBatchRecord lot) async {
    if (!lot.farmingAreaIds.contains(areaId)) return;
    _lots = [lot, ..._lots.where((l) => l.id != lot.id)];
    notifyListeners();
  }

  Future<FarmingBatchRecord?> updateInfo(
    String id, {
    String? name,
    String? supplierName,
    String? notes,
    int? quantity,
    DateTime? importDate,
  }) async {
    if (!_guard(id)) return null;
    final generation = _generation;
    try {
      final lot = await _api.updateCrabLot(
        token,
        id,
        name: name,
        supplierName: supplierName,
        notes: notes,
        quantity: quantity,
        importDate: importDate,
      );
      if (generation != _generation) return null;
      _lots = [lot, ..._lots.where((l) => l.id != id)];
      notifyListeners();
      return lot;
    } on CloudApiException catch (e) {
      if (generation != _generation) return null;
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<FarmingBatchRecord?> uploadPhotos(String lotId, List<String> paths) async {
    if (!_guard(lotId)) return null;
    final generation = _generation;
    if (paths.isEmpty) return findById(lotId);
    try {
      await _api.uploadLotImages(token, lotId, paths);
      if (generation != _generation) return null;
      return await refreshOne(lotId);
    } on CloudApiException catch (e) {
      if (generation != _generation) return null;
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<FarmingBatchRecord?> cancel(String id) async {
    if (!_guard(id)) return null;
    final generation = _generation;
    try {
      final lot = await _api.updateCrabLot(token, id, status: 'Cancelled');
      if (generation != _generation) return null;
      _lots = [lot, ..._lots.where((l) => l.id != id)];
      notifyListeners();
      return lot;
    } on CloudApiException catch (e) {
      if (generation != _generation) return null;
      _error = e.message;
      notifyListeners();
      return null;
    }
  }
  Future<FarmingBatchRecord?> close(String id, String disposition) async {
    final lot = findById(id);
    if (lot == null || !canCloseLot(lot) || disposition.trim().isEmpty) {
      _error = 'Lô không thể kết thúc hoặc thiếu phương án xử lý.';
      notifyListeners(); return null;
    }
    final generation = _generation;
    try {
      final next = await _api.closeCrabLot(token,id,disposition:disposition.trim());
      if (generation != _generation) return null;
      _lots = [next,..._lots.where((l)=>l.id != id)];
      _error = null; notifyListeners(); return next;
    } catch (e) {
      if (generation == _generation) { _error = '$e'; notifyListeners(); }
      return null;
    }
  }

  Future<bool> deleteUnused(String id) async {
    final lot = findById(id);
    if (lot == null || !canDeleteLot(lot)) {
      _error = 'Chỉ xóa lô chưa kết thúc và không có cua tham chiếu.';
      notifyListeners(); return false;
    }
    final generation = _generation;
    try {
      await _api.deleteBatch(token,id);
      if (generation != _generation) return false;
      _lots = _lots.where((l)=>l.id != id).toList();
      _error = null; notifyListeners(); return true;
    } catch (e) {
      if (generation == _generation) { _error = '$e'; notifyListeners(); }
      return false;
    }
  }
  @override
  void dispose() { ++_generation; super.dispose(); }
}
