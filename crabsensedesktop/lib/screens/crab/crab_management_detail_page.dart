import 'package:flutter/material.dart';

import '../../models/crab_individual.dart';
import '../../models/crab_profile.dart';
import '../../models/crab_status.dart';
import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/camera_device_service.dart';
import '../../services/cloud_api_client.dart';
import '../../services/crab_feeding_activity_controller.dart';
import '../../services/crab_growth_molt_controller.dart';
import '../../services/crab_lifecycle_controller.dart';
import '../../services/crab_service.dart';
import '../../services/gateway_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/crab/crab_action_modals.dart';
import '../../widgets/crab/crab_auth_image.dart';
import '../../widgets/crab/crab_box_cameras_tab.dart';
import '../../widgets/crab/crab_management_dialogs.dart';
import '../../widgets/crab/crab_overview_cards.dart';
import '../../widgets/crab/crab_status_badge.dart';
import '../../widgets/crab/feeding/add_feeding_modal.dart';
import '../../widgets/crab/feeding/crab_feeding_activity_tab.dart';
import '../../widgets/crab/feeding/feeding_event_drawer.dart';
import '../../widgets/crab/growth/crab_growth_molt_tab.dart';
import '../../widgets/crab/growth/growth_record_modal.dart';
import '../../widgets/crab/history/crab_history_log_tab.dart';
import '../../widgets/shared/mgmt_ui.dart';

enum CrabDetailTab { overview, growth, feeding, history }

/// Chi tiết cua: header cá thể + 4 tab
/// (Tổng quan | Sinh trưởng & Lột xác | Ăn & Vận động | Lịch sử & Nhật ký).
class CrabManagementDetailPage extends StatefulWidget {
  const CrabManagementDetailPage({
    super.key,
    required this.crabId,
    required this.service,
    required this.cameraService,
    required this.gatewayService,
    required this.onBack,
    this.onOpenArea,
    this.onOpenBoxes,
    this.onOpenBox,
    this.onNavigate,
    this.initialTab = CrabDetailTab.overview,
  });

  final String crabId;
  final CrabService service;
  final CameraDeviceService cameraService;
  final GatewayService gatewayService;
  final VoidCallback onBack;
  final void Function(String areaId)? onOpenArea;
  final void Function({required String areaId, String? rowId})? onOpenBoxes;

  /// Mở Chi tiết hộp (BoxDetailPage) cho hộp đang chứa cua.
  final void Function(BoxRecord box, CrabIndividual crab)? onOpenBox;
  final void Function(AppRoute route)? onNavigate;
  final CrabDetailTab initialTab;

  @override
  State<CrabManagementDetailPage> createState() => _CrabManagementDetailPageState();
}

class _CrabManagementDetailPageState extends State<CrabManagementDetailPage> {
  late CrabDetailTab _tab = widget.initialTab;
  late final CrabFeedingActivityController _feeding = CrabFeedingActivityController(
    crabId: widget.crabId,
    api: widget.service.api,
    tokenProvider: () => widget.service.token,
  );
  late final CrabGrowthMoltController _growth = CrabGrowthMoltController(
    crabId: widget.crabId,
    api: widget.service.api,
    tokenProvider: () => widget.service.token,
  );
  late final CrabLifecycleController _history = CrabLifecycleController(
    crabId: widget.crabId,
    api: widget.service.api,
    tokenProvider: () => widget.service.token,
  );
  var _detailLoading = false;
  BoxRecord? _box;
  var _boxLoading = false;

