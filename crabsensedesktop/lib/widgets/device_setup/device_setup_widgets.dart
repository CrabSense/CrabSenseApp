import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/cloud_edge_connectivity.dart';
import '../../models/device_setup.dart';
import '../../services/connectivity_link_service.dart';
import '../../services/device_setup_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_action_notice.dart';
import '../shared/cloud_edge_header_badges.dart';

Future<void> runDeviceTestWithNotice(
  BuildContext context,
  DeviceSetupService service,
  DeviceSetupTestKind kind,
) {
  final (busy, success) = switch (kind) {
    DeviceSetupTestKind.wifi => (
        'Đang kiểm tra kết nối WiFi...',
        'WiFi: kết nối ổn định!',
      ),
    DeviceSetupTestKind.mqtt => (
        'Đang kiểm tra MQTT Broker...',
        'MQTT: kết nối thành công!',
      ),
    DeviceSetupTestKind.sensorPublish => (
        'Đang gửi thử dữ liệu sensor...',
        'Đã gửi gói sensor thử nghiệm!',
      ),
    DeviceSetupTestKind.relayCommand => (
        'Đang gửi lệnh relay ON/OFF...',
        'Relay phản hồi bình thường!',
      ),
    DeviceSetupTestKind.ping => (
        'Đang ping broker...',
        'Ping thành công!',
      ),
  };
  return AiAssistantActionNotice.run(
    context,
    busyMessage: busy,
    successMessage: success,
    action: () => service.runTest(kind),
  );
}

Future<bool> showDeviceSetupConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận & gửi lên ESP32',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(title, style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
      content: Text(
        message,
        style: GoogleFonts.notoSans(
          color: DashboardColors.textMuted,
          fontSize: 13,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Hủy', style: GoogleFonts.notoSans()),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          child: Text(confirmLabel, style: GoogleFonts.notoSans(fontSize: 12)),
        ),
      ],
    ),
  );
  return ok == true;
}

class DeviceSetupNavPanel extends StatelessWidget {
  const DeviceSetupNavPanel({
    super.key,
    required this.section,
    required this.onSelect,
    required this.nodeStatus,
  });

  final DeviceSetupSection section;
  final ValueChanged<DeviceSetupSection> onSelect;
  final String nodeStatus;

