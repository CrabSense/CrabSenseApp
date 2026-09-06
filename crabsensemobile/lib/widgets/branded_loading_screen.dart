import 'package:flutter/material.dart';
import 'app_logo.dart';

/// Màn chờ branded — sáng, thân thiện, xanh lá.
/// Dùng khi: splash, đang đăng nhập, đang tải dữ liệu.
class BrandedLoadingScreen extends StatelessWidget {
  const BrandedLoadingScreen({
    super.key,
    this.message = 'Đang tải…',
    this.subtitle,
  });

  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo container — nền xanh lá nhạt, border xanh lá
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5F5E3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF27AE60).withValues(alpha: 0.18),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(child: AppLogo(size: 72)),
              ),
              const SizedBox(height: 24),

              // App name
              const Text(
                'CrabSense',
                style: TextStyle(
                  color: Color(0xFF1A2E3B),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Tagline
              const Text(
                'Giám sát nuôi cua thông minh',
                style: TextStyle(
                  color: Color(0xFF5A7184),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              // Progress indicator — xanh lá
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
                  backgroundColor: Color(0xFFD5F5E3),
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF1A2E3B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5A7184),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 48),

              // Footer
              const Text(
                'CrabSense — Ứng dụng quản lý trại cua thông minh',
                style: TextStyle(
                  color: Color(0xFF9DB3C2),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
