// ignore_for_file: lines_longer_than_80_chars
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

// â”€â”€ Design tokens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const Color _p = Color(0xFF12A87A); // primary
const Color _pDark = Color(0xFF087F5B);
const Color _pLight = Color(0xFFDDF7EE);
const Color _mint = Color(0xFFF3FBF8);
const Color _surf = Color(0xFFFFFFFF);
const Color _bdr = Color(0xFFD8E9E4);
const Color _txM = Color(0xFF12332D);
const Color _txS = Color(0xFF66847C);
const Color _txH = Color(0xFF94A3B8);
const Color _blue = Color(0xFF2495E8);
const Color _blueL = Color(0xFFDBEDFB);
const Color _amber = Color(0xFFF5B700);
const Color _amberL = Color(0xFFFFF8DC);
const Color _red = Color(0xFFEF4444);
const Color _redL = Color(0xFFFEE2E2);
const Color _greenL = Color(0xFFDCFCE7);
const Color _shadow = Color(0x14000000);

// â”€â”€ Thresholds â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const double _feedWatchThreshold = 50.0; // %
const int _activityLowThreshold = 30;
const int _activityHighThreshold = 71;

// â”€â”€ Period enum â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum _Period { h24, d7, d30, custom }

extension _PeriodX on _Period {
  String get label => switch (this) {
    _Period.h24 => '24 giá»',
    _Period.d7 => '7 ngĂ y',
    _Period.d30 => '30 ngĂ y',
    _Period.custom => 'Tuá»³ chá»‰nh',
  };
  Duration get duration => switch (this) {
    _Period.h24 => const Duration(hours: 24),
    _Period.d7 => const Duration(days: 7),
    _Period.d30 => const Duration(days: 30),
    _Period.custom => const Duration(days: 7),
  };
}

// â”€â”€ Models â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TrendPoint {
  const _TrendPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

class _FeedEvent {
  const _FeedEvent({
    required this.id,
    required this.fedAt,
    required this.foodName,
    required this.servedGram,
    required this.eatenGram,
    required this.feedingPercent,
    required this.activityBefore,
    required this.activityAfter,
    required this.operatorName,
    required this.source,
    this.note,
    this.mediaUrl,
    this.cameraId,
    this.feedingDurationMinutes,
  });

  final String id;
  final DateTime fedAt;
  final String foodName;
  final double servedGram;
  final double eatenGram;
  final double feedingPercent; // 0â€“100
  final int? activityBefore; // 0â€“100
  final int? activityAfter; // 0â€“100
  final String operatorName;
  final String source; // MANUAL | AI_CAMERA | MANUAL_AI | SYSTEM
  final String? note;
  final String? mediaUrl;
  final String? cameraId;
  final int? feedingDurationMinutes;

  factory _FeedEvent.fromJson(Map<String, dynamic> j) {
    double asD(Object? v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
    int? asI(Object? v) => v is int ? v : int.tryParse(v?.toString() ?? '');

    final served = asD(
      j['servedGram'] ?? j['servedAmount'] ?? j['servedWeight'] ?? 0,
    );
    final eaten = asD(
      j['eatenGram'] ?? j['eatenAmount'] ?? j['eatenWeight'] ?? 0,
    );
    final pct = served > 0 ? (eaten / served * 100).clamp(0.0, 100.0) : 0.0;

    final food = j['food'] is Map ? j['food'] as Map : <String, dynamic>{};
    final op = j['operator'] is Map
        ? j['operator'] as Map
        : <String, dynamic>{};

    return _FeedEvent(
      id: (j['id'] ?? '').toString(),
      fedAt:
          DateTime.tryParse(
            (j['fedAt'] ?? j['timestamp'] ?? '').toString(),
          )?.toLocal() ??
          DateTime.now(),
      foodName: (food['name'] ?? j['foodType'] ?? j['food'] ?? 'ChÆ°a ghi')
          .toString(),
      servedGram: served,
      eatenGram: eaten,
      feedingPercent: pct,
      activityBefore: asI(j['activityBefore'] ?? j['activityScoreBefore']),
      activityAfter: asI(j['activityAfter'] ?? j['activityScoreAfter']),
      operatorName: (op['name'] ?? j['operatorName'] ?? j['addedBy'] ?? '')
          .toString(),
      source: (j['source'] ?? 'MANUAL').toString().toUpperCase(),
      note: j['note']?.toString(),
      mediaUrl: _firstMedia(j['mediaUrls'] ?? j['mediaUrl']),
      cameraId: j['cameraId']?.toString(),
      feedingDurationMinutes: asI(
        j['feedingDurationMinutes'] ?? j['durationMinutes'],
      ),
    );
  }

  static String? _firstMedia(dynamic raw) {
    if (raw is List && raw.isNotEmpty) return raw.first.toString();
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }
}

class _Summary {
  const _Summary({
    required this.feedingCount,
    required this.finishRate,
    required this.avgFeedingPercent,
    required this.avgActivityScore,
    this.prevFeedingCount,
    this.prevFinishRate,
  });

  final int feedingCount;
  final double finishRate; // 0â€“100
  final double avgFeedingPercent; // 0â€“100
  final double avgActivityScore; // 0â€“100
  final int? prevFeedingCount;
  final double? prevFinishRate;

  static _Summary compute(List<_FeedEvent> events) {
    if (events.isEmpty)
      return const _Summary(
        feedingCount: 0,
        finishRate: 0,
        avgFeedingPercent: 0,
        avgActivityScore: 0,
      );
    final count = events.length;
    final finished = events.where((e) => e.feedingPercent >= 80).length;
    final avgFeed =
        events.map((e) => e.feedingPercent).reduce((a, b) => a + b) / count;
    final activity = events.where((e) => e.activityAfter != null);
    final avgAct = activity.isEmpty
        ? 0.0
        : activity
                  .map((e) => e.activityAfter!.toDouble())
                  .reduce((a, b) => a + b) /
              activity.length;
    return _Summary(
      feedingCount: count,
      finishRate: count == 0 ? 0 : finished / count * 100,
      avgFeedingPercent: avgFeed,
      avgActivityScore: avgAct,
    );
  }
}

// â”€â”€ Main tab widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class CrabFeedingActivityTab extends StatefulWidget {
  const CrabFeedingActivityTab({required this.crabId, super.key});
  final String crabId;

