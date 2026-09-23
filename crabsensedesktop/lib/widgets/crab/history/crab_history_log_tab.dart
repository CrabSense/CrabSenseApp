import 'package:flutter/material.dart';

import '../../../models/camera_device.dart';
import '../../../models/crab_individual.dart';
import '../../../models/crab_lifecycle_event.dart';
import '../../../models/production_models.dart';
import '../../../services/crab_lifecycle_controller.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import 'crab_event_detail_panel.dart';
import 'crab_history_export.dart';
import 'crab_history_filters.dart';
import 'crab_history_summary.dart';
import 'crab_timeline.dart';

/// Nội dung tab "Lịch sử & Nhật ký" trong Chi tiết cua.
class CrabHistoryLogTab extends StatefulWidget {
  const CrabHistoryLogTab({
    super.key,
    required this.crab,
    required this.controller,
    required this.token,
    this.cameras = const [],
    this.onOpenArea,
    this.onOpenRow,
    this.onOpenBox,
    this.onOpenCamera,
  });

  final CrabIndividual crab;
  final CrabLifecycleController controller;
  final String token;
  final List<CameraDevice> cameras;
  final void Function(String areaId)? onOpenArea;
  final void Function({required String areaId, String? rowId})? onOpenRow;
  final void Function(BoxRecord box)? onOpenBox;
  final void Function(String? cameraId)? onOpenCamera;

  @override
  State<CrabHistoryLogTab> createState() => _CrabHistoryLogTabState();
}

class _CrabHistoryLogTabState extends State<CrabHistoryLogTab> {
  late final TextEditingController _search = TextEditingController(text: widget.controller.search);

  CrabLifecycleController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_rebuild);
    if (_c.items.isEmpty && !_c.loading) _c.load();
  }

  @override
  void dispose() {
    _c.removeListener(_rebuild);
    _search.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    if (_search.text != _c.search) _search.value = TextEditingValue(text: _c.search);
    setState(() {});
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(
        start: _c.from ?? now.subtract(const Duration(days: 7)),
        end: _c.to ?? now,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: DashboardColors.brand,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: DashboardColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    _c.setCustomRange(picked.start, picked.end);
  }

  Future<void> _export(CrabHistoryExportFormat format) async {
    try {
      final events = await _c.fetchAllForExport();
      if (!mounted) return;
      await exportCrabHistory(
        context: context,
        crabCode: widget.crab.code,
        events: events,
        format: format,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xuất được lịch sử: $e')),
      );
    }
  }

  String? _cameraLabel(String? id) {
    if (id == null || id.isEmpty) return null;
    final cam = widget.cameras.where((c) => c.id == id || c.cameraCode == id).firstOrNull;
    return cam == null ? id : cam.cameraCode;
  }

  void _openArea(CrabLifecycleEvent e) {
    final id = e.location?.farmAreaId ?? widget.crab.areaId;
    if (id.isEmpty) return;
    widget.onOpenArea?.call(id);
  }

  void _openRow(CrabLifecycleEvent e) {
    final areaId = e.location?.farmAreaId ?? widget.crab.areaId;
    if (areaId.isEmpty) return;
    widget.onOpenRow?.call(areaId: areaId, rowId: e.location?.rowId ?? widget.crab.rowId);
  }

  void _openBox(CrabLifecycleEvent e) {
    final loc = e.location;
    if (loc?.boxId == null || loc!.boxId!.isEmpty) return;
    widget.onOpenBox?.call(BoxRecord(
      id: loc.boxId!,
      rowId: loc.rowId ?? widget.crab.rowId,
      boxCode: loc.boxCode ?? loc.boxId!,
      status: 'active',
      areaId: loc.farmAreaId ?? widget.crab.areaId,
      areaCode: loc.farmAreaCode ?? widget.crab.areaCode,
      rowCode: loc.rowCode ?? widget.crab.rowName,
    ));
  }

  void _select(CrabLifecycleEvent e, double width) {
    _c.select(e.id);
    if (width < 1100) _openDetailOverlay(width < 720);
  }

  Future<void> _openDetailOverlay(bool sheet) async {
    final e = _c.selected;
    if (e == null) return;
    if (sheet) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: SingleChildScrollView(child: _detail(e, onClose: () => Navigator.of(ctx).pop())),
        ),
      );
      return;
    }
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng',
      barrierColor: const Color.fromRGBO(15, 35, 30, 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.white,
          elevation: 12,
          child: SizedBox(
            width: 420,
            height: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: _detail(e, onClose: () => Navigator.of(ctx).pop()),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  Widget _detail(CrabLifecycleEvent? e, {VoidCallback? onClose}) {
    return CrabEventDetailPanel(
      event: e,
      token: widget.token,
      loading: _c.loading && e == null,
      onClose: onClose ?? () => _c.select(null),
      onOpenArea: e == null ? null : () => _openArea(e),
      onOpenRow: e == null ? null : () => _openRow(e),
      onOpenBox: e == null ? null : () => _openBox(e),
      onOpenCamera: e == null ? null : () => widget.onOpenCamera?.call(e.cameraId),
      cameraLabel: e == null ? null : _cameraLabel(e.cameraId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = _c.loading && _c.items.isEmpty;
    final error = _c.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 14),
        CrabHistoryFilters(
          search: _search,
          onSearch: _c.setSearch,
          type: _c.type,
          onType: _c.setType,
          period: _c.period,
          onPeriod: (p) {
            if (p == CrabHistoryPeriod.custom) {
              _pickRange();
              return;
            }
            _c.setPeriod(p);
          },
          from: _c.from,
          to: _c.to,
          onPickRange: _pickRange,
          onClear: () {
            _search.clear();
            _c.clearFilters();
          },
        ),
        const SizedBox(height: 14),
        if (error != null && _c.items.isEmpty)
          MgmtEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải lịch sử.',
            message: error,
            action: MgmtPrimaryButton(label: 'Thử lại', onTap: _c.load, height: 38),
          )
        else ...[
          CrabHistorySummary(
            summary: _c.summary,
            active: _c.type,
            onTap: _c.setType,
            loading: loading,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 1100;
            final timeline = CrabTimeline(
              items: _c.items,
              sort: _c.sort,
              onSort: _c.setSort,
              selectedId: _c.selectedId,
              onSelect: (e) => _select(e, c.maxWidth),
              hasMore: _c.hasMore,
              loadingMore: _c.loadingMore,
              onLoadMore: _c.loadMore,
              loading: loading,
              emptyFiltered: _c.items.isEmpty && !loading && _c.hasActiveFilters,
              onClearFilters: () {
                _search.clear();
                _c.clearFilters();
              },
            );
            if (!wide) return timeline;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 65, child: timeline),
                const SizedBox(width: 14),
                Expanded(flex: 35, child: _detail(_c.selected)),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 20, color: DashboardColors.brand),
                  const SizedBox(width: 8),
                  Text(
                    'Lịch sử & Nhật ký',
                    style: bvText(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Theo dõi toàn bộ hoạt động, sự kiện và thay đổi của cua theo thời gian.',
                style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
        CrabHistoryExportMenu(onExport: _export),
      ],
    );
  }
}
