import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

enum WaterMetricTone { good, low, warn, empty }

/// Thẻ một chỉ số — pH / oxy / nhiệt / mặn.
class SensorReadingCard extends StatelessWidget {
  const SensorReadingCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.isNormal,
    required this.rangeLabel,
    super.key,
    this.timestamp,
    this.tone,
    this.statusLabel,
    this.iconColor,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool isNormal;
  final String rangeLabel;
  final String? timestamp;
  final WaterMetricTone? tone;
  final String? statusLabel;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolved = tone ??
        (isNormal ? WaterMetricTone.good : WaterMetricTone.warn);
    final (bg, accent, badge) = switch (resolved) {
      WaterMetricTone.good => (
          const Color(0xFFEAF8F1),
          const Color(0xFF1B8A5A),
          statusLabel ?? 'Tốt',
        ),
      WaterMetricTone.low => (
          const Color(0xFFFFF7EA),
          const Color(0xFFE09A2A),
          statusLabel ?? 'Thấp',
        ),
      WaterMetricTone.warn => (
          const Color(0xFFFFF1F0),
          kHomeDanger,
          statusLabel ?? 'Cảnh báo',
        ),
      WaterMetricTone.empty => (
          const Color(0xFFF4F7F6),
          kHomeTextHint,
          statusLabel ?? 'Chưa có dữ liệu',
        ),
    };
    final glyph = iconColor ?? accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: glyph),
              const Spacer(),
              Icon(
                resolved == WaterMetricTone.good
                    ? Icons.check_circle
                    : resolved == WaterMetricTone.empty
                        ? Icons.remove_circle_outline
                        : Icons.warning_amber_rounded,
                size: 14,
                color: resolved == WaterMetricTone.good
                    ? const Color(0xFF2BB673)
                    : accent,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: glyph,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: value,
                style: TextStyle(
                  color: resolved == WaterMetricTone.good
                      ? kHomeTextMain
                      : accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
                children: [
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        color: kHomeTextSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rangeLabel,
            maxLines: 2,
            style: const TextStyle(
              color: kHomeTextSub,
              fontSize: 9,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
