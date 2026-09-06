import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

/// Home — Water quality overview card (light theme).
class WaterQualityOverview extends StatelessWidget {
  final List<WaterMetricItem> metrics;
  final VoidCallback onViewDetailsPressed;

  const WaterQualityOverview({
    super.key,
    required this.metrics,
    required this.onViewDetailsPressed,
  });

  Color _statusColor(MetricStatus status) => switch (status) {
        MetricStatus.optimal => kHomePrimary,
        MetricStatus.warning => kHomeWarning,
        MetricStatus.danger => kHomeDanger,
      };

  String _statusLabel(MetricStatus status) => switch (status) {
        MetricStatus.optimal => 'OK',
        MetricStatus.warning => 'Cảnh báo',
        MetricStatus.danger => 'Nguy hiểm',
      };

  IconData _metricIcon(String code) {
    final t = code.toLowerCase();
    if (t.contains('temp')) return Icons.thermostat_rounded;
    if (t.contains('ph')) return Icons.science_rounded;
    if (t.contains('do') || t.contains('oxy')) return Icons.air_rounded;
    if (t.contains('salin') || t.contains('salt')) return Icons.water_drop_outlined;
    if (t.contains('nh') || t.contains('amm')) return Icons.biotech_rounded;
    return Icons.sensors_rounded;
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    if ((value * 10).roundToDouble() == value * 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }

  DateTime? get _latestUpdate {
    if (metrics.isEmpty) return null;
    return metrics.map((m) => m.lastUpdated).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return 'Chưa có dữ liệu';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa cập nhật';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${diff.inHours} giờ trước';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          icon: Icons.water_drop_rounded,
          iconColor: kHomeSecondary,
          title: 'Chất lượng nước',
          actionLabel: 'Xem chi tiết',
          onAction: onViewDetailsPressed,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: homeCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: kHomeSecondaryBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.water_drop_rounded,
                          color: kHomeSecondary, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chất lượng nước',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kHomeTextMain,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeLabel(_latestUpdate),
                      style: const TextStyle(
                          fontSize: 11, color: kHomeTextHint),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: kHomeBorder),
              ),
              const SizedBox(height: 12),
              // Metrics row
              if (metrics.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Center(
                    child: Text(
                      'Chưa có tín hiệu cảm biến',
                      style: TextStyle(color: kHomeTextHint, fontSize: 13),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Row(
                    children: metrics.take(4).map((m) {
                      final c = _statusColor(m.status);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _MetricTile(
                            label: m.name,
                            value: _formatValue(m.currentValue),
                            unit: m.unit,
                            icon: _metricIcon(m.code),
                            statusColor: c,
                            statusLabel: _statusLabel(m.status),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 12),
              // Footer link
              GestureDetector(
                onTap: onViewDetailsPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: kHomeBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Xem chi tiết →',
                        style: TextStyle(
                          color: kHomePrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.statusColor,
    required this.statusLabel,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color statusColor;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: statusColor, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 10, color: kHomeTextHint, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kHomeTextMain,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 9,
                    color: kHomeTextHint,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
