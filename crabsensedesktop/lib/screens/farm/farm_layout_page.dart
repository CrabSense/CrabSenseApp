import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_status.dart';
import '../../models/farm_layout.dart';
import '../../services/area_management_service.dart';
import '../../services/farm_layout_service.dart';
import '../../services/iot_device_service.dart';
import '../../services/ras_flow_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/farm/box_detail_drawer.dart';
import '../../widgets/farm/crab_box_card.dart';
import '../../widgets/farm/farm_kpi_strip.dart';
import '../../widgets/farm/farm_devices_tab.dart';
import '../../widgets/farm/farm_layout_ras_flow.dart';
import '../../widgets/shared/ai_assistant_avatar.dart';

class FarmLayoutPage extends StatefulWidget {
  const FarmLayoutPage({
    super.key,
    required this.farmLayoutService,
    required this.rasFlowService,
    required this.areaService,
    required this.deviceService,
  });

  final FarmLayoutService farmLayoutService;
  final RasFlowService rasFlowService;
  final AreaManagementService areaService;
  final IoTDeviceService deviceService;

  @override
  State<FarmLayoutPage> createState() => _FarmLayoutPageState();
}

class _FarmLayoutPageState extends State<FarmLayoutPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  BoxStatus? _statusFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.farmLayoutService.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Service giữ cache giữa các lần mở màn — luôn làm mới để thấy hộp mới / đổi status.
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
      final b = item.display;
      if (_statusFilter != null && b.status != _statusFilter) return false;
      if (_search.isNotEmpty &&
          !b.id.toLowerCase().contains(_search.toLowerCase()) &&
          !item.areaName.toLowerCase().contains(_search.toLowerCase()) &&
          !item.rowName.toLowerCase().contains(_search.toLowerCase())) {
        return false;
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
                search: _search,
                mascotMessage: mascotMsg,
                highlightBoxId: _highlightBoxId,
                farmLayoutService: widget.farmLayoutService,
                rasFlowService: widget.rasFlowService,
                areaService: widget.areaService,
                onStatusFilter: (s) => setState(() => _statusFilter = s),
                onSearch: (q) => setState(() => _search = q),
                onBoxTap: (item) => showBoxDetailDrawer(context, item),
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
    required this.search,
    required this.mascotMessage,
    required this.highlightBoxId,
    required this.farmLayoutService,
    required this.rasFlowService,
    required this.areaService,
    required this.onStatusFilter,
    required this.onSearch,
    required this.onBoxTap,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final FarmLayoutSummary summary;
  final List<FarmMapBox> filtered;
  final BoxStatus? statusFilter;
  final String search;
  final String mascotMessage;
  final String? highlightBoxId;
  final FarmLayoutService farmLayoutService;
  final RasFlowService rasFlowService;
  final AreaManagementService areaService;
  final ValueChanged<BoxStatus?> onStatusFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<FarmMapBox> onBoxTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                        const SizedBox(height: 8),
                        Text(
                          farmLayoutService.selectedArea == null
                              ? 'Toàn bộ khu — chọn khu trên header hoặc chip bên dưới'
                              : 'Khu ${farmLayoutService.areaChipLabel(farmLayoutService.selectedArea!)} — hộp và sơ đồ RAS',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DashboardColors.cyan,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Làm mới',
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, color: DashboardColors.cyan),
                    ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: GoogleFonts.notoSans(color: DashboardColors.risk, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              FarmKpiStrip(summary: summary),
              const SizedBox(height: 20),
              FarmLayoutRasFlow(
                rasFlowService: rasFlowService,
                areaService: areaService,
                farmLayoutService: farmLayoutService,
                areaId: farmLayoutService.selectedAreaId,
              ),
              const SizedBox(height: 20),
              _FilterBar(
                farmLayoutService: farmLayoutService,
                statusFilter: statusFilter,
                search: search,
                onStatusFilter: onStatusFilter,
                onSearch: onSearch,
              ),
              const SizedBox(height: 20),
              if (!loading && farmLayoutService.areas.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Chưa có khu / hộp trên trại. Thêm khu trong Quản lý khu.',
                      style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                    ),
                  ),
                )
              else
                for (final area in farmLayoutService.areas)
                  if (farmLayoutService.selectedAreaId == null ||
                      area.id == farmLayoutService.selectedAreaId)
                    _ZoneSection(
                      zone: farmLayoutService.areaChipLabel(area),
                      zoneTotal: filtered.where((e) => e.areaId == area.id).length,
                      items: filtered.where((e) => e.areaId == area.id).toList(),
                      highlightBoxId: highlightBoxId,
                      onBoxTap: onBoxTap,
                    ),
              if (!loading && filtered.isEmpty && farmLayoutService.areas.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Không tìm thấy hộp phù hợp',
                      style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                    ),
                  ),
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
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.farmLayoutService,
    required this.statusFilter,
    required this.search,
    required this.onStatusFilter,
    required this.onSearch,
  });

  final FarmLayoutService farmLayoutService;
  final BoxStatus? statusFilter;
  final String search;
  final ValueChanged<BoxStatus?> onStatusFilter;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final selected = farmLayoutService.selectedAreaId;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _zoneChip('Tất cả khu', selected == null, () {
                farmLayoutService.selectArea(null);
              }),
              for (final a in farmLayoutService.areas)
                _zoneChip(
                  farmLayoutService.areaChipLabel(a),
                  selected == a.id,
                  () => farmLayoutService.selectArea(a.id),
                ),
              const SizedBox(width: 8),
              _statusChip('Tất cả', statusFilter == null, () => onStatusFilter(null)),
              for (final s in BoxStatus.values)
                _statusChip(s.label, statusFilter == s, () => onStatusFilter(s)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            height: 40,
            child: TextField(
              onChanged: onSearch,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Tìm mã hộp...',
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
          ),
        ],
      ),
    );
  }

  Widget _zoneChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: DashboardColors.purple.withValues(alpha: 0.25),
      checkmarkColor: DashboardColors.cyan,
      labelStyle: GoogleFonts.notoSans(
        fontSize: 11,
        color: selected ? DashboardColors.cyan : DashboardColors.textMuted,
      ),
      side: BorderSide(
        color: selected ? DashboardColors.cyan : DashboardColors.cardBorder,
      ),
    );
  }

  Widget _statusChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: DashboardColors.blue.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.notoSans(
        fontSize: 11,
        color: selected ? DashboardColors.textPrimary : DashboardColors.textMuted,
      ),
      side: BorderSide(
        color: selected ? DashboardColors.blue : DashboardColors.cardBorder,
      ),
    );
  }
}

class _ZoneSection extends StatelessWidget {
  const _ZoneSection({
    required this.zone,
    required this.zoneTotal,
    required this.items,
    required this.highlightBoxId,
    required this.onBoxTap,
  });

  final String zone;
  final int zoneTotal;
  final List<FarmMapBox> items;
  final String? highlightBoxId;
  final ValueChanged<FarmMapBox> onBoxTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && zoneTotal == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$zone — ${items.length}${zoneTotal > 0 ? ' / $zoneTotal' : ''} hộp',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Không có hộp khớp bộ lọc trong khu này',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const cols = FarmLayoutService.columnsPerRow;
                const spacing = 10.0;
                const itemHeight = 80.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (cols - 1)) / cols;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: items.map((item) {
                    final box = item.display;
                    return SizedBox(
                      width: itemWidth,
                      height: itemHeight,
                      child: CrabBoxCard(
                        box: box,
                        highlighted: highlightBoxId != null && box.id == highlightBoxId,
                        onTap: () => onBoxTap(item),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
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
