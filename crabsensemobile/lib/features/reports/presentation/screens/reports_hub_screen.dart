import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../profile/presentation/widgets/profile_hub_scaffold.dart';
import '../../data/models/report_models.dart';

/// Hub công cụ Farm Staff; báo cáo quản trị chỉ có trên Web/Desktop.
class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key, this.initialKind});

  final ReportKind? initialKind;

  @override
  Widget build(BuildContext context) {
    if (initialKind != null) {
      return ReportDetailScreen(kind: initialKind!);
    }

    return ProfileHubScaffold(
      title: 'BÁO CÁO & PHÂN TÍCH',
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          HubCard(
            child: Text(
              'Báo cáo quản trị dành cho Farm Administrator trên Web và Farm Manager trên Desktop. Farm Staff sử dụng các công cụ vận hành bên dưới.',
              style: TextStyle(
                color: const Color(0xFF5A7184),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),
          HubCard(
            child: Column(
              children: [
                HubTile(
                  icon: Icons.water_rounded,
                  title: 'Chất lượng nước',
                  subtitle: 'Mở giám sát thông số môi trường',
                  onTap: () => context.push(RoutePaths.waterQuality),
                ),
                HubTile(
                  icon: Icons.scale_rounded,
                  title: 'Pha nước & liều khoáng',
                  subtitle: 'Tính muối để tăng độ mặn, nước ngọt để giảm, '
                      'rồi tính gram CaCl₂ / MgCl₂',
                  onTap: () => context.push(RoutePaths.mineralDosing),
                ),
                HubTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'Báo cáo AI & Dự báo',
                  subtitle: 'Trung tâm AI — phát hiện & khuyến nghị',
                  onTap: () => context.push(RoutePaths.aiCenter),
                ),
                HubTile(
                  icon: Icons.developer_board_rounded,
                  title: 'Tình trạng thiết bị',
                  subtitle: 'Danh sách IoT online / offline',
                  onTap: () => context.push(RoutePaths.devices),
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

/// Retain existing deep-link routes but never request management data on Mobile.
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.kind});

  final ReportKind kind;

  @override
  Widget build(BuildContext context) {
    return ProfileHubScaffold(
      title: kind.titleVi.toUpperCase(),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Farm Staff không có quyền xem hoặc xuất báo cáo quản trị.',
            key: ValueKey('management-report-forbidden'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
