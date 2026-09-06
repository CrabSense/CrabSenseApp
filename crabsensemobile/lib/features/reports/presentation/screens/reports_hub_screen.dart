import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../../profile/presentation/widgets/profile_hub_scaffold.dart';
import '../../data/models/report_models.dart';
import '../providers/reports_provider.dart';
import '../utils/report_file_exporter.dart';

/// Hub Báo cáo & Phân tích — API reports + deep-link màn liên quan.
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
              'Báo cáo vận hành từ API /reports. Mở từng mục để xem và xuất CSV/JSON (lưu Drive).',
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
                for (final kind in ReportKind.values)
                  HubTile(
                    icon: switch (kind) {
                      ReportKind.harvest => Icons.inventory_2_outlined,
                      ReportKind.inventory => Icons.point_of_sale_rounded,
                      ReportKind.molting => Icons.trending_up_rounded,
                      ReportKind.survival => Icons.warning_amber_rounded,
                      ReportKind.efficiency => Icons.analytics_outlined,
                    },
                    title: kind.titleVi,
                    subtitle: kind.subtitleVi,
                    onTap: () => context.push(
                      '${RoutePaths.reports}?type=${kind.queryValue}',
                    ),
                    showDivider: kind != ReportKind.values.last,
                  ),
              ],
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

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({super.key, required this.kind});

  final ReportKind kind;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  bool _exporting = false;

  Future<void> _export(ReportDetailData data) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final result = await ReportFileExporter.exportAndShare(data);
      if (!mounted) return;
      if (result.driveUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu CSV${result.jsonPath != null ? ' + JSON' : ''} '
              'vào Google Drive.\n${result.folderUrl ?? ''}',
            ),
            backgroundColor: kHomeSurface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (result.shared) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã mở folder CRAB + sheet chia sẻ.\n'
              'Chọn Google Drive → lưu vào folder vừa mở.',
            ),
            backgroundColor: kHomeSurface,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        await Clipboard.setData(
          ClipboardData(
            text: result.folderUrl ?? result.csvPath,
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File đã lưu máy. Link folder CRAB đã copy.\n'
              '${result.folderUrl ?? ''}',
            ),
            backgroundColor: kHomeOrange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xuất file thất bại: $e'),
          backgroundColor: kHomeOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final async = ref.watch(reportDetailProvider(kind));

    return ProfileHubScaffold(
      title: kind.titleVi.toUpperCase(),
      actions: [
        if (async.hasValue)
          IconButton(
            tooltip: 'Xuất CSV / lưu Drive',
            onPressed: _exporting ? null : () => _export(async.requireValue),
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kHomeCyan,
                    ),
                  )
                : const Icon(Icons.download_rounded, color: kHomeCyan),
          ),
        IconButton(
          tooltip: 'Làm mới',
          onPressed: () => ref.invalidate(reportDetailProvider(kind)),
          icon: const Icon(Icons.refresh_rounded, color: kHomeCyan),
        ),
      ],
      onRefresh: () async => ref.refresh(reportDetailProvider(kind).future),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: kHomeCyan),
        ),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            HubCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Không tải được báo cáo',
                    style: TextStyle(
                      color: kHomeTextMain,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    style: TextStyle(
                      color: const Color(0xFF5A7184),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(reportDetailProvider(kind)),
                    style: FilledButton.styleFrom(
                      backgroundColor: kHomeCyan,
                      foregroundColor: kHomeBg,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (data) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _exporting ? null : () => _export(data),
                icon: _exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
                label: Text(
                  _exporting
                      ? 'Đang lưu Drive…'
                      : 'Xuất & lưu Google Drive',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: kHomeCyan,
                  foregroundColor: kHomeBg,
                ),
              ),
            ),
            const SizedBox(height: 14),
            HubCard(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final m in data.metrics)
                    _MetricChip(label: m.label, value: m.value),
                ],
              ),
            ),
            for (final section in data.sections) ...[
              const SizedBox(height: 14),
              HubCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        color: kHomePrimaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < section.rows.length; i++)
                      HubTile(
                        icon: Icons.bar_chart_rounded,
                        title: section.rows[i].label,
                        subtitle: section.rows[i].hint,
                        value: section.rows[i].value,
                        showDivider: i != section.rows.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: homeTileDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF5A7184),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: kHomeCyan,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
