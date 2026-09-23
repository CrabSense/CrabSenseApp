import 'package:flutter/material.dart';

import '../../../models/camera_device.dart';
import '../../../models/crab_feeding_activity.dart';
import '../../../models/crab_individual.dart';
import '../../../services/cloud_api_client.dart';
import '../../../services/crab_feeding_activity_controller.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import 'add_feeding_modal.dart';
import 'feeding_event_drawer.dart';
import 'feeding_history_table.dart';
import 'feeding_trend_charts.dart';

/// Nội dung tab "Ăn & Vận động" trong Chi tiết cua.
class CrabFeedingActivityTab extends StatefulWidget {
  const CrabFeedingActivityTab({
    super.key,
    required this.crab,
    required this.controller,
    required this.token,
    required this.api,
    this.cameras = const [],
    this.operatorName,
    this.onViewCamera,
  });

  final CrabIndividual crab;
  final CrabFeedingActivityController controller;
  final String token;
  final CloudApiClient api;
  final List<CameraDevice> cameras;
  final String? operatorName;

  /// Mở màn camera của hộp (từ ⋯ "Xem camera liên quan").
  final VoidCallback? onViewCamera;

  @override
  State<CrabFeedingActivityTab> createState() => _CrabFeedingActivityTabState();
}

class _CrabFeedingActivityTabState extends State<CrabFeedingActivityTab> {
  final _hover = ValueNotifier<int?>(null);
  String? _selectedEventId;

  CrabFeedingActivityController get _c => widget.controller;
  FeedingThresholds get _th => _c.thresholds;

  @override
  void initState() {
    super.initState();
    _c.addListener(_rebuild);
    if (_c.data == null && !_c.loading) _c.load();
  }

