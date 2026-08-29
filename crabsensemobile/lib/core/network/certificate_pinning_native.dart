import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';

/// Native-only certificate pinning adapter (Android / iOS / desktop).
///
/// This file uses `dart:io` and `package:dio/io.dart`, which are NOT
/// available on web.  Import this file only from non-web code paths
/// (i.e. guarded by `kIsWeb` checks) or via conditional imports.
///
/// Requirements: 23.2 (TLS 1.2+), 23.3 (certificate pinning)
class CertificatePinningNative {
  CertificatePinningNative._();

  /// Builds an [IOHttpClientAdapter] that enforces certificate pinning.
  static IOHttpClientAdapter buildAdapter({
    required Logger logger,
    String expectedHash = ApiConstants.certSha256Hash,
  }) =>
      IOHttpClientAdapter(
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
                logger.e(
                  'CertPinning: FAILED for $host:$port. '
                  'Expected=$expectedHash Got=$actual',
                );
              }

              return pinned;
            };
          return client;
        },
      );

  /// Returns the base64-encoded SHA-256 digest of [cert]'s DER bytes.
  static String _sha256Hash(X509Certificate cert) {
    final digest = sha256.convert(cert.der);
    return base64.encode(digest.bytes);
  }
}
