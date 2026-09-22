import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class ReferenceLoginScreen extends StatefulWidget {
  const ReferenceLoginScreen({super.key});

  @override
  State<ReferenceLoginScreen> createState() => _ReferenceLoginScreenState();
}

class _ReferenceLoginScreenState extends State<ReferenceLoginScreen> {
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
          LoginRequested(
            email: email.text.trim(),
            password: password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1198ED);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFF),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 405,
              child: Image.asset(
                'assets/images/farm_hero.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Positioned.fill(
              top: 350,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 22),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(54)),
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/36d784c2-e209-485b-95f3-94254733a0a2.png',
                    ),
                    fit: BoxFit.fill,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/357f2b21-9f88-460e-be46-a9e045539513.png',
                        width: 235,
                        height: 132,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      _field(
                        controller: email,
                        hint: 'Email',
                        icon: Icons.mail_outline_rounded,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: password,
                        hint: 'Mật khẩu',
                        icon: Icons.lock_outline_rounded,
                        obscure: hidden,
                        suffix: IconButton(
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(
                            hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Quên mật khẩu?'),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
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
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Đăng ký tài khoản'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: blue,
                          minimumSize: const Size(220, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF31547A)),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
