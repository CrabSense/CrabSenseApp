import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/camera_device.dart';
import '../../models/production_models.dart';
import '../../models/row_list_item.dart';
import '../../navigation/app_route.dart';
import '../../services/area_environment_service.dart';
import '../../services/area_management_service.dart';
import '../../services/cloud_api_client.dart';
import '../../services/production_management_service.dart';
import '../../services/ras_flow_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_form_dialog.dart';
import '../../widgets/box/box_form_dialog.dart';
import '../../widgets/camera/camera_stream_player.dart';
import '../../widgets/production/production_dialogs.dart' show confirmDelete;
import '../../widgets/row/row_cards.dart' show showRowDetailDialog;
import '../../widgets/shared/mgmt_ui.dart';
import 'area_boxes_tab.dart';
import 'area_cameras_tab.dart';
import 'area_environment_tab.dart';
import 'area_history_tab.dart';

const _kCamFallback = 'assets/images/maps.png';

enum _Tab { rows, boxes, environment, cameras, history }

extension on _Tab {
  String get label => switch (this) {
        _Tab.rows => 'Danh sách dãy',
        _Tab.boxes => 'Danh sách hộp',
        _Tab.environment => 'Thông số môi trường',
        _Tab.cameras => 'Camera giám sát',
        _Tab.history => 'Lịch sử & nhật ký',
      };
}

/// Chi tiết một khu nuôi: header khu, 7 KPI, tab (dãy / hộp / môi trường /
/// camera / lịch sử), sơ đồ nhiệt + camera AI. Dữ liệu thật từ CrabSenseBE.
class AreaDetailPage extends StatefulWidget {
  const AreaDetailPage({
    super.key,
    required this.service,
    required this.areaEnvironmentService,
    required this.rasFlowService,
    required this.areaId,
    required this.onBack,
    this.productionService,
    this.onNavigate,
    this.onViewBoxesOfRow,
    this.onOpenBox,
    this.onOpenCrab,
  });

  final AreaManagementService service;
  final AreaEnvironmentService areaEnvironmentService;
  final RasFlowService rasFlowService;
  final String areaId;
  final VoidCallback onBack;

  /// Dùng cho dialog thêm / sửa hộp và xoá hộp (tab Danh sách hộp).
  final ProductionManagementService? productionService;
  final void Function(AppRoute route)? onNavigate;

  /// Dãy → Quản lý hộp (lọc theo dãy).
  final void Function(RowRecord row)? onViewBoxesOfRow;

  /// Mở chi tiết một hộp.
  final void Function(BoxRecord box)? onOpenBox;

  /// Mở chi tiết cua đang ở trong hộp.
  final void Function(BoxRecord box)? onOpenCrab;

  @override
  State<AreaDetailPage> createState() => _AreaDetailPageState();
}

class _AreaDetailPageState extends State<AreaDetailPage> {
  final _api = CloudApiClient();
  final _rowSearch = TextEditingController();

  _Tab _tab = _Tab.rows;
  AreaRecord? _detail;
  List<RowRecord> _rows = [];
  List<BoxRecord> _boxes = [];
  bool _loading = true;
  String? _error;

  // Sơ đồ nhiệt / camera / lịch sử (tải nền, không chặn trang).
  List<Map<String, dynamic>> _live = const [];
  List<CameraDevice> _cameras = const [];
  int _camIndex = 0;
  Timer? _liveTimer;
  String _heatMetric = 'temp';

  String get _token => widget.service.token;

  @override
  void initState() {
    super.initState();
    _load();
    _liveTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadLive());
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    widget.rasFlowService.stopLiveRefresh(notify: false);
    _rowSearch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.service.loadAreaDetail(widget.areaId);
      if (!mounted) return;
      setState(() {
        _detail = r.detail;
        _rows = [...r.rows]..sort((a, b) => a.rowCode.compareTo(b.rowCode));
        _boxes = r.boxes;
        _loading = false;
      });
      unawaited(_loadLive());
      unawaited(_loadCameras());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadLive() async {
    try {
      final live = await _api.fetchIotLive(_token, farmingAreaId: widget.areaId);
      if (mounted) setState(() => _live = live);
    } catch (_) {}
  }

