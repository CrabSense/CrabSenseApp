import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../widgets/app_logo.dart';
import '../../../../widgets/branded_loading_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/biometric_cubit.dart';
import '../bloc/biometric_state.dart';
import 'login_screen_spec.dart';
import 'crab_login_screen.dart';

/// Login screen using the supplied CrabSense farm artwork and brand assets.
class LegacyLoginScreen extends StatefulWidget {
  const LegacyLoginScreen({super.key});

  @override
  State<LegacyLoginScreen> createState() => _LoginScreenState();
}

class LoginScreen extends CrabLoginScreen {
  const LoginScreen({super.key});
}

class _LoginScreenState extends State<LegacyLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isFormValid = false;

  // Brand colors — đồng bộ với CrabSenseColors theme mới
  static const _primary = Color(0xFF6DC22E);
  static const _primaryDark = Color(0xFF0A3323);
  static const _textPrimary = Color(0xFF0F1F18);
  static const _textSecondary = Color(0xFF5A6B60);
  static const _textDisabled = Color(0xFF8A9A8E);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceVariant = Color(0xFFF3F8E8);
  static const _outline = Color(0xFFD5E0D0);
  static const _background = Color(0xFFF3F6EC);
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
    final valid =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _primaryDark,
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

              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/farm_hero.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: _primaryDark),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x660A3323),
                          Color(0x330A3323),
                          Color(0xE60A3323),
                        ],
                        stops: [0, 0.35, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 28),
                                _buildForm(),
                                const SizedBox(height: 18),
                                _buildDivider(),
                                const SizedBox(height: 14),
                                _buildSocialButtons(),
                                const SizedBox(height: 20),
                                _buildFooter(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Image.asset(
            'assets/images/357f2b21-9f88-460e-be46-a9e045539513.png',
            width: 92,
            height: 72,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'CrabSense',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quản lý nuôi cua thông minh',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFC8E86A),
          ),
        ),
      ],
    );
  }

  // ── Form card ────────────────────────────────────────────────────────

  Widget _buildForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Đăng nhập',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nhập tài khoản để vào trung tâm điều hành',
                style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 20),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                validator: _validateEmail,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                ),
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
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                ),
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
                      horizontal: 4,
                      vertical: 4,
                    ),
                    foregroundColor: _primary,
                  ),
                  child: Text(
                    'Quên mật khẩu?',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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
                    disabledBackgroundColor: const Color(0xFF4E9A22),
                    disabledForegroundColor: Color(
                      0xFF0A3323,
                    ).withValues(alpha: 0.55),
                    foregroundColor: _primaryDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Đăng nhập',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // Biometric button
              _buildBiometricButton(),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      hintStyle: GoogleFonts.nunito(
        fontSize: 14,
        color: const Color(0xFF5A6B60),
      ),
      prefixIcon: Icon(prefixIcon, color: _primaryDark, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.94),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
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
      errorStyle: GoogleFonts.inter(fontSize: 12, color: _error),
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
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
        const Expanded(child: Divider(color: Color(0x66FFFFFF), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Hoặc đăng nhập với',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0x66FFFFFF), thickness: 1)),
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
      style: GoogleFonts.nunito(
        fontSize: 13,
        color: Colors.white70,
        fontWeight: FontWeight.w600,
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
            borderRadius: BorderRadius.circular(12),
          ),
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _onBiometricStateChanged(BuildContext context, BiometricState state) {
    if (state is BiometricAuthenticated) {
      context.read<AuthBloc>().add(const BiometricAuthenticationRequested());
    } else if (state is BiometricAuthFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: const Color(0xFFE17055),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: iconColor, size: 22),
      label: Text(
        label,
        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
