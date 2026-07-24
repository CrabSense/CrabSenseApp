import 'package:bloc_test/bloc_test.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:crabsensemobile/features/authentication/domain/usecases/login_usecase.dart';
import 'package:crabsensemobile/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:crabsensemobile/features/authentication/domain/usecases/refresh_token_usecase.dart';
import 'package:crabsensemobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:crabsensemobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:crabsensemobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Manual mocks (no mocktail/mockito dependency needed)
// ---------------------------------------------------------------------------

/// Configurable mock for [AuthRepository].
class MockAuthRepository implements AuthRepository {
  // Configurable responses
  Future<Either<Failure, User>> Function({required String email, required String password})?
  onLogin;

  Future<Either<Failure, void>> Function()? onLogout;

  Future<Either<Failure, User>> Function()? onRefreshToken;

  Future<Either<Failure, User>> Function()? onLoginWithBiometric;

  Future<Either<Failure, bool>> Function()? onIsAuthenticated;

  Future<Either<Failure, User>> Function()? onGetCurrentUser;

  @override
  Future<Either<Failure, User>> login({required String email, required String password}) async =>
      onLogin != null ? onLogin!(email: email, password: password) : Right(_testUser());

  @override
  Future<Either<Failure, void>> logout() async =>
      onLogout != null ? onLogout!() : const Right(null);

  @override
  Future<Either<Failure, User>> refreshToken() async =>
      onRefreshToken != null ? onRefreshToken!() : Right(_testUser());

  @override
  Future<Either<Failure, User>> loginWithBiometric() async =>
      onLoginWithBiometric != null ? onLoginWithBiometric!() : Right(_testUser());

  @override
  Future<Either<Failure, bool>> isAuthenticated() async =>
      onIsAuthenticated != null ? onIsAuthenticated!() : const Right(false);

  @override
  Future<Either<Failure, User>> getCurrentUser() async =>
      onGetCurrentUser != null ? onGetCurrentUser!() : Right(_testUser());

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => const Right(null);

  @override
  Future<Either<Failure, void>> setBiometricEnabled(bool enabled) async => const Right(null);

