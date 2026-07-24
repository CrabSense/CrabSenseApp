import 'package:flutter/material.dart';

/// Floating Action Button Component
/// Primary floating action button for main screen actions
/// Requirements: 20.1-20.10
class FABButton extends StatelessWidget {
  /// Creates a floating action button
  const FABButton({
    required this.onPressed,
    required this.icon,
    super.key,
    this.label,
    this.tooltip,
    this.heroTag,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Icon to display
  final IconData icon;

  /// Optional label for extended FAB
  final String? label;

  /// Optional tooltip text
  final String? tooltip;

  /// Optional hero tag for navigation animations
  final Object? heroTag;

  /// Optional background color
  final Color? backgroundColor;

  /// Optional icon/text color
  final Color? foregroundColor;

  /// Whether to use mini FAB
  final bool mini;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget fab;

    if (label != null) {
      // Extended FAB with label
      fab = FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        heroTag: heroTag,
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? Colors.black,
        tooltip: tooltip,
      );
    } else if (mini) {
      // Mini FAB
      fab = FloatingActionButton.small(
        onPressed: onPressed,
        heroTag: heroTag,
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? Colors.black,
        tooltip: tooltip,
        child: Icon(icon),
      );
    } else {
      // Standard FAB
      fab = FloatingActionButton(
        onPressed: onPressed,
        heroTag: heroTag,
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? Colors.black,
        tooltip: tooltip,
        child: Icon(icon),
      );
    }

    return fab;
  }
}
