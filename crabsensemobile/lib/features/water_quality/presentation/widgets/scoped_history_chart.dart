import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/scoped_history_snapshot.dart';
import '../../domain/entities/water_quality.dart';
import '../models/scoped_history_series.dart';

/// Explicit online request; history is never sourced from the legacy cache.
/// Only one sensor is plotted at a time, using measured points without
/// interpolation or invented values. Invalidation clears visible data.
class ScopedHistoryChart extends StatefulWidget {
  const ScopedHistoryChart({
    super.key,
    required this.areaId,
    required this.rowId,
    required this.readings,
    required this.online,
    required this.fetch,
    required this.revision,
    required this.invalidations,
  });

  final String areaId;
  final String? rowId;
  final List<WaterQuality> readings;
  final bool online;
  final Future<ScopedHistorySnapshot> Function(ScopedHistoryQuery) fetch;
  final int Function() revision;
  final Stream<int> invalidations;

  @override
  State<ScopedHistoryChart> createState() => _ScopedHistoryChartState();
}

class _ScopedHistoryChartState extends State<ScopedHistoryChart> {
  String? _selected;
  Duration _period = const Duration(hours: 24);
  int _request = 0;
  int? _displayRevision;
  bool _loading = false;
  String? _message;
  HistorySeries? _series;
  Timer? _expiry;
  StreamSubscription<int>? _subscription;

