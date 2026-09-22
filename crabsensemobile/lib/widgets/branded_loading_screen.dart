import 'package:flutter/material.dart';

/// Splash dùng chung trước khi kiểm tra phiên đăng nhập.
class BrandedLoadingScreen extends StatelessWidget {
  const BrandedLoadingScreen({
    super.key,
    this.message = 'Đang tải…',
    this.subtitle,
    this.showBackground = true,
  });

  final String message;
  final String? subtitle;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (showBackground)
            Image.asset('assets/images/login_splash.png', fit: BoxFit.fill)
          else
            const ColoredBox(color: Colors.white),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF2AA764),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF173A6A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(color: Color(0xFF5A7184)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