  Future<void> _loadCameras() async {
    try {
      final devices =
          await _api.fetchCrabSenseDevices(_token, farmingAreaId: widget.areaId);
      final cams = devices
          .where((d) => (d['deviceType'] ?? d['DeviceType'] ?? '')
              .toString()
              .toLowerCase()
              .contains('cam'))
          .map(CameraDevice.fromJson)
          .toList();
      if (mounted) {
        setState(() {
          _cameras = cams;
          _camIndex = 0;
        });
      }
    } catch (_) {}
  }

  void _setTab(_Tab t) {
    if (_tab == t) return;
    setState(() => _tab = t);
  }

  void _editArea(AreaRecord d) {
    showAreaFormDialog(context, widget.service, existing: d).then((_) {
      if (mounted) _load();
    });
  }

  Future<void> _addRow() async {
    // Dùng flow tạo dãy ở màn Quản lý dãy (đã có dialog + service riêng).
    widget.onNavigate?.call(AppRoute.rowManagement);
  }

  void _openRow(RowRecord r) {
    final d = _detail;
    showRowDetailDialog(
      context,
      item: RowListItem(row: r, areaCode: d?.areaCode ?? ''),
      onEdit: () => widget.onNavigate?.call(AppRoute.rowManagement),
    );
  }

  // ── Hộp (tab Danh sách hộp) ──────────────────────────────────────────────

