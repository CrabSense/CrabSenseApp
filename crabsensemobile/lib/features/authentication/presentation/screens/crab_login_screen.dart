import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class CrabLoginScreen extends StatefulWidget {
  const CrabLoginScreen({super.key});

  @override
  State<CrabLoginScreen> createState() => _CrabLoginScreenState();
}

class _CrabLoginScreenState extends State<CrabLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _account = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _remember = true;
  String? _errorMessage;

  static const navy = Color(0xFF173A5E);
  static const teal = Color(0xFF1498A9);
  static const green = Color(0xFF2BA866);

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
      LoginRequested(email: _account.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthBloc, AuthState>(
    listener: (context, state) {
      if (state is AuthError) {
        setState(() => _errorMessage = state.message);
        Future<void>.delayed(const Duration(seconds: 5), () {
          if (mounted && _errorMessage == state.message) {
            setState(() => _errorMessage = null);
          }
        });
      }
    },
    builder: (context, authState) {
      final loading = authState is AuthLoading;
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
            final compact = constraints.maxHeight < 900 || keyboardOpen;
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/crabsense_splash_background.png',
                  fit: BoxFit.cover,
                ),
                Container(color: Colors.white.withValues(alpha: .08)),
                SafeArea(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      18,
                      compact ? 8 : 18,
                      18,
                      compact ? 28 : 38,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - (compact ? 22 : 40))
                            .clamp(0.0, double.infinity),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _brand(compact: compact),
                          SizedBox(height: compact ? 10 : 20),
                          Transform.translate(
                            offset: const Offset(0, -15),
                            child: _formCard(
                              compact: compact,
                              loading: loading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  Widget _brand({required bool compact}) => Column(
    children: [
      Image.asset(
        'assets/images/crabsense_splash_logo.png',
        width: compact ? 100 : 150,
        height: compact ? 100 : 150,
        fit: BoxFit.contain,
      ),
      SizedBox(height: compact ? 2 : 5),
      Image.asset(
        'assets/images/crabsense_splash_slogan.png',
        width: compact ? 190 : 278,
        fit: BoxFit.contain,
      ),
    ],
  );

  Widget _formCard({required bool compact, required bool loading}) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(17, compact ? 10 : 14, 17, 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .91),
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: Colors.white.withValues(alpha: .8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x220B4261),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Đăng nhập',
            style: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Theo dõi hộp nuôi cua ngay tại trại',
            style: TextStyle(color: Color(0xFF687987), fontSize: 10),
          ),
          SizedBox(height: compact ? 9 : 15),
          _field(
            controller: _account,
            hint: 'Tên đăng nhập',
            icon: Icons.person_outline_rounded,
            validator: (value) => value == null || value.trim().length < 3
                ? 'Nhập tên đăng nhập'
                : null,
          ),
          SizedBox(height: compact ? 7 : 10),
          _field(
            controller: _password,
            hint: 'Mật khẩu',
            icon: Icons.lock_outline_rounded,
            obscure: _hidePassword,
            suffix: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF71838C),
              ),
            ),
            validator: (value) =>
                value == null || value.length < 3 ? 'Nhập mật khẩu' : null,
          ),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _remember,
                      activeColor: const Color(0xFF117C5A),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (value) =>
                          setState(() => _remember = value ?? true),
                    ),
                    const Flexible(
                      child: Text(
                        'Ghi nhớ đăng nhập',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF607581),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerRight,
                  ),
                  child: const Text(
                    'Quên mật khẩu?',
                    maxLines: 2,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF2675A0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _errorMessage == null
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(_errorMessage),
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFC5C0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFD64545),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFB33131),
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _errorMessage = null),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFB33131),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF159BAA), Color(0xFF2AA764)],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: loading ? null : _login,
                  borderRadius: BorderRadius.circular(13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: loading
                        ? const [
                            SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Đang đăng nhập...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ]
                        : const [
                            Text(
                              'Đăng nhập',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFD5E0E0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'hoặc',
                  style: TextStyle(color: navy.withValues(alpha: .55)),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFD5E0E0))),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: OutlinedButton(
              onPressed: loading
                  ? null
                  : () => context.read<AuthBloc>().add(
                      const GoogleLoginRequested(),
                    ),
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Color(0xFFD0DADB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Đăng nhập với Google',
                    style: TextStyle(
                      color: navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFF607581), fontSize: 11),
              children: [
                TextSpan(text: 'Chưa có tài khoản? '),
                TextSpan(
                  text: 'Đăng ký ngay  →',
                  style: TextStyle(color: green, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    Widget? suffix,
    bool obscure = false,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    style: const TextStyle(fontSize: 14, color: Color(0xFF35505A)),
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF14835F)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FCFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: teal, width: 1.5),
      ),
    ),
  );
}
