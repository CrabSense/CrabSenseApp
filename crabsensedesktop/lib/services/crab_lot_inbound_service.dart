import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/crab_lot_status.dart';
import '../models/production_models.dart';
import 'cloud_api_client.dart';

class CrabLotInboundKpis {
  const CrabLotInboundKpis({
    required this.totalLots,
    required this.totalCrabs,
    required this.inProgress,
    required this.completed,
  });

  final int totalLots;
  final int totalCrabs;
  final int inProgress;
  final int completed;
}

class CrabLotInboundService extends ChangeNotifier {
  CrabLotInboundService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<FarmingBatchRecord> _lots = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  CrabLotWorkflowStatus? _statusFilter;
  CrabLotDateRange _dateRange = CrabLotDateRange.all;
  String _supplierFilter = '';
  static const _pageSize = 10;
  int _page = 1;

  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  CrabLotWorkflowStatus? get statusFilter => _statusFilter;
  CrabLotDateRange get dateRange => _dateRange;
  String get supplierFilter => _supplierFilter;
  int get currentPage => _page;
  int get pageSize => _pageSize;
  List<FarmingBatchRecord> get lots => List.unmodifiable(_lots);

  String get token => _session.token;

  void updateSession(AuthSession session) {
    _session = session;
    _lots = [];
    _page = 1;
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
    final active = _lots.where((l) => l.workflowStatus != CrabLotWorkflowStatus.cancelled);
    var inProgress = 0;
    var completed = 0;
    var crabs = 0;
    for (final lot in active) {
      crabs += lot.initialQuantity;
      switch (lot.workflowStatus) {
        case CrabLotWorkflowStatus.pending:
        case CrabLotWorkflowStatus.allocating:
          inProgress++;
        case CrabLotWorkflowStatus.completed:
          completed++;
        case CrabLotWorkflowStatus.cancelled:
          break;
      }
    }
    return CrabLotInboundKpis(
      totalLots: _lots.length,
      totalCrabs: crabs,
      inProgress: inProgress,
      completed: completed,
    );
  }

  List<FarmingBatchRecord> get filtered {
    final q = _search.trim().toLowerCase();
    final now = DateTime.now();
    return _lots.where((lot) {
      if (_statusFilter != null && lot.workflowStatus != _statusFilter) return false;
      if (!_dateRange.contains(lot.startDate, now)) return false;
      if (_supplierFilter.isNotEmpty &&
          (lot.supplierName ?? '').trim() != _supplierFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return lot.batchCode.toLowerCase().contains(q) ||
          (lot.name ?? '').toLowerCase().contains(q) ||
          (lot.supplierName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  int get filteredCount => filtered.length;

  int get totalPages => (filteredCount / _pageSize).ceil().clamp(1, 999);

  List<FarmingBatchRecord> get paged {
    final list = filtered;
    final start = (_page - 1) * _pageSize;
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
    _page = 1;
    notifyListeners();
  }

  void setStatusFilter(CrabLotWorkflowStatus? value) {
    _statusFilter = value;
    _page = 1;
    notifyListeners();
  }

  void setDateRange(CrabLotDateRange value) {
    _dateRange = value;
    _page = 1;
    notifyListeners();
  }

  void setSupplierFilter(String value) {
    _supplierFilter = value;
    _page = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    _page = page.clamp(1, totalPages);
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _lots = await _api.fetchCrabLots(token);
      _error = null;
    } on CloudApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<FarmingBatchRecord?> refreshOne(String id) async {
    try {
      final lot = await _api.fetchCrabLot(token, id);
      _lots = [lot, ..._lots.where((l) => l.id != id)];
      notifyListeners();
      return lot;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<void> upsert(FarmingBatchRecord lot) async {
    _lots = [lot, ..._lots.where((l) => l.id != lot.id)];
    notifyListeners();
  }

  Future<FarmingBatchRecord?> cancel(String id) async {
    try {
      final lot = await _api.updateCrabLot(token, id, status: 'Cancelled');
      _lots = [lot, ..._lots.where((l) => l.id != id)];
      notifyListeners();
      return lot;
    } on CloudApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }
}