  @override
  void dispose() {
    _c.removeListener(_rebuild);
    _hover.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  String _cameraLabel(String? id) {
    if (id == null || id.isEmpty) return '—';
    final cam = widget.cameras.where((c) => c.id == id || c.cameraCode == id).firstOrNull;
    return cam == null ? id : '${cam.name} (${cam.cameraCode})';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _c.from, end: _c.to.isAfter(now) ? now : _c.to),
      helpText: 'Chọn khoảng thời gian',
      saveText: 'Áp dụng',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: DashboardColors.brand),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    _c.setCustomRange(picked.start, picked.end);
  }

  Future<void> _addFeeding() async {
    final input = await showAddFeedingModal(
      context,
      crabCode: widget.crab.code,
      boxLabel: widget.crab.boxLabel,
      boxId: widget.crab.boxId,
      token: widget.token,
      api: widget.api,
      cameras: widget.cameras,
      thresholds: _th,
    );
    if (input == null || !mounted) return;
    final err = await _c.addFeeding(
      boxId: widget.crab.boxId,
      input: input,
      operatorName: widget.operatorName,
      locationLabel: widget.crab.locationLine,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Đã lưu lần cho ăn cho ${widget.crab.code}')),
    );
  }

  Future<void> _editNote(FeedingEvent e) async {
    final note = await showEditFeedingNoteDialog(context, e);
    if (note == null || !mounted) return;
    final err = await _c.updateNote(e, note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Đã cập nhật ghi chú')),
    );
  }

  void _openDetail(FeedingEvent e) {
    setState(() => _selectedEventId = e.id);
    showFeedingEventDrawer(
      context,
      event: e,
      token: widget.token,
      cameraLabel: _cameraLabel(e.cameraId),
      thresholds: _th,
      onEditNote: () => _editNote(e),
      onViewCamera: widget.onViewCamera,
    ).then((_) {
      if (mounted) setState(() => _selectedEventId = null);
    });
  }

  void _onAction(FeedingEvent e, FeedingEventAction a) {
    switch (a) {
      case FeedingEventAction.detail:
        _openDetail(e);
      case FeedingEventAction.editNote:
        _editNote(e);
      case FeedingEventAction.viewPhotos:
        showFeedingLightbox(context, urls: e.photoUrls, token: widget.token);
      case FeedingEventAction.viewCamera:
        widget.onViewCamera?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _c.data;
    final loading = _c.loading;
    final error = _c.error;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 16),
          if (error != null && data == null)
            _errorState(error)
          else if (!loading && data != null && data.totalEvents == 0 && _c.period == FeedingPeriod.d30)
            _emptyState()
          else ...[
            FeedingActivitySummaryRow(summary: data?.summary, loading: loading || data == null, thresholds: _th, periodLabel: _c.periodLabel),
            if (!loading && data?.insight != null) ...[
              const SizedBox(height: 14),
              _InsightBanner(text: data!.insight!, level: data.insightLevel),
            ],
            const SizedBox(height: 16),
            _charts(data, loading),
            const SizedBox(height: 16),
            _historyCard(data, loading),
          ],
        ],
    );
  }

  // ── header ────────────────────────────────────────────────────────────

  Widget _header() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_rounded, size: 20, color: DashboardColors.brand),
                const SizedBox(width: 8),
                Text(
                  'Ăn & Vận động',
                  style: bvText(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Theo dõi lịch sử cho ăn, mức ăn và mức độ vận động của cua theo thời gian.',
              style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _PeriodChips(value: _c.period, onChanged: _c.setPeriod),
            MgmtOutlineButton(
              icon: Icons.calendar_month_outlined,
              label: _c.period == FeedingPeriod.custom ? _c.periodLabel : 'Chọn khoảng',
              onTap: _pickRange,
              color: _c.period == FeedingPeriod.custom ? DashboardColors.brand : DashboardColors.textPrimary,
              borderColor: _c.period == FeedingPeriod.custom ? DashboardColors.brand : DashboardColors.cardBorder,
              height: 36,
            ),
            MgmtPrimaryButton(
              icon: Icons.add_rounded,
              label: 'Ghi nhận cho ăn',
              onTap: _addFeeding,
              height: 36,
            ),
          ],
        ),
      ],
    );
  }

  // ── charts ────────────────────────────────────────────────────────────

  Widget _charts(CrabFeedingActivityData? data, bool loading) {
    return LayoutBuilder(
      builder: (context, c) {
        final twoCols = c.maxWidth >= 900;
        if (loading || data == null) {
          final a = const ChartSkeleton();
          final b = const ChartSkeleton();
          return twoCols
              ? Row(children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)])
              : Column(children: [a, const SizedBox(height: 16), b]);
        }
        final axis = buildSharedAxis(data);
        final a = FeedingTrendChart(data: data, axis: axis, hover: _hover, thresholds: _th);
        final b = ActivityTrendChart(data: data, axis: axis, hover: _hover, thresholds: _th);
        return twoCols
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)],
              )
            : Column(children: [a, const SizedBox(height: 16), b]);
      },
    );
  }

  // ── history table ─────────────────────────────────────────────────────

  Widget _historyCard(CrabFeedingActivityData? data, bool loading) {
    final events = _c.pageEvents;
    final total = data?.totalEvents ?? 0;
    final start = total == 0 ? 0 : (_c.page - 1) * _c.pageSize + 1;
    final end = total == 0 ? 0 : (start + events.length - 1).clamp(0, total);
    final busy = loading || _c.tableLoading || data == null;

    return Container(
      decoration: mgmtCardDeco(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch sử cho ăn',
                        style: bvText(fontSize: 14.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                      ),
                      Text(_c.periodLabel, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                    ],
                  ),
                ),
                MgmtInlineSort<FeedingSort>(
                  value: _c.sort,
                  items: const [
                    (FeedingSort.time, 'Thời gian'),
                    (FeedingSort.feedingPercent, 'Mức ăn'),
                    (FeedingSort.served, 'Khẩu phần'),
                    (FeedingSort.activity, 'Vận động'),
                  ],
                  onChanged: _c.setSort,
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _c.setPeriod(FeedingPeriod.d30),
                  style: TextButton.styleFrom(foregroundColor: DashboardColors.brand),
                  child: Text('Xem tất cả →', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          if (busy)
            const FeedingTableSkeleton()
          else if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  const Icon(Icons.restaurant_outlined, size: 28, color: DashboardColors.brand),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có dữ liệu cho ăn',
                    style: bvText(fontSize: 14, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Không có lần cho ăn nào trong ${_c.periodLabel.toLowerCase()}.',
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  MgmtOutlineButton(icon: Icons.add_rounded, label: 'Ghi nhận lần cho ăn', onTap: _addFeeding),
                ],
              ),
            )
          else
            FeedingHistoryTable(
              events: events,
              token: widget.token,
              sort: _c.sort,
              sortDesc: _c.sortDesc,
              onSort: _c.setSort,
              onRowTap: _openDetail,
              onAction: _onAction,
              thresholds: _th,
              selectedId: _selectedEventId,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Text(
                  total == 0 ? 'Không có lần cho ăn' : '$start–$end của $total lần cho ăn',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                ),
                const SizedBox(width: 14),
                MgmtInlineSort<int>(
                  value: _c.pageSize,
                  items: const [(10, '10 / trang'), (20, '20 / trang'), (50, '50 / trang')],
                  onChanged: _c.setPageSize,
                ),
                const Spacer(),
                MgmtPageBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: _c.page > 1 ? () => _c.setPage(_c.page - 1) : null,
                ),
                for (final p in _pageWindow(_c.page, _c.totalPages)) ...[
                  const SizedBox(width: 6),
                  p < 0
                      ? Text('…', style: bvText(color: DashboardColors.textMuted))
                      : MgmtPageBtn(label: '$p', active: p == _c.page, onTap: () => _c.setPage(p)),
                ],
                const SizedBox(width: 6),
                MgmtPageBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: _c.page < _c.totalPages ? () => _c.setPage(_c.page + 1) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<int> _pageWindow(int page, int total) {
    if (total <= 7) return [for (var i = 1; i <= total; i++) i];
    final s = <int>{1, total, page, page - 1, page + 1}..removeWhere((p) => p < 1 || p > total);
    final sorted = s.toList()..sort();
    final out = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(-1);
      out.add(sorted[i]);
    }
    return out;
  }

  // ── states ────────────────────────────────────────────────────────────

  Widget _emptyState() {
    return MgmtEmptyState(
      icon: Icons.restaurant_rounded,
      title: 'Chưa có dữ liệu cho ăn',
      message: 'Các lần cho ăn của cua sẽ xuất hiện tại đây.',
      action: MgmtPrimaryButton(icon: Icons.add_rounded, label: 'Ghi nhận lần cho ăn', onTap: _addFeeding, height: 38),
    );
  }

  Widget _errorState(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 30, color: DashboardColors.risk),
          const SizedBox(height: 10),
          Text(
            'Không tải được dữ liệu ăn & vận động',
            style: bvText(fontSize: 14, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(error, textAlign: TextAlign.center, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 14),
          MgmtOutlineButton(icon: Icons.refresh_rounded, label: 'Thử lại', onTap: _c.load),
        ],
      ),
    );
  }
}

