import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

/// Nút đăng xuất + dialog xác nhận hologram.
class LogoutButton extends StatelessWidget {
  final VoidCallback onLogoutConfirmed;

  const LogoutButton({
    super.key,
    required this.onLogoutConfirmed,
  });

  void _showLogoutConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kHomeNavyLift,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.5)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Xác nhận đăng xuất',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất? Dữ liệu ngoại tuyến chưa đồng bộ vẫn được lưu trên máy.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.5)),
            ),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogoutConfirmed();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.only(top: 8, bottom: 32),
      child: FilledButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'ĐĂNG XUẤT',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xCCFF6B6B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
