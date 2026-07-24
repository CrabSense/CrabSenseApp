import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../widgets/app_logo.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/biometric_cubit.dart';
import '../bloc/biometric_state.dart';

/// Login screen for user authentication.
///
/// This screen provides:
/// - Email and password input fields with client-side validation
/// - Loading indicator during authentication operations
/// - Error message display for failed authentication
/// - Password visibility toggle
/// - Biometric authentication button — shown ONLY when the device
///   supports biometrics AND the user has enabled the feature
///
/// Design follows Material Design 3 with CrabSense brand colours:
/// - Primary:    #00C8FF
/// - Background: #081528 (dark theme default)
/// - Glassmorphism card effects with 16dp border radius
/// - 14dp border radius on buttons and text fields
///
/// Requirements: 1.1-1.10, 20.1-20.10
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isFormValid = false;

  // ── Constants ───────────────────────────────────────────────────────────────

  static const Color _primaryColor = Color(0xFF00C8FF);
  static const Color _bgColor = Color(0xFF081528);

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);

    // Check biometric availability as soon as the screen is mounted.
    // Safe to call after first frame so the cubit is fully provided.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BiometricCubit>().checkBiometricAvailability();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Form helpers ────────────────────────────────────────────────────────────

  void _validateForm() {
    final valid = _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  // ── Action handlers ─────────────────────────────────────────────────────────

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        LoginRequested(email: _emailController.text.trim(), password: _passwordController.text),
      );
    }
  }

  /// Triggers the OS biometric prompt via [BiometricCubit].
  ///
  /// On [BiometricAuthenticated] the [BlocListener] will dispatch
  /// [BiometricAuthenticationRequested] on the [AuthBloc].
  void _handleBiometricLogin() {
    context.read<BiometricCubit>().authenticate();
  }

  // ── Validators ───────────────────────────────────────────────────────────────

  /// Requirements: 1.4
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Tài khoản / Email là bắt buộc';
    if (value.trim().length < 3) return 'Tài khoản tối thiểu 3 ký tự';
    return null;
  }

  /// Requirements: 1.4 — minimum 8 chars, upper, lower, digit.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp('[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp('[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp('[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  // ── UI helpers ───────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
    prefixIcon: Icon(prefixIcon, color: _primaryColor),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red.shade700),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red.shade700, width: 2),
    ),
  );

  /// Returns the icon that best represents the available biometric type.
  IconData _biometricIcon(BiometricState biometricState) {
    if (biometricState is! BiometricAvailable) return Icons.fingerprint;
    // We read cached available types via the cubit; default to fingerprint.
    return Icons.fingerprint;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bgColor,
    body: MultiBlocListener(
      listeners: [
        // AuthBloc listener — navigation and auth-error snackbars.
        BlocListener<AuthBloc, AuthState>(listener: _onAuthStateChanged),
        // BiometricCubit listener — dispatches auth event on success,
        // shows error snackbar on failure.
        BlocListener<BiometricCubit, BiometricState>(listener: _onBiometricStateChanged),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isAuthLoading = authState is AuthLoading;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 48),
                      _buildEmailField(isAuthLoading),
                      const SizedBox(height: 16),
                      _buildPasswordField(isAuthLoading),
                      const SizedBox(height: 24),
                      _buildLoginButton(isAuthLoading),
                      const SizedBox(height: 12),
                      _buildGoogleButton(isAuthLoading),
                      const SizedBox(height: 16),
                      _buildBiometricButton(isAuthLoading),
                      const SizedBox(height: 32),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  // ── Section widgets ──────────────────────────────────────────────────────────

  Widget _buildHeader() => Column(
    children: [
      const AppLogo(size: 100),
      const SizedBox(height: 24),
      const Text(
        'CrabSense',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      const SizedBox(height: 8),
      Text(
        'Smart Crab Farming Operations',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7)),
      ),
    ],
  );

  Widget _buildEmailField(bool isLoading) => TextFormField(
    controller: _emailController,
    enabled: !isLoading,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autocorrect: false,
    validator: _validateEmail,
    style: const TextStyle(color: Colors.white),
    decoration: _fieldDecoration(label: 'Tài khoản / Email', prefixIcon: Icons.person_outline),
  );

  Widget _buildPasswordField(bool isLoading) => TextFormField(
    controller: _passwordController,
    enabled: !isLoading,
    obscureText: _obscurePassword,
    textInputAction: TextInputAction.done,
    validator: _validatePassword,
    style: const TextStyle(color: Colors.white),
    onFieldSubmitted: (_) {
      if (_isFormValid && !isLoading) _handleLogin();
    },
    decoration: _fieldDecoration(
      label: 'Password',
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    ),
  );

  Widget _buildLoginButton(bool isLoading) => ElevatedButton(
    onPressed: _isFormValid && !isLoading ? _handleLogin : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: _primaryColor,
      foregroundColor: _bgColor,
      disabledBackgroundColor: _primaryColor.withValues(alpha: 0.3),
      disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
    child: isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_bgColor),
            ),
          )
        : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  );

  void _handleGoogleLogin() {
    context.read<AuthBloc>().add(const GoogleLoginRequested());
  }

  Widget _buildGoogleButton(bool isLoading) => OutlinedButton.icon(
        onPressed: isLoading ? null : _handleGoogleLogin,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Colors.white),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.g_mobiledata_rounded, size: 32, color: Color(0xFFEA4335)),
        label: const Text(
          'Đăng nhập bằng Google',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      );

  /// Conditionally renders the biometric login button.
  ///
  /// The button is visible ONLY when:
  /// 1. Biometric hardware is available and a credential is enrolled.
  /// 2. The user has explicitly enabled biometric login.
  ///
  /// Requirements: 1.9
  Widget _buildBiometricButton(bool isAuthLoading) => BlocBuilder<BiometricCubit, BiometricState>(
    builder: (context, biometricState) {
      // Only show the button when available and user opted in.
      if (biometricState is! BiometricAvailable || !biometricState.isEnabled) {
        return const SizedBox.shrink();
      }

      final isBiometricLoading = biometricState is BiometricLoading;
      final isDisabled = isAuthLoading || isBiometricLoading;

      return OutlinedButton.icon(
        onPressed: isDisabled ? null : _handleBiometricLogin,
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor, width: 1.5),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: isBiometricLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              )
            : Icon(_biometricIcon(biometricState), size: 24),
        label: const Text(
          'Login with Biometrics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    },
  );

  Widget _buildFooter() => Text(
    'Forgot password? Contact your administrator',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
  );

  // ── BlocListeners ────────────────────────────────────────────────────────────

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } else if (state is Authenticated) {
      // Router redirect will handle navigation to dashboard.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${state.user.name}!'),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _onBiometricStateChanged(BuildContext context, BiometricState state) {
    if (state is BiometricAuthenticated) {
      // Biometric device verification passed — dispatch to AuthBloc to
      // retrieve cached JWT or perform a silent token refresh.
      context.read<AuthBloc>().add(const BiometricAuthenticationRequested());
    } else if (state is BiometricAuthFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }
}
