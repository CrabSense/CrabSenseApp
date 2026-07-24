import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for logging out the current user.
///
/// This use case encapsulates the business logic for user logout:
/// 1. Invalidates the current JWT token on the server
/// 2. Clears stored tokens from secure storage
/// 3. Clears user session data
///
/// Following Clean Architecture, this use case coordinates the logout operation
/// between the domain layer and the repository.
///
/// Note: Even if server logout fails due to network issues, the local session
/// will still be cleared to ensure the user is logged out from the device.
///
/// Requirements: 1.3, 18.9
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the logout use case.
  ///
  /// Returns:
  /// - Right(void): Successfully logged out
  /// - Left(NetworkFailure): No internet connection (local logout still performed)
  /// - Left(ServerFailure): Server error during logout (local logout still performed)
  ///
  /// The use case ensures that even if server-side logout fails, the local
  /// session is always cleared, so the user cannot continue using the app
  /// with an invalid session.
  Future<Either<Failure, void>> call() async {
    // Delegate to repository for logout operation
    // Repository implementation should handle clearing local data
    // even if server logout fails
    return _repository.logout();
  }
}
