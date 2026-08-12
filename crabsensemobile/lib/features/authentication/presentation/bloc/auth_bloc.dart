import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Business Logic Component for authentication operations.
///
/// This BLoC manages the authentication state of the application and handles:
/// - User login with email and password
/// - User logout
/// - Checking authentication status
/// - Token refresh
/// - Biometric authentication
///
/// The BLoC follows Clean Architecture principles by depending on use cases
/// and the repository interface, not on concrete implementations.
///
/// State Flow:
/// - AuthInitial → initial state on app startup
/// - Unauthenticated → no valid session
/// - AuthLoading → operation in progress
/// - Authenticated → user successfully authenticated
/// - AuthError → operation failed
///
/// Requirements: 1.1-1.10, 18.6-18.7
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.refreshTokenUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthenticationStatusRequested>(_onAuthenticationStatusRequested);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<BiometricAuthenticationRequested>(_onBiometricAuthenticationRequested);
  }

  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final AuthRepository authRepository;

  /// Handles the login request event.
  ///
  /// Validates credentials and authenticates the user via the LoginUseCase.
  /// Emits:
  /// - AuthLoading: while login is in progress
  /// - Authenticated: if login succeeds
  /// - AuthError: if login fails
  ///
  /// Requirements: 1.1, 1.2, 1.5
  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await loginUseCase(email: event.email, password: event.password);

    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (user) => emit(Authenticated(user)),
    );
  }

  /// Handles Google OAuth login request event.
  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await authRepository.loginWithGoogle(idToken: event.idToken);

    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (user) => emit(Authenticated(user)),
    );
  }

  /// Handles the logout request event.
  ///
  /// Clears the user session and stored credentials.
  ///
  /// Emits [Unauthenticated] directly (no [AuthLoading]) to avoid racing
  /// GoRouter redirect with open dialogs/overlays → Duplicate GlobalKey.
  ///
  /// Requirements: 1.3
  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    final result = await logoutUseCase();

    result.fold(
      // Even if server logout fails, we consider it successful locally
      (_) => emit(const Unauthenticated()),
      (_) => emit(const Unauthenticated()),
    );
  }

  /// Handles the authentication status check event.
  ///
  /// Checks if the user has a valid session on app startup.
  /// Emits:
  /// - Authenticated: if valid session exists
  /// - Unauthenticated: if no valid session
  ///
  /// Requirements: 1.8
  Future<void> _onAuthenticationStatusRequested(
    AuthenticationStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isAuthResult = await authRepository.isAuthenticated();

    await isAuthResult.fold((_) async => emit(const Unauthenticated()), (isAuthenticated) async {
      if (isAuthenticated) {
        final userResult = await authRepository.getCurrentUser();
        userResult.fold((_) => emit(const Unauthenticated()), (user) => emit(Authenticated(user)));
      } else {
        emit(const Unauthenticated());
      }
    });
  }

  /// Handles the token refresh request event.
  ///
  /// Refreshes the access token using the stored refresh token.
  /// This is typically called automatically before the token expires.
  /// Emits:
  /// - Authenticated: if token refresh succeeds
  /// - Unauthenticated: if token refresh fails (session expired)
  /// - AuthError: if refresh fails due to network or server error
  ///
  /// Requirements: 1.3, 1.10
  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await refreshTokenUseCase();

    result.fold((failure) {
      // If token is expired, emit Unauthenticated
      if (failure.code == 'TOKEN_EXPIRED') {
        emit(const Unauthenticated());
      } else {
        emit(AuthError(failure.message, code: failure.code));
      }
    }, (user) => emit(Authenticated(user)));
  }

  /// Handles the biometric authentication request event.
  ///
  /// Authenticates the user using device biometrics (fingerprint/face).
  /// Emits:
  /// - AuthLoading: while biometric authentication is in progress
  /// - Authenticated: if biometric authentication succeeds
  /// - AuthError: if biometric authentication fails
  ///
  /// Requirements: 1.9
  Future<void> _onBiometricAuthenticationRequested(
    BiometricAuthenticationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await authRepository.loginWithBiometric();

    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (user) => emit(Authenticated(user)),
    );
  }
}
