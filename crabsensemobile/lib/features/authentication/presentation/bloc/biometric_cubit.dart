import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/biometric_auth_service.dart';
import 'biometric_state.dart';

/// Cubit that manages biometric availability checks, preference toggles,
/// and the biometric authentication challenge flow.
///
/// Used by the login screen to:
/// 1. Check on start-up whether to show the biometric button.
/// 2. Trigger the OS biometric prompt when the user taps the button.
///
/// Used by the profile / settings screen to:
/// - Read the current preference.
/// - Toggle the preference on or off.
///
/// This Cubit intentionally does NOT perform the JWT exchange after a
/// successful biometric challenge — that responsibility stays in [AuthBloc].
/// Instead, it emits [BiometricAuthenticated] so the login screen can
/// dispatch [BiometricAuthenticationRequested] on the [AuthBloc].
///
/// Requirements: 1.9, 18.7
class BiometricCubit extends Cubit<BiometricState> {
  BiometricCubit({required this.biometricService}) : super(const BiometricInitial());

  final BiometricAuthService biometricService;

  // ---------------------------------------------------------------------------
  // Public methods
  // ---------------------------------------------------------------------------

  /// Checks whether the device supports biometrics and reads the user's
  /// stored preference. Emits one of:
  ///
  /// - [BiometricAvailable]: hardware ready, preference loaded
  /// - [BiometricNotEnrolled]: hardware present but no credential enrolled
  /// - [BiometricNotAvailable]: hardware absent or policy disabled
  ///
  /// Requirements: 1.9
  Future<void> checkBiometricAvailability() async {
    emit(const BiometricLoading());

    final result = await biometricService.checkAvailability();

    switch (result) {
      case BiometricResult.available:
        final isEnabled = await biometricService.isBiometricEnabled();
        emit(BiometricAvailable(isEnabled: isEnabled));
      case BiometricResult.notEnrolled:
        emit(const BiometricNotEnrolled());
      case BiometricResult.notAvailable:
      case BiometricResult.error:
        emit(const BiometricNotAvailable());
      case BiometricResult.success:
      case BiometricResult.failed:
        // These are authentication results, not availability results.
        emit(const BiometricNotAvailable());
    }
  }

  /// Presents the OS biometric prompt to the user. Emits:
  ///
  /// - [BiometricAuthenticated]: challenge passed — caller should proceed
  ///   with JWT-based authentication via [AuthBloc]
  /// - [BiometricAuthFailed]: challenge rejected or cancelled
  ///
  /// Requirements: 1.9
  Future<void> authenticate() async {
    emit(const BiometricLoading());

    final result = await biometricService.authenticate();

    switch (result) {
      case BiometricResult.success:
        emit(const BiometricAuthenticated());
      case BiometricResult.failed:
        emit(
          const BiometricAuthFailed(
            'Biometric authentication failed. Please try again '
            'or use your password.',
          ),
        );
      case BiometricResult.error:
        emit(
          const BiometricAuthFailed(
            'An error occurred during biometric authentication. '
            'Please use your password.',
          ),
        );
      case BiometricResult.available:
      case BiometricResult.notEnrolled:
      case BiometricResult.notAvailable:
        // Unexpected — treat as unavailable.
        emit(const BiometricNotAvailable());
    }
  }

  /// Enables or disables biometric login and persists the preference.
  ///
  /// Emits [BiometricPreferenceUpdated] on success or re-emits
  /// [BiometricAvailable] with the unchanged value on failure.
  ///
  /// Requirements: 1.9, 18.7
  Future<void> setBiometricEnabled({required bool enabled}) async {
    try {
      await biometricService.setBiometricEnabled(enabled: enabled);
      emit(BiometricPreferenceUpdated(isEnabled: enabled));
    } on Exception {
      // Re-read and emit current availability so the UI remains consistent.
      await checkBiometricAvailability();
    }
  }

  /// Reads the current preference without triggering an availability check.
  ///
  /// Useful for populating a settings toggle on first load.
  Future<bool> readBiometricEnabled() => biometricService.isBiometricEnabled();
}
