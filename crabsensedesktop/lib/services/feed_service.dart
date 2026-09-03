import 'package:flutter/foundation.dart';

import '../data/mock_feed_data.dart';
import '../models/auth_models.dart';
import '../models/feed_management.dart';
import '../models/feed_management_overview.dart';
import '../utils/feed_management_mapper.dart';
import 'cloud_api_client.dart';

class FeedService extends ChangeNotifier {
  FeedService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient() {
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  AuthSession _session;
  final CloudApiClient _api;

  final List<FeedInventoryItem> _inventory = [];
  final List<FeedingScheduleItem> _schedule = [];
  final List<BatchFeedConsumption> _batchConsumption = [];
  final List<DailyFeedConsumption> _dailyConsumption = [];
  List<FeedBatchOptionDto> _batchOptions = const [];
  List<String> _areas = const [];
  List<String> _feedTypes = const [];

  FeedKpi? _kpi;
  String _aiInsight = '';
  String _aiRecommendation = '';
  FeedPortionSuggestion? _portion;

  String _search = '';
  bool _fcrByBatch = true;
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  bool loading = false;
  String? error;

  static const milestoneDays = {7, 14, 21, 28};

  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  bool get hasApiData => _kpi != null;

  bool get canCreateSchedule =>
      _batchOptions.any((b) => b.id.isNotEmpty);

  List<String> get areas {
    if (_areas.isNotEmpty) return _areas;
    if (!hasApiData) return const ['Khu A', 'Khu B'];
    return const [];
  }

  List<String> get batchCodes => _batchOptions
      .where((b) => b.id.isNotEmpty)
      .map((b) => b.batchCode)
      .toList();
  List<String> get feedNames =>
      _feedTypes.isNotEmpty ? _feedTypes : MockFeedData.inventory().map((e) => e.name).toList();

  FeedKpi get kpi => _kpi ?? MockFeedData.kpi;
  String get aiInsight =>
      _aiInsight.isNotEmpty ? _aiInsight : MockFeedData.aiInsight;
  String get aiRecommendation =>
      _aiRecommendation.isNotEmpty
          ? _aiRecommendation
          : MockFeedData.aiRecommendation;
  FeedPortionSuggestion get portion =>
      _portion ?? MockFeedData.portionSuggestion();

  bool get fcrByBatch => _fcrByBatch;
  DateTime get focusedMonth => _focusedMonth;
  DateTime get selectedDay => _selectedDay;

  int get feedingStreak => _computeStreak(anchor: DateTime.now());
  int get nextMilestone {
    for (final m in milestoneDays) {
      if (feedingStreak < m) return m;
    }
    return feedingStreak + 7;
  }

  List<BatchFeedConsumption> get batchConsumption =>
      _batchConsumption.isNotEmpty
          ? List.unmodifiable(_batchConsumption)
          : MockFeedData.batchConsumption();

  List<DailyFeedConsumption> get dailyConsumption =>
      _dailyConsumption.isNotEmpty
          ? List.unmodifiable(_dailyConsumption)
          : MockFeedData.dailyConsumption();

  List<FeedInventoryItem> get inventory {
    if (_search.trim().isEmpty) return List.unmodifiable(_inventory);
    final q = _search.toLowerCase();
    return _inventory
        .where(
          (i) =>
              i.code.toLowerCase().contains(q) ||
              i.name.toLowerCase().contains(q),
        )
        .toList();
  }

  List<FeedingScheduleItem> get schedule {
    final day = _selectedDay;
    return _schedule
        .where((s) => _sameDay(s.scheduledDate, day))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<FeedCalendarDayState> calendarDaysForFocusedMonth() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final last = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();

    final completeDays = <DateTime>{};
    for (var d = 1; d <= last; d++) {
      final date = DateTime(year, month, d);
      final items = _schedule.where((s) => _sameDay(s.scheduledDate, date));
      if (items.isEmpty) continue;
      if (items.every((s) => s.completed)) {
        completeDays.add(date);
      }
    }

    final streakMap = _streakSegments(completeDays, year, month);

    return List.generate(last, (i) {
      final day = i + 1;
      final date = DateTime(year, month, day);
      final items =
          _schedule.where((s) => _sameDay(s.scheduledDate, date)).toList();
      final completed = items.where((s) => s.completed).length;
      return FeedCalendarDayState(
        date: date,
        total: items.length,
        completed: completed,
        isToday: _sameDay(date, today),
        isSelected: _sameDay(date, _selectedDay),
        isMilestone:
            milestoneDays.contains(day) && completeDays.contains(date),
        streakSegment: streakMap[day] ?? 'none',
      );
    });
  }

  void updateSession(AuthSession session) {
    _session = session;
    _inventory.clear();
    _schedule.clear();
    _kpi = null;
    error = null;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (loading && !force) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final overview = await _api.fetchFeedManagementOverview(
        token,
        farmId,
        year: _focusedMonth.year,
        month: _focusedMonth.month,
        day: _selectedDay.day,
      );
      _applyOverview(overview);
      error = null;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _applyOverview(FeedManagementOverview overview) {
    _kpi = mapFeedKpi(overview.kpi);
    _aiInsight = overview.aiInsight;
    _aiRecommendation = overview.aiRecommendation;
    _portion = mapFeedPortion(overview.portion);
    _inventory
      ..clear()
      ..addAll(overview.inventory.map(mapFeedInventory));
    _schedule
      ..clear()
      ..addAll(overview.schedules.map(mapFeedSchedule));
    _batchConsumption
      ..clear()
      ..addAll(overview.batchConsumption.map(mapBatchConsumption));
    _dailyConsumption
      ..clear()
      ..addAll(overview.dailyConsumption.map(mapDailyConsumption));
    _areas = overview.areas;
    _batchOptions = overview.batches;
    _feedTypes = overview.feedTypes;
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setFcrView(bool byBatch) {
    _fcrByBatch = byBatch;
    notifyListeners();
  }

  void setFocusedMonth(DateTime month) {
    _focusedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
    load(force: true);
  }

  void previousMonth() {
    setFocusedMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1));
  }

  void nextMonth() {
    setFocusedMonth(DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1));
  }

