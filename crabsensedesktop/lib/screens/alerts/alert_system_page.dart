import 'package:flutter/material.dart';

import '../../models/auth_models.dart';
import '../../models/farm_alert.dart';
import '../../navigation/app_route.dart';
import '../../services/alert_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/alerts/alert_system_widgets.dart';
import '../../widgets/shared/mgmt_ui.dart';

class AlertSystemPage extends StatefulWidget {
  const AlertSystemPage({
    super.key,
    required this.service,
    this.session,
    this.onNavigate,
  });

  final AlertService service;
  final AuthSession? session;
  final void Function(AppRoute route)? onNavigate;

  @override
  State<AlertSystemPage> createState() => _AlertSystemPageState();
}

class _AlertSystemPageState extends State<AlertSystemPage> {
  final _search = TextEditingController();

  AlertService get _svc => widget.service;

  bool get _canAct {
    final s = widget.session;
    if (s == null) return true;
    return s.user.isFarmOwner ||
        s.user.isStaff ||
        s.user.isSystemAdmin ||
        s.isOrgAdmin;
  }

  String get _muteLabel {
    if (!_svc.soundOn && _svc.muteUntil == null) return 'Đến khi bật lại';
    final until = _svc.muteUntil;
    if (until != null) {
      final left = until.difference(DateTime.now());
      if (left.inHours >= 1) return 'Tắt tiếng 1 giờ';
      if (left.inMinutes >= 25) return 'Tắt tiếng 30 phút';
      return 'Tắt tiếng 15 phút';
    }
    return 'Tắt tiếng 15 phút';
  }

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
    _svc.load();
    _svc.startPolling();
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    _search.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _openMobileDetail(FarmAlert alert) async {
    _svc.selectAlert(alert.id);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chi tiết cảnh báo',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      pageBuilder: (ctx, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SizedBox(
              width: MediaQuery.sizeOf(ctx).width,
              height: MediaQuery.sizeOf(ctx).height,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  AlertDetailPanel(
                    alert: alert,
                    service: _svc,
                    onNavigate: widget.onNavigate,
                    canAct: _canAct,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final mobile = w < 760;
    final tablet = w < 1100;
    final loading = _svc.loading && _svc.alerts.isEmpty;
    final selected = _svc.selectedAlert;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 14),
          if (loading)
            const WaLikeKpiSkeleton()
          else
            AlertKpiStrip(kpi: _svc.kpi),
          const SizedBox(height: 14),
          AlertFilterToolbar(service: _svc, searchController: _search),
          const SizedBox(height: 14),
          if (_svc.error != null && _svc.alerts.isEmpty)
            _error(_svc.error!, () => _svc.load())
          else if (mobile) ...[
            _listCard(true),
          ] else if (tablet) ...[
            _listCard(false),
            const SizedBox(height: 14),
            if (selected != null)
              AlertDetailPanel(
                alert: selected,
                service: _svc,
                onNavigate: widget.onNavigate,
                canAct: _canAct,
              ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 68, child: _listCard(false)),
                const SizedBox(width: 14),
                Expanded(
                  flex: 32,
                  child: selected == null
                      ? _emptyDetail()
                      : AlertDetailPanel(
                          alert: selected,
                          service: _svc,
                          onNavigate: widget.onNavigate,
                          canAct: _canAct,
                        ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: DashboardColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hệ thống cảnh báo',
                  style: bvText(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                Text(
                  'Theo dõi và xử lý các sự cố trong toàn hệ thống CrabSense.',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MgmtOutlineButton(
                icon: _svc.isMuted ? Icons.volume_off : Icons.volume_up,
                label: _svc.soundOn && !_svc.isMuted
                    ? 'Âm cảnh báo ON'
                    : 'Âm cảnh báo OFF',
                tooltip: 'Bật hoặc tắt âm cảnh báo',
                onTap: () => _svc.toggleSound(!_svc.soundOn),
              ),
              SizedBox(
                width: 170,
                child: MgmtDropdown<Duration>(
                  valueLabel: _muteLabel,
                  items: const [
                    (Duration(minutes: 15), '15 phút'),
                    (Duration(minutes: 30), '30 phút'),
                    (Duration(hours: 1), '1 giờ'),
                    (Duration(days: 3650), 'Đến khi bật lại'),
                  ],
                  onSelected: _svc.muteFor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _listCard(bool mobile) {
    final rows = _svc.pagedAlerts;
    final total = _svc.filteredCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Danh sách cảnh báo ($total)',
                  style: bvText(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              if (_canAct && _svc.checked.isNotEmpty) ...[
                MgmtOutlineButton(
                  label: 'Xác nhận đã chọn',
                  tooltip: 'Xác nhận các cảnh báo đã chọn',
                  onTap: _svc.acknowledgeChecked,
                ),
                const SizedBox(width: 8),
                MgmtOutlineButton(
                  label: 'Đánh dấu đang xử lý',
                  tooltip: 'Đánh dấu các cảnh báo đã chọn đang xử lý',
                  onTap: _svc.processChecked,
                ),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: 190,
                child: MgmtDropdown<String>(
                  valueLabel: switch (_svc.sort) {
                    'oldest' => 'Cũ nhất trước',
                    'longest' => 'Mở lâu nhất',
                    'status' => 'Theo trạng thái',
                    'severity' => 'Theo mức độ',
                    'newest' => 'Mới nhất trước',
                    _ => 'Nghiêm trọng trước',
                  },
                  items: const [
                    ('priority', 'Nghiêm trọng trước, mới nhất'),
                    ('newest', 'Mới nhất trước'),
                    ('oldest', 'Cũ nhất trước'),
                    ('longest', 'Mở lâu nhất'),
                    ('status', 'Theo trạng thái'),
                    ('severity', 'Theo mức độ'),
                  ],
                  onSelected: _svc.setSort,
                ),
              ),
            ],
          ),
          if (_svc.newCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Có ${_svc.newCount} cảnh báo mới',
                      style: bvText(fontWeight: FontWeight.w700),
                    ),
                  ),
                  MgmtOutlineButton(label: 'Hiển thị', onTap: _svc.showNew),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_svc.loading && _svc.alerts.isEmpty)
            const Column(
              children: [
                WaLikeRowSkeleton(),
                SizedBox(height: 8),
                WaLikeRowSkeleton(),
                SizedBox(height: 8),
                WaLikeRowSkeleton(),
                SizedBox(height: 8),
                WaLikeRowSkeleton(),
                SizedBox(height: 8),
                WaLikeRowSkeleton(),
                SizedBox(height: 8),
                WaLikeRowSkeleton(),
                SizedBox(height: 8),
                WaLikeRowSkeleton(),
                SizedBox(height: 8),
                WaLikeRowSkeleton(),
              ],
            )
          else if (rows.isEmpty)
            _emptyList()
          else
            AlertTable(
              service: _svc,
              alerts: rows,
              selectedId: _svc.selectedAlert?.id,
              asCards: mobile,
              onRowTap: mobile ? (a) => _openMobileDetail(a) : null,
            ),
          const SizedBox(height: 12),
          _pager(total),
        ],
      ),
    );
  }

  Widget _emptyList() {
    if (_svc.hasFilters) {
      return Column(
        children: [
          const SizedBox(height: 24),
          Text('Không tìm thấy cảnh báo',
              style: bvText(
                fontWeight: FontWeight.w800,
                color: DashboardColors.textPrimary,
              )),
          Text(
            'Không có cảnh báo phù hợp với bộ lọc hiện tại.',
            style: bvText(color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 10),
          MgmtOutlineButton(label: 'Xóa bộ lọc', onTap: _svc.clearFilters),
        ],
      );
    }
    return Column(
      children: [
        const SizedBox(height: 28),
        const Icon(Icons.check_circle, color: DashboardColors.brandGreen, size: 36),
        const SizedBox(height: 8),
        Text('Không có cảnh báo đang mở',
            style: bvText(
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            )),
        Text(
          'Hệ thống đang hoạt động bình thường.',
          style: bvText(color: DashboardColors.textMuted),
        ),
      ],
    );
  }

  Widget _emptyDetail() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: mgmtCardDeco(radius: 16),
      child: Text(
        'Chọn một cảnh báo để xem chi tiết.',
        style: bvText(color: DashboardColors.textMuted),
      ),
    );
  }

  Widget _pager(int total) {
    final start = total == 0 ? 0 : ((_svc.page - 1) * _svc.pageSize) + 1;
    final end = (_svc.page * _svc.pageSize).clamp(0, total);
    final pages = (total / _svc.pageSize).ceil().clamp(1, 999);
    return Row(
      children: [
        Text(
          'Hiển thị: $start–$end / $total cảnh báo',
          style: bvText(fontSize: 12, color: DashboardColors.textMuted),
        ),
        const Spacer(),
        IconButton(
          onPressed: _svc.page > 1 ? () => _svc.setPage(_svc.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('${_svc.page} / $pages', style: bvText(fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: _svc.page < pages ? () => _svc.setPage(_svc.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: MgmtDropdown<int>(
            valueLabel: '${_svc.pageSize} / trang',
            items: const [(10, '10'), (20, '20'), (50, '50'), (100, '100')],
            onSelected: _svc.setPageSize,
          ),
        ),
      ],
    );
  }

  Widget _error(String msg, VoidCallback retry) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5B700).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text('⚠ Không thể tải danh sách cảnh báo.\n$msg')),
          MgmtOutlineButton(label: 'Thử lại', onTap: retry),
        ],
      ),
    );
  }
}

class WaLikeKpiSkeleton extends StatelessWidget {
  const WaLikeKpiSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: WaLikeBox()),
        SizedBox(width: 10),
        Expanded(child: WaLikeBox()),
        SizedBox(width: 10),
        Expanded(child: WaLikeBox()),
        SizedBox(width: 10),
        Expanded(child: WaLikeBox()),
        SizedBox(width: 10),
        Expanded(child: WaLikeBox()),
        SizedBox(width: 10),
        Expanded(child: WaLikeBox()),
      ],
    );
  }
}

class WaLikeBox extends StatelessWidget {
  const WaLikeBox({super.key, this.height = 88});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
    );
  }
}

class WaLikeRowSkeleton extends StatelessWidget {
  const WaLikeRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const WaLikeBox(height: 48);
  }
}
