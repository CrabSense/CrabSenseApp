import 'package:flutter/material.dart';

/// Primary Button Component
/// Elevated button with primary brand color for main actions
/// Requirements: 20.1-20.10
class PrimaryButton extends StatelessWidget {
  /// Creates a primary button
  const PrimaryButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.padding,
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button label widget (usually Text)
  final Widget child;

  /// Whether to show loading indicator
  final bool isLoading;

  /// Optional leading icon
  final Widget? icon;

  /// Whether button should take full width
  final bool fullWidth;

  /// Custom padding (uses theme default if null)
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget button;

    if (icon != null && !isLoading) {
      button = ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon,
        label: child,
        style: padding != null ? ElevatedButton.styleFrom(padding: padding) : null,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: padding != null ? ElevatedButton.styleFrom(padding: padding) : null,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                ),
              )
            : child,
      );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
