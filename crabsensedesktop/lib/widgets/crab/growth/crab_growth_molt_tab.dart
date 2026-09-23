import 'package:flutter/material.dart';

import '../../../models/camera_device.dart';
import '../../../models/crab_growth_molt.dart';
import '../../../models/crab_individual.dart';
import '../../../services/cloud_api_client.dart';
import '../../../services/crab_growth_molt_controller.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import '../feeding/feeding_history_table.dart';
import '../feeding/feeding_trend_charts.dart';
import 'growth_charts.dart';
import 'growth_history_table.dart';
import 'growth_record_modal.dart';
import 'molt_history.dart';

/// Nội dung tab "Sinh trưởng & Lột xác" trong Chi tiết cua.
class CrabGrowthMoltTab extends StatefulWidget {
  const CrabGrowthMoltTab({
    super.key,
    required this.crab,
    required this.controller,
    required this.token,
    required this.api,
    this.cameras = const [],
    this.operatorName,
    this.onRecorded,
  });

  final CrabIndividual crab;
  final CrabGrowthMoltController controller;
  final String token;
  final CloudApiClient api;
  final List<CameraDevice> cameras;
  final String? operatorName;
  final VoidCallback? onRecorded;

  @override
  State<CrabGrowthMoltTab> createState() => _CrabGrowthMoltTabState();
}