  Future<void> _addBox(RowRecord? row) async {
    final prod = widget.productionService;
    if (prod == null) return;
    var target = row;
    if (target == null) {
      if (_rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khu chưa có dãy — thêm dãy trước')),
        );
        return;
      }
      target = _rows.length == 1 ? _rows.first : await _pickRow();
      if (target == null || !mounted) return;
    }
    prod.selectArea(widget.areaId);
    prod.selectRow(target.id);
    await showBoxFormDialog(context, prod);
    if (mounted) await _load();
  }

  Future<RowRecord?> _pickRow() {
    return showDialog<RowRecord>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Thêm hộp vào dãy',
            style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          for (final r in _rows)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Text('${r.rowName} · ${r.boxCount} hộp',
                  style: bvText(fontSize: 13.5)),
            ),
        ],
      ),
    );
  }

  Future<void> _editBox(BoxRecord b) async {
    final prod = widget.productionService;
    if (prod == null) return;
    prod.selectArea(widget.areaId);
    prod.selectRow(b.rowId);
    await showBoxFormDialog(context, prod, existing: b);
    if (mounted) await _load();
  }

  Future<bool> _deleteBoxes(List<BoxRecord> boxes) async {
    final prod = widget.productionService;
    if (prod == null || boxes.isEmpty) return false;
    final msg = boxes.length == 1
        ? 'Hộp ${boxes.first.boxCode} sẽ bị xoá khỏi khu.'
        : '${boxes.length} hộp sẽ bị xoá khỏi khu:\n'
            '${boxes.map((b) => b.boxCode).take(8).join(', ')}'
            '${boxes.length > 8 ? '…' : ''}';
    final ok = await confirmDelete(context,
        title: boxes.length == 1 ? 'Xóa hộp?' : 'Xóa ${boxes.length} hộp?',
        message: msg);
    if (!ok || !mounted) return false;
    var failed = 0;
    for (final b in boxes) {
      try {
        await prod.deleteBox(b);
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return true;
    if (failed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xoá được $failed hộp (hộp đang có cua?)')),
      );
    }
    await _load();
    return true;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: bvText(color: DashboardColors.risk)),
            const SizedBox(height: 12),
            MgmtPrimaryButton(label: 'Thử lại', onTap: _load),
          ],
        ),
      );
    }
    final d = _detail;
    if (d == null) {
      return Center(
        child: Text('Không tìm thấy khu',
            style: bvText(color: DashboardColors.textMuted)),
      );
    }

    final total = d.boxCount;
    final occupied = d.occupiedBoxCount > 0
        ? d.occupiedBoxCount
        : _boxes.where((b) => b.hasCrab).length;
    final empty = d.emptyBoxCount > 0 || d.occupiedBoxCount > 0
        ? d.emptyBoxCount
        : (total - occupied).clamp(0, total);
    String pct(int v) => total == 0 ? '0%' : '${(v * 100 / total).round()}%';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Breadcrumb(
            current: d.areaName,
            onDashboard: () => widget.onNavigate?.call(AppRoute.dashboard),
            onAreaList: widget.onBack,
          ),
          const SizedBox(height: 10),
          _Header(area: d, onEdit: () => _editArea(d)),
          const SizedBox(height: 16),

          // 7 KPI
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 1250
                  ? 7
                  : c.maxWidth >= 900
                      ? 4
                      : 2;
              const gap = 12.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              final kpis = [
                _Kpi(Icons.view_week_outlined, 'Tổng dãy', '${d.rowCount}',
                    null, DashboardColors.brand),
                _Kpi(Icons.inventory_2_outlined, 'Tổng hộp', '$total', null,
                    kMgmtBlue),
                _Kpi(Icons.set_meal_outlined, 'Đang nuôi', '$occupied',
                    pct(occupied), kMgmtBlue),
                _Kpi(Icons.crop_square_outlined, 'Hộp trống', '$empty',
                    pct(empty), kMgmtSlate),
                _Kpi(Icons.check_circle_outline_rounded, 'Bình thường',
                    '${d.healthyBoxCount}', pct(d.healthyBoxCount),
                    DashboardColors.brandGreen),
                _Kpi(Icons.visibility_outlined, 'Theo dõi',
                    '${d.watchBoxCount}', pct(d.watchBoxCount), kMgmtAmber),
                _Kpi(Icons.warning_amber_rounded, 'Cảnh báo',
                    '${d.alertBoxCount}', pct(d.alertBoxCount),
                    DashboardColors.risk),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final k in kpis) SizedBox(width: w, child: _KpiSmall(k)),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Tabs
          _TabBar(current: _tab, onChanged: _setTab),
          const SizedBox(height: 14),

          switch (_tab) {
            _Tab.rows => _RowsCard(
                rows: _rows,
                search: _rowSearch,
                onSearch: () => setState(() {}),
                onAdd: _addRow,
                onView: _openRow,
                onViewBoxes: widget.onViewBoxesOfRow,
              ),
            _Tab.boxes => AreaBoxesTab(
                boxes: _boxes,
                rows: _rows,
                onOpenBox: widget.onOpenBox,
                onOpenCrab: widget.onOpenCrab,
                onEditBox: widget.productionService == null ? null : _editBox,
                onDeleteBoxes:
                    widget.productionService == null ? null : _deleteBoxes,
                onAddBox: widget.productionService == null ? null : _addBox,
                onRefresh: _load,
              ),
            _Tab.environment => AreaEnvironmentTab(
                key: ValueKey('env-${widget.areaId}'),
                token: _token,
                areaId: widget.areaId,
                areaName: d.areaName,
                rows: _rows,
                onOpenAlerts: () => widget.onNavigate?.call(AppRoute.alerts),
              ),
            _Tab.cameras => AreaCamerasTab(
                key: ValueKey('cams-${widget.areaId}'),
                token: _token,
                areaId: widget.areaId,
                areaName: d.areaName,
                rows: _rows,
                boxes: _boxes,
                onOpenBox: widget.onOpenBox,
                onOpenCrab: widget.onOpenCrab,
                onOpenAlerts: () => widget.onNavigate?.call(AppRoute.alerts),
                onAddCamera: widget.onNavigate == null
                    ? null
                    : () => widget.onNavigate!(AppRoute.deviceSetup),
              ),
            _Tab.history => AreaHistoryTab(
                key: ValueKey('hist-${widget.areaId}'),
                token: _token,
                areaId: widget.areaId,
                areaName: d.areaName,
                areaCode: d.areaCode,
                rows: _rows,
                boxes: _boxes,
                onOpenBox: widget.onOpenBox,
                onOpenCrab: widget.onOpenCrab,
                onOpenCameras: () => _setTab(_Tab.cameras),
                onOpenRas: () => widget.onNavigate?.call(AppRoute.devices),
              ),
          },
          // Sơ đồ nhiệt + Camera AI chỉ hiện ở tab tổng quan (Danh sách dãy);
          // các tab còn lại cần toàn bộ chiều cao cho bảng / nội dung riêng.
          if (_tab == _Tab.rows) ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final heat = _HeatmapCard(
                areaName: d.areaName,
                rows: _rows,
                live: _live,
                metric: _heatMetric,
                onMetric: (m) => setState(() => _heatMetric = m),
              );
              final cam = _CameraCard(
                areaName: d.areaName,
                cameras: _cameras,
                index: _camIndex,
                onIndex: (i) => setState(() => _camIndex = i),
              );
              if (c.maxWidth < 1000) {
                return Column(
                  children: [
                    SizedBox(height: 300, child: heat),
                    const SizedBox(height: 16),
                    SizedBox(height: 300, child: cam),
                  ],
                );
              }
              return SizedBox(
                height: 292,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 61, child: heat),
                    const SizedBox(width: 16),
                    Expanded(flex: 39, child: cam),
                  ],
                ),
              );
            },
          ),
          ],
        ],
      ),
    );
  }
}

