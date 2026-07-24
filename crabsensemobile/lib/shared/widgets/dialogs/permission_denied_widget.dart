import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme.dart';

/// Widget displayed when a permission has been permanently denied.
///
/// Shows an explanatory icon, title, and message alongside an
/// "Open Settings" button so the user can re-enable the permission
/// from device settings, and a "Cancel" button to dismiss.
///
/// Example usage (inline replacement content):
/// ```dart
/// if (result == PermissionResult.permanentlyDenied) {
///   return PermissionDeniedWidget(
///     permissionName: 'Camera',
///     onCancel: () => Navigator.of(context).pop(),
///   );
/// }
/// ```
///
/// Requirements: 3.4, 24.2, 24.9
class PermissionDeniedWidget extends StatelessWidget {
  const PermissionDeniedWidget({
    required this.permissionName,
    required this.onCancel,
    super.key,
    this.customMessage,
  });

  /// Human-readable name of the permission (e.g. "Camera").
  final String permissionName;

  /// Called when the user taps the "Cancel" button.
  final VoidCallback onCancel;

  /// Optional override for the explanatory body text. When omitted a
  /// sensible default is generated from [permissionName].
  final String? customMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message =
        customMessage ??
        '$permissionName permission has been permanently denied. '
            'Please open your device settings to enable it so '
            'CrabSense can use this feature.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CrabSenseColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: CrabSenseColors.error.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                size: 40,
                color: CrabSenseColors.error,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              '$permissionName Permission Denied',
              style: theme.textTheme.titleLarge?.copyWith(color: CrabSenseColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Body
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Open Settings button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings_outlined, size: 20),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrabSenseColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CrabSenseColors.textSecondary,
                  side: const BorderSide(color: CrabSenseColors.outline),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