  CrabService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_rebuild);
    widget.cameraService.addListener(_rebuild);
    _loadDetail();
    _feeding.load();
    _growth.load();
    _history.load();
  }

  @override
  void dispose() {
    _svc.removeListener(_rebuild);
    widget.cameraService.removeListener(_rebuild);
    _feeding.dispose();
    _growth.dispose();
    _history.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDetail() async {
    setState(() => _detailLoading = true);
    await _svc.loadDetail(widget.crabId);
    final crab = _svc.getById(widget.crabId);
    if (mounted) setState(() => _detailLoading = false);
    if (crab != null && crab.boxId.isNotEmpty) {
      _loadBox(crab);
      try {
        await widget.cameraService.loadCamerasByBox(crab.boxId);
      } catch (_) {}
    }
  }

  Future<void> _loadBox(CrabIndividual crab) async {
    setState(() => _boxLoading = true);
    try {
      final boxes = await _svc.api.fetchAllBoxes(
        _svc.token,
        areaId: crab.areaId.isEmpty ? null : crab.areaId,
        rowId: crab.rowId.isEmpty ? null : crab.rowId,
      );
      _box = boxes.where((b) => b.id == crab.boxId).firstOrNull;
    } catch (_) {
      _box = null;
    } finally {
      if (mounted) setState(() => _boxLoading = false);
    }
  }

  void _openBoxes(CrabIndividual crab) {
    if (crab.areaId.isEmpty) return;
    widget.onOpenBoxes?.call(areaId: crab.areaId, rowId: crab.rowId.isEmpty ? null : crab.rowId);
  }

  void _openBoxDetail(CrabIndividual crab) {
    final box = _box;
    if (box != null && widget.onOpenBox != null) {
      widget.onOpenBox!(box, crab);
    } else {
      _openBoxes(crab);
    }
  }

  Future<void> _editCrab(CrabIndividual crab) async {
    await showCrabManagementFormDialog(
      context,
      _svc,
      existing: crab,
      onRecordMeasurement: () => _recordGrowth(crab),
      onMoveBox: () => showMoveCrabModal(context, _svc, crab),
    );
    if (!mounted) return;
    await _loadDetail();
    _history.load();
    _growth.load();
  }

  Future<void> _recordGrowth(CrabIndividual crab) async {
    final input = await showGrowthRecordModal(
      context,
      crabCode: crab.code,
      token: _svc.token,
      api: _svc.api,
      cameras: widget.cameraService.cameras,
    );
    if (input == null || !mounted) return;
    final err = await _growth.record(input, crab: crab, operatorName: _svc.operatorName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? (input.isMolt ? 'Đã ghi nhận lần lột xác mới.' : 'Đã ghi nhận sinh trưởng thành công.'))),
    );
    if (err == null) {
      await _loadDetail();
      _history.load();
    }
  }

  Future<void> _editNote(CrabIndividual crab) async {
    final text = await showCrabNoteDialog(context, initial: _cleanNote(crab.quickNote));
    if (text == null || !mounted) return;
    final ok = await _svc.updateCrab(crab.copyWith(quickNote: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã lưu ghi chú' : (_svc.error ?? 'Không lưu được ghi chú'))),
    );
  }

  Future<void> _addFeeding(CrabIndividual crab) async {
    final input = await showAddFeedingModal(
      context,
      crabCode: crab.code,
      boxLabel: crab.boxLabel,
      boxId: crab.boxId,
      token: _svc.token,
      api: _svc.api,
      cameras: widget.cameraService.cameras,
    );
    if (input == null || !mounted) return;
    final err = await _feeding.addFeeding(
      boxId: crab.boxId,
      input: input,
      operatorName: _svc.operatorName,
      locationLabel: crab.locationLine,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Đã lưu lần cho ăn')));
    if (err == null) _history.load();
  }

  void _openActivity(CrabActivityItem it, CrabIndividual crab) {
    final f = it.feedingEvent;
    if (f != null) {
      showFeedingEventDrawer(
        context,
        event: f,
        token: _svc.token,
        cameraLabel: f.cameraId ?? '—',
        onViewCamera: () => _showCameras(crab),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(it.title, style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fmtDateTimeVn(it.at), style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              const SizedBox(height: 10),
              Text(it.detail.isEmpty ? 'Không có mô tả chi tiết.' : it.detail,
                  style: bvText(fontSize: 13, height: 1.45, color: DashboardColors.textPrimary)),
            ],
          ),
        ),
        actions: [MgmtOutlineButton(label: 'Đóng', onTap: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  static String? _cleanNote(String? s) {
    final t = (s ?? '').trim();
    if (t.isEmpty || t.toLowerCase() == 'null' || t.toLowerCase() == 'undefined') return null;
    return t;
  }

  void _showCameras(CrabIndividual crab) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(28),
        child: SizedBox(
          width: 900,
          height: 600,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.videocam_outlined, size: 18, color: DashboardColors.brand),
                    const SizedBox(width: 8),
                    Text(
                      'Camera hộp ${crab.boxLabel}',
                      style: bvText(fontSize: 15, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: DashboardColors.mint),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CrabBoxCamerasTab(
                    boxId: crab.boxId,
                    cameraService: widget.cameraService,
                    gatewayId: widget.gatewayService.gatewayId,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moreAction(_HeaderAction a, CrabIndividual crab) async {
    final messenger = ScaffoldMessenger.of(context);
    switch (a) {
      case _HeaderAction.edit:
        await _editCrab(crab);
      case _HeaderAction.history:
        setState(() => _tab = CrabDetailTab.history);
      case _HeaderAction.recordMolt:
        await showRecordMoltDialog(context, _svc, crab);
      case _HeaderAction.markMolting:
        await showMarkMoltingModal(context, _svc, crab);
      case _HeaderAction.readyHarvest:
        final ok = await _svc.markReadyHarvest(crab.id);
        messenger.showSnackBar(
          SnackBar(content: Text(ok ? 'Đã đánh dấu ${crab.code} sắp thu hoạch' : (_svc.error ?? 'Lỗi'))),
        );
      case _HeaderAction.markDead:
        await showMarkDeadModal(context, _svc, crab);
      case _HeaderAction.exportSoftshell:
        if (!await confirmCrabAction(
          context,
          title: 'Xuất cua lột?',
          message: 'Xuất ${crab.code} ra tồn kho với loại cua lột.',
          confirmLabel: 'Xuất',
        )) {
          return;
        }
        final ok = await _svc.exportSoftshell(crab.id);
        messenger.showSnackBar(
          SnackBar(content: Text(ok ? 'Đã xuất cua lột vào tồn kho' : (_svc.error ?? 'Lỗi'))),
        );
      case _HeaderAction.cameras:
        _showCameras(crab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final crab = _svc.getById(widget.crabId);
    if (crab == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Breadcrumb(onNavigate: widget.onNavigate, onBack: widget.onBack),
            const SizedBox(height: 12),
            if (_detailLoading)
              const _HeaderSkeleton()
            else
              MgmtEmptyState(
                icon: Icons.warning_amber_rounded,
                title: 'Không thể tải thông tin cua.',
                message: _svc.error ?? 'Vui lòng thử lại.',
                action: Wrap(
                  spacing: 8,
                  children: [
                    MgmtOutlineButton(icon: Icons.arrow_back_rounded, label: 'Quay lại', onTap: widget.onBack),
                    MgmtPrimaryButton(icon: Icons.refresh_rounded, label: 'Thử lại', onTap: _retry, height: 38),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    final profile = _svc.profileOf(crab.id);
    final initialLoading = _detailLoading && profile == null;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _Breadcrumb(onNavigate: widget.onNavigate, onBack: widget.onBack),
              const SizedBox(height: 10),
              if (initialLoading)
                const _HeaderSkeleton()
              else
                _CrabDetailHeader(
                  crab: crab,
                  profile: profile,
                  token: _svc.token,
                  loading: _detailLoading,
                  onBack: widget.onBack,
                  onRefresh: _loadDetail,
                  onMove: () async {
                    final ok = await showMoveCrabModal(context, _svc, crab);
                    if (!mounted || !ok) return;
                    await _loadDetail();
                    _history.load();
                  },
                  onMore: (a) => _moreAction(a, crab),
                  onOpenArea: crab.areaId.isEmpty ? null : () => widget.onOpenArea?.call(crab.areaId),
                  onOpenRow: crab.areaId.isEmpty ? null : () => _openBoxes(crab),
                  onOpenBox: crab.boxId.isEmpty ? null : () => _openBoxDetail(crab),
                ),
              const SizedBox(height: 14),
              _DetailTabBar(value: _tab, onChanged: (t) => setState(() => _tab = t)),
              const SizedBox(height: 14),
              _tabBody(crab, profile, initialLoading),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _retry() async {
    await _svc.load();
    await _loadDetail();
  }

  Widget _tabBody(CrabIndividual crab, CrabProfile? profile, bool initialLoading) {
    switch (_tab) {
      case CrabDetailTab.overview:
        return _OverviewTab(
          crab: crab,
          profile: profile,
          loading: initialLoading,
          feeding: _feeding,
          box: _box,
          boxLoading: _boxLoading,
          onOpenFeeding: () => setState(() => _tab = CrabDetailTab.feeding),
          onOpenHistory: () => setState(() => _tab = CrabDetailTab.history),
          onEdit: () => _editCrab(crab),
          onEditNote: () => _editNote(crab),
          onAddFeeding: () => _addFeeding(crab),
          onOpenArea: crab.areaId.isEmpty ? null : () => widget.onOpenArea?.call(crab.areaId),
          onOpenRow: crab.areaId.isEmpty ? null : () => _openBoxes(crab),
          onOpenBox: crab.boxId.isEmpty ? null : () => _openBoxDetail(crab),
          onTapActivity: (it) => _openActivity(it, crab),
        );
      case CrabDetailTab.growth:
        return CrabGrowthMoltTab(
          crab: crab,
          controller: _growth,
          token: _svc.token,
          api: _svc.api,
          cameras: widget.cameraService.cameras,
          operatorName: _svc.operatorName,
          onRecorded: () {
            _loadDetail();
            _history.load();
          },
        );
      case CrabDetailTab.feeding:
        return CrabFeedingActivityTab(
          crab: crab,
          controller: _feeding,
          token: _svc.token,
          api: _svc.api,
          cameras: widget.cameraService.cameras,
          operatorName: _svc.operatorName,
          onViewCamera: () => _showCameras(crab),
        );
      case CrabDetailTab.history:
        return CrabHistoryLogTab(
          crab: crab,
          controller: _history,
          token: _svc.token,
          cameras: widget.cameraService.cameras,
          onOpenArea: widget.onOpenArea,
          onOpenRow: widget.onOpenBoxes,
          onOpenBox: (box) => widget.onOpenBox?.call(box, crab),
          onOpenCamera: (_) => _showCameras(crab),
        );
    }
  }
}

// ── Breadcrumb ───────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({this.onNavigate, this.onBack});

  final void Function(AppRoute route)? onNavigate;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final link = bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textMuted);
    final sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.chevron_right_rounded, size: 15, color: DashboardColors.textMuted.withValues(alpha: 0.7)),
    );
    return Row(
      children: [
        InkWell(onTap: () => onNavigate?.call(AppRoute.dashboard), child: Text('Dashboard', style: link)),
        sep,
        InkWell(onTap: onBack, child: Text('Quản lý Cua', style: link)),
        sep,
        Text('Chi tiết cua',
            style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
      ],
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────

enum _HeaderAction { edit, history, recordMolt, markMolting, readyHarvest, markDead, exportSoftshell, cameras }

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(8)),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(136, 136),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(220, 24),
                const SizedBox(height: 10),
                bar(180, 12),
                const SizedBox(height: 22),
                bar(double.infinity, 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrabDetailHeader extends StatelessWidget {
  const _CrabDetailHeader({
    required this.crab,
    required this.profile,
    required this.token,
    required this.loading,
    required this.onBack,
    required this.onRefresh,
    required this.onMove,
    required this.onMore,
    this.onOpenArea,
    this.onOpenRow,
    this.onOpenBox,
  });

  final CrabIndividual crab;
  final CrabProfile? profile;
  final String token;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onMove;
  final ValueChanged<_HeaderAction> onMore;
  final VoidCallback? onOpenArea;
  final VoidCallback? onOpenRow;
  final VoidCallback? onOpenBox;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (profile?.imageUrls.isNotEmpty ?? false) || (profile?.avatarUrl?.isNotEmpty ?? false);
    final lot = crab.batchId.trim().isEmpty ? (profile?.lotCode ?? '') : crab.batchId;
    final alive = crab.lifecycleStatus != CrabLifecycleStatus.dead &&
        crab.lifecycleStatus != CrabLifecycleStatus.harvested;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 900;
          final photoSize = compact ? 96.0 : 136.0;
          final photo = ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: photoSize,
              height: photoSize,
              color: DashboardColors.mint,
              alignment: Alignment.center,
              child: hasPhoto
                  ? CrabAuthImage(
                      crabId: crab.id,
                      index: 0,
                      token: token,
                      fallbackUrl: profile?.avatarUrl ?? profile?.imageUrls.firstOrNull,
                      width: photoSize,
                      height: photoSize,
                      fit: BoxFit.cover,
                      error: const Icon(Icons.set_meal_rounded, size: 40, color: DashboardColors.brand),
                    )
                  : const Icon(Icons.set_meal_rounded, size: 40, color: DashboardColors.brand),
            ),
          );

          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(crab.code,
                      style: bvText(fontSize: 24, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                  CrabLifecycleBadge(status: crab.lifecycleStatus),
                  CrabHealthBadge(status: crab.displayHealth),
                  if (loading) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(crab.crabType, style: bvText(fontSize: 13, color: DashboardColors.textMuted)),
                  Text('  •  ', style: bvText(fontSize: 13, color: DashboardColors.textMuted)),
                  Text('Giới tính: ', style: bvText(fontSize: 13, color: DashboardColors.textMuted)),
                  CrabGenderBadge(gender: crab.gender),
                ],
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MgmtOutlineButton(
                icon: Icons.arrow_back_rounded,
                label: 'Quay lại',
                onTap: onBack,
                color: DashboardColors.textPrimary,
                borderColor: DashboardColors.cardBorder,
              ),
              MgmtOutlineButton(icon: Icons.swap_horiz_rounded, label: 'Chuyển hộp', onTap: alive ? onMove : null),
              PopupMenuButton<_HeaderAction>(
                tooltip: 'Thao tác khác',
                offset: const Offset(0, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                onSelected: onMore,
                itemBuilder: (_) => [
                  _item(_HeaderAction.edit, Icons.edit_outlined, 'Chỉnh sửa thông tin'),
                  _item(_HeaderAction.history, Icons.history_rounded, 'Xem lịch sử'),
                  if (alive) _item(_HeaderAction.markMolting, Icons.autorenew_rounded, 'Đánh dấu lột xác'),
                  if (alive) _item(_HeaderAction.readyHarvest, Icons.flag_outlined, 'Đánh dấu sắp thu hoạch'),
                  _item(_HeaderAction.recordMolt, Icons.history_edu_outlined, 'Ghi nhận lần lột xác'),
                  _item(_HeaderAction.cameras, Icons.videocam_outlined, 'Camera hộp'),
                  if (crab.lifeStatus == CrabLifeStatus.raising)
                    _item(_HeaderAction.exportSoftshell, Icons.outbox_outlined, 'Xuất cua lột'),
                  if (alive) const PopupMenuDivider(height: 8),
                  if (alive) _item(_HeaderAction.markDead, Icons.dangerous_outlined, 'Đánh dấu chết', danger: true),
                ],
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DashboardColors.cardBorder),
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.more_horiz_rounded, size: 20, color: DashboardColors.textPrimary),
                ),
              ),
            ],
          );

          final meta = _MetaStrip(
            compact: compact,
            items: [
              _MetaItem(
                Icons.place_outlined,
                'Vị trí hiện tại',
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _link(crab.areaLabel, onOpenArea),
                    _chev(),
                    _link(crab.rowLabel, onOpenRow),
                    _chev(),
                    _link(crab.boxLabel, onOpenBox),
                  ],
                ),
              ),
              _MetaItem(Icons.inventory_2_outlined, 'Lô cua', _val(lot.isEmpty ? 'Chưa gắn lô' : lot)),
              _MetaItem(
                Icons.calendar_today_outlined,
                'Nhập trại',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _val(fmtDateVn(crab.releaseDate)),
                    Text('(${crab.ageDays} ngày trong hệ thống)',
                        style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
                  ],
                ),
              ),
              _MetaItem(Icons.autorenew_rounded, 'Số lần lột xác', _val('${crab.moltCount}')),
              _MetaItem(Icons.monitor_weight_outlined, 'Cân nặng', _val(crab.weightLabel)),
              _MetaItem(Icons.straighten_outlined, 'Kích thước', _val(crab.sizeLabel)),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  photo,
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: identity),
                            const SizedBox(width: 12),
                            actions,
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (!compact) meta,
                      ],
                    ),
                  ),
                ],
              ),
              if (compact) ...[const SizedBox(height: 14), meta],
            ],
          );
        },
      ),
    );
  }

  PopupMenuItem<_HeaderAction> _item(_HeaderAction a, IconData icon, String label, {bool danger = false}) {
    final c = danger ? DashboardColors.risk : DashboardColors.textPrimary;
    return PopupMenuItem(
      value: a,
      height: 38,
      child: Row(
        children: [
          Icon(icon, size: 16, color: danger ? DashboardColors.risk : DashboardColors.textMuted),
          const SizedBox(width: 8),
          Text(label, style: bvText(fontSize: 13, color: c, fontWeight: danger ? FontWeight.w700 : null)),
        ],
      ),
    );
  }

  Widget _val(String v) =>
      Text(v, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary));

  Widget _chev() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Icon(Icons.chevron_right_rounded, size: 15, color: DashboardColors.textMuted),
      );

  Widget _link(String text, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
          child: Text(
            text.isEmpty ? '—' : text,
            style: bvText(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: onTap == null ? DashboardColors.textPrimary : DashboardColors.brand,
            ),
          ),
        ),
      );
}

