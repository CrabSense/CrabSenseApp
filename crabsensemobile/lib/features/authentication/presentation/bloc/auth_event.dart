import 'package:equatable/equatable.dart';

/// Base class for all authentication events.
///
/// Events represent user actions or external triggers that cause state changes
/// in the AuthBloc. All events should extend this class and use Equatable for
/// value equality comparisons.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when the user attempts to login with email and password.
///
/// Requirements: 1.1, 1.2
class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Event triggered when the user attempts Google OAuth login.
class GoogleLoginRequested extends AuthEvent {
  const GoogleLoginRequested({this.idToken});

  final String? idToken;

  @override
  List<Object?> get props => [idToken];
}

/// Event triggered when the user attempts to logout.
///
/// Requirements: 1.3
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event triggered when the app checks for existing authentication.
///
/// This is typically called on app startup to check if the user has
/// a valid session.
///
/// Requirements: 1.8
class AuthenticationStatusRequested extends AuthEvent {
  const AuthenticationStatusRequested();
}

/// Event triggered when the authentication token needs to be refreshed.
///
/// This is typically called automatically when the access token is about
/// to expire.
///
/// Requirements: 1.10
class TokenRefreshRequested extends AuthEvent {
  const TokenRefreshRequested();
}

/// Event triggered when the user attempts biometric authentication.
///
/// Requirements: 1.9
class BiometricAuthenticationRequested extends AuthEvent {
  const BiometricAuthenticationRequested();
}
