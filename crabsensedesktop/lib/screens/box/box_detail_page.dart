import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/box_alert.dart';
import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/area_environment_service.dart';
import '../../services/camera_device_service.dart';
import '../../services/controller_service.dart';
import '../../services/crab_profile_service.dart';
import '../../services/crab_service.dart';
import '../../services/production_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/box/detail/box_alert_tab.dart';
import '../../widgets/box/detail/box_camera_ai_tab.dart';
import '../../widgets/box/detail/box_history_tab.dart';
import '../../widgets/box/detail/box_crab_tab.dart';
import '../../widgets/box/detail/box_detail_header.dart';
import '../../widgets/box/detail/box_labels.dart';
import '../../widgets/box/detail/box_overview_tab.dart';
import '../../widgets/box/detail/box_sensor_tab.dart';
import '../../widgets/crab/add/add_crab_modal.dart';
import '../../widgets/crab/crab_action_modals.dart';
import '../../widgets/crab/feeding/add_feeding_modal.dart';
import '../../widgets/production/production_dialogs.dart';
import '../../widgets/shared/mgmt_ui.dart';

class BoxDetailPage extends StatefulWidget {
  const BoxDetailPage({
    super.key,
    required this.box,
    required this.areaName,
    required this.rowName,
    required this.crabProfileService,
    required this.cameraService,
    required this.areaEnvironmentService,
    required this.areaId,
    this.areaCode,
    this.rowId,
    this.rowCode,
    this.onBack,
    this.onNavigate,
    this.onOpenArea,
    this.onOpenRow,
    this.onOpenCrab,
    this.onBoxUpdated,
    this.productionService,
    this.crabService,
    this.controllerService,
    this.initialTab = 0,
  });

  final BoxRecord box;
  final String areaId;
  final String? areaCode;
  final String areaName;
  final String? rowId;
  final String? rowCode;
  final String rowName;
  final CrabProfileService crabProfileService;
  final CameraDeviceService cameraService;
  final AreaEnvironmentService areaEnvironmentService;
  final VoidCallback? onBack;
  final void Function(AppRoute route)? onNavigate;
  final VoidCallback? onOpenArea;
  final VoidCallback? onOpenRow;
  final void Function(String crabId, {BoxOpenCrabTarget target})? onOpenCrab;
  final ValueChanged<BoxRecord>? onBoxUpdated;
  final ProductionManagementService? productionService;
  final CrabService? crabService;
  final ControllerService? controllerService;
  final int initialTab;

  @override
  State<BoxDetailPage> createState() => _BoxDetailPageState();
}

