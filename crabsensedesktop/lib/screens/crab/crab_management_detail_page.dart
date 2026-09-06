import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_crab_data.dart';
import '../../models/crab_individual.dart';
import '../../services/camera_device_service.dart';
import '../../services/crab_service.dart';
import '../../services/gateway_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/crab/crab_box_cameras_tab.dart';
import '../../widgets/crab/crab_detail_widgets.dart';
import '../../widgets/crab/crab_management_dialogs.dart';
import '../../widgets/crab/crab_profile_journey.dart';
import '../../widgets/dashboard/glass_card.dart';

class CrabManagementDetailPage extends StatefulWidget {
  const CrabManagementDetailPage({
    super.key,
    required this.crabId,
    required this.service,
    required this.cameraService,
    required this.gatewayService,
    required this.onBack,
  });

  final String crabId;
  final CrabService service;
  final CameraDeviceService cameraService;
  final GatewayService gatewayService;
  final VoidCallback onBack;

  @override
  State<CrabManagementDetailPage> createState() => _CrabManagementDetailPageState();
}

class _CrabManagementDetailPageState extends State<CrabManagementDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  var _detailLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    widget.service.addListener(_rebuild);
    _loadDetail();
  }

  @override
  void dispose() {
    widget.service.removeListener(_rebuild);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _detailLoading = true);
    await widget.service.loadDetail(widget.crabId);
    if (mounted) setState(() => _detailLoading = false);
  }

  void _rebuild() => setState(() {});

  Widget _tabScroll(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final crab = widget.service.getById(widget.crabId);
    if (crab == null) {
      return Center(
        child: Text(
          'Không tìm thấy cua',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Text(
                      'Chi tiết Cua · ${crab.code}',
                      style: GoogleFonts.notoSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                  ),
                  if (_detailLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      tooltip: 'Làm mới',
                      onPressed: _loadDetail,
                      icon: const Icon(Icons.refresh),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => showCrabManagementFormDialog(
                      context,
                      widget.service,
                      existing: crab,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Chỉnh sửa'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.service.profileOf(crab.id)?.locationPath ?? crab.locationLine,
                style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              ),
              const SizedBox(height: 16),
              _DetailKpiRow(crab: crab),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: DashboardColors.oceanBlue,
          unselectedLabelColor: DashboardColors.textMuted,
          indicatorColor: DashboardColors.oceanBlue,
          tabs: const [
            Tab(text: 'Hồ sơ cua'),
            Tab(text: 'Lịch sử sức khỏe'),
            Tab(text: 'Lịch sử lột xác'),
            Tab(text: 'Lịch sử cân nặng'),
            Tab(text: 'Cảnh báo'),
            Tab(text: 'Giá trị cua'),
            Tab(text: 'Hình ảnh / Camera AI'),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: TabBarView(
              controller: _tabs,
              children: [
                _tabScroll(
                  CrabProfileJourney(
                    crab: crab,
                    profile: widget.service.profileOf(crab.id),
                    token: widget.service.token,
                  ),
                ),
                _tabScroll(_HealthHistoryTab(crab: crab)),
                _tabScroll(CrabMoltTimeline(crab: crab)),
                _tabScroll(
                  crab.weightHistory.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có lịch sử cân nặng',
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textMuted,
                            ),
                          ),
                        )
                      : CrabWeightChart(crab: crab),
                ),
                _tabScroll(_AlertsTab(crab: crab)),
                _tabScroll(_ValueTab(crab: crab)),
                CrabBoxCamerasTab(
                  boxId: crab.boxId,
                  cameraService: widget.cameraService,
                  gatewayId: widget.gatewayService.gatewayId,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailKpiRow extends StatelessWidget {
  const _DetailKpiRow({required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    final growth = crab.growthLast7Days;
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 64) / 5;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _kpi('Số lần lột xác', '${crab.moltCount}', Icons.sync, DashboardColors.molting, w),
            _kpi(
              'Tăng trưởng 7 ngày',
              '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(0)}g',
              Icons.trending_up,
              DashboardColors.seaGreen,
              w,
            ),
            _kpi(
              'Cảnh báo',
              '${crab.alertCount}',
              Icons.notifications_active_outlined,
              DashboardColors.monitoring,
              w,
            ),
            _kpi(
              'Giá trị ước tính',
              crab.estimatedValueVnd > 0
                  ? '${(crab.estimatedValueVnd / 1000).toStringAsFixed(0)}k'
                  : '—',
              Icons.payments_outlined,
              DashboardColors.oceanBlue,
              w,
            ),
            _kpi(
              'Chất lượng thịt',
              '${crab.meatQualityScore.toStringAsFixed(0)}%',
              Icons.grade_outlined,
              DashboardColors.healthy,
              w,
            ),
          ],
        );
      },
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width.clamp(140, 280),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthHistoryTab extends StatelessWidget {
  const _HealthHistoryTab({required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    if (crab.healthLogs.isEmpty) {
      return Center(
        child: Text(
          'Chưa có lịch sử sức khỏe — dùng "Ghi nhận sức khỏe" trên danh sách',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
          textAlign: TextAlign.center,
        ),
      );
    }
    return GlassCard(
      child: Column(
        children: [
          for (var i = crab.healthLogs.length - 1; i >= 0; i--) ...[
            if (i < crab.healthLogs.length - 1)
              Divider(color: DashboardColors.cardBorder),
            ListTile(
              title: Text(
                '${crab.healthLogs[i].weightGram.toStringAsFixed(0)}g · ${crab.healthLogs[i].shellSizeCm}cm',
              ),
              subtitle: Text(
                'Mai: ${crab.healthLogs[i].shellCondition} · Bệnh: ${crab.healthLogs[i].diseaseNote}',
              ),
              trailing: Text(MockCrabData.formatDate(crab.healthLogs[i].recordedAt)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: crab.diseases.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Không có cảnh báo',
                  style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                ),
              ),
            )
          : Column(
              children: crab.diseases
                  .map(
                    (d) => ListTile(
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: DashboardColors.monitoring,
                      ),
                      title: Text(d.name),
                      subtitle: Text(d.symptoms),
                      trailing: Text(d.severity.label),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ValueTab extends StatelessWidget {
  const _ValueTab({required this.crab});

  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    final hasValue = crab.estimatedValueVnd > 0;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giá trị ước tính',
            style: GoogleFonts.notoSans(fontSize: 14, color: DashboardColors.textMuted),
          ),
          Text(
            hasValue
                ? '${crab.estimatedValueVnd.toStringAsFixed(0)} VNĐ'
                : 'Chưa đánh giá',
            style: GoogleFonts.notoSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: DashboardColors.oceanBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text('Chất lượng thịt / gạch', style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (crab.meatQualityScore / 100).clamp(0, 1),
            backgroundColor: DashboardColors.cardBorder,
            valueColor: const AlwaysStoppedAnimation(DashboardColors.healthy),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text('${crab.meatQualityScore.toStringAsFixed(0)}% đạt chuẩn xuất khẩu'),
          if (crab.feedings.isNotEmpty) ...[
            const SizedBox(height: 24),
            CrabFeedingTable(crab: crab),
          ],
        ],
      ),
    );
  }
}
