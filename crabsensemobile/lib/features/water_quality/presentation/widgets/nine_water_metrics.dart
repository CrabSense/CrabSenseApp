import 'package:flutter/material.dart';

import '../../../home/domain/models/home_models.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// 9 chỉ số như Trang chủ / desktop (live + xét nghiệm).
class NineWaterMetrics extends StatelessWidget {
  const NineWaterMetrics({required this.metrics, super.key});

  final List<WaterMetricItem> metrics;

  static const _kinds = [
    ('temp', '🌡', 'Nhiệt độ', '°C'),
    ('sal', '≋', 'Độ mặn / TDS', null),
    ('ph', 'pH', 'pH', null),
    ('do', 'O₂', 'DO', null),
    ('nh3', 'NH₃', 'NH₃/NH₄', null),
    ('no2', 'NO₂', 'NO₂', null),
    ('kh', 'KH', 'KH', null),
    ('ca', 'Ca', 'Ca', null),
    ('mg', 'Mg', 'Mg', null),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var r = 0; r < 3; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var c = 0; c < 3; c++)
                _Cell(kind: _kinds[r * 3 + c], metrics: metrics),
            ],
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.kind, required this.metrics});

  final (String, String, String, String?) kind;
  final List<WaterMetricItem> metrics;

  @override
  Widget build(BuildContext context) {
    final m = _pick(metrics, kind.$1);
    final level = _lvl(m, kind.$1);
    final (color, badge) = switch (level) {
      0 => (const Color(0xFF16A66A), Icons.check_circle),
      1 => (const Color(0xFFF09A27), Icons.error_outline),
      2 => (const Color(0xFFE34850), Icons.warning_rounded),
      _ => (const Color(0xFF9AA7B2), null),
    };
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (badge != null) ...[
                  Icon(badge, size: 11, color: color),
                  const SizedBox(width: 3),
                ],
                Text(
                  kind.$2,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmt(m, kind.$4),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kHomeTextMain,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          Text(
            kind.$3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kHomeTextSub,
              fontSize: 9,
              height: 1.2,
            ),
          ),
          SizedBox(
            height: 12,
            child: Text(
              _range(m, kind.$1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 8, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

WaterMetricItem? _pick(List<WaterMetricItem> items, String kind) {
  final matches = items.where((m) => _kind(m, kind)).toList();
  if (matches.isEmpty) return null;
  matches.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  if (kind == 'temp') {
    final ok = matches.where((m) => m.currentValue >= 5 && m.currentValue <= 40);
    return ok.isEmpty ? null : ok.first;
  }
  if (kind == 'ph') {
    final ok = matches.where((m) => m.currentValue >= 5 && m.currentValue <= 10);
    if (ok.isNotEmpty) return ok.first;
  }
  return matches.first;
}

bool _kind(WaterMetricItem m, String kind) {
  final t = m.code.toLowerCase();
  final n = m.name.toLowerCase();
  return switch (kind) {
    'temp' => t.contains('temp') || n.contains('nhiệt'),
    'sal' => t.contains('salin') ||
        t.contains('tds') ||
        n.contains('mặn') ||
        n.contains('tds'),
    'ph' => t == 'ph' || t.startsWith('ph_') || n == 'ph',
    'do' => t == 'do' || t.contains('oxy') || n.contains('oxy'),
    'nh3' => t.contains('nh3') ||
        t.contains('nh4') ||
        t.contains('ammon') ||
        n.contains('amoni'),
    'no2' => t.contains('no2') || t.contains('nitrit') || n.contains('nitrit'),
    'kh' => t == 'kh' || t.contains('alkal') || n.contains('kh'),
    'ca' => t == 'ca' || t.contains('calci') || n.contains('canxi'),
    'mg' => t == 'mg' || t.contains('magnes') || n.contains('magie'),
    _ => false,
  };
}

(double?, double?) _refs(String kind) => switch (kind) {
      'temp' => (24.0, 28.0),
      'sal' => (10.0, 20.0),
      'ph' => (7.5, 8.5),
      'do' => (5.0, null),
      'nh3' => (null, 0.1),
      'no2' => (null, 0.2),
      'kh' => (7.0, 10.0),
      'ca' => (380.0, 460.0),
      'mg' => (1200.0, 1400.0),
      _ => (null, null),
    };

int _lvl(WaterMetricItem? m, String kind) {
  if (m == null) return 3;
  if (m.status == MetricStatus.danger) return 2;
  final refs = _refs(kind);
  final min = m.minThreshold ?? refs.$1;
  final max = m.maxThreshold ?? refs.$2;
  final v = m.currentValue;
  if (min != null && v < min) return 2;
  if (max != null && v > max) return 2;
  final span = (min != null && max != null) ? (max - min) : (min ?? max ?? 0).abs();
  final margin = span * 0.1;
  if (margin > 0) {
    if (min != null && v < min + margin) return 1;
    if (max != null && v > max - margin) return 1;
  }
  if (m.status == MetricStatus.warning) return 1;
  return 0;
}

String _fmt(WaterMetricItem? metric, String? unit) {
  if (metric == null) return '--';
  final u = (unit ?? metric.unit).trim();
  final value = metric.currentValue == metric.currentValue.roundToDouble()
      ? metric.currentValue.toStringAsFixed(0)
      : metric.currentValue.toStringAsFixed(1);
  return u.isEmpty ? value : '$value$u';
}

String _range(WaterMetricItem? m, String kind) {
  if (m == null) return '';
  final refs = _refs(kind);
  final min = m.minThreshold ?? refs.$1;
  final max = m.maxThreshold ?? refs.$2;
  String n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  if (min != null && max != null) return '${n(min)}–${n(max)}';
  if (min != null) return '≥${n(min)}';
  if (max != null) return '≤${n(max)}';
  return '';
}
