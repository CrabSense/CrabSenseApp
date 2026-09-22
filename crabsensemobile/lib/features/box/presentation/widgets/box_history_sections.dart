import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/presentation/widgets/home_palette.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = sl<ApiClient>();
      final responses = await Future.wait<dynamic>([
        api.get<dynamic>(
          ApiConstants.operationsForBox(widget.boxId),
          queryParameters: const {'page': 1, 'limit': 80},
        ),
        api.get<dynamic>(ApiConstants.boxTimeline(widget.boxId)),
      ]);
      final operations = _asList(responses[0].data);
      final feeding =
          operations.map(_parseFeeding).whereType<_FeedingRecord>().toList()
            ..sort((a, b) => b.at.compareTo(a.at));
      final events =
          _asList(
              responses[1].data,
            ).map(_parseEvent).whereType<_HistoryEvent>().toList()
            ..sort((a, b) => b.at.compareTo(a.at));
      if (!mounted) return;
      setState(() {
        _feeding = feeding;
        _events = events;
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
    }
    return body is List ? body : const [];
  }

  static _FeedingRecord? _parseFeeding(dynamic raw) {
    if (raw is! Map) return null;
    final type = (raw['type'] ?? raw['Type'] ?? '').toString().toLowerCase();
    if (type.isNotEmpty && !type.contains('feed') && type != 'operation') {
      return null;
    }
    final at = DateTime.tryParse(
      (raw['timestamp'] ?? raw['Timestamp'] ?? raw['createdAt'] ?? '')
          .toString(),
    )?.toLocal();
    if (at == null) return null;
    final notes = (raw['notes'] ?? raw['Notes'] ?? '').toString();
    final quantity = raw['quantity'] ?? raw['Quantity'];
    return _FeedingRecord(
      at: at,
      foodType: _foodType(
        _value(raw, 'foodType', 'FoodType') ?? _line(notes, 'Thức ăn:'),
      ),
      grams: quantity is num
          ? quantity.toDouble()
          : double.tryParse(quantity?.toString() ?? '') ??
                _number(_line(notes, 'Lượng:')),
      appetite: _appetite(
        _value(raw, 'appetite', 'Appetite') ?? _line(notes, 'Mức ăn:'),
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
                    _FeedingSummary(records: _feeding),
                    const SizedBox(height: 14),
                    _FeedingChart(records: _feeding),
                    const SizedBox(height: 14),
                    _FeedingTable(records: _feeding),
                  ],
                ),
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
              'Tổng lượng thức ăn',
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

  @override
  Widget build(BuildContext context) {
    final dated = records.where((record) => record.grams != null).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (dated.isEmpty) {
      return const _EmptyHistory('Chưa có khối lượng thức ăn để vẽ biểu đồ.');
    }
    final points = <FlSpot>[
      for (var i = 0; i < dated.length; i++)
        FlSpot(i.toDouble(), dated[i].grams!),
    ];
    final maxY = points.fold<double>(
      0,
      (max, point) => point.y > max ? point.y : max,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Lượng thức ăn theo lần ghi nhận',
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
              maxY: maxY <= 0 ? 1 : maxY * 1.2,
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
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
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
