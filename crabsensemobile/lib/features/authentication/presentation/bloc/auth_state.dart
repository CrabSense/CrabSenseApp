import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Base class for all authentication states.
///
/// States represent the current condition of the authentication feature.
/// All states should extend this class and use Equatable for value equality.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the BLoC is first created.
///
/// The app has not yet checked for an existing session.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when the user is not authenticated.
///
/// This state is entered after:
/// - Initial authentication check finds no valid session
/// - User logs out
/// - Token expires and cannot be refreshed
///
/// Requirements: 1.3, 1.8
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// State when authentication operation is in progress.
///
/// This state indicates:
/// - Login request is being processed
/// - Token refresh is in progress
/// - Biometric authentication is being performed
///
/// Requirements: 1.1, 1.10
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when the user is successfully authenticated.
///
/// This state contains the authenticated user data and is entered after:
/// - Successful login with email/password
/// - Successful biometric authentication
/// - Successful token refresh
/// - Valid session found on app startup
///
/// Requirements: 1.1, 1.8, 1.9, 1.10
class Authenticated extends AuthState {
  const Authenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

/// State when an authentication error occurs.
///
/// This state contains the error message and is entered when:
/// - Login fails with invalid credentials
/// - Network connection is unavailable
/// - Server returns an error
/// - Account is locked
/// - Token refresh fails
/// - Biometric authentication fails
///
/// Requirements: 1.2, 1.5, 1.7, 1.9
class AuthError extends AuthState {
  const AuthError(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
