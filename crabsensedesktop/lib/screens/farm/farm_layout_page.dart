import 'dart:math' as math;

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
import '../../widgets/farm/farm_map_box_tile.dart';

const _kMapAsset = 'assets/images/maps.png';
const _kSlate = Color(0xFF94A3B8);

TextStyle _bv({
  double fontSize = 13,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) =>
    GoogleFonts.beVietnamPro(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

enum _MapLevel { farm, area, row }

/// Bản đồ trại — Toàn trại → Khu → Dãy → Hộp trên ảnh Maps của trại.
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
    this.onOpenAreaDetail,
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

  /// Mở màn chi tiết khu (Quản lý khu) theo id khu.
  final ValueChanged<String>? onOpenAreaDetail;

  @override
  State<FarmLayoutPage> createState() => _FarmLayoutPageState();
}

class _FarmLayoutPageState extends State<FarmLayoutPage> {
  final _tc = TransformationController();

  _MapLevel _level = _MapLevel.farm;
  String? _rowId;
  BoxStatus? _statusFilter;
  String _search = '';
  bool _showOverlay = true;
  Size _viewport = Size.zero;

  static const _statusOptions = <BoxStatus?>[
    null,
    BoxStatus.normal,
    BoxStatus.watch,
    BoxStatus.alert,
    BoxStatus.empty,
  ];

  /// Slot dự phòng cho khu chưa được đặt khung trên ảnh (BE `mapX1..mapY2`
  /// null): khu đầu tiên neo vào cụm nhà trại, các khu tiếp theo xoay vòng.
  static const _anchors = <Rect>[
    Rect.fromLTRB(0.14, 0.09, 0.43, 0.46),
    Rect.fromLTRB(0.52, 0.12, 0.74, 0.36),
    Rect.fromLTRB(0.18, 0.62, 0.42, 0.88),
    Rect.fromLTRB(0.66, 0.52, 0.90, 0.80),
  ];

  @override
  void initState() {
    super.initState();
    widget.farmLayoutService.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.farmLayoutService.load(force: true);
    });
  }

  @override
  void dispose() {
    widget.farmLayoutService.removeListener(_onUpdate);
    widget.rasFlowService.stopLiveRefresh(notify: false);
    _tc.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  FarmLayoutService get _svc => widget.farmLayoutService;

  AreaRecord? get _selectedArea {
    final s = _svc.selectedArea;
    if (s != null) return s;
    return _svc.areas.isEmpty ? null : _svc.areas.first;
  }

  /// Khung khu (tỉ lệ 0–1): ưu tiên toạ độ BE, fallback slot dự phòng.
  Rect _rectFor(AreaRecord area, int index) {
    if (area.hasMapBounds) {
      final r = Rect.fromLTRB(area.mapX1!, area.mapY1!, area.mapX2!, area.mapY2!);
      if (r.width > 0.005 && r.height > 0.005) return r;
    }
    return _anchors[index % _anchors.length];
  }

  Rect _rectForSelected() {
    final area = _selectedArea;
    if (area == null) return _anchors.first;
    final idx = _svc.areas.indexWhere((a) => a.id == area.id);
    return _rectFor(area, idx < 0 ? 0 : idx);
  }

  /// Ảnh bản đồ trại: BE `mapImageUrl` (khu đang chọn, hoặc khu bất kỳ có ảnh)
  /// → fallback asset `maps.png`.
  String? get _mapImageUrl {
    String? pick(AreaRecord? a) {
      final u = a?.mapImageUrl?.trim() ?? '';
      return u.isEmpty ? null : u;
    }

    final fromSelected = pick(_selectedArea);
    if (fromSelected != null) return fromSelected;
    for (final a in _svc.areas) {
      final u = pick(a);
      if (u != null) return u;
    }
    return null;
  }

  Widget _mapImage({
    required BoxFit fit,
    Alignment alignment = Alignment.center,
    required Widget fallback,
  }) {
    final url = _mapImageUrl;
    if (url == null) {
      return Image.asset(
        _kMapAsset,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      // URL hỏng → về ảnh mặc định thay vì để trống bản đồ.
      errorBuilder: (_, __, ___) => Image.asset(
        _kMapAsset,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Rect _absRect(Rect rel) => Rect.fromLTRB(
        rel.left * _viewport.width,
        rel.top * _viewport.height,
        rel.right * _viewport.width,
        rel.bottom * _viewport.height,
      );

  List<FarmMapBox> _boxesForRow(String rowId) {
    return _svc.boxes.where((item) {
      if (item.rowId != rowId && item.rowCode != rowId) return false;
      if (_statusFilter != null) {
        final status = item.display.status;
        final match = switch (_statusFilter) {
          BoxStatus.empty =>
            status == BoxStatus.empty || status == BoxStatus.deceased,
          _ => status == _statusFilter,
        };
        if (!match) return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final hit = item.display.id.toLowerCase().contains(q) ||
            item.rowName.toLowerCase().contains(q) ||
            item.rowCode.toLowerCase().contains(q) ||
            (item.display.crabId?.toLowerCase().contains(q) ?? false);
        if (!hit) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.display.id.compareTo(b.display.id));
  }

  List<FarmMapBox> _boxesInRow(String rowId) =>
      _svc.boxes.where((b) => b.rowId == rowId || b.rowCode == rowId).toList();

  // ── Zoom helpers ────────────────────────────────────────────────────────

  void _clampAndSet(Matrix4 m) {
    final s = m.getMaxScaleOnAxis().clamp(1.0, 4.0);
    final t = m.getTranslation();
    final vw = _viewport.width, vh = _viewport.height;
    final tx = t.x.clamp(vw - vw * s, 0.0);
    final ty = t.y.clamp(vh - vh * s, 0.0);
    _tc.value = _ts(tx, ty, s);
  }

  /// Translate(tx, ty) · Scale(s).
  static Matrix4 _ts(double tx, double ty, double s) =>
      Matrix4.translationValues(tx, ty, 0)
          .multiplied(Matrix4.diagonal3Values(s, s, 1));

  void _zoomTo(Rect rel, {double maxScale = 2.4}) {
    if (_viewport == Size.zero) return;
    final r = _absRect(rel);
    final vw = _viewport.width, vh = _viewport.height;
    final fit = math.min(vw / r.width, vh / r.height) * 0.72;
    final s = math.min(maxScale, math.max(1.0, fit));
    final tx = vw / 2 - r.center.dx * s;
    final ty = vh / 2 - r.center.dy * s;
    _clampAndSet(_ts(tx, ty, s));
  }

  void _zoomBy(double factor) {
    if (_viewport == Size.zero) return;
    final cur = _tc.value.getMaxScaleOnAxis();
    final target = (cur * factor).clamp(1.0, 4.0);
    final k = target / cur;
    final c = Offset(_viewport.width / 2, _viewport.height / 2);
    // Scale quanh tâm viewport: T(c) · S(k) · T(-c)
    final m = Matrix4.translationValues(c.dx, c.dy, 0)
        .multiplied(Matrix4.diagonal3Values(k, k, 1))
        .multiplied(Matrix4.translationValues(-c.dx, -c.dy, 0));
    _clampAndSet(m.multiplied(_tc.value));
  }

  void _resetView() {
    setState(() {
      _level = _MapLevel.farm;
      _rowId = null;
    });
    _tc.value = Matrix4.identity();
  }

  void _centerOnSelected() {
    if (_selectedArea == null) return;
    _zoomTo(_rectForSelected());
  }

  // ── Interactions ───────────────────────────────────────────────────────

  Future<void> _selectArea(AreaRecord area, int index) async {
    setState(() {
      _level = _MapLevel.area;
      _rowId = null;
    });
    _zoomTo(_rectFor(area, index));
    if (_svc.selectedAreaId != area.id) {
      await _svc.selectArea(area.id);
    }
  }

  void _selectRow(RowRecord row) {
    setState(() {
      _level = _MapLevel.row;
      _rowId = row.id;
    });
    // Dãy đã có toạ độ trên ảnh → zoom sát vào vị trí dãy.
    if (row.hasMapPoint) {
      _zoomTo(
        Rect.fromCenter(
          center: Offset(row.mapX!, row.mapY!),
          width: 0.12,
          height: 0.12,
        ),
        maxScale: 3.2,
      );
    }
  }

  void _openBox(FarmMapBox item) {
    showBoxDetailDrawer(
      context,
      item,
      onViewDetail: widget.onOpenBox,
      onExportMolting: widget.onExportMolting == null
          ? null
          : () => widget.onExportMolting!(item),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final svc = _svc;
    final summary = svc.summary;
    final rows = svc.rowsForArea(svc.selectedAreaId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          _KpiRow(
            areas: svc.areas.length,
            rows: rows.length,
            summary: summary,
          ),
          if (svc.error != null) ...[
            const SizedBox(height: 8),
            Text(
              svc.error!,
              style: _bv(color: DashboardColors.risk, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
        Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final stacked = c.maxWidth < 1020;
                final map = _buildMap(svc);
                final side = _buildSidePanel(svc, rows);
                if (stacked) {
                  return Column(
            children: [
                      Expanded(child: map),
                      const SizedBox(height: 14),
                      SizedBox(height: 260, child: side),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: map),
                    const SizedBox(width: 14),
                    SizedBox(width: 300, child: side),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(FarmLayoutService svc) {
    final selected = _selectedArea;
    final areas = svc.areas;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: DashboardColors.lightMint,
          border: Border.all(color: DashboardColors.cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            _viewport = size;

            return Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  transformationController: _tc,
                  minScale: 1,
                  maxScale: 4,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _mapImage(
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: DashboardColors.mint,
                            alignment: Alignment.center,
                            child: Text(
                              'Không tải được ảnh bản đồ trại',
                              style: _bv(color: DashboardColors.textMuted),
                            ),
                          ),
                        ),
                        if (_showOverlay)
                          for (var i = 0; i < areas.length; i++)
                            _AreaOverlay(
                              rect: _absRect(_rectFor(areas[i], i)),
                              area: areas[i],
                              selected: selected?.id == areas[i].id,
                              label: svc.areaChipLabel(areas[i]),
                              onTap: () => _selectArea(areas[i], i),
                            ),
                        // Dãy có toạ độ BE → vẽ đúng chỗ trên ảnh khi đã vào khu.
                        if (_showOverlay &&
                            selected != null &&
                            _level == _MapLevel.area)
                          for (final r in svc.rowsForArea(selected.id))
                            if (r.hasMapPoint)
                              _RowMarker(
                                center: Offset(
                                  r.mapX! * size.width,
                                  r.mapY! * size.height,
                                ),
                                label: _rowLabelOf(svc, r.id),
                                boxes: _boxesInRow(r.id),
                                onTap: () => _selectRow(r),
                              ),
                        // Hộp có toạ độ BE → chấm màu theo trạng thái khi đã vào dãy.
                        if (_showOverlay && _level == _MapLevel.row && _rowId != null)
                          for (final b in _boxesForRow(_rowId!))
                            if (b.source?.hasMapPoint == true)
                              _BoxMarker(
                                center: Offset(
                                  b.source!.mapX! * size.width,
                                  b.source!.mapY! * size.height,
                                ),
                                box: b,
                                onTap: () => _openBox(b),
                              ),
                      ],
                    ),
                  ),
                ),

                // Legend
                const Positioned(left: 14, top: 14, child: _LegendCard()),

                // Breadcrumb
                if (_level != _MapLevel.farm && selected != null)
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _Breadcrumb(
                        areaLabel: svc.areaChipLabel(selected),
                        rowLabel: _rowId == null
                            ? null
                            : _rowLabelOf(svc, _rowId!),
                        onFarm: _resetView,
                        onArea: () => setState(() {
                          _level = _MapLevel.area;
                          _rowId = null;
                        }),
                      ),
                    ),
                  ),

                // Controls
                Positioned(
                  right: 14,
                  top: 14,
                  child: _MapControls(
                    onZoomIn: () => _zoomBy(1.4),
                    onZoomOut: () => _zoomBy(1 / 1.4),
                    onCenter: _centerOnSelected,
                    onToggleLayer: () =>
                        setState(() => _showOverlay = !_showOverlay),
                    layerOn: _showOverlay,
                  ),
                ),

                // Floating info card follows selected overlay
                if (_showOverlay && selected != null && _level != _MapLevel.row)
                  AnimatedBuilder(
                    animation: _tc,
                    builder: (context, _) {
                      final r = _absRect(_rectForSelected());
                      final p = MatrixUtils.transformPoint(
                        _tc.value,
                        Offset(r.right, r.top),
                      );
                      const cardW = 236.0;
                      final left = math.min(p.dx + 10, size.width - cardW - 14)
                          .clamp(14.0, size.width - cardW - 14)
                          .toDouble();
                      final top = p.dy
                          .clamp(64.0, math.max(64.0, size.height - 190))
                          .toDouble();
                      return Positioned(
                        left: left,
                        top: top,
                        child: _AreaInfoCard(
                          width: cardW,
                          area: selected,
                          label: svc.areaChipLabel(selected),
                          rows: svc.rowsForArea(selected.id).length,
                          summary: svc.summary,
                        ),
                      );
                    },
                  ),

                // Bottom-left: full farm
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: _PillButton(
                    icon: Icons.fullscreen_rounded,
                    label: 'Xem toàn trại',
                    onTap: _resetView,
                  ),
                ),

                // Drill-down panel (rows / boxes)
                if (_level != _MapLevel.farm && selected != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: Center(
                      child: _level == _MapLevel.area
                          ? _RowsPanel(
                              areaLabel: svc.areaChipLabel(selected),
                              rows: svc.rowsForArea(selected.id),
                              boxesInRow: _boxesInRow,
                              onSelectRow: _selectRow,
                            )
                          : _BoxesPanel(
                              rowLabel: _rowLabelOf(svc, _rowId!),
                              boxes: _boxesForRow(_rowId!),
                              onBack: () => setState(() {
                                _level = _MapLevel.area;
                                _rowId = null;
                              }),
                              onBoxTap: _openBox,
                            ),
                    ),
                  ),

                if (svc.loading && svc.boxes.isEmpty)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: DashboardColors.brand,
          ),
        ),
      ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _rowLabelOf(FarmLayoutService svc, String rowId) {
    for (final r in svc.rows) {
      if (r.id == rowId) {
        final n = r.rowName.trim();
        return n.isNotEmpty ? n : r.rowCode;
      }
    }
    return rowId;
  }

  Widget _buildSidePanel(FarmLayoutService svc, List<RowRecord> rows) {
    final selected = _selectedArea;
    final summary = svc.summary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Text(
                  'Thông tin khu vực',
                  style: _bv(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _Dropdown<String>(
                  valueLabel: selected == null
                      ? 'Chưa có khu'
                      : '${svc.areaChipLabel(selected)} – ${selected.areaCode}',
                  items: [
                    for (final a in svc.areas)
                      (a.id, '${svc.areaChipLabel(a)} – ${a.areaCode}'),
                  ],
                  onSelected: (id) {
                    final idx = svc.areas.indexWhere((a) => a.id == id);
                    if (idx >= 0) _selectArea(svc.areas[idx], idx);
                  },
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 96,
                    child: _mapImage(
                      fit: BoxFit.cover,
                      alignment: const Alignment(-0.4, -0.5),
                      fallback: Container(color: DashboardColors.mint),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.qr_code_2_outlined,
                  label: 'Mã khu',
                  value: selected?.areaCode ?? '—',
                ),
                _InfoRow(
                  icon: Icons.view_week_outlined,
                  label: 'Tổng dãy',
                  value: '${rows.length}',
                ),
                _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Tổng hộp',
                  value: '${summary.total}',
                ),
                _InfoRow(
                  icon: Icons.pets_outlined,
                  label: 'Đang nuôi',
                  value: _withPct(summary.occupied, summary.total),
                  color: DashboardColors.blue,
                ),
                _InfoRow(
                  icon: Icons.crop_square_outlined,
                  label: 'Hộp trống',
                  value: _withPct(summary.empty, summary.total),
                  color: _kSlate,
                ),
                _InfoRow(
                  icon: Icons.check_circle_outline,
                  label: 'Bình thường',
                  value: _withPct(summary.normal, summary.total),
                  color: DashboardColors.healthy,
                ),
                _InfoRow(
                  icon: Icons.visibility_outlined,
                  label: 'Theo dõi',
                  value: _withPct(summary.watch, summary.total),
                  color: DashboardColors.monitoring,
                ),
                _InfoRow(
                  icon: Icons.warning_amber_rounded,
                  label: 'Cảnh báo',
                  value: _withPct(summary.alert, summary.total),
                  color: DashboardColors.risk,
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: selected == null || widget.onOpenAreaDetail == null
                    ? null
                      : () => widget.onOpenAreaDetail!(selected.id),
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: Text(
                    'Xem chi tiết khu →',
                    style: _bv(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
                const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bộ lọc hiển thị',
                  style: _bv(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _Dropdown<BoxStatus?>(
                  valueLabel: _statusFilter?.label ?? 'Tất cả trạng thái',
                  items: [
                    for (final s in _statusOptions)
                      (s, s?.label ?? 'Tất cả trạng thái'),
                  ],
                  onSelected: (s) => setState(() => _statusFilter = s),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (q) => setState(() => _search = q.trim()),
                  style: _bv(color: DashboardColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tìm dãy, hộp...',
                    hintStyle: _bv(
                        color: DashboardColors.textMuted,
                      fontSize: 12.5,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: DashboardColors.textMuted,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: DashboardColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: DashboardColors.brandGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _level == _MapLevel.row
                      ? 'Bộ lọc đang áp dụng cho hộp trong dãy đã chọn.'
                      : 'Chọn Khu → Dãy trên bản đồ để xem hộp theo bộ lọc.',
                  style: _bv(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  static String _withPct(int n, int total) {
    if (total <= 0) return '$n';
    return '$n (${((n / total) * 100).round()}%)';
  }
}

// ── KPI row ────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.areas,
    required this.rows,
    required this.summary,
  });

  final int areas;
  final int rows;
  final FarmLayoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.total;
    String pct(int n) => total <= 0 ? '' : '(${((n / total) * 100).round()}%)';

    final items = <_KpiSpec>[
      _KpiSpec('Tổng khu', '$areas', '', Icons.home_work_outlined,
          DashboardColors.brand),
      _KpiSpec('Tổng dãy', '$rows', '', Icons.view_week_outlined,
          DashboardColors.brand),
      _KpiSpec('Tổng hộp', '$total', '', Icons.inventory_2_outlined,
          DashboardColors.brand),
      _KpiSpec('Đang nuôi', '${summary.occupied}', pct(summary.occupied),
          Icons.pets_outlined, DashboardColors.blue),
      _KpiSpec('Hộp trống', '${summary.empty}', pct(summary.empty),
          Icons.crop_square_outlined, _kSlate),
      _KpiSpec('Bình thường', '${summary.normal}', pct(summary.normal),
          Icons.check_circle_outline, DashboardColors.healthy),
      _KpiSpec('Theo dõi', '${summary.watch}', pct(summary.watch),
          Icons.visibility_outlined, DashboardColors.monitoring),
      _KpiSpec('Cảnh báo', '${summary.alert}', pct(summary.alert),
          Icons.warning_amber_rounded, DashboardColors.risk),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1180 ? 8 : (c.maxWidth > 720 ? 4 : 2);
        const gap = 10.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final k in items) SizedBox(width: w, child: _MiniKpi(spec: k)),
          ],
        );
      },
    );
  }
}

class _KpiSpec {
  const _KpiSpec(this.label, this.value, this.sub, this.icon, this.color);
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({required this.spec});
  final _KpiSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.brand.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
      children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(spec.icon, size: 18, color: spec.color),
          ),
          const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bv(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
              Text(
                      spec.value,
                      style: _bv(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                      ),
                    ),
                    if (spec.sub.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          spec.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _bv(
                            fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                            color: spec.color,
                          ),
                        ),
                      ),
                    ],
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

// ── Map overlays ───────────────────────────────────────────────────────────

class _AreaOverlay extends StatelessWidget {
  const _AreaOverlay({
    required this.rect,
    required this.area,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final Rect rect;
  final AreaRecord area;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Stack(
            clipBehavior: Clip.none,
                children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: DashboardColors.brandGreen
                        .withValues(alpha: selected ? 0.20 : 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? DashboardColors.brand
                          : DashboardColors.brandGreen,
                      width: selected ? 2.6 : 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -6,
                top: -30,
                child: Icon(
                  Icons.location_on,
                  size: 34,
                  color: DashboardColors.brand,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: _bv(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.brand,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Điểm dãy trên ảnh (BE `mapX`/`mapY`): chip nhỏ có tên dãy + số hộp.
class _RowMarker extends StatelessWidget {
  const _RowMarker({
    required this.center,
    required this.label,
    required this.boxes,
    required this.onTap,
  });

  final Offset center;
  final String label;
  final List<FarmMapBox> boxes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alerts =
        boxes.where((b) => b.display.status == BoxStatus.alert).length;
    final watch =
        boxes.where((b) => b.display.status == BoxStatus.watch).length;
    final accent = alerts > 0
        ? DashboardColors.risk
        : watch > 0
            ? DashboardColors.monitoring
            : DashboardColors.brand;
    const w = 112.0, h = 30.0;
    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      width: w,
      height: h,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
              ),
            ],
          ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.view_week_outlined, size: 13, color: accent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _bv(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${boxes.length}',
                  style: _bv(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accent,
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

/// Điểm hộp trên ảnh (BE `mapX`/`mapY`): chấm màu theo trạng thái hộp.
class _BoxMarker extends StatelessWidget {
  const _BoxMarker({
    required this.center,
    required this.box,
    required this.onTap,
  });

  final Offset center;
  final FarmMapBox box;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = box.display.status;
    const d = 16.0;
    return Positioned(
      left: center.dx - d / 2,
      top: center.dy - d / 2,
      width: d,
      height: d,
      child: Tooltip(
        message: '${box.display.id} · ${status.label}',
        textStyle: _bv(fontSize: 11, color: Colors.white),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: status.color.withValues(alpha: 0.45),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaInfoCard extends StatelessWidget {
  const _AreaInfoCard({
    required this.width,
    required this.area,
    required this.label,
    required this.rows,
    required this.summary,
  });

  final double width;
  final AreaRecord area;
  final String label;
  final int rows;
  final FarmLayoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final sub = (area.description?.trim().isNotEmpty ?? false)
        ? area.description!.trim()
        : area.areaCode;
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.brand.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _bv(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          Text(
            '($sub)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _bv(fontSize: 11, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            '$rows dãy · ${summary.total} hộp',
            style: _bv(
                fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _Count(DashboardColors.healthy, summary.normal, 'bình thường'),
              _Count(DashboardColors.monitoring, summary.watch, 'theo dõi'),
              _Count(DashboardColors.risk, summary.alert, 'cảnh báo'),
              _Count(_kSlate, summary.empty, 'hộp trống'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.color, this.n, this.label);
  final Color color;
  final int n;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 5),
        Text(
          '$n',
          style: _bv(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: _bv(fontSize: 11, color: DashboardColors.textMuted)),
      ],
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    Widget row(Color c, String t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 9, color: c),
              const SizedBox(width: 7),
              Text(
                t,
                style: _bv(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          row(DashboardColors.healthy, 'Bình thường'),
          row(DashboardColors.monitoring, 'Theo dõi'),
          row(DashboardColors.risk, 'Cảnh báo'),
          row(_kSlate, 'Hộp trống'),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenter,
    required this.onToggleLayer,
    required this.layerOn,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenter;
  final VoidCallback onToggleLayer;
  final bool layerOn;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlGroup(children: [
          _ControlBtn(icon: Icons.add_rounded, tooltip: 'Phóng to', onTap: onZoomIn),
          _ControlBtn(icon: Icons.remove_rounded, tooltip: 'Thu nhỏ', onTap: onZoomOut),
        ]),
        const SizedBox(height: 8),
        _ControlGroup(children: [
          _ControlBtn(
            icon: Icons.my_location_rounded,
            tooltip: 'Về khu đang chọn',
            onTap: onCenter,
          ),
        ]),
        const SizedBox(height: 8),
        _ControlGroup(children: [
          _ControlBtn(
            icon: Icons.layers_outlined,
            tooltip: layerOn ? 'Ẩn lớp khu nuôi' : 'Hiện lớp khu nuôi',
            onTap: onToggleLayer,
            active: layerOn,
          ),
        ]),
      ],
    );
  }
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.brand.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: DashboardColors.cardBorder),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 20,
            color: active ? DashboardColors.brand : DashboardColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DashboardColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: DashboardColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: _bv(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                color: DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    required this.areaLabel,
    required this.onFarm,
    required this.onArea,
    this.rowLabel,
  });

  final String areaLabel;
  final String? rowLabel;
  final VoidCallback onFarm;
  final VoidCallback onArea;

  @override
  Widget build(BuildContext context) {
    Widget crumb(String t, {VoidCallback? onTap, bool last = false}) {
      final w = Text(
        t,
        style: _bv(
          fontSize: 12,
          fontWeight: last ? FontWeight.w800 : FontWeight.w600,
          color: last ? DashboardColors.brand : DashboardColors.textMuted,
        ),
      );
      if (onTap == null) return w;
      return InkWell(onTap: onTap, child: w);
    }

    Widget sep() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right_rounded,
              size: 16, color: DashboardColors.textMuted),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          crumb('Toàn trại', onTap: onFarm),
          sep(),
          crumb(areaLabel, onTap: rowLabel == null ? null : onArea, last: rowLabel == null),
          if (rowLabel != null) ...[
            sep(),
            crumb('Dãy $rowLabel', last: true),
          ],
        ],
      ),
    );
  }
}

class _RowsPanel extends StatelessWidget {
  const _RowsPanel({
    required this.areaLabel,
    required this.rows,
    required this.boxesInRow,
    required this.onSelectRow,
  });

  final String areaLabel;
  final List<RowRecord> rows;
  final List<FarmMapBox> Function(String rowId) boxesInRow;
  final ValueChanged<RowRecord> onSelectRow;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 760),
      margin: const EdgeInsets.symmetric(horizontal: 150),
      padding: const EdgeInsets.all(12),
      decoration: _panelDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$areaLabel · ${rows.length} dãy',
            style: _bv(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              'Khu này chưa có dãy.',
              style: _bv(fontSize: 12, color: DashboardColors.textMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in rows)
                  _RowChip(
                    row: r,
                    boxes: boxesInRow(r.id),
                    onTap: () => onSelectRow(r),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RowChip extends StatelessWidget {
  const _RowChip({required this.row, required this.boxes, required this.onTap});

  final RowRecord row;
  final List<FarmMapBox> boxes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = row.rowName.trim().isNotEmpty ? row.rowName : row.rowCode;
    final alerts = boxes
        .where((b) =>
            b.display.status == BoxStatus.alert ||
            b.display.status == BoxStatus.watch)
        .length;
    return Material(
      color: DashboardColors.lightMint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
              Icon(Icons.view_week_outlined,
                  size: 16, color: DashboardColors.brand),
              const SizedBox(width: 6),
            Text(
                'Dãy $label',
                style: _bv(
                fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary,
              ),
            ),
              const SizedBox(width: 6),
            Text(
                '${boxes.length} hộp',
                style: _bv(fontSize: 11, color: DashboardColors.textMuted),
              ),
              if (alerts > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DashboardColors.risk.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$alerts',
                    style: _bv(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.risk,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxesPanel extends StatelessWidget {
  const _BoxesPanel({
    required this.rowLabel,
    required this.boxes,
    required this.onBack,
    required this.onBoxTap,
  });

  final String rowLabel;
  final List<FarmMapBox> boxes;
  final VoidCallback onBack;
  final ValueChanged<FarmMapBox> onBoxTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 820),
      margin: const EdgeInsets.symmetric(horizontal: 150),
      padding: const EdgeInsets.all(12),
      decoration: _panelDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 18, color: DashboardColors.brand),
                ),
              ),
                const SizedBox(width: 6),
              Text(
                'Dãy $rowLabel · ${boxes.length} hộp',
                style: _bv(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
            ],
                ),
          const SizedBox(height: 8),
          if (boxes.isEmpty)
                Text(
              'Không có hộp phù hợp với bộ lọc.',
              style: _bv(fontSize: 12, color: DashboardColors.textMuted),
            )
          else
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: boxes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => FarmMapBoxTile(
                  item: boxes[i],
                  onTap: () => onBoxTap(boxes[i]),
                ),
                  ),
                ),
              ],
            ),
    );
  }
}

BoxDecoration _panelDeco() => BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: DashboardColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: DashboardColors.brand.withValues(alpha: 0.10),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );

// ── Side panel widgets ─────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
                children: [
          Icon(icon, size: 16, color: color ?? DashboardColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: _bv(fontSize: 12, color: DashboardColors.textMuted),
            ),
          ),
          Text(
            value,
            style: _bv(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.valueLabel,
    required this.items,
    required this.onSelected,
  });

  final String valueLabel;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      color: Colors.white,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DashboardColors.cardBorder),
      ),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.$1,
            child: Text(
              item.$2,
              style: _bv(fontSize: 13, color: DashboardColors.textPrimary),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(
                valueLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _bv(
                  fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.expand_more_rounded,
                size: 18, color: DashboardColors.textMuted),
          ],
        ),
      ),
    );
  }
}
