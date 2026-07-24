import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_hub_scaffold.dart';
import 'legal_document_screen.dart';

/// Bảo mật & quyền riêng tư.
class SecurityPrivacyScreen extends ConsumerWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(profileStateProvider).valueOrNull;
    final sec = data?.security ?? SecuritySummary.sample;
    final fmt = DateFormat('dd/MM/yyyy');

    void toast(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    return ProfileHubScaffold(
      title: 'BẢO MẬT & QUYỀN RIÊNG TƯ',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          HubCard(
            child: Column(
              children: [
                HubTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Đổi mật khẩu',
                  subtitle:
                      'Đổi lần cuối: ${fmt.format(sec.passwordLastChanged)}',
                  onTap: () => context.push(RoutePaths.changePassword),
                ),
                HubTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Đăng nhập sinh trắc học',
                  subtitle: 'Vân tay / FaceID trên thiết bị này',
                  trailing: Switch(
                    value: sec.biometricEnabled,
                    activeColor: kHomeCyan,
                    onChanged: (v) {
                      ref
                          .read(profileStateProvider.notifier)
                          .toggleBiometric(v);
                      toast(v ? 'Đã bật sinh trắc học' : 'Đã tắt sinh trắc học');
                    },
                  ),
                ),
                HubTile(
                  icon: Icons.shield_outlined,
                  title: 'Xác thực 2 yếu tố (2FA)',
                  value: sec.twoFactorEnabled ? 'Đã bật' : 'Đang tắt',
                  subtitle: 'OTP ứng dụng xác thực — cấu hình phía máy chủ',
                  onTap: () => _infoSheet(
                    context,
                    title: 'Xác thực 2 yếu tố',
                    body: sec.twoFactorEnabled
                        ? 'Tài khoản đang bật 2FA. Mã OTP được yêu cầu khi đăng nhập từ thiết bị mới.'
                        : '2FA chưa bật. Liên hệ quản trị viên trang trại để kích hoạt OTP.',
                  ),
                ),
                HubTile(
                  icon: Icons.devices_rounded,
                  title: 'Thiết bị đang đăng nhập',
                  value: '${sec.activeDevicesCount} thiết bị',
                  onTap: () => _infoSheet(
                    context,
                    title: 'Thiết bị đăng nhập',
                    body:
                        'Hiện có khoảng ${sec.activeDevicesCount} phiên đang hoạt động. '
                        'Thu hồi phiên từ xa sẽ có trong bản cập nhật quản trị.',
                  ),
                ),
                HubTile(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Lịch sử đăng nhập',
                  value: '${sec.loginHistoryCount} lần gần đây',
                  onTap: () => _infoSheet(
                    context,
                    title: 'Lịch sử đăng nhập',
                    body:
                        'Đã ghi nhận ${sec.loginHistoryCount} lần đăng nhập gần đây trên hệ thống CrabSense.',
                  ),
                ),
                HubTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Cài đặt quyền riêng tư',
                  subtitle: 'Dữ liệu cảm biến, camera AI, nhật ký vận hành',
                  onTap: () => context.push(
                    RoutePaths.legalDocument,
                    extra: LegalDocumentArgs.privacy,
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _infoSheet(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: kHomeCyan,
                  foregroundColor: kHomeNavyDeep,
                ),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
