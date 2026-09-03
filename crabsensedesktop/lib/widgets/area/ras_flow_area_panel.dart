import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/ras_flow.dart';
import '../../services/ras_flow_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../farm/ras_flow_section.dart';

/// Sơ đồ RAS + quản lý node theo khu.
class RasFlowAreaPanel extends StatefulWidget {
  const RasFlowAreaPanel({
    super.key,
    required this.service,
    required this.areaId,
  });

  final RasFlowService service;
  final String areaId;

  @override
  State<RasFlowAreaPanel> createState() => _RasFlowAreaPanelState();
}

class _RasFlowAreaPanelState extends State<RasFlowAreaPanel> {
  final _codeCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '0');
  final _relayCtrl = TextEditingController();
  final _paramCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    _codeCtrl.dispose();
    _labelCtrl.dispose();
    _orderCtrl.dispose();
    _relayCtrl.dispose();
    _paramCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  Future<void> _addNode() async {
    final code = _codeCtrl.text.trim();
    final label = _labelCtrl.text.trim();
    if (code.isEmpty || label.isEmpty) return;
    final order = int.tryParse(_orderCtrl.text.trim()) ?? 0;
    final ok = await widget.service.addNode(
      areaId: widget.areaId,
      nodeCode: code,
      displayLabel: label,
      sortOrder: order,
      relayChannel: _relayCtrl.text.trim().isEmpty ? null : _relayCtrl.text.trim(),
      paramDefaults: _paramCtrl.text.trim().isEmpty ? null : _paramCtrl.text.trim(),
    );
    if (ok && mounted) {
      _codeCtrl.clear();
      _labelCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm node')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    if (svc.loading && svc.diagram == null) {
      return const Center(child: CircularProgressIndicator(color: DashboardColors.cyan));
    }

    final diagram = svc.diagram;
    if (diagram == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(svc.error ?? 'Không tải sơ đồ RAS', style: GoogleFonts.notoSans(color: DashboardColors.risk)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => svc.loadDiagram(widget.areaId),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sơ đồ hệ thống RAS — ${diagram.areaName}',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ),
            _LiveStatusBadge(service: svc),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryChip(
              icon: Icons.bolt,
              label: '${diagram.totalPowerW.toStringAsFixed(0)} W tổng',
              color: DashboardColors.molting,
            ),
            _SummaryChip(
              icon: Icons.play_circle_outline,
              label: '${diagram.runningCount}/${diagram.controllableCount} đang chạy',
              color: DashboardColors.healthy,
            ),
            _SummaryChip(
              icon: Icons.wifi,
              label: '${diagram.onlineCount}/${diagram.nodes.length} online',
              color: DashboardColors.cyan,
            ),
          ],
        ),
        const SizedBox(height: 16),
        RasFlowSection(
          liveNodes: diagram.nodes,
          liveUpdatedAt: svc.lastRefreshedAt,
          liveRefreshing: svc.isRefreshing,
          onRelayCommand: (node, cmd) => svc.sendCommand(
            areaId: widget.areaId,
            nodeId: node.id,
            command: cmd,
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Thêm node vào sơ đồ',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 12),
              _field(_codeCtrl, 'Mã node', 'drum'),
              const SizedBox(height: 8),
              _field(_labelCtrl, 'Nhãn hiển thị', 'Drum Filter'),
              const SizedBox(height: 8),
              _field(_orderCtrl, 'Thứ tự', '8', keyboard: TextInputType.number),
              const SizedBox(height: 8),
              _field(_relayCtrl, 'Máy relay (channel)', 'drum_filter'),
              const SizedBox(height: 8),
              _field(_paramCtrl, 'Thông số JSON', '{"capacity_l":100}'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _addNode,
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
                style: FilledButton.styleFrom(backgroundColor: DashboardColors.cyan),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Thứ tự sơ đồ tuần hoàn',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...diagram.nodes.asMap().entries.map((e) {
          final i = e.key;
          final n = e.value;
          final ids = diagram.nodes.map((x) => x.id).toList();
          return _NodeListTile(
            node: n,
            onMoveUp: i > 0
                ? () {
                    final next = List<String>.from(ids);
                    final t = next[i - 1];
                    next[i - 1] = next[i];
                    next[i] = t;
                    svc.reorderNodes(areaId: widget.areaId, nodeIdsInOrder: next);
                  }
                : null,
            onMoveDown: i < diagram.nodes.length - 1
                ? () {
                    final next = List<String>.from(ids);
                    final t = next[i + 1];
                    next[i + 1] = next[i];
                    next[i] = t;
                    svc.reorderNodes(areaId: widget.areaId, nodeIdsInOrder: next);
                  }
                : null,
            onDelete: () => svc.deleteNode(areaId: widget.areaId, nodeId: n.id),
          );
        }),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    String hint, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: DashboardColors.darkNavy,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
    );
  }
}

class _LiveStatusBadge extends StatelessWidget {
  const _LiveStatusBadge({required this.service});

  final RasFlowService service;

  @override
  Widget build(BuildContext context) {
    if (!service.isLiveActive) return const SizedBox.shrink();
    final at = service.lastRefreshedAt;
    final time = at != null
        ? '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}:${at.second.toString().padLeft(2, '0')}'
        : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DashboardColors.healthy.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DashboardColors.healthy.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: service.isRefreshing
                ? const CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: DashboardColors.healthy,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      color: DashboardColors.healthy,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE · $time',
            style: GoogleFonts.notoSans(
              color: DashboardColors.healthy,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.notoSans(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}

class _NodeListTile extends StatelessWidget {
  const _NodeListTile({
    required this.node,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  final RasFlowNodeLive node;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: DashboardColors.darkNavy,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${node.sortOrder}. ${node.displayLabel}',
            style: GoogleFonts.notoSans(fontSize: 13)),
        subtitle: Text(
          '${node.nodeCode} · relay: ${node.relayChannel ?? "—"}',
          style: GoogleFonts.robotoMono(fontSize: 11, color: DashboardColors.textMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 18),
              onPressed: onMoveUp,
              color: onMoveUp == null ? DashboardColors.textMuted : DashboardColors.cyan,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward, size: 18),
              onPressed: onMoveDown,
              color: onMoveDown == null ? DashboardColors.textMuted : DashboardColors.cyan,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: DashboardColors.risk),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
