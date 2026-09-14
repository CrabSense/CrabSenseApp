import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../models/camera_device.dart';
import '../../models/box_alert.dart';
import '../../models/area_environment_metric.dart';
import '../../services/area_environment_service.dart';
import '../../services/crab_profile_service.dart';
import '../../services/camera_device_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/camera_stream_url_helper.dart';
import '../../widgets/camera/camera_connect_test_dialog.dart';
import '../../widgets/camera/camera_stream_player.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/environment/area_environment_panel.dart';

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
    this.onBack,
  });

  final BoxRecord box;
  final String areaId;
  final String? areaCode;
  final String areaName;
  final String rowName;
  final CrabProfileService crabProfileService;
  final CameraDeviceService cameraService;
  final AreaEnvironmentService areaEnvironmentService;
  final VoidCallback? onBack;

  @override
  State<BoxDetailPage> createState() => _BoxDetailPageState();
}

class _BoxDetailPageState extends State<BoxDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BoxAlert> _alerts = const [];
  var _alertsLoading = false;

  CrabProfileService get _svc => widget.crabProfileService;
  CrabProfileData? get _crab => _svc.data;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _svc.addListener(_onUpdate);
    _svc.loadByBox(widget.box.id);
    _loadAlerts();
    widget.cameraService.addListener(_onUpdate);
    widget.cameraService.loadCamerasByBox(widget.box.id);
    widget.areaEnvironmentService.addListener(_onUpdate);
    widget.areaEnvironmentService.startLiveRefreshByBox(widget.box.id);
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    widget.cameraService.removeListener(_onUpdate);
    widget.areaEnvironmentService.removeListener(_onUpdate);
    widget.areaEnvironmentService.stopLiveRefresh(notify: false);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() => _alertsLoading = true);
    try {
      final rows = await _svc.fetchBoxAlerts(
        boxId: widget.box.id,
        farmingAreaId: widget.areaId,
      );
      final mapped = rows.map(_alertFromJson).toList();
      if (!mounted) return;
      setState(() {
        _alerts = mapped;
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

  BoxAlert _alertFromJson(Map<String, dynamic> json) {
    final sev = (json['severity'] ?? json['Severity'] ?? 'info')
        .toString()
        .toLowerCase();
    final at = DateTime.tryParse(
      (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
    );
    String time = '';
    if (at != null) {
      final l = at.toLocal();
      time =
          '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} '
          '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }
    return BoxAlert(
      severity: sev.contains('crit')
          ? 'critical'
          : (sev.contains('warn') ? 'warning' : 'info'),
      message: (json['message'] ??
              json['Message'] ??
              json['title'] ??
              json['Title'] ??
              '')
          .toString(),
      time: time,
    );
  }

  void _onUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  // ─── helpers ───────────────────────────────────────────────────────

  TextStyle _font({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) =>
      GoogleFonts.notoSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? DashboardColors.textPrimary,
      );

  String _fmtDateTime(String isoOrDate) {
    final d = DateTime.tryParse(isoOrDate);
    if (d == null) return isoOrDate;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fmtCurrency(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'active' || 'đang nuôi' => DashboardColors.healthy,
        'empty' || 'trống' => DashboardColors.textMuted,
        'maintenance' || 'bảo trì' => DashboardColors.monitoring,
        _ => DashboardColors.cyan,
      };

  String _statusLabel(String status) => switch (status.toLowerCase()) {
        'active' => 'Đang nuôi',
        'empty' => 'Trống',
        'maintenance' => 'Bảo trì',
        _ => status,
      };

  Color _alertColor(String severity) => switch (severity) {
        'critical' => DashboardColors.risk,
        'warning' => DashboardColors.monitoring,
        _ => DashboardColors.cyan,
      };

  IconData _envIcon(String key) => switch (key) {
        'pH' => Icons.science_outlined,
        'temp' => Icons.thermostat_outlined,
        'do' => Icons.bubble_chart_outlined,
        'sal' => Icons.water_drop_outlined,
        'nh3' => Icons.warning_amber_rounded,
        'no2' => Icons.analytics_outlined,
        _ => Icons.sensors_outlined,
      };

  Color _envColor(String status) => switch (status) {
        'warning' => DashboardColors.monitoring,
        'danger' => DashboardColors.risk,
        _ => DashboardColors.healthy,
      };

  Widget _statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: _font(size: 12, weight: FontWeight.w600, color: color)),
      );

  Widget _infoRow(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(label, style: _font(size: 13, color: DashboardColors.textMuted)),
            ),
            Expanded(
              child: Text(
                value,
                style: _font(size: 13, weight: FontWeight.w600, color: valueColor),
              ),
            ),
          ],
        ),
      );

  // ─── build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: DashboardColors.pageGradient),
      child: Column(
        children: [
          _buildHeader(),
          _buildBoxInfoCard(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCrabProfileTab(),
                _buildSensorTab(),
                _buildCameraTab(),
                _buildAlertTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── header ────────────────────────────────────────────────────────

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: Icon(Icons.arrow_back_rounded, color: DashboardColors.textPrimary),
              tooltip: 'Quay lại',
            ),
            const SizedBox(width: 8),
            Icon(Icons.inventory_2_outlined, size: 16, color: DashboardColors.textMuted),
            const SizedBox(width: 6),
            Text(
              '${widget.areaName} / ${widget.rowName}',
              style: _font(size: 13, color: DashboardColors.textMuted),
            ),
            const SizedBox(width: 12),
            Text(
              widget.box.boxCode,
              style: _font(size: 22, weight: FontWeight.w700),
            ),
            const Spacer(),
            _statusBadge(_statusLabel(widget.box.status), _statusColor(widget.box.status)),
          ],
        ),
      );

  // ─── box info card ─────────────────────────────────────────────────

  Widget _buildBoxInfoCard() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chips = <Widget>[
                _chipInfo(Icons.qr_code_2_outlined, 'Mã hộp', widget.box.boxCode),
                _chipInfo(Icons.map_outlined, 'Khu', widget.areaName),
                _chipInfo(Icons.view_column_outlined, 'Dãy', widget.rowName),
                _chipInfo(
                  Icons.pin_drop_outlined,
                  'Vị trí',
                  widget.box.position ?? '—',
                ),
                _chipInfo(
                  Icons.straighten_outlined,
                  'Thể tích',
                  widget.box.volume != null ? '${widget.box.volume!.toStringAsFixed(1)} L' : '—',
                ),
              ];
              return Wrap(spacing: 24, runSpacing: 12, children: chips);
            },
          ),
        ),
      );

  Widget _chipInfo(IconData icon, String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DashboardColors.cyan),
          const SizedBox(width: 6),
          Text('$label: ', style: _font(size: 12, color: DashboardColors.textMuted)),
          Text(value, style: _font(size: 12, weight: FontWeight.w600)),
        ],
      );

  // ─── tab bar ───────────────────────────────────────────────────────

  Widget _buildTabBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: _font(size: 13, weight: FontWeight.w600),
          unselectedLabelStyle: _font(size: 13),
          labelColor: DashboardColors.cyan,
          unselectedLabelColor: DashboardColors.textMuted,
          indicatorColor: DashboardColors.cyan,
          indicatorSize: TabBarIndicatorSize.label,
          dividerHeight: 0.5,
          dividerColor: DashboardColors.cardBorder,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Profile Cua'),
            Tab(text: 'Cảm biến'),
            Tab(text: 'Camera AI'),
            Tab(text: 'Cảnh báo'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TAB 1 – Tổng quan
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildOverviewTab() {
    if (_svc.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_svc.error != null) {
      return Center(child: Text('Lỗi: ${_svc.error}', style: _font(color: DashboardColors.risk)));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _overviewCrabSummary(),
        const SizedBox(height: 16),
        _overviewEnvironment(),
        const SizedBox(height: 16),
        _overviewQuickAlerts(),
      ],
    );
  }

  Widget _overviewCrabSummary() => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pest_control_outlined, size: 20, color: DashboardColors.cyan),
                const SizedBox(width: 8),
                Text('Cua trong hộp', style: _font(size: 16, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 500;
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _crabQuickInfo()),
                          const SizedBox(width: 20),
                          _healthScoreCircle(),
                        ],
                      )
                    : Column(
                        children: [
                          _crabQuickInfo(),
                          const SizedBox(height: 16),
                          _healthScoreCircle(),
                        ],
                      );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: Icon(Icons.visibility_outlined, size: 16, color: DashboardColors.cyan),
                label: Text('Xem Profile', style: _font(size: 13, color: DashboardColors.cyan)),
              ),
            ),
          ],
        ),
      );

  Widget _crabQuickInfo() {
    final c = _crab;
    if (c == null) {
      return Text('Chưa có cua trong hộp', style: _font(color: DashboardColors.textMuted));
    }
    final healthColor = switch (c.healthStatus) {
      'healthy' => DashboardColors.healthy,
      'monitoring' => DashboardColors.monitoring,
      'at_risk' => DashboardColors.risk,
      'molting' => DashboardColors.molting,
      _ => DashboardColors.cyan,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Mã cua', c.crabCode),
        _infoRow('Giới tính', c.genderLabel),
        _infoRow('Cân nặng', '${c.weight?.toStringAsFixed(0) ?? '—'} g'),
        _infoRow('Kích thước mai', '${c.shellWidth?.toStringAsFixed(1) ?? '—'} cm'),
        Row(
          children: [
            SizedBox(
              width: 140,
              child: Text('Sức khỏe', style: _font(size: 13, color: DashboardColors.textMuted)),
            ),
            _statusBadge(c.healthStatusLabel, healthColor),
          ],
        ),
        const SizedBox(height: 4),
        _infoRow('Trạng thái', c.statusLabel),
        _infoRow('Giai đoạn', c.growthStageLabel),
      ],
    );
  }

  Widget _healthScoreCircle() {
    final score = _crab?.meatQuality?.toInt() ?? 0;
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: DashboardColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    score >= 85
                        ? DashboardColors.healthy
                        : score >= 70
                            ? DashboardColors.monitoring
                            : DashboardColors.risk,
                  ),
                ),
              ),
              Text('$score', style: _font(size: 28, weight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Chất lượng', style: _font(size: 12, color: DashboardColors.textMuted)),
      ],
    );
  }

  Widget _overviewEnvironment() => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors_outlined, size: 20, color: DashboardColors.seaGreen),
                const SizedBox(width: 8),
                Text('Môi trường realtime', style: _font(size: 16, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.areaEnvironmentService.loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: DashboardColors.cyan),
              )
            else if (widget.areaEnvironmentService.metrics.isEmpty)
              Text(
                widget.areaEnvironmentService.error ??
                    'Chưa có dữ liệu cảm biến khu — xem tab Cảm biến',
                style: _font(size: 13, color: DashboardColors.textMuted),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.areaEnvironmentService.metrics
                    .map(_miniEnvCard)
                    .toList(),
              ),
          ],
        ),
      );

  Widget _miniEnvCard(BoxEnvironmentMetric m) {
    final color = _envColor(m.status);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_envIcon(m.icon), size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  m.label,
                  style: _font(size: 11, color: DashboardColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${m.value}${m.unit.isNotEmpty ? ' ${m.unit}' : ''}',
            style: _font(size: 20, weight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _overviewQuickAlerts() => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_outlined, size: 20, color: DashboardColors.monitoring),
                const SizedBox(width: 8),
                Text('Cảnh báo gần đây', style: _font(size: 16, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            if (_alertsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_alerts.isEmpty)
              Text(
                'Chưa có cảnh báo cho hộp này.',
                style: _font(size: 13, color: DashboardColors.textMuted),
              )
            else
              ..._alerts.take(3).map(_alertTile),
          ],
        ),
      );

  Widget _alertTile(BoxAlert a) {
    final color = _alertColor(a.severity);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(a.message, style: _font(size: 13)),
          ),
          Text(a.time, style: _font(size: 11, color: DashboardColors.textMuted)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TAB 2 – Profile Cua
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildCrabProfileTab() {
    if (_svc.loading) return const Center(child: CircularProgressIndicator());
    final c = _crab;
    if (c == null) {
      return Center(child: Text('Chưa có cua trong hộp', style: _font(color: DashboardColors.textMuted)));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _profileStats(c),
        const SizedBox(height: 16),
        _profileMoltTable(c),
        const SizedBox(height: 16),
        _profileFeedingTable(c),
        const SizedBox(height: 16),
        _profileHealthLogTable(c),
      ],
    );
  }

  Widget _profileStats(CrabProfileData c) {
    final healthColor = switch (c.healthStatus) {
      'healthy' => DashboardColors.healthy,
      'monitoring' => DashboardColors.monitoring,
      'at_risk' => DashboardColors.risk,
      _ => DashboardColors.cyan,
    };
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 20, color: DashboardColors.purple),
              const SizedBox(width: 8),
              Text('Thông tin cá thể', style: _font(size: 16, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Mã cua', c.crabCode),
          _infoRow('Giới tính', c.genderLabel),
          _infoRow('Cân nặng', '${c.weight?.toStringAsFixed(0) ?? '—'} g'),
          _infoRow('Kích thước mai', '${c.shellWidth?.toStringAsFixed(1) ?? '—'} cm'),
          _infoRow('Số lần lột xác', '${c.moltCount}'),
          _infoRow('Ngày lột gần nhất', c.lastMoltDate ?? '—'),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: Text('Tình trạng sức khỏe', style: _font(size: 13, color: DashboardColors.textMuted)),
              ),
              _statusBadge(c.healthStatusLabel, healthColor),
            ],
          ),
          const SizedBox(height: 4),
          _infoRow('Giai đoạn phát triển', c.growthStageLabel),
          _infoRow('Giá trị ước tính', c.estimatedPrice != null ? _fmtCurrency(c.estimatedPrice!) : '—'),
          _infoRow('Chất lượng thịt', '${c.meatQuality?.toStringAsFixed(0) ?? '—'}/100'),
          _infoRow('Chất lượng gạch', '${c.roeQuality?.toStringAsFixed(0) ?? '—'}/100'),
          if (c.profileNote != null) ...[
            const SizedBox(height: 8),
            _infoRow('Ghi chú', c.profileNote!),
          ],
        ],
      ),
    );
  }

  Widget _profileMoltTable(CrabProfileData c) => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lịch sử lột xác', style: _font(size: 15, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (c.moltLogs.isEmpty)
              Text('Chưa có dữ liệu', style: _font(size: 13, color: DashboardColors.textMuted))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(DashboardColors.darkNavy),
                  dataRowColor: WidgetStateProperty.all(Colors.transparent),
                  headingTextStyle: _font(size: 12, weight: FontWeight.w600, color: DashboardColors.textMuted),
                  dataTextStyle: _font(size: 12),
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Lần')),
                    DataColumn(label: Text('Ngày')),
                    DataColumn(label: Text('Tình trạng')),
                    DataColumn(label: Text('Ghi chú')),
                  ],
                  rows: c.moltLogs.map((m) {
                    final condColor = switch (m.condition) {
                      'normal' => DashboardColors.healthy,
                      'weak' => DashboardColors.risk,
                      _ => DashboardColors.monitoring,
                    };
                    return DataRow(cells: [
                      DataCell(Text('${m.moltNumber}')),
                      DataCell(Text(m.moltDate)),
                      DataCell(_statusBadge(m.conditionLabel, condColor)),
                      DataCell(Text(m.note ?? '—')),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      );

  Widget _profileFeedingTable(CrabProfileData c) => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lịch sử cho ăn', style: _font(size: 15, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (c.feedingLogs.isEmpty)
              Text('Chưa có dữ liệu', style: _font(size: 13, color: DashboardColors.textMuted))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(DashboardColors.darkNavy),
                  dataRowColor: WidgetStateProperty.all(Colors.transparent),
                  headingTextStyle: _font(size: 12, weight: FontWeight.w600, color: DashboardColors.textMuted),
                  dataTextStyle: _font(size: 12),
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Thời gian')),
                    DataColumn(label: Text('Loại thức ăn')),
                    DataColumn(label: Text('Lượng')),
                    DataColumn(label: Text('Ghi chú')),
                  ],
                  rows: c.feedingLogs.map((f) => DataRow(cells: [
                    DataCell(Text(_fmtDateTime(f.fedAt))),
                    DataCell(Text(f.foodType)),
                    DataCell(Text('${f.quantity.toStringAsFixed(0)} ${f.unit}')),
                    DataCell(Text(f.note ?? '—')),
                  ])).toList(),
                ),
              ),
          ],
        ),
      );

  Widget _profileHealthLogTable(CrabProfileData c) => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhật ký sức khỏe', style: _font(size: 15, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (c.healthRecords.isEmpty)
              Text('Chưa có dữ liệu', style: _font(size: 13, color: DashboardColors.textMuted))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(DashboardColors.darkNavy),
                  dataRowColor: WidgetStateProperty.all(Colors.transparent),
                  headingTextStyle: _font(size: 12, weight: FontWeight.w600, color: DashboardColors.textMuted),
                  dataTextStyle: _font(size: 12),
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Ngày')),
                    DataColumn(label: Text('Cân nặng (g)')),
                    DataColumn(label: Text('Trạng thái vỏ')),
                    DataColumn(label: Text('Bệnh')),
                  ],
                  rows: c.healthRecords.map((h) => DataRow(cells: [
                    DataCell(Text(_fmtDateTime(h.recordedAt))),
                    DataCell(Text(h.weight?.toStringAsFixed(0) ?? '—')),
                    DataCell(Text(h.shellStatus ?? '—')),
                    DataCell(Text(h.diseaseStatus ?? '—')),
                  ])).toList(),
                ),
              ),
          ],
        ),
      );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TAB 3 – Cảm biến
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildSensorTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AreaEnvironmentPanel(
              service: widget.areaEnvironmentService,
              areaId: widget.areaId,
              boxId: widget.box.id,
              boxCode: widget.box.boxCode,
              areaName: widget.areaName,
              areaCode: widget.areaCode,
              showInheritedHint: true,
            ),
          ),
        ],
      );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TAB 4 – Camera AI
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildCameraTab() {
    final cameras = widget.cameraService.cameras;
    if (widget.cameraService.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cameras.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, size: 64, color: DashboardColors.textMuted),
            const SizedBox(height: 16),
            Text('Chưa có camera gắn với hộp này', style: _font(size: 16, color: DashboardColors.textMuted)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: cameras.map(_cameraCard).toList(),
    );
  }

  Widget _cameraCard(CameraDevice cam) {
    final hasStream = cam.streamUrl != null && cam.streamUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.videocam, size: 20, color: cam.isOnline ? DashboardColors.healthy : DashboardColors.textMuted),
                const SizedBox(width: 8),
                Text(cam.name, style: _font(size: 16, weight: FontWeight.w700)),
                const SizedBox(width: 12),
                _statusBadge(
                  cam.isOnline ? 'Online' : 'Offline',
                  cam.isOnline ? DashboardColors.healthy : DashboardColors.dead,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => showCameraConnectTestForDevice(context, cam),
                  icon: const Icon(Icons.lan_outlined, size: 16),
                  label: const Text('Test kết nối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardColors.cyan,
                    side: const BorderSide(color: DashboardColors.cyan),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                Text(cam.cameraCode, style: _font(size: 12, color: DashboardColors.textMuted)),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('IP Address', cam.ipAddress ?? '—'),
            _infoRow('Stream URL', cam.streamUrl ?? '—'),
            if (CameraStreamUrlHelper.ipMismatch(cam.streamUrl, cam.ipAddress))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'IP và Stream URL khác nhau — app phát theo Stream URL '
                  '(${CameraStreamUrlHelper.streamHost(streamUrl: cam.streamUrl) ?? "?"}). '
                  'Nên sửa DB cho khớp một camera.',
                  style: _font(size: 12, color: DashboardColors.risk),
                ),
              ),
            if (hasStream && cam.isOnline) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 360,
                  color: Colors.black,
                  child: _buildStreamWidget(cam),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'MJPEG Stream — ${cam.streamUrl}',
                style: _font(size: 11, color: DashboardColors.textMuted),
              ),
            ],
            if (!cam.isOnline) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: DashboardColors.darkNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off, size: 48, color: DashboardColors.dead),
                      const SizedBox(height: 12),
                      Text('Camera offline', style: _font(size: 14, color: DashboardColors.dead)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreamWidget(CameraDevice cam) {
    final raw = cam.streamUrl!.trim();
    final candidates = CameraStreamUrlHelper.hasMjpegEndpoint(raw)
        ? [raw]
        : CameraStreamUrlHelper.streamCandidates(
            streamUrl: cam.streamUrl,
            ipAddress: cam.ipAddress,
          );
    final streamUrl = candidates.first;
    final extras = candidates.length > 1 ? candidates.sublist(1) : null;

    final streamHost = CameraStreamUrlHelper.streamHost(
      streamUrl: cam.streamUrl,
      ipAddress: cam.ipAddress,
    );

    return CameraStreamPlayer(
      key: ValueKey('box-stream-${cam.id}-$streamUrl'),
      streamUrl: streamUrl,
      ipAddress: streamHost ?? cam.ipAddress,
      snapshotFallbackUrl: CameraStreamUrlHelper.snapshotFallback(
        streamUrl: cam.streamUrl,
        ipAddress: cam.ipAddress,
      ),
      streamUrlCandidates: extras,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TAB 5 – Cảnh báo
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildAlertTab() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tất cả cảnh báo', style: _font(size: 16, weight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (_alertsLoading)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2))
                else if (_alerts.isEmpty)
                  Text(
                    'Chưa có cảnh báo cho hộp này.',
                    style: _font(size: 13, color: DashboardColors.textMuted),
                  )
                else
                  ..._alerts.map(_alertDetailTile),
              ],
            ),
          ),
        ],
      );

  Widget _alertDetailTile(BoxAlert a) {
    final color = _alertColor(a.severity);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.message, style: _font(size: 13)),
                const SizedBox(height: 2),
                Text(a.time, style: _font(size: 11, color: DashboardColors.textMuted)),
              ],
            ),
          ),
          _statusBadge(
            a.severity == 'critical'
                ? 'Nghiêm trọng'
                : a.severity == 'warning'
                    ? 'Cảnh báo'
                    : 'Thông tin',
            color,
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TAB 6 – Lịch sử
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildHistoryTab() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, size: 64, color: DashboardColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Lịch sử hoạt động hộp nuôi',
              style: _font(size: 18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Các sự kiện, thay đổi, thao tác trên hộp nuôi',
              style: _font(size: 14, color: DashboardColors.textMuted),
            ),
          ],
        ),
      );
}