class _BoxDetailPageState extends State<BoxDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late BoxRecord _box;
  List<BoxAlert> _alerts = const [];
  List<BoxActivityItem> _activities = const [];
  List<BoxActivityItem> _fetchedActivities = const [];
  var _alertsLoading = false;
  var _activityLoading = false;
  var _locking = false;
  String? _pageError;

  CrabProfileService get _svc => widget.crabProfileService;
  CrabProfileData? get _crab => _svc.data;

  @override
  void initState() {
    super.initState();
    _box = widget.box;
    _tabs = TabController(length: 6, vsync: this, initialIndex: widget.initialTab.clamp(0, 5));
    _svc.addListener(_onUpdate);
    widget.cameraService.addListener(_onUpdate);
    widget.areaEnvironmentService.addListener(_onUpdate);
    widget.controllerService?.addListener(_onUpdate);
    _reload();
  }

  @override
  void didUpdateWidget(covariant BoxDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.box.id != widget.box.id) {
      _box = widget.box;
      _reload();
    }
    if (oldWidget.initialTab != widget.initialTab) {
      _tabs.animateTo(widget.initialTab.clamp(0, 5));
    }
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    widget.cameraService.removeListener(_onUpdate);
    widget.areaEnvironmentService.removeListener(_onUpdate);
    widget.controllerService?.removeListener(_onUpdate);
    widget.areaEnvironmentService.stopLiveRefresh(notify: false);
    _tabs.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(_composeActivities);
    });
  }

  Future<void> _reload() async {
    setState(() => _pageError = null);
    widget.cameraService.loadCamerasByBox(_box.id);
    widget.areaEnvironmentService.startLiveRefreshByBox(_box.id);
    final ctrl = widget.controllerService;
    if (ctrl != null && ctrl.items.isEmpty && !ctrl.loading) {
      ctrl.load();
    }
    await Future.wait([
      _svc.loadByBox(_box.id),
      _loadAlerts(),
    ]);
    if (!mounted) return;
    await _loadActivity();
  }

  Future<void> _loadAlerts() async {
    setState(() => _alertsLoading = true);
    try {
      final rows = await _svc.fetchBoxAlerts(boxId: _box.id, farmingAreaId: widget.areaId);
      if (!mounted) return;
      setState(() {
        _alerts = rows.map(_alertFromJson).toList()
          ..sort((a, b) => (b.occurredAt ?? DateTime(0)).compareTo(a.occurredAt ?? DateTime(0)));
        _alertsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alerts = const [];
        _alertsLoading = false;
      });
    }
  }

  Future<void> _loadActivity() async {
    setState(() => _activityLoading = true);
    final items = <BoxActivityItem>[];
    try {
      final rows = await _svc.fetchBoxStatusHistory(_box.id);
      for (final raw in rows) {
        final at = DateTime.tryParse((raw['changedAt'] ?? raw['ChangedAt'] ?? '').toString());
        if (at == null) continue;
        final reason = (raw['reason'] ?? raw['Reason'] ?? '').toString();
        final next = (raw['newStatus'] ?? raw['NewStatus'] ?? '').toString();
        items.add(BoxActivityItem(
          at: at.toLocal(),
          title: reason.trim().isEmpty ? 'Cập nhật trạng thái hộp' : reason,
          detail: next.isEmpty ? '' : 'Trạng thái: ${boxOperationalLabel(next)}',
          source: 'System',
        ));
      }
    } catch (_) {}

    final crabId = _svc.data?.id;
    if (crabId != null && crabId.isNotEmpty) {
      try {
        final page = await _svc.fetchCrabLifecycle(crabId);
        for (final e in page.items) {
          items.add(BoxActivityItem(
            at: e.occurredAt.isUtc ? e.occurredAt.toLocal() : e.occurredAt,
            title: e.title.trim().isEmpty ? e.eventType.label : e.title,
            detail: e.summary,
            source: _activitySource(e.source, e.actor.name),
          ));
        }
      } catch (_) {}
      try {
        final growth = await _svc.fetchCrabGrowth(crabId);
        for (final m in growth.measurements) {
          final parts = <String>[
            'Cân nặng: ${m.weightGram.toStringAsFixed(0)} g',
            if (m.shellWidthMm != null && m.shellWidthMm! > 0) 'Rộng mai: ${m.shellWidthMm!.toStringAsFixed(0)} mm',
            if (m.shellLengthMm != null && m.shellLengthMm! > 0) 'Dài mai: ${m.shellLengthMm!.toStringAsFixed(0)} mm',
          ];
          items.add(BoxActivityItem(
            at: m.measuredAt.isUtc ? m.measuredAt.toLocal() : m.measuredAt,
            title: 'Cập nhật sinh trưởng',
            detail: parts.join('  ·  '),
            source: (m.recordedBy ?? '').trim().isEmpty ? 'Admin' : m.recordedBy!,
          ));
        }
        for (final molt in growth.molts) {
          items.add(BoxActivityItem(
            at: molt.at,
            title: 'Lột xác',
            detail: molt.status.label,
            source: molt.sourceLabel,
          ));
        }
      } catch (_) {}
    }

    try {
      final ops = await _svc.fetchAreaOperations(widget.areaId);
      for (final raw in ops) {
        if (!_operationMatchesBox(raw)) continue;
        final at = DateTime.tryParse((raw['timestamp'] ?? raw['Timestamp'] ?? '').toString());
        if (at == null) continue;
        items.add(BoxActivityItem(
          at: at.toLocal(),
          title: (raw['type'] ?? raw['Type'] ?? raw['title'] ?? raw['Title'] ?? 'Hoạt động').toString(),
          detail: (raw['notes'] ?? raw['Notes'] ?? raw['description'] ?? raw['Description'] ?? '').toString(),
          source: (raw['operatorName'] ?? raw['OperatorName'] ?? 'Admin').toString(),
        ));
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _fetchedActivities = items;
      _activityLoading = false;
      _composeActivities();
    });
  }

  bool _operationMatchesBox(Map<String, dynamic> raw) {
    final ids = raw['boxIds'] ?? raw['BoxIds'];
    if (ids is List && ids.map((e) => e.toString()).contains(_box.id)) return true;
    final one = (raw['boxId'] ?? raw['BoxId'] ?? '').toString();
    if (one == _box.id) return true;
    final loc = '${raw['locationLabel'] ?? raw['LocationLabel'] ?? raw['notes'] ?? raw['Notes'] ?? ''}';
    return loc.contains(_box.boxCode);
  }

  String _activitySource(String source, String actor) {
    final s = source.toLowerCase();
    if (s.contains('sensor')) return 'Sensor';
    if (s.contains('ai')) return 'AI Camera';
    if (s.contains('controller')) return 'Controller';
    if (s.contains('manual') || actor.toLowerCase().contains('admin')) return 'Admin';
    if (actor.trim().isNotEmpty && actor.toLowerCase() != 'system') return actor;
    return 'System';
  }

  void _composeActivities() {
    final items = List<BoxActivityItem>.from(_fetchedActivities);
    final seen = <String>{
      for (final e in items) '${e.at.millisecondsSinceEpoch}|${e.title}|${e.detail}',
    };

    void add(BoxActivityItem e) {
      final key = '${e.at.millisecondsSinceEpoch}|${e.title}|${e.detail}';
      if (seen.add(key)) items.add(e);
    }

    final env = widget.areaEnvironmentService;
    final envAt = env.data?.lastUpdatedAt ?? env.lastRefreshedAt;
    if (env.metrics.isNotEmpty && envAt != null) {
      final parts = <String>[];
      for (final m in env.metrics.take(4)) {
        if (m.value == 0 && m.recordedAt == null) continue;
        final label = m.label.toLowerCase();
        final digits = label == 'ph' ? 2 : 1;
        parts.add('${m.label}: ${m.value.toStringAsFixed(digits)}${m.unit.isEmpty ? '' : ' ${m.unit}'}');
      }
      add(BoxActivityItem(
        at: envAt.isUtc ? envAt.toLocal() : envAt,
        title: 'Cập nhật số liệu môi trường',
        detail: parts.join('  ·  '),
        source: 'Sensor',
      ));
    }

    final crab = _svc.data;
    if (crab != null) {
      for (final f in crab.feedingLogs) {
        final at = DateTime.tryParse(f.fedAt);
        if (at == null) continue;
        add(BoxActivityItem(
          at: at.toLocal(),
          title: 'Cho ăn',
          detail: 'Lượng: ${f.quantity.toStringAsFixed(0)} ${f.unit}',
          source: 'Admin',
        ));
      }
      final stocked = DateTime.tryParse(crab.startDate);
      if (stocked != null) {
        add(BoxActivityItem(
          at: stocked.toLocal(),
          title: 'Phân cua vào hộp',
          detail: crab.crabCode,
          source: 'System',
        ));
      }
      if (crab.weight != null && crab.weight! > 0) {
        final at = stocked ?? DateTime.now();
        add(BoxActivityItem(
          at: at.toLocal(),
          title: 'Cập nhật sinh trưởng',
          detail: [
            'Cân nặng: ${crab.weight!.toStringAsFixed(0)} g',
            if (crab.shellWidth != null && crab.shellWidth! > 0) 'Rộng mai: ${crab.shellWidth!.toStringAsFixed(0)} mm',
            if (crab.shellLength != null && crab.shellLength! > 0) 'Dài mai: ${crab.shellLength!.toStringAsFixed(0)} mm',
          ].join('  ·  '),
          source: 'Admin',
        ));
      }
    }

    final cam = widget.cameraService.cameras.where((c) => c.lastSeenAt != null).firstOrNull;
    if (cam?.lastSeenAt != null) {
      add(BoxActivityItem(
        at: cam!.lastSeenAt!,
        title: 'Camera AI',
        detail: cam.isOnline ? 'Không phát hiện bất thường' : 'Camera mất kết nối',
        source: 'AI Camera',
      ));
    }

    for (final a in _alerts.take(8)) {
      if (a.occurredAt == null) continue;
      final resolved = a.statusLabel == 'Đã xử lý' || a.statusLabel == 'Đã khôi phục';
      add(BoxActivityItem(
        at: a.occurredAt!,
        title: resolved ? 'Cảnh báo đã được xử lý' : a.message,
        detail: resolved ? a.message : a.statusLabel,
        source: 'Hệ thống cảnh báo',
      ));
    }

    items.sort((a, b) => b.at.compareTo(a.at));
    _activities = items;
  }

  BoxAlert _alertFromJson(Map<String, dynamic> json) {
    final sev = (json['severity'] ?? json['Severity'] ?? 'info').toString().toLowerCase();
    final at = DateTime.tryParse((json['createdAt'] ?? json['CreatedAt'] ?? '').toString());
    return BoxAlert(
      severity: sev.contains('crit') ? 'critical' : (sev.contains('warn') ? 'warning' : 'info'),
      message: (json['message'] ?? json['Message'] ?? json['title'] ?? json['Title'] ?? '').toString(),
      time: at == null ? '' : fmtDateTimeVn(at),
      status: (json['status'] ?? json['Status'] ?? 'open').toString(),
      occurredAt: at?.toLocal(),
    );
  }

  String get _rowLabel {
    final name = widget.rowName.trim();
    final code = (widget.rowCode ?? _box.rowCode ?? '').trim();
    if (name.isNotEmpty) return name;
    return code;
  }

  String get _areaCode => (widget.areaCode ?? _box.areaCode ?? '').trim();

  String get _sensorStatus {
    final env = widget.areaEnvironmentService;
    if (env.error != null && env.metrics.isEmpty) return 'offline';
    if (env.metrics.isEmpty) return 'offline';
    if (isSensorStale(env.data?.lastUpdatedAt ?? env.lastRefreshedAt)) return 'degraded';
    return 'online';
  }

  String get _controllerStatus {
    final items = widget.controllerService?.items ?? const [];
    if (items.isEmpty) return 'offline';
    if (items.any((d) => d.isOnline)) return 'online';
    return 'offline';
  }

  String? get _sensorSource {
    for (final m in widget.areaEnvironmentService.metrics) {
      final code = (m.sensorCode ?? '').trim();
      if (code.isNotEmpty) return code;
    }
    return null;
  }

  String get _sensorNote {
    final row = _rowLabel;
    if (widget.areaEnvironmentService.data?.inheritedByBox == true || widget.areaEnvironmentService.metrics.isNotEmpty) {
      return row.isEmpty ? 'Nước tuần hoàn của khu vực.' : 'Nước tuần hoàn dãy $row';
    }
    return 'Nguồn cảm biến của hộp.';
  }

  Future<void> _editBox() async {
    final prod = widget.productionService;
    if (prod == null) return;
    if (widget.areaId.isNotEmpty) prod.selectArea(widget.areaId);
    if ((widget.rowId ?? _box.rowId).isNotEmpty) prod.selectRow(widget.rowId ?? _box.rowId);
    await showBoxFormDialog(context, prod, existing: _box);
    if (!mounted) return;
    try {
      await prod.loadBoxes();
      final next = prod.boxes.where((b) => b.id == _box.id).firstOrNull;
      if (next != null) {
        setState(() => _box = next);
        widget.onBoxUpdated?.call(next);
      }
    } catch (_) {}
  }

  Future<void> _toggleLock() async {
    final prod = widget.productionService;
    if (prod == null) return;
    final locked = isBoxLocked(_box.status);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(locked ? 'Mở khóa ${_box.boxCode}?' : 'Khóa ${_box.boxCode}?', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text(
          locked
              ? 'Hộp sẽ trở lại trạng thái hoạt động.'
              : (_box.hasCrab || _crab != null)
                  ? 'Hộp đang chứa cua. Khi khóa sẽ không cho thêm hoặc chuyển cua vào hộp này.'
                  : 'Khi khóa sẽ không cho thêm hoặc chuyển cua vào hộp này.',
          style: bvText(color: DashboardColors.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
            child: Text(locked ? 'Mở khóa' : 'Khóa hộp'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _locking = true);
    try {
      final nextStatus = locked ? ((_box.hasCrab || _crab != null) ? 'active' : 'empty') : 'maintenance';
      final updated = await prod.updateBox(_box, boxCode: _box.boxCode, position: _box.position, volume: _box.volume, status: nextStatus);
      if (!mounted) return;
      setState(() {
        _box = updated;
        _locking = false;
      });
      widget.onBoxUpdated?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locked ? 'Đã mở khóa ${_box.boxCode}.' : 'Đã khóa ${_box.boxCode}.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _locking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addCrab() async {
    final svc = widget.crabService;
    if (svc == null) {
      widget.onNavigate?.call(AppRoute.productionCrabManagement);
      return;
    }
    if (isBoxLocked(_box.status)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hộp đang khóa, không thể thêm cua.')));
      return;
    }
    if (widget.areaId.isNotEmpty) svc.setAreaFilter(widget.areaId);
    final ok = await showAddCrabModal(
      context,
      svc,
      onManageLots: () {
        Navigator.of(context).maybePop();
        widget.onNavigate?.call(AppRoute.inboundLots);
      },
    );
    if (ok && mounted) _reload();
  }

  Future<void> _more(BoxHeaderAction a) async {
    switch (a) {
      case BoxHeaderAction.qr:
      case BoxHeaderAction.print:
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(_box.boxCode, style: bvText(fontSize: 18, fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 120, color: DashboardColors.brand),
                const SizedBox(height: 8),
                Text('QR-${_box.boxCode}', style: bvText(fontWeight: FontWeight.w700)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _box.boxCode));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Sao chép mã'),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            ],
          ),
        );
      case BoxHeaderAction.history:
        _tabs.animateTo(5);
      case BoxHeaderAction.transfer:
        await _transferCrab();
      case BoxHeaderAction.maintenance:
        if (!isBoxLocked(_box.status)) await _toggleLock();
      case BoxHeaderAction.delete:
        if (!await confirmDelete(context, title: 'Xóa hộp?', message: '${_box.boxCode}?')) return;
        final prod = widget.productionService;
        if (prod == null) return;
        try {
          await prod.deleteBox(_box);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa ${_box.boxCode}.')));
          widget.onBack?.call();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
    }
  }

  void _openCrab({BoxOpenCrabTarget target = BoxOpenCrabTarget.overview}) {
    final id = (_crab?.id ?? _box.crabId ?? '').trim();
    if (id.isEmpty || id == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã cua trong hộp này.')),
      );
      return;
    }
    widget.onOpenCrab?.call(id, target: target);
  }

  Future<void> _transferCrab() async {
    final svc = widget.crabService;
    final id = _crab?.id ?? _box.crabId;
    if (svc == null || id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hộp chưa có cua để chuyển.')));
      return;
    }
    await svc.loadDetail(id);
    final crab = svc.getById(id);
    if (crab == null || !mounted) return;
    final ok = await showMoveCrabModal(context, svc, crab);
    if (ok && mounted) _reload();
  }

  Future<void> _addFeeding() async {
    final svc = widget.crabService;
    final crab = _crab;
    if (svc == null || crab == null || crab.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy cua để ghi nhận cho ăn.')));
      return;
    }
    final input = await showAddFeedingModal(
      context,
      crabCode: crab.crabCode,
      boxLabel: _box.boxCode,
      boxId: _box.id,
      token: svc.token,
      api: svc.api,
      cameras: widget.cameraService.cameras,
    );
    if (input == null || !mounted) return;
    try {
      await _svc.recordFeeding(
        crabId: crab.id!,
        boxId: _box.id,
        input: input,
        operatorName: svc.operatorName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã ghi nhận cho ăn.')));
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialLoading = _svc.loading && _crab == null && _alertsLoading;
    return ColoredBox(
      color: const Color(0xFFF7FCFA),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              children: [
                BoxDetailBreadcrumb(
                  areaName: widget.areaName,
                  rowName: _rowLabel,
                  boxCode: _box.boxCode,
                  onBoxes: widget.onBack ?? () => widget.onNavigate?.call(AppRoute.boxManagement),
                  onArea: widget.onOpenArea,
                  onRow: widget.onOpenRow,
                ),
                const SizedBox(height: 12),
                if (initialLoading)
                  const BoxDetailSkeleton()
                else if (_pageError != null)
                  MgmtEmptyState(
                    icon: Icons.warning_amber_rounded,
                    title: 'Không thể tải thông tin hộp.',
                    message: _pageError!,
                    action: MgmtPrimaryButton(icon: Icons.refresh_rounded, label: 'Thử lại', height: 38, onTap: _reload),
                  )
                else ...[
                  BoxDetailHeader(
                    box: _box,
                    areaName: widget.areaName,
                    rowName: _rowLabel,
                    hasCrab: _box.hasCrab || _crab != null,
                    locked: isBoxLocked(_box.status),
                    locking: _locking,
                    onEdit: widget.productionService == null ? null : _editBox,
                    onLock: widget.productionService == null ? null : _toggleLock,
                    onMore: _more,
                  ),
                  const SizedBox(height: 12),
                  BoxMetaBar(
                    box: _box,
                    areaCode: _areaCode,
                    rowLabel: _rowLabel,
                    updatedAt: widget.areaEnvironmentService.lastRefreshedAt ?? _box.aiUpdatedAt,
                  ),
                  const SizedBox(height: 8),
                  BoxDetailTabBar(controller: _tabs),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _tabs,
                    builder: (_, __) => _tabBody(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBody() {
    switch (_tabs.index) {
      case 0:
        return BoxOverviewTab(
          box: _box,
          areaName: widget.areaName,
          rowLabel: _rowLabel,
          crab: _crab,
          crabLoading: _svc.loading && _crab == null,
          token: _svc.token,
          controllerStatus: _controllerStatus,
          sensorStatus: _sensorStatus,
          camera: widget.cameraService.cameras.firstOrNull,
          cameraLoading: widget.cameraService.loading && widget.cameraService.cameras.isEmpty,
          metrics: widget.areaEnvironmentService.metrics,
          envLoading: widget.areaEnvironmentService.loading && widget.areaEnvironmentService.metrics.isEmpty,
          envError: widget.areaEnvironmentService.error,
          envUpdatedAt: widget.areaEnvironmentService.data?.lastUpdatedAt ?? widget.areaEnvironmentService.lastRefreshedAt,
          sensorSourceCode: _sensorSource,
          sensorSourceNote: _sensorNote,
          alerts: _alerts,
          alertsLoading: _alertsLoading,
          activities: _activities,
          activitiesLoading: _activityLoading,
          onOpenCrab: () => _openCrab(),
          onOpenCrabGrowth: () => _openCrab(target: BoxOpenCrabTarget.growth),
          onAddCrab: _addCrab,
          onManageLots: () => widget.onNavigate?.call(AppRoute.inboundLots),
          onOpenCamera: () => _tabs.animateTo(3),
          onOpenSensors: () => _tabs.animateTo(2),
          onOpenAlerts: () => _tabs.animateTo(4),
          onOpenHistory: () => _tabs.animateTo(5),
        );
      case 1:
        return BoxCrabTab(
          box: _box,
          crab: _crab,
          crabLoading: _svc.loading && _crab == null,
          crabError: _svc.error,
          profileService: _svc,
          token: _svc.token,
          camera: widget.cameraService.cameras.firstOrNull,
          cameraLoading: widget.cameraService.loading && widget.cameraService.cameras.isEmpty,
          alerts: _alerts,
          onOpenCrab: (id, {target = BoxOpenCrabTarget.overview}) => _openCrab(target: target),
          onTransferCrab: _transferCrab,
          onAddCrab: _addCrab,
          onManageLots: () => widget.onNavigate?.call(AppRoute.inboundLots),
          onAddFeeding: _addFeeding,
          onOpenCamera: () => _tabs.animateTo(3),
          onOpenHistory: () => _tabs.animateTo(5),
          onRetryCrab: _reload,
        );
      case 2:
        return BoxSensorTab(
          box: _box,
          service: widget.areaEnvironmentService,
          areaId: widget.areaId,
          areaName: widget.areaName,
          areaCode: _areaCode,
          rowLabel: _rowLabel,
          controllerStatus: _controllerStatus,
          alerts: _alerts,
          alertsLoading: _alertsLoading,
          onOpenSource: () => widget.onNavigate?.call(AppRoute.controllers),
          onOpenWaterAnalysis: () => widget.onNavigate?.call(AppRoute.waterAnalysis),
          onOpenAlerts: () => _tabs.animateTo(4),
        );
      case 3:
        return BoxCameraAITab(
          box: _box,
          cameraService: widget.cameraService,
          profileService: _svc,
          areaCode: _areaCode,
          rowLabel: _rowLabel,
          crabCode: _crab?.crabCode ?? _box.crabTag,
          onManageCamera: () => widget.onNavigate?.call(AppRoute.controllers),
          onOpenAlerts: () => _tabs.animateTo(4),
          onOpenAllHistory: () => widget.onNavigate?.call(AppRoute.cameraAi),
        );
      case 4:
        return BoxAlertTab(
          box: _box,
          profileService: _svc,
          areaId: widget.areaId,
          areaCode: _areaCode,
          areaName: widget.areaName,
          crabCode: _crab?.crabCode ?? _box.crabTag,
          cameraCode: widget.cameraService.cameras.firstOrNull?.cameraCode,
          sensorCodes: [
            for (final m in widget.areaEnvironmentService.metrics)
              if ((m.sensorCode ?? '').trim().isNotEmpty) m.sensorCode!,
          ],
          inheritedSensor: widget.areaEnvironmentService.data?.inheritedByBox ?? true,
          onAlertsChanged: () {
            _loadAlerts();
            _loadActivity();
          },
          onOpenCamera: () => _tabs.animateTo(3),
          onOpenSensors: () => _tabs.animateTo(2),
          onOpenCrab: () => _openCrab(),
          onOpenDevice: () => widget.onNavigate?.call(AppRoute.controllers),
          onOpenHistory: () => _tabs.animateTo(5),
        );
      default:
        return BoxHistoryTab(
          box: _box,
          profileService: _svc,
          areaId: widget.areaId,
          areaCode: _areaCode,
          areaName: widget.areaName,
          rowLabel: _rowLabel,
          crabId: _crab?.id ?? _box.crabId,
          crabCode: _crab?.crabCode ?? _box.crabTag,
          camera: widget.cameraService.cameras.firstOrNull,
          onOpenCrab: (id) => widget.onOpenCrab?.call(id),
          onOpenCamera: () => _tabs.animateTo(3),
          onOpenSensors: () => _tabs.animateTo(2),
          onOpenAlerts: () => _tabs.animateTo(4),
        );
    }
  }

}