  void selectDay(DateTime day) {
    _selectedDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
    if (day.month != _focusedMonth.month || day.year != _focusedMonth.year) {
      setFocusedMonth(DateTime(day.year, day.month, 1));
    }
  }

  Future<void> addSchedule({
    required DateTime date,
    required String time,
    required String area,
    required String batchId,
    required String feedName,
    required double portionKg,
    String repeatRule = 'Hàng ngày',
  }) async {
    if (_batchOptions.isEmpty) {
      error = 'Chưa có lứa nuôi trên trại. Tạo lứa nuôi trước khi lập lịch.';
      notifyListeners();
      throw StateError(error!);
    }

    FeedBatchOptionDto? batch;
    for (final b in _batchOptions) {
      if (b.batchCode == batchId || b.id == batchId) {
        batch = b;
        break;
      }
    }
    batch ??= _batchOptions.where((b) => b.areaName == area).firstOrNull;
    batch ??= _batchOptions.first;
    if (batch.id.isEmpty) {
      error = 'Không tìm thấy lứa nuôi. Chọn lại lứa trong danh sách.';
      notifyListeners();
      throw StateError(error!);
    }

    try {
      await _api.createFeedSchedule(
        token,
        farmId,
        batchId: batch.id,
        date:
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        time: time,
        feedName: feedName,
        portionKg: portionKg,
        repeatRule: repeatRule,
      );
      _selectedDay = DateTime(date.year, date.month, date.day);
      _focusedMonth = DateTime(date.year, date.month, 1);
      await load(force: true);
      error = null;
    } catch (e) {
      error = '$e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> importStock(String code, double kg) async {
    await _api.importFeedStock(token, farmId, code: code, kg: kg);
    await load(force: true);
  }

  Future<void> exportStock(String code, double kg) async {
    await _api.exportFeedStock(token, farmId, code: code, kg: kg);
    await load(force: true);
  }

  Future<void> feedNow(String scheduleId) async {
    await _api.completeFeedSchedule(token, farmId, scheduleId);
    await load(force: true);
  }

  Future<void> completeNextSchedule() async {
    final pending = _schedule.where((s) => !s.completed);
    if (pending.isEmpty) return;
    await feedNow(pending.first.id);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _computeStreak({required DateTime anchor}) {
    var streak = 0;
    var d = DateTime(anchor.year, anchor.month, anchor.day);
    while (true) {
      final items = _schedule.where((s) => _sameDay(s.scheduledDate, d));
      if (items.isEmpty || !items.every((s) => s.completed)) break;
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Map<int, String> _streakSegments(
      Set<DateTime> completeDays, int year, int month) {
    final result = <int, String>{};
    final sorted = completeDays
        .where((d) => d.year == year && d.month == month)
        .map((d) => d.day)
        .toList()
      ..sort();

    if (sorted.isEmpty) return result;

    var runStart = sorted.first;
    var prev = sorted.first;
    for (var i = 1; i <= sorted.length; i++) {
      final atEnd = i == sorted.length;
      final day = atEnd ? null : sorted[i];
      if (!atEnd && day == prev + 1) {
        prev = day!;
        continue;
      }
      _assignRun(result, runStart, prev);
      if (!atEnd) {
        runStart = day!;
        prev = day;
      }
    }
    return result;
  }

  void _assignRun(Map<int, String> map, int start, int end) {
    if (start == end) {
      map[start] = 'single';
      return;
    }
    for (var d = start; d <= end; d++) {
      if (d == start) {
        map[d] = 'start';
      } else if (d == end) {
        map[d] = 'end';
      } else {
        map[d] = 'middle';
      }
    }
  }
}
