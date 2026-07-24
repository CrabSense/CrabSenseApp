import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'crab_hologram_painter.dart';
import 'home_palette.dart';

/// Home — panel chất lượng nước (một composition, instrument-style).
class WaterQualityOverview extends StatefulWidget {
  final List<WaterMetricItem> metrics;
  final VoidCallback onViewDetailsPressed;

  const WaterQualityOverview({
    super.key,
    required this.metrics,
    required this.onViewDetailsPressed,
  });

  @override
  State<WaterQualityOverview> createState() => _WaterQualityOverviewState();
}

class _WaterQualityOverviewState extends State<WaterQualityOverview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color _statusColor(MetricStatus status) => switch (status) {
        MetricStatus.optimal => kHomeGreen,
        MetricStatus.warning => kHomeOrange,
        MetricStatus.danger => CrabSenseColors.danger,
      };

  String _statusLabel(MetricStatus status) => switch (status) {
        MetricStatus.optimal => 'Ổn định',
        MetricStatus.warning => 'Cần theo dõi',
        MetricStatus.danger => 'Ngoài ngưỡng',
      };

  IconData _metricIcon(String code) {
    final t = code.toLowerCase();
    if (t.contains('temp')) return Icons.thermostat_rounded;
    if (t.contains('ph')) return Icons.science_rounded;
    if (t.contains('do') || t.contains('oxy') || t.contains('oxygen')) {
      return Icons.air_rounded;
    }
    if (t.contains('salin') || t.contains('salt')) {
      return Icons.water_drop_outlined;
    }
    return Icons.sensors_rounded;
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    if ((value * 10).roundToDouble() == value * 10) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  DateTime? get _latestUpdate {
    if (widget.metrics.isEmpty) return null;
    return widget.metrics
        .map((m) => m.lastUpdated)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return 'Chưa có dữ liệu';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa cập nhật';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  MetricStatus get _overallStatus {
    if (widget.metrics.any((m) => m.status == MetricStatus.danger)) {
      return MetricStatus.danger;
    }
    if (widget.metrics.any((m) => m.status == MetricStatus.warning)) {
      return MetricStatus.warning;
    }
    return MetricStatus.optimal;
  }

  @override
  Widget build(BuildContext context) {
    final overall = widget.metrics.isEmpty ? null : _overallStatus;
    final overallColor = overall == null ? kHomeCyan : _statusColor(overall);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          icon: Icons.water_rounded,
          iconColor: kHomeCyan,
          title: 'CHẤT LƯỢNG NƯỚC',
          actionLabel: 'Xem biểu đồ',
          onAction: widget.onViewDetailsPressed,
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onViewDetailsPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              decoration: homeCardDecoration(accent: kHomeCyan),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: CrabHologramPainter(
                            color: kHomeCyan.withValues(alpha: 0.09),
                            trayExtent: 26,
                          ),
                        ),
                      ),
                    ),
                    const HomeTopEdgeGlow(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (_, __) {
                                  final t = _pulse.value;
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: overallColor.withValues(
                                        alpha: 0.55 + t * 0.45,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: overallColor.withValues(
                                            alpha: 0.25 + t * 0.35,
                                          ),
                                          blurRadius: 6 + t * 4,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.metrics.isEmpty
                                    ? 'Không có tín hiệu'
                                    : 'Trực tiếp',
                                style: TextStyle(
                                  color: overallColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              if (overall != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: overallColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: overallColor.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _statusLabel(overall),
                                    style: TextStyle(
                                      color: overallColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Text(
                                _timeLabel(_latestUpdate),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (widget.metrics.isEmpty)
                            _EmptyWaterState(onTap: widget.onViewDetailsPressed)
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 420;
                                final tiles = widget.metrics.take(4).toList();
                                if (wide) {
                                  return Row(
                                    children: [
                                      for (var i = 0; i < tiles.length; i++) ...[
                                        if (i > 0) const SizedBox(width: 10),
                                        Expanded(
                                          child: _MetricTile(
                                            item: tiles[i],
                                            icon: _metricIcon(tiles[i].code),
                                            statusColor: _statusColor(
                                              tiles[i].status,
                                            ),
                                            valueText: _formatValue(
                                              tiles[i].currentValue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                }
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: tiles.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 1.55,
                                  ),
                                  itemBuilder: (_, i) => _MetricTile(
                                    item: tiles[i],
                                    icon: _metricIcon(tiles[i].code),
                                    statusColor: _statusColor(tiles[i].status),
                                    valueText: _formatValue(
                                      tiles[i].currentValue,
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Xem biểu đồ chi tiết',
                                style: TextStyle(
                                  color: kHomeCyan.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: kHomeCyan.withValues(alpha: 0.9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.item,
    required this.icon,
    required this.statusColor,
    required this.valueText,
  });

  final WaterMetricItem item;
  final IconData icon;
  final Color statusColor;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: kHomeNavyDeep.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, size: 14, color: statusColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.4,
                    shadows: [
                      Shadow(
                        color: statusColor.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              if (item.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  item.unit,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _railValue(item),
              minHeight: 3,
              backgroundColor: kHomeNavyLift,
              color: statusColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  double _railValue(WaterMetricItem item) {
    final v = item.currentValue.abs();
    if (item.code.contains('ph')) return (v / 14).clamp(0.08, 1.0);
    if (item.code.contains('temp')) return (v / 40).clamp(0.08, 1.0);
    if (item.code.contains('salin') || item.code.contains('salt')) {
      return (v / 40).clamp(0.08, 1.0);
    }
    return (v / 12).clamp(0.08, 1.0);
  }
}

class _EmptyWaterState extends StatelessWidget {
  const _EmptyWaterState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: homeTileDecoration(radius: 12, accent: kHomeCyan),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kHomeCyan.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: kHomeCyan.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: kHomeCyan.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.water_drop_outlined,
                color: kHomeCyan,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có tín hiệu cảm biến cho khu này',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mở biểu đồ để kiểm tra chi tiết',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
