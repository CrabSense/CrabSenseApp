import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import 'certificate_pinning_native.dart' if (dart.library.html) 'certificate_pinning_web_stub.dart';

/// Certificate pinning configuration for the CrabSense API client.
///
/// On web: returns `null` — the browser handles TLS natively and
/// `dart:io` / `IOHttpClientAdapter` are not available.
///
/// On native (Android / iOS / desktop): pins the SHA-256 fingerprint of
/// the server certificate against [ApiConstants.certSha256Hash].  In
/// **debug** mode the check is bypassed.  In **profile and release** mode
/// the check is always enforced and any mismatch terminates the TLS
/// handshake.
///
/// Usage:
/// ```dart
/// if (!kIsWeb) {
///   final adapter = CertificatePinning.buildAdapter(logger: logger);
///   if (adapter != null) dio.httpClientAdapter = adapter;
/// }
/// ```
///
/// Requirements: 23.2 (TLS 1.2+), 23.3 (certificate pinning)
class CertificatePinning {
  CertificatePinning._(); // Utility class — no instances.

  /// On web: returns `null` (no pinning, uses browser's TLS).
  /// On native: returns an [IOHttpClientAdapter] with SHA-256 pinning.
  static dynamic buildAdapter({
    required Logger logger,
    String expectedHash = ApiConstants.certSha256Hash,
  }) {
    if (kIsWeb) return null;
    return CertificatePinningNative.buildAdapter(
      logger: logger,
      expectedHash: expectedHash,
    );
  }
}
