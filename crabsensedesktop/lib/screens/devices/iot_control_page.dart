import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/iot_device.dart';
import '../../services/iot_device_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/devices/iot_device_widgets.dart';

class IotControlPage extends StatefulWidget {
  const IotControlPage({super.key, required this.service});

  final IotDeviceService service;

  @override
  State<IotControlPage> createState() => _IotControlPageState();
}

class _IotControlPageState extends State<IotControlPage> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.service.loadUiDevices();
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final devices = service.filteredIotDevices;
    final selected = service.selectedDevice;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Điều Khiển Thiết Bị IoT',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'IoT Device Control Center — SCADA thu nhỏ cho hệ thống RAS',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          IotEmergencyStopButton(service: service),
          const SizedBox(height: 20),
          IotOverviewDashboard(overview: service.overview),
          const SizedBox(height: 16),
          IotKpiStrip(kpi: service.kpi),
          const SizedBox(height: 16),
          IotCategoryChips(
            selected: service.category,
            onSelect: service.setCategory,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1100;
              final main = _MainColumn(
                service: service,
                devices: devices,
                selected: selected,
              );
              final side = _SideColumn(service: service);
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: main),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: side),
                  ],
                );
              }
              return Column(
                children: [
                  main,
                  const SizedBox(height: 16),
                  side,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          IotActivityLogTable(logs: service.activityLogs),
        ],
      ),
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.service,
    required this.devices,
    required this.selected,
  });

  final IotDeviceService service;
  final List<IotDevice> devices;
  final IotDevice? selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Danh sách thiết bị',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 700 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: cols == 2 ? 0.82 : 0.78,
              ),
              itemCount: devices.length,
              itemBuilder: (_, i) {
                final d = devices[i];
                return IotDeviceCard(
                  device: d,
                  service: service,
                  selected: selected?.id == d.id,
                );
              },
            );
          },
        ),
        if (selected != null) ...[
          const SizedBox(height: 16),
          IotDeviceDetailPanel(device: selected!, service: service),
        ],
        const SizedBox(height: 16),
        const IotStatusLegend(),
        const SizedBox(height: 16),
        IotSchedulePanel(
          deviceName: selected?.name ?? 'Pump-01',
          entries: service.schedule,
          calendarBlocks: service.calendarBlocks,
        ),
        const SizedBox(height: 16),
        IotStatsPanel(stats: service.stats),
      ],
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.service});

  final IotDeviceService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IotAssistantPanel(
          insight: service.aiInsight,
          recommendation: service.aiRecommendation,
        ),
        const SizedBox(height: 16),
        IotAutomationPanel(service: service),
        const SizedBox(height: 16),
        IotCoreHealthPanel(
          cpuPercent: service.coreCpuPercent,
          zigbeePercent: service.zigbeeSignalPercent,
        ),
        const SizedBox(height: 16),
        IotSystemAlertsPanel(alerts: service.alerts),
      ],
    );
  }
}