class _MetaItem {
  const _MetaItem(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final Widget value;
}

/// Dải metadata ngang trên header (grid 2 cột khi hẹp).
class _MetaStrip extends StatelessWidget {
  const _MetaStrip({required this.items, required this.compact});

  final List<_MetaItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget cell(_MetaItem it) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(it.icon, size: 16, color: DashboardColors.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.label, style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
                  const SizedBox(height: 3),
                  it.value,
                ],
              ),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: compact
          ? LayoutBuilder(
              builder: (context, c) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final it in items) SizedBox(width: (c.maxWidth - 12) / 2, child: cell(it))],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Expanded(flex: i == 0 ? 5 : 3, child: cell(items[i])),
                  if (i < items.length - 1)
                    Container(width: 1, height: 34, color: DashboardColors.mint, margin: const EdgeInsets.symmetric(horizontal: 10)),
                ],
              ],
            ),
    );
  }
}

// ── Tab bar ──────────────────────────────────────────────────────────────

class _DetailTabBar extends StatelessWidget {
  const _DetailTabBar({required this.value, required this.onChanged});

  final CrabDetailTab value;
  final ValueChanged<CrabDetailTab> onChanged;

  static const _labels = {
    CrabDetailTab.overview: ('Tổng quan', Icons.dashboard_outlined),
    CrabDetailTab.growth: ('Sinh trưởng & Lột xác', Icons.trending_up_rounded),
    CrabDetailTab.feeding: ('Ăn & Vận động', Icons.restaurant_rounded),
    CrabDetailTab.history: ('Lịch sử & Nhật ký', Icons.history_rounded),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DashboardColors.mint, width: 1.5)),
      ),
      child: Row(
        children: [
          for (final t in CrabDetailTab.values)
            InkWell(
              onTap: () => onChanged(t),
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 8, 18, 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: value == t ? DashboardColors.brand : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _labels[t]!.$2,
                      size: 16,
                      color: value == t ? DashboardColors.brand : DashboardColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _labels[t]!.$1,
                      style: bvText(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: value == t ? DashboardColors.brand : DashboardColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab: Tổng quan ───────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.crab,
    required this.profile,
    required this.loading,
    required this.feeding,
    required this.box,
    required this.boxLoading,
    required this.onOpenFeeding,
    required this.onOpenHistory,
    required this.onEdit,
    required this.onEditNote,
    required this.onAddFeeding,
    required this.onTapActivity,
    this.onOpenArea,
    this.onOpenRow,
    this.onOpenBox,
  });

  final CrabIndividual crab;
  final CrabProfile? profile;
  final bool loading;
  final CrabFeedingActivityController feeding;
  final BoxRecord? box;
  final bool boxLoading;
  final VoidCallback onOpenFeeding;
  final VoidCallback onOpenHistory;
  final VoidCallback onEdit;
  final VoidCallback onEditNote;
  final VoidCallback onAddFeeding;
  final ValueChanged<CrabActivityItem> onTapActivity;
  final VoidCallback? onOpenArea;
  final VoidCallback? onOpenRow;
  final VoidCallback? onOpenBox;

  @override
  Widget build(BuildContext context) {
    final note = _cleanNote(crab.quickNote) ?? _cleanNote(profile?.notes);

    final basic = CrabBasicInfoCard(crab: crab, profile: profile, onEdit: onEdit, loading: loading);
    final status = CrabStatusCard(crab: crab, profile: profile, loading: loading);
    final feedingCard = CrabFeedingSummaryCard(
      controller: feeding,
      onOpenAnalysis: onOpenFeeding,
      onAddFeeding: onAddFeeding,
    );
    final location = CrabLocationCard(
      crab: crab,
      profile: profile,
      box: box,
      boxLoading: boxLoading,
      onOpenArea: onOpenArea,
      onOpenRow: onOpenRow,
      onOpenBox: onOpenBox,
    );
    final ai = CrabAIAlertCard(
      crab: crab,
      profile: profile,
      feeding: feeding,
      loading: loading,
      onViewHistory: onOpenHistory,
    );
    final activity = AnimatedBuilder(
      animation: feeding,
      builder: (_, __) => CrabRecentActivity(
        items: buildRecentActivity(profile, feeding.data),
        loading: loading || (feeding.loading && feeding.data == null),
        onViewAll: onOpenHistory,
        onTapItem: onTapActivity,
      ),
    );
    final noteCard = CrabNoteCard(note: note, onEdit: onEditNote, loading: loading);

    return LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          if (w >= 1040) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 32,
                      child: Column(children: [basic, const SizedBox(height: 14), status]),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 68,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          feedingCard,
                          const SizedBox(height: 14),
                          location,
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: ai),
                              const SizedBox(width: 14),
                              Expanded(child: activity),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                noteCard,
              ],
            );
          }
          if (w >= 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: Column(children: [basic, const SizedBox(height: 14), status])),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [feedingCard, const SizedBox(height: 14), location, const SizedBox(height: 14), ai],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                activity,
                const SizedBox(height: 14),
                noteCard,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final card in [basic, feedingCard, status, location, ai, activity, noteCard]) ...[
                card,
                const SizedBox(height: 14),
              ],
            ],
          );
        },
    );
  }

  static String? _cleanNote(String? s) {
    final t = (s ?? '').trim();
    if (t.isEmpty || t.toLowerCase() == 'null' || t.toLowerCase() == 'undefined') return null;
    return t;
  }
}

