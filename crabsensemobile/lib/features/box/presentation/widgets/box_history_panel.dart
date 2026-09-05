import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// Lịch sử hộp — ưu tiên biểu đồ ăn / hoạt động để nông dân nhìn là hiểu.
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
  List<_HistEvent> _events = [];
  List<_DayHealth> _days = [];

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
      final tlRes = await api.get<dynamic>(
        ApiConstants.boxTimeline(widget.boxId),
      );

      final events = <_HistEvent>[
        ..._asList(opsRes.data).map(_fromOperation).whereType<_HistEvent>(),
        ..._asList(tlRes.data).map(_fromTimeline).whereType<_HistEvent>(),
      ]..sort((a, b) => b.at.compareTo(a.at));

      final seen = <String>{};
      final unique = <_HistEvent>[];
      for (final e in events) {
        final key =
            '${e.at.toIso8601String().substring(0, 10)}|${e.kind}|${e.title}';
        if (seen.add(key)) unique.add(e);
      }

      final now = DateTime.now();
      final days = List.generate(7, (i) {
        final d = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 6 - i));
        final ofDay = unique.where(
          (e) =>
              e.at.year == d.year &&
              e.at.month == d.month &&
              e.at.day == d.day,
        );
        int? eat;
        int? act;
        for (final e in ofDay) {
          eat ??= e.eatScore;
          act ??= e.actScore;
        }
        return _DayHealth(day: d, eat: eat, activity: act);
      });

      if (!mounted) return;
      setState(() {
        _events = unique;
        _days = days;
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
        final items = data['items'] ?? data['Items'] ?? data['results'];
        if (items is List) return items;
      }
    }
    if (body is List) return body;
    return const [];
  }

  static _HistEvent? _fromOperation(dynamic item) {
    if (item is! Map) return null;
    final type = (item['type'] ?? item['Type'] ?? 'inspection').toString();
    final notes = (item['notes'] ?? item['Notes'] ?? '').toString();
    final atRaw = item['timestamp'] ??
        item['Timestamp'] ??
        item['createdAt'] ??
        item['CreatedAt'];
    final at = DateTime.tryParse(atRaw?.toString() ?? '')?.toLocal() ??
        DateTime.now();
    final qtyRaw = item['quantity'] ?? item['Quantity'];
    final qty = qtyRaw is num
        ? qtyRaw.toDouble()
        : double.tryParse(qtyRaw?.toString() ?? '');
    final blob = '$notes ${item['type'] ?? ''}';
    final eat = _scoreEat(blob);
    final act = _scoreActivity(blob);
    final title = switch (type.toLowerCase()) {
      'feeding' => 'Cho ăn',
      'inspection' => 'Phiếu ngày',
      'waterchange' || 'water_change' => 'Đổi nước',
      'cleaning' => 'Vệ sinh',
      'medication' => 'Thuốc',
      _ => 'Ghi nhận',
    };

    return _HistEvent(
      kind: type.toLowerCase() == 'feeding' ? _HistKind.feed : _HistKind.care,
      title: title,
      at: at,
      quantity: qty,
      eatScore: eat,
      actScore: act,
    );
  }

  static _HistEvent? _fromTimeline(dynamic item) {
    if (item is! Map) return null;
    final type =
        (item['eventType'] ?? item['EventType'] ?? '').toString().toLowerCase();
    final atRaw = item['at'] ?? item['At'];
    final at = DateTime.tryParse(atRaw?.toString() ?? '')?.toLocal() ??
        DateTime.now();

    final (kind, titleVi) = switch (type) {
      'allocation_start' => (_HistKind.move, 'Cua vào hộp'),
      'allocation_end' => (_HistKind.move, 'Cua rời hộp'),
      'molting' => (_HistKind.molt, 'Lột xác'),
      'status' => (_HistKind.status, 'Đổi trạng thái'),
      _ => (_HistKind.other, 'Sự kiện'),
    };

    return _HistEvent(kind: kind, title: titleVi, at: at);
  }

  static int? _scoreEat(String text) {
    final t = text.toLowerCase();
    if (t.contains('không ăn') || t.contains('none')) return 0;
    if (t.contains('ít') || t.contains('little')) return 1;
    if (t.contains('ăn nhiều') || t.contains('many') || t.contains('ăn:')) {
      return 2;
    }
    return null;
  }

  static int? _scoreActivity(String text) {
    final t = text.toLowerCase();
    if (t.contains('không phản ứng') || t.contains('no_response')) return 0;
    if (t.contains('không di chuyển') || t.contains('still')) return 0;
    if (t.contains('chui') || t.contains('góc') || t.contains('corner')) {
      return 1;
    }
    if (t.contains('di chuyển nhiều') || t.contains('active')) return 2;
    return null;
  }

  _HistEvent? get _latestCare {
    for (final e in _events) {
      if (e.eatScore != null || e.actScore != null) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latestCare;
    return Container(
      decoration: BoxDecoration(
        color: kHomeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kHomeBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: kHomePrimaryDark, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tình trạng cua',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: kHomePrimaryDark,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tải lại',
                onPressed: _loading ? null : reload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: kHomePrimaryDark,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            widget.boxCode != null && widget.boxCode!.isNotEmpty
                ? 'Nhìn màu là biết cua trong hộp ${widget.boxCode}'
                : 'Nhìn màu là biết cua đang thế nào',
            style: const TextStyle(fontSize: 12, color: kHomeTextSub),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: kHomePrimary),
              ),
            )
          else if (_error != null)
            _ErrorBlock(message: _error!, onRetry: reload)
          else ...[
            _NowStatus(latest: latest),
            const SizedBox(height: 14),
            const Text(
              'Ăn & vận động 7 ngày',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: kHomeTextMain,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Cột xanh = ăn   ·   Cột teal = vận động   ·   Cao = tốt',
              style: TextStyle(fontSize: 11, color: kHomeTextHint),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 168, child: _TwinBars(days: _days)),
            const SizedBox(height: 8),
            const _LegendRow(),
            const SizedBox(height: 16),
            const Text(
              'Từng ngày',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: kHomeTextMain,
              ),
            ),
            const SizedBox(height: 8),
            if (_events.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kHomeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kHomeBorder),
                ),
                child: const Text(
                  'Chưa có phiếu. Lưu chăm sóc hôm nay để hiện biểu đồ.',
                  style: TextStyle(color: kHomeTextSub, fontSize: 13),
                ),
              )
            else
              ..._events.take(12).map((e) => _VisualLogTile(event: e)),
          ],
        ],
      ),
    );
  }
}

