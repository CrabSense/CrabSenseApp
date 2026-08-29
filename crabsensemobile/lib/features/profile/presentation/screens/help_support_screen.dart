import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../widgets/profile_hub_scaffold.dart';
import 'legal_document_screen.dart';

/// Trợ giúp & hỗ trợ — FAQ, liên hệ, feedback, bug.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _hotline = '1900 8888';
  static const _email = 'support@crabsense.vn';

  static const _faqs = <(String, String)>[
    (
      'Làm sao quét QR box?',
      'Vào tab Quét QR, đưa camera vào mã trên nắp box. Hệ thống mở chi tiết box nếu mã hợp lệ.'
    ),
    (
      'Dữ liệu ngoại tuyến khi mất mạng?',
      'Thao tác được xếp hàng chờ. Khi có mạng, vào Tài khoản → Ngoại tuyến & đồng bộ → Đồng bộ ngay.'
    ),
    (
      'Cảnh báo nước bất thường?',
      'Tab Cảnh báo hiển thị ngưỡng vượt. Có thể xác nhận / xử lý ngay trên từng cảnh báo.'
    ),
    (
      'AI phát hiện sai?',
      'Vào Trung tâm AI → Phát hiện → chọn Đúng/Sai để gửi phản hồi huấn luyện.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ProfileHubScaffold(
      title: 'TRỢ GIÚP & HỖ TRỢ',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          HubCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Câu hỏi thường gặp',
                  style: TextStyle(
                    color: kHomePrimaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _faqs.length; i++)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    iconColor: kHomeCyan,
                    collapsedIconColor: Colors.white54,
                    title: Text(
                      _faqs[i].$1,
                      style: const TextStyle(
                        color: kHomeTextMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _faqs[i].$2,
                          style: TextStyle(
                            color: const Color(0xFF5A7184),
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          HubCard(
            child: Column(
              children: [
                HubTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Hướng dẫn sử dụng',
                  subtitle: 'Tóm tắt thao tác chính trên CrabSense',
                  onTap: () => _guideSheet(context),
                ),
                HubTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Liên hệ hỗ trợ kỹ thuật',
                  value: 'Hotline: $_hotline',
                  subtitle: _email,
                  onTap: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: _hotline),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép số hotline'),
                        ),
                      );
                    }
                  },
                ),
                HubTile(
                  icon: Icons.rate_review_outlined,
                  title: 'Gửi ý kiến đóng góp',
                  onTap: () => _feedbackForm(context, isBug: false),
                ),
                HubTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Báo lỗi ứng dụng',
                  onTap: () => _feedbackForm(context, isBug: true),
                ),
                HubTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Về dự án CrabSense',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'CrabSense Mobile',
                    applicationVersion: '1.0.0+1',
                    applicationLegalese:
                        '© 2026 CrabSense Smart Aquaculture Platform',
                    children: const [
                      SizedBox(height: 12),
                      Text(
                        'Hệ thống quản lý trang trại cua thông minh tích hợp IoT, camera AI và đồng bộ dữ liệu ngoại tuyến.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
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

  void _guideSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kHomeSurface,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: const [
            Text(
              'Hướng dẫn nhanh',
              style: TextStyle(
                color: kHomeTextMain,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '1. Trang chủ — sức khỏe trang trại, cảnh báo, lối tắt.\n'
              '2. Boxes — bản đồ số / danh sách box nuôi.\n'
              '3. Quét QR — mở nhanh chi tiết box.\n'
              '4. Cảnh báo — xử lý sự cố môi trường / thiết bị.\n'
              '5. Tài khoản — thiết bị, AI, báo cáo, đồng bộ, cài đặt.',
              style: TextStyle(color: Colors.white70, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _feedbackForm(BuildContext context, {required bool isBug}) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kHomeSurface,
        title: Text(
          isBug ? 'Báo lỗi' : 'Góp ý',
          style: const TextStyle(color: kHomeTextMain),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: kHomeTextMain),
          decoration: InputDecoration(
            hintText: isBug
                ? 'Mô tả lỗi, màn hình, bước tái hiện…'
                : 'Ý kiến của bạn…',
            hintStyle: TextStyle(color: const Color(0xFF5A7184)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.5)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: kHomeCyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: kHomeCyan,
              foregroundColor: kHomeBg,
            ),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final text = controller.text.trim();
      if (text.isEmpty) return;
      await Clipboard.setData(
        ClipboardData(
          text: '${isBug ? '[BUG]' : '[FEEDBACK]'} $text\n→ $_email',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBug
                  ? 'Đã lưu nội dung báo lỗi vào clipboard'
                  : 'Đã lưu góp ý vào clipboard — gửi tới $_email',
            ),
          ),
        );
      }
    }
    controller.dispose();
  }
}

/// Thông tin ứng dụng — version, legal, licenses.
class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileHubScaffold(
      title: 'THÔNG TIN ỨNG DỤNG',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          HubCard(
            child: Column(
              children: [
                const HubTile(
                  icon: Icons.verified_outlined,
                  title: 'Phiên bản ứng dụng',
                  value: '1.0.0',
                ),
                const HubTile(
                  icon: Icons.build_circle_outlined,
                  title: 'Mã bản dựng',
                  value: '1001',
                ),
                HubTile(
                  icon: Icons.description_outlined,
                  title: 'Điều khoản dịch vụ',
                  onTap: () => context.push(
                    RoutePaths.legalDocument,
                    extra: LegalDocumentArgs.terms,
                  ),
                ),
                HubTile(
                  icon: Icons.policy_outlined,
                  title: 'Chính sách bảo mật',
                  onTap: () => context.push(
                    RoutePaths.legalDocument,
                    extra: LegalDocumentArgs.privacy,
                  ),
                ),
                HubTile(
                  icon: Icons.code_rounded,
                  title: 'Giấy phép nguồn mở',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'CrabSense Mobile',
                    applicationVersion: '1.0.0+1',
                  ),
                ),
                HubTile(
                  icon: Icons.system_update_rounded,
                  title: 'Kiểm tra cập nhật',
                  value: 'Phiên bản mới nhất',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bạn đang dùng phiên bản mới nhất (1.0.0)'),
                      ),
                    );
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