  @override
  State<CrabFeedingActivityTab> createState() => _CrabFeedingActivityTabState();
}

class _CrabFeedingActivityTabState extends State<CrabFeedingActivityTab> {
  final ApiClient _api = sl<ApiClient>();

  _Period _period = _Period.d7;
  DateTimeRange? _customRange;

  bool _loadingKpi = true;
  bool _loadingCharts = true;
  bool _loadingTable = true;
  // ignore: unused_field
  String? _error;

  _Summary _summary = const _Summary(
    feedingCount: 0,
    finishRate: 0,
    avgFeedingPercent: 0,
    avgActivityScore: 0,
  );
  List<_TrendPoint> _feedingTrend = [];
  List<_TrendPoint> _activityTrend = [];
  List<_FeedEvent> _events = [];
  int _totalEvents = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  // Detail drawer
  _FeedEvent? _detailEvent;

  // Chart hover sync
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // â”€â”€ Date range â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  DateTimeRange get _range {
    if (_period == _Period.custom && _customRange != null) return _customRange!;
    final end = DateTime.now();
    return DateTimeRange(start: end.subtract(_period.duration), end: end);
  }

  String get _rangeLabel {
    final fmt = DateFormat('dd/MM/yyyy');
    return '${fmt.format(_range.start)} â†’ ${fmt.format(_range.end)}';
  }

  // â”€â”€ Fetch â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _fetchAll() async {
    setState(() {
      _loadingKpi = true;
      _loadingCharts = true;
      _loadingTable = true;
      _error = null;
    });
    await Future.wait([_fetchSummary(), _fetchTrends(), _fetchEvents()]);
  }

  Future<void> _fetchSummary() async {
    try {
      // Try dedicated summary endpoint first
      final q = _buildQuery();
      final res = await _api.safeGet<dynamic>(
        '/crabs/${widget.crabId}/feeding-summary',
        queryParameters: q,
      );
      if (res.failure == null && res.data.data != null) {
        final body = _unwrap(res.data.data);
        if (body is Map<String, dynamic>) {
          setState(() {
            _summary = _Summary(
              feedingCount: _asInt(body['feedingCount'] ?? body['count']) ?? 0,
              finishRate:
                  _asDouble(body['finishRate'] ?? body['finishPercent']) ?? 0,
              avgFeedingPercent: _asDouble(body['avgFeedingPercent']) ?? 0,
              avgActivityScore: _asDouble(body['avgActivityScore']) ?? 0,
              prevFeedingCount: _asInt(body['prevFeedingCount']),
              prevFinishRate: _asDouble(body['prevFinishRate']),
            );
            _loadingKpi = false;
          });
          return;
        }
      }
    } catch (_) {}
    // Compute from events list (fallback)
    if (mounted) setState(() => _loadingKpi = false);
  }

  Future<void> _fetchTrends() async {
    try {
      final q = _buildQuery();
      final res = await _api.safeGet<dynamic>(
        '/crabs/${widget.crabId}/feeding-trend',
        queryParameters: q,
      );
      final body = res.failure == null ? _unwrap(res.data.data) : null;
      if (body is Map) {
        final feed =
            (body['feedingTrend'] ?? body['feeding'] ?? const []) as List;
        final act =
            (body['activityTrend'] ?? body['activity'] ?? const []) as List;
        setState(() {
          _feedingTrend = _parseTrend(feed, 'feedingPercent');
          _activityTrend = _parseTrend(act, 'activityScore');
          _loadingCharts = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingCharts = false);
  }

  Future<void> _fetchEvents({int? page}) async {
    setState(() => _loadingTable = true);
    final p = page ?? _currentPage;
    try {
      final q = {..._buildQuery(), 'page': p, 'pageSize': _pageSize};
      final res = await _api.safeGet<dynamic>(
        ApiConstants.operationsForCrab(widget.crabId),
        queryParameters: q.map((k, v) => MapEntry(k, v.toString())),
      );
      final body = res.failure == null ? _unwrap(res.data.data) : null;
      List raw = [];
      int total = 0;
      if (body is Map) {
        raw = (body['items'] ?? body['data'] ?? const []) as List;
        total = _asInt(body['total'] ?? body['count']) ?? raw.length;
      } else if (body is List) {
        raw = body;
        total = body.length;
      }
      final evts = raw
          .whereType<Map<String, dynamic>>()
          .map(_FeedEvent.fromJson)
          .toList();
      if (mounted) {
        setState(() {
          _events = evts;
          _totalEvents = total;
          _currentPage = p;
          _loadingTable = false;
          // If summary not from API, compute from events
          if (_loadingKpi) {
            _summary = _Summary.compute(evts);
            _loadingKpi = false;
          }
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loadingTable = false;
          _error = e.toString();
        });
    }
  }

  Map<String, String> _buildQuery() {
    final r = _range;
    return {'from': r.start.toIso8601String(), 'to': r.end.toIso8601String()};
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchAll,
          color: _p,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context),
                const SizedBox(height: 14),
                _buildKpiRow(),
                const SizedBox(height: 14),
                _buildChartsRow(context),
                _buildAiInsight(),
                const SizedBox(height: 14),
                _buildHistorySection(context),
                const SizedBox(height: 14),
                _buildPagination(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        if (_detailEvent != null)
          _FeedEventDrawer(
            event: _detailEvent!,
            onClose: () => setState(() => _detailEvent = null),
          ),
      ],
    );
  }

  // â”€â”€ Section header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('đŸ´', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Ä‚n & Váº­n Ä‘á»™ng',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _txM,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Theo dĂµi lá»‹ch sá»­ cho Äƒn, má»©c Äƒn vĂ  má»©c Ä‘á»™ váº­n Ä‘á»™ng\ncá»§a cua theo thá»i gian.',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: _txS,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildPeriodChips(),
            const SizedBox(height: 6),
            _buildDateRangeBadge(context),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodChips() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [_Period.h24, _Period.d7, _Period.d30].map((p) {
      final active = _period == p;
      return GestureDetector(
        onTap: () {
          setState(() => _period = p);
          _fetchAll();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? _p : _surf,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? _p : _bdr),
          ),
          child: Text(
            p.label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : _txS,
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildDateRangeBadge(BuildContext context) => GestureDetector(
    onTap: () async {
      final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        initialDateRange:
            _customRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
        builder: (ctx, child) => Theme(
          data: Theme.of(
            ctx,
          ).copyWith(colorScheme: const ColorScheme.light(primary: _p)),
          child: child!,
        ),
      );
      if (r != null && mounted) {
        setState(() {
          _period = _Period.custom;
          _customRange = r;
        });
        _fetchAll();
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _bdr),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 12, color: _txH),
          const SizedBox(width: 5),
          Text(
            _rangeLabel,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: _txS,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  // â”€â”€ KPI row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildKpiRow() {
    if (_loadingKpi) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
        children: List.generate(4, (_) => _KpiSkeleton()),
      );
    }

    final prevCountDiff = _summary.prevFeedingCount != null
        ? _summary.feedingCount - _summary.prevFeedingCount!
        : null;
    final prevFinishDiff = _summary.prevFinishRate != null
        ? _summary.finishRate - _summary.prevFinishRate!
        : null;

    final actLabel = _activityLabel(_summary.avgActivityScore.round());

    return LayoutBuilder(
      builder: (ctx, cons) {
        final cols = cons.maxWidth >= 640 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: cols == 4 ? 1.45 : 1.5,
          children: [
            _KpiCard(
              emoji: 'đŸ´',
              label: 'Láº§n cho Äƒn',
              value: '${_summary.feedingCount}',
              sub: prevCountDiff != null
                  ? '${prevCountDiff >= 0 ? '+' : ''}$prevCountDiff láº§n so vá»›i ${_period == _Period.h24
                        ? '24h'
                        : _period == _Period.d7
                        ? '7 ngĂ y'
                        : '30 ngĂ y'} trÆ°á»›c'
                  : 'Trong ká»³ Ä‘Ă£ chá»n',
              color: _blue,
              bgColor: _blueL,
            ),
            _KpiCard(
              emoji: 'â—”',
              label: 'Tá»· lá»‡ Äƒn háº¿t',
              value: '${_summary.finishRate.toStringAsFixed(0)}%',
              sub: prevFinishDiff != null
                  ? '${prevFinishDiff >= 0 ? '+' : ''}${prevFinishDiff.toStringAsFixed(0)}% so vá»›i ká»³ trÆ°á»›c'
                  : 'Ä‚n >= 80% kháº©u pháº§n',
              color: const Color(0xFF0D9488),
              bgColor: const Color(0xFFCCFBF1),
            ),
            _KpiCard(
              emoji: 'â–¥',
              label: 'Má»©c Äƒn TB',
              value: '${_summary.avgFeedingPercent.toStringAsFixed(0)}%',
              sub: _feedingTrendLabel(_summary.avgFeedingPercent),
              color: _p,
              bgColor: _pLight,
            ),
            _KpiCard(
              emoji: 'ă€½',
              label: 'Váº­n Ä‘á»™ng TB',
              value: '${_summary.avgActivityScore.toStringAsFixed(0)} / 100',
              sub: actLabel,
              color: _activityColor(_summary.avgActivityScore.round()),
              bgColor: _activityBg(_summary.avgActivityScore.round()),
            ),
          ],
        );
      },
    );
  }

  // â”€â”€ Charts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildChartsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, cons) {
        final wide = cons.maxWidth >= 640;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFeedingChart()),
              const SizedBox(width: 12),
              Expanded(child: _buildActivityChart()),
            ],
          );
        }
        return Column(
          children: [
            _buildFeedingChart(),
            const SizedBox(height: 12),
            _buildActivityChart(),
          ],
        );
      },
    );
  }

  Widget _buildFeedingChart() {
    return _ChartCard(
      title: 'Má»©c Äƒn theo thá»i gian',
      legendLabel: 'Má»©c Äƒn (%)',
      legendColor: _p,
      loading: _loadingCharts,
      isEmpty: _feedingTrend.isEmpty,
      emptyMsg: 'ChÆ°a Ä‘á»§ dá»¯ liá»‡u Ä‘á»ƒ táº¡o biá»ƒu Ä‘á»“.',
      child: _FeedLineChart(
        points: _feedingTrend,
        lineColor: _p,
        areaColor: _pLight.withValues(alpha: 0.5),
        yMax: 100,
        yLabels: ['0%', '25%', '50%', '75%', '100%'],
        warningThreshold: _feedWatchThreshold,
        tooltipSuffix: '%',
        tooltipTitle: 'Má»©c Äƒn',
        hoveredIndex: _hoveredIndex,
        onHover: (i) => setState(() => _hoveredIndex = i),
        period: _period,
      ),
    );
  }

  Widget _buildActivityChart() {
    return _ChartCard(
      title: 'Má»©c váº­n Ä‘á»™ng theo thá»i gian',
      legendLabel: 'Váº­n Ä‘á»™ng (Ä‘iá»ƒm)',
      legendColor: _blue,
      loading: _loadingCharts,
      isEmpty: _activityTrend.isEmpty,
      emptyMsg: 'ChÆ°a cĂ³ dá»¯ liá»‡u váº­n Ä‘á»™ng.',
      child: _FeedLineChart(
        points: _activityTrend,
        lineColor: _blue,
        areaColor: _blueL.withValues(alpha: 0.45),
        yMax: 100,
        yLabels: ['0', '25', '50', '75', '100'],
        warningThreshold: _activityLowThreshold.toDouble(),
        tooltipSuffix: '',
        tooltipTitle: 'Váº­n Ä‘á»™ng',
        hoveredIndex: _hoveredIndex,
        onHover: (i) => setState(() => _hoveredIndex = i),
        period: _period,
        labelMapper: (v) => _activityLabel(v.round()),
      ),
    );
  }

  // â”€â”€ AI Insight â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAiInsight() {
    if (_feedingTrend.isEmpty) return const SizedBox.shrink();

    // Detect trend
    final last3 = _feedingTrend.length >= 3
        ? _feedingTrend.sublist(_feedingTrend.length - 3)
        : _feedingTrend;
    final declining =
        last3.length == 3 &&
        last3[0].value > last3[1].value &&
        last3[1].value > last3[2].value &&
        last3[2].value < _feedWatchThreshold;

    final actLow =
        _activityTrend.isNotEmpty &&
        _activityTrend.last.value < _activityLowThreshold;

    final isWarning = declining || actLow;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isWarning ? _amberL : _mint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWarning ? _amber.withValues(alpha: 0.5) : _bdr,
          ),
        ),
        child: Row(
          children: [
            Text(isWarning ? 'â ' : 'âœ¨', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isWarning
                        ? 'AI phĂ¡t hiá»‡n xu hÆ°á»›ng cáº§n theo dĂµi'
                        : 'AI nháº­n Ä‘á»‹nh',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isWarning ? const Color(0xFFB45309) : _pDark,
                    ),
                  ),
                  Text(
                    isWarning
                        ? declining && actLow
                              ? 'Má»©c Äƒn giáº£m 3 láº§n liĂªn tiáº¿p vĂ  váº­n Ä‘á»™ng tháº¥p. NĂªn kiá»ƒm tra tĂ¬nh tráº¡ng cua vĂ  mĂ´i trÆ°á»ng há»™p.'
                              : declining
                              ? 'Má»©c Äƒn giáº£m 3 láº§n liĂªn tiáº¿p. NĂªn kiá»ƒm tra tĂ¬nh tráº¡ng cua.'
                              : 'Váº­n Ä‘á»™ng tháº¥p hÆ¡n ngÆ°á»¡ng bĂ¬nh thÆ°á»ng.'
                        : 'Má»©c Äƒn vĂ  váº­n Ä‘á»™ng cá»§a cua nhĂ¬n chung á»•n Ä‘á»‹nh trong ká»³ Ä‘Ă£ chá»n.',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: isWarning ? const Color(0xFF92400E) : _txS,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ History table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lá»‹ch sá»­ cho Äƒn',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _txM,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${_period == _Period.custom ? 'tuá»³ chá»‰nh' : _period.label} gáº§n nháº¥t)',
              style: GoogleFonts.nunito(fontSize: 12, color: _txH),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem táº¥t cáº£ â†’',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: _p,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Add event button
            ElevatedButton.icon(
              onPressed: () => _showAddFeedingModal(context),
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text(
                'Ghi nháº­n',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _p,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _loadingTable
            ? _TableSkeleton(rows: 5)
            : _events.isEmpty
            ? _buildEmptyState(context)
            : _buildTable(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    decoration: BoxDecoration(
      color: _surf,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _bdr),
    ),
    child: Column(
      children: [
        const Text('đŸ´', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          'ChÆ°a cĂ³ dá»¯ liá»‡u cho Äƒn',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _txM,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'CĂ¡c láº§n cho Äƒn cá»§a cua sáº½ xuáº¥t hiá»‡n táº¡i Ä‘Ă¢y.',
          style: GoogleFonts.nunito(fontSize: 12, color: _txS),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showAddFeedingModal(context),
          icon: const Icon(Icons.add_rounded, size: 14),
          label: Text(
            '+ Ghi nháº­n láº§n cho Äƒn',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _p,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bdr),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _TableHeader(),
          const Divider(height: 1, color: _bdr),
          ..._events.asMap().entries.map(
            (e) => Column(
              children: [
                _TableRow(
                  event: e.value,
                  isEven: e.key.isEven,
                  onTap: () => setState(() => _detailEvent = e.value),
                  onMenu: (offset) => _showRowMenu(context, e.value, offset),
                ),
                if (e.key < _events.length - 1)
                  const Divider(height: 1, color: _bdr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Pagination â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPagination() {
    if (_totalEvents == 0 || _loadingTable) return const SizedBox.shrink();
    final totalPages = (_totalEvents / _pageSize).ceil();
    final start = (_currentPage - 1) * _pageSize + 1;
    final end = (_currentPage * _pageSize).clamp(0, _totalEvents);

    return Row(
      children: [
        Text(
          '$start â€“ $end cá»§a $_totalEvents láº§n cho Äƒn',
          style: GoogleFonts.nunito(fontSize: 12, color: _txS),
        ),
        const Spacer(),
        for (int p = 1; p <= totalPages.clamp(1, 6); p++)
          _PageBtn(
            page: p,
            active: p == _currentPage,
            onTap: () => _fetchEvents(page: p),
          ),
      ],
    );
  }

  // â”€â”€ Add feeding modal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _showAddFeedingModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AddFeedingModal(crabId: widget.crabId, onSaved: _fetchAll),
    );
  }

  // â”€â”€ Row action menu â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _showRowMenu(
    BuildContext ctx,
    _FeedEvent event,
    Offset offset,
  ) async {
    await showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + 200,
        offset.dy + 40,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _surf,
      items: [
        _menuItem('detail', Icons.visibility_outlined, 'Xem chi tiáº¿t láº§n Äƒn'),
        _menuItem('note', Icons.edit_outlined, 'Chá»‰nh sá»­a ghi chĂº'),
        if (event.mediaUrl != null)
          _menuItem('media', Icons.image_outlined, 'Xem hĂ¬nh áº£nh'),
        _menuItem('camera', Icons.videocam_outlined, 'Xem camera liĂªn quan'),
      ],
    ).then((action) {
      if (action == null || !ctx.mounted) return;
      if (action == 'detail') setState(() => _detailEvent = event);
    });
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static dynamic _unwrap(dynamic raw) {
    dynamic body = raw;
    try {
      body = jsonDecode(jsonEncode(raw));
    } catch (_) {}
    if (body is Map && body['data'] != null) return body['data'];
    return body;
  }

  static List<_TrendPoint> _parseTrend(List raw, String key) {
    final out = <_TrendPoint>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final dt = DateTime.tryParse(
        (item['date'] ?? item['timestamp'] ?? '').toString(),
      )?.toLocal();
      final v =
          item[key] ?? item[key.replaceAll('Percent', '')] ?? item['value'];
      if (dt != null && v is num)
        out.add(_TrendPoint(date: dt, value: v.toDouble()));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  static double? _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  String _feedingTrendLabel(double avg) {
    if (_feedingTrend.length < 3) return 'KhĂ´ng Ä‘á»§ dá»¯ liá»‡u';
    final last3 = _feedingTrend.sublist(_feedingTrend.length - 3);
    final isUp = last3.last.value > last3.first.value + 5;
    final isDown = last3.last.value < last3.first.value - 5;
    if (isUp) return 'Xu hÆ°á»›ng tÄƒng';
    if (isDown) return 'Xu hÆ°á»›ng giáº£m';
    return 'á»”n Ä‘á»‹nh';
  }
}

// â”€â”€ KPI card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.bgColor,
  });
  final String emoji;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: _surf,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _bdr),
      boxShadow: const [
        BoxShadow(color: _shadow, blurRadius: 8, offset: Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _txS,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.nunito(fontSize: 10, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    ),
  );
}

class _KpiSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _surf,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _bdr),
    ),
  );
}

// â”€â”€ Chart card wrapper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.legendLabel,
    required this.legendColor,
    required this.loading,
    required this.isEmpty,
    required this.emptyMsg,
    required this.child,
  });
  final String title;
  final String legendLabel;
  final Color legendColor;
  final bool loading;
  final bool isEmpty;
  final String emptyMsg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bdr),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _txM,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: legendColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                legendLabel,
                style: GoogleFonts.nunito(fontSize: 11, color: _txS),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: loading
                ? _ChartSkeleton()
                : isEmpty
                ? Center(
                    child: Text(
                      emptyMsg,
                      style: GoogleFonts.nunito(fontSize: 12, color: _txH),
                      textAlign: TextAlign.center,
                    ),
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: CircularProgressIndicator(color: _p, strokeWidth: 2),
    ),
  );
}

