import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';

/// Certificate pinning configuration for the CrabSense API client.
///
/// Pins the SHA-256 fingerprint of the server certificate against
/// [ApiConstants.certSha256Hash].  In **debug** mode the check is
/// bypassed (allowing local dev with self-signed certificates and
/// proxy tools).  In **profile and release** mode the check is always
/// enforced and any mismatch terminates the TLS handshake.
///
/// Usage:
/// ```dart
/// final adapter = CertificatePinning.buildAdapter(logger: logger);
/// dio.httpClientAdapter = adapter;
/// ```
///
/// Requirements: 23.2 (TLS 1.2+), 23.3 (certificate pinning)
class CertificatePinning {
  CertificatePinning._(); // Utility class — no instances.

  /// Builds an [IOHttpClientAdapter] that enforces certificate pinning.
  ///
  /// [expectedHash] — base64-encoded SHA-256 hash of the expected
  ///   DER-encoded certificate bytes.  Defaults to
  ///   [ApiConstants.certSha256Hash].
  ///
  /// [logger] — used to emit a warning in debug mode and an error on
  ///   pinning failure.
  static IOHttpClientAdapter buildAdapter({
    required Logger logger,
    String expectedHash = ApiConstants.certSha256Hash,
  }) => IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient()
        ..badCertificateCallback = (cert, host, port) {
          // Allow all certificates in debug mode for local development.
          if (kDebugMode) {
            logger.w(
              'CertPinning: check bypassed in debug mode '
              'for $host:$port',
            );
            return true;
          }

          // Production: reject mismatches.
          final actual = _sha256Hash(cert);
          final pinned = actual == expectedHash;

          if (!pinned) {
            // Never log the actual cert content — only the hashes.
            logger.e(
              'CertPinning: FAILED for $host:$port. '
              'Expected=$expectedHash Got=$actual',
            );
          }

          // returning false → TLS handshake rejected.
          return pinned;
        };
      return client;
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the base64-encoded SHA-256 digest of [cert]'s DER bytes.
  static String _sha256Hash(X509Certificate cert) {
    final digest = sha256.convert(cert.der);
    return base64.encode(digest.bytes);
  }
}
