import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/datasources/box_remote_data_source.dart';

/// Real-data history shown inside the box details history tab.
class BoxHistorySections extends StatefulWidget {
  const BoxHistorySections({required this.boxId, super.key});

  final String boxId;

  @override
  State<BoxHistorySections> createState() => _BoxHistorySectionsState();
}

class _BoxHistorySectionsState extends State<BoxHistorySections> {
  bool _loading = true;
  String? _error;
  List<_FeedingRecord> _feeding = const [];
  List<_HistoryEvent> _events = const [];
  List<_GrowthMolt> _growth = const [];
  List<_GrowthPoint> _weights = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = sl<ApiClient>();
      var crabs = <dynamic>[];
      try {
        crabs = await sl<BoxRemoteDataSource>().getCrabsByBox(widget.boxId);
      } catch (_) {}
      final crabId = crabs.isNotEmpty ? crabs.first.id : '';
      final fetches = <Future<dynamic>>[
        api.get<dynamic>(
          ApiConstants.operationsForBox(widget.boxId),
          queryParameters: const {'page': 1, 'limit': 80},
        ),
        api.get<dynamic>(ApiConstants.boxTimeline(widget.boxId)),
      ];
      if (crabId.isNotEmpty) {
        fetches.add(
          api.get<dynamic>(
            ApiConstants.operationsForCrab(crabId),
            queryParameters: const {'page': 1, 'limit': 80},
          ),
        );
      }
      final responses = await Future.wait<dynamic>(fetches);
      final operations = _mergeOps(
        _asList(responses[0].data),
        responses.length > 2 ? _asList(responses[2].data) : const [],
      );
      final feeding =
          operations.map(_parseFeeding).whereType<_FeedingRecord>().toList()
            ..sort((a, b) => b.at.compareTo(a.at));
      final events =
          _asList(
              responses[1].data,
            ).map(_parseEvent).whereType<_HistoryEvent>().toList()
            ..sort((a, b) => b.at.compareTo(a.at));
      var growth = <_GrowthMolt>[];
      var weights = <_GrowthPoint>[];
      try {
        if (crabId.isNotEmpty) {
          final extra = await Future.wait<dynamic>([
            api.get<dynamic>(ApiConstants.crabMoltings(crabId)),
            api.get<dynamic>(ApiConstants.crabWeights(crabId)),
          ]);
          growth = _asList(extra[0].data)
              .map(_parseGrowth)
              .whereType<_GrowthMolt>()
              .toList()
            ..sort((a, b) => b.at.compareTo(a.at));
          weights = _asList(extra[1].data)
              .map(_parseWeight)
              .whereType<_GrowthPoint>()
              .toList()
            ..sort((a, b) => a.at.compareTo(b.at));
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _feeding = feeding;
        _events = events;
        _growth = growth;
        _weights = weights;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  static DateTime get _windowStart {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).subtract(const Duration(days: 6));
  }

  static List<_FeedingRecord> _last7(List<_FeedingRecord> all) =>
      all.where((r) => !r.at.isBefore(_windowStart)).toList();

  /// Một điểm / ngày trong 7 ngày — trục ngang đọc được, không chồng 29/09.
  static List<_FeedingRecord> _onePerDayLast7(List<_FeedingRecord> all) {
    final now = DateTime.now();
    final out = <_FeedingRecord>[];
    for (var i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final ofDay = all
          .where(
            (e) =>
                e.at.year == d.year &&
                e.at.month == d.month &&
                e.at.day == d.day,
          )
          .toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      if (ofDay.isNotEmpty) out.add(ofDay.last);
    }
    return out;
  }

  static List<dynamic> _mergeOps(List<dynamic> a, List<dynamic> b) {
    if (b.isEmpty) return a;
    final seen = <String>{};
    final out = <dynamic>[];
    void add(dynamic raw) {
      if (raw is! Map) return;
      final id = (raw['id'] ?? raw['Id'] ?? '').toString();
      final key = id.isNotEmpty
          ? id
          : '${raw['timestamp'] ?? raw['Timestamp']}|${raw['notes'] ?? raw['Notes']}';
      if (!seen.add(key)) return;
      out.add(raw);
    }

    for (final item in a) {
      add(item);
    }
    for (final item in b) {
      add(item);
    }
    return out;
  }

  static List<dynamic> _asList(dynamic raw) {
    dynamic body = raw;
    try {
      body = jsonDecode(jsonEncode(raw));
    } catch (_) {}
    if (body is Map) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map) {
        final items =
            data['items'] ??
            data['results'] ??
            data['events'] ??
            data['timeline'];
        if (items is List) return items;
      }
      final items =
          body['items'] ?? body['results'] ?? body['events'] ?? body['timeline'];
      if (items is List) return items;
    }
    return body is List ? body : const [];
  }

  static _FeedingRecord? _parseFeeding(dynamic raw) {
    if (raw is! Map) return null;
    final type = (raw['type'] ?? raw['Type'] ?? '').toString().toLowerCase();
    if (type.isNotEmpty &&
        !type.contains('feed') &&
        type != 'operation' &&
        type != 'inspection') {
      return null;
    }
    final at = DateTime.tryParse(
      (raw['timestamp'] ?? raw['Timestamp'] ?? raw['createdAt'] ?? '')
          .toString(),
    )?.toLocal();
    if (at == null) return null;
    final notes = (raw['notes'] ?? raw['Notes'] ?? '').toString();
    final quantity = raw['quantity'] ?? raw['Quantity'];
    final grams = quantity is num
        ? quantity.toDouble()
        : double.tryParse(quantity?.toString() ?? '') ??
              _number(_line(notes, 'Lượng:')) ??
              _number(_line(notes, 'Bao nhiêu gam')) ??
              _gramsFromNotes(notes);
    return _FeedingRecord(
      at: at,
      foodType: _foodType(
        _value(raw, 'foodType', 'FoodType') ?? _line(notes, 'Thức ăn:'),
      ),
      grams: grams != null && grams > 0 ? grams : null,
      appetite: _appetite(
        _value(raw, 'appetite', 'Appetite') ??
            _line(notes, 'Mức ăn:') ??
            _line(notes, 'Ăn:'),
      ),
      activity: _activity(
        _value(raw, 'activity', 'Activity') ?? _line(notes, 'Hoạt động:'),
      ),
    );
  }

  static _HistoryEvent? _parseEvent(dynamic raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse(
      (raw['timestamp'] ?? raw['at'] ?? raw['date'] ?? raw['createdAt'] ?? '')
          .toString(),
    )?.toLocal();
    if (at == null) return null;
    final kind = (raw['type'] ?? raw['kind'] ?? raw['eventType'] ?? '')
        .toString();
    final title = _eventTitle(kind, raw);
    if (title == null) return null;
    return _HistoryEvent(
      at: at,
      kind: kind,
      title: title,
      detail: _eventDetail(
        _value(raw, 'description', 'detail') ?? _value(raw, 'notes', 'Notes'),
      ),
    );
  }

  static _GrowthMolt? _parseGrowth(dynamic raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse(
      (raw['moltTime'] ?? raw['MoltTime'] ?? raw['createdAt'] ?? '').toString(),
    )?.toLocal();
    if (at == null) return null;
    return _GrowthMolt(
      at: at,
      weightBefore: _asNum(raw['weightBeforeGram'] ?? raw['WeightBeforeGram']),
      weightAfter: _asNum(raw['weightAfterGram'] ?? raw['WeightAfterGram']),
      lengthBefore:
          _asNum(raw['shellLengthBeforeMm'] ?? raw['ShellLengthBeforeMm']),
      lengthAfter:
          _asNum(raw['shellLengthAfterMm'] ?? raw['ShellLengthAfterMm']),
      widthBefore:
          _asNum(raw['shellWidthBeforeMm'] ?? raw['ShellWidthBeforeMm']),
      widthAfter: _asNum(raw['shellWidthAfterMm'] ?? raw['ShellWidthAfterMm']),
    );
  }

  static _GrowthPoint? _parseWeight(dynamic raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse(
      (raw['measuredAt'] ?? raw['MeasuredAt'] ?? '').toString(),
    )?.toLocal();
    final grams = _asNum(raw['weightGram'] ?? raw['WeightGram']);
    if (at == null || grams == null) return null;
    return _GrowthPoint(
      at: at,
      grams: grams,
      length: _asNum(raw['carapaceLengthMm'] ?? raw['CarapaceLengthMm']),
      width: _asNum(raw['carapaceWidthMm'] ?? raw['CarapaceWidthMm']),
    );
  }

  static double? _asNum(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String? _eventTitle(String kind, Map raw) {
    final value = kind.toLowerCase();
    if (value.contains('stock') ||
        value.contains('add') ||
        value.contains('put')) {
      return 'Nhập cua vào hộp';
    }
    if (value.contains('feed')) return 'Cho ăn';
    if (value.contains('molt') || value.contains('lột')) return 'Lột xác';
    if (value.contains('transfer') ||
        value.contains('move') ||
        value.contains('allocation')) {
      return 'Chuyển hộp';
    }
    if (value.contains('harvest') || value.contains('thu')) return 'Thu hoạch';
    if (value.contains('death') ||
        value.contains('dead') ||
        value.contains('chết')) {
      return 'Cua chết';
    }
    return _value(raw, 'title', 'Title');
  }

  static String? _value(Map raw, String first, String second) {
    final value = raw[first] ?? raw[second];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double? _gramsFromNotes(String notes) {
    final match = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*g\b',
      caseSensitive: false,
    ).firstMatch(notes);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  static String? _line(String notes, String prefix) {
    for (final line in notes.split('\n')) {
      final text = line.trim();
      if (text.startsWith(prefix)) return text.substring(prefix.length).trim();
    }
    return null;
  }

  static double? _number(String? value) => value == null
      ? null
      : double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));

  static String? _appetite(String? value) {
    if (value == null) return null;
    final text = value.trim();
    final normalized = text.toLowerCase();
    if (normalized.contains('many') ||
        normalized.contains('much') ||
        normalized.contains('good') ||
        normalized.contains('nhiều')) {
      return 'Ăn nhiều';
    }
    if (normalized.contains('little') ||
        normalized.contains('few') ||
        normalized.contains(' ít')) {
      return 'Ăn ít';
    }
    if (normalized.contains('none') ||
        normalized.contains('nothing') ||
        normalized.contains('no eat') ||
        normalized.contains('không')) {
      return 'Không ăn';
    }
    return text;
  }

  static String? _activity(String? value) {
    if (value == null) return null;
    final text = value.trim();
    final normalized = text.toLowerCase();
    if (normalized.contains('move') ||
        normalized.contains('transfer') ||
        normalized.contains('di chuyển')) {
      return normalized.contains('many') || normalized.contains('nhiều')
          ? 'Di chuyển nhiều'
          : 'Di chuyển';
    }
    if (normalized.contains('corner') ||
        normalized.contains('hide') ||
        normalized.contains('chui') ||
        normalized.contains('góc')) {
      return 'Ít di chuyển';
    }
    if (normalized.contains('no reaction') ||
        normalized.contains('inactive') ||
        normalized.contains('không phản ứng')) {
      return 'Không di chuyển';
    }
    return text;
  }

  static String? _foodType(String? value) {
    if (value == null) return null;
    final text = value.trim();
    final normalized = text.toLowerCase();
    const translations = {
      'fish': 'Cá',
      'shrimp': 'Tôm',
      'crab': 'Cua',
      'pellet': 'Thức ăn viên',
      'pellets': 'Thức ăn viên',
      'mussel': 'Vẹm',
      'clam': 'Nghêu',
      'squid': 'Mực',
    };
    return translations[normalized] ?? text;
  }

  static String? _eventDetail(String? value) {
    if (value == null) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    return _activity(text) ?? _foodType(text) ?? text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HistoryCard(
          title: 'Lịch sử cho ăn',
          icon: Icons.restaurant_outlined,
          child: _loading
              ? const _HistoryLoading()
              : _feeding.isEmpty
              ? const _EmptyHistory('Chưa có dữ liệu cho ăn.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FeedingSummary(records: _last7(_feeding)),
                    const SizedBox(height: 14),
                    _FeedingChart(records: _onePerDayLast7(_feeding)),
                    const SizedBox(height: 14),
                    _ActivityChart(records: _onePerDayLast7(_feeding)),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _HistoryCard(
          title: 'Tăng trưởng',
          icon: Icons.show_chart_rounded,
          child: _loading
              ? const _HistoryLoading()
              : _growth.isEmpty && _weights.isEmpty
              ? const _EmptyHistory(
                  'Đây là cân nặng và kích thước cua (sau lột hoặc cân tay). '
                  'Hộp này chưa ghi lần cân / phiếu lột nên chưa có số.',
                )
              : _GrowthSection(molts: _growth, weights: _weights),
        ),
        const SizedBox(height: 12),
        _HistoryCard(
          title: 'Lịch sử hộp',
          icon: Icons.timeline_rounded,
          child: _loading
              ? const _HistoryLoading()
              : _events.isEmpty
              ? const _EmptyHistory('Chưa có sự kiện của hộp.')
              : _EventTimeline(events: _events),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Không thể tải lịch sử: $_error',
              style: const TextStyle(color: kHomeDanger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _GrowthMolt {
  const _GrowthMolt({
    required this.at,
    this.weightBefore,
    this.weightAfter,
    this.lengthBefore,
    this.lengthAfter,
    this.widthBefore,
    this.widthAfter,
  });
  final DateTime at;
  final double? weightBefore;
  final double? weightAfter;
  final double? lengthBefore;
  final double? lengthAfter;
  final double? widthBefore;
  final double? widthAfter;
}

class _GrowthPoint {
  const _GrowthPoint({
    required this.at,
    required this.grams,
    this.length,
    this.width,
  });
  final DateTime at;
  final double grams;
  final double? length;
  final double? width;
}

class _GrowthSection extends StatelessWidget {
  const _GrowthSection({required this.molts, required this.weights});
  final List<_GrowthMolt> molts;
  final List<_GrowthPoint> weights;

  @override
  Widget build(BuildContext context) {
    final points = weights.isNotEmpty
        ? weights
        : [
            for (final molt in [...molts]..sort((a, b) => a.at.compareTo(b.at)))
              if (molt.weightAfter != null)
                _GrowthPoint(
                  at: molt.at,
                  grams: molt.weightAfter!,
                  length: molt.lengthAfter,
                  width: molt.widthAfter,
                ),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (points.length >= 2) ...[
          const Text(
            'Khối lượng theo lần đo',
            style: TextStyle(
              color: kHomeTextMain,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: kHomeBorder, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: points.length > 6
                          ? (points.length / 4).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('dd/MM').format(points[i].at),
                            style: const TextStyle(
                              fontSize: 9,
                              color: kHomeTextSub,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].grams),
                    ],
                    isCurved: true,
                    color: kHomePrimary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final molt in molts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${DateFormat('dd/MM HH:mm').format(molt.at)}  '
              '${_pair(molt.weightBefore, molt.weightAfter, 'g')}  '
              '${_pair(molt.lengthBefore, molt.lengthAfter, 'mm dài')}  '
              '${_pair(molt.widthBefore, molt.widthAfter, 'mm rộng')}',
              style: const TextStyle(
                color: kHomeTextMain,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }

  static String _pair(double? before, double? after, String unit) {
    if (before == null && after == null) return '';
    final a = after == null ? '—' : after.toStringAsFixed(after % 1 == 0 ? 0 : 1);
    if (before == null) return '$a $unit';
    final b = before.toStringAsFixed(before % 1 == 0 ? 0 : 1);
    final delta = after == null ? '' : ' (${after - before >= 0 ? '+' : ''}${(after - before).toStringAsFixed(1)})';
    return '$b → $a $unit$delta';
  }
}

class _FeedingRecord {
  const _FeedingRecord({
    required this.at,
    this.foodType,
    this.grams,
    this.appetite,
    this.activity,
  });
  final DateTime at;
  final String? foodType;
  final double? grams;
  final String? appetite;
  final String? activity;
}

class _HistoryEvent {
  const _HistoryEvent({
    required this.at,
    required this.kind,
    required this.title,
    this.detail,
  });
  final DateTime at;
  final String kind;
  final String title;
  final String? detail;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kHomeSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kHomeBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: kHomePrimaryDark),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: kHomeTextMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _FeedingSummary extends StatelessWidget {
  const _FeedingSummary({required this.records});
  final List<_FeedingRecord> records;

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(
      0,
      (sum, item) => sum + (item.grams ?? 0),
    );
    final amount = total == total.roundToDouble()
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kHomePrimaryBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kHomePrimary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.scale_outlined, color: kHomePrimaryDark, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tổng lượng thức ăn (7 ngày)',
              style: const TextStyle(
                color: kHomeTextSub,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$amount g',
            style: const TextStyle(
              color: kHomePrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedingChart extends StatelessWidget {
  const _FeedingChart({required this.records});
  final List<_FeedingRecord> records;

  static double? _appetiteScore(String? appetite) {
    final text = (appetite ?? '').toLowerCase();
    if (text.contains('không')) return 0;
    if (text.contains('ít') || text.contains('little')) return 1;
    if (text.contains('nhiều') || text.contains('many')) return 3;
    if (text.isEmpty) return null;
    return 2;
  }

  static String _appetiteLabel(double score) => switch (score.round()) {
        0 => 'Không ăn',
        1 => 'Ít',
        2 => 'Vừa',
        3 => 'Nhiều',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final byTime = [...records]..sort((a, b) => a.at.compareTo(b.at));
    final gramDated = byTime.where((r) => r.grams != null).toList();
    final appetiteDated =
        byTime.where((r) => _appetiteScore(r.appetite) != null).toList();
    final useGrams = gramDated.isNotEmpty && appetiteDated.isEmpty;
    final dated = useGrams ? gramDated : appetiteDated;
    if (dated.isEmpty) {
      return const _EmptyHistory('Chưa có lần cho ăn để vẽ biểu đồ.');
    }
    final points = <FlSpot>[
      for (var i = 0; i < dated.length; i++)
        FlSpot(
          i.toDouble(),
          useGrams
              ? dated[i].grams!
              : _appetiteScore(dated[i].appetite)!,
        ),
    ];
    final maxY = useGrams
        ? points.fold<double>(0, (max, p) => p.y > max ? p.y : max)
        : 3.2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          useGrams
              ? 'Lượng thức ăn (7 ngày gần nhất)'
              : 'Mức ăn (7 ngày gần nhất)',
          style: const TextStyle(
            color: kHomeTextMain,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: useGrams ? (maxY <= 0 ? 1 : maxY * 1.2) : 3,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: kHomeBorder, strokeWidth: 1),
              ),
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
                    reservedSize: useGrams ? 28 : 56,
                    interval: useGrams ? null : 1,
                    getTitlesWidget: (value, _) {
                      if (useGrams) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: kHomeTextSub,
                          ),
                        );
                      }
                      final label = _appetiteLabel(value);
                      if (label.isEmpty) return const SizedBox.shrink();
                      return Text(
                        label,
                        style: const TextStyle(
                          fontSize: 9,
                          color: kHomeTextSub,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: points.length > 6
                        ? (points.length / 4).ceilToDouble()
                        : 1,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= dated.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('dd/MM').format(dated[index].at),
                          style: const TextStyle(
                            fontSize: 9,
                            color: kHomeTextSub,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) => [
                    for (final t in touched)
                      LineTooltipItem(
                        useGrams
                            ? '${t.y.toStringAsFixed(t.y == t.y.roundToDouble() ? 0 : 1)} g'
                            : _appetiteLabel(t.y),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  isCurved: true,
                  color: kHomePrimary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: kHomePrimary.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.records});
  final List<_FeedingRecord> records;

  static double _score(String? activity) {
    final text = (activity ?? '').toLowerCase();
    if (text.contains('nhiều') || text.contains('active')) return 3;
    if (text.contains('góc') || text.contains('corner')) return 1;
    if (text.contains('không') || text.contains('still')) return 0;
    if (text.isEmpty) return -1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final dated = records.where((r) => _score(r.activity) >= 0).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (dated.isEmpty) {
      return const _EmptyHistory('Chưa có dữ liệu hoạt động để vẽ biểu đồ.');
    }
    final points = <FlSpot>[
      for (var i = 0; i < dated.length; i++)
        FlSpot(i.toDouble(), _score(dated[i].activity)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Hoạt động (7 ngày gần nhất)',
          style: TextStyle(
            color: kHomeTextMain,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 3.2,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: kHomeBorder, strokeWidth: 1),
              ),
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
                    reservedSize: 56,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final label = switch (value.round()) {
                        0 => 'Không',
                        1 => 'Ít',
                        2 => 'Vừa',
                        3 => 'Nhiều',
                        _ => '',
                      };
                      return Text(
                        label,
                        style: const TextStyle(fontSize: 9, color: kHomeTextSub),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: points.length > 6
                        ? (points.length / 4).ceilToDouble()
                        : 1,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= dated.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('dd/MM').format(dated[index].at),
                          style: const TextStyle(
                            fontSize: 9,
                            color: kHomeTextSub,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  isCurved: true,
                  color: const Color(0xFF168BE5),
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF168BE5).withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedingTable extends StatelessWidget {
  const _FeedingTable({required this.records});
  final List<_FeedingRecord> records;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columnSpacing: 16,
      horizontalMargin: 0,
      headingRowHeight: 30,
      dataRowMinHeight: 42,
      dataRowMaxHeight: 58,
      columns: const [
        DataColumn(label: Text('Ngày / giờ')),
        DataColumn(label: Text('Thức ăn')),
        DataColumn(label: Text('Gram')),
        DataColumn(label: Text('Ăn / hoạt động')),
      ],
      rows: records.take(50).map((record) {
        final status = [
          if (record.appetite?.isNotEmpty == true) record.appetite!,
          if (record.activity?.isNotEmpty == true) record.activity!,
        ].join(' · ');
        return DataRow(
          cells: [
            DataCell(
              Text(
                DateFormat('dd/MM\nHH:mm').format(record.at),
                style: const TextStyle(fontSize: 11),
              ),
            ),
            DataCell(
              Text(
                record.foodType?.isNotEmpty == true ? record.foodType! : '—',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataCell(
              Text(
                record.grams == null
                    ? '—'
                    : '${record.grams!.toStringAsFixed(record.grams! % 1 == 0 ? 0 : 1)} g',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataCell(
              Text(
                status.isEmpty ? '—' : status,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        );
      }).toList(),
    ),
  );
}

class _EventTimeline extends StatelessWidget {
  const _EventTimeline({required this.events});
  final List<_HistoryEvent> events;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < events.length && i < 50; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _EventIcon(event: events[i]),
                  if (i < events.length - 1)
                    Expanded(child: Container(width: 2, color: kHomeBorder)),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              events[i].title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: kHomeTextMain,
                              ),
                            ),
                            if (events[i].detail?.isNotEmpty == true)
                              Text(
                                events[i].detail!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kHomeTextSub,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy\nHH:mm').format(events[i].at),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 10,
                          color: kHomeTextHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({required this.event});
  final _HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    final kind = event.kind.toLowerCase();
    final icon = kind.contains('feed')
        ? Icons.restaurant_outlined
        : kind.contains('molt') || kind.contains('lột')
        ? Icons.autorenew_rounded
        : kind.contains('transfer') || kind.contains('move')
        ? Icons.swap_horiz_rounded
        : kind.contains('harvest')
        ? Icons.inventory_2_outlined
        : kind.contains('death') || kind.contains('dead')
        ? Icons.close_rounded
        : Icons.add_circle_outline;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: kHomePrimaryBg,
        shape: BoxShape.circle,
        border: Border.all(color: kHomePrimary.withOpacity(0.5)),
      ),
      child: Icon(icon, size: 15, color: kHomePrimaryDark),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: kHomeTextSub, fontSize: 13));
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: CircularProgressIndicator(strokeWidth: 2, color: kHomePrimary),
    ),
  );
}
