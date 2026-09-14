import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../services/area_management_service.dart';
import '../../services/farm_layout_service.dart';
import '../../services/ras_flow_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import 'ras_flow_section.dart';

/// Sơ đồ RAS trên Bản đồ trại — API + live 2s, theo khu lọc (A/B/C).
class FarmLayoutRasFlow extends StatefulWidget {
  const FarmLayoutRasFlow({
    super.key,
    required this.rasFlowService,
    required this.areaService,
    this.farmLayoutService,
    this.zoneFilter,
    this.areaId,
    this.compact = false,
    this.onOpenRasControl,
  });

  final RasFlowService rasFlowService;
  final AreaManagementService areaService;
  final FarmLayoutService? farmLayoutService;
  /// Mã khu cũ (AREA-A01). Ưu tiên [areaId] nếu có.
  final String? zoneFilter;
  /// Id FarmingArea đang xem trên bản đồ / header.
  final String? areaId;
  final bool compact;
  final VoidCallback? onOpenRasControl;

  @override
  State<FarmLayoutRasFlow> createState() => _FarmLayoutRasFlowState();
}

class _FarmLayoutRasFlowState extends State<FarmLayoutRasFlow> {
  String? _activeAreaId;

  @override
  void initState() {
    super.initState();
    widget.rasFlowService.addListener(_onUpdate);
    widget.areaService.addListener(_onUpdate);
    widget.farmLayoutService?.addListener(_onFarmLayoutUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didUpdateWidget(FarmLayoutRasFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoneFilter != widget.zoneFilter ||
        oldWidget.areaId != widget.areaId ||
        oldWidget.farmLayoutService != widget.farmLayoutService) {
      _syncLiveRefresh();
    }
  }

  @override
  void dispose() {
    widget.rasFlowService.removeListener(_onUpdate);
    widget.areaService.removeListener(_onUpdate);
    widget.farmLayoutService?.removeListener(_onFarmLayoutUpdate);
    widget.rasFlowService.stopLiveRefresh(notify: false);
    super.dispose();
  }

  void _onFarmLayoutUpdate() {
    if (mounted) _syncLiveRefresh();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  List<AreaRecord> get _areas {
    final fromLayout = widget.farmLayoutService?.areas;
    if (fromLayout != null && fromLayout.isNotEmpty) return fromLayout;
    return widget.areaService.areas;
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    if (_areas.isEmpty && !widget.areaService.loading) {
      await widget.areaService.load();
    }
    if (mounted) _syncLiveRefresh();
  }

  void _syncLiveRefresh() {
    final id = _resolveAreaId();
    if (id == _activeAreaId && widget.rasFlowService.isLiveActive) return;

    _activeAreaId = id;
    if (id == null) {
      widget.rasFlowService.stopLiveRefresh();
      return;
    }
    widget.rasFlowService.startLiveRefresh(id);
  }

  String? _resolveAreaId() {
    final areas = _areas;
    final explicit = widget.areaId?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      if (areas.any((a) => a.id == explicit)) return explicit;
      return explicit;
    }

    if (areas.isEmpty) return null;

    final zone = widget.zoneFilter?.trim();
    if (zone != null && zone.isNotEmpty) {
      final z = zone.toUpperCase();
      for (final a in areas) {
        if (a.id == zone) return a.id;
        final code = a.areaCode.toUpperCase();
        if (code == z || code.endsWith(z) || code.contains(z)) {
          return a.id;
        }
      }
    }
    final fromLayout = widget.farmLayoutService?.selectedAreaId;
    if (fromLayout != null && fromLayout.isNotEmpty) return fromLayout;
    return areas.first.id;
  }

  AreaRecord? get _activeArea {
    final id = _activeAreaId;
    if (id == null) return null;
    for (final a in _areas) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.rasFlowService;
    final diagram = svc.diagram;
    final area = _activeArea;

    if (widget.areaService.loading && diagram == null) {
      return const _RasFlowShell(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: DashboardColors.cyan),
          ),
        ),
      );
    }

    if (diagram != null && diagram.nodes.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (area != null) ...[
            Row(
              children: [
                Text(
                  widget.compact
                      ? 'RAS — ${area.areaName}'
                      : 'Sơ đồ RAS — ${area.areaName}',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (svc.isLiveActive) _LiveChip(service: svc),
              ],
            ),
            const SizedBox(height: 8),
          ],
          RasFlowSection(
            compact: widget.compact,
            liveNodes: diagram.nodes,
            liveUpdatedAt: svc.lastRefreshedAt,
            liveRefreshing: svc.isRefreshing,
            onRelayCommand: widget.compact || area == null
                ? null
                : (node, cmd) => svc.sendCommand(
                      areaId: area.id,
                      nodeId: node.id,
                      command: cmd,
                    ),
          ),
          if (widget.onOpenRasControl != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onOpenRasControl,
                icon: const Icon(Icons.settings_suggest_outlined, size: 16),
                label: const Text('Xem chi tiết hệ thống RAS'),
              ),
            ),
          ],
        ],
      );
    }

    if (widget.areaService.error != null && diagram == null) {
      return _RasFlowShell(
        child: Column(
          children: [
            Text(
              widget.areaService.error!,
              style: GoogleFonts.notoSans(color: DashboardColors.risk, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa có sơ đồ RAS cho khu này.',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return _RasFlowShell(
      child: Text(
        'Chưa có sơ đồ RAS cho khu này.',
        style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
      ),
    );
  }
}

class _RasFlowShell extends StatelessWidget {
  const _RasFlowShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(padding: const EdgeInsets.all(20), child: child);
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.service});

  final RasFlowService service;

  @override
  Widget build(BuildContext context) {
    final at = service.lastRefreshedAt;
    final time = at != null
        ? '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}:${at.second.toString().padLeft(2, '0')}'
        : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardColors.healthy.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.healthy.withValues(alpha: 0.4)),
      ),
      child: Text(
        'TRỰC TIẾP · $time',
        style: GoogleFonts.notoSans(
          color: DashboardColors.healthy,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
