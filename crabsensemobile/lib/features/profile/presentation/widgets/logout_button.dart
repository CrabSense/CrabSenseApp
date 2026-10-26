import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// Đỏ đậm hơn `kHomeDanger` để chữ 14px trên nền card sáng đủ tương phản.
const Color _kLogoutInk = Color(0xFFB4342A);

/// Nút đăng xuất + dialog xác nhận — outlined cho đúng pattern destructive.
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kHomeSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kHomeBorder),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kHomeDangerBg,
                border: Border.all(
                  color: kHomeDanger.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: _kLogoutInk,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xác nhận đăng xuất',
                style: TextStyle(
                  color: kHomeTextMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn đăng xuất? Dữ liệu ngoại tuyến chưa đồng bộ vẫn được lưu trên máy.',
          style: TextStyle(
            color: kHomeTextSub,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          OutlinedButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: kHomeTextMain,
              side: const BorderSide(color: kHomeBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
              backgroundColor: kHomeDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kLogoutInk,
          backgroundColor: kHomeSurface,
          side: const BorderSide(color: kHomeBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
