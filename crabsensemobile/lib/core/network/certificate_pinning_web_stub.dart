import 'package:logger/logger.dart';

import '../constants/api_constants.dart';

/// Web stub for [CertificatePinningNative].
///
/// On web platforms `dart:io` is not available, so certificate pinning
/// via [IOHttpClientAdapter] is not possible.  This stub satisfies the
/// conditional import in `certificate_pinning.dart` and always returns
/// `null`.
class CertificatePinningNative {
  CertificatePinningNative._();

  /// Always returns `null` on web — the browser manages TLS.
  // ignore: avoid_unused_parameters
  static dynamic buildAdapter({
    required Logger logger,
    String expectedHash = ApiConstants.certSha256Hash,
  }) =>
      null;
}
