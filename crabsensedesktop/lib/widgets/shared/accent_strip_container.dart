import 'package:flutter/material.dart';

import '../../theme/dashboard_theme.dart';

/// Card with optional left accent bar — safe inside [Wrap] / unbounded height parents.
class AccentStripContainer extends StatelessWidget {
  const AccentStripContainer({
    super.key,
    required this.child,
    this.accentColor,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 14,
    this.backgroundColor,
  });

  final Widget child;
  final Color? accentColor;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: (backgroundColor ?? DashboardColors.card).withValues(alpha: 0.92),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Stack(
          children: [
            if (accent != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: accent),
              ),
            Padding(
              padding: padding.copyWith(
                left: padding.left + (accent != null ? 4 : 0),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
