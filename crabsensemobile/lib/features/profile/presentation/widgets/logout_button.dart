import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// Nút đăng xuất hologram + dialog xác nhận.
class LogoutButton extends StatelessWidget {
  const LogoutButton({
    super.key,
    this.onLogoutConfirmed,
  });

  /// Optional hook after AuthBloc logout is dispatched.
  final VoidCallback? onLogoutConfirmed;

  void _showLogoutConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kHomeNavyLift,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.55)),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.14),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFFF6B6B),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xác nhận đăng xuất',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất? Dữ liệu ngoại tuyến chưa đồng bộ vẫn được lưu trên máy.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: kHomeBlueLight,
              side: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.55)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final authBloc = context.read<AuthBloc>();
              // Đóng dialog trước, logout sau 1 frame — tránh Duplicate GlobalKey
              // khi GoRouter redirect lúc overlay còn trên tree.
              Navigator.of(dialogContext, rootNavigator: true).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                authBloc.add(const LogoutRequested());
                onLogoutConfirmed?.call();
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE85D5D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.w800),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3A1520),
            kHomeNavyDeep,
            const Color(0xFF2A1018),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutConfirmation(context),
          borderRadius: BorderRadius.circular(16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFFF8A8A), size: 20),
              SizedBox(width: 10),
              Text(
                'ĐĂNG XUẤT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
