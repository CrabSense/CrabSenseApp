import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Repository interface for authentication operations.
///
/// This interface defines the contract for authentication data operations
/// following Clean Architecture principles. The domain layer depends on this
/// abstraction, not on concrete implementations.
///
/// Implementations should handle:
/// - Remote authentication via API
/// - Local session management
/// - Token storage and refresh
/// - Error mapping to domain Failures
///
/// All methods return Either<Failure, Result> for functional error handling:
/// - Left(Failure): Operation failed with a specific failure reason
/// - Right(Result): Operation succeeded with the result data
abstract class AuthRepository {
  /// Authenticates a user with email and password credentials.
  ///
  /// Returns:
  /// - Right(User): Successfully authenticated user with valid JWT token
  /// - Left(AuthenticationFailure.invalidCredentials): Invalid email/password
  /// - Left(AuthenticationFailure.accountLocked): Too many failed attempts
  /// - Left(NetworkFailure): No internet connection
  /// - Left(ServerFailure): Server error during authentication
  ///
  /// Requirements: 1.1, 1.2, 1.5
  Future<Either<Failure, User>> login({required String email, required String password});

  /// Authenticates a user via Google OAuth ID token.
  Future<Either<Failure, User>> loginWithGoogle({String? idToken});

  /// Logs out the current user and clears stored credentials.
  ///
  /// This operation:
  /// - Invalidates the current JWT token on the server
  /// - Clears stored tokens from secure storage
  /// - Clears user session data
  ///
  /// Returns:
  /// - Right(void): Successfully logged out
  /// - Left(NetworkFailure): No internet (local logout still performed)
  /// - Left(ServerFailure): Server error during logout
  ///
  /// Note: Even if server logout fails, local session is always cleared.
  ///
  /// Requirements: 1.3
  Future<Either<Failure, void>> logout();

  /// Refreshes the current authentication token.
  ///
  /// This operation:
  /// - Uses the stored refresh token to obtain a new access token
  /// - Updates stored tokens in secure storage
  /// - Returns the current user with updated session
  ///
  /// Returns:
  /// - Right(User): Successfully refreshed with new token
  /// - Left(AuthenticationFailure.tokenExpired): Refresh token expired
  /// - Left(NetworkFailure): No internet connection
  /// - Left(ServerFailure): Server error during refresh
  ///
  /// Requirements: 1.3, 1.10
  Future<Either<Failure, User>> refreshToken();

  /// Authenticates a user using biometric authentication.
  ///
  /// This operation:
  /// - Verifies biometric (fingerprint/face) with device
  /// - Retrieves stored credentials from secure storage
  /// - Exchanges credentials for a new JWT token
  ///
  /// Returns:
  /// - Right(User): Successfully authenticated with biometrics
  /// - Left(AuthenticationFailure.biometricFailed): Biometric verification failed
  /// - Left(PermissionFailure): Biometric permission denied
  /// - Left(CacheFailure): No stored credentials found
  /// - Left(NetworkFailure): No internet connection
  ///
  /// Requirements: 1.9
  Future<Either<Failure, User>> loginWithBiometric();

  /// Checks if the current user session is valid.
  ///
  /// Returns:
  /// - Right(true): Valid session with non-expired token
  /// - Right(false): No session or expired token
  /// - Left(CacheFailure): Error checking local session
  ///
  /// Requirements: 1.8
  Future<Either<Failure, bool>> isAuthenticated();

  /// Gets the currently authenticated user from local storage.
  ///
  /// Returns:
  /// - Right(User): Current user if authenticated
  /// - Left(AuthenticationFailure.tokenExpired): Session expired
  /// - Left(CacheFailure): Error reading local user data
  ///
  /// Requirements: 1.8
  Future<Either<Failure, User>> getCurrentUser();

  /// Changes the password for the current user.
  ///
  /// Returns:
  /// - Right(void): Password successfully changed
  /// - Left(AuthenticationFailure.invalidCredentials): Current password incorrect
  /// - Left(ValidationFailure): New password doesn't meet requirements
  /// - Left(NetworkFailure): No internet connection
  /// - Left(ServerFailure): Server error during password change
  ///
  /// Requirements: 18.6
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Enables or disables biometric authentication for the current user.
  ///
  /// Returns:
  /// - Right(void): Biometric preference saved
  /// - Left(PermissionFailure): Biometric permission denied
  /// - Left(CacheFailure): Error saving preference
  ///
  /// Requirements: 1.9, 18.7
  Future<Either<Failure, void>> setBiometricEnabled(bool enabled);

  /// Checks if biometric authentication is enabled for the current user.
  ///
  /// Returns:
  /// - Right(bool): Biometric enabled status
  /// - Left(CacheFailure): Error reading preference
  ///
  /// Requirements: 1.9, 18.7
  Future<Either<Failure, bool>> isBiometricEnabled();
}
