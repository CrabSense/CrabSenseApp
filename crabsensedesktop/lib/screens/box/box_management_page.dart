import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/box_list_item.dart';
import '../../models/camera_device.dart';
import '../../models/crab_individual.dart';
import '../../models/iot_device.dart';
import '../../navigation/app_route.dart';
import '../../services/box_management_service.dart';
import '../../services/camera_device_service.dart';
import '../../services/crab_service.dart';
import '../../services/iot_device_service.dart';
import '../../services/production_management_service.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/box/management/box_mgmt_widgets.dart';
import '../../widgets/crab/add/add_crab_modal.dart';
import '../../widgets/crab/transfer/transfer_crab_modal.dart';
import '../../widgets/production/production_dialogs.dart';
import '../../widgets/shared/mgmt_ui.dart';

enum _ViewMode { grid, list }

class BoxManagementPage extends StatefulWidget {
  const BoxManagementPage({
    super.key,
    required this.service,
    required this.productionService,
    this.rowService,
    this.crabService,
    this.cameraService,
    this.iotService,
    this.onNavigate,
    this.onBoxTap,
  });

  final BoxManagementService service;
  final ProductionManagementService productionService;
  final RowManagementService? rowService;
  final CrabService? crabService;
  final CameraDeviceService? cameraService;
  final IoTDeviceService? iotService;
  final void Function(AppRoute route)? onNavigate;
  final void Function(BoxListItem item, {int tab})? onBoxTap;

  @override
  State<BoxManagementPage> createState() => _BoxManagementPageState();
}

