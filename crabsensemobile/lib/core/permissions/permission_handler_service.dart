import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../shared/widgets/dialogs/permission_rationale_dialog.dart';
import 'permission_result.dart';

/// Service that wraps [permission_handler] to provide a consistent,
/// app-level API for runtime permission management.
///
/// ### Responsibilities
/// - Checks current permission status before requesting.
/// - Shows an in-app rationale dialog (via the caller's [BuildContext])
///   before the OS prompt when the permission has not yet been decided.
/// - Maps all [PermissionStatus] values to [PermissionResult].
/// - Opens app settings when permission is permanently denied.
///
/// All methods are static so the service can be called without DI
/// registration while still being easy to mock in tests by subclassing.
///
/// Requirements: 3.4, 24.1-24.9
class PermissionHandlerService {
  const PermissionHandlerService._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Requests camera permission, showing an in-app rationale dialog first
  /// when the permission has not yet been granted or permanently denied.
  ///
  /// Returns [PermissionResult.granted] if the camera may be used.
  /// Returns [PermissionResult.permanentlyDenied] and opens app settings
  /// automatically when the user has permanently denied the permission.
  ///
  /// [context] must be the [BuildContext] of a mounted widget so the
  /// rationale dialog can be shown before the OS prompt.
  ///
  /// Requirements: 3.4, 24.1, 24.2, 24.7, 24.8
  static Future<PermissionResult> requestCameraPermission(BuildContext context) async =>
      _requestPermission(
        context: context,
        permission: Permission.camera,
        rationaleTitle: 'Camera Access Required',
        rationaleMessage:
            'CrabSense needs access to your camera to scan QR codes '
            'on crab boxes. Without camera access, QR scanning will '
            'not be available.',
        rationaleIcon: Icons.camera_alt_outlined,
      );

  /// Requests storage/photos permission for photo and video operations.
  ///
  /// Requirements: 24.4, 24.6, 24.7
  static Future<PermissionResult> requestStoragePermission(BuildContext context) async =>
      _requestPermission(
        context: context,
        permission: Permission.photos,
        rationaleTitle: 'Storage Access Required',
        rationaleMessage:
            'CrabSense needs storage access to save photos and videos '
            'of your crab operations. This lets you document harvests '
            'and attach images to operation logs.',
        rationaleIcon: Icons.photo_library_outlined,
      );

  /// Requests location permission for farm location features.
  ///
  /// Requirements: 24.3, 24.6, 24.7
  static Future<PermissionResult> requestLocationPermission(BuildContext context) async =>
      _requestPermission(
        context: context,
        permission: Permission.locationWhenInUse,
        rationaleTitle: 'Location Access Required',
        rationaleMessage:
            'CrabSense uses your location to display your farm on the '
            'map and enable accurate field tracking. Location is only '
            'accessed while the app is in use.',
        rationaleIcon: Icons.location_on_outlined,
      );

  /// Requests notification permission with a clear explanation of alert
  /// types the user will receive.
  ///
  /// Requirements: 24.5, 24.6, 24.7
  static Future<PermissionResult> requestNotificationPermission(BuildContext context) async =>
      _requestPermission(
        context: context,
        permission: Permission.notification,
        rationaleTitle: 'Notification Permission',
        rationaleMessage:
            'CrabSense sends alerts for critical water-quality changes, '
            'equipment issues, crab-health warnings, and task reminders. '
            'Enable notifications to stay informed about your farm.',
        rationaleIcon: Icons.notifications_outlined,
      );

  /// Returns the current [PermissionResult] for [Permission.camera] without
  /// requesting or showing any UI.
  ///
  /// Useful for checking status before attempting a protected operation.
  ///
  /// Requirements: 24.7
  static Future<PermissionResult> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return _mapStatus(status);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Generic permission request flow:
  /// 1. Check current status.
  /// 2. If already granted/restricted → return immediately.
  /// 3. If permanently denied → open settings, return result.
  /// 4. Otherwise show rationale → request OS prompt → map result.
  static Future<PermissionResult> _requestPermission({
    required BuildContext context,
    required Permission permission,
    required String rationaleTitle,
    required String rationaleMessage,
    required IconData rationaleIcon,
  }) async {
    // Step 1: check current status to avoid unnecessary prompts.
    final current = await permission.status;

    if (current.isGranted) {
      return PermissionResult.granted;
    }

    if (current.isRestricted) {
      return PermissionResult.restricted;
    }

    if (current.isPermanentlyDenied) {
      await openAppSettings();
      return PermissionResult.permanentlyDenied;
    }

    // Step 2: show in-app rationale before the OS prompt.
    // Only show if the context is still mounted.
    if (!context.mounted) {
      return PermissionResult.denied;
    }

    final userAccepted = await PermissionRationaleDialog.show(
      context: context,
      title: rationaleTitle,
      message: rationaleMessage,
      icon: rationaleIcon,
    );

    if (!userAccepted) {
      return PermissionResult.denied;
    }

    // Step 3: request the OS permission prompt.
    final status = await permission.request();
    return _mapStatus(status);
  }

  /// Converts a [permission_handler] [PermissionStatus] to [PermissionResult].
  ///
  /// Requirements: 24.8 (platform-specific flows are handled internally
  /// by the permission_handler package).
  static PermissionResult _mapStatus(PermissionStatus status) => switch (status) {
    PermissionStatus.granted => PermissionResult.granted,
    PermissionStatus.limited => PermissionResult.granted,
    PermissionStatus.permanentlyDenied => PermissionResult.permanentlyDenied,
    PermissionStatus.restricted => PermissionResult.restricted,
    // denied, provisional, etc.
    _ => PermissionResult.denied,
  };
}