// â”€â”€ Line chart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FeedLineChart extends StatelessWidget {
  const _FeedLineChart({
    required this.points,
    required this.lineColor,
    required this.areaColor,
    required this.yMax,
    required this.yLabels,
    required this.warningThreshold,
    required this.tooltipSuffix,
    required this.tooltipTitle,
    required this.hoveredIndex,
    required this.onHover,
    required this.period,
    this.labelMapper,
  });

  final List<_TrendPoint> points;
  final Color lineColor;
  final Color areaColor;
  final double yMax;
  final List<String> yLabels;
  final double warningThreshold;
  final String tooltipSuffix;
  final String tooltipTitle;
  final int? hoveredIndex;
  final void Function(int?) onHover;
  final _Period period;
  final String Function(double)? labelMapper;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final spots = [
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];

    // Warning markers: indices where value < threshold
    final warnIdx = <int>{};
    for (int i = 0; i < points.length; i++) {
      if (points[i].value < warningThreshold) warnIdx.add(i);
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: yMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yMax / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: _bdr.withValues(alpha: 0.8), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yMax / 4,
              getTitlesWidget: (v, meta) {
                final idx = (v / (yMax / 4)).round().clamp(
                  0,
                  yLabels.length - 1,
                );
                return Text(
                  yLabels[idx],
                  style: GoogleFonts.nunito(fontSize: 9, color: _txH),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: _xInterval(points.length),
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                if (i % _xInterval(points.length).round() != 0)
                  return const SizedBox.shrink();
                final fmt = period == _Period.h24
                    ? DateFormat('HH:mm')
                    : DateFormat('dd/MM');
                return Text(
                  fmt.format(points[i].date),
                  style: GoogleFonts.nunito(fontSize: 9, color: _txH),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: warningThreshold,
              color: _amber.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchCallback: (ev, resp) {
            if (resp?.lineBarSpots?.isNotEmpty == true) {
              onHover(resp!.lineBarSpots!.first.spotIndex);
            } else {
              onHover(null);
            }
          },
          getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes
              .map(
                (i) => TouchedSpotIndicatorData(
                  FlLine(
                    color: lineColor.withValues(alpha: 0.4),
                    strokeWidth: 1,
                    dashArray: [3, 3],
                  ),
                  FlDotData(
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 5,
                      color: lineColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: _txM,
            getTooltipItems: (spots) => spots.map((s) {
              final pt = points[s.spotIndex];
              final dateStr = DateFormat('dd/MM/yyyy').format(pt.date);
              final valStr = '${pt.value.toStringAsFixed(0)}$tooltipSuffix';
              final extra = labelMapper != null
                  ? '\n${labelMapper!(pt.value)}'
                  : '';
              return LineTooltipItem(
                '$dateStr\n$tooltipTitle: $valStr$extra',
                GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: lineColor,
            barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (spot, _, __, i) {
                final isWarning = warnIdx.contains(i);
                final isHovered = hoveredIndex == i;
                return FlDotCirclePainter(
                  radius: isHovered ? 5 : (isWarning ? 4 : 3),
                  color: isWarning ? _amber : lineColor,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: true, color: areaColor),
          ),
        ],
      ),
    );
  }

  static double _xInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    return (count / 6).ceilToDouble();
  }
}

// â”€â”€ Table header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _mint,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TH('THá»œI GIAN', 130),
            _TH('THá»¨C Ä‚N', 100),
            _TH('KHáº¨U PHáº¦N', 90),
            _TH('ÄĂƒ Ä‚N', 80),
            _TH('Má»¨C Ä‚N', 80),
            _TH('Váº¬N Äá»˜NG (T/S)', 130),
            _TH('GHI CHĂ', 100),
            _TH('NGÆ¯á»œI T.HIá»†N', 110),
            _TH('HĂŒNH áº¢NH', 80),
            _TH('THAO TĂC', 70),
          ],
        ),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  const _TH(this.label, this.width);
  final String label;
  final double width;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: _txS,
          letterSpacing: 0.4,
        ),
      ),
    ),
  );
}

