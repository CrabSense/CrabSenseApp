import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

/// Card hiển thị một chỉ số cảm biến chất lượng nước.
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
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool isNormal;
  final String rangeLabel;
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final accent = isNormal ? kHomeCyan : kHomeOrange;
    final valueColor = isNormal ? Colors.white : kHomeOrange;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isNormal ? 0.4 : 0.75),
          width: isNormal ? 1 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isNormal ? 0.12 : 0.28),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 16, color: accent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -0.4,
                          shadows: [
                            Shadow(
                              color: accent.withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: valueColor.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  rangeLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    timestamp!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isNormal)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kHomeOrange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: kHomeOrange.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kHomeOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: kHomeOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