// ── Period chips ─────────────────────────────────────────────────────────

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.value, required this.onChanged});

  final FeedingPeriod value;
  final ValueChanged<FeedingPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in [FeedingPeriod.h24, FeedingPeriod.d7, FeedingPeriod.d30])
            InkWell(
              onTap: () => onChanged(p),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == p ? DashboardColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.label,
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: value == p ? Colors.white : DashboardColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── KPI row ──────────────────────────────────────────────────────────────

class FeedingActivitySummaryRow extends StatelessWidget {
  const FeedingActivitySummaryRow({
    super.key,
    required this.summary,
    required this.loading,
    required this.periodLabel,
    this.thresholds = FeedingThresholds.defaults,
  });

  final FeedingActivitySummary? summary;
  final bool loading;
  final String periodLabel;
  final FeedingThresholds thresholds;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    String delta(int? d, {String unit = ''}) {
      if (d == null) return 'Chưa có kỳ so sánh';
      if (d == 0) return 'Không đổi so với kỳ trước';
      return '${d > 0 ? '+' : ''}$d$unit so với kỳ trước';
    }
    Color? deltaColor(int? d) => d == null || d == 0 ? null : (d > 0 ? DashboardColors.brand : DashboardColors.risk);

    final act = s?.avgActivityScore;
    final cards = <Widget>[
      _KpiCard(
        icon: Icons.restaurant_rounded,
        color: DashboardColors.brand,
        label: 'Lần cho ăn',
        value: loading ? null : '${s?.feedingCount ?? 0}',
        sub: loading ? null : delta(s?.feedingCountDelta),
        subColor: deltaColor(s?.feedingCountDelta),
      ),
      _KpiCard(
        icon: Icons.task_alt_rounded,
        color: DashboardColors.brandGreen,
        label: 'Tỷ lệ ăn hết',
        value: loading ? null : (s?.finishRate == null ? '—' : '${s!.finishRate}%'),
        sub: loading ? null : (s?.finishRate == null ? 'Chưa đủ dữ liệu' : delta(s?.finishRateDelta, unit: '%')),
        subColor: deltaColor(s?.finishRateDelta),
      ),
      _KpiCard(
        icon: Icons.pie_chart_outline_rounded,
        color: const Color(0xFFF5B700),
        label: 'Mức ăn trung bình',
        value: loading ? null : (s?.avgFeedingPercent == null ? '—' : '${s!.avgFeedingPercent}%'),
        sub: loading
            ? null
            : s?.avgFeedingPercent == null
                ? 'Chưa đủ dữ liệu'
                : s!.avgFeedingPercent! < thresholds.alertPercent
                    ? 'Cảnh báo: dưới ${thresholds.alertPercent}%'
                    : s.avgFeedingPercent! < thresholds.watchPercent
                        ? 'Theo dõi: dưới ${thresholds.watchPercent}%'
                        : 'Trong ngưỡng bình thường',
        subColor: s?.avgFeedingPercent != null && s!.avgFeedingPercent! < thresholds.watchPercent
            ? DashboardColors.risk
            : null,
      ),
      _KpiCard(
        icon: Icons.directions_run_rounded,
        color: kFeedingBlue,
        label: 'Mức vận động trung bình',
        value: loading ? null : (act == null ? '—' : '$act / 100'),
        sub: loading ? null : (act == null ? 'Chưa có dữ liệu vận động.' : thresholds.activityLabel(act)),
        subDot: act == null ? null : thresholds.activityColor(act),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1000 ? 4 : 2;
        final gap = 14.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
    this.subDot,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? value;
  final String? sub;
  final Color? subColor;
  final Color? subDot;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(6)),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: mgmtCardDeco(radius: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: bvText(fontSize: 12, fontWeight: FontWeight.w600, color: DashboardColors.textMuted)),
                const SizedBox(height: 4),
                if (value == null)
                  bar(80, 22)
                else
                  Text(
                    value!,
                    style: bvText(fontSize: 22, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary, height: 1.1),
                  ),
                const SizedBox(height: 4),
                if (sub == null)
                  bar(120, 10)
                else
                  Row(
                    children: [
                      if (subDot != null) ...[
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: subDot, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          sub!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bvText(fontSize: 11.5, fontWeight: FontWeight.w600, color: subColor ?? DashboardColors.textMuted),
                        ),
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

// ── AI insight banner ────────────────────────────────────────────────────

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.text, required this.level});

  final String text;
  final String level;

  @override
  Widget build(BuildContext context) {
    final warn = level == 'warning' || level == 'watch';
    final color = level == 'warning'
        ? DashboardColors.risk
        : level == 'watch'
            ? const Color(0xFFF5B700)
            : DashboardColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(warn ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary),
            ),
          ),
          Text(
            level == 'warning' ? 'Phát hiện bất thường' : level == 'watch' ? 'Xu hướng cần theo dõi' : 'Ổn định',
            style: bvText(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Card "Ăn & vận động hôm nay" (tab Tổng quan) ─────────────────────────

class FeedingTodayCard extends StatelessWidget {
  const FeedingTodayCard({
    super.key,
    required this.controller,
    required this.onOpenAnalysis,
  });

  final CrabFeedingActivityController controller;
  final VoidCallback onOpenAnalysis;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final e = controller.latestEvent;
        final th = controller.thresholds;
        final loading = controller.loading && controller.data == null;
        final now = DateTime.now();
        final isToday = e != null && e.time.year == now.year && e.time.month == now.month && e.time.day == now.day;
        String g(double? v) => v == null ? '—' : '${v.toStringAsFixed(0)} g';
        final act = e?.activityScore;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: mgmtCardDeco(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_rounded, size: 17, color: DashboardColors.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isToday ? 'Ăn & vận động hôm nay' : 'Ăn & vận động gần nhất',
                      style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenAnalysis,
                    style: TextButton.styleFrom(
                      foregroundColor: DashboardColors.brand,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                    child: Text('Xem phân tích →', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (loading)
                Container(
                  height: 56,
                  decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(10)),
                )
              else if (e == null)
                Text(
                  'Chưa có dữ liệu cho ăn trong ${controller.periodLabel.toLowerCase()}.',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                )
              else
                Wrap(
                  spacing: 22,
                  runSpacing: 10,
                  children: [
                    _stat('Mức ăn', e.feedingPercent == null ? '—' : '${e.feedingPercent}%',
                        color: e.feedingPercent == null ? null : th.feedingColor(e.feedingPercent!)),
                    _stat('Vận động', act == null ? '—' : '$act / 100',
                        color: act == null ? null : th.activityColor(act)),
                    _stat('Lần ăn cuối', fmtDateTimeVn(e.time)),
                    _stat('Khẩu phần', g(e.servedGram)),
                    _stat('Đã ăn', g(e.eatenGram)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, {Color? color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: color ?? DashboardColors.textPrimary),
          ),
        ],
      );
}
