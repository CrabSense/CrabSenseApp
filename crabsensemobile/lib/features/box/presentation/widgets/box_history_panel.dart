import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// Lịch sử hộp: biểu đồ ăn / vận động / lượng TA + sản phẩm thức ăn.
class BoxHistoryPanel extends StatefulWidget {
  const BoxHistoryPanel({
    super.key,
    required this.boxId,
    this.boxCode,
  });

  final String boxId;
  final String? boxCode;

  @override
  State<BoxHistoryPanel> createState() => BoxHistoryPanelState();
}

class BoxHistoryPanelState extends State<BoxHistoryPanel> {
  bool _loading = true;
  String? _error;
  List<BoxCareDayPoint> _days = [];
  List<_ProductSlice> _products = [];

  /// Có ngày nào trong cửa sổ 7 ngày thực sự có số liệu không. Không có ⇒ đừng vẽ
  /// biểu đồ rỗng: 7 ngày toàn `null` sẽ bị fl_chart ném lỗi (`firstWhere` không có
  /// `orElse`) và trước đó thì vẽ thành "Không ăn" — sai sự thật.
  bool _hasRecords = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = sl<ApiClient>();
      final opsRes = await api.get<dynamic>(
        ApiConstants.operationsForBox(widget.boxId),
        queryParameters: {'page': 1, 'limit': 80},
      );
      final records = _asList(opsRes.data)
          .map(_fromOp)
          .whereType<BoxCareRecord>()
          .toList()
        ..sort((a, b) => a.at.compareTo(b.at));

      final now = DateTime.now();
      final days = List.generate(7, (i) {
        final d = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 6 - i));
        final ofDay = records.where(
          (e) =>
              e.at.year == d.year &&
              e.at.month == d.month &&
              e.at.day == d.day,
        );
        return mergeDay(d, ofDay);
      });

      final productMap = <String, double>{};
      for (final e in records) {
        final name = (e.product ?? '').trim();
        if (name.isEmpty) continue;
        productMap[name] = (productMap[name] ?? 0) + (e.grams ?? 1);
      }
      final products = [
        for (final e in productMap.entries)
          _ProductSlice(name: e.key, grams: e.value),
      ]..sort((a, b) => b.grams.compareTo(a.grams));

      if (!mounted) return;
      setState(() {
        _days = days;
        _products = products;
        _hasRecords =
            days.any((d) => d.eat != null || d.act != null || d.grams > 0);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
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
        final items = data['items'] ?? data['results'];
        if (items is List) return items;
      }
    }
    return body is List ? body : const [];
  }

  /// Gộp các phiếu trong MỘT ngày thành một điểm biểu đồ.
  ///
  /// Điểm mấu chốt: ngày KHÔNG có phiếu (hoặc phiếu không ghi mục đó) trả `null`,
  /// KHÔNG trả 0. Trả 0 là bịa ra một lần đánh giá "Không ăn"/"Yếu" mà nông dân
  /// chưa từng thực hiện — đúng lỗi đã thấy trên hộp trống.
  static BoxCareDayPoint mergeDay(
    DateTime day,
    Iterable<BoxCareRecord> ofDay,
  ) {
    int? eat;
    int? act;
    var grams = 0.0;
    for (final e in ofDay) {
      if (e.eat != null) eat = e.eat;
      if (e.act != null) act = e.act;
      grams += e.grams ?? 0;
    }
    return BoxCareDayPoint(day: day, eat: eat, act: act, grams: grams);
  }

  static BoxCareRecord? _fromOp(dynamic item) {
    if (item is! Map) return null;
    final notes = (item['notes'] ?? item['Notes'] ?? '').toString();
    final atRaw = item['timestamp'] ??
        item['Timestamp'] ??
        item['createdAt'] ??
        item['CreatedAt'];
    final at = DateTime.tryParse(atRaw?.toString() ?? '')?.toLocal();
    if (at == null) return null;
    final qtyRaw = item['quantity'] ?? item['Quantity'];
    final qty = qtyRaw is num
        ? qtyRaw.toDouble()
        : double.tryParse(qtyRaw?.toString() ?? '');
    return BoxCareRecord(
      at: at,
      eat: _scoreEat(notes),
      act: _scoreAct(notes),
      grams: qty ?? _parseGrams(notes),
      product: _line(notes, 'Thức ăn:'),
    );
  }

  static String? _line(String notes, String prefix) {
    for (final line in notes.split('\n')) {
      final t = line.trim();
      if (t.startsWith(prefix)) {
        final v = t.substring(prefix.length).trim();
        return v.isEmpty ? null : v;
      }
    }
    return null;
  }

  static double? _parseGrams(String notes) {
    final line = _line(notes, 'Lượng:');
    if (line == null) return null;
    return double.tryParse(line.replaceAll(RegExp('[^0-9.]'), ''));
  }

  static int? _scoreEat(String text) {
    final t = text.toLowerCase();
    if (t.contains('không ăn')) return 0;
    if (t.contains('ít')) return 1;
    if (t.contains('ăn nhiều')) return 2;
    return null;
  }

  static int? _scoreAct(String text) {
    final t = text.toLowerCase();
    if (t.contains('không phản ứng') || t.contains('không di chuyển')) {
      return 0;
    }
    if (t.contains('chui') || t.contains('góc')) return 1;
    if (t.contains('di chuyển nhiều')) return 2;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kHomeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kHomeBorder),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: kHomePrimaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.boxCode == null || widget.boxCode!.isEmpty
                      ? 'Biểu đồ theo dõi'
                      : 'Biểu đồ hộp ${widget.boxCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: kHomePrimaryDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : reload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: kHomePrimaryDark,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: kHomePrimary),
              ),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: kHomeDanger, fontSize: 12))
          else if (!_hasRecords)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Chưa có phiếu nào trong 7 ngày qua nên chưa có gì để vẽ. '
                'Điền phiếu chăm sóc ở trên để biểu đồ bắt đầu ghi.',
                style: TextStyle(color: kHomeTextSub, fontSize: 13, height: 1.4),
              ),
            )
          else ...[
            const _ChartTitle('Mức ăn (7 ngày)'),
            SizedBox(
              height: 160,
              child: _ScoreChart(
                days: _days,
                values: [for (final d in _days) d.eat?.toDouble()],
                color: const Color(0xFF2E7D32),
                labels: const ['Không', 'Ít', 'Nhiều'],
              ),
            ),
            const SizedBox(height: 16),
            const _ChartTitle('Vận động (7 ngày)'),
            SizedBox(
              height: 160,
              child: _ScoreChart(
                days: _days,
                values: [for (final d in _days) d.act?.toDouble()],
                color: const Color(0xFF1565C0),
                labels: const ['Yếu', 'Vừa', 'Nhiều'],
              ),
            ),
            const SizedBox(height: 16),
            const _ChartTitle('Lượng thức ăn (g)'),
            SizedBox(
              height: 160,
              child: _GramsChart(days: _days),
            ),
            const SizedBox(height: 16),
            const _ChartTitle('Sản phẩm thức ăn'),
            if (_products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Chưa ghi loại thức ăn trên phiếu.',
                  style: TextStyle(color: kHomeTextSub, fontSize: 13),
                ),
              )
            else ...[
              if (_products.length >= 2)
                SizedBox(height: 160, child: _ProductPie(items: _products)),
              const SizedBox(height: 8),
              ..._products.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${p.grams.round()} g',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: kHomePrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Một phiếu chăm sóc đã đọc từ API. `null` = phiếu đó không ghi mục tương ứng.
class BoxCareRecord {
  const BoxCareRecord({
    required this.at,
    this.eat,
    this.act,
    this.grams,
    this.product,
  });
  final DateTime at;
  final int? eat;
  final int? act;
  final double? grams;
  final String? product;
}

/// Một ngày trên biểu đồ. `null` = ngày đó KHÔNG có số liệu (khác hẳn 0 = "Không ăn").
class BoxCareDayPoint {
  const BoxCareDayPoint({
    required this.day,
    required this.eat,
    required this.act,
    required this.grams,
  });
  final DateTime day;
  final int? eat;
  final int? act;
  final double grams;
}

class _ProductSlice {
  const _ProductSlice({required this.name, required this.grams});
  final String name;
  final double grams;
}

class _ChartTitle extends StatelessWidget {
  const _ChartTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: kHomeTextMain,
        ),
      ),
    );
  }
}

