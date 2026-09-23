import 'package:flutter/foundation.dart';

import '../models/crab_feeding_activity.dart';
import 'cloud_api_client.dart';

/// State của tab "Ăn & Vận động" cho một con cua: khoảng thời gian, dữ liệu
/// KPI/trend/lịch sử, phân trang & sắp xếp. Dữ liệu 100% từ API.
class CrabFeedingActivityController extends ChangeNotifier {
  CrabFeedingActivityController({
    required this.crabId,
    required this.api,
    required this.tokenProvider,
    this.thresholds = FeedingThresholds.defaults,
  });

  final String crabId;
  final CloudApiClient api;
  final String Function() tokenProvider;
  final FeedingThresholds thresholds;

  FeedingPeriod _period = FeedingPeriod.d7;
  DateTime? _customFrom;
  DateTime? _customTo;
  int _page = 1;
  int _pageSize = 10;
  FeedingSort _sort = FeedingSort.time;
  bool _sortDesc = true;

  CrabFeedingActivityData? _data;
  bool _loading = false;
  bool _tableLoading = false;
  String? _error;
  int _gen = 0;

  FeedingPeriod get period => _period;
  DateTime get from => _period == FeedingPeriod.custom && _customFrom != null
      ? _customFrom!
      : DateTime.now().subtract(_period.duration ?? const Duration(days: 7));
  DateTime get to => _period == FeedingPeriod.custom && _customTo != null
      ? _customTo!
      : DateTime.now();
  int get page => _page;
  int get pageSize => _pageSize;
  FeedingSort get sort => _sort;
  bool get sortDesc => _sortDesc;
  CrabFeedingActivityData? get data => _data;
  bool get loading => _loading;
  bool get tableLoading => _tableLoading;
  String? get error => _error;

  int get totalPages =>
      _data == null ? 1 : (_data!.totalEvents / _pageSize).ceil().clamp(1, 9999);

  /// Danh sách event của trang hiện tại, đã sắp xếp theo lựa chọn.
  List<FeedingEvent> get pageEvents {
    final list = [...?_data?.events];
    int cmp(FeedingEvent a, FeedingEvent b) {
      switch (_sort) {
        case FeedingSort.time:
          return a.time.compareTo(b.time);
        case FeedingSort.feedingPercent:
          return (a.feedingPercent ?? -1).compareTo(b.feedingPercent ?? -1);
        case FeedingSort.served:
          return (a.servedGram ?? -1).compareTo(b.servedGram ?? -1);
        case FeedingSort.activity:
          return (a.activityScore ?? -1).compareTo(b.activityScore ?? -1);
      }
    }
    list.sort((a, b) => _sortDesc ? cmp(b, a) : cmp(a, b));
    return list;
  }

  String get periodLabel {
    if (_period != FeedingPeriod.custom) return '${_period.label} gần nhất';
    String d(DateTime t) =>
        '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
    return '${d(from)} – ${d(to)}';
  }

  Future<void> load({bool tableOnly = false}) async {
    final gen = ++_gen;
    if (tableOnly) {
      _tableLoading = true;
    } else {
      _loading = true;
    }
    _error = null;
    notifyListeners();
    try {
      final result = await api.fetchCrabFeedingActivity(
        tokenProvider(),
        crabId,
        from: from,
        to: to,
        page: _page,
        limit: _pageSize,
      );
      if (gen != _gen) return;
      _data = result;
    } on CloudApiException catch (e) {
      if (gen != _gen) return;
      _error = e.message;
    } catch (e) {
      if (gen != _gen) return;
      _error = 'Không tải được dữ liệu cho ăn: $e';
    } finally {
      if (gen == _gen) {
        _loading = false;
        _tableLoading = false;
        notifyListeners();
      }
    }
  }

  void setPeriod(FeedingPeriod p) {
    if (p == FeedingPeriod.custom) return;
    _period = p;
    _page = 1;
    load();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _period = FeedingPeriod.custom;
    _customFrom = DateTime(start.year, start.month, start.day);
    _customTo = DateTime(end.year, end.month, end.day, 23, 59, 59);
    _page = 1;
    load();
  }

  void setPage(int page) {
    if (page < 1 || page == _page) return;
    _page = page;
    load(tableOnly: true);
  }

  void setPageSize(int size) {
    if (size == _pageSize) return;
    _pageSize = size;
    _page = 1;
    load(tableOnly: true);
  }

  void setSort(FeedingSort sort) {
    if (_sort == sort) {
      _sortDesc = !_sortDesc;
    } else {
      _sort = sort;
      _sortDesc = true;
    }
    notifyListeners();
  }

  Future<String?> addFeeding({
    required String boxId,
    required NewFeedingInput input,
    String? operatorName,
    String? locationLabel,
  }) async {
    try {
      await api.createFeedingEvent(
        tokenProvider(),
        crabId: crabId,
        boxId: boxId,
        input: input,
        operatorName: operatorName,
        locationLabel: locationLabel,
      );
      _page = 1;
      await load();
      return null;
    } on CloudApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Không lưu được lần cho ăn: $e';
    }
  }

  Future<String?> updateNote(FeedingEvent event, String note) async {
    try {
      final updated = await api.updateFeedingNote(tokenProvider(), event.id, note);
      final d = _data;
      if (d != null) {
        final events = d.events
            .map((e) => e.id == event.id ? e.copyWith(note: updated.note ?? note) : e)
            .toList();
        _data = CrabFeedingActivityData(
          from: d.from,
          to: d.to,
          hourly: d.hourly,
          summary: d.summary,
          feedingTrend: d.feedingTrend,
          activityTrend: d.activityTrend,
          events: events,
          totalEvents: d.totalEvents,
          insight: d.insight,
          insightLevel: d.insightLevel,
        );
        notifyListeners();
      }
      return null;
    } on CloudApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Không cập nhật được ghi chú: $e';
    }
  }

  /// Snapshot "hôm nay" cho card ở tab Tổng quan: event gần nhất trong ngày.
  FeedingEvent? get latestEvent {
    final events = _data?.events;
    if (events == null || events.isEmpty) return null;
    return events.reduce((a, b) => a.time.isAfter(b.time) ? a : b);
  }
}
