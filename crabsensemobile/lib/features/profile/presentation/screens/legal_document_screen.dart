import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../widgets/profile_hub_scaffold.dart';

class LegalDocumentArgs {
  const LegalDocumentArgs({required this.title, required this.body});

  final String title;
  final String body;

  static const terms = LegalDocumentArgs(
    title: 'Điều khoản dịch vụ',
    body: '''
Điều khoản sử dụng CrabSense Mobile

1. Phạm vi
Ứng dụng CrabSense hỗ trợ quản lý trang trại nuôi cua thông minh (IoT, camera AI, nhật ký vận hành, đồng bộ ngoại tuyến).

2. Tài khoản
Người dùng chịu trách nhiệm bảo mật thông tin đăng nhập. Không chia sẻ mật khẩu hoặc thiết bị đã đăng nhập với người không được ủy quyền.

3. Dữ liệu vận hành
Dữ liệu cảm biến, hình ảnh/video AI và nhật ký thao tác được xử lý để phục vụ vận hành trang trại theo chính sách bảo mật.

4. Giới hạn trách nhiệm
CrabSense cung cấp công cụ hỗ trợ quyết định. Quyết định kỹ thuật cuối cùng thuộc về cán bộ vận hành trang trại.

5. Cập nhật
Điều khoản có thể được cập nhật theo phiên bản ứng dụng. Tiếp tục sử dụng đồng nghĩa chấp nhận phiên bản mới nhất.
''',
  );

  static const privacy = LegalDocumentArgs(
    title: 'Chính sách bảo mật',
    body: '''
Chính sách bảo mật dữ liệu CrabSense

1. Thu thập
Chúng tôi thu thập thông tin tài khoản (họ tên, email, số điện thoại), dữ liệu trang trại (box, cảm biến, camera), và nhật ký thao tác để vận hành hệ thống.

2. Mục đích
Phục vụ giám sát môi trường, cảnh báo, báo cáo, đồng bộ ngoại tuyến và cải thiện mô hình AI.

3. Lưu trữ & bảo mật
Token xác thực lưu trên thiết bị bằng kho bảo mật. Truyền tải qua kênh HTTPS khi online. Dữ liệu ngoại tuyến được mã hóa ở mức ứng dụng khi khả dụng.

4. Chia sẻ
Không bán dữ liệu cá nhân. Chỉ chia sẻ trong phạm vi trang trại / tổ chức được phân quyền, hoặc khi pháp luật yêu cầu.

5. Quyền của người dùng
Có thể yêu cầu cập nhật hồ sơ, đổi mật khẩu, và liên hệ hỗ trợ để hỏi về dữ liệu cá nhân.
''',
  );
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.args});

  final LegalDocumentArgs args;

  @override
  Widget build(BuildContext context) {
    return ProfileHubScaffold(
      title: args.title.toUpperCase(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          HubCard(
            child: Text(
              args.body.trim(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.45,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Đóng', style: TextStyle(color: kHomeCyan)),
          ),
        ],
      ),
    );
  }
}
