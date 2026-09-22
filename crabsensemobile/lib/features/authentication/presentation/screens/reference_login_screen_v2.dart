import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class ReferenceLoginScreenV2 extends StatefulWidget {
  const ReferenceLoginScreenV2({super.key});

  @override
  State<ReferenceLoginScreenV2> createState() => _ReferenceLoginScreenV2State();
}

class _ReferenceLoginScreenV2State extends State<ReferenceLoginScreenV2> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _login() {
    if (email.text.trim().isEmpty || password.text.isEmpty) return;
    context.read<AuthBloc>().add(
          LoginRequested(email: email.text.trim(), password: password.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFF),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              SizedBox(
                height: 410,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/farm_hero.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                    Positioned(
                      top: 14,
                      left: 18,
                      right: 18,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('9:41',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text('🇻🇳  VI ⌄',
                                style: TextStyle(
                                    color: Color(0xFF173A6A),
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -45),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 42, 28, 26),
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(54)),
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/images/36d784c2-e209-485b-95f3-94254733a0a2.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  foregroundDecoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/login_footer.png'),
                      alignment: Alignment.bottomCenter,
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/357f2b21-9f88-460e-be46-a9e045539513.png',
                        width: 235,
                        height: 116,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      _field(email, 'Email', Icons.mail_outline_rounded),
                      const SizedBox(height: 12),
                      _field(password, 'Mật khẩu', Icons.lock_outline_rounded,
                          obscure: hidden,
                          suffix: IconButton(
                            onPressed: () => setState(() => hidden = !hidden),
                            icon: Icon(hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                          )),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Quên mật khẩu?'),
                        ),
                      ),
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1198ED),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Text('Đăng nhập  →',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(children: [
                          Expanded(child: Divider()),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('hoặc')),
                          Expanded(child: Divider()),
                        ]),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Đăng ký tài khoản'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1198ED),
                          minimumSize: const Size(220, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon,
      {bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF31547A)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD5E0EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD5E0EA)),
        ),
      ),
    );
  }
}