  static const _sections = [
    DeviceSetupSection.deviceInfo,
    DeviceSetupSection.wifi,
    DeviceSetupSection.mqtt,
    DeviceSetupSection.sensorMapping,
    DeviceSetupSection.relayMapping,
    DeviceSetupSection.testConnection,
    DeviceSetupSection.cloudEdge,
    DeviceSetupSection.otaFirmware,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: DashboardColors.sidebarBg.withValues(alpha: 0.92),
        border: Border(
          right: BorderSide(color: DashboardColors.cardBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.memory, color: DashboardColors.purple, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Setup',
                            style: GoogleFonts.notoSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'CONFIGURE IOT NODES',
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textMuted,
                              fontSize: 8,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final s in _sections)
                  _NavTile(
                    icon: s.icon,
                    label: s.label,
                    active: section == s,
                    onTap: () => onSelect(s),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DashboardColors.card.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DashboardColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DashboardColors.healthy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NODE STATUS',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 8,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          nodeStatus,
                          style: GoogleFonts.notoSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active
            ? DashboardColors.purple.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? DashboardColors.purple : DashboardColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active
                          ? DashboardColors.textPrimary
                          : DashboardColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeviceSpecsPanel extends StatelessWidget {
  const DeviceSpecsPanel({
    super.key,
    required this.device,
    required this.onRestart,
    this.busy = false,
  });

  final Esp32Device device;
  final VoidCallback onRestart;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thông số kỹ thuật',
              style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DashboardColors.purple.withValues(alpha: 0.2),
                        DashboardColors.darkNavy,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DashboardColors.cardBorder),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.developer_board,
                      size: 72,
                      color: DashboardColors.purple.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DashboardColors.purple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    device.hardwareVersion,
                    style: GoogleFonts.notoSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _specTile('FIRMWARE', device.firmwareVersion),
            _specTile('MAC ADDRESS', device.macAddress),
            _specTile('IP LOCAL', device.localIp),
            _specTile('UPTIME', device.uptime),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  device.status == DeviceOnlineStatus.online
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 10,
                  color: device.status == DeviceOnlineStatus.online
                      ? DashboardColors.healthy
                      : DashboardColors.risk,
                ),
                const SizedBox(width: 6),
                Text(
                  device.status == DeviceOnlineStatus.online
                      ? 'Trực tuyến'
                      : 'Ngoại tuyến',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.healthy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              'Cập nhật: ${device.lastSeen}',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: busy ? null : onRestart,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restart_alt, size: 18),
              label: Text(
                'Khởi động lại Node',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DashboardColors.textPrimary,
                side: BorderSide(color: DashboardColors.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DashboardColors.darkNavy.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceInfoSection extends StatelessWidget {
  const DeviceInfoSection({super.key, required this.service});

  final DeviceSetupService service;

  @override
  Widget build(BuildContext context) {
    final d = service.device;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin thiết bị ESP32',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _SetupField(
                label: 'Mã thiết bị ESP32',
                initial: d.id,
                readOnly: true,
                width: 220,
              ),
              _SetupField(
                label: 'Tên thiết bị',
                initial: d.name,
                width: 280,
                onChanged: (v) => service.updateDevice(name: v),
              ),
              _SetupDropdown<Esp32DeviceType>(
                label: 'Loại thiết bị',
                value: d.type,
                width: 200,
                items: Esp32DeviceType.values,
                itemLabel: (t) => t.label,
                onChanged: (t) {
                  if (t != null) service.updateDevice(type: t);
                },
              ),
              _SetupField(
                label: 'Khu vực lắp đặt',
                initial: d.area,
                width: 240,
                onChanged: (v) => service.updateDevice(area: v),
              ),
              _SetupField(
                label: 'Gán vào bể / dãy / cảm biến',
                initial: d.assignment,
                width: 320,
                onChanged: (v) => service.updateDevice(assignment: v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _infoChip('Firmware', d.firmwareVersion),
              _infoChip(
                'Trạng thái',
                d.status == DeviceOnlineStatus.online ? 'Online' : 'Offline',
                color: d.status == DeviceOnlineStatus.online
                    ? DashboardColors.healthy
                    : DashboardColors.risk,
              ),
              _infoChip('Last seen', d.lastSeen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        ),
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class WifiSetupSection extends StatelessWidget {
  const WifiSetupSection({super.key, required this.service});

  final DeviceSetupService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thiết lập WiFi',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 20),
              _SetupField(
                label: 'Tên WiFi (SSID)',
                initial: service.wifi.ssid,
                prefixIcon: Icons.wifi,
                width: double.infinity,
                onChanged: service.setWifiSsid,
              ),
              const SizedBox(height: 14),
              _SetupField(
                label: 'Mật khẩu',
                initial: service.wifiPasswordDisplay,
                obscure: !service.wifiPasswordVisible,
                prefixIcon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    service.wifiPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: DashboardColors.textMuted,
                  ),
                  onPressed: service.toggleWifiPasswordVisible,
                ),
                width: double.infinity,
                onChanged: service.setWifiPassword,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  _provisionChip(
                    'SmartConfig',
                    service.wifi.smartConfigEnabled,
                    (v) => service.setWifiOption(smartConfig: v),
                  ),
                  _provisionChip(
                    'BLE Provisioning',
                    service.wifi.bleProvisioningEnabled,
                    (v) => service.setWifiOption(ble: v),
                  ),
                  _provisionChip(
                    'ESP32 AP Setup',
                    service.wifi.apModeEnabled,
                    (v) => service.setWifiOption(apMode: v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Mạng WiFi gần đó',
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: service.busy
                        ? null
                        : () async {
                            await AiAssistantActionNotice.run(
                              context,
                              busyMessage: 'Đang quét WiFi gần đó...',
                              successMessage: 'Đã quét xong các mạng WiFi!',
                              action: service.rescanWifi,
                            );
                          },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('Quét lại', style: GoogleFonts.notoSans(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final n in service.wifiNetworks)
                _WifiNetworkRow(
                  network: n,
                  onTap: () => service.selectWifiNetwork(n.ssid),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: service.busy
                        ? null
                        : () => runDeviceTestWithNotice(
                              context,
                              service,
                              DeviceSetupTestKind.wifi,
                            ),
                    icon: const Icon(Icons.network_check, size: 18),
                    label: Text(
                      'Kiểm tra kết nối',
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: service.busy
                        ? null
                        : () async {
                            final ok = await showDeviceSetupConfirmDialog(
                              context,
                              title: 'Lưu cấu hình WiFi',
                              message:
                                  'Gửi SSID và mật khẩu lên ESP32 ${_deviceId(service)}? '
                                  'Thiết bị có thể ngắt kết nối tạm thời.',
                            );
                            if (ok && context.mounted) {
                              await AiAssistantActionNotice.run(
                                context,
                                busyMessage:
                                    'Đang gửi cấu hình WiFi lên ESP32...',
                                successMessage: 'Đã lưu cấu hình WiFi thành công!',
                                action: service.saveWifiToDevice,
                              );
                            }
                          },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      'Lưu cấu hình',
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: DashboardColors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FallbackRulesCard(rules: service.fallbackRules),
      ],
    );
  }

  Widget _provisionChip(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.notoSans(fontSize: 11)),
      selected: value,
      onSelected: onChanged,
      selectedColor: DashboardColors.purple.withValues(alpha: 0.25),
      checkmarkColor: DashboardColors.purple,
    );
  }
}

class _WifiNetworkRow extends StatelessWidget {
  const _WifiNetworkRow({required this.network, required this.onTap});

  final WifiNetwork network;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: network.selected
          ? DashboardColors.purple.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              if (network.selected)
                const Icon(Icons.check_circle, color: DashboardColors.purple, size: 18)
              else
                Icon(Icons.wifi, color: DashboardColors.textMuted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(network.ssid, style: GoogleFonts.notoSans(fontSize: 13)),
              ),
              if (network.secured)
                Icon(Icons.lock_outline, size: 14, color: DashboardColors.textMuted),
              const SizedBox(width: 8),
              Text(
                '${network.rssi} dBm',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FallbackRulesCard extends StatelessWidget {
  const FallbackRulesCard({super.key, required this.rules});

  final List<FallbackRule> rules;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logic an toàn (Safety Fallback)',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final r in rules)
                SizedBox(
                  width: 320,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DashboardColors.darkNavy.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DashboardColors.cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(r.icon, color: DashboardColors.cyan, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r.description,
                                style: GoogleFonts.notoSans(
                                  color: DashboardColors.textMuted,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _deviceId(DeviceSetupService s) => s.device.id;

class MqttConfigSection extends StatelessWidget {
  const MqttConfigSection({super.key, required this.service});

  final DeviceSetupService service;

  @override
  Widget build(BuildContext context) {
    final s = service;
    final m = s.mqtt;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MQTT Config',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const Spacer(),
              TextButton(
                onPressed: s.applySuggestedTopics,
                child: Text(
                  'Topic đề xuất',
                  style: GoogleFonts.notoSans(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: s.mqttTopicTemplates
                .map(
                  (t) => Chip(
                    label: Text(t, style: GoogleFonts.notoSans(fontSize: 10)),
                    backgroundColor: DashboardColors.darkNavy,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _SetupField(
                label: 'MQTT Broker URL',
                initial: m.brokerUrl,
                width: 280,
                onChanged: (v) => s.setMqttField(brokerUrl: v),
              ),
              _SetupField(
                label: 'Port',
                initial: '${m.port}',
                width: 100,
                onChanged: (v) => s.setMqttField(port: int.tryParse(v) ?? m.port),
              ),
              _SetupField(
                label: 'Username',
                initial: m.username,
                width: 200,
                onChanged: (v) => s.setMqttField(username: v),
              ),
              _SetupField(
                label: 'Password',
                initial: s.mqttPasswordDisplay,
                obscure: !s.mqttPasswordVisible,
                prefixIcon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    s.mqttPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: s.toggleMqttPasswordVisible,
                ),
                width: 200,
                onChanged: (v) => s.setMqttField(password: v),
              ),
              _SetupField(
                label: 'Client ID',
                initial: m.clientId,
                width: 240,
                onChanged: (v) => s.setMqttField(clientId: v),
              ),
              _SetupField(
                label: 'Topic publish',
                initial: m.topicPublish,
                width: 360,
                onChanged: (v) => s.setMqttField(topicPublish: v),
              ),
              _SetupField(
                label: 'Topic subscribe',
                initial: m.topicSubscribe,
                width: 360,
                onChanged: (v) => s.setMqttField(topicSubscribe: v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _labeledDropdown(
                'QoS',
                m.qos,
                const [0, 1, 2],
                (v) => s.setMqttField(qos: v),
              ),
              _labeledDropdown(
                'Keep Alive (s)',
                m.keepAlive,
                const [30, 60, 120],
                (v) => s.setMqttField(keepAlive: v),
              ),
              _SetupSwitch(
                label: 'Clean Session',
                value: m.cleanSession,
                onChanged: (v) => s.setMqttField(cleanSession: v),
              ),
              _SetupSwitch(
                label: 'TLS/SSL',
                value: m.tlsEnabled,
                onChanged: (v) => s.setMqttField(tlsEnabled: v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: s.busy
                    ? null
                    : () => runDeviceTestWithNotice(
                          context,
                          s,
                          DeviceSetupTestKind.mqtt,
                        ),
                icon: const Icon(Icons.hub_outlined, size: 18),
                label: Text('Test MQTT Broker', style: GoogleFonts.notoSans()),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: s.busy
                    ? null
                    : () async {
                        final ok = await showDeviceSetupConfirmDialog(
                          context,
                          title: 'Lưu cấu hình MQTT',
                          message:
                              'Gửi broker, credential và topic lên ESP32? '
                              'Mật khẩu được lưu cục bộ (demo).',
                        );
                        if (ok && context.mounted) {
                          await AiAssistantActionNotice.run(
                            context,
                            busyMessage:
                                'Đang gửi cấu hình MQTT lên ESP32...',
                            successMessage:
                                'Đã lưu cấu hình MQTT thành công!',
                            action: s.saveMqttToDevice,
                          );
                        }
                      },
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text('Lưu cấu hình', style: GoogleFonts.notoSans()),
                style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labeledDropdown(
    String label,
    int value,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.notoSans(fontSize: 12)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: value,
          dropdownColor: DashboardColors.card,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text('$o')))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class SensorMappingSection extends StatelessWidget {
  const SensorMappingSection({super.key, required this.service});

  final DeviceSetupService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Mapping — GPIO',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          for (final m in service.sensorMappings) ...[
            _SensorRow(
              mapping: m,
              onChanged: (updated) => service.updateSensorMapping(m.id, updated),
            ),
            Divider(height: 24, color: DashboardColors.cardBorder),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: service.busy
                  ? null
                  : () async {
                      final ok = await showDeviceSetupConfirmDialog(
                        context,
                        title: 'Lưu Sensor Mapping',
                        message: 'Đồng bộ GPIO và ngưỡng lên ESP32?',
                      );
                      if (ok && context.mounted) {
                        await AiAssistantActionNotice.run(
                          context,
                          busyMessage: 'Đang đồng bộ Sensor Mapping...',
                          successMessage: 'Đã lưu Sensor Mapping thành công!',
                          action: service.saveMappingsToDevice,
                        );
                      }
                    },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text('Lưu mapping', style: GoogleFonts.notoSans()),
              style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({required this.mapping, required this.onChanged});

  final SensorMapping mapping;
  final ValueChanged<SensorMapping> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            mapping.label,
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        _SetupField(
          label: 'GPIO',
          initial: '${mapping.gpio}',
          width: 80,
          onChanged: (v) =>
              onChanged(mapping.copyWith(gpio: int.tryParse(v) ?? mapping.gpio)),
        ),
        _SetupField(
          label: 'Interval (s)',
          initial: '${mapping.sendIntervalSeconds}',
          width: 100,
          onChanged: (v) => onChanged(mapping.copyWith(
            sendIntervalSeconds: int.tryParse(v) ?? mapping.sendIntervalSeconds,
          )),
        ),
        _SetupField(
          label: 'Ngưỡng cảnh báo',
          initial: mapping.alertThreshold,
          width: 160,
          onChanged: (v) => onChanged(mapping.copyWith(alertThreshold: v)),
        ),
        Text(
          mapping.calibrationNote,
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class RelayMappingSection extends StatelessWidget {
  const RelayMappingSection({super.key, required this.service});

  final DeviceSetupService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relay Mapping',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              for (final r in service.relayMappings) ...[
                _RelayRow(
                  mapping: r,
                  onChanged: (u) => service.updateRelayMapping(r.id, u),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: service.busy
                      ? null
                      : () async {
                          final ok = await showDeviceSetupConfirmDialog(
                            context,
                            title: 'Lưu Relay Mapping',
                            message: 'Gửi cấu hình relay và chế độ AUTO/MANUAL?',
                          );
                          if (ok && context.mounted) {
                            await AiAssistantActionNotice.run(
                              context,
                              busyMessage: 'Đang đồng bộ Relay Mapping...',
                              successMessage:
                                  'Đã lưu Relay Mapping thành công!',
                              action: service.saveMappingsToDevice,
                            );
                          }
                        },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text('Lưu mapping', style: GoogleFonts.notoSans()),
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.purple,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FallbackRulesCard(rules: service.fallbackRules),
      ],
    );
  }
}

class _RelayRow extends StatelessWidget {
  const _RelayRow({required this.mapping, required this.onChanged});

  final RelayMapping mapping;
  final ValueChanged<RelayMapping> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              mapping.label,
              style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          _SetupField(
            label: 'GPIO',
            initial: '${mapping.gpio}',
            width: 72,
            onChanged: (v) =>
                onChanged(mapping.copyWith(gpio: int.tryParse(v) ?? mapping.gpio)),
          ),
          SegmentedButton<RelayMode>(
            segments: const [
              ButtonSegment(value: RelayMode.auto, label: Text('AUTO')),
              ButtonSegment(value: RelayMode.manual, label: Text('MANUAL')),
            ],
            selected: {mapping.mode},
            onSelectionChanged: (s) => onChanged(mapping.copyWith(mode: s.first)),
          ),
          Text(
            'An toàn: ${mapping.safeOnDisconnect}',
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class TestConnectionSection extends StatelessWidget {
  const TestConnectionSection({super.key, required this.service});

  final DeviceSetupService service;

  @override
  Widget build(BuildContext context) {
    final r = service.testResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test Connection',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _testBtn(context, 'Test WiFi', DeviceSetupTestKind.wifi),
                  _testBtn(context, 'Test MQTT Broker', DeviceSetupTestKind.mqtt),
                  _testBtn(
                    context,
                    'Gửi thử sensor',
                    DeviceSetupTestKind.sensorPublish,
                  ),
                  _testBtn(
                    context,
                    'Lệnh ON/OFF relay',
                    DeviceSetupTestKind.relayCommand,
                  ),
                  _testBtn(context, 'Ping', DeviceSetupTestKind.ping),
                ],
              ),
              if (service.statusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  service.statusMessage!,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.cyan,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (r != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _resultLine('WiFi', r.wifiConnected ? 'Connected' : 'Failed',
                    ok: r.wifiConnected),
                _resultLine('MQTT', r.mqttConnected ? 'Connected' : 'Failed',
                    ok: r.mqttConnected),
                _resultLine('Signal', '${r.signalDbm} dBm'),
                _resultLine('Latency', '${r.latencyMs} ms'),
                _resultLine('Ping', r.pingOk ? 'OK' : 'Fail', ok: r.pingOk),
                _resultLine('Last Update', r.lastUpdate),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _testBtn(BuildContext context, String label, DeviceSetupTestKind kind) {
    return OutlinedButton(
      onPressed: service.busy
          ? null
          : () => runDeviceTestWithNotice(context, service, kind),
      child: Text(label, style: GoogleFonts.notoSans(fontSize: 12)),
    );
  }

  Widget _resultLine(String label, String value, {bool? ok}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        ),
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ok == null
                ? null
                : (ok ? DashboardColors.healthy : DashboardColors.risk),
          ),
        ),
      ],
    );
  }
}

class CloudEdgeTestSection extends StatelessWidget {
  const CloudEdgeTestSection({
    super.key,
    required this.connectivity,
  });

  final ConnectivityLinkService connectivity;

  @override
  Widget build(BuildContext context) {
    final c = connectivity.cloud;
    final session = connectivity.session;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cloud API — Kết nối',
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ras IoT Cloud · JWT từ đăng nhập · Farm: ${connectivity.farmLabel}',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CloudEdgeHeaderBadges(service: connectivity),
                ],
              ),
              const SizedBox(height: 16),
              _CloudInfoRow(label: 'API URL', value: connectivity.cloudApiUrl),
              _CloudInfoRow(label: 'Farm', value: '${session.selectedFarm.name} (${session.selectedFarm.code})'),
              _CloudInfoRow(label: 'Tài khoản', value: session.user.email),
              _CloudInfoRow(
                label: 'Farm ID',
                value: session.selectedFarm.id,
                mono: true,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: connectivity.busy
                        ? null
                        : () => AiAssistantActionNotice.run(
                              context,
                              busyMessage: 'Đang kiểm tra Cloud (/health + /api/auth/me)...',
                              successMessage: 'Cloud: kết nối thành công!',
                              successFromResult: (ok) => ok
                                  ? 'Cloud API phản hồi OK — JWT hợp lệ'
                                  : 'Cloud: không kết nối được — kiểm tra .env và VPS',
                              action: connectivity.testCloud,
                            ),
                    icon: const Icon(Icons.cloud_done_outlined, size: 18),
                    label: Text('Kiểm tra lại Cloud', style: GoogleFonts.notoSans()),
                    style: FilledButton.styleFrom(
                      backgroundColor: DashboardColors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _LinkStatusCard(status: c),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Luồng dữ liệu (desktop)',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text(
                'ESP32 / Edge tại trại → đồng bộ lên Cloud (${connectivity.cloudApiUrl}) → '
                'CrabFarm Monitor đọc REST API (Bearer token).\n'
                'Ứng dụng desktop không nối trực tiếp Edge trên LAN.',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CloudInfoRow extends StatelessWidget {
  const _CloudInfoRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: (mono ? GoogleFonts.robotoMono : GoogleFonts.notoSans)(
                fontSize: 12,
                color: DashboardColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkStatusCard extends StatelessWidget {
  const _LinkStatusCard({required this.status});

  final ConnectivityLinkStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.isConnected
        ? DashboardColors.healthy
        : status.state == ConnectivityLinkState.checking
            ? DashboardColors.monitoring
            : DashboardColors.risk;

    return SizedBox(
      width: 320,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DashboardColors.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(status.kind.icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  status.kind.label,
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    switch (status.state) {
                      ConnectivityLinkState.connected => 'Connected',
                      ConnectivityLinkState.disconnected => 'Offline',
                      ConnectivityLinkState.checking => 'Checking...',
                      ConnectivityLinkState.unknown => 'Unknown',
                    },
                    style: GoogleFonts.notoSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailRow('Endpoint', status.endpoint),
            if (status.latencyMs != null)
              _detailRow('Latency', '${status.latencyMs} ms'),
            if (status.lastChecked != null)
              _detailRow('Last check', status.lastChecked!),
            if (status.message != null) ...[
              const SizedBox(height: 8),
              Text(
                status.message!,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class OtaFirmwareSection extends StatelessWidget {
  const OtaFirmwareSection({super.key, required this.service});

  final DeviceSetupService service;

  @override
  Widget build(BuildContext context) {
    final o = service.ota;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OTA Firmware',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _infoChip('Phiên bản hiện tại', o.currentVersion),
          const SizedBox(height: 8),
          _infoChip(
            'Bản mới nhất',
            o.latestVersion,
            highlight: o.updateAvailable,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton(
                onPressed: service.busy
                    ? null
                    : () async {
                        await AiAssistantActionNotice.run(
                          context,
                          busyMessage: 'Đang kiểm tra bản firmware...',
                          successMessage: 'Kiểm tra hoàn tất',
                          successFromResult: (hasUpdate) => hasUpdate
                              ? 'Có bản cập nhật firmware mới!'
                              : 'Firmware đã là bản mới nhất!',
                          action: service.checkOtaUpdate,
                        );
                      },
                child: Text('Kiểm tra bản cập nhật', style: GoogleFonts.notoSans()),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: !o.updateAvailable || service.busy
                    ? null
                    : () async {
                        final ok = await showDeviceSetupConfirmDialog(
                          context,
                          title: 'Cập nhật OTA',
                          message:
                              'Cập nhật lên ${o.latestVersion}? '
                              'Có thể rollback nếu lỗi.',
                          confirmLabel: 'Bắt đầu OTA',
                        );
                        if (ok && context.mounted) {
                          await AiAssistantActionNotice.run(
                            context,
                            busyMessage: 'Đang cập nhật firmware OTA...',
                            successMessage: 'Cập nhật OTA thành công!',
                            action: service.applyOtaUpdate,
                            holdSuccess: const Duration(milliseconds: 2800),
                          );
                        }
                      },
                icon: const Icon(Icons.system_update_alt, size: 18),
                label: Text('Cập nhật OTA', style: GoogleFonts.notoSans()),
                style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Lịch sử cập nhật',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          for (final log in o.history)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(log.version, style: GoogleFonts.notoSans(fontSize: 12)),
                  const SizedBox(width: 12),
                  Text(
                    log.appliedAt,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    log.status,
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      color: log.status.contains('Rollback')
                          ? DashboardColors.monitoring
                          : DashboardColors.healthy,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        ),
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w600,
            color: highlight ? DashboardColors.cyan : null,
          ),
        ),
      ],
    );
  }
}

class _SetupField extends StatefulWidget {
  const _SetupField({
    required this.label,
    this.initial,
    this.controller,
    this.width = 200,
    this.onChanged,
    this.readOnly = false,
    this.obscure = false,
    this.prefixIcon,
    this.suffix,
  });

  final String label;
  final String? initial;
  final TextEditingController? controller;
  final double width;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool obscure;
  final IconData? prefixIcon;
  final Widget? suffix;

  @override
  State<_SetupField> createState() => _SetupFieldState();
}

class _SetupFieldState extends State<_SetupField> {
  late TextEditingController _ctrl;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
    } else {
      _ownsController = true;
      _ctrl = TextEditingController(text: widget.initial ?? '');
    }
  }

  @override
  void didUpdateWidget(_SetupField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ownsController &&
        widget.initial != null &&
        widget.initial != oldWidget.initial &&
        _ctrl.text != widget.initial) {
      _ctrl.text = widget.initial!;
    }
  }

  @override
  void dispose() {
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _ctrl,
      readOnly: widget.readOnly,
      obscureText: widget.obscure,
      onChanged: widget.onChanged,
      style: GoogleFonts.notoSans(fontSize: 13),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.notoSans(fontSize: 11),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20, color: DashboardColors.textMuted)
            : null,
        suffixIcon: widget.suffix,
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      ),
    );

    if (widget.width == double.infinity) {
      return SizedBox(width: double.infinity, child: field);
    }
    return SizedBox(width: widget.width, child: field);
  }
}

class _SetupSwitch extends StatelessWidget {
  const _SetupSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.notoSans(fontSize: 12)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: DashboardColors.purple,
        ),
      ],
    );
  }
}

class _SetupDropdown<T> extends StatelessWidget {
  const _SetupDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.width = 200,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.notoSans(fontSize: 11),
          filled: true,
          fillColor: DashboardColors.darkNavy.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        dropdownColor: DashboardColors.card,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(itemLabel(e))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
