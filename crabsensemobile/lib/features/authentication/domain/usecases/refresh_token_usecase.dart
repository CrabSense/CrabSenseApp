import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for refreshing the current authentication token.
///
/// This use case encapsulates the business logic for token refresh:
/// 1. Uses the stored refresh token to obtain a new access token
/// 2. Updates stored tokens in secure storage
/// 3. Returns the current user with updated session
///
/// Token refresh should be triggered:
/// - Automatically 5 minutes before token expiry (proactive refresh)
/// - When API returns 401 Unauthorized (reactive refresh)
///
/// Following Clean Architecture, this use case coordinates the token refresh
/// operation between the domain layer and the repository.
///
/// Requirements: 1.3, 1.10
class RefreshTokenUseCase {
  const RefreshTokenUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the refresh token use case.
  ///
  /// Returns:
  /// - Right(User): Successfully refreshed with new token
  /// - Left(AuthenticationFailure.tokenExpired): Refresh token expired,
  ///   user must login again
  /// - Left(NetworkFailure): No internet connection, token refresh failed
  /// - Left(ServerFailure): Server error during token refresh
  ///
  /// If token refresh fails, the user should be redirected to the login screen
  /// to re-authenticate.
  Future<Either<Failure, User>> call() async {
    // Delegate to repository for token refresh operation
    return _repository.refreshToken();
  }
}
