import 'package:equatable/equatable.dart';

import '../screens/login_screen.dart' show LoginScreen;

import 'auth_bloc.dart' show AuthBloc;

import 'auth_event.dart' show BiometricAuthenticationRequested;

import 'biometric_cubit.dart' show BiometricCubit;

import 'bloc.dart' show BiometricCubit, BiometricAuthenticationRequested, AuthBloc;

/// Base class for all biometric-related states.
///
/// Used by [BiometricCubit] to drive conditional rendering of the biometric
/// login button on the [LoginScreen] and the toggle in profile/settings.
///
/// Requirements: 1.9, 18.7
abstract class BiometricState extends Equatable {
  const BiometricState();

  @override
  List<Object?> get props => [];
}

/// Initial state — biometric availability has not yet been checked.
class BiometricInitial extends BiometricState {
  const BiometricInitial();
}

/// Availability check or authentication is in progress.
class BiometricLoading extends BiometricState {
  const BiometricLoading();
}

/// Device supports biometric authentication and at least one credential
/// is enrolled.
///
/// [isEnabled] reflects whether the user has opted in to biometric login.
/// When `true` the login screen should show the biometric button.
class BiometricAvailable extends BiometricState {
  const BiometricAvailable({required this.isEnabled});

  /// Whether the user has enabled biometric login in their preferences.
  final bool isEnabled;

  @override
  List<Object?> get props => [isEnabled];
}

/// Device hardware is present but no biometric credential is enrolled.
///
/// Show a prompt directing the user to enroll in device settings.
class BiometricNotEnrolled extends BiometricState {
  const BiometricNotEnrolled();
}

/// Device does not support biometric authentication.
///
/// The biometric login button should be hidden entirely.
class BiometricNotAvailable extends BiometricState {
  const BiometricNotAvailable();
}

/// Biometric challenge completed successfully.
///
/// The caller (e.g. [LoginScreen]) should proceed to load cached credentials
/// and dispatch [BiometricAuthenticationRequested] on [AuthBloc].
class BiometricAuthenticated extends BiometricState {
  const BiometricAuthenticated();
}

/// Biometric challenge failed or was cancelled by the user.
///
/// [message] contains a user-friendly description of what went wrong.
class BiometricAuthFailed extends BiometricState {
  const BiometricAuthFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The biometric-enabled preference was toggled successfully.
///
/// [isEnabled] reflects the new preference value.
class BiometricPreferenceUpdated extends BiometricState {
  const BiometricPreferenceUpdated({required this.isEnabled});

  final bool isEnabled;

  @override
  List<Object?> get props => [isEnabled];
}