// â”€â”€ Table row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.event,
    required this.isEven,
    required this.onTap,
    required this.onMenu,
  });
  final _FeedEvent event;
  final bool isEven;
  final VoidCallback onTap;
  final void Function(Offset) onMenu;

  @override
  Widget build(BuildContext context) {
    final (feedBg, feedFg) = _feedBadge(event.feedingPercent);
    final actLabel =
        '${_activityLabel(event.activityBefore)} â†’ ${_activityLabel(event.activityAfter)}';
    final actColor = _activityColor(event.activityAfter ?? 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isEven ? _surf : _mint.withValues(alpha: 0.4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Thá»i gian
              _TD(
                130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(event.fedAt),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _txM,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(event.fedAt),
                      style: GoogleFonts.nunito(fontSize: 11, color: _txH),
                    ),
                  ],
                ),
              ),
              // Thá»©c Äƒn
              _TD(
                100,
                child: Text(
                  event.foodName,
                  style: GoogleFonts.nunito(fontSize: 12, color: _txM),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Kháº©u pháº§n
              _TD(
                90,
                child: Text(
                  '${event.servedGram.toStringAsFixed(0)} g',
                  style: GoogleFonts.nunito(fontSize: 12, color: _txM),
                ),
              ),
              // ÄĂ£ Äƒn
              _TD(
                80,
                child: Text(
                  '${event.eatenGram.toStringAsFixed(0)} g',
                  style: GoogleFonts.nunito(fontSize: 12, color: _txM),
                ),
              ),
              // Má»©c Äƒn badge
              _TD(
                80,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: feedBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${event.feedingPercent.toStringAsFixed(0)}%',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: feedFg,
                    ),
                  ),
                ),
              ),
              // Váº­n Ä‘á»™ng
              _TD(
                130,
                child: Text(
                  actLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: actColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Ghi chĂº
              _TD(
                100,
                child: Text(
                  event.note?.isNotEmpty == true ? event.note! : 'â€”',
                  style: GoogleFonts.nunito(fontSize: 11, color: _txS),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // NgÆ°á»i thá»±c hiá»‡n
              _TD(
                110,
                child: Text(
                  event.source.contains('AI') &&
                          (event.operatorName.isEmpty ||
                              event.operatorName == 'System')
                      ? 'AI Camera'
                      : event.operatorName.isNotEmpty
                      ? event.operatorName
                      : event.source,
                  style: GoogleFonts.nunito(fontSize: 11, color: _txS),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // HĂ¬nh áº£nh
              _TD(
                80,
                child: event.mediaUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          event.mediaUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            size: 18,
                            color: _txH,
                          ),
                        ),
                      )
                    : Text(
                        'â€”',
                        style: GoogleFonts.nunito(fontSize: 12, color: _txH),
                      ),
              ),
              // Thao tĂ¡c
              _TD(
                70,
                child: GestureDetector(
                  onTapDown: (d) => onMenu(d.globalPosition),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: _txH,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TD extends StatelessWidget {
  const _TD(this.width, {required this.child});
  final double width;
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
    ),
  );
}

// â”€â”€ Table skeleton â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton({required this.rows});
  final int rows;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _surf,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _bdr),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(height: 36, color: _mint),
        const Divider(height: 1, color: _bdr),
        for (int i = 0; i < rows; i++)
          Column(
            children: [
              Container(
                height: 52,
                color: i.isEven ? _surf : _mint.withValues(alpha: 0.4),
              ),
              const Divider(height: 1, color: _bdr),
            ],
          ),
      ],
    ),
  );
}

