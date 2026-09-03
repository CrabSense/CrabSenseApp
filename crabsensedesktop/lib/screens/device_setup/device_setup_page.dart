import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/device_setup.dart';
import '../../services/connectivity_link_service.dart';
import '../../services/device_setup_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/device_setup/device_setup_widgets.dart';
import '../../widgets/shared/ai_assistant_action_notice.dart';
import '../../widgets/shared/cloud_edge_header_badges.dart';

class DeviceSetupPage extends StatefulWidget {
  const DeviceSetupPage({
    super.key,
    required this.service,
    required this.connectivity,
  });

  final DeviceSetupService service;
  final ConnectivityLinkService connectivity;

  @override
  State<DeviceSetupPage> createState() => _DeviceSetupPageState();
}

class _DeviceSetupPageState extends State<DeviceSetupPage> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.connectivity.addListener(_onUpdate);
  }

  @override
  void dispose() {
    AiAssistantActionNotice.hide();
    widget.service.removeListener(_onUpdate);
    widget.connectivity.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  bool get _showSpecsPanel {
    final s = widget.service.section;
    return s == DeviceSetupSection.wifi ||
        s == DeviceSetupSection.deviceInfo ||
        s == DeviceSetupSection.testConnection ||
        s == DeviceSetupSection.cloudEdge;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeviceSetupNavPanel(
          section: service.section,
          onSelect: service.selectSection,
          nodeStatus: service.nodeStatusLabel,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(service),
                      const SizedBox(height: 20),
                      _buildSection(service),
                    ],
                  ),
                ),
                if (_showSpecsPanel) ...[
                  const SizedBox(width: 20),
                  DeviceSpecsPanel(
                    device: service.device,
                    busy: service.busy,
                    onRestart: () async {
                      final ok = await showDeviceSetupConfirmDialog(
                        context,
                        title: 'Khởi động lại Node',
                        message:
                            'ESP32 sẽ ngắt kết nối MQTT tạm thời. Tiếp tục?',
                        confirmLabel: 'Khởi động lại',
                      );
                      if (ok && context.mounted) {
                        await AiAssistantActionNotice.run(
                          context,
                          busyMessage: 'Đang khởi động lại node ESP32...',
                          successMessage: 'Node đã khởi động lại thành công!',
                          action: service.restartNode,
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(DeviceSetupService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cài đặt — Device Setup',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                service.section.label,
                style: GoogleFonts.notoSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CloudEdgeHeaderBadges(service: widget.connectivity),
          ],
        ),
        if (service.busy || widget.connectivity.busy)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              color: DashboardColors.purple,
              backgroundColor: DashboardColors.cardBorder,
            ),
          ),
      ],
    );
  }

  Widget _buildSection(DeviceSetupService service) {
    return switch (service.section) {
      DeviceSetupSection.deviceInfo => DeviceInfoSection(service: service),
      DeviceSetupSection.wifi => WifiSetupSection(service: service),
      DeviceSetupSection.mqtt => MqttConfigSection(service: service),
      DeviceSetupSection.sensorMapping =>
        SensorMappingSection(service: service),
      DeviceSetupSection.relayMapping => RelayMappingSection(service: service),
      DeviceSetupSection.testConnection =>
        TestConnectionSection(service: service),
      DeviceSetupSection.cloudEdge => CloudEdgeTestSection(
          connectivity: widget.connectivity,
        ),
      DeviceSetupSection.otaFirmware => OtaFirmwareSection(service: service),
    };
  }
}