  List<HistorySensor> get _sensors =>
      historySensors(widget.areaId, widget.rowId, widget.readings);

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _subscription = widget.invalidations.listen((_) {
      if (!mounted) return;
      setState(() {
        _clear();
        _message = 'Phiên hoặc quyền truy cập thay đổi. Hãy tải lại.';
      });
    });
  }

  void _clear() {
    ++_request;
    _expiry?.cancel();
    _series = null;
    _displayRevision = null;
    _loading = false;
    _message = null;
  }

  @override
  void didUpdateWidget(covariant ScopedHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invalidations != widget.invalidations) {
      unawaited(_subscription?.cancel());
      _subscribe();
      _clear();
    }
    if (oldWidget.areaId != widget.areaId ||
        oldWidget.rowId != widget.rowId ||
        oldWidget.online != widget.online ||
        (_selected != null && !_sensors.any((s) => s.key == _selected))) {
      _clear();
      _selected = null;
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _load(HistorySensor sensor) async {
    if (!widget.online) return;
    setState(() {
      _clear();
      _loading = true;
    });
    final request = _request;
    final revision = widget.revision();
    try {
      final query = sensor.query(DateTime.now().toUtc(), _period);
      final snapshot = await widget.fetch(query);
      if (!mounted || request != _request || revision != widget.revision()) return;
      if (snapshot.query.key != query.key) {
        throw const FormatException('History request mismatch');
      }
      final series = HistorySeries.fromSnapshot(sensor, snapshot);
      setState(() {
        _series = series;
        _displayRevision = revision;
        _loading = false;
      });
      // Historical view is not a live permission lease. Require periodic
      // online revalidation instead of retaining indefinitely.
      _expiry = Timer(const Duration(minutes: 1), () {
        if (!mounted || request != _request) return;
        setState(() {
          _clear();
          _message = 'Dữ liệu đã hết hạn hiển thị. Hãy tải lại.';
        });
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _clear();
        _message = 'Không tải được lịch sử đã xác minh. Kiểm tra quyền, '
            'kết nối hoặc chọn khoảng thời gian ngắn hơn.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensors = _sensors;
    final matching = sensors.where((s) => s.key == _selected);
    final selected = matching.isEmpty ? null : matching.first;
    final series = _displayRevision == widget.revision() && widget.online
        ? _series : null;
    return Container(
      key: const Key('scoped-history-chart'),
      padding: const EdgeInsets.all(16),
      decoration: homeCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Biểu đồ theo dõi', style: TextStyle(
            fontWeight: FontWeight.w800, color: kHomeTextMain)),
          const SizedBox(height: 8),
          const Text('Lịch sử từng cảm biến · chỉ dữ liệu đo đã xác minh.',
            style: TextStyle(color: kHomeTextSub)),
          if (!widget.online)
            const Text('Mất kết nối. Không hiển thị cache lịch sử.')
          else if (sensors.isEmpty)
            const Text('Chọn khu cụ thể có cảm biến với dữ liệu đo hợp lệ.')
          else ...[
            DropdownButton<String>(
              key: const Key('history-sensor-select'),
              isExpanded: true,
              value: selected?.key,
              hint: const Text('Chọn cảm biến'),
              items: [
                for (final s in sensors)
                  DropdownMenuItem(value: s.key, child: Text(s.label)),
              ],
              onChanged: (key) => setState(() {
                _clear();
                _selected = key;
              }),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in const {
                  '24 giờ': Duration(hours: 24),
                  '7 ngày': Duration(days: 7),
                  '30 ngày': Duration(days: 30),
                }.entries)
                  ChoiceChip(
                    label: Text(entry.key),
                    selected: _period == entry.value,
                    onSelected: (_) => setState(() {
                      _clear();
                      _period = entry.value;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('history-fetch'),
              onPressed: selected == null || _loading
                  ? null : () => _load(selected),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lịch sử'),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_message != null) Text(_message!,
              style: const TextStyle(color: kHomeWarning)),
            if (series != null)
              if (series.points.isEmpty)
                const Text('Không có phép đo trong khoảng đã chọn.')
              else
                _MeasuredPlot(series: series),
          ],
          const SizedBox(height: 8),
          const Text('Không nội suy giữa các điểm đo. Kết quả hóa học xem '
              'tại Phân tích nước WaterBench.',
            style: TextStyle(color: kHomeTextSub)),
        ],
      ),
    );
  }
}

class _MeasuredPlot extends StatelessWidget {
  const _MeasuredPlot({required this.series});
  final HistorySeries series;

  @override
  Widget build(BuildContext context) {
    final points = series.points;
    final lo = points.map((p) => p.value).reduce(math.min);
    final hi = points.map((p) => p.value).reduce(math.max);
    final latest = points.last;
    final date = DateFormat('dd/MM HH:mm:ss');
    String stamp(DateTime d) => date.format(d.toLocal());
    String val(double v) => v.toStringAsPrecision(6);
    return Column(
      key: const Key('history-measured-plot'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${series.metric.label} (${series.metric.unit}) · ${points.length} điểm'),
        Text('Mới nhất: ${val(latest.value)} ${series.metric.unit} · ${stamp(latest.at)}'),
        Text('Dữ liệu đến: ${stamp(series.asOf)}',
          style: const TextStyle(color: kHomeTextSub)),
        const SizedBox(height: 8),
        Text('Max: ${val(hi)}'),
        Semantics(
          label: 'Biểu đồ ${points.length} điểm đo',
          child: SizedBox(
            width: double.infinity, height: 160,
            child: CustomPaint(painter: _PointPainter(series, lo, hi)),
          ),
        ),
        Text('Min: ${val(lo)}'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(stamp(series.query.from),
              style: const TextStyle(fontSize: 10))),
            Flexible(child: Text(stamp(series.query.to),
              textAlign: TextAlign.end, style: const TextStyle(fontSize: 10))),
          ],
        ),
      ],
    );
  }
}

class _PointPainter extends CustomPainter {
  _PointPainter(this.series, this.lo, this.hi);
  final HistorySeries series;
  final double lo;
  final double hi;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(4, 4, math.max(0.0, size.width - 8),
      math.max(0.0, size.height - 8));
    canvas.drawRect(bounds, Paint()..color = kHomeBorder
      ..style = PaintingStyle.stroke);
    final paint = Paint()..color = kHomePrimary;
    final span = series.query.to.difference(series.query.from).inMicroseconds;
    final scale = math.max(1.0, math.max(lo.abs(), hi.abs()));
    final low = lo / scale;
    final high = hi / scale;
    canvas.save();
    canvas.clipRect(bounds);
    for (final p in series.points) {
      final x = p.at.difference(series.query.from).inMicroseconds / span;
      final y = high == low ? 0.5 : (p.value / scale - low) / (high - low);
      canvas.drawCircle(Offset(bounds.left + x * bounds.width,
        bounds.bottom - y * bounds.height), 2.5, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PointPainter oldDelegate) =>
      oldDelegate.series != series;
}