// â”€â”€ Feed event detail drawer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FeedEventDrawer extends StatelessWidget {
  const _FeedEventDrawer({required this.event, required this.onClose});
  final _FeedEvent event;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final (_, feedFg) = _feedBadge(event.feedingPercent);

    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: MediaQuery.sizeOf(context).width >= 700
          ? 320
          : MediaQuery.sizeOf(context).width,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: const BoxDecoration(
            color: _surf,
            border: Border(left: BorderSide(color: _bdr)),
            boxShadow: [
              BoxShadow(color: _shadow, blurRadius: 16, offset: Offset(-4, 0)),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: const BoxDecoration(
                  color: _mint,
                  border: Border(bottom: BorderSide(color: _bdr)),
                ),
                child: Row(
                  children: [
                    const Text('đŸ´', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chi tiáº¿t láº§n cho Äƒn',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _txM,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: _txS,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DrawerRow(
                        'Thá»i gian',
                        DateFormat('dd/MM/yyyy HH:mm').format(event.fedAt),
                      ),
                      _DrawerRow('Thá»©c Äƒn', event.foodName),
                      _DrawerRow(
                        'Kháº©u pháº§n',
                        '${event.servedGram.toStringAsFixed(0)} g',
                      ),
                      _DrawerRow(
                        'ÄĂ£ Äƒn',
                        '${event.eatenGram.toStringAsFixed(0)} g',
                      ),
                      _DrawerRow(
                        'Thá»©c Äƒn dÆ°',
                        '${(event.servedGram - event.eatenGram).clamp(0, double.infinity).toStringAsFixed(0)} g',
                      ),
                      _DrawerRow(
                        'Má»©c Äƒn',
                        '',
                        badge: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _feedBadge(event.feedingPercent).$1,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${event.feedingPercent.toStringAsFixed(0)}%',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: feedFg,
                            ),
                          ),
                        ),
                      ),
                      if (event.feedingDurationMinutes != null)
                        _DrawerRow(
                          'Thá»i gian Äƒn',
                          '${event.feedingDurationMinutes} phĂºt',
                        ),
                      const Divider(height: 20, color: _bdr),
                      if (event.activityBefore != null)
                        _DrawerRow(
                          'Váº­n Ä‘á»™ng trÆ°á»›c Äƒn',
                          '${event.activityBefore} / 100  ${_activityLabel(event.activityBefore)}',
                        ),
                      if (event.activityAfter != null)
                        _DrawerRow(
                          'Váº­n Ä‘á»™ng sau Äƒn',
                          '${event.activityAfter} / 100  ${_activityLabel(event.activityAfter)}',
                        ),
                      const Divider(height: 20, color: _bdr),
                      _DrawerRow(
                        'NgÆ°á»i thá»±c hiá»‡n',
                        event.operatorName.isNotEmpty
                            ? event.operatorName
                            : 'â€”',
                      ),
                      _DrawerRow('Nguá»“n', _sourceLabel(event.source)),
                      if (event.cameraId != null && event.cameraId!.isNotEmpty)
                        _DrawerRow('Camera', event.cameraId!),
                      _DrawerRow(
                        'Ghi chĂº',
                        event.note?.isNotEmpty == true ? event.note! : 'â€”',
                      ),
                      if (event.mediaUrl != null) ...[
                        const Divider(height: 20, color: _bdr),
                        Text(
                          'HĂ¬nh áº£nh / Video',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _txM,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            event.mediaUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 160,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              color: _mint,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: _txH,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: Text(
                            'Xem video Ä‘áº§y Ä‘á»§ â†—',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _p,
                            side: const BorderSide(color: _bdr),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'KhĂ´ng cĂ³ hĂ¬nh áº£nh/video cho láº§n cho Äƒn nĂ y.',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: _txH,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow(this.label, this.value, {this.badge});
  final String label;
  final String value;
  final Widget? badge;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.nunito(fontSize: 12, color: _txS),
          ),
        ),
        badge ??
            Expanded(
              child: Text(
                value.isEmpty ? 'â€”' : value,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _txM,
                ),
              ),
            ),
      ],
    ),
  );
}

