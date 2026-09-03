import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_env.dart';
import '../services/cloud_auth_service.dart';
import '../services/theme_mode_service.dart';
import '../theme/dashboard_theme.dart';
import '../widgets/dashboard/wave_background.dart';
import '../widgets/shared/theme_mode_toggle.dart';
import 'farm_select_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = CloudAuthService();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signIn(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FarmSelectScreen(
            token: result.token!,
            user: result.user!,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.errorMessage!),
        backgroundColor: DashboardColors.risk,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appThemeMode,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: DashboardColors.darkNavy,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const WaveBackground(),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CrabFarm Monitor',
                                  style: GoogleFonts.notoSans(
                                    color: DashboardColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'PRECISION AQUACULTURE',
                                  style: GoogleFonts.notoSans(
                                    color: DashboardColors.textMuted,
                                    fontSize: 9,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const ThemeModeToggle(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: _LoginCard(
                              formKey: _formKey,
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              rememberMe: _rememberMe,
                              obscurePassword: _obscurePassword,
                              isLoading: _isLoading,
                              onRememberMeChanged: (v) =>
                                  setState(() => _rememberMe = v ?? false),
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onLogin: _handleLogin,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const _LoginFooter(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.isLoading,
    required this.onRememberMeChanged,
    required this.onTogglePassword,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final bool isLoading;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardColors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DashboardColors.purple.withValues(alpha: 0.35),
        ),
        boxShadow: [
          DashboardColors.glowShadow,
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Đăng nhập chủ trại',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Theo dõi trại nuôi cua — CrabSenseBE',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: DashboardColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DashboardColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DashboardColors.cardBorder.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  'API: ${AppEnv.cloudApiUrl}\nChủ trại: owner / Owner@123',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    color: DashboardColors.cyan.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _FieldLabel('Tên đăng nhập'),
              const SizedBox(height: 6),
              _AuthTextField(
                controller: usernameController,
                hint: 'username hoặc email',
                icon: Icons.person_outline,
                keyboardType: TextInputType.text,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _FieldLabel('Mật khẩu'),
              const SizedBox(height: 6),
              _AuthTextField(
                controller: passwordController,
                hint: 'Nhập mật khẩu',
                icon: Icons.lock_outline,
                obscureText: obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: DashboardColors.textMuted,
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    height: 28,
                    width: 28,
                    child: Checkbox(
                      value: rememberMe,
                      onChanged: onRememberMeChanged,
                      activeColor: DashboardColors.purple,
                      side: BorderSide(color: DashboardColors.cardBorder),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Text(
                    'Ghi nhớ đăng nhập',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: DashboardColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: DashboardColors.cyan,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Quên mật khẩu?',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _LoginButton(isLoading: isLoading, onPressed: onLogin),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Chưa có tài khoản? ',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: DashboardColors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Đăng ký',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DashboardColors.textPrimary,
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.notoSans(
        fontSize: 14,
        color: DashboardColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSans(
          color: DashboardColors.textMuted.withValues(alpha: 0.75),
        ),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Icon(icon, color: DashboardColors.textMuted, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardColors.purple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.risk.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: DashboardColors.accentGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: DashboardColors.purple.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Đăng nhập',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    final linkStyle = GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 11,
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;
          final links = [
            Text('Chính sách', style: linkStyle),
            Text('Điều khoản', style: linkStyle),
            Text('Trợ giúp', style: linkStyle),
            Text('Liên hệ', style: linkStyle),
          ];

          if (narrow) {
            return Column(
              children: [
                Text(
                  '© 2024 CrabFarm Monitor · Precision Aquaculture',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: links,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Text(
                  '© 2024 CrabFarm Monitor · Precision Aquaculture',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              Wrap(spacing: 16, children: links),
            ],
          );
        },
      ),
    );
  }
}
