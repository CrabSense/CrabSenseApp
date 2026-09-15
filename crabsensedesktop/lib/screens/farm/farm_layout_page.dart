import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_list_item.dart';
import '../../models/box_status.dart';
import '../../models/farm_layout.dart';
import '../../models/production_models.dart';
import '../../services/area_management_service.dart';
import '../../services/farm_layout_service.dart';
import '../../services/iot_device_service.dart';
import '../../services/ras_flow_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/farm/box_detail_drawer.dart';
import '../../widgets/farm/farm_devices_tab.dart';
import '../../widgets/farm/farm_kpi_strip.dart';
import '../../widgets/farm/farm_layout_ras_flow.dart';
import '../../widgets/farm/crab_box_card.dart';
import '../../widgets/farm/farm_map_box_tile.dart';
import '../../widgets/shared/ai_assistant_avatar.dart';

class FarmLayoutPage extends StatefulWidget {
  const FarmLayoutPage({
    super.key,
    required this.farmLayoutService,
    required this.rasFlowService,
    required this.areaService,
    required this.deviceService,
      this.farmName,
      this.onOpenRas,
      this.onOpenBox,
      this.onExportMolting,
    });

    final FarmLayoutService farmLayoutService;
    final RasFlowService rasFlowService;
    final AreaManagementService areaService;
    final IoTDeviceService deviceService;
    final String? farmName;
    final VoidCallback? onOpenRas;
    final ValueChanged<BoxListItem>? onOpenBox;

    /// Xuất bán cua đang lột ở hộp này (hướng còn lại là để lại nuôi tiếp).
    final ValueChanged<FarmMapBox>? onExportMolting;

  @override
  State<FarmLayoutPage> createState() => _FarmLayoutPageState();
}

