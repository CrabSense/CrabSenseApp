import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_list_item.dart';
import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/box_management_service.dart';
import '../../services/production_management_service.dart';
import '../../services/iot_device_service.dart';
import '../../services/camera_device_service.dart';
import '../../services/gateway_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/batch/batch_summary_kpi.dart';
import '../../widgets/box/box_grid_card.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/device/device_list_panel.dart';
import '../../widgets/camera/camera_list_panel.dart';
import '../../data/mock_batch_data.dart';
import '../../widgets/production/production_dialogs.dart';

class BoxManagementPage extends StatefulWidget {
  const BoxManagementPage({
    super.key,
    required this.service,
    required this.productionService,
    required this.deviceService,
    required this.cameraService,
    required this.gatewayService,
    this.onNavigate,
    this.onBoxTap,
  });

  final BoxManagementService service;
  final ProductionManagementService productionService;
  final IoTDeviceService deviceService;
  final CameraDeviceService cameraService;
  final GatewayService gatewayService;
  final void Function(AppRoute route)? onNavigate;
  final void Function(BoxListItem item)? onBoxTap;

  @override
  State<BoxManagementPage> createState() => _BoxManagementPageState();
}

class _BoxManagementPageState extends State<BoxManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  var _gridView = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    widget.service.addListener(_onUpdate);
    _searchCtrl.text = widget.service.search;
    if (!widget.service.loading && widget.service.items.isEmpty) {
      widget.service.load();
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    widget.service.removeListener(_onUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  Future<void> _onAdd() async {
    final svc = widget.service;
    final prod = widget.productionService;
    if (svc.selectedRowId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn dãy trước khi thêm hộp')),
      );
      return;
    }
    prod.selectArea(svc.selectedAreaId);
    prod.selectRow(svc.selectedRowId);
    await showBoxFormDialog(context, prod);
    if (mounted) await svc.load();
  }

  Future<void> _editBox(BoxListItem item) async {
    final prod = widget.productionService;
    prod.selectArea(item.areaId);
    prod.selectRow(item.rowId);
    await showBoxFormDialog(context, prod, existing: item.box);
    if (mounted) await widget.service.load();
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final filtered = svc.filteredItems;
    final stats = svc.rowStats;
    final row = svc.selectedRow;
    AreaRecord? selectedArea;
    if (svc.selectedAreaId != null) {
      for (final a in svc.areas) {
        if (a.id == svc.selectedAreaId) {
          selectedArea = a;
          break;
        }
      }
    }

    final kpis = [
      BatchSummaryKpi(
        label: 'Số hộp nuôi',
        value: '${stats.total}',
        subtext: stats.total > 0 ? '${stats.total} hộp trên dãy' : '—',
        icon: Icons.grid_view_rounded,
        accentColor: DashboardColors.purple,
      ),
      BatchSummaryKpi(
        label: 'Đang nuôi',
        value: '${stats.farming}',
        subtext: 'Live Metrics',
        icon: Icons.water_drop_outlined,
        accentColor: DashboardColors.cyan,
      ),
      BatchSummaryKpi(
        label: 'Hộp trống',
        value: '${stats.empty}',
        subtext: 'Sẵn sàng thả giống',
        icon: Icons.inbox_outlined,
        accentColor: DashboardColors.textMuted,
      ),
      BatchSummaryKpi(
        label: 'Cần chú ý',
        value: '${stats.attention}',
        subtext: 'Kiểm tra ngay',
        icon: Icons.warning_amber_rounded,
        accentColor: DashboardColors.monitoring,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Breadcrumb(onNavigate: widget.onNavigate),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row != null ? row.rowName : 'Quản lý Hộp Nuôi',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      row != null
                          ? '${row.rowCode} — ${stats.total} hộp trên dãy'
                          : 'Theo dõi trạng thái từng hộp nuôi theo dãy.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: svc.loading ? null : _onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm hộp'),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ScopeBar(service: svc, searchController: _searchCtrl),
          const SizedBox(height: 20),
          if (row != null) ...[
            _RowHeader(row: row),
            const SizedBox(height: 16),
          ],
          BatchSummaryKpiRow(items: kpis),
          const SizedBox(height: 20),
          if (svc.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                svc.error!,
                style: GoogleFonts.notoSans(color: DashboardColors.risk),
              ),
            ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabs,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: DashboardColors.cyan,
                        unselectedLabelColor: DashboardColors.textMuted,
                        indicatorColor: DashboardColors.cyan,
                        tabs: const [
                          Tab(text: 'Danh sách hộp'),
                          Tab(text: 'Thiết bị IoT'),
                          Tab(text: 'Camera AI'),
                          Tab(text: 'Cảm biến môi trường'),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Lưới',
                      onPressed: () => setState(() => _gridView = true),
                      icon: Icon(
                        Icons.grid_view,
                        color: _gridView
                            ? DashboardColors.cyan
                            : DashboardColors.textMuted,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Danh sách',
                      onPressed: () => setState(() => _gridView = false),
                      icon: Icon(
                        Icons.view_list,
                        color: !_gridView
                            ? DashboardColors.cyan
                            : DashboardColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 520,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _BoxGridPanel(
                        loading: svc.loading,
                        items: filtered,
                        gridView: _gridView,
                        rowSelected: svc.selectedRowId != null,
                        onTap: (item) {
                          if (widget.onBoxTap != null) {
                            widget.onBoxTap!(item);
                          } else {
                            _editBox(item);
                          }
                        },
                        onDelete: (item) async {
                          if (!await confirmDelete(
                            context,
                            title: 'Xóa hộp?',
                            message: item.box.boxCode,
                          )) {
                            return;
                          }
                          try {
                            await svc.deleteBox(item);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                      ),
                      DeviceListPanel(
                        service: widget.deviceService,
                        boxIds: svc.selectedRowId == null
                            ? null
                            : svc.items
                                .where((i) => i.rowId == svc.selectedRowId)
                                .map((i) => i.box.id)
                                .toList(),
                      ),
                      CameraListPanel(
                        service: widget.cameraService,
                        boxIds: svc.selectedRowId == null
                            ? null
                            : svc.items
                                .where((i) => i.rowId == svc.selectedRowId)
                                .map((i) => i.box.id)
                                .toList(),
                        gatewayId: widget.gatewayService.gatewayId,
                      ),
                      _AreaSensorRedirectTab(
                        areaName: selectedArea?.areaName,
                        onOpenAreaManagement: () =>
                            widget.onNavigate?.call(AppRoute.areaManagement),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Hiển thị ${filtered.length} hộp nuôi',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: svc.loading ? null : svc.load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({this.onNavigate});

  final void Function(AppRoute route)? onNavigate;

  @override
  Widget build(BuildContext context) {
    final link = GoogleFonts.notoSans(
      color: DashboardColors.oceanBlue,
      fontSize: 13,
    );
    final muted = GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 13,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: () => onNavigate?.call(AppRoute.dashboard),
          child: Text('Dashboard', style: link),
        ),
        Text('  >  ', style: muted),
        InkWell(
          onTap: () => onNavigate?.call(AppRoute.areaManagement),
          child: Text('Quản lý Khu', style: link),
        ),
        Text('  >  ', style: muted),
        InkWell(
          onTap: () => onNavigate?.call(AppRoute.rowManagement),
          child: Text('Quản lý Dãy', style: link),
        ),
        Text('  >  ', style: muted),
        Text(
          'Quản lý hộp',
          style: muted.copyWith(color: DashboardColors.textPrimary),
        ),
      ],
    );
  }
}

class _ScopeBar extends StatelessWidget {
  const _ScopeBar({
    required this.service,
    required this.searchController,
  });

  final BoxManagementService service;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final svc = service;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final f in BoxViewFilter.values)
                FilterChip(
                  label: Text(f.label),
                  selected: svc.viewFilter == f,
                  onSelected: svc.loading
                      ? null
                      : (_) => svc.setViewFilter(f),
                  selectedColor:
                      DashboardColors.cyan.withValues(alpha: 0.2),
                  checkmarkColor: DashboardColors.cyan,
                  labelStyle: GoogleFonts.notoSans(
                    color: svc.viewFilter == f
                        ? DashboardColors.cyan
                        : DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 700;
              final areaIds = {for (final a in svc.areas) a.id};
              final areaValue =
                  svc.selectedAreaId != null && areaIds.contains(svc.selectedAreaId)
                      ? svc.selectedAreaId
                      : null;
              final rowIds = {for (final r in svc.rows) r.id};
              final rowValue =
                  svc.selectedRowId != null && rowIds.contains(svc.selectedRowId)
                      ? svc.selectedRowId
                      : null;
              final areaDrop = DropdownButtonFormField<String?>(
                isExpanded: true,
                value: areaValue,
                decoration: _dec('Khu'),
                dropdownColor: DashboardColors.card,
                style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả khu')),
                  ...svc.areas.map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(
                        '${a.areaCode} — ${a.areaName}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
                onChanged: svc.loading ? null : svc.selectArea,
              );
              final rowDrop = DropdownButtonFormField<String?>(
                isExpanded: true,
                value: rowValue,
                decoration: _dec('Dãy'),
                dropdownColor: DashboardColors.card,
                style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Chọn dãy')),
                  ...svc.rows.map(
                    (r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        '${r.rowCode} — ${r.rowName}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
                onChanged: svc.loading || svc.selectedAreaId == null
                    ? null
                    : svc.selectRow,
              );
              final search = TextField(
                controller: searchController,
                onChanged: svc.setSearch,
                decoration: InputDecoration(
                  hintText: 'Tìm mã hộp...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: DashboardColors.darkNavy,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: DashboardColors.cardBorder),
                  ),
                ),
                style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
              );
              if (stacked) {
                return Column(
                  children: [
                    areaDrop,
                    const SizedBox(height: 8),
                    rowDrop,
                    const SizedBox(height: 8),
                    search,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 2, child: areaDrop),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: rowDrop),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: search),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: DashboardColors.darkNavy,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      );
}

class _RowHeader extends StatelessWidget {
  const _RowHeader({required this.row});

  final RowRecord row;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: DashboardColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.view_week_rounded,
              color: DashboardColors.purple,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      row.rowName,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DashboardColors.seaGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        row.rowCode,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.seaGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Dãy nuôi — quản lý lưới hộp theo từng ô',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 13,
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

class _BoxGridPanel extends StatelessWidget {
  const _BoxGridPanel({
    required this.loading,
    required this.items,
    required this.gridView,
    required this.rowSelected,
    required this.onTap,
    required this.onDelete,
  });

  final bool loading;
  final List<BoxListItem> items;
  final bool gridView;
  final bool rowSelected;
  final ValueChanged<BoxListItem> onTap;
  final ValueChanged<BoxListItem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!rowSelected) {
      return Center(
        child: Text(
          'Chọn khu và dãy để xem lưới hộp.',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Không có hộp phù hợp bộ lọc.',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }
    if (!gridView) {
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            tileColor: DashboardColors.darkNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(item.box.boxCode),
            subtitle: Text('${item.rowCode} · ${item.box.status}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => onTap(item),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: DashboardColors.risk),
                  onPressed: () => onDelete(item),
                ),
              ],
            ),
            onTap: () => onTap(item),
          );
        },
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width > 1200
            ? 8
            : MediaQuery.sizeOf(context).width > 900
                ? 6
                : 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => BoxGridCard(
        box: items[i].box,
        onTap: () => onTap(items[i]),
      ),
    );
  }
}

class _AreaSensorRedirectTab extends StatelessWidget {
  const _AreaSensorRedirectTab({
    this.areaName,
    this.onOpenAreaManagement,
  });

  final String? areaName;
  final VoidCallback? onOpenAreaManagement;

  @override
  Widget build(BuildContext context) {
    final khu = areaName ?? 'khu đang chọn';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors, size: 48, color: DashboardColors.cyan),
          const SizedBox(height: 12),
          Text(
            'Cảm biến bể chung — $khu',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Nước các hộp dùng chung một bể khu. Xem và quản lý chỉ số tại '
              'Quản lý khu → chọn khu → tab Cảm biến bể chung.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onOpenAreaManagement,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Mở Quản lý khu'),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: DashboardColors.textMuted),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }
}
