import 'package:flutter/foundation.dart';

import '../data/mock_batch_data.dart';
import '../models/batch_status.dart';
import '../models/crab_batch.dart';

class BatchService extends ChangeNotifier {
  BatchService() : _batches = MockBatchData.initialBatches();

  List<CrabBatch> _batches;

  List<CrabBatch> get batches => List.unmodifiable(_batches);

  List<CrabBatch> get _visible => filteredBatches;

  List<CrabBatch> get paginatedBatches {
    final list = _visible;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= list.length) return [];
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int _currentPage = 1;
  int get currentPage => _currentPage;

  static const _pageSize = 4;
  int get pageSize => _pageSize;

  int get totalPages => (_visible.length / _pageSize).ceil().clamp(1, 999);

  int get totalCount => _visible.length;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<CrabBatch> get filteredBatches {
    if (_searchQuery.isEmpty) return _batches;
    final q = _searchQuery.toLowerCase();
    return _batches
        .where(
          (b) =>
              b.id.toLowerCase().contains(q) ||
              (b.name?.toLowerCase().contains(q) ?? false) ||
              b.source.toLowerCase().contains(q),
        )
        .toList();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    _currentPage = page.clamp(1, totalPages);
    notifyListeners();
  }

  CrabBatch? getById(String id) => MockBatchData.findById(_batches, id);

  void addBatch(CrabBatch batch) {
    _batches = [batch, ..._batches];
    _currentPage = 1;
    notifyListeners();
  }

  void updateBatch(CrabBatch batch) {
    final i = _batches.indexWhere((b) => b.id == batch.id);
    if (i >= 0) {
      _batches = [..._batches]..[i] = batch;
      notifyListeners();
    }
  }

  void endBatch(
    String id, {
    required int harvestQty,
    required double weightKg,
    required double revenue,
    required double cost,
  }) {
    final batch = getById(id);
    if (batch == null) return;
    updateBatch(
      batch.copyWith(
        status: BatchStatus.ended,
        aliveCount: 0,
        revenueMillion: revenue,
        cycleProgress: 1,
      ),
    );
  }

  String generateNextId() {
    final year = DateTime.now().year;
    final count =
        _batches.where((b) => b.id.contains('$year')).length + 1;
    return 'CFM-$year-${count.toString().padLeft(3, '0')}';
  }
}
