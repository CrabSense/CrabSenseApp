/// Client-side preview guard, not an authorization or hosting access control.
abstract final class PreviewPolicy {
  static bool allows({
    required Uri uri,
    required bool debug,
    required bool localEnabled,
    required bool hostedEnabled,
    required String hostedOrigin,
  }) {
    if (debug) {
      return localEnabled && const {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
    }
    final configured = Uri.tryParse(hostedOrigin);
    return hostedEnabled && configured != null &&
        _httpsOrigin(configured) && uri.scheme == 'https' &&
        uri.origin == configured.origin;
  }

  static bool validHostedApi(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && _httpsOrigin(uri);
  }

  static bool _httpsOrigin(Uri uri) =>
      uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty &&
      !const {'localhost', '127.0.0.1', '::1'}.contains(uri.host) &&
      (uri.path.isEmpty || uri.path == '/') && !uri.hasQuery && !uri.hasFragment;
}
