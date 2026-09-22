import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Login layout matching the supplied 390x844 mockup.
class SpecLoginScreen extends StatefulWidget {
  const SpecLoginScreen({super.key});

  @override
  State<SpecLoginScreen> createState() => _SpecLoginScreenState();
}

class _SpecLoginScreenState extends State<SpecLoginScreen>
    with WidgetsBindingObserver {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordKey = GlobalKey();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _hidePassword = true;
  bool _loading = false;
  bool _showSplash = true;
  bool _keyboardWasOpen = false;
  late final DraggableScrollableController _sheetController;
  ScrollController? _formScrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sheetController = DraggableScrollableController();
    _emailFocus.addListener(_onFocusChanged);
    _passwordFocus.addListener(_onFocusChanged);
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailFocus.removeListener(_onFocusChanged);
    _passwordFocus.removeListener(_onFocusChanged);
    _sheetController.dispose();
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final keyboardOpen =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .viewInsets
            .bottom >
        0;
    if (keyboardOpen) {
      _keyboardWasOpen = true;
    } else if (_keyboardWasOpen) {
      _keyboardWasOpen = false;
      FocusManager.instance.primaryFocus?.unfocus();
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          _initialSheet(MediaQuery.sizeOf(context).height),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
      _formScrollController?.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _onFocusChanged() {
    if (!_sheetController.isAttached) return;
    final focused = _emailFocus.hasFocus || _passwordFocus.hasFocus;
    if (focused) {
      _sheetController.animateTo(
        .80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (!mounted ||
            _formScrollController == null ||
            !_formScrollController!.hasClients) {
          return;
        }
        final passwordContext = _passwordKey.currentContext;
        if (passwordContext != null) {
          Scrollable.ensureVisible(
            passwordContext,
            alignment: .12,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _submit() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.length < 3) {
      _message('Vui lòng nhập tài khoản hoặc email');
      return;
    }
    if (password.isEmpty) {
      _message('Vui lòng nhập mật khẩu');
      return;
    }
    setState(() => _loading = true);
    context.read<AuthBloc>().add(
      LoginRequested(email: email, password: password),
    );
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const _LoginSplash();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final width = constraints.maxWidth;
          return Stack(
            fit: StackFit.expand,
            children: [
              _background(width, height),
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: _initialSheet(height),
                minChildSize: _initialSheet(height),
                maxChildSize: .80,
                snap: true,
                snapAnimationDuration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                builder: (context, controller) => _panel(controller, width),
              ),
            ],
          );
        },
      ),
    );
  }

  double _initialSheet(double height) => height < 700 ? .72 : .68;

  Widget _background(double width, double height) => Positioned.fill(
    child: Image.asset(
      'assets/images/farm_hero.jpg',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    ),
  );

  Widget _leaves(double width, double height) => IgnorePointer(
    child: Stack(
      children: [
        Positioned(
          left: -22,
          bottom: 8,
          width: width * .30,
          child: Image.asset('assets/images/login_leaf.png'),
        ),
        Positioned(
          right: -22,
          bottom: 8,
          width: width * .30,
          child: Transform.flip(
            flipX: true,
            child: Image.asset('assets/images/login_leaf.png'),
          ),
        ),
      ],
    ),
  );

  Widget _panel(ScrollController controller, double width) {
    _formScrollController = controller;
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(56)),
        image: DecorationImage(
          image: AssetImage(
            'assets/images/36d784c2-e209-485b-95f3-94254733a0a2.png',
          ),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                width < 380 ? 22 : 28,
                20,
                width < 380 ? 22 : 28,
                128,
              ),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB7C8D2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Image.asset(
                    'assets/images/357f2b21-9f88-460e-be46-a9e045539513.png',
                    width: width * .60,
                    height: 112,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                _field(
                  controller: _email,
                  focusNode: _emailFocus,
                  hint: 'Tài khoản hoặc Email',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: _passwordKey,
                  child: _field(
                    controller: _password,
                    focusNode: _passwordFocus,
                    hint: 'Mật khẩu',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _hidePassword,
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _message('Tính năng khôi phục mật khẩu'),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1298EA),
                      minimumSize: Size.zero,
                      fixedSize: const Size.fromHeight(48),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Đăng nhập  →',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('hoặc'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<AuthBloc>().add(
                      const GoogleLoginRequested(),
                    ),
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    label: const Text('Đăng nhập bằng Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1298EA),
                      minimumSize: Size.zero,
                      fixedSize: const Size.fromHeight(48),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) => TextField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: keyboardType,
    obscureText: obscureText,
    textInputAction: hint != 'Mật khẩu'
        ? TextInputAction.next
        : TextInputAction.done,
    onSubmitted: hint == 'Mật khẩu' ? (_) => _submit() : null,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF31547A)),
      suffixIcon: suffix,
      constraints: const BoxConstraints(minHeight: 64, maxHeight: 64),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .94),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5E0EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5E0EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1298EA), width: 2),
      ),
    ),
  );
}

class _LoginSplash extends StatefulWidget {
  const _LoginSplash();

  @override
  State<_LoginSplash> createState() => _LoginSplashState();
}

class _LoginSplashState extends State<_LoginSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/login_splash.png', fit: BoxFit.fill),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: Tween<double>(begin: .35, end: 1).animate(_controller),
            child: const Column(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF1298EA),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Đang tải CrabSense...',
                  style: TextStyle(
                    color: Color(0xFF173A6A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