enum _HistKind { feed, care, move, molt, status, other }

class _HistEvent {
  const _HistEvent({
    required this.kind,
    required this.title,
    required this.at,
    this.quantity,
    this.eatScore,
    this.actScore,
  });

  final _HistKind kind;
  final String title;
  final DateTime at;
  final double? quantity;
  final int? eatScore;
  final int? actScore;
}

class _DayHealth {
  const _DayHealth({required this.day, this.eat, this.activity});
  final DateTime day;
  final int? eat;
  final int? activity;
}

class _NowStatus extends StatelessWidget {
  const _NowStatus({required this.latest});
  final _HistEvent? latest;

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kHomeBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kHomeBorder),
        ),
        child: const Text(
          'Chưa có phiếu gần đây — chưa rõ tình trạng.',
          style: TextStyle(color: kHomeTextSub, fontSize: 13),
        ),
      );
    }

    final eat = latest!.eatScore;
    final act = latest!.actScore;
    final ok = (eat ?? 1) >= 2 && (act ?? 1) >= 2;
    final warn = (eat ?? 2) == 0 || (act ?? 2) == 0;
    final tone = warn ? kHomeDanger : (ok ? kHomePrimaryDark : kHomeWarning);
    final bg = warn
        ? const Color(0x14E53935)
        : (ok ? kHomePrimaryBg : kHomeWarningBg);
    final headline = warn
        ? 'Cần xem ngay'
        : (ok ? 'Cua khỏe' : 'Cần theo dõi');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            headline,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: tone,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BigMeter(
                  icon: Icons.restaurant_rounded,
                  label: 'Ăn',
                  score: eat,
                  good: 'Nhiều',
                  mid: 'Ít',
                  bad: 'Không ăn',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BigMeter(
                  icon: Icons.directions_run_rounded,
                  label: 'Vận động',
                  score: act,
                  good: 'Năng động',
                  mid: 'Ít động',
                  bad: 'Đứng yên',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigMeter extends StatelessWidget {
  const _BigMeter({
    required this.icon,
    required this.label,
    required this.score,
    required this.good,
    required this.mid,
    required this.bad,
  });

  final IconData icon;
  final String label;
  final int? score;
  final String good;
  final String mid;
  final String bad;

  @override
  Widget build(BuildContext context) {
    final color = switch (score) {
      2 => kHomePrimaryDark,
      1 => kHomeWarning,
      0 => kHomeDanger,
      _ => kHomeTextHint,
    };
    final word = switch (score) {
      2 => good,
      1 => mid,
      0 => bad,
      _ => 'Chưa ghi',
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: kHomeSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: kHomeTextSub)),
          Text(
            word,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 18,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: (score ?? -1) >= i
                        ? color
                        : kHomeBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TwinBars extends StatelessWidget {
  const _TwinBars({required this.days});
  final List<_DayHealth> days;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 3,
        groupsSpace: 12,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: kHomeBorder.withValues(alpha: 0.7),
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
              reservedSize: 36,
              interval: 1,
              getTitlesWidget: (v, _) {
                final t = switch (v.toInt()) {
                  0 => '',
                  1 => 'Kém',
                  2 => 'Tốt',
                  _ => '',
                };
                return Text(
                  t,
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
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: (days[i].eat ?? 0).toDouble(),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  color: days[i].eat == null
                      ? kHomeBorder
                      : (days[i].eat == 0
                          ? kHomeDanger
                          : days[i].eat == 1
                              ? kHomeWarning
                              : kHomePrimary),
                ),
                BarChartRodData(
                  toY: (days[i].activity ?? 0).toDouble(),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  color: days[i].activity == null
                      ? kHomeBorder
                      : (days[i].activity == 0
                          ? kHomeDanger
                          : days[i].activity == 1
                              ? kHomeWarning
                              : kHomeInfo),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(t, style: const TextStyle(fontSize: 11, color: kHomeTextSub)),
          ],
        );
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        dot(kHomePrimary, 'Ăn tốt'),
        dot(kHomeInfo, 'Năng động'),
        dot(kHomeWarning, 'Trung bình'),
        dot(kHomeDanger, 'Kém / không'),
      ],
    );
  }
}

class _VisualLogTile extends StatelessWidget {
  const _VisualLogTile({required this.event});
  final _HistEvent event;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('dd/MM HH:mm').format(event.at);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: kHomeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHomeBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              event.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: kHomeTextMain,
              ),
            ),
          ),
          if (event.eatScore != null)
            _Face(score: event.eatScore!, icon: Icons.restaurant_rounded),
          if (event.actScore != null) ...[
            const SizedBox(width: 6),
            _Face(score: event.actScore!, icon: Icons.directions_run_rounded),
          ],
          if (event.kind == _HistKind.move)
            const Icon(Icons.swap_horiz_rounded, color: kHomePrimaryDark),
          if (event.kind == _HistKind.molt)
            const Icon(Icons.autorenew_rounded, color: kHomeWarning),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: kHomeTextHint),
          ),
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.score, required this.icon});
  final int score;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = switch (score) {
      2 => kHomePrimaryDark,
      1 => kHomeWarning,
      _ => kHomeDanger,
    };
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Không tải được lịch sử',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: kHomeDanger,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: kHomeTextSub),
        ),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}