class _BoxManagementPageState extends State<BoxManagementPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  _ViewMode _view = _ViewMode.grid;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.cameraService?.addListener(_onDevices);
    widget.iotService?.addListener(_onDevices);
    _searchCtrl.text = widget.service.search;
    if (!widget.service.loading && widget.service.items.isEmpty) {
      widget.service.load().then((_) {
        if (mounted) _syncDevices();
      });
    } else {
      _syncDevices();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    widget.cameraService?.removeListener(_onDevices);
    widget.iotService?.removeListener(_onDevices);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  void _onDevices() => _syncDevices();

  void _syncDevices() {
    final cams = widget.cameraService?.cameras ?? const <CameraDevice>[];
    final iots = widget.iotService?.devices ?? const <IoTDevice>[];
    if (cams.isEmpty && iots.isEmpty) return;
    final next = widget.service.items.map((item) {
      final boxCams = cams.where((c) => c.boxId == item.box.id || c.boxCode == item.box.boxCode).toList();
      final boxIots = iots.where((d) => d.boxId == item.box.id || d.boxCode == item.box.boxCode).toList();
      final total = boxCams.length + boxIots.length;
      if (total == 0) return item;
      final online = boxCams.where((c) => c.isOnline).length + boxIots.where((d) => d.status.toLowerCase() == 'online').length;
      return item.withDevices(
        online: online,
        total: total,
        cameraOnline: boxCams.isEmpty ? null : boxCams.any((c) => c.isOnline),
      );
    }).toList();
    widget.service.attachDevices(next);
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.service.setSearch(v);
    });
  }

  Future<void> _onAddBox() async {
    final svc = widget.service;
    if (svc.areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có khu — thêm khu trước')));
      return;
    }
    await showBoxFormDialog(
      context,
      widget.productionService,
      boxService: svc,
      rowService: widget.rowService,
      onNavigate: widget.onNavigate,
    );
    if (!mounted) return;
    await svc.load();
    _syncDevices();
  }

  void _open(BoxListItem item, {int tab = 0}) => widget.onBoxTap?.call(item, tab: tab);

  CrabIndividual? _crabOf(BoxListItem item) {
    final id = item.box.crabId;
    if (id == null || id.isEmpty) return null;
    return widget.crabService?.getById(id);
  }

  Future<void> _addCrab(BoxListItem item) async {
    final crabSvc = widget.crabService;
    if (crabSvc == null) {
      _open(item);
      return;
    }
    if (!item.canAddCrab) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.box.boxCode} không còn trống.')),
      );
      return;
    }
    final ok = await showAddCrabModal(
      context,
      crabSvc,
      initialAreaId: item.areaId,
      initialRowId: item.rowId,
      initialBoxId: item.box.id,
      onManageLots: () {
        Navigator.of(context).maybePop();
        widget.onNavigate?.call(AppRoute.inboundLots);
      },
    );
    if (ok && mounted) {
      await widget.service.load();
      _syncDevices();
    }
  }

  Future<void> _edit(BoxListItem item) async {
    widget.productionService.selectArea(item.areaId);
    widget.productionService.selectRow(item.rowId);
    await showBoxFormDialog(context, widget.productionService, existing: item.box);
    if (mounted) {
      await widget.service.load();
      _syncDevices();
    }
  }

  Future<void> _qr(BoxListItem item, {required bool print}) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item.box.boxCode, style: bvText(fontSize: 18, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 120, color: DashboardColors.brand),
            const SizedBox(height: 8),
            Text('QR-${item.box.boxCode}', style: bvText(fontWeight: FontWeight.w700)),
            if (print) Text('In mã hộp từ hộp thoại này.', style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: item.box.boxCode));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sao chép mã'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> _setStatus(BoxListItem item, String status) async {
    try {
      await widget.productionService.updateBox(
        item.box,
        boxCode: item.box.boxCode,
        position: item.box.position,
        volume: item.box.volume,
        status: status,
      );
      if (!mounted) return;
      await widget.service.load();
      _syncDevices();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _transfer(BoxListItem item) async {
    final crabSvc = widget.crabService;
    final id = item.box.crabId;
    if (crabSvc == null || id == null || id.isEmpty) {
      _open(item);
      return;
    }
    var crab = crabSvc.getById(id);
    if (crab == null) {
      await crabSvc.load();
      crab = crabSvc.getById(id);
    }
    if (crab == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được thông tin cua để chuyển hộp.')));
      }
      return;
    }
    final ok = await showTransferCrabModal(context, crabSvc, crab: crab);
    if (ok && mounted) {
      await widget.service.load();
      _syncDevices();
    }
  }

  Future<void> _delete(BoxListItem item) async {
    final hadHistory = item.box.crabInBoxSince != null || item.box.emptySince != null || item.hasAlert || item.hasCrab;
    if (hadHistory) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Lưu trữ hộp?', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
          content: Text(
            '${item.box.boxCode} đã có lịch sử. Ưu tiên chuyển sang bảo trì thay vì xóa vật lý.',
            style: bvText(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đánh dấu bảo trì')),
          ],
        ),
      );
      if (ok == true) await _setStatus(item, 'maintenance');
      return;
    }
    if (!await confirmDelete(context, title: 'Gỡ hộp?', message: '${item.displayName} (${item.box.boxCode})?')) {
      return;
    }
    try {
      await widget.service.deleteBox(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gỡ hộp.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _onAction(BoxListItem item, BoxCardAction action) async {
    switch (action) {
      case BoxCardAction.detail:
        _open(item);
      case BoxCardAction.edit:
        await _edit(item);
      case BoxCardAction.qr:
        await _qr(item, print: false);
      case BoxCardAction.print:
        await _qr(item, print: true);
      case BoxCardAction.lock:
        await _setStatus(item, 'maintenance');
      case BoxCardAction.unlock:
        await _setStatus(item, item.hasCrab ? 'active' : 'empty');
      case BoxCardAction.maintenance:
        await _setStatus(item, 'maintenance');
      case BoxCardAction.transfer:
        await _transfer(item);
      case BoxCardAction.addCrab:
        await _addCrab(item);
      case BoxCardAction.delete:
        await _delete(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final filtered = svc.filteredItems;
    final pageSize = svc.pageSize;
    final totalPages = svc.totalPages;
    final page = svc.page.clamp(0, totalPages - 1);
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    final paged = svc.pagedItems;
    final kpi = svc.kpi;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Breadcrumb(onNavigate: widget.onNavigate),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DashboardColors.lightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.inventory_2_outlined, color: DashboardColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quản lý Hộp', style: bvText(fontSize: 26, fontWeight: FontWeight.w800)),
                    Text(
                      'Theo dõi tình trạng hộp nuôi, cua hiện tại và cảnh báo theo từng dãy.',
                      style: bvText(fontSize: 13, color: DashboardColors.textMuted),
                    ),
                  ],
                ),
              ),
              MgmtPrimaryButton(icon: Icons.add_rounded, label: 'Thêm hộp', onTap: svc.loading ? null : _onAddBox),
            ],
          ),
          const SizedBox(height: 16),
          BoxSummaryCards(
            kpi: kpi,
            loading: svc.loading,
            statusFilter: svc.statusFilter,
            healthFilter: svc.healthFilter,
            alertOnly: svc.alertOnly,
            onSelect: ({status, health, alerts = false}) {
              if (status == null && health == null && !alerts) {
                svc.applyKpi(null);
                return;
              }
              svc.applyKpi(status, health: health, alerts: alerts);
            },
          ),
          const SizedBox(height: 16),
          BoxFilterToolbar(
            search: _searchCtrl,
            areas: svc.areas,
            rows: svc.rowsForFilter,
            areaFilterId: svc.areaFilterId,
            rowFilterId: svc.rowFilterId,
            statusFilter: svc.statusFilter,
            healthFilter: svc.healthFilter,
            onSearch: _onSearch,
            onArea: svc.setAreaFilter,
            onRow: svc.setRowFilter,
            onStatus: svc.setStatusFilter,
            onHealth: svc.setHealthFilter,
            onClear: () {
              _searchCtrl.clear();
              svc.clearFilters();
            },
            onAdd: _onAddBox,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Danh sách hộp (${filtered.length})', style: bvText(fontSize: 15.5, fontWeight: FontWeight.w800)),
              if (svc.loading) ...[
                const SizedBox(width: 10),
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
              const Spacer(),
              MgmtInlineSort<BoxListSort>(
                value: svc.sort,
                items: [for (final s in BoxListSort.values) (s, boxListSortLabel(s))],
                onChanged: svc.setSort,
              ),
              const SizedBox(width: 12),
              MgmtIconToggle(
                icon: Icons.grid_view_rounded,
                active: _view == _ViewMode.grid,
                tooltip: 'Card',
                onTap: () => setState(() => _view = _ViewMode.grid),
              ),
              const SizedBox(width: 6),
              MgmtIconToggle(
                icon: Icons.view_list_rounded,
                active: _view == _ViewMode.list,
                tooltip: 'Danh sách',
                onTap: () => setState(() => _view = _ViewMode.list),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (svc.loading && svc.items.isEmpty)
            const BoxCardSkeletonGrid()
          else if (svc.error != null && svc.items.isEmpty)
            MgmtEmptyState(
              icon: Icons.warning_amber_rounded,
              title: 'Không thể tải danh sách hộp.',
              message: svc.error!,
              action: MgmtPrimaryButton(icon: Icons.refresh_rounded, label: 'Thử lại', onTap: () async {
                await svc.load();
                _syncDevices();
              }),
            )
          else if (paged.isEmpty && svc.items.isEmpty)
            MgmtEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Chưa có hộp nuôi',
              message: 'Hãy thêm hộp đầu tiên để bắt đầu quản lý cua.',
              action: MgmtPrimaryButton(icon: Icons.add_rounded, label: 'Thêm hộp', onTap: _onAddBox),
            )
          else if (paged.isEmpty)
            MgmtEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Không tìm thấy hộp',
              message: 'Không có hộp phù hợp với bộ lọc hiện tại.',
              action: MgmtOutlineButton(
                label: 'Xóa bộ lọc',
                onTap: () {
                  _searchCtrl.clear();
                  svc.clearFilters();
                },
              ),
            )
          else if (_view == _ViewMode.grid)
            BoxMgmtGrid(
              items: paged,
              crabOf: _crabOf,
              onOpen: _open,
              onAction: _onAction,
              onAlerts: (i) => _open(i, tab: 4),
              onAddCrab: _addCrab,
            )
          else
            BoxListTable(
              items: paged,
              crabOf: _crabOf,
              onOpen: _open,
              onAction: _onAction,
              onAlerts: (i) => _open(i, tab: 4),
              onAddCrab: _addCrab,
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MgmtPagination(
                  page: page,
                  totalPages: totalPages,
                  start: filtered.isEmpty ? 0 : start + 1,
                  end: end,
                  total: filtered.length,
                  onPage: svc.setPage,
                  itemLabel: 'hộp',
                ),
              ),
              const SizedBox(width: 12),
              MgmtDropdown<int>(
                width: 128,
                valueLabel: '$pageSize / trang',
                items: const [(12, '12 / trang'), (24, '24 / trang'), (48, '48 / trang')],
                onSelected: svc.setPageSize,
              ),
            ],
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
    final link = bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.brand);
    final muted = bvText(fontSize: 12.5, color: DashboardColors.textMuted);
    Widget crumb(String label, AppRoute? route) {
      if (route == null) {
        return Text(label, style: muted.copyWith(color: DashboardColors.textPrimary, fontWeight: FontWeight.w700));
      }
      return InkWell(onTap: () => onNavigate?.call(route), child: Text(label, style: link));
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        crumb('Quản lý khu', AppRoute.farmManagement),
        Text('  >  ', style: muted),
        crumb('Quản lý dãy', AppRoute.rowManagement),
        Text('  >  ', style: muted),
        crumb('Quản lý hộp', null),
      ],
    );
  }
}
