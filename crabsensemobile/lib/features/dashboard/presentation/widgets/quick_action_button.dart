import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// A prominent tappable quick-action button with an icon and text label.
///
/// Used in the quick-actions row on the dashboard:
///   - Scan QR
///   - Capture Video
///   - Operation Log
///
/// Requirements: 2.5
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.color,
  });

  /// Icon to display above the label.
  final IconData icon;

  /// Short action label displayed below the icon.
  final String label;

  /// Callback invoked when the button is tapped.
  final VoidCallback onTap;

  /// Optional accent color. Defaults to [CrabSenseColors.primary].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? CrabSenseColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: accentColor),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: CrabSenseColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
