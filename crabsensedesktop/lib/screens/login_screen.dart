import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cloud_auth_service.dart';
import '../theme/dashboard_theme.dart';
import 'farm_select_screen.dart';

/// Palette theo UI_Login.png — xanh lá / teal / navy.
abstract final class _LoginInk {
  static const brand = Color(0xFF0D5C3D);
  static const title = Color(0xFF163A5C);
  static const body = Color(0xFF5A6B75);
  static const muted = Color(0xFF8A9BA3);
  static const teal = Color(0xFF1A8A85);
  static const leaf = Color(0xFF2E9B5F);
  static const fieldFill = Color(0xFFF3F6F5);
  static const fieldBorder = Color(0xFFD0DDD6);
  static const card = Color(0xFFFFFFF8);
  static const onImage = Color(0xFF0F2A1C);

  static List<Shadow> get softGlow => [
        Shadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 10),
        Shadow(color: Colors.white.withValues(alpha: 0.55), blurRadius: 18),
      ];
}

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

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillRememberedUsername();
  }

  Future<void> _prefillRememberedUsername() async {
    final username = await _authService.loadRememberedUsername();
    if (!mounted || username == null) return;
    _usernameController.text = username;
    setState(() => _rememberMe = true);
  }

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
      if (!_rememberMe) {
        await _authService.clearSession(keepUsername: false);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FarmSelectScreen(
            token: result.token!,
            refreshToken: result.refreshToken,
            user: result.user!,
            persistSession: _rememberMe,
            username: _usernameController.text.trim(),
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
    return Scaffold(
      backgroundColor: const Color(0xFFE8F2EC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login/Nen_Login.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.1, 0),
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0x55FFFFFF),
                  Color(0x22FFFFFF),
                  Color(0x33E8F5EE),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Họa tiết góc phải — bỏ nền đen, giữ màu xanh/trắng.
          const Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.55,
              heightFactor: 1,
              child: IgnorePointer(
                child: _KnockoutBlackImage(
                  asset: 'assets/images/login/background_right.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Slogan VN góc trên phải (như UI_Login).
          const Positioned(
            top: 28,
            right: 36,
            child: IgnorePointer(
              child: _KnockoutBlackImage(
                asset: 'assets/images/login/slogan_right_tv.png',
                height: 88,
              ),
            ),
          ),
          // Slogan EN góc dưới phải (như UI_Login).
          const Positioned(
            bottom: 52,
            right: 28,
            child: IgnorePointer(
              child: _KnockoutBlackImage(
                asset: 'assets/images/login/slogan_right-en.png',
                height: 96,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 960;
                return Column(
                  children: [
                    Expanded(
                      child: wide
                          ? _WideLayout(
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
                            )
                          : _CompactLayout(
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
                    const _LoginFooter(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 40, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 12, child: _BrandColumn()),
          const SizedBox(width: 12),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _LoginCard(
                    formKey: formKey,
                    usernameController: usernameController,
                    passwordController: passwordController,
                    rememberMe: rememberMe,
                    obscurePassword: obscurePassword,
                    isLoading: isLoading,
                    onRememberMeChanged: onRememberMeChanged,
                    onTogglePassword: onTogglePassword,
                    onLogin: onLogin,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          const _BrandColumn(compact: true),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _LoginCard(
              formKey: formKey,
              usernameController: usernameController,
              passwordController: passwordController,
              rememberMe: rememberMe,
              obscurePassword: obscurePassword,
              isLoading: isLoading,
              onRememberMeChanged: onRememberMeChanged,
              onTogglePassword: onTogglePassword,
              onLogin: onLogin,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cột branding trái theo UI_Login.png — lưới 3×3 (cột 1 trống).
class _BrandColumn extends StatelessWidget {
  const _BrandColumn({this.compact = false});

  final bool compact;

  /// Cột 1 hẹp (để trống nhìn thấy cua nền), cột 2–3 chứa nội dung.
  static const _col1 = 2;
  static const _col23 = 7;

  Widget _row1({required bool expand}) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(flex: _col1, child: SizedBox.shrink()),
        Expanded(
          flex: _col23,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/logo.png',
              height: compact ? 132 : 180,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ],
    );
    if (!expand) return content;
    return Expanded(flex: 4, child: content);
  }

  Widget _row2({required bool expand}) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(flex: _col1, child: SizedBox.shrink()),
        Expanded(
          flex: _col23,
          child: Align(
            alignment: Alignment.topCenter,
            child: _BrandCopy(compact: compact),
          ),
        ),
      ],
    );
    if (!expand) return content;
    return Expanded(flex: 5, child: content);
  }

  Widget _row3({required bool expand}) {
    final slogan = Transform.rotate(
      angle: -0.06,
      child: Image.asset(
        'assets/images/login/Sologan_Login.png',
        height: compact ? 100 : 150,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(flex: _col1, child: SizedBox.shrink()),
        const Expanded(flex: 4, child: SizedBox.shrink()),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 12),
            child: Align(
              alignment: Alignment.bottomRight,
              child: slogan,
            ),
          ),
        ),
      ],
    );
    if (!expand) return content;
    return Expanded(flex: 3, child: content);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row1(expand: false),
          const SizedBox(height: 12),
          _row2(expand: false),
          const SizedBox(height: 16),
          _row3(expand: false),
        ],
      );
    }

    return Column(
      children: [
        _row1(expand: true),
        const SizedBox(height: 8),
        _row2(expand: true),
        _row3(expand: true),
      ],
    );
  }
}

class _BrandCopy extends StatelessWidget {
  const _BrandCopy({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF1B8A4A),
              Color(0xFF1A8A85),
              Color(0xFF1A6FB5),
            ],
          ).createShader(bounds),
          child: Text(
            'CrabSense',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: compact ? 40 : 52,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.6,
              shadows: _LoginInk.softGlow,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'TRẠI NUÔI CUA LỘT THÔNG MINH',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            color: _LoginInk.title,
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            shadows: _LoginInk.softGlow,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Công nghệ đồng hành — Cua khỏe mỗi ngày',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            color: _LoginInk.body,
            fontSize: compact ? 13 : 14.5,
            fontWeight: FontWeight.w500,
            shadows: _LoginInk.softGlow,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 22),
          width: 180,
          height: 2.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _LoginInk.leaf,
                _LoginInk.leaf.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const _FeatureRow(),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  static const _items = [
    (Icons.bar_chart_rounded, 'Giám sát\nthông minh'),
    (Icons.settings_rounded, 'Quản lý\ndễ dàng'),
    (Icons.water_drop_rounded, 'Môi trường\nổn định'),
    (Icons.pets_rounded, 'Năng suất\nbền vững'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 18),
          SizedBox(
            width: 100,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3FA86A), Color(0xFF1B6B3A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _LoginInk.leaf.withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(_items[i].$1, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  _items[i].$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    color: _LoginInk.onImage,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    shadows: _LoginInk.softGlow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Brush / leaf accents sau card (như mockup).
        Positioned(
          top: -14,
          right: -8,
          child: Transform.rotate(
            angle: 0.4,
            child: Container(
              width: 86,
              height: 28,
              decoration: BoxDecoration(
                color: _LoginInk.leaf.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -12,
          left: -10,
          child: Transform.rotate(
            angle: -0.3,
            child: Container(
              width: 100,
              height: 30,
              decoration: BoxDecoration(
                color: _LoginInk.teal.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _LoginInk.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: _LoginInk.brand.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 26, 32, 26),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Đăng nhập chủ trại',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _LoginInk.title,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Theo dõi hộp nuôi cua ngay tại trại',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: _LoginInk.body,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _FieldLabel('Tên đăng nhập'),
                  const SizedBox(height: 7),
                  _AuthTextField(
                    controller: usernameController,
                    hint: 'Tên tài khoản chủ trại',
                    icon: Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Mật khẩu'),
                  const SizedBox(height: 7),
                  _AuthTextField(
                    controller: passwordController,
                    hint: 'Nhập mật khẩu',
                    icon: Icons.lock_outline_rounded,
                    obscureText: obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _LoginInk.muted,
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
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: rememberMe,
                          onChanged: onRememberMeChanged,
                          activeColor: _LoginInk.brand,
                          side: const BorderSide(color: Color(0xFFB5C9BF)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ghi nhớ đăng nhập',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.5,
                          color: _LoginInk.body,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2B6F9A),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Quên mật khẩu?',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _LoginButton(isLoading: isLoading, onPressed: onLogin),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFD5DED8))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'hoặc',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: _LoginInk.muted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFD5DED8))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _RegisterButton(onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: _LoginInk.title,
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
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.beVietnamPro(
        fontSize: 14.5,
        color: _LoginInk.title,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.beVietnamPro(color: _LoginInk.muted),
        filled: true,
        fillColor: _LoginInk.fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        prefixIcon: Icon(icon, color: _LoginInk.teal, size: 21),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _LoginInk.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _LoginInk.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _LoginInk.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: DashboardColors.risk.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF147A8F),
              Color(0xFF1A8A7A),
              Color(0xFF2E9B5F),
            ],
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: _LoginInk.teal.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(13),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đăng nhập',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _LoginInk.title,
          side: const BorderSide(color: Color(0xFFC5D2CA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chưa có tài khoản? Đăng ký',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    final linkStyle = GoogleFonts.beVietnamPro(
      color: _LoginInk.onImage,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: _LoginInk.brand,
      shadows: _LoginInk.softGlow,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 4, 36, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final links = [
            Text('Chính sách', style: linkStyle),
            Text('Điều khoản', style: linkStyle),
            Text('Trợ giúp', style: linkStyle),
            Text('Liên hệ', style: linkStyle),
          ];

          final copyright = Text(
            '© 2026 CrabSense • Trại nuôi cua lột',
            style: GoogleFonts.beVietnamPro(
              color: _LoginInk.onImage,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              shadows: _LoginInk.softGlow,
            ),
            textAlign: narrow ? TextAlign.center : TextAlign.left,
          );

          if (narrow) {
            return Column(
              children: [
                copyright,
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  children: links,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: copyright),
              Wrap(spacing: 16, children: links),
            ],
          );
        },
      ),
    );
  }
}

/// PNG nền đen: chuyển đen → trong suốt, giữ họa tiết sáng.
class _KnockoutBlackImage extends StatelessWidget {
  const _KnockoutBlackImage({
    required this.asset,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final String asset;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  static const _knockout = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0.33, 0.5, 0.17, 0, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _knockout,
      child: Image.asset(
        asset,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
