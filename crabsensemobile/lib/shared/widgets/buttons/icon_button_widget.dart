import 'package:flutter/material.dart';

/// Icon Button Component
/// Circular icon button for compact actions
/// Requirements: 20.1-20.10
class IconButtonWidget extends StatelessWidget {
  /// Creates an icon button
  const IconButtonWidget({
    required this.onPressed,
    required this.icon,
    super.key,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 24,
    this.padding = const EdgeInsets.all(8),
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Icon to display
  final IconData icon;

  /// Optional tooltip text
  final String? tooltip;

  /// Optional background color
  final Color? backgroundColor;

  /// Optional icon color
  final Color? foregroundColor;

  /// Icon size
  final double size;

  /// Button padding
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      padding: padding,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }

    return button;
  }
}
