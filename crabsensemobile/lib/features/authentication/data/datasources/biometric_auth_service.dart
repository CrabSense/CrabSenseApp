import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'auth_local_data_source.dart' show AuthLocalDataSourceImpl;

/// Typed result of a biometric availability check or authentication attempt.
///
/// This enum is returned instead of raw booleans so that callers can handle
/// each outcome explicitly and display the right message or UI.
///
/// Requirements: 1.9
enum BiometricResult {
  /// Device hardware is present and at least one biometric is enrolled.
  available,

  /// Hardware exists but no biometric (fingerprint / face) is enrolled.
  notEnrolled,

  /// Device does not support biometric authentication at all.
  notAvailable,

  /// Biometric challenge passed — user is verified.
  success,

  /// Biometric challenge failed (wrong fingerprint, face not recognised).
  failed,

  /// An unexpected exception was thrown during the operation.
  error,
}

/// Service responsible for biometric authentication and preference storage.
///
/// This service wraps [LocalAuthentication] and [FlutterSecureStorage] to:
/// - Check hardware availability and enrollment status
/// - Perform fingerprint / Face ID challenges
/// - Persist the user's biometric-login preference in secure storage
///
/// Security notes:
/// - Biometric data is NEVER stored here; only a boolean preference flag.
/// - The preference is stored in [FlutterSecureStorage] (Keychain / Keystore),
///   NOT in SharedPreferences, so it is encrypted at rest.
/// - After a successful biometric challenge the caller is responsible for
///   using the cached JWT token (or refreshing it). This service only
///   performs the local device verification step.
///
/// Requirements: 1.9, 18.7, 23.4
abstract class BiometricAuthService {
  /// Returns [BiometricResult.available] when the device has biometric
  /// hardware and at least one fingerprint or face is enrolled.
  ///
  /// Returns [BiometricResult.notEnrolled] when the hardware is present
  /// but no biometric credential is enrolled in the OS.
  ///
  /// Returns [BiometricResult.notAvailable] when the device has no
  /// biometric hardware or the feature is disabled by device policy.
  Future<BiometricResult> checkAvailability();

  /// Returns the list of biometric types available on the device.
  ///
  /// Typical values: [BiometricType.fingerprint], [BiometricType.face],
  /// [BiometricType.iris].  Returns an empty list when unavailable.
  Future<List<BiometricType>> getAvailableBiometrics();

  /// Presents the OS biometric prompt and returns the challenge result.
  ///
  /// [localizedReason] is displayed in the system biometric dialog.
  ///
  /// Returns [BiometricResult.success] when the user is verified,
  /// [BiometricResult.failed] when the challenge is rejected, or
  /// [BiometricResult.error] on unexpected exceptions.
  Future<BiometricResult> authenticate({
    String localizedReason = 'Authenticate to access CrabSense',
  });

  /// Persists the user's choice to enable or disable biometric login.
  ///
  /// Stored under the key [BiometricAuthServiceImpl.biometricEnabledKey]
  /// in [FlutterSecureStorage].
  Future<void> setBiometricEnabled({required bool enabled});

  /// Reads the persisted biometric-login preference.
  ///
  /// Returns `false` by default when no preference has been saved yet.
  Future<bool> isBiometricEnabled();
}

/// [FlutterSecureStorage] + [LocalAuthentication] implementation of
/// [BiometricAuthService].
///
/// Platform behaviour:
/// - **iOS**: Uses Face ID when available, falls back to Touch ID.
///   Requires `NSFaceIDUsageDescription` in `ios/Runner/Info.plist`.
/// - **Android**: Uses [BiometricPrompt] backed by fingerprint, face, or
///   iris depending on what the device supports.  Requires
///   `USE_BIOMETRIC` permission in `AndroidManifest.xml`.
///
/// Requirements: 1.9, 18.7, 23.4
class BiometricAuthServiceImpl implements BiometricAuthService {
  const BiometricAuthServiceImpl({required this.localAuth, required this.secureStorage});

  final LocalAuthentication localAuth;
  final FlutterSecureStorage secureStorage;

  /// Secure-storage key for the biometric-enabled preference.
  ///
  /// Deliberately distinct from [AuthLocalDataSourceImpl._keyBiometricEnabled]
  /// so that the service can be used independently.
  static const String biometricEnabledKey = 'biometric_enabled';

  // ---------------------------------------------------------------------------
  // BiometricAuthService implementation
  // ---------------------------------------------------------------------------

  @override
  Future<BiometricResult> checkAvailability() async {
    try {
      // isDeviceSupported() returns true even when biometrics are enrolled,
      // but canCheckBiometrics specifically checks biometric hardware.
      final isSupported = await localAuth.isDeviceSupported();
      if (!isSupported) {
        return BiometricResult.notAvailable;
      }

      final canCheck = await localAuth.canCheckBiometrics;
      if (!canCheck) {
        // Hardware present but PIN/pattern only — no biometric enrolled.
        return BiometricResult.notEnrolled;
      }

      final available = await localAuth.getAvailableBiometrics();
      if (available.isEmpty) {
        return BiometricResult.notEnrolled;
      }

      return BiometricResult.available;
    } on Exception {
      return BiometricResult.notAvailable;
    }
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await localAuth.getAvailableBiometrics();
    } on Exception {
      return const [];
    }
  }

  @override
  Future<BiometricResult> authenticate({
    String localizedReason = 'Authenticate to access CrabSense',
  }) async {
    try {
      final result = await localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          // Keep the prompt open if the user switches away and returns.
          stickyAuth: true,
          // Use ONLY biometrics — no fallback to PIN/pattern from this prompt.
          biometricOnly: true,
        ),
      );

      return result ? BiometricResult.success : BiometricResult.failed;
    } on Exception {
      return BiometricResult.error;
    }
  }

  @override
  Future<void> setBiometricEnabled({required bool enabled}) async {
    await secureStorage.write(key: biometricEnabledKey, value: enabled.toString());
  }

  @override
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await secureStorage.read(key: biometricEnabledKey);
      return value == 'true';
    } on Exception {
      return false;
    }
  }
}