// â”€â”€ Add feeding modal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AddFeedingModal extends StatefulWidget {
  const _AddFeedingModal({required this.crabId, required this.onSaved});
  final String crabId;
  final VoidCallback onSaved;
  @override
  State<_AddFeedingModal> createState() => _AddFeedingModalState();
}

class _AddFeedingModalState extends State<_AddFeedingModal> {
  final _servedCtrl = TextEditingController();
  final _eatenCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _fedAt = DateTime.now();
  String _foodType = 'CĂ¡ táº¡p';
  int? _actBefore;
  int? _actAfter;
  bool _saving = false;
  String? _validError;

  double get _feedPct {
    final s = double.tryParse(_servedCtrl.text) ?? 0;
    final e = double.tryParse(_eatenCtrl.text) ?? 0;
    if (s <= 0) return 0;
    return (e / s * 100).clamp(0, 100);
  }

  void _validate() {
    final s = double.tryParse(_servedCtrl.text) ?? 0;
    final e = double.tryParse(_eatenCtrl.text) ?? 0;
    if (s <= 0) {
      setState(() => _validError = 'Kháº©u pháº§n pháº£i > 0');
      return;
    }
    if (e < 0) {
      setState(() => _validError = 'LÆ°á»£ng Äƒn khĂ´ng Ä‘Æ°á»£c Ă¢m');
      return;
    }
    if (e > s) {
      setState(
        () => _validError = 'â  LÆ°á»£ng Ä‘Ă£ Äƒn khĂ´ng Ä‘Æ°á»£c lá»›n hÆ¡n kháº©u pháº§n.',
      );
      return;
    }
    setState(() => _validError = null);
  }