class _CrabGrowthMoltTabState extends State<CrabGrowthMoltTab> {
  CrabGrowthMoltController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_rebuild);
    if (_c.data == null && !_c.loading) _c.load();
  }

  @override
  void dispose() {
    _c.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    final input = await showGrowthRecordModal(
      context,
      crabCode: widget.crab.code,
      token: widget.token,
      api: widget.api,
      cameras: widget.cameras,
    );
    if (input == null || !mounted) return;
    final err = await _c.record(input, crab: widget.crab, operatorName: widget.operatorName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ??
              (input.isMolt ? 'Đã ghi nhận lần lột xác mới.' : 'Đã ghi nhận sinh trưởng thành công.'),
        ),
      ),
    );
    if (err == null) widget.onRecorded?.call();
  }

  Future<void> _onRow(GrowthMeasurement m, GrowthRowAction a) async {
    switch (a) {
      case GrowthRowAction.detail:
        await showGrowthMeasurementDetail(context, m, widget.token);
      case GrowthRowAction.editNote:
        final note = await _editNote(m);
        if (note == null || !mounted) return;
        final err = await _c.updateNote(m, note);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Đã cập nhật ghi chú')));
      case GrowthRowAction.viewPhotos:
        if (m.photoUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lần đo này chưa có ảnh.')));
          return;
        }
        await showFeedingLightbox(context, urls: m.photoUrls, token: widget.token);
    }
  }

  Future<String?> _editNote(GrowthMeasurement m) {
    final ctrl = TextEditingController(text: m.note ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Chỉnh sửa ghi chú', style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          maxLength: 500,
          autofocus: true,
          style: bvText(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Ghi chú lần đo',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          MgmtOutlineButton(label: 'Hủy', onTap: () => Navigator.of(ctx).pop()),
          MgmtPrimaryButton(label: 'Lưu', height: 38, onTap: () => Navigator.of(ctx).pop(ctrl.text.trim())),
        ],
      ),
    );
  }

  String? _cameraLabel(String? id) {
    if (id == null || id.isEmpty) return null;
    final cam = widget.cameras.where((c) => c.id == id || c.cameraCode == id).firstOrNull;
    return cam == null ? id : '${cam.name} (${cam.cameraCode})';
  }

  @override
  Widget build(BuildContext context) {
    final data = _c.data;
    final loading = _c.loading && data == null;
    final error = _c.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 16),
        if (error != null && data == null)
          _error(error)
        else ...[
          _kpis(data, loading),
          const SizedBox(height: 16),
          _charts(data, loading),
          const SizedBox(height: 16),
          _history(data, loading),
          const SizedBox(height: 16),
          if (!loading) _insight(data),
        ],
      ],
    );
  }

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
                const Icon(Icons.trending_up_rounded, size: 20, color: DashboardColors.brand),
                const SizedBox(width: 8),
                Text('Sinh trưởng & Lột xác',
                    style: bvText(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Theo dõi cân nặng, kích thước và lịch sử lột xác của cua theo thời gian.',
              style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MgmtPrimaryButton(icon: Icons.add_rounded, label: 'Ghi nhận', onTap: _add, height: 36),
            _PeriodChips(value: _c.period, onChanged: _c.setPeriod),
          ],
        ),
      ],
    );
  }

  Widget _kpis(CrabGrowthMoltData? data, bool loading) {
    final latest = data?.latest;
    final w = latest?.weightGram ?? data?.currentWeightGram;
    final sw = latest?.shellWidthMm ?? data?.currentWidthMm;
    final sl = latest?.shellLengthMm ?? data?.currentLengthMm;
    final wd = data?.weightDelta;
    final dW = data?.widthDelta;
    final dL = data?.lengthDelta;
    final molt = data?.lastMolt;

    final cards = [
      _Kpi(
        icon: Icons.monitor_weight_outlined,
        label: 'Cân nặng hiện tại',
        value: loading ? null : (w == null ? '—' : fmtGram(w)),
        sub: loading || wd == null ? null : '${wd >= 0 ? '↑' : '↓'} ${fmtSignedGram(wd)} so với lần đo trước',
        down: wd != null && wd < 0,
      ),
      _Kpi(
        icon: Icons.straighten_outlined,
        label: 'Kích thước hiện tại',
        value: loading ? null : fmtShellSize(sw, sl),
        sub: loading || (dW == null && dL == null)
            ? null
            : '↑ ${fmtSignedMmPair(dW, dL)} so với lần đo trước',
      ),
      _Kpi(
        icon: Icons.autorenew_rounded,
        label: 'Số lần lột xác',
        value: loading ? null : '${data?.molts.length ?? 0} lần',
      ),
      _Kpi(
        icon: Icons.calendar_today_outlined,
        label: 'Lần lột xác gần nhất',
        value: loading ? null : (molt == null ? '—' : fmtDateVn(molt.at)),
        sub: loading || molt == null ? null : fmtRelativeAgo(molt.at),
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

  Widget _charts(CrabGrowthMoltData? data, bool loading) {
    return LayoutBuilder(
      builder: (context, c) {
        final a = loading
            ? const ChartSkeleton(height: 240)
            : WeightTrendChart(points: data?.measurements ?? const [], onAdd: _add);
        final b = loading
            ? const ChartSkeleton(height: 240)
            : ShellSizeTrendChart(points: data?.measurements ?? const [], onAdd: _add);
        if (c.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)],
          );
        }
        return Column(children: [a, const SizedBox(height: 16), b]);
      },
    );
  }

  Widget _history(CrabGrowthMoltData? data, bool loading) {
    final measures = [...?data?.measurements].reversed.toList();
    final table = GrowthHistoryTable(
      rows: measures,
      token: widget.token,
      loading: loading,
      onAction: _onRow,
    );
    final molts = MoltHistoryCard(
      molts: data?.molts ?? const [],
      token: widget.token,
      loading: loading,
      error: _c.moltError,
      onRetry: _c.load,
      onOpen: (e) => showMoltDetailDrawer(
        context,
        event: e,
        token: widget.token,
        cameraLabel: _cameraLabel(e.cameraId),
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1040) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(flex: 6, child: table), const SizedBox(width: 16), Expanded(flex: 4, child: molts)],
          );
        }
        return Column(children: [table, const SizedBox(height: 16), molts]);
      },
    );
  }

  Widget _insight(CrabGrowthMoltData? data) {
    final insight = data?.insight();
    if (insight == null) return const SizedBox.shrink();
    final color = insight.stable ? DashboardColors.brand : kGrowthAmber;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.stable ? Icons.info_outline_rounded : Icons.warning_amber_rounded, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nhận định', style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.textMuted)),
                const SizedBox(height: 2),
                Text(insight.title, style: bvText(fontSize: 14.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                const SizedBox(height: 4),
                Text(insight.body, style: bvText(fontSize: 13, height: 1.45, color: DashboardColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 30, color: DashboardColors.risk),
          const SizedBox(height: 10),
          Text('Không thể tải dữ liệu sinh trưởng.',
              style: bvText(fontSize: 14, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
          const SizedBox(height: 4),
          Text(error, textAlign: TextAlign.center, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 14),
          MgmtOutlineButton(icon: Icons.refresh_rounded, label: 'Thử lại', onTap: _c.load),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.label, this.value, this.sub, this.down = false});

  final IconData icon;
  final String label;
  final String? value;
  final String? sub;
  final bool down;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: mgmtCardDeco(radius: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: DashboardColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: bvText(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: DashboardColors.textMuted)),
                const SizedBox(height: 4),
                if (value == null)
                  Container(
                    width: 80,
                    height: 22,
                    decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(6)),
                  )
                else
                  Text(value!, style: bvText(fontSize: 22, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary, height: 1.1)),
                if (sub != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sub!,
                    style: bvText(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: down ? DashboardColors.risk : DashboardColors.brand,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.value, required this.onChanged});

  final GrowthPeriod value;
  final ValueChanged<GrowthPeriod> onChanged;

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
          for (final p in GrowthPeriod.values)
            InkWell(
              onTap: () => onChanged(p),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: value == p ? DashboardColors.mint : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.label,
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: value == p ? DashboardColors.brand : DashboardColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
