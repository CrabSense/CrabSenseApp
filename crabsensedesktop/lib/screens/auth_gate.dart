import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cloud_auth_service.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';

/// Mở app: có session đã lưu thì vào thẳng trang chủ, không bắt login lại.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Widget? _child;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final session = await CloudAuthService().restorePersistedSession();
    if (!mounted) return;
    setState(() {
      _child = session == null
          ? const LoginScreen()
          : MainShellScreen(session: session);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _child ?? const _AuthSplash();
  }
}

class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', height: 72),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFF2B6F9A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Đang khôi phục phiên đăng nhập...',
                  style: GoogleFonts.notoSans(
                    color: const Color(0xFF16333F),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
