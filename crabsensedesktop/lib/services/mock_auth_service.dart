/// Demo credentials for mock login.
class MockCredentials {
  static const demoEmail = 'demo@crabfarm.com';
  static const demoUsername = 'admin';
  static const demoPassword = '123456';

  static const hint =
      'Demo: demo@crabfarm.com hoặc admin / mật khẩu: 123456';
}

class MockAuthService {
  Future<MockAuthResult> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final input = emailOrUsername.trim().toLowerCase();
    final pass = password;

    final validUser = input == MockCredentials.demoEmail ||
        input == MockCredentials.demoUsername;
    final validPass = pass == MockCredentials.demoPassword;

    if (validUser && validPass) {
      return MockAuthResult.success(
        displayName: input == MockCredentials.demoUsername
            ? 'Khanh'
            : 'Demo User',
        email: MockCredentials.demoEmail,
      );
    }

    return MockAuthResult.failure('Email hoặc mật khẩu không đúng.');
  }
}

class MockAuthResult {
  const MockAuthResult._({
    required this.success,
    this.displayName,
    this.email,
    this.errorMessage,
  });

  factory MockAuthResult.success({
    required String displayName,
    required String email,
  }) =>
      MockAuthResult._(
        success: true,
        displayName: displayName,
        email: email,
      );

  factory MockAuthResult.failure(String message) => MockAuthResult._(
        success: false,
        errorMessage: message,
      );

  final bool success;
  final String? displayName;
  final String? email;
  final String? errorMessage;
}
