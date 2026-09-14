import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/batch_status.dart';
import '../models/crab_batch.dart';
import '../theme/dashboard_theme.dart';

class BatchService extends ChangeNotifier {
  BatchService() : _batches = [];

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

  CrabBatch? getById(String id) {
    for (final b in _batches) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<BatchSummaryKpi> summaryKpis() {
    final total = _batches.length;
    final raising =
        _batches.where((b) => b.status == BatchStatus.raising).length;
    final harvested = _batches
        .where((b) =>
            b.status == BatchStatus.harvested ||
            b.status == BatchStatus.ended)
        .length;
    final active = _batches.where((b) => b.aliveCount > 0).toList();
    final avgSurvival = active.isEmpty
        ? 0.0
        : active.map((b) => b.survivalRate).reduce((a, b) => a + b) /
            active.length;
    return [
      BatchSummaryKpi(
        label: 'Tổng lứa',
        value: '$total',
        subtext: '',
        icon: Icons.description_outlined,
        accentColor: const Color(0xFF7C5CFF),
      ),
      BatchSummaryKpi(
        label: 'Đang nuôi',
        value: '$raising',
        subtext: '',
        icon: Icons.waves_outlined,
        accentColor: const Color(0xFF57E6FF),
      ),
      BatchSummaryKpi(
        label: 'Đã thu hoạch',
        value: '$harvested',
        subtext: '',
        icon: Icons.check_circle_outline,
        accentColor: const Color(0xFF94A3B8),
      ),
      BatchSummaryKpi(
        label: 'Tỷ lệ sống',
        value: '${avgSurvival.toStringAsFixed(1)}%',
        subtext: '',
        icon: Icons.favorite_outline,
        accentColor: const Color(0xFF57E6FF),
      ),
    ];
  }

  static List<double> weightGrowthGrams(CrabBatch batch) {
    const steps = 6;
    final delta = (batch.avgWeightGram - batch.initialWeightGram) / (steps - 1);
    return List.generate(
      steps,
      (i) => batch.initialWeightGram + delta * i,
    );
  }

  static List<double> expectedWeightGrowth(CrabBatch batch) {
    return weightGrowthGrams(batch).map((v) => v * 0.92).toList();
  }

  static List<double> survivalHistory(CrabBatch batch) {
    final rate = batch.survivalRate;
    return [100, 99.5, 99, 98.5, 98, rate];
  }

  static List<String> survivalLabels(CrabBatch batch) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return [
      fmt(batch.releaseDate),
      fmt(batch.releaseDate.add(const Duration(days: 14))),
      fmt(batch.releaseDate.add(const Duration(days: 30))),
      fmt(batch.releaseDate.add(const Duration(days: 45))),
      fmt(batch.releaseDate.add(const Duration(days: 60))),
      'Hiện tại',
    ];
  }

  static List<BatchStatusDistribution> crabDistribution(CrabBatch batch) {
    if (batch.aliveCount <= 0) return const [];
    return [
      BatchStatusDistribution(
        label: 'Khỏe mạnh',
        percent: 100,
        color: DashboardColors.cyan,
      ),
    ];
  }

  static List<BatchTimelineEvent> timeline(CrabBatch batch) => [
        BatchTimelineEvent(
          date: batch.releaseDate,
          title: 'Thả giống',
          subtitle: 'Hoàn tất thả ${batch.initialQuantity} con',
          icon: Icons.water_drop_outlined,
        ),
        BatchTimelineEvent(
          date: batch.releaseDate.add(Duration(days: batch.daysToHarvest)),
          title: 'Dự kiến thu hoạch',
          subtitle: 'Kế hoạch thu hoạch',
          icon: Icons.flag_outlined,
          isFuture: true,
        ),
      ];

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
