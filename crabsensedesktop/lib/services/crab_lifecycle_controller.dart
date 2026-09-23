import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/crab_lifecycle_event.dart';
import 'cloud_api_client.dart';

/// State tab "Lịch sử & Nhật ký". Dữ liệu 100% từ API.
class CrabLifecycleController extends ChangeNotifier {
  CrabLifecycleController({
    required this.crabId,
    required this.api,
    required this.tokenProvider,
  });

  final String crabId;
  final CloudApiClient api;
  final String Function() tokenProvider;

  static const pageSize = 20;

  CrabHistoryPeriod _period = CrabHistoryPeriod.d7;
  CrabHistoryEventFilter _type = CrabHistoryEventFilter.all;
  CrabHistorySort _sort = CrabHistorySort.newest;
  DateTime? _from;
  DateTime? _to;
  String _search = '';
  Timer? _debounce;

  final List<CrabLifecycleEvent> _items = [];
  CrabLifecycleSummary _summary = const CrabLifecycleSummary();
  int _total = 0;
  bool _hasMore = false;
  String? _selectedId;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _gen = 0;

  CrabHistoryPeriod get period => _period;
  CrabHistoryEventFilter get type => _type;
  CrabHistorySort get sort => _sort;
  DateTime? get from => _from ?? _periodFrom;
  DateTime? get to => _to ?? _periodTo;
  String get search => _search;
  List<CrabLifecycleEvent> get items => List.unmodifiable(_items);
  CrabLifecycleSummary get summary => _summary;
  int get total => _total;
  bool get hasMore => _hasMore;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  String? get selectedId => _selectedId;

  CrabLifecycleEvent? get selected {
    final id = _selectedId;
    if (id == null) return null;
    return _items.where((e) => e.id == id).firstOrNull;
  }

  DateTime? get _periodFrom {
    final d = _period.duration;
    if (d == null) return null;
    return DateTime.now().subtract(d);
  }

  DateTime? get _periodTo => _period.duration == null ? null : DateTime.now();

  bool get hasActiveFilters =>
      _type != CrabHistoryEventFilter.all ||
      _search.trim().isNotEmpty ||
      _period != CrabHistoryPeriod.d7;

  Future<void> load() async {
    final gen = ++_gen;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final page = await api.fetchCrabLifecycleEvents(
        tokenProvider(),
        crabId,
        from: from,
        to: to,
        eventType: _type == CrabHistoryEventFilter.all ? null : _type.api,
        search: _search.trim().isEmpty ? null : _search.trim(),
        sort: _sort == CrabHistorySort.oldest ? 'asc' : 'desc',
        skip: 0,
        take: pageSize,
      );
      if (gen != _gen) return;
      _items
        ..clear()
        ..addAll(page.items);
      _summary = page.summary;
      _total = page.total;
      _hasMore = page.hasMore;
      if (_selectedId == null || _items.every((e) => e.id != _selectedId)) {
        _selectedId = _items.isEmpty ? null : _items.first.id;
      }
    } on CloudApiException catch (e) {
      if (gen != _gen) return;
      _error = e.message;
      _items.clear();
    } catch (e) {
      if (gen != _gen) return;
      _error = '$e';
      _items.clear();
    } finally {
      if (gen == _gen) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final gen = _gen;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await api.fetchCrabLifecycleEvents(
        tokenProvider(),
        crabId,
        from: from,
        to: to,
        eventType: _type == CrabHistoryEventFilter.all ? null : _type.api,
        search: _search.trim().isEmpty ? null : _search.trim(),
        sort: _sort == CrabHistorySort.oldest ? 'asc' : 'desc',
        skip: _items.length,
        take: pageSize,
      );
      if (gen != _gen) return;
      _items.addAll(page.items);
      _hasMore = page.hasMore;
      _total = page.total;
    } on CloudApiException catch (e) {
      if (gen != _gen) return;
      _error = e.message;
    } catch (e) {
      if (gen != _gen) return;
      _error = '$e';
    } finally {
      if (gen == _gen) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<List<CrabLifecycleEvent>> fetchAllForExport() async {
    final page = await api.fetchCrabLifecycleEvents(
      tokenProvider(),
      crabId,
      from: from,
      to: to,
      eventType: _type == CrabHistoryEventFilter.all ? null : _type.api,
      search: _search.trim().isEmpty ? null : _search.trim(),
      sort: _sort == CrabHistorySort.oldest ? 'asc' : 'desc',
      skip: 0,
      take: 500,
    );
    return page.items;
  }

  void setPeriod(CrabHistoryPeriod p) {
    if (_period == p && p != CrabHistoryPeriod.custom) return;
    _period = p;
    if (p != CrabHistoryPeriod.custom) {
      _from = null;
      _to = null;
    }
    load();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _period = CrabHistoryPeriod.custom;
    _from = DateTime(start.year, start.month, start.day);
    _to = DateTime(end.year, end.month, end.day, 23, 59, 59);
    load();
  }

  void setType(CrabHistoryEventFilter t) {
    _type = _type == t && t != CrabHistoryEventFilter.all
        ? CrabHistoryEventFilter.all
        : t;
    load();
  }

  void setSort(CrabHistorySort s) {
    if (_sort == s) return;
    _sort = s;
    load();
  }

  void setSearch(String q) {
    _search = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), load);
  }

  void clearFilters() {
    _debounce?.cancel();
    _period = CrabHistoryPeriod.d7;
    _type = CrabHistoryEventFilter.all;
    _sort = CrabHistorySort.newest;
    _from = null;
    _to = null;
    _search = '';
    load();
  }

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
