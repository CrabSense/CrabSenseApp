import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// A reusable in-app dialog shown before the OS permission prompt.
///
/// Displays a [title], explanatory [message], and an [icon] so users
/// understand why a permission is needed before the OS dialog appears.
///
/// Returns `true` when the user taps "Allow" and `false` when they tap
/// "Deny" or dismiss the dialog.
///
/// Usage:
/// ```dart
/// final allowed = await PermissionRationaleDialog.show(
///   context: context,
///   title: 'Camera Access Required',
///   message: 'CrabSense needs the camera to scan QR codes.',
///   icon: Icons.camera_alt_outlined,
/// );
/// ```
///
/// Requirements: 3.4, 24.1
class PermissionRationaleDialog extends StatelessWidget {
  const PermissionRationaleDialog({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  /// The dialog title (e.g. "Camera Access Required").
  final String title;

  /// The explanatory body text shown below the icon.
  final String message;

  /// The icon representing the permission type.
  final IconData icon;

  // ---------------------------------------------------------------------------
  // Static factory
  // ---------------------------------------------------------------------------

  /// Shows the dialog and returns whether the user accepted.
  ///
  /// Returns `false` if [context] is unmounted or the dialog is dismissed
  /// without tapping a button.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PermissionRationaleDialog(title: title, message: message, icon: icon),
    );
    return result ?? false;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: CrabSenseColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: CrabSenseColors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CrabSenseColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CrabSenseColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 32, color: CrabSenseColors.primary),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(color: CrabSenseColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Deny button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CrabSenseColors.textSecondary,
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Deny'),
                  ),
                ),
                const SizedBox(width: 12),

                // Allow button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CrabSenseColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Allow'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