class _FarmLayoutPageState extends State<FarmLayoutPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  BoxStatus? _statusFilter;
  String? _rowId;
  String _search = '';

  static const _statusOptions = <BoxStatus?>[
    null,
    BoxStatus.normal,
    BoxStatus.watch,
    BoxStatus.molting,
    BoxStatus.alert,
    BoxStatus.empty,
    BoxStatus.deceased,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.farmLayoutService.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.farmLayoutService.load(force: true);
    });
  }

  @override
  void dispose() {
    widget.farmLayoutService.removeListener(_onUpdate);
    widget.rasFlowService.stopLiveRefresh(notify: false);
    super.dispose();
    _tabController.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  List<FarmMapBox> get _filtered {
    return widget.farmLayoutService.boxes.where((item) {
      if (_statusFilter != null && item.display.status != _statusFilter) {
        return false;
      }
      if (_rowId != null && item.rowId != _rowId) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final hit = item.display.id.toLowerCase().contains(q) ||
            item.areaName.toLowerCase().contains(q) ||
            item.areaCode.toLowerCase().contains(q) ||
            item.rowName.toLowerCase().contains(q) ||
            item.rowCode.toLowerCase().contains(q) ||
            (item.display.crabId?.toLowerCase().contains(q) ?? false);
        if (!hit) return false;
      }
      return true;
    }).toList();
  }

  String? get _highlightBoxId {
    for (final item in widget.farmLayoutService.boxes) {
      if (item.display.status == BoxStatus.alert) return item.display.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.farmLayoutService;
    final filtered = _filtered;
    final mascotMsg = svc.mascotMessage();

    return Column(
      children: [
        _PageTabs(tabController: _tabController),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MapTab(
                loading: svc.loading,
                error: svc.error,
                onRetry: () => svc.load(force: true),
                summary: svc.summary,
                filtered: filtered,
                statusFilter: _statusFilter,
                rowId: _rowId,
                search: _search,
                mascotMessage: mascotMsg,
                highlightBoxId: _highlightBoxId,
                farmName: widget.farmName,
                farmLayoutService: widget.farmLayoutService,
                rasFlowService: widget.rasFlowService,
                areaService: widget.areaService,
                statusOptions: _statusOptions,
                onStatusFilter: (s) => setState(() => _statusFilter = s),
                onRowFilter: (id) => setState(() => _rowId = id),
                onSearch: (q) => setState(() => _search = q),
                onAreaFilter: (id) {
                  setState(() => _rowId = null);
                  svc.selectArea(id);
                },
                onOpenRas: widget.onOpenRas,
                onBoxTap: (item) => showBoxDetailDrawer(
                  context,
                  item,
                  onViewDetail: widget.onOpenBox,
                  onExportMolting: widget.onExportMolting == null
                      ? null
                      : () => widget.onExportMolting!(item),
                ),
              ),
              FarmDevicesTab(
                deviceService: widget.deviceService,
                areaService: widget.areaService,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageTabs extends StatelessWidget {
  const _PageTabs({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DashboardColors.cardBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: DashboardColors.cyan,
        labelColor: DashboardColors.cyan,
        unselectedLabelColor: DashboardColors.textMuted,
        labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Bản đồ'),
          Tab(text: 'Thiết bị'),
        ],
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.summary,
    required this.filtered,
    required this.statusFilter,
    required this.rowId,
    required this.search,
    required this.mascotMessage,
    required this.highlightBoxId,
    required this.farmLayoutService,
    required this.rasFlowService,
    required this.areaService,
    required this.statusOptions,
    required this.onStatusFilter,
    required this.onRowFilter,
    required this.onSearch,
    required this.onAreaFilter,
    required this.onBoxTap,
    this.farmName,
    this.onOpenRas,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final FarmLayoutSummary summary;
  final List<FarmMapBox> filtered;
  final BoxStatus? statusFilter;
  final String? rowId;
  final String search;
  final String mascotMessage;
  final String? highlightBoxId;
  final String? farmName;
  final FarmLayoutService farmLayoutService;
  final RasFlowService rasFlowService;
  final AreaManagementService areaService;
  final List<BoxStatus?> statusOptions;
  final ValueChanged<BoxStatus?> onStatusFilter;
  final ValueChanged<String?> onRowFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onAreaFilter;
  final ValueChanged<FarmMapBox> onBoxTap;
  final VoidCallback? onOpenRas;

  @override
  Widget build(BuildContext context) {
    final areaGroups = _groupByArea(filtered);
    final healthy = summary.alert == 0 && summary.deceased == 0;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                farmName: farmName,
                area: farmLayoutService.selectedArea,
                areaLabel: farmLayoutService.selectedArea == null
                    ? null
                    : farmLayoutService
                        .areaChipLabel(farmLayoutService.selectedArea!),
                healthy: healthy,
                loading: loading,
                onRetry: onRetry,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.risk,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FarmKpiStrip(summary: summary),
              const SizedBox(height: 16),
              _FilterBar(
                farmLayoutService: farmLayoutService,
                statusFilter: statusFilter,
                rowId: rowId,
                search: search,
                statusOptions: statusOptions,
                onStatusFilter: onStatusFilter,
                onRowFilter: onRowFilter,
                onSearch: onSearch,
                onAreaFilter: onAreaFilter,
              ),
              const SizedBox(height: 20),
              if (!loading && farmLayoutService.areas.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Chưa có khu / hộp trên trại. Thêm khu trong Quản lý khu.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                      ),
                    ),
                  ),
                )
              else if (!loading && filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Không tìm thấy hộp phù hợp',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                for (final group in areaGroups)
                  _AreaMapCard(
                    group: group,
                    highlightBoxId: highlightBoxId,
                    onBoxTap: onBoxTap,
                  ),
              const SizedBox(height: 20),
              FarmLayoutRasFlow(
                compact: true,
                rasFlowService: rasFlowService,
                areaService: areaService,
                farmLayoutService: farmLayoutService,
                areaId: farmLayoutService.selectedAreaId,
                onOpenRasControl: onOpenRas,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: _MascotBanner(message: mascotMessage),
        ),
      ],
    );
  }

  List<_AreaGroup> _groupByArea(List<FarmMapBox> items) {
    final byArea = <String, List<FarmMapBox>>{};
    for (final item in items) {
      byArea.putIfAbsent(item.areaId, () => []).add(item);
    }
    final groups = <_AreaGroup>[];
    for (final area in farmLayoutService.areas) {
      final boxes = byArea[area.id];
      if (boxes == null || boxes.isEmpty) continue;
      groups.add(_AreaGroup(
        title: farmLayoutService.areaChipLabel(area),
        rows: _groupByRow(boxes),
      ));
    }
    for (final entry in byArea.entries) {
      if (groups.any((g) => g.rows.any((r) => r.items.first.areaId == entry.key))) {
        continue;
      }
      if (farmLayoutService.areas.any((a) => a.id == entry.key)) continue;
      groups.add(_AreaGroup(
        title: entry.value.first.areaLabel,
        rows: _groupByRow(entry.value),
      ));
    }
    return groups;
  }

  List<_RowGroup> _groupByRow(List<FarmMapBox> items) {
    final byRow = <String, List<FarmMapBox>>{};
    for (final item in items) {
      byRow.putIfAbsent(item.rowId.isEmpty ? item.rowCode : item.rowId, () => [])
          .add(item);
    }
    final rows = byRow.values.map((list) {
      list.sort((a, b) => a.display.id.compareTo(b.display.id));
      return _RowGroup(title: list.first.rowLabel, items: list);
    }).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    return rows;
  }
}

class _AreaGroup {
  const _AreaGroup({required this.title, required this.rows});
  final String title;
  final List<_RowGroup> rows;
}

class _RowGroup {
  const _RowGroup({required this.title, required this.items});
  final String title;
  final List<FarmMapBox> items;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.healthy,
    required this.loading,
    required this.onRetry,
    this.farmName,
    this.area,
    this.areaLabel,
  });

  final String? farmName;
  final AreaRecord? area;
  final String? areaLabel;
  final bool healthy;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final title = farmName?.trim().isNotEmpty == true
        ? farmName!
        : (areaLabel ?? 'Bản đồ trại nuôi');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bản đồ trại nuôi',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: healthy
                        ? DashboardColors.healthy
                        : DashboardColors.risk,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    healthy
                        ? 'Hệ thống hoạt động bình thường'
                        : 'Có hộp cần xử lý',
                    style: GoogleFonts.notoSans(
                      color: healthy
                          ? DashboardColors.healthy
                          : DashboardColors.risk,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (area != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      '· ${area!.areaCode}',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (loading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DashboardColors.cyan,
            ),
          )
        else
          IconButton(
            tooltip: 'Làm mới',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: DashboardColors.cyan),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.farmLayoutService,
    required this.statusFilter,
    required this.rowId,
    required this.search,
    required this.statusOptions,
    required this.onStatusFilter,
    required this.onRowFilter,
    required this.onSearch,
    required this.onAreaFilter,
  });

  final FarmLayoutService farmLayoutService;
  final BoxStatus? statusFilter;
  final String? rowId;
  final String search;
  final List<BoxStatus?> statusOptions;
  final ValueChanged<BoxStatus?> onStatusFilter;
  final ValueChanged<String?> onRowFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onAreaFilter;

  @override
  Widget build(BuildContext context) {
    final rows = farmLayoutService.rowsForArea(farmLayoutService.selectedAreaId);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TÌM KIẾM & LỌC',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: onSearch,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm hộp, mã cua…',
              hintStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: DashboardColors.darkNavy,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Menu<String?>(
                label: 'Khu',
                valueLabel: farmLayoutService.selectedArea == null
                    ? 'Tất cả'
                    : farmLayoutService
                        .areaChipLabel(farmLayoutService.selectedArea!),
                items: [
                  const (null, 'Tất cả'),
                  for (final a in farmLayoutService.areas)
                    (a.id, farmLayoutService.areaChipLabel(a)),
                ],
                onSelected: onAreaFilter,
              ),
              _Menu<String?>(
                label: 'Dãy',
                valueLabel: rowId == null
                    ? 'Tất cả'
                    : rows
                        .where((r) => r.id == rowId)
                        .map((r) => r.rowName.trim().isEmpty ? r.rowCode : r.rowName)
                        .firstOrNull ??
                        'Tất cả',
                items: [
                  const (null, 'Tất cả'),
                  for (final r in rows)
                    (r.id, r.rowName.trim().isEmpty ? r.rowCode : r.rowName),
                ],
                onSelected: onRowFilter,
              ),
              _Menu<BoxStatus?>(
                label: 'Trạng thái',
                valueLabel: statusFilter?.label ?? 'Tất cả',
                items: [
                  for (final s in statusOptions)
                    (s, s?.label ?? 'Tất cả'),
                ],
                onSelected: onStatusFilter,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Menu<T> extends StatelessWidget {
  const _Menu({
    required this.label,
    required this.valueLabel,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final String valueLabel;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      color: DashboardColors.card,
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem(
            value: item.$1,
            child: Text(
              item.$2,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DashboardColors.darkNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
            Text(
              valueLabel,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: DashboardColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _AreaMapCard extends StatelessWidget {
  const _AreaMapCard({
    required this.group,
    required this.highlightBoxId,
    required this.onBoxTap,
  });

  final _AreaGroup group;
  final String? highlightBoxId;
  final ValueChanged<FarmMapBox> onBoxTap;

  @override
  Widget build(BuildContext context) {
    final total = group.rows.fold<int>(0, (n, r) => n + r.items.length);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: DashboardColors.cyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    group.title,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$total hộp',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final row in group.rows) ...[
              Text(
                'Dãy ${row.title}',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in row.items)
                    item.crabCount > 0 || item.display.isOccupied
                        ? SizedBox(
                            width: 92,
                            height: 80,
                            child: CrabBoxCard(
                              box: item.display,
                              highlighted: highlightBoxId != null &&
                                  item.display.id == highlightBoxId,
                              onTap: () => onBoxTap(item),
                            ),
                          )
                        : FarmMapBoxTile(
                            item: item,
                            highlighted: highlightBoxId != null &&
                                item.display.id == highlightBoxId,
                            onTap: () => onBoxTap(item),
                          ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _MascotBanner extends StatelessWidget {
  const _MascotBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardColors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.purple.withValues(alpha: 0.4)),
        boxShadow: [DashboardColors.glowShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiAssistantAvatar(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý Cua',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
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
    );
  }
}
