import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../widgets/app_logo.dart';
import '../../../../widgets/branded_loading_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/biometric_cubit.dart';
import '../bloc/biometric_state.dart';

/// Màn đăng nhập — Light theme, teal primary, thân thiện.
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

  // Brand colors — đồng bộ với CrabSenseColors theme mới
  static const _primary = Color(0xFF2ECC71);      // Xanh lá tươi
  static const _primaryDark = Color(0xFF27AE60);  // Xanh lá đậm
  static const _textPrimary = Color(0xFF1A2E3B);
  static const _textSecondary = Color(0xFF5A7184);
  static const _textDisabled = Color(0xFF9DB3C2);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceVariant = Color(0xFFF0F4F8);
  static const _outline = Color(0xFFDDE4EB);
  static const _background = Color(0xFFF5F7FA);
  static const _error = Color(0xFFE74C3C);
  static const _danger = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
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

  void _validateForm() {
    final valid = _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _handleBiometricLogin() {
    context.read<BiometricCubit>().authenticate();
  }

  void _handleGoogleLogin() {
    context.read<AuthBloc>().add(const GoogleLoginRequested());
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tài khoản / Email là bắt buộc';
    }
    if (value.trim().length < 3) return 'Tài khoản tối thiểu 3 ký tự';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mật khẩu là bắt buộc';
    if (value.length < 8) return 'Mật khẩu tối thiểu 8 ký tự';
    if (!value.contains(RegExp('[A-Z]'))) {
      return 'Mật khẩu cần ít nhất 1 chữ hoa';
    }
    if (!value.contains(RegExp('[a-z]'))) {
      return 'Mật khẩu cần ít nhất 1 chữ thường';
    }
    if (!value.contains(RegExp('[0-9]'))) {
      return 'Mật khẩu cần ít nhất 1 chữ số';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(listener: _onAuthStateChanged),
          BlocListener<BiometricCubit, BiometricState>(
            listener: _onBiometricStateChanged,
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is AuthLoading) {
              return const BrandedLoadingScreen(
                message: 'Đang đăng nhập…',
                subtitle: 'Vui lòng chờ trong giây lát',
              );
            }

            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildForm(),
                          const SizedBox(height: 20),
                          _buildDivider(),
                          const SizedBox(height: 16),
                          _buildSocialButtons(),
                          const SizedBox(height: 24),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const AppLogo(size: 80),
        ),
        const SizedBox(height: 20),
        Text(
          'CrabSense',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Giám sát nuôi cua thông minh',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Form card ────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Đăng nhập',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhập tài khoản để vào trung tâm điều hành',
            style: GoogleFonts.inter(
                fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 20),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: _validateEmail,
            style: GoogleFonts.inter(
                fontSize: 15, color: _textPrimary),
            decoration: _fieldDeco(
              label: 'Tài khoản / Email',
              prefixIcon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: _validatePassword,
            style: GoogleFonts.inter(
                fontSize: 15, color: _textPrimary),
            onFieldSubmitted: (_) {
              if (_isFormValid) _handleLogin();
            },
            decoration: _fieldDeco(
              label: 'Mật khẩu',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _textDisabled,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 4),
                foregroundColor: _primary,
              ),
              child: Text(
                'Quên mật khẩu?',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Login button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isFormValid ? _handleLogin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: _primary.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Đăng nhập',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Biometric button
          _buildBiometricButton(),
        ],
      ),
    );
  }

  InputDecoration _fieldDeco({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          GoogleFonts.inter(fontSize: 14, color: _textSecondary),
      prefixIcon: Icon(prefixIcon, color: _primary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _surfaceVariant,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 2),
      ),
      errorStyle:
          GoogleFonts.inter(fontSize: 12, color: _error),
    );
  }

  Widget _buildBiometricButton() {
    return BlocBuilder<BiometricCubit, BiometricState>(
      builder: (context, biometricState) {
        if (biometricState is! BiometricAvailable ||
            !biometricState.isEnabled) {
          return const SizedBox.shrink();
        }
        final loading = biometricState is BiometricLoading;
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: OutlinedButton.icon(
            onPressed: loading ? null : _handleBiometricLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _outline, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  )
                : const Icon(Icons.fingerprint_rounded, size: 22),
            label: Text(
              'Đăng nhập sinh trắc học',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  // ── Social divider ────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
            child: Divider(color: Color(0xFFDFE6E9), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Hoặc đăng nhập với',
            style: GoogleFonts.inter(
                fontSize: 13, color: _textSecondary),
          ),
        ),
        const Expanded(
            child: Divider(color: Color(0xFFDFE6E9), thickness: 1)),
      ],
    );
  }

  // ── Social buttons ────────────────────────────────────────────────

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            iconColor: const Color(0xFFEA4335),
            onPressed: _handleGoogleLogin,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: 'Facebook',
            icon: Icons.facebook_rounded,
            iconColor: const Color(0xFF1877F2),
            onPressed: () {
              // TODO: Facebook login
            },
          ),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Text(
      'Chưa có tài khoản? Liên hệ quản trị viên',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: _textSecondary,
      ),
    );
  }

  // ── Bloc listeners ────────────────────────────────────────────────

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (state is Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chào mừng trở lại, ${state.user.name}!'),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _onBiometricStateChanged(
      BuildContext context, BiometricState state) {
    if (state is BiometricAuthenticated) {
      context
          .read<AuthBloc>()
          .add(const BiometricAuthenticationRequested());
    } else if (state is BiometricAuthFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: const Color(0xFFE17055),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

/// Nút mạng xã hội — viền nhạt, icon màu, nền trắng.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3436),
        side: const BorderSide(color: Color(0xFFDFE6E9), width: 1.5),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: iconColor, size: 22),
      label: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
