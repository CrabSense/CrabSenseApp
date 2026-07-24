import 'dart:ui';
import 'package:flutter/material.dart';

/// CrabSense Card with Glassmorphism Effect
/// A reusable card component featuring frosted glass effect following Material Design 3
/// Requirements: 20.1-20.10
class CrabSenseCard extends StatelessWidget {
  /// Creates a glassmorphism card
  const CrabSenseCard({
    required this.child, super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.1,
    this.elevation = 2,
    this.border = true,
  });

  /// The widget to display inside the card
  final Widget child;

  /// Optional tap callback
  final VoidCallback? onTap;

  /// Internal padding of the card
  final EdgeInsetsGeometry padding;

  /// External margin of the card
  final EdgeInsetsGeometry margin;

  /// Border radius of the card (default 16dp)
  final double borderRadius;

  /// Blur intensity for glassmorphism effect
  final double blur;

  /// Opacity of the background
  final double opacity;

  /// Shadow elevation
  final double elevation;

  /// Whether to show border
  final bool border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border
                  ? Border.all(color: primaryColor.withValues(alpha: 0.2))
                  : null,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