  @override
  Future<Either<Failure, bool>> isBiometricEnabled() async => const Right(false);
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

User _testUser() => User(
  id: 'user-123',
  email: 'operator@crabsense.com',
  name: 'Test Operator',
  role: UserRole.fieldOperator,
  assignedFarmIds: const ['farm-1'],
  createdAt: DateTime(2024),
);

// ---------------------------------------------------------------------------
// Helper to build a bloc with a given mock repository
// ---------------------------------------------------------------------------

AuthBloc _buildBloc(MockAuthRepository repo) => AuthBloc(
  loginUseCase: LoginUseCase(repo),
  logoutUseCase: LogoutUseCase(repo),
  refreshTokenUseCase: RefreshTokenUseCase(repo),
  authRepository: repo,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Shared test data
  const validEmail = 'operator@crabsense.com';
  const validPassword = 'Password1'; // meets: 8+ chars, upper, lower, digit
  const invalidEmail = 'wrong@crabsense.com';
  const invalidPassword = 'Password1'; // same length but wrong credentials

  group('AuthBloc', () {
    // -------------------------------------------------------------------------
    // Initial state
    // -------------------------------------------------------------------------

    test('initial state is AuthInitial', () {
      final repo = MockAuthRepository();
      final bloc = _buildBloc(repo);
      expect(bloc.state, const AuthInitial());
      bloc.close();
    });

    // -------------------------------------------------------------------------
    // Login success — Requirement 1.1, 25.1
    // -------------------------------------------------------------------------

    group('LoginRequested - success', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when login succeeds',
        build: () {
          final repo = MockAuthRepository()
            ..onLogin = ({required email, required password}) async => Right(_testUser());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const LoginRequested(email: validEmail, password: validPassword)),
        expect: () => [const AuthLoading(), Authenticated(_testUser())],
      );

      blocTest<AuthBloc, AuthState>(
        'authenticated state contains the user returned by the use case',
        build: () {
          final repo = MockAuthRepository()
            ..onLogin = ({required email, required password}) async => Right(_testUser());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const LoginRequested(email: validEmail, password: validPassword)),
        expect: () => [
          const AuthLoading(),
          isA<Authenticated>().having((s) => s.user.email, 'user email', validEmail),
        ],
      );
    });

    // -------------------------------------------------------------------------
    // Login failure — Requirement 1.2, 25.1
    // -------------------------------------------------------------------------

    group('LoginRequested - failure', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when credentials are invalid',
        build: () {
          final repo = MockAuthRepository()
            ..onLogin = ({required email, required password}) async =>
                const Left(AuthenticationFailure.invalidCredentials());
          return _buildBloc(repo);
        },
        act: (bloc) =>
            bloc.add(const LoginRequested(email: invalidEmail, password: invalidPassword)),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>().having((s) => s.code, 'error code', 'INVALID_CREDENTIALS'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when network is unavailable',
        build: () {
          final repo = MockAuthRepository()
            ..onLogin = ({required email, required password}) async => const Left(NetworkFailure());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const LoginRequested(email: validEmail, password: validPassword)),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>().having((s) => s.code, 'error code', 'NETWORK_ERROR'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] with validation error '
        'when email is empty',
        // LoginUseCase validates before hitting the repository
        build: () => _buildBloc(MockAuthRepository()),
        act: (bloc) => bloc.add(const LoginRequested(email: '', password: validPassword)),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>().having((s) => s.code, 'error code', 'REQUIRED_FIELD'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] with validation error '
        'when password is too short',
        build: () => _buildBloc(MockAuthRepository()),
        act: (bloc) => bloc.add(const LoginRequested(email: validEmail, password: 'Abc1')),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>().having((s) => s.code, 'error code', 'PASSWORD_TOO_SHORT'),
        ],
      );
    });

    // -------------------------------------------------------------------------
    // Account lockout — Requirement 1.5, 25.1
    //
    // After 3 consecutive failed login attempts the Authentication_Service
    // SHALL temporarily lock the account for 15 minutes.
    //
    // The BLoC reflects this by emitting AuthError with code 'ACCOUNT_LOCKED'
    // when the repository returns AuthenticationFailure.accountLocked().
    // -------------------------------------------------------------------------

    group('Account lockout after 3 consecutive failures (Req 1.5)', () {
      blocTest<AuthBloc, AuthState>(
        'emits AuthError with ACCOUNT_LOCKED code '
        'when repository signals account lockout',
        build: () {
          final repo = MockAuthRepository()
            ..onLogin = ({required email, required password}) async =>
                const Left(AuthenticationFailure.accountLocked());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const LoginRequested(email: validEmail, password: validPassword)),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>().having((s) => s.code, 'error code', 'ACCOUNT_LOCKED'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'locked account error message mentions 15 minutes',
        build: () {
          final repo = MockAuthRepository()
            ..onLogin = ({required email, required password}) async =>
                const Left(AuthenticationFailure.accountLocked());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const LoginRequested(email: validEmail, password: validPassword)),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>().having((s) => s.message, 'error message', contains('15 minutes')),
        ],
      );

      test('after 3 consecutive failed attempts each triggers '
          'AuthLoading then AuthError', () async {
        var callCount = 0;
        final repo = MockAuthRepository()
          ..onLogin = ({required email, required password}) async {
            callCount++;
            if (callCount < 3) {
              return const Left(AuthenticationFailure.invalidCredentials());
            }
            // 3rd attempt — server locks account
            return const Left(AuthenticationFailure.accountLocked());
          };

        final bloc = _buildBloc(repo);
        final states = <AuthState>[];
        final subscription = bloc.stream.listen(states.add);

        // Attempt 1 — invalid credentials
        bloc.add(const LoginRequested(email: validEmail, password: validPassword));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Attempt 2 — invalid credentials
        bloc.add(const LoginRequested(email: validEmail, password: validPassword));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Attempt 3 — account locked
        bloc.add(const LoginRequested(email: validEmail, password: validPassword));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();
        await bloc.close();

        // 3 login attempts → 3×[AuthLoading, AuthError] = 6 states
        expect(states.length, 6);
        expect(states[0], const AuthLoading());
        expect(states[1], isA<AuthError>().having((s) => s.code, 'code', 'INVALID_CREDENTIALS'));
        expect(states[2], const AuthLoading());
        expect(states[3], isA<AuthError>().having((s) => s.code, 'code', 'INVALID_CREDENTIALS'));
        expect(states[4], const AuthLoading());
        // 3rd attempt → account locked
        expect(states[5], isA<AuthError>().having((s) => s.code, 'code', 'ACCOUNT_LOCKED'));
      });
    });

    // -------------------------------------------------------------------------
    // Token refresh — Requirement 1.10, 25.1
    // -------------------------------------------------------------------------

    group('TokenRefreshRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Authenticated] when token refresh succeeds',
        build: () {
          final repo = MockAuthRepository()..onRefreshToken = () async => Right(_testUser());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const TokenRefreshRequested()),
        expect: () => [Authenticated(_testUser())],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] when refresh token is expired '
        '(TOKEN_EXPIRED code)',
        build: () {
          final repo = MockAuthRepository()
            ..onRefreshToken = () async => const Left(AuthenticationFailure.tokenExpired());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const TokenRefreshRequested()),
        expect: () => [const Unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthError] when refresh fails with a network error',
        build: () {
          final repo = MockAuthRepository()
            ..onRefreshToken = () async => const Left(NetworkFailure());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const TokenRefreshRequested()),
        expect: () => [isA<AuthError>().having((s) => s.code, 'error code', 'NETWORK_ERROR')],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthError] when refresh fails with a server error',
        build: () {
          final repo = MockAuthRepository()
            ..onRefreshToken = () async => const Left(ServerFailure.internal());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const TokenRefreshRequested()),
        expect: () => [
          isA<AuthError>().having((s) => s.code, 'error code', 'INTERNAL_SERVER_ERROR'),
        ],
      );
    });

    // -------------------------------------------------------------------------
    // Logout
    // -------------------------------------------------------------------------

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Unauthenticated] when logout succeeds',
        build: () {
          final repo = MockAuthRepository()..onLogout = () async => const Right(null);
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [const AuthLoading(), const Unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Unauthenticated] even when server logout fails',
        build: () {
          final repo = MockAuthRepository()..onLogout = () async => const Left(NetworkFailure());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        // BLoC treats both fold branches as Unauthenticated (local-first logout)
        expect: () => [const AuthLoading(), const Unauthenticated()],
      );
    });

    // -------------------------------------------------------------------------
    // Authentication status check
    // -------------------------------------------------------------------------

    group('AuthenticationStatusRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Authenticated] when valid session exists',
        build: () {
          final repo = MockAuthRepository();
          repo.onIsAuthenticated = () async => const Right(true);
          repo.onGetCurrentUser = () async => Right(_testUser());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const AuthenticationStatusRequested()),
        expect: () => [Authenticated(_testUser())],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] when no valid session exists',
        build: () {
          final repo = MockAuthRepository()..onIsAuthenticated = () async => const Right(false);
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const AuthenticationStatusRequested()),
        expect: () => [const Unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] when isAuthenticated returns a failure',
        build: () {
          final repo = MockAuthRepository()
            ..onIsAuthenticated = () async => const Left(CacheFailure());
          return _buildBloc(repo);
        },
        act: (bloc) => bloc.add(const AuthenticationStatusRequested()),
        expect: () => [const Unauthenticated()],
      );
    });
  });
}
