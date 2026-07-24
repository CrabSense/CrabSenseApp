import 'package:dartz/dartz.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for authenticating a user with email and password.
///
/// This use case encapsulates the business logic for user login:
/// 1. Validates input credentials
/// 2. Delegates authentication to the repository
/// 3. Returns the authenticated user or a failure
///
/// Following Clean Architecture, use cases represent single business operations
/// and coordinate between entities and repositories.
///
/// Requirements: 1.1, 1.2, 1.4, 1.5
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the login use case with the provided credentials.
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  ///
  /// Returns:
  /// - Right(User): Successfully authenticated user
  /// - Left(ValidationFailure): Input validation failed
  /// - Left(AuthenticationFailure.invalidCredentials): Invalid credentials
  /// - Left(AuthenticationFailure.accountLocked): Account temporarily locked
  /// - Left(NetworkFailure): No internet connection
  /// - Left(ServerFailure): Server error during authentication
  ///
  /// Validation rules:
  /// - Email must not be empty and must be a valid email format
  /// - Password must not be empty and must meet complexity requirements
  ///   (minimum 8 characters, uppercase, lowercase, number)
  Future<Either<Failure, User>> call({required String email, required String password}) async {
    // Validate email
    final emailValidation = _validateEmail(email);
    if (emailValidation != null) {
      return Left(emailValidation);
    }

    // Validate password
    final passwordValidation = _validatePassword(password);
    if (passwordValidation != null) {
      return Left(passwordValidation);
    }

    // Delegate to repository for actual authentication
    return _repository.login(email: email, password: password);
  }

  /// Validates the username or email format.
  ///
  /// Returns null if valid, or a ValidationFailure if invalid.
  ValidationFailure? _validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return const ValidationFailure.required('Tài khoản / Email');
    }

    if (trimmed.length < 3) {
      return const ValidationFailure(
        'Tài khoản phải có ít nhất 3 ký tự.',
        code: 'USERNAME_TOO_SHORT',
      );
    }

    return null;
  }

  /// Validates the password meets complexity requirements.
  ///
  /// Requirements (from Requirement 1.4):
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  ///
  /// Returns null if valid, or a ValidationFailure if invalid.
  ValidationFailure? _validatePassword(String password) {
    if (password.isEmpty) {
      return const ValidationFailure.required('Password');
    }

    if (password.length < 8) {
      return const ValidationFailure(
        'Password must be at least 8 characters long.',
        code: 'PASSWORD_TOO_SHORT',
      );
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return const ValidationFailure(
        'Password must contain at least one uppercase letter.',
        code: 'PASSWORD_NO_UPPERCASE',
      );
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return const ValidationFailure(
        'Password must contain at least one lowercase letter.',
        code: 'PASSWORD_NO_LOWERCASE',
      );
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return const ValidationFailure(
        'Password must contain at least one number.',
        code: 'PASSWORD_NO_NUMBER',
      );
    }

    return null;
  }
}
