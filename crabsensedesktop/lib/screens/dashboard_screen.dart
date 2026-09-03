import 'package:flutter/material.dart';

import '../services/farm_dashboard_service.dart';
import '../widgets/dashboard/charts_section.dart';
import '../widgets/dashboard/kpi_widgets.dart';
import '../widgets/dashboard/right_panel.dart';

/// Dashboard body used inside [MainShellScreen].
class DashboardContent extends StatefulWidget {
  const DashboardContent({
    super.key,
    required this.displayName,
    required this.dashboardService,
  });

  final String displayName;
  final FarmDashboardService dashboardService;

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  @override
  void initState() {
    super.initState();
    widget.dashboardService.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.dashboardService.load();
    });
  }

  @override
  void dispose() {
    widget.dashboardService.removeListener(_onUpdate);
    widget.dashboardService.stopLiveRefresh();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.dashboardService;

    if (svc.loading && svc.overview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _MainScrollArea(userName: widget.displayName, service: svc)),
        SizedBox(
          width: 320,
          child: _RightColumn(service: svc),
        ),
      ],
    );
  }
}

class _MainScrollArea extends StatelessWidget {
  const _MainScrollArea({required this.userName, required this.service});

  final String userName;
  final FarmDashboardService service;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (service.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MaterialBanner(
                content: Text(service.error!),
                actions: [
                  TextButton(
                    onPressed: () => service.load(force: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          WelcomeSection(
            userName: userName,
            healthScore: service.healthScore,
            statusMessage: service.statusMessage,
          ),
          const SizedBox(height: 24),
          const Text(
            'Tổng quan',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          KpiGrid(items: service.summaryKpis, columns: 4),
          const SizedBox(height: 24),
          const Text(
            'Chi tiết KPI',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          KpiGrid(items: service.kpiRow1, columns: 6),
          const SizedBox(height: 12),
          KpiGrid(items: service.kpiRow2, columns: 6),
          const SizedBox(height: 24),
          StatusDistributionCard(segments: service.statusSegments),
          const SizedBox(height: 24),
          ChartsSection(dashboardService: service),
          const SizedBox(height: 24),
          AlertsPanel(
            alerts: service.alerts,
            emptyMessage:
                service.hasApiData ? 'Không có cảnh báo' : 'Chưa tải cảnh báo',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.service});

  final FarmDashboardService service;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Column(
        children: [
          EnvironmentPanel(
            params: service.environmentParams,
            isLive: service.isLive,
            lastUpdated: service.lastSensorAt,
          ),
          const SizedBox(height: 16),
          DeviceAlertSummary(
            devicesOnline: service.devicesOnline,
            alertCount: service.alertCount,
          ),
          const SizedBox(height: 16),
          CrabAssistantCard(
            healthScore: service.healthScore,
            hint: service.assistantHint,
          ),
        ],
      ),
    );
  }
}
