import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// A card that displays a single sensor parameter reading.
///
/// Used on the water quality screen to show temperature, pH,
/// dissolved oxygen, and salinity readings with their units, ranges,
/// and out-of-range warning indicators.
///
/// Requirements: 8.2, 8.3, 8.4
class SensorReadingCard extends StatelessWidget {
  /// Creates a sensor reading card.
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

  /// Parameter name, e.g. "Temperature".
  final String label;

  /// Formatted numeric value, e.g. "28.5".
  final String value;

  /// Unit of measurement, e.g. "°C".
  final String unit;

  /// Icon representing this parameter.
  final IconData icon;

  /// Whether the reading is within the acceptable threshold range.
  ///
  /// When false the card border and badge turn [CrabSenseColors.warning]
  /// to highlight the out-of-range value (Requirement 8.4).
  final bool isNormal;

  /// Human-readable threshold range, e.g. "26–30°C".
  final String rangeLabel;

  /// Optional "Updated X min ago" timestamp text.
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isNormal
        ? CrabSenseColors.primary.withValues(alpha: 0.3)
        : CrabSenseColors.warning;
    final valueColor = isNormal ? CrabSenseColors.textPrimary : CrabSenseColors.warning;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CrabSenseColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isNormal ? 1 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and label row
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isNormal ? CrabSenseColors.primary : CrabSenseColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: CrabSenseColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Value and unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        unit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: valueColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Range hint
                Text(
                  rangeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
                ),

                // Optional timestamp
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    timestamp!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: CrabSenseColors.textDisabled,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Warning badge in top-right corner
          if (!isNormal)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: CrabSenseColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: CrabSenseColors.warning.withValues(alpha: 0.5)),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: CrabSenseColors.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
