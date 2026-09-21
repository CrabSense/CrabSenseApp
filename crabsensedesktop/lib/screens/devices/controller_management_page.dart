import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/esp_controller.dart';
import '../../models/iot_device.dart';
import '../../services/controller_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import 'add_controller_dialog.dart';

/// Đăng ký / xem từng ESP32. Sensor và output thuộc controller, không hard-code 1 board.
class ControllerManagementPage extends StatefulWidget {
  const ControllerManagementPage({
    super.key,
    required this.service,
    this.areaName,
  });

  final ControllerService service;
  final String? areaName;

  @override
  State<ControllerManagementPage> createState() =>
      _ControllerManagementPageState();
}

class _ControllerManagementPageState extends State<ControllerManagementPage> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.service.load();
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.developer_board, color: DashboardColors.cyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý Controller',
                        style: GoogleFonts.notoSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mỗi ESP32 là một controller. Sensor và output (bơm, drum, van) gắn vào board đó.',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showAdd(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm Controller'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Chip(
                color: DashboardColors.healthy,
                label: '${svc.onlineCount} Online',
              ),
              _Chip(
                color: DashboardColors.textMuted,
                label: '${svc.offlineCount} Offline',
              ),
              _Chip(
                color: DashboardColors.oceanBlue,
                label: '${svc.items.length} Controller',
              ),
              if (widget.areaName != null)
                _Chip(
                  color: DashboardColors.purple,
                  label: widget.areaName!,
                ),
            ],
          ),
          if (svc.loading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (svc.error != null) ...[
            const SizedBox(height: 12),
            Text(
              svc.error!,
              style: GoogleFonts.notoSans(color: DashboardColors.risk),
            ),
          ],
          const SizedBox(height: 20),
          if (!svc.loading && svc.items.isEmpty)
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(
                      Icons.memory_outlined,
                      color: DashboardColors.textMuted,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Chưa có controller trên khu này',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thêm ESP32-S3 đầu tiên — sau này thêm board thứ 2 không cần đổi schema.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 720 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: svc.items.length,
                  itemBuilder: (_, i) {
                    final d = svc.items[i];
                    return _ControllerCard(
                      device: d,
                      selected: svc.selectedId == d.id,
                      onOpen: () => svc.select(d.id),
                    );
                  },
                );
              },
            ),
          if (svc.detail != null) ...[
            const SizedBox(height: 20),
            _DetailPanel(
              detail: svc.detail!,
              loading: svc.detailLoading,
            ),
          ] else if (svc.detailLoading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _showAdd(BuildContext context) async {
    final saved = await showAddControllerDialog(
      context,
      service: widget.service,
      session: widget.service.session,
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm Controller')),
    );
  }
}

class _ControllerCard extends StatelessWidget {
  const _ControllerCard({
    required this.device,
    required this.selected,
    required this.onOpen,
  });

  final IoTDevice device;
  final bool selected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final online = device.isOnline;
    final color = online ? DashboardColors.healthy : DashboardColors.textMuted;
    return GlassCard(
      highlight: selected,
      onTap: onOpen,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.deviceName ?? device.deviceCode,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            device.deviceCode,
            style: GoogleFonts.robotoMono(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          if ((device.deviceType ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              controllerTypeLabel(device.deviceType!),
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            online ? 'Online' : 'Offline',
            style: GoogleFonts.notoSans(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            device.ipLan != null && device.ipLan!.isNotEmpty
                ? 'WiFi: ${device.ipLan}'
                : (online ? 'WiFi: Connected' : 'Chưa có IP'),
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          Text(
            'Last seen: ${_lastSeen(device.lastSeenAt)}',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            '${device.sensorCount} Sensors • ${device.actuatorCount} Outputs',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selected ? 'Đang xem chi tiết' : 'Xem chi tiết',
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _lastSeen(DateTime? at) {
    if (at == null) return 'Chưa từng';
    final ago = DateTime.now().difference(at.toLocal());
    if (ago.inSeconds < 15) return 'Vừa xong';
    if (ago.inMinutes < 1) return '${ago.inSeconds} giây trước';
    if (ago.inHours < 1) return '${ago.inMinutes} phút trước';
    return '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.detail, required this.loading});

  final ControllerDetail detail;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = detail.controller;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.deviceName ?? c.deviceCode,
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              c.deviceType ?? 'ESP32',
              if (c.firmwareVersion != null) 'FW ${c.firmwareVersion}',
              if (c.macAddress != null && c.macAddress!.isNotEmpty)
                'MAC ${c.macAddress}',
              if (c.areaName != null) c.areaName!,
            ].join(' · '),
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth > 800;
              final sensors = _ChildList(
                title: 'Sensors',
                empty: 'Chưa gắn cảm biến — Sensor.DeviceId = controller này.',
                items: detail.sensors,
              );
              final acts = _ChildList(
                title: 'Outputs / Actuators',
                empty:
                    'Chưa gắn output — bơm/drum/van dùng RasComponent.RelayDeviceId.',
                items: detail.actuators,
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: sensors),
                    const SizedBox(width: 16),
                    Expanded(child: acts),
                  ],
                );
              }
              return Column(children: [sensors, const SizedBox(height: 12), acts]);
            },
          ),
        ],
      ),
    );
  }
}

class _ChildList extends StatelessWidget {
  const _ChildList({
    required this.title,
    required this.empty,
    required this.items,
  });

  final String title;
  final String empty;
  final List<ControllerChild> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.4,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            empty,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          )
        else
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    i.kind == 'sensor'
                        ? Icons.sensors
                        : Icons.settings_input_component,
                    size: 16,
                    color: DashboardColors.cyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i.name.isEmpty ? i.code : '${i.name}  (${i.code})',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (i.latestValue != null)
                    Text(
                      i.latestValue!.toStringAsFixed(
                        i.latestValue!.abs() >= 100 ? 0 : 2,
                      ),
                      style: GoogleFonts.robotoMono(
                        color: DashboardColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (i.unit != null && i.unit!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      i.unit!,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (i.isOn != null)
                    Text(
                      i.isOn! ? 'ON' : 'OFF',
                      style: GoogleFonts.notoSans(
                        color: i.isOn!
                            ? DashboardColors.healthy
                            : DashboardColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSans(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
