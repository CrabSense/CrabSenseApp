import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// A compact metrics card with a glassmorphism style.
///
/// Displays an [icon], a large bold [value] (e.g. "42"), and a smaller
/// [label] (e.g. "Active Boxes"). An optional [color] tints both the icon
/// and value text.
///
/// Used in the quick-metrics row on the dashboard:
///   - Active Boxes
///   - Videos Due Today
///   - Active Alerts
///
/// Requirements: 2.2, 2.3
class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
    this.color,
    this.onTap,
  });

  /// Icon representing the metric category.
  final IconData icon;

  /// The numeric (or text) value to display prominently.
  final String value;

  /// Short descriptive label below the value.
  final String label;

  /// Optional accent color for icon and value text.
  /// Defaults to [CrabSenseColors.primary].
  final Color? color;

  /// Optional tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? CrabSenseColors.primary;

    final Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: CrabSenseColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: accentColor),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: CrabSenseColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: card);
    }

    return card;
  }
}
