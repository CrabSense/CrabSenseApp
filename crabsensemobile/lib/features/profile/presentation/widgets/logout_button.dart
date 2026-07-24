import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Styled Logout Button with Confirmation Dialog
class LogoutButton extends StatelessWidget {
  final VoidCallback onLogoutConfirmed;

  const LogoutButton({
    super.key,
    required this.onLogoutConfirmed,
  });

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CrabSenseColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CrabSenseColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: CrabSenseColors.danger),
            SizedBox(width: 10),
            Text(
              'Xác nhận đăng xuất',
              style: TextStyle(
                color: CrabSenseColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng CrabSense? Dữ liệu chưa đồng bộ ngoại tuyến sẽ được lưu trữ an toàn trên thiết bị.',
          style: TextStyle(
            color: CrabSenseColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: CrabSenseColors.textSecondary,
              side: const BorderSide(color: CrabSenseColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogoutConfirmed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CrabSenseColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
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
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
        label: const Text(
          'ĐĂNG XUẤT TÀI KHOẢN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: CrabSenseColors.danger.withValues(alpha: 0.85),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: CrabSenseColors.danger.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: CrabSenseColors.danger.withValues(alpha: 0.6), width: 1.5),
          ),
        ),
      ),
    );
  }
}