class _ScoreChart extends StatelessWidget {
  const _ScoreChart({
    required this.days,
    required this.values,
    required this.color,
    required this.labels,
  });

  final List<BoxCareDayPoint> days;
  final List<double?> values;
  final Color color;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');

    // Toàn bộ 7 ngày đều không có số liệu ⇒ không vẽ gì. Vẽ sẽ ra đường phẳng ở
    // "Không ăn"/"Yếu" (sai sự thật), còn để fl_chart tự xử lý thì nó ném lỗi vì
    // `firstWhere` tìm spot khác null mà không có `orElse`.
    if (values.every((v) => v == null)) {
      return const Center(
        child: Text(
          'Chưa ghi mục này trên phiếu nào.',
          style: TextStyle(color: kHomeTextHint, fontSize: 12),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 2.4,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: kHomeBorder.withValues(alpha: 0.8),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i > 2) return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(fontSize: 9, color: kHomeTextHint),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    fmt.format(days[i].day),
                    style: const TextStyle(fontSize: 10, color: kHomeTextSub),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              // `nullSpot` cắt đường tại ngày không có phiếu — để lộ khoảng trống
              // thay vì nối liền và ngụ ý đã đo được số 0.
              for (var i = 0; i < values.length; i++)
                if (values[i] == null)
                  FlSpot.nullSpot
                else
                  FlSpot(i.toDouble(), values[i]!),
            ],
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GramsChart extends StatelessWidget {
  const _GramsChart({required this.days});
  final List<BoxCareDayPoint> days;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    final maxY = days.fold<double>(0, (m, d) => d.grams > m ? d.grams : m);
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY <= 0 ? 10 : maxY * 1.25,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: kHomeBorder.withValues(alpha: 0.8),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    fmt.format(days[i].day),
                    style: const TextStyle(fontSize: 10, color: kHomeTextSub),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].grams,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  color: const Color(0xFFEF6C00),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProductPie extends StatelessWidget {
  const _ProductPie({required this.items});
  final List<_ProductSlice> items;

  static const _colors = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
  ];

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, e) => s + e.grams);
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 28,
        sections: [
          for (var i = 0; i < items.length; i++)
            PieChartSectionData(
              value: items[i].grams,
              color: _colors[i % _colors.length],
              title: total <= 0
                  ? ''
                  : '${((items[i].grams / total) * 100).round()}%',
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              radius: 48,
            ),
        ],
      ),
    );
  }
}
