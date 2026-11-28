import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/network_info.dart';
import '../../../water_quality/data/repositories/scoped_history_service.dart';
import '../../../water_quality/domain/entities/water_quality.dart';
import '../../../water_quality/presentation/widgets/live_water_metrics.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

List<WaterQuality> visibleHomeWaterReadings(List<WaterMetricItem> metrics, {
  required String? areaId, required int revision, required bool online,
  required DateTime now,
}) {
  if (!online || areaId == null) return [];
  return scopedLiveMetrics(areaId, null, [
    for (final item in metrics)
      if (item.sessionRevision == revision && item.qualifiedReading != null)
        item.qualifiedReading!,
  ], now);
}

/// Compact per-sensor overview, with no offline or previous-session fallback.
class WaterQualityOverview extends StatefulWidget {
  const WaterQualityOverview({super.key, required this.metrics,
    required this.areaId, required this.online, required this.session,
    required this.network, required this.onViewDetailsPressed});
  final List<WaterMetricItem> metrics;
  final String? areaId;
  final bool online;
  final ScopedHistoryService session;
  final NetworkInfo network;
  final VoidCallback onViewDetailsPressed;

  @override
  State<WaterQualityOverview> createState() => _WaterQualityOverviewState();
}

class _WaterQualityOverviewState extends State<WaterQualityOverview>
    with WidgetsBindingObserver {
  StreamSubscription<int>? _sessionSub;
  StreamSubscription<List<NetworkType>>? _networkSub;
  Timer? _timer;
  bool _transport = false;
  bool _foreground = false;
  DateTime? _onlineSince;
  int _probe = 0;
  // A transport change requires an entirely new online snapshot. Do not
  // resurrect the same List reference after reconnect or app resume.
  List<WaterMetricItem>? _blockedMetrics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final life = WidgetsBinding.instance.lifecycleState;
    _foreground = life == null || life == AppLifecycleState.resumed;
    _sessionSub = widget.session.invalidations.listen((_) {
      if (!mounted) return;
      setState(() => _blockedMetrics = widget.metrics);
    });
    _networkSub = widget.network.onNetworkTypesChanged.listen((types) {
      ++_probe;
      _setTransport(historyTransportAvailable(types));
    }, onError: (Object _) {
      ++_probe;
      _setTransport(false);
    });
    unawaited(_checkTransport());
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      setState(() {});
      unawaited(_checkTransport());
    });
  }

  void _setTransport(bool available) {
    if (!mounted) return;
    final next = available && _foreground;
    if (next == _transport) return;
    setState(() {
      _transport = next;
      if (!next) {
        _blockedMetrics = widget.metrics;
        _onlineSince = null;
      } else {
        _onlineSince = DateTime.now();
      }
    });
  }

  Future<void> _checkTransport() async {
    final generation = ++_probe;
    final online = await historyNetworkAvailable(widget.network);
    if (mounted && generation == _probe) _setTransport(online);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ++_probe;
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _setTransport(false);
    } else {
      unawaited(_checkTransport());
    }
  }

  @override
  void didUpdateWidget(covariant WaterQualityOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId || !widget.online) {
      _blockedMetrics = oldWidget.metrics;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_sessionSub?.cancel());
    unawaited(_networkSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final readings = visibleHomeWaterReadings(widget.metrics,
      areaId: widget.areaId, revision: widget.session.revision,
      online: widget.online && _transport && _foreground &&
          _onlineSince != null && !identical(_blockedMetrics, widget.metrics),
      now: now);
    // Old samples remain labelled old, never green. Show at most four
    // separate sensors and expose the full set in environment details.
    final items = readings.take(4).toList();
    final stamp = DateFormat('dd/MM HH:mm:ss');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(icon: Icons.water_drop_rounded,
          iconColor: kHomeSecondary, title: 'Chất lượng nước',
          actionLabel: 'Xem chi tiết', onAction: widget.onViewDetailsPressed),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: homeCardDecoration(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (items.isEmpty)
              const Text('Chưa có chỉ số đã xác minh. Kéo để tải lại.')
            else ...[
              for (final r in items) ...[
                _HomeWaterTile(reading: r, now: now, stamp: stamp),
                const Divider(height: 16),
              ],
              if (readings.length > items.length)
                Text('Còn ${readings.length-items.length} cảm biến · Xem chi tiết'),
            ],
            const Text('Dữ liệu đại diện vòng nước RAS dùng chung cho các dãy và hộp trong khu; không đo riêng từng hộp.',
              style: TextStyle(color: kHomeTextSub, fontSize: 11)),
            const SizedBox(height: 4),
            const Text('Ngưỡng cấu hình không phải kết luận nước an toàn.',
              style: TextStyle(color: kHomeTextSub, fontSize: 11)),
            const SizedBox(height: 4),
            const Text('NH₃/NH₄, NO₂, NO₃: xem tại Phân tích nước.',
              style: TextStyle(color: kHomeTextSub, fontSize: 11)),
          ]),
        ),
      ],
    );
  }
}

class _HomeWaterTile extends StatelessWidget {
  const _HomeWaterTile({required this.reading,required this.now,required this.stamp});
  final WaterQuality reading;
  final DateTime now;
  final DateFormat stamp;
  @override
  Widget build(BuildContext context) {
    final m = reading.liveMetric!;
    final assessment = liveMetricAssessment(reading,now);
    final color = assessment == 'Cảnh báo từ cấu hình' ? kHomeDanger :
        assessment == 'Trong giới hạn đã cấu hình' ? kHomePrimaryDark : kHomeWarning;
    return Column(
      key: ValueKey('home-water-${reading.sensorId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${m.kind.label} · ${m.sensorCode}',
          style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('${m.value == 0 ? '0' : m.value.toString()} ${m.unit}',
          style: const TextStyle(fontSize: 18,fontWeight: FontWeight.w800)),
        Text('Đo: ${stamp.format(reading.timestamp.toLocal())} · Nhận: ${stamp.format(m.receivedAt.toLocal())}',
          style: const TextStyle(fontSize: 11,color: kHomeTextSub)),
        Text('Ngưỡng: ${liveMetricRange(m)}',style: const TextStyle(fontSize: 11)),
        Text(assessment,style: TextStyle(color: color,fontSize: 12)),
      ],
    );
  }
}