  Future<void> _save() async {
    _validate();
    if (_validError != null) return;
    final s = double.tryParse(_servedCtrl.text) ?? 0;
    final e = double.tryParse(_eatenCtrl.text) ?? 0;
    setState(() => _saving = true);
    try {
      final api = sl<ApiClient>();
      await api.safePost<dynamic>(
        ApiConstants.operationsForCrab(widget.crabId),
        data: {
          'fedAt': _fedAt.toIso8601String(),
          'foodType': _foodType,
          'servedGram': s,
          'eatenGram': e,
          'feedingPercent': _feedPct,
          if (_actBefore != null) 'activityBefore': _actBefore,
          if (_actAfter != null) 'activityAfter': _actAfter,
          'note': _noteCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lá»—i: $e', style: GoogleFonts.nunito()),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = _feedPct;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _surf,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _bdr,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Ghi nháº­n cho Äƒn',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _txM,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: _txS),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _bdr),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Thá»i gian *'),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: ctx,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                          initialDateRange: DateTimeRange(
                            start: _fedAt,
                            end: _fedAt,
                          ),
                        );
                        if (picked != null && mounted)
                          setState(() => _fedAt = picked.start);
                      },
                      child: _InputBox(
                        DateFormat('dd/MM/yyyy HH:mm').format(_fedAt),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Label('Loáº¡i thá»©c Äƒn *'),
                    _DropdownField(
                      value: _foodType,
                      items: const [
                        'CĂ¡ táº¡p',
                        'TĂ´m',
                        'Cua nhá»',
                        'Thá»©c Äƒn cĂ´ng nghiá»‡p',
                        'KhĂ¡c',
                      ],
                      onChanged: (v) => setState(() => _foodType = v!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Kháº©u pháº§n (g) *'),
                              _TextField(
                                ctrl: _servedCtrl,
                                hint: 'vd: 10',
                                onChanged: (_) {
                                  _validate();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('LÆ°á»£ng Ä‘Ă£ Äƒn (g)'),
                              _TextField(
                                ctrl: _eatenCtrl,
                                hint: 'vd: 9',
                                onChanged: (_) {
                                  _validate();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_validError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _validError!,
                          style: GoogleFonts.nunito(fontSize: 11, color: _red),
                        ),
                      ),
                    if (_servedCtrl.text.isNotEmpty &&
                        _eatenCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _mint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _bdr),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calculate_outlined,
                              size: 14,
                              color: _txH,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Má»©c Äƒn tá»± tĂ­nh: ${pct.toStringAsFixed(0)}%',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _p,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Váº­n Ä‘á»™ng trÆ°á»›c Äƒn (0â€“100)'),
                              _TextField(
                                ctrl: TextEditingController(
                                  text: _actBefore?.toString(),
                                ),
                                hint: 'vd: 62',
                                onChanged: (v) => setState(
                                  () => _actBefore = int.tryParse(v),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Váº­n Ä‘á»™ng sau Äƒn (0â€“100)'),
                              _TextField(
                                ctrl: TextEditingController(
                                  text: _actAfter?.toString(),
                                ),
                                hint: 'vd: 78',
                                onChanged: (v) =>
                                    setState(() => _actAfter = int.tryParse(v)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Label('Ghi chĂº'),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      style: GoogleFonts.nunito(fontSize: 13, color: _txM),
                      decoration: _inputDeco('Nháº­p ghi chĂº...'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _txS,
                              side: const BorderSide(color: _bdr),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Há»§y',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _p,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'LÆ°u láº§n cho Äƒn',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _servedCtrl.dispose();
    _eatenCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
}

// â”€â”€ Pagination button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.page,
    required this.active,
    required this.onTap,
  });
  final int page;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: active ? _p : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: active ? _p : _bdr),
      ),
      child: Center(
        child: Text(
          '$page',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : _txM,
          ),
        ),
      ),
    ),
  );
}

