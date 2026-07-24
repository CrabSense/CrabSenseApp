import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// In-app rationale dialog shown before requesting camera permission.
///
/// Explains WHY camera access is needed — both for QR code scanning
/// and for AI-powered crab health video analysis — before the OS
/// permission prompt is shown.
///
/// Returns `true` when the user taps "Allow" and `false` when they
/// tap "Deny" or dismiss the dialog.
///
/// Example usage:
/// ```dart
/// final allowed = await CameraPermissionDialog.show(context: context);
/// if (allowed) {
///   // proceed to request OS permission
/// }
/// ```
///
/// Requirements: 3.4, 24.1
class CameraPermissionDialog extends StatelessWidget {
  const CameraPermissionDialog({super.key});

  // ---------------------------------------------------------------------------
  // Static factory
  // ---------------------------------------------------------------------------

  /// Shows the dialog and returns whether the user accepted.
  ///
  /// Returns `false` if [context] is unmounted or the user dismisses
  /// without tapping a button.
  static Future<bool> show({required BuildContext context}) async {
    if (!context.mounted) {
      return false;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CameraPermissionDialog(),
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
            // Camera icon badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: CrabSenseColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CrabSenseColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 36,
                color: CrabSenseColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Camera Access Required',
              style: theme.textTheme.titleLarge?.copyWith(color: CrabSenseColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Use-case list
            const _UseCaseRow(icon: Icons.qr_code_scanner, label: 'Scan QR codes on crab boxes'),
            const SizedBox(height: 8),
            const _UseCaseRow(
              icon: Icons.videocam_outlined,
              label: 'Record videos for AI health analysis',
            ),
            const SizedBox(height: 16),

            // Body message
            Text(
              'CrabSense needs camera access to identify your boxes '
              'and perform AI-powered crab health detection. '
              'Your camera is only used while the app is open.',
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

/// Small row widget displaying a permission use-case with an icon.
class _UseCaseRow extends StatelessWidget {
  const _UseCaseRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: CrabSenseColors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
        ),
      ),
    ],
  );
}
