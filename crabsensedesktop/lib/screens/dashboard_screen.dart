import 'package:flutter/material.dart';

import '../models/farm_layout.dart';
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
    final water = widget.waterQualityService;
    final analysis = widget.waterAnalysisService;
    final ras = widget.rasFlowService;
    final alerts = widget.alertService;
    final summary = layout.boxes.isNotEmpty
        ? layout.summary
        : _summaryFromDashboard(dash);

    final attention = ownerAttentionItems(
      alerts: alerts.filteredAlerts,
      summary: summary,
      water: water.readings,
    );
    final stable = attention.isEmpty && dash.alertCount == 0;
    final status = stable
        ? 'Hệ thống hoạt động ổn định'
        : (dash.statusMessage.isNotEmpty
            ? dash.statusMessage
            : 'Có việc cần Owner xem');

    if (dash.loading && dash.overview == null && layout.boxes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = summary.total <= 0 ? 1 : summary.total;
    final alertCount = summary.alert + dash.alertCount;

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
            alertBoxCount: alertCount,
            areaLabel: widget.areaLabel,
            onViewAll: () => widget.onNavigate(AppRoute.alerts),
          ),
          const SizedBox(height: 16),
          OwnerKpiStrip(
            items: [
              OwnerKpiItem(
                label: 'Tổng hộp',
                value: '${summary.total}',
                caption: '↑ so với hôm qua',
                color: DashboardColors.textPrimary,
                icon: Icons.inventory_2_outlined,
              ),
              OwnerKpiItem(
                label: 'Đang nuôi',
                value: '${summary.occupied}',
                caption: '${((summary.occupied / total) * 100).round()}%',
                color: DashboardColors.blue,
                icon: Icons.pets_outlined,
                progress: summary.occupied / total,
              ),
              OwnerKpiItem(
                label: 'Hộp trống',
                value: '${summary.empty}',
                caption: '${((summary.empty / total) * 100).round()}%',
                color: DashboardColors.dead,
                icon: Icons.crop_square_outlined,
                progress: summary.empty / total,
              ),
              OwnerKpiItem(
                label: 'Bình thường',
                value: '${summary.normal}',
                caption: '${((summary.normal / total) * 100).round()}%',
                color: DashboardColors.healthy,
                icon: Icons.check_circle_outline,
                progress: summary.normal / total,
              ),
              OwnerKpiItem(
                label: 'Theo dõi',
                value: '${summary.watch}',
                caption: '${((summary.watch / total) * 100).round()}%',
                color: DashboardColors.monitoring,
                icon: Icons.visibility_outlined,
                progress: summary.watch / total,
              ),
              OwnerKpiItem(
                label: 'Cảnh báo',
                value: '$alertCount',
                caption: '${((alertCount / total) * 100).round()}%',
                color: alertCount > 0
                    ? DashboardColors.risk
                    : DashboardColors.healthy,
                icon: Icons.warning_amber_rounded,
                progress: alertCount / total,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 980;
              final waterCard = OwnerWaterCard(
                readings: water.readings,
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
              final crab = OwnerCrabStatusCard(summary: summary);
              final trend = OwnerTrendCard(readings: water.readings);
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

  FarmLayoutSummary _summaryFromDashboard(FarmDashboardService dash) {
    int pick(String needle) {
      for (final k in [...dash.summaryKpis, ...dash.kpiRow1]) {
        if (k.label.toLowerCase().contains(needle)) {
          return int.tryParse(k.value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }
      }
      return 0;
    }

    final total = pick('tổng hộp') > 0 ? pick('tổng hộp') : pick('hộp');
    final occupied = pick('đang nuôi');
    final alerts = pick('cảnh báo');
    return FarmLayoutSummary(
      total: total,
      occupied: occupied,
      empty: (total - occupied).clamp(0, total),
      normal: occupied,
      watch: 0,
      molting: 0,
      alert: alerts,
      deceased: 0,
    );
  }
}
