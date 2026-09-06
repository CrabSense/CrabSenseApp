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
    final fn = add ? (Listenable l) => l.addListener(_onUpdate) : (Listenable l) => l.removeListener(_onUpdate);
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
    final logs = widget.farmLogService;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 20),
          OwnerAttentionCard(
            items: attention,
            onViewAll: () => widget.onNavigate(AppRoute.alerts),
          ),
          const SizedBox(height: 16),
          OwnerKpiStrip(
            items: [
              ('Tổng hộp', '${summary.total}', DashboardColors.textPrimary),
              ('Đang nuôi', '${summary.occupied}', DashboardColors.blue),
              ('Hộp trống', '${summary.empty}', DashboardColors.textMuted),
              ('Bình thường', '${summary.normal}', DashboardColors.healthy),
              ('Theo dõi', '${summary.watch}', DashboardColors.monitoring),
              (
                'Cảnh báo',
                '${summary.alert + dash.alertCount}',
                (summary.alert + dash.alertCount) > 0
                    ? DashboardColors.risk
                    : DashboardColors.healthy,
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
          OwnerCrabStatusCard(summary: summary),
          const SizedBox(height: 16),
          OwnerRasCard(
            nodes: ras.diagram?.nodes ?? const [],
            onOpen: () => widget.onNavigate(AppRoute.devices),
          ),
          const SizedBox(height: 16),
          OwnerAssistantCard(
            lines: ownerAssistantLines(
              summary: summary,
              hint: dash.assistantHint,
              openAlerts: dash.alertCount,
            ),
            onOpen: () => widget.onNavigate(AppRoute.aiInsight),
          ),
          const SizedBox(height: 16),
          OwnerActivityCard(entries: logs.filteredEntries),
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
