/// Describes the outcome of a permission request.
///
/// Returned by [PermissionHandlerService] so callers can react without
/// depending directly on the [permission_handler] package's internal types.
///
/// Requirements: 3.4, 24.1-24.9
enum PermissionResult {
  /// The user granted the requested permission.
  granted,

  /// The user denied the permission (can be requested again later).
  denied,

  /// The user permanently denied the permission; the app must direct the
  /// user to device settings to re-enable it.
  permanentlyDenied,

  /// The permission is restricted by the operating system (e.g. parental
  /// controls on iOS). The app cannot request it.
  restricted,
}
