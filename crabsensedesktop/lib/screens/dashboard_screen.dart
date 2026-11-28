import 'package:flutter/material.dart';

import '../navigation/app_route.dart';
import '../services/alert_service.dart';
import '../services/farm_dashboard_service.dart';
import '../services/farm_layout_service.dart';
import '../services/farm_log_service.dart';
import '../services/ras_flow_service.dart';
import '../services/water_analysis_service.dart';
import '../services/water_quality_service.dart';
import '../theme/dashboard_theme.dart';
import '../widgets/dashboard/owner_dashboard_sections.dart';

/// Dashboard Owner — 5 giây biết trại có ổn không.
class DashboardContent extends StatefulWidget {
  const DashboardContent({
    super.key,
    required this.displayName,
    required this.dashboardService,
    required this.farmLayoutService,
    required this.waterQualityService,
    required this.waterAnalysisService,
    required this.rasFlowService,
    required this.alertService,
    required this.farmLogService,
    required this.areaId,
    required this.onNavigate,
    this.areaLabel,
  });

  final String displayName;
  final FarmDashboardService dashboardService;
  final FarmLayoutService farmLayoutService;
  final WaterQualityService waterQualityService;
  final WaterAnalysisService waterAnalysisService;
  final RasFlowService rasFlowService;
  final AlertService alertService;
  final FarmLogService farmLogService;
  final String areaId;
  final ValueChanged<AppRoute> onNavigate;
  final String? areaLabel;

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  @override
  void initState() {
    super.initState();
    _listen(true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didUpdateWidget(DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dashboardService != widget.dashboardService) {
      oldWidget.dashboardService.removeListener(_onUpdate);
      widget.dashboardService.addListener(_onUpdate);
    }
    if (oldWidget.farmLayoutService != widget.farmLayoutService) {
      oldWidget.farmLayoutService.removeListener(_onUpdate);
      widget.farmLayoutService.addListener(_onUpdate);
    }
    if (oldWidget.waterQualityService != widget.waterQualityService) {
      oldWidget.waterQualityService.removeListener(_onUpdate);
      widget.waterQualityService.addListener(_onUpdate);
    }
    if (oldWidget.waterAnalysisService != widget.waterAnalysisService) {
      oldWidget.waterAnalysisService.removeListener(_onUpdate);
      widget.waterAnalysisService.addListener(_onUpdate);
    }
    if (oldWidget.rasFlowService != widget.rasFlowService) {
      oldWidget.rasFlowService.removeListener(_onUpdate);
      widget.rasFlowService.addListener(_onUpdate);
    }
    if (oldWidget.alertService != widget.alertService) {
      oldWidget.alertService.removeListener(_onUpdate);
      widget.alertService.addListener(_onUpdate);
    }
    if (oldWidget.farmLogService != widget.farmLogService) {
      oldWidget.farmLogService.removeListener(_onUpdate);
      widget.farmLogService.addListener(_onUpdate);
    }
  }

  @override
  void dispose() {
    _listen(false);
    super.dispose();
  }

  void _listen(bool add) {
    final fn = add
        ? (Listenable l) => l.addListener(_onUpdate)
        : (Listenable l) => l.removeListener(_onUpdate);
    fn(widget.dashboardService);
    fn(widget.farmLayoutService);
    fn(widget.waterQualityService);
    fn(widget.waterAnalysisService);
    fn(widget.rasFlowService);
    fn(widget.alertService);
    fn(widget.farmLogService);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _bootstrap() {
    widget.dashboardService.load();
    widget.farmLayoutService.load();
    widget.waterQualityService.refresh();
    widget.waterAnalysisService.load();
    widget.alertService.load();
    widget.farmLogService.load();
    if (widget.areaId.isNotEmpty) {
      widget.rasFlowService.startLiveRefresh(widget.areaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = widget.dashboardService;
    final layout = widget.farmLayoutService;
    final water = dash.qualifiedReadingsFor(widget.areaId);
    final analysis = widget.waterAnalysisService;
    final ras = widget.rasFlowService;
    final alerts = widget.alertService;
    final summary = layout.summary;
    final layoutVerified = !layout.loading && layout.error == null &&
        layout.loadedAt != null && layout.selectedAreaId == widget.areaId;
    String count(int n) => layoutVerified ? '$n' : '—';
    double? ratio(int n) => layoutVerified && summary.total > 0 ? n / summary.total : null;
    String percent(int n) => ratio(n) == null ? '—' : '${(ratio(n)! * 100).round()}%';

    final attention = ownerAttentionItems(
      alerts: alerts.filteredAlerts,
      summary: summary,
      water: water,
    );
    final stable = false; // No overall safety inference from an area sample.
    final status = attention.isEmpty
        ? 'Chưa xác minh toàn bộ trạng thái hệ thống; xem từng chỉ số nước.'
        : 'Có chỉ số hoặc cảnh báo cần theo dõi.';

    if (dash.loading && dash.overview == null && layout.boxes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final alertCount = dash.alertCount;
    final alertBoxes = layoutVerified ? summary.alert : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerWelcome(
            userName: widget.displayName,
            stable: stable,
            statusMessage: status,
          ),
          if (dash.error != null) ...[
            const SizedBox(height: 12),
            Text(
              dash.error!,
              style: const TextStyle(color: DashboardColors.risk, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          OwnerAttentionCard(
            items: attention,
            alertBoxCount: alertBoxes,
            areaLabel: widget.areaLabel,
            onViewAll: () => widget.onNavigate(AppRoute.alerts),
          ),
          const SizedBox(height: 16),
          OwnerKpiStrip(
            items: [
              OwnerKpiItem(
                label: 'Tổng hộp',
                value: count(summary.total),
                caption: 'Theo khu đã xác minh',
                color: DashboardColors.textPrimary,
                icon: Icons.inventory_2_outlined,
              ),
              OwnerKpiItem(
                label: 'Đang nuôi',
                value: count(summary.occupied),
                caption: percent(summary.occupied),
                color: DashboardColors.blue,
                icon: Icons.pets_outlined,
                progress: ratio(summary.occupied),
              ),
              OwnerKpiItem(
                label: 'Hộp trống',
                value: count(summary.empty),
                caption: percent(summary.empty),
                color: DashboardColors.dead,
                icon: Icons.crop_square_outlined,
                progress: ratio(summary.empty),
              ),
              OwnerKpiItem(
                label: 'Bình thường',
                value: count(summary.normal),
                caption: percent(summary.normal),
                color: DashboardColors.healthy,
                icon: Icons.check_circle_outline,
                progress: ratio(summary.normal),
              ),
              OwnerKpiItem(
                label: 'Theo dõi',
                value: count(summary.watch),
                caption: percent(summary.watch),
                color: DashboardColors.monitoring,
                icon: Icons.visibility_outlined,
                progress: ratio(summary.watch),
              ),
              OwnerKpiItem(
                label: 'Cảnh báo mở',
                value: alertCount?.toString() ?? '—',
                caption: 'Số bản ghi cảnh báo, không phải số hộp',
                color: (alertCount ?? 0) > 0 ? DashboardColors.risk : DashboardColors.textMuted,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 980;
              final waterCard = OwnerWaterCard(
                readings: water,
                onOpenRealtime: () => widget.onNavigate(AppRoute.environment),
              );
              final analysisCard = OwnerAnalysisCard(
                run: analysis.snapshot?.latest,
                onOpen: () => widget.onNavigate(AppRoute.waterAnalysis),
              );
              if (!wide) {
                return Column(
                  children: [
                    waterCard,
                    const SizedBox(height: 16),
                    analysisCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: waterCard),
                  const SizedBox(width: 16),
                  Expanded(child: analysisCard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1100;
              final crab = layoutVerified ? OwnerCrabStatusCard(summary: summary) :
                  const Center(child: Text('Chưa xác minh tình trạng hộp.'));
              final trend = OwnerTrendCard(readings: water, onOpenHistory: () => widget.onNavigate(AppRoute.environment));
              final devices = OwnerRasCard(
                nodes: ras.diagram?.nodes ?? const [],
                onOpen: () => widget.onNavigate(AppRoute.devices),
              );
              if (!wide) {
                return Column(
                  children: [
                    crab,
                    const SizedBox(height: 16),
                    trend,
                    const SizedBox(height: 16),
                    devices,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: crab),
                  const SizedBox(width: 16),
                  Expanded(child: trend),
                  const SizedBox(width: 16),
                  Expanded(child: devices),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}
