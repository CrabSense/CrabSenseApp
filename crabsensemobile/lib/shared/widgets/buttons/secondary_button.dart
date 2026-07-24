import 'package:flutter/material.dart';

/// Secondary Button Component
/// Outlined button with primary color outline for secondary actions
/// Requirements: 20.1-20.10
class SecondaryButton extends StatelessWidget {
  /// Creates a secondary button
  const SecondaryButton({
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
      button = OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon,
        label: child,
        style: padding != null ? OutlinedButton.styleFrom(padding: padding) : null,
      );
    } else {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: padding != null ? OutlinedButton.styleFrom(padding: padding) : null,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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
