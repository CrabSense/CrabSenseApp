import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/area_environment_service.dart';
import '../../services/area_management_service.dart';
import '../../services/ras_flow_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_form_dialog.dart';
import '../../widgets/area/area_detail_widgets.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/environment/area_environment_panel.dart';

class AreaDetailPage extends StatefulWidget {
  const AreaDetailPage({
    super.key,
    required this.service,
    required this.areaEnvironmentService,
    required this.rasFlowService,
    required this.areaId,
    required this.onBack,
    this.onNavigate,
  });

  final AreaManagementService service;
  final AreaEnvironmentService areaEnvironmentService;
  final RasFlowService rasFlowService;
  final String areaId;
  final VoidCallback onBack;
  final void Function(AppRoute route)? onNavigate;

  @override
  State<AreaDetailPage> createState() => _AreaDetailPageState();
}

class _AreaDetailPageState extends State<AreaDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  AreaRecord? _detail;
  List<RowRecord> _rows = [];
  List<BoxRecord> _boxes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(_onTabChanged);
    _load();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    _syncLiveForTab(_tabs.index);
    if (mounted) setState(() {});
  }

  void _syncLiveForTab(int index) {
    widget.rasFlowService.stopLiveRefresh();
    widget.areaEnvironmentService.stopLiveRefresh(notify: false);
    if (index == 3) {
      widget.areaEnvironmentService.startLiveRefresh(widget.areaId);
    }
  }

  @override
  void dispose() {
    widget.rasFlowService.stopLiveRefresh(notify: false);
    widget.areaEnvironmentService.stopLiveRefresh(notify: false);
    _tabs.removeListener(_onTabChanged);
    super.dispose();
    _tabs.dispose();
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
        _rows = r.rows;
        _boxes = r.boxes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _editArea(AreaRecord d) {
    showAreaFormDialog(context, widget.service, existing: d).then((_) {
      if (mounted) _load();
    });
  }

  void _report() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo cáo khu — đang phát triển')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: GoogleFonts.notoSans(color: DashboardColors.risk),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final d = _detail;
    if (d == null) {
      return Center(
        child: Text(
          'Không tìm thấy khu',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AreaDetailBreadcrumb(
            onDashboard: () =>
                widget.onNavigate?.call(AppRoute.dashboard),
            onAreaList: widget.onBack,
          ),
          const SizedBox(height: 16),
          AreaDetailHeader(
            area: d,
            onEdit: () => _editArea(d),
            onReport: _report,
          ),
          const SizedBox(height: 24),
          AreaDetailStatCards(area: d),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AreaDetailTabBar(controller: _tabs),
                const SizedBox(height: 8),
                SizedBox(
                  height: _tabs.index >= 3 ? 560 : 320,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      AreaDetailRowTable(rows: _rows, boxes: _boxes),
                      AreaDetailBoxTable(boxes: _boxes),
                      AreaDetailDevicePanel(
                        count: d.esp32Count,
                        title: '${d.esp32Count} ESP32',
                        deviceLabel:
            'Mở menu Điều khiển thiết bị để xem camera gắn hộp',
                      ),
                      AreaEnvironmentPanel(
                        service: widget.areaEnvironmentService,
                        areaId: widget.areaId,
                        areaName: d.areaName,
                        areaCode: d.areaCode,
                        showInheritedHint: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AreaDetailBottomPanels(
            areaName: d.areaName,
            areaCode: d.areaCode,
          ),
        ],
      ),
    );
  }
}