// â”€â”€ Shared helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

String _activityLabel(int? v) {
  if (v == null) return 'â€”';
  if (v <= _activityLowThreshold) return 'Tháº¥p';
  if (v >= _activityHighThreshold) return 'Cao';
  return 'BĂ¬nh thÆ°á»ng';
}

Color _activityColor(int v) {
  if (v <= _activityLowThreshold) return const Color(0xFFEF4444);
  if (v >= _activityHighThreshold) return const Color(0xFF22C55E);
  return const Color(0xFF2495E8);
}

Color _activityBg(int v) {
  if (v <= _activityLowThreshold) return const Color(0xFFFEE2E2);
  if (v >= _activityHighThreshold) return const Color(0xFFDCFCE7);
  return const Color(0xFFDBEDFB);
}

(Color, Color) _feedBadge(double pct) {
  if (pct >= 80) return (_greenL, _pDark);
  if (pct >= 50) return (_amberL, const Color(0xFFB45309));
  if (pct > 0) return (const Color(0xFFFEE9D0), const Color(0xFFEA580C));
  return (_redL, _red);
}

String _sourceLabel(String raw) => switch (raw) {
  'AI_CAMERA' => 'AI Camera',
  'MANUAL_AI' => 'Manual + AI Camera',
  'SYSTEM' => 'Há»‡ thá»‘ng',
  _ => 'Thá»§ cĂ´ng',
};

PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
    PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 16, color: _txS),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _txM,
            ),
          ),
        ],
      ),
    );

InputDecoration _inputDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: GoogleFonts.nunito(fontSize: 12, color: _txH),
  filled: true,
  fillColor: _mint,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _bdr),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _bdr),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _p, width: 1.5),
  ),
);

// â”€â”€ Small form helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _txS,
      ),
    ),
  );
}

class _InputBox extends StatelessWidget {
  const _InputBox(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _bdr),
    ),
    child: Row(
      children: [
        const Icon(Icons.calendar_today_outlined, size: 14, color: _txH),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.nunito(fontSize: 13, color: _txM)),
      ],
    ),
  );
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.ctrl,
    required this.hint,
    required this.onChanged,
  });
  final TextEditingController ctrl;
  final String hint;
  final void Function(String) onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    onChanged: onChanged,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: GoogleFonts.nunito(fontSize: 13, color: _txM),
    decoration: _inputDeco(hint),
  );
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    isDense: true,
    items: items
        .map(
          (i) => DropdownMenuItem(
            value: i,
            child: Text(
              i,
              style: GoogleFonts.nunito(fontSize: 13, color: _txM),
            ),
          ),
        )
        .toList(),
    onChanged: onChanged,
    decoration: _inputDeco(''),
    style: GoogleFonts.nunito(fontSize: 13, color: _txM),
    dropdownColor: _surf,
  );
}

