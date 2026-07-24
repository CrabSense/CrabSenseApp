import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme.dart';
import '../../../features/qr_scanner/presentation/bloc/bloc.dart' show CameraPermissionRequested;
import '../../../features/qr_scanner/presentation/bloc/scanner_event.dart'
    show CameraPermissionRequested;

/// Widget displayed when the camera permission has been denied.
///
/// Handles two denial states:
///
/// - **Denied** (can request again): Shows a friendly message and an
///   "Enable Camera" button that calls the provided [onRetry] callback
///   so the caller can re-trigger the permission request flow.
///
/// - **Permanently Denied** (must use settings): Shows a stronger
///   message and an "Open Settings" button that launches the device
///   app-settings page via [openAppSettings] from permission_handler.
///
/// A "Go Back" / cancel button is always shown so the user can leave
/// the screen if they choose not to grant the permission.
///
/// Example usage:
/// ```dart
/// CameraPermissionDeniedWidget(
///   isPermanentlyDenied: result == PermissionResult.permanentlyDenied,
///   onRetry: () {
///     context.read<ScannerBloc>()
///         .add(const CameraPermissionRequested());
///   },
///   onCancel: () => context.pop(),
/// );
/// ```
///
/// Requirements: 3.4, 24.2, 24.6, 24.9
class CameraPermissionDeniedWidget extends StatelessWidget {
  const CameraPermissionDeniedWidget({
    required this.onCancel,
    super.key,
    this.isPermanentlyDenied = false,
    this.onRetry,
  });

  /// When `true`, shows the permanently-denied variant with an
  /// "Open Settings" button instead of the "Enable Camera" button.
  final bool isPermanentlyDenied;

  /// Called when the user taps "Enable Camera" (denied variant only).
  /// Typically re-dispatches [CameraPermissionRequested] to the BLoC.
  /// Not required when [isPermanentlyDenied] is `true`.
  final VoidCallback? onRetry;

  /// Called when the user taps the "Go Back" button.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => isPermanentlyDenied
      ? _PermanentlyDeniedBody(onCancel: onCancel)
      : _DeniedBody(onRetry: onRetry, onCancel: onCancel);
}

// ---------------------------------------------------------------------------
// Denied variant (can retry)
// ---------------------------------------------------------------------------

class _DeniedBody extends StatelessWidget {
  const _DeniedBody({required this.onCancel, this.onRetry});

  final VoidCallback? onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CrabSenseColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CrabSenseColors.warning.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 40,
                color: CrabSenseColors.warning,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Camera Access Needed',
              style: theme.textTheme.titleLarge?.copyWith(color: CrabSenseColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Text(
              'Camera access was denied. CrabSense needs the camera '
              'to scan QR codes and capture videos for AI analysis. '
              'Tap "Enable Camera" to grant access.',
              style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Enable camera button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('Enable Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrabSenseColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel / go back button
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
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permanently denied variant (must open settings)
// ---------------------------------------------------------------------------

class _PermanentlyDeniedBody extends StatelessWidget {
  const _PermanentlyDeniedBody({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

            Text(
              'Camera Permission Blocked',
              style: theme.textTheme.titleLarge?.copyWith(color: CrabSenseColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Text(
              'Camera access has been permanently denied. '
              'To use QR scanning and AI video analysis, please open '
              'your device settings and enable the Camera permission '
              'for CrabSense.',
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

            // Go back button
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
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
