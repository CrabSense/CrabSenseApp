import 'package:flutter/material.dart';

import '../../core/permissions/permission_handler_service.dart';
import '../../core/permissions/permission_result.dart';

export '../../core/permissions/permission_result.dart';

/// Camera-specific permission service for QR scanning and video capture.
///
/// Thin wrapper around [PermissionHandlerService] that provides
/// camera-focused rationale and enforces the app's required flow:
///
/// 1. Check current status — short-circuit if already granted.
/// 2. Show in-app rationale explaining WHY camera access is needed.
/// 3. Request the OS permission prompt.
/// 4. Return a typed [PermissionResult] for callers to act on.
///
/// Usage from a mounted widget:
/// ```dart
/// final result = await CameraPermissionService.request(context);
/// switch (result) {
///   case PermissionResult.granted:
///     // proceed with camera
///   case PermissionResult.denied:
///     // show soft prompt or disable feature
///   case PermissionResult.permanentlyDenied:
///     // show CameraPermissionDeniedWidget with settings link
///   case PermissionResult.restricted:
///     // notify user that OS restricts camera
/// }
/// ```
///
/// Requirements: 3.4, 24.1, 24.2, 24.7, 24.8, 24.9
class CameraPermissionService {
  const CameraPermissionService._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Requests camera permission, showing a rationale dialog that
  /// explains QR scanning and AI video capture use cases.
  ///
  /// Must be called from a mounted [BuildContext].
  ///
  /// Requirements: 3.4, 24.1, 24.2, 24.7
  static Future<PermissionResult> request(BuildContext context) =>
      PermissionHandlerService.requestCameraPermission(context);

  /// Returns the current camera permission status without showing any UI.
  ///
  /// Useful for checking before attempting a protected camera operation.
  ///
  /// Requirements: 24.7
  static Future<PermissionResult> check() => PermissionHandlerService.checkCameraPermission();

  /// Returns `true` if the camera permission is currently granted.
  ///
  /// Requirements: 24.7
  static Future<bool> isGranted() async {
    final result = await check();
    return result == PermissionResult.granted;
  }

  /// Returns `true` if the permission has been permanently denied and
  /// the user must navigate to device settings to re-enable it.
  ///
  /// Requirements: 24.2, 24.9
  static Future<bool> isPermanentlyDenied() async {
    final result = await check();
    return result == PermissionResult.permanentlyDenied;
  }
}
