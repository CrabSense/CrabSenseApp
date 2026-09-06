import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/ras_flow.dart';
import '../../services/ras_flow_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/farm/ras_flow_section.dart';

/// Control Center RAS — vận hành thiết bị tuần hoàn, không hiện chỉ số nước.
class RasControlPage extends StatefulWidget {
  const RasControlPage({
    super.key,
    required this.service,
    required this.areaId,
    this.areaName,
  });

  final RasFlowService service;
  final String areaId;
  final String? areaName;

  @override
  State<RasControlPage> createState() => _RasControlPageState();
}

class _RasControlPageState extends State<RasControlPage> {
  var _busyId = '';

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.service.startLiveRefresh(widget.areaId);
  }

  @override
  void didUpdateWidget(RasControlPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId) {
      widget.service.startLiveRefresh(widget.areaId);
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<bool> _cmd(RasFlowNodeLive node, String command) async {
    setState(() => _busyId = node.id);
    final ok = await widget.service.sendCommand(
      areaId: widget.areaId,
      nodeId: node.id,
      command: command,
    );
    if (mounted) setState(() => _busyId = '');
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.service.error ?? 'Không gửi được lệnh'),
        ),
      );
    }
    return ok;
  }

  Future<void> _autoAll(List<RasFlowNodeLive> nodes) async {
    for (final n in nodes.where((e) => e.hasRelay)) {
      await widget.service.sendCommand(
        areaId: widget.areaId,
        nodeId: n.id,
        command: 'auto',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final diagram = svc.diagram;
    final nodes = diagram?.nodes ?? const <RasFlowNodeLive>[];
    final controllable = nodes.where((n) => n.hasRelay).toList();
    final running = controllable.where((n) => n.isOn == true).length;
    final off = controllable.where((n) => n.isOn != true && !n.isFault).length;
    final fault = nodes.where((n) => n.isFault).length;
    final allAuto =
        controllable.isNotEmpty && controllable.every((n) => n.isAuto);
    final anyManual = controllable.any((n) => !n.isAuto);
    final systemOk = fault == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            systemName: diagram?.areaName.isNotEmpty == true
                ? diagram!.areaName
                : (widget.areaName ?? 'Hệ thống RAS'),
            systemOk: systemOk,
            running: running,
            off: off,
            fault: fault,
            allAuto: allAuto,
            loading: svc.loading && diagram == null,
            onAutoAll: controllable.isEmpty
                ? null
                : () => _autoAll(controllable),
          ),
          if (anyManual) ...[
            const SizedBox(height: 12),
            const _ManualBanner(),
          ],
          if (svc.error != null && diagram == null) ...[
            const SizedBox(height: 16),
            Text(svc.error!, style: GoogleFonts.notoSans(color: DashboardColors.risk)),
          ],
          const SizedBox(height: 16),
          const _SectionTitle('Sơ đồ tuần hoàn RAS', Icons.account_tree_outlined),
          const SizedBox(height: 10),
          if (nodes.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Text(
                svc.loading
                    ? 'Đang tải sơ đồ RAS…'
                    : 'Chưa có sơ đồ tuần hoàn cho khu này.',
                style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              ),
            )
          else
            RasFlowSection(
              liveNodes: nodes,
              liveUpdatedAt: svc.lastRefreshedAt,
              liveRefreshing: svc.isRefreshing,
              onRelayCommand: (node, command) => _cmd(node, command),
            ),
          const SizedBox(height: 20),
          const _SectionTitle('Thiết bị điều khiển', Icons.tune),
          const SizedBox(height: 10),
          if (controllable.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Chưa có thiết bị điều khiển (bơm, drum, skimmer). '
                'Thêm relay trên sơ đồ RAS ở Quản lý khu.',
                style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controllable.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: cols == 1 ? 2.1 : 1.35,
                  ),
                  itemBuilder: (_, i) {
                    final n = controllable[i];
                    return _DeviceCard(
                      node: n,
                      busy: _busyId == n.id,
                      onAuto: () => _cmd(n, 'auto'),
                      onOn: () => _cmd(n, n.nodeCode == 'drum' ? 'start' : 'on'),
                      onOff: () => _cmd(n, 'off'),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final alerts = _alertsOf(nodes);
              final activity = diagram?.activity ?? const <RasControlEvent>[];
              final wide = c.maxWidth > 1000;
              final alertCard = _AlertsCard(alerts: alerts);
              final logCard = _ActivityCard(events: activity);
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: alertCard),
                    const SizedBox(width: 16),
                    Expanded(child: logCard),
                  ],
                );
              }
              return Column(
                children: [
                  alertCard,
                  const SizedBox(height: 16),
                  logCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.systemName,
    required this.systemOk,
    required this.running,
    required this.off,
    required this.fault,
    required this.allAuto,
    required this.loading,
    this.onAutoAll,
  });

  final String systemName;
  final bool systemOk;
  final int running;
  final int off;
  final int fault;
  final bool allAuto;
  final bool loading;
  final VoidCallback? onAutoAll;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_input_component, color: DashboardColors.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Điều khiển hệ thống RAS',
                  style: GoogleFonts.notoSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(width: 10),
              _Pill(
                label: allAuto ? 'AUTO MODE' : 'MIXED / MANUAL',
                color: allAuto ? DashboardColors.healthy : DashboardColors.monitoring,
                icon: allAuto ? Icons.smart_toy_outlined : Icons.pan_tool_outlined,
                onTap: onAutoAll,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            systemName,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatChip(
                color: systemOk ? DashboardColors.healthy : DashboardColors.risk,
                label: systemOk
                    ? 'Hệ thống đang hoạt động'
                    : 'Hệ thống có thiết bị lỗi',
              ),
              _StatChip(
                color: DashboardColors.healthy,
                label: '$running Thiết bị đang chạy',
              ),
              _StatChip(
                color: DashboardColors.textMuted,
                label: '$off Thiết bị đang tắt',
              ),
              _StatChip(
                color: fault == 0 ? DashboardColors.healthy : DashboardColors.risk,
                label: '$fault Thiết bị lỗi',
              ),
              _StatChip(
                color: allAuto ? DashboardColors.oceanBlue : DashboardColors.monitoring,
                label: allAuto ? 'Chế độ: AUTO' : 'Có thiết bị Manual',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualBanner extends StatelessWidget {
  const _ManualBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardColors.monitoring.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.monitoring.withValues(alpha: 0.45)),
      ),
      child: Text(
        'Bạn đang điều khiển thủ công một số thiết bị. Chế độ tự động của những thiết bị đó tạm dừng.',
        style: GoogleFonts.notoSans(
          color: DashboardColors.monitoring,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.node,
    required this.busy,
    required this.onAuto,
    required this.onOn,
    required this.onOff,
  });

  final RasFlowNodeLive node;
  final bool busy;
  final VoidCallback onAuto;
  final VoidCallback onOn;
  final VoidCallback onOff;

  @override
  Widget build(BuildContext context) {
    final onLabel = node.nodeCode == 'drum' ? 'START' : 'ON';
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(node.icon, color: DashboardColors.cyan, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: node.runColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                node.runLabel,
                style: GoogleFonts.notoSans(
                  color: node.runColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chế độ: ${node.isAuto ? 'AUTO' : 'MANUAL'}',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CmdBtn(
                label: 'AUTO',
                selected: node.isAuto,
                color: DashboardColors.oceanBlue,
                onTap: busy ? null : onAuto,
              ),
              _CmdBtn(
                label: onLabel,
                selected: node.isOn == true && !node.isAuto,
                color: DashboardColors.healthy,
                onTap: busy ? null : onOn,
              ),
              _CmdBtn(
                label: 'OFF',
                selected: node.isOn != true && !node.isAuto,
                color: DashboardColors.textMuted,
                onTap: busy ? null : onOff,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _runtimeLine(node),
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Cảnh báo thiết bị', Icons.warning_amber_outlined),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            Text(
              'Không có lỗi nghiêm trọng',
              style: GoogleFonts.notoSans(
                color: DashboardColors.healthy,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            for (final a in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  a,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.monitoring,
                    fontSize: 13,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.events});

  final List<RasControlEvent> events;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Hoạt động gần đây', Icons.history),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text(
              'Chưa có lệnh bật/tắt trên khu này.',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            )
          else
            for (final e in events.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        _hhmm(e.at),
                        style: GoogleFonts.robotoMono(
                          color: DashboardColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.title,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DashboardColors.cyan),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.4,
            color: DashboardColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSans(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CmdBtn extends StatelessWidget {
  const _CmdBtn({
    required this.label,
    required this.selected,
    required this.color,
    this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : DashboardColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSans(
            color: selected ? color : DashboardColors.textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

List<String> _alertsOf(List<RasFlowNodeLive> nodes) {
  final out = <String>[];
  for (final n in nodes) {
    if (n.isFault) out.add('${n.displayLabel} đang lỗi / ngoại tuyến');
    if (n.alertMessage != null && n.alertMessage!.isNotEmpty) {
      out.add('${n.displayLabel}: ${n.alertMessage}');
    }
    final start = n.runStartedAt;
    if (n.isOn == true && start != null) {
      final hours = DateTime.now().toUtc().difference(start.toUtc()).inHours;
      if (hours >= 4) {
        out.add('${n.displayLabel} hoạt động liên tục $hours giờ');
      }
    }
    final last = n.lastCommandAt;
    if (n.hasRelay && n.isOn != true && last != null) {
      final hours = DateTime.now().toUtc().difference(last.toUtc()).inHours;
      if (hours >= 2) {
        out.add('${n.displayLabel} chưa hoạt động trong $hours giờ');
      }
    }
  }
  return out;
}

String _runtimeLine(RasFlowNodeLive node) {
  if (node.isOn == true && node.runStartedAt != null) {
    return 'Chạy: ${_elapsed(node.runStartedAt!)}';
  }
  if (node.lastCommandAt != null) {
    final l = node.lastCommandAt!.toLocal();
    return 'Hoạt động gần nhất  ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
  return 'Chưa có lệnh vận hành';
}

String _elapsed(DateTime from) {
  final d = DateTime.now().toUtc().difference(from.toUtc());
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _hhmm(DateTime at) {
  final l = at.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
