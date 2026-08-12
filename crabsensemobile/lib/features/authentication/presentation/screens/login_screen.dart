import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../widgets/app_logo.dart';
import '../../../../widgets/branded_loading_screen.dart';
import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/biometric_cubit.dart';
import '../bloc/biometric_state.dart';

/// Màn đăng nhập — palette hologram đồng bộ Home / Quét QR.
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

  InputDecoration _fieldDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
      prefixIcon: Icon(prefixIcon, color: kHomeCyan),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: kHomeNavyDeep.withValues(alpha: 0.72),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.45)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kHomeCyan, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.8)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeNavyDeep,
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
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A274F),
                        kHomeNavyDeep,
                        Color(0xFF06122A),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CrabHologramPainter(
                        color: kHomeBlueLight.withValues(alpha: 0.06),
                        trayExtent: 36,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 28),
                              _buildFormCard(),
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
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                kHomeCyan.withValues(alpha: 0.22),
                kHomeBlue.withValues(alpha: 0.06),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: kHomeCyan.withValues(alpha: 0.28),
                blurRadius: 32,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const AppLogo(size: 88),
        ),
        const SizedBox(height: 18),
        Text(
          'CRABSENSE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: kHomeBlueLight,
            letterSpacing: 1.4,
            shadows: [
              Shadow(
                color: kHomeCyan.withValues(alpha: 0.45),
                blurRadius: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Giám sát nuôi cua thông minh',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.65),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: homeCardDecoration(radius: 22, glowAlpha: 0.22),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const HomeCrabWatermark(alpha: 0.05, trayExtent: 22),
          const HomeTopEdgeGlow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ĐĂNG NHẬP',
                  style: TextStyle(
                    color: kHomeBlueLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    fontSize: 13,
                    shadows: [
                      Shadow(
                        color: kHomeCyan.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhập tài khoản để vào trung tâm điều hành',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: _validateEmail,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    label: 'Tài khoản / Email',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  style: const TextStyle(color: Colors.white),
                  onFieldSubmitted: (_) {
                    if (_isFormValid) _handleLogin();
                  },
                  decoration: _fieldDecoration(
                    label: 'Mật khẩu',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _PrimaryButton(
                  enabled: _isFormValid,
                  label: 'Đăng nhập',
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 12),
                _OutlineButton(
                  label: 'Đăng nhập bằng Google',
                  icon: Icons.g_mobiledata_rounded,
                  iconColor: const Color(0xFFEA4335),
                  onPressed: _handleGoogleLogin,
                ),
                const SizedBox(height: 10),
                _buildBiometricButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton() {
    return BlocBuilder<BiometricCubit, BiometricState>(
      builder: (context, biometricState) {
        if (biometricState is! BiometricAvailable ||
            !biometricState.isEnabled) {
          return const SizedBox.shrink();
        }

        final isBiometricLoading = biometricState is BiometricLoading;

        return _OutlineButton(
          label: 'Đăng nhập sinh trắc học',
          icon: Icons.fingerprint_rounded,
          loading: isBiometricLoading,
          onPressed: isBiometricLoading ? null : _handleBiometricLogin,
        );
      },
    );
  }

  Widget _buildFooter() {
    return Text(
      'Quên mật khẩu? Liên hệ quản trị viên',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } else if (state is Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chào mừng trở lại, ${state.user.name}!'),
          backgroundColor: kHomeBlue,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? const [Color(0xFF5BA0FF), kHomeBlue, Color(0xFF1A5FD0)]
                : [
                    kHomeBlue.withValues(alpha: 0.28),
                    kHomeBlue.withValues(alpha: 0.18),
                  ],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: kHomeBlue.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.45),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: kHomeBlueLight,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.35),
          side: BorderSide(
            color: enabled
                ? kHomeBorderBlue.withValues(alpha: 0.7)
                : kHomeBorderBlue.withValues(alpha: 0.3),
            width: 1.4,
          ),
          backgroundColor: kHomeNavyDeep.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kHomeCyan),
                ),
              )
            : Icon(icon, size: 22, color: iconColor ?? kHomeCyan),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