// ── Breadcrumb / header ────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    required this.current,
    this.onDashboard,
    this.onAreaList,
  });

  final String current;
  final VoidCallback? onDashboard;
  final VoidCallback? onAreaList;

  @override
  Widget build(BuildContext context) {
    final link = bvText(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: DashboardColors.brand,
    );
    final muted = bvText(fontSize: 12.5, color: DashboardColors.textMuted);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(onTap: onDashboard, child: Text('Dashboard', style: link)),
        Text('  ›  ', style: muted),
        InkWell(onTap: onAreaList, child: Text('Quản lý khu', style: link)),
        Text('  ›  ', style: muted),
        Text(
          current,
          style: muted.copyWith(
            color: DashboardColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.area, required this.onEdit});

  final AreaRecord area;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (area.status) {
      'maintenance' => 'Bảo trì',
      'disabled' => 'Ngưng sử dụng',
      _ => 'Đang hoạt động',
    };
    final statusColor = switch (area.status) {
      'maintenance' => kMgmtAmber,
      'disabled' => kMgmtSlate,
      _ => DashboardColors.brandGreen,
    };
    final loc = area.location?.trim() ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      area.areaName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  MgmtStatusBadge(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Mã khu: ',
                      style: bvText(
                          fontSize: 12.5, color: DashboardColors.textMuted),
                      children: [
                        TextSpan(
                          text: area.areaCode,
                          style: bvText(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: DashboardColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (loc.isNotEmpty) ...[
                    Container(
                        width: 1, height: 12, color: DashboardColors.cardBorder),
                    Text.rich(
                      TextSpan(
                        text: 'Vị trí: ',
                        style: bvText(
                            fontSize: 12.5, color: DashboardColors.textMuted),
                        children: [
                          TextSpan(
                            text: loc,
                            style: bvText(
                              fontSize: 12.5,
                              color: DashboardColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        MgmtOutlineButton(
          icon: Icons.edit_outlined,
          label: 'Chỉnh sửa khu',
          color: DashboardColors.textPrimary,
          borderColor: DashboardColors.cardBorder,
          height: 40,
          onTap: onEdit,
        ),
      ],
    );
  }
}

// ── KPI nhỏ ────────────────────────────────────────────────────────────────

class _Kpi {
  const _Kpi(this.icon, this.label, this.value, this.pct, this.color);
  final IconData icon;
  final String label;
  final String value;
  final String? pct;
  final Color color;
}

class _KpiSmall extends StatelessWidget {
  const _KpiSmall(this.k);
  final _Kpi k;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: k.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(k.icon, size: 19, color: k.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                ),
                const SizedBox(height: 1),
                Text.rich(
                  TextSpan(
                    text: k.value,
                    style: bvText(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                      height: 1.1,
                    ),
                    children: [
                      if (k.pct != null)
                        TextSpan(
                          text: ' (${k.pct})',
                          style: bvText(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DashboardColors.textPrimary
                                .withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab bar ────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onChanged});

  final _Tab current;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: DashboardColors.cardBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in _Tab.values)
              InkWell(
                onTap: () => onChanged(t),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                  margin: const EdgeInsets.only(right: 26),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: t == current
                            ? DashboardColors.brand
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    t.label,
                    style: bvText(
                      fontSize: 13.5,
                      fontWeight:
                          t == current ? FontWeight.w700 : FontWeight.w500,
                      color: t == current
                          ? DashboardColors.brand
                          : DashboardColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Card khung chung cho tab ───────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: mgmtCardDeco(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: bvText(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Tab: Danh sách dãy ─────────────────────────────────────────────────────

class _RowsCard extends StatelessWidget {
  const _RowsCard({
    required this.rows,
    required this.search,
    required this.onSearch,
    required this.onAdd,
    required this.onView,
    required this.onViewBoxes,
  });

  final List<RowRecord> rows;
  final TextEditingController search;
  final VoidCallback onSearch;
  final VoidCallback onAdd;
  final void Function(RowRecord) onView;
  final void Function(RowRecord)? onViewBoxes;

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();
    final list = q.isEmpty
        ? rows
        : rows
            .where((r) =>
                r.rowCode.toLowerCase().contains(q) ||
                r.rowName.toLowerCase().contains(q))
            .toList();

    return _SectionCard(
      title: 'Danh sách dãy (${rows.length})',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 230,
            height: 40,
            child: MgmtSearchField(
              controller: search,
              onChanged: (_) => onSearch(),
              hint: 'Tìm kiếm dãy...',
            ),
          ),
          const SizedBox(width: 10),
          MgmtPrimaryButton(
            icon: Icons.add_rounded,
            label: 'Thêm dãy',
            height: 40,
            onTap: onAdd,
          ),
        ],
      ),
      child: list.isEmpty
          ? _emptyText('Chưa có dãy trong khu này.')
          : _RowsTable(rows: list, onView: onView, onViewBoxes: onViewBoxes),
    );
  }
}

class _RowsTable extends StatelessWidget {
  const _RowsTable({
    required this.rows,
    required this.onView,
    required this.onViewBoxes,
  });

  final List<RowRecord> rows;
  final void Function(RowRecord) onView;
  final void Function(RowRecord)? onViewBoxes;

  static const _cols = <(String, int, TextAlign)>[
    ('MÃ DÃY', 12, TextAlign.left),
    ('SỐ HỘP', 11, TextAlign.left),
    ('TRẠNG THÁI', 15, TextAlign.left),
    ('HIỆU SUẤT', 20, TextAlign.left),
    ('BÌNH THƯỜNG', 12, TextAlign.center),
    ('THEO DÕI', 10, TextAlign.center),
    ('CẢNH BÁO', 10, TextAlign.center),
    ('THAO TÁC', 10, TextAlign.center),
  ];

  @override
  Widget build(BuildContext context) {
    final head = bvText(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: DashboardColors.textMuted,
      letterSpacing: 0.4,
    );
    return Column(
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: DashboardColors.lightMint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              for (final (label, flex, align) in _cols)
                Expanded(
                  flex: flex,
                  child: Text(label, style: head, textAlign: align),
                ),
            ],
          ),
        ),
        for (final r in rows) _RowLine(row: r, onView: onView, onViewBoxes: onViewBoxes),
      ],
    );
  }
}

class _RowLine extends StatefulWidget {
  const _RowLine({
    required this.row,
    required this.onView,
    required this.onViewBoxes,
  });

  final RowRecord row;
  final void Function(RowRecord) onView;
  final void Function(RowRecord)? onViewBoxes;

  @override
  State<_RowLine> createState() => _RowLineState();
}

class _RowLineState extends State<_RowLine> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final total = r.boxCount;
    final occupied = r.occupiedBoxes;
    final perf = total == 0 ? 0.0 : occupied / total;
    final hasAlert = r.alertBoxCount > 0;
    final stable = !hasAlert && r.watchBoxCount == 0;
    final barColor = hasAlert
        ? kMgmtAmber
        : stable
            ? DashboardColors.brandGreen
            : kMgmtAmber;
    final num = bvText(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: DashboardColors.textPrimary,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _hover
              ? DashboardColors.lightMint.withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(color: DashboardColors.cardBorder, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: _RowsTable._cols[0].$2,
              child: InkWell(
                onTap: () => widget.onView(r),
                child: Text(
                  r.rowName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.brand,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: _RowsTable._cols[1].$2,
              child: Text('$total Hộp',
                  style: bvText(
                      fontSize: 13, color: DashboardColors.textPrimary)),
            ),
            Expanded(
              flex: _RowsTable._cols[2].$2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _HealthBadge(
                  label: hasAlert
                      ? 'Cảnh báo'
                      : stable
                          ? 'Ổn định'
                          : 'Theo dõi',
                  color: hasAlert
                      ? kMgmtAmber
                      : stable
                          ? DashboardColors.brand
                          : kMgmtAmber,
                ),
              ),
            ),
            Expanded(
              flex: _RowsTable._cols[3].$2,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Container(color: DashboardColors.mint),
                            FractionallySizedBox(
                              widthFactor: perf.clamp(0.0, 1.0),
                              child: Container(color: barColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(perf * 100).round()}%',
                      style: bvText(
                          fontSize: 11.5, color: DashboardColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(
              flex: _RowsTable._cols[4].$2,
              child: Text('${r.healthyBoxCount}',
                  textAlign: TextAlign.center,
                  style: num.copyWith(color: DashboardColors.brandGreen)),
            ),
            Expanded(
              flex: _RowsTable._cols[5].$2,
              child: Text('${r.watchBoxCount}',
                  textAlign: TextAlign.center,
                  style: num.copyWith(
                      color: r.watchBoxCount > 0
                          ? kMgmtAmber
                          : DashboardColors.textPrimary)),
            ),
            Expanded(
              flex: _RowsTable._cols[6].$2,
              child: Text('${r.alertBoxCount}',
                  textAlign: TextAlign.center,
                  style: num.copyWith(
                      color: r.alertBoxCount > 0
                          ? DashboardColors.risk
                          : DashboardColors.textPrimary)),
            ),
            Expanded(
              flex: _RowsTable._cols[7].$2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconBtn(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Chi tiết dãy',
                    onTap: () => widget.onView(r),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    tooltip: '',
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    icon: Icon(Icons.more_vert_rounded,
                        size: 18, color: DashboardColors.textMuted),
                    onSelected: (v) {
                      if (v == 'boxes') widget.onViewBoxes?.call(r);
                      if (v == 'detail') widget.onView(r);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'detail',
                        height: 36,
                        child: Text('Chi tiết dãy', style: bvText(fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'boxes',
                        height: 36,
                        child: Text('Xem hộp của dãy →',
                            style: bvText(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final w = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: DashboardColors.brand),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}


// ── Sơ đồ nhiệt ────────────────────────────────────────────────────────────

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({
    required this.areaName,
    required this.rows,
    required this.live,
    required this.metric,
    required this.onMetric,
  });

  final String areaName;
  final List<RowRecord> rows;
  final List<Map<String, dynamic>> live;
  final String metric;
  final ValueChanged<String> onMetric;

  static const _metrics = <(String, String, String, double, double)>[
    // key, label, unit, scaleMin, scaleMax
    ('temp', 'Nhiệt độ (°C)', '°C', 20, 32),
    ('ph', 'pH', '', 6.5, 9),
    ('do', 'Oxy hòa tan (mg/L)', 'mg/L', 3, 9),
    ('salin', 'Độ mặn (‰)', '‰', 5, 35),
  ];

  (String, String, String, double, double) get _m =>
      _metrics.firstWhere((e) => e.$1 == metric, orElse: () => _metrics.first);

  /// Sensor phù hợp metric: theo sensorType.
  bool _matches(Map<String, dynamic> s) {
    final t = (s['sensorType'] ?? s['SensorType'] ?? '').toString().toLowerCase();
    return switch (metric) {
      'temp' => t.contains('temp'),
      'ph' => t == 'ph' || t.contains('ph_'),
      'do' => t == 'do' || t.contains('oxy'),
      'salin' => t.contains('salin'),
      _ => false,
    };
  }

  double? _value(Map<String, dynamic> s) {
    final v = s['latestValue'] ?? s['LatestValue'];
    return v is num ? v.toDouble() : double.tryParse('$v');
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    final sensors = live.where(_matches).toList();
    // Giá trị chung khu (không gắn vị trí) + giá trị theo vị trí (LocationName).
    final byLocation = <String, double>{};
    final general = <double>[];
    for (final s in sensors) {
      final v = _value(s);
      if (v == null) continue;
      final loc = (s['locationName'] ?? s['LocationName'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (loc.isEmpty) {
        general.add(v);
      } else {
        byLocation[loc] = v;
      }
    }
    final areaAvg = general.isEmpty
        ? null
        : general.reduce((a, b) => a + b) / general.length;

    double? tempFor(RowRecord r) {
      final k1 = r.rowName.trim().toLowerCase();
      final k2 = r.rowCode.trim().toLowerCase();
      return byLocation[k1] ?? byLocation[k2] ?? areaAvg;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: mgmtCardDeco(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sơ đồ nhiệt $areaName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 34,
                child: MgmtDropdown<String>(
                  width: 170,
                  valueLabel: m.$2,
                  items: [for (final e in _metrics) (e.$1, e.$2)],
                  onSelected: onMetric,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Nền: ảnh khu nhìn từ trên (ảnh trại thật), làm tối nhẹ.
                        Image.asset(
                          _kCamFallback,
                          fit: BoxFit.cover,
                          alignment: const Alignment(-0.4, -0.5),
                          errorBuilder: (_, __, ___) =>
                              Container(color: DashboardColors.mint),
                        ),
                        Container(color: Colors.black.withValues(alpha: 0.18)),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: rows.isEmpty
                              ? Center(
                                  child: Text('Chưa có dãy để hiển thị',
                                      style: bvText(color: Colors.white)))
                              : _HeatGrid(
                                  rows: rows,
                                  valueFor: tempFor,
                                  unit: m.$3,
                                  min: m.$4,
                                  max: m.$5,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _HeatScale(min: m.$4, max: m.$5, unit: m.$3),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            children: [
              _legend(DashboardColors.brandGreen, _goodLabel(metric)),
              _legend(const Color(0xFFF59E0B), _highLabel(metric)),
              _legend(kMgmtBlue, _lowLabel(metric)),
              if (sensors.isEmpty)
                Text('Chưa có cảm biến ${m.$2.toLowerCase()} cho khu này',
                    style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  static String _goodLabel(String k) => switch (k) {
        'temp' => 'Tốt (24–28°C)',
        'ph' => 'Tốt (7.5–8.5)',
        'do' => 'Tốt (>5 mg/L)',
        _ => 'Tốt (15–25‰)',
      };
  static String _highLabel(String k) => switch (k) {
        'temp' => 'Cao (>28°C)',
        'ph' => 'Cao (>8.5)',
        'do' => 'Cao (>8 mg/L)',
        _ => 'Cao (>25‰)',
      };
  static String _lowLabel(String k) => switch (k) {
        'temp' => 'Thấp (<24°C)',
        'ph' => 'Thấp (<7.5)',
        'do' => 'Thấp (<5 mg/L)',
        _ => 'Thấp (<15‰)',
      };

  Widget _legend(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        ],
      );
}

/// Gradient nhiệt: xanh dương → xanh lá → vàng → cam → đỏ.
Color heatColor(double t) {
  const stops = <(double, Color)>[
    (0.0, Color(0xFF2495E8)),
    (0.35, Color(0xFF12A87A)),
    (0.6, Color(0xFFF5D90A)),
    (0.8, Color(0xFFF59E0B)),
    (1.0, Color(0xFFEF4444)),
  ];
  final x = t.clamp(0.0, 1.0);
  for (var i = 1; i < stops.length; i++) {
    if (x <= stops[i].$1) {
      final (a, ca) = stops[i - 1];
      final (b, cb) = stops[i];
      return Color.lerp(ca, cb, (x - a) / (b - a))!;
    }
  }
  return stops.last.$2;
}

class _HeatGrid extends StatelessWidget {
  const _HeatGrid({
    required this.rows,
    required this.valueFor,
    required this.unit,
    required this.min,
    required this.max,
  });

  final List<RowRecord> rows;
  final double? Function(RowRecord) valueFor;
  final String unit;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = rows.length;
        final cols = n <= 3 ? n : (n <= 6 ? 3 : 4);
        final lines = (n / cols).ceil();
        const gap = 10.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        final h = (c.maxHeight - gap * (lines - 1)) / lines;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final r in rows)
              SizedBox(
                width: w,
                height: h,
                child: _HeatTile(
                  label: r.rowName,
                  value: valueFor(r),
                  unit: unit,
                  min: min,
                  max: max,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeatTile extends StatelessWidget {
  const _HeatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
  });

  final String label;
  final double? value;
  final String unit;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final t = v == null ? null : ((v - min) / (max - min)).clamp(0.0, 1.0);
    final base = t == null ? kMgmtSlate : heatColor(t);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        gradient: RadialGradient(
          center: const Alignment(0.15, -0.1),
          radius: 1.1,
          colors: [
            base.withValues(alpha: 0.92),
            Color.lerp(base, kMgmtBlue, 0.35)!.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 6,
            child: Text(
              label,
              style: bvText(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                v == null ? '—' : '${_fmtNum(v)}$unit',
                style: bvText(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatScale extends StatelessWidget {
  const _HeatScale({required this.min, required this.max, required this.unit});
  final double min;
  final double max;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final labels = [
      for (var i = 0; i <= 3; i++) max - (max - min) * i / 3,
    ];
    return Row(
      children: [
        Container(
          width: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [for (var i = 10; i >= 0; i--) heatColor(i / 10)],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in labels)
              Text(
                '${_fmtNum(l)}$unit',
                style: bvText(fontSize: 10.5, color: DashboardColors.textMuted),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Camera AI card ─────────────────────────────────────────────────────────

class _CameraCard extends StatelessWidget {
  const _CameraCard({
    required this.areaName,
    required this.cameras,
    required this.index,
    required this.onIndex,
  });

  final String areaName;
  final List<CameraDevice> cameras;
  final int index;
  final ValueChanged<int> onIndex;

  @override
  Widget build(BuildContext context) {
    final n = cameras.length;
    final i = n == 0 ? 0 : index.clamp(0, n - 1);
    final cam = n == 0 ? null : cameras[i];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: mgmtCardDeco(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Camera giám sát AI',
                  style: bvText(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DashboardColors.risk,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cam == null || cam.isOnline ? 'LIVE' : 'OFFLINE',
                  style: bvText(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _CameraFrame(
              camera: cam,
              areaName: areaName,
              camLabel: 'CAM-${(i + 1).toString().padLeft(2, '0')}',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconBtn(
                icon: Icons.chevron_left_rounded,
                onTap: n <= 1 ? () {} : () => onIndex((i - 1 + n) % n),
              ),
              const SizedBox(width: 6),
              for (var k = 0; k < (n == 0 ? 1 : n).clamp(1, 8); k++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => onIndex(k),
                    child: Container(
                      width: k == i ? 9 : 7,
                      height: k == i ? 9 : 7,
                      decoration: BoxDecoration(
                        color: k == i
                            ? DashboardColors.brand
                            : DashboardColors.cardBorder,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              _IconBtn(
                icon: Icons.chevron_right_rounded,
                onTap: n <= 1 ? () {} : () => onIndex((i + 1) % n),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Khung camera: stream thật nếu có `streamUrl`, ngược lại ảnh trại + overlay CCTV.
class _CameraFrame extends StatelessWidget {
  const _CameraFrame({
    required this.camera,
    required this.areaName,
    this.camLabel,
  });

  final CameraDevice? camera;
  final String areaName;
  final String? camLabel;

  @override
  Widget build(BuildContext context) {
    final cam = camera;
    final url = cam?.streamUrl?.trim() ?? '';
    final label = camLabel ?? cam?.cameraCode ?? 'CAM-01';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isNotEmpty)
            CameraStreamPlayer(
              key: ValueKey('area-cam-${cam!.id}-$url'),
              streamUrl: url,
              ipAddress: cam.ipAddress,
              snapshotFallbackUrl: cam.ipAddress,
            )
          else ...[
            // Chưa có stream: dùng ảnh khu nuôi thật (nhìn từ trên) làm khung hình.
            Image.asset(
              _kCamFallback,
              fit: BoxFit.cover,
              alignment: const Alignment(0.2, 0.1),
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1F2A2E)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ],
          // Góc trên trái: REC
          Positioned(
            left: 10,
            top: 8,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DashboardColors.risk,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text('REC',
                    style: bvText(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
          // Overlay dưới: tên cam + thời gian
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              color: Colors.black.withValues(alpha: 0.45),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$label: $areaName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _Clock(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Clock extends StatefulWidget {
  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return Text(
      '${two(n.day)}/${two(n.month)}/${n.year} ${two(n.hour)}:${two(n.minute)}:${two(n.second)}',
      style: bvText(fontSize: 11, color: Colors.white.withValues(alpha: 0.9)),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _emptyText(String msg) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(msg,
            textAlign: TextAlign.center,
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
      ),
    );

String _fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}
