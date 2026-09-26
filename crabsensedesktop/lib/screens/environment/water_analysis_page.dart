import 'package:flutter/material.dart';

import '../../models/auth_models.dart';
import '../../models/water_analysis.dart';
import '../../navigation/app_route.dart';
import '../../services/water_analysis_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/environment/analysis_detail_drawer.dart';
import '../../widgets/environment/water_analysis_widgets.dart';
import '../../widgets/shared/mgmt_ui.dart';

/// Phân tích hóa học (thuốc thử + camera + AI) — không phải sensor realtime.
class WaterAnalysisPage extends StatefulWidget {
  const WaterAnalysisPage({
    super.key,
    required this.service,
    this.areaName,
    this.areaCode,
    this.session,
    this.onNavigate,
  });

  final WaterAnalysisService service;
  final String? areaName;
  final String? areaCode;
  final AuthSession? session;
  final void Function(AppRoute route)? onNavigate;

  @override
  State<WaterAnalysisPage> createState() => _WaterAnalysisPageState();
}

class _WaterAnalysisPageState extends State<WaterAnalysisPage> {
  String _analyte = 'NO2';
  String _trend = 'no2';

  WaterAnalysisService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
    _svc.load();
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    final assays = _svc.snapshot?.assays ?? const <WaterAnalysisAssay>[];
    if (assays.isNotEmpty &&
        !assays.any((a) =>
            a.configured && a.analyte.toUpperCase() == _analyte.toUpperCase())) {
      final first = assays.firstWhere(
        (a) => a.configured,
        orElse: () => assays.first,
      );
      _analyte = first.analyte;
    }
    setState(() {});
  }

  String get _areaName {
    final fromSample = _svc.snapshot?.sample?.areaName;
    if (fromSample != null && fromSample.isNotEmpty) return fromSample;
    return widget.areaName ?? widget.session?.selectedFarm.name ?? 'Khu vực';
  }

  String get _areaCode {
    final fromSample = _svc.snapshot?.sample?.areaCode;
    if (fromSample != null && fromSample.isNotEmpty) return fromSample;
    return widget.areaCode ?? widget.session?.selectedFarm.code ?? '';
  }

  String get _areaLabel {
    if (_areaCode.isEmpty || _areaCode == _areaName) return _areaName;
    return '$_areaCode — $_areaName';
  }

  WaterAnalysisAssay? get _selectedAssay {
    final assays = _svc.snapshot?.assays ?? const <WaterAnalysisAssay>[];
    for (final a in assays) {
      if (a.analyte.toUpperCase() == _analyte.toUpperCase()) return a;
    }
    return null;
  }

  List<WaterAnalysisStepDef> get _steps {
    final fromApi = _svc.snapshot?.steps ?? const <WaterAnalysisStepDef>[];
    if (fromApi.isNotEmpty) return fromApi;
    return [
      for (var i = 0; i < WaterAnalysisSteps.labels.length; i++)
        WaterAnalysisStepDef(
          index: i + 1,
          label: WaterAnalysisSteps.labels[i],
          command: '',
        ),
    ];
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openDetail(WaterAnalysisRun run) {
    return showAnalysisDetailDrawer(
      context: context,
      run: run,
      service: _svc,
      snapshot: _svc.snapshot,
      onRerun: () => _svc.start(
        analyte: run.analyte ?? _analyte,
        sampleSource: _svc.snapshot?.sample?.sampleSource,
        sampleLocation: _svc.snapshot?.sample?.sampleLocation,
        notes: _svc.snapshot?.sample?.notes,
      ),
      onOpenController: () {
        Navigator.of(context).maybePop();
        widget.onNavigate?.call(AppRoute.controllers);
      },
      onOpenAlert: () {
        Navigator.of(context).maybePop();
        widget.onNavigate?.call(AppRoute.alerts);
      },
    );
  }

  Future<void> _start() async {
    final assay = _selectedAssay;
    if (assay == null || !assay.configured) {
      _toast('Chỉ tiêu $_analyte chưa được cấu hình.');
      return;
    }
    if (!_svc.canStart) {
      _toast(_svc.error ?? 'Chưa thể bắt đầu — hệ thống chưa sẵn sàng.');
      return;
    }
    final sample = _svc.snapshot?.sample;
    final ok = await _svc.start(
      analyte: assay.analyte,
      sampleSource: sample?.sampleSource,
      sampleLocation: sample?.sampleLocation,
      notes: sample?.notes,
    );
    if (!ok) _toast(_svc.error ?? 'Không bắt đầu được');
  }

  Future<void> _stop() async {
    final go = await confirmStopAnalysis(context);
    if (!go) return;
    final ok = await _svc.stop();
    if (!ok) _toast(_svc.error ?? 'Không dừng được');
  }

  Future<void> _editSample() async {
    final snap = _svc.snapshot;
    if (snap?.sample == null) return;
    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (_) => SampleEditDialog(
        sample: snap!.sample!,
        sources: snap.sampleSources,
        areaLabel: _areaLabel,
      ),
    );
    if (result == null) return;
    final ok = await _svc.updateSample(
      sampleSource: result.$1,
      sampleLocation: result.$2.isEmpty ? null : result.$2,
      notes: result.$3.isEmpty ? null : result.$3,
    );
    _toast(ok ? 'Đã cập nhật thông tin mẫu.' : (_svc.error ?? 'Không lưu được'));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final mobile = w < 760;
    final tablet = w < 1180;
    final snap = _svc.snapshot;
    final loading = _svc.loading && snap == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 16),
          if (loading) ...[
            _latestSkeleton(),
            const SizedBox(height: 16),
            _bodySkeleton(tablet),
          ] else ...[
            if (_svc.error != null && snap == null)
              _errorBanner(_svc.error!, _svc.load)
            else ...[
              _latest(snap, mobile),
              const SizedBox(height: 16),
              if (tablet) ...[
                _leftColumn(snap, mobile),
                const SizedBox(height: 14),
                _systemColumn(snap),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 70, child: _leftColumn(snap, false)),
                    const SizedBox(width: 14),
                    Expanded(flex: 30, child: _systemColumn(snap)),
                  ],
                ),
              const SizedBox(height: 16),
              _imageAi(snap),
              const SizedBox(height: 16),
              if (tablet) ...[
                _history(snap, asCards: mobile),
                const SizedBox(height: 14),
                _trendCard(snap),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 60, child: _history(snap, asCards: false)),
                    const SizedBox(width: 14),
                    Expanded(flex: 40, child: _trendCard(snap)),
                  ],
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _header() {
    final sample = _svc.snapshot?.sample;
    final sources = _svc.snapshot?.sampleSources ?? const <WaterAnalysisSourceOption>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DashboardColors.lightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.science_outlined, color: DashboardColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phân tích nước',
                      style: bvText(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Kiểm tra hóa học pH • NH3 • NO2 • NO3 bằng thuốc thử + camera + AI. Không lấy số từ sensor realtime.',
                      style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                    ),
                  ],
                ),
              ),
              MgmtOutlineButton(
                icon: Icons.refresh_rounded,
                label: 'Làm mới',
                onTap: () => _svc.load(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Khu vực: $_areaLabel',
                style: bvText(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.textPrimary,
                ),
              ),
              Text(
                'Nguồn mẫu:',
                style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
              ),
              if (sources.isEmpty)
                Text(
                  sample?.sampleSourceLabel ?? 'Nước tuần hoàn RAS',
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textPrimary,
                  ),
                )
              else
                SizedBox(
                  width: 220,
                  child: MgmtDropdown<String>(
                    valueLabel: sample?.sampleSourceLabel ?? 'Nguồn mẫu',
                    items: [for (final s in sources) (s.code, s.label)],
                    onSelected: (code) {
                      _svc.updateSample(
                        sampleSource: code,
                        sampleLocation: sample?.sampleLocation,
                        notes: sample?.notes,
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _latest(WaterAnalysisSnapshot? snap, bool mobile) {
    final latest = snap?.latest;
    final metrics = latest?.metrics ?? const <WaterAnalysisMetric>[];
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
                  'Kết quả phân tích mới nhất',
                  style: bvText(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              if (latest != null) ...[
                Flexible(
                  child: Text(
                    'Phân tích lúc: ${waClock(latest.completedAt ?? latest.startedAt, withSeconds: true)}',
                    textAlign: TextAlign.right,
                    style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Mã: ${latest.displayCode}',
                  style: bvText(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                MgmtOutlineButton(
                  label: 'Xem chi tiết →',
                  onTap: () => _openDetail(latest),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (latest == null)
            const MgmtEmptyState(
              icon: Icons.science_outlined,
              title: 'Chưa có kết quả phân tích',
              message:
                  'Bắt đầu lần phân tích đầu tiên khi hệ thống đã sẵn sàng.',
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth < 640
                    ? 1
                    : c.maxWidth < 980
                        ? 2
                        : 4;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: cols == 1 ? 2.4 : 1.55,
                  children: [
                    for (final m in metrics) AnalysisResultCard(metric: m),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _leftColumn(WaterAnalysisSnapshot? snap, bool verticalSteps) {
    return Column(
      children: [
        WaSectionCard(
          title: 'Chỉ tiêu phân tích',
          subtitle: 'Chọn chỉ tiêu hoặc phân tích tất cả.',
          child: AnalyteSelector(
            assays: snap?.assays.isNotEmpty == true
                ? snap!.assays
                : const [
                    WaterAnalysisAssay(
                      analyte: 'NO2',
                      label: 'NO2',
                      configured: true,
                    ),
                    WaterAnalysisAssay(
                      analyte: 'NH3',
                      label: 'NH3',
                      configured: false,
                    ),
                    WaterAnalysisAssay(
                      analyte: 'NO3',
                      label: 'NO3',
                      configured: false,
                    ),
                    WaterAnalysisAssay(
                      analyte: 'PH',
                      label: 'pH',
                      configured: false,
                    ),
                  ],
            selected: _analyte,
            onSelected: (v) => setState(() => _analyte = v),
          ),
        ),
        const SizedBox(height: 14),
        WaSectionCard(
          title: 'Thông tin mẫu',
          trailing: MgmtOutlineButton(
            icon: Icons.edit_outlined,
            label: 'Chỉnh sửa',
            onTap: _editSample,
          ),
          child: _sampleRows(snap),
        ),
        const SizedBox(height: 14),
        _workflow(snap, verticalSteps),
      ],
    );
  }

  Widget _sampleRows(WaterAnalysisSnapshot? snap) {
    final s = snap?.sample;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(k,
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              ),
              Expanded(
                child: Text(
                  v,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
    return Column(
      children: [
        row('Khu vực', _areaLabel),
        row('Nguồn mẫu', s?.sampleSourceLabel ?? '—'),
        row('Vị trí lấy mẫu', s?.sampleLocation?.isNotEmpty == true
            ? s!.sampleLocation!
            : '—'),
        row('Ghi chú', s?.notes?.isNotEmpty == true ? s!.notes! : '—'),
      ],
    );
  }

  Widget _workflow(WaterAnalysisSnapshot? snap, bool vertical) {
    final active = snap?.active;
    final running = active?.isRunning == true;
    final assay = _selectedAssay;
    final label = assay?.label ?? _analyte;
    final failed = active?.isFailed == true;
    return WaSectionCard(
      title: running ? 'Đang phân tích $label' : 'Quy trình phân tích $label',
      trailing: running
          ? Text(
              waMmss(active?.remainingSeconds),
              style: bvText(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: DashboardColors.brand,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalysisWorkflowStepper(
            steps: _steps,
            currentStep: active?.currentStep ?? 0,
            running: running || failed,
            failed: failed,
            vertical: vertical,
          ),
          if (running) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ((active?.progressPct ?? 0) / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: DashboardColors.lightMint,
                color: DashboardColors.brand,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${active?.progressPct ?? 0}%  •  ${active?.stepLabel ?? ''}'
              '${active?.remainingSeconds == null ? '' : ' — còn ${waMmss(active!.remainingSeconds)}'}',
              style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: MgmtOutlineButton(
                icon: Icons.stop_circle_outlined,
                label: _svc.stopping ? 'Đang dừng…' : 'Dừng phân tích',
                color: kWaRed,
                onTap: _svc.stopping ? null : _stop,
              ),
            ),
          ],
          if (active?.isFailed == true && active?.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kWaRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kWaRed.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✕ ${active!.error}',
                    style: bvText(
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                  if (active.cameraId != null)
                    Text(
                      'Camera: ${active.cameraId}',
                      style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      MgmtOutlineButton(
                        label: 'Thử lại Camera',
                        onTap: () => _svc.load(),
                      ),
                      MgmtOutlineButton(
                        label: 'Hủy & Xả mẫu',
                        color: kWaRed,
                        onTap: _stop,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _systemColumn(WaterAnalysisSnapshot? snap) {
    final parts = snap?.station ?? const <WaterAnalysisStationPart>[];
    final blockers = snap?.blockers ?? const <WaterAnalysisBlocker>[];
    final can = snap?.canStart == true &&
        (_selectedAssay?.configured ?? false) &&
        !_svc.starting &&
        !_svc.isRunning;
    final label = _selectedAssay?.label ?? _analyte;
    return Column(
      children: [
        WaSectionCard(
          title: 'Hệ thống phân tích',
          trailing: MgmtOutlineButton(
            label: 'Kiểm tra hệ thống',
            onTap: () => showSystemDiagnosticDialog(
              context: context,
              parts: parts,
              onRecheck: () => _svc.load(),
            ),
          ),
          child: parts.isEmpty
              ? Column(
                  children: [
                    Text(
                      '⚠ Không thể kiểm tra trạng thái hệ thống.',
                      style: bvText(color: kWaAmber, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    MgmtOutlineButton(
                      label: 'Thử lại',
                      onTap: () => _svc.load(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    for (final p in parts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(waStationIcon(p.code),
                                size: 18, color: DashboardColors.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.label,
                                    style: bvText(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: DashboardColors.textPrimary,
                                    ),
                                  ),
                                  if (p.levelLabel != null)
                                    Text(
                                      p.levelLabel!,
                                      style: bvText(
                                        fontSize: 11.5,
                                        color: DashboardColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            MgmtStatusBadge(
                              label: p.stateLabel,
                              color: p.ready
                                  ? DashboardColors.brandGreen
                                  : kWaRed,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        if (blockers.isNotEmpty)
          AnalysisPrerequisitePanel(
            blockers: blockers,
            onRecheck: () => _svc.load(),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Text(
              'Hệ thống sẵn sàng. Có thể bắt đầu phân tích $label.',
              style: bvText(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DashboardColors.textPrimary,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Tooltip(
          message: can
              ? 'Bắt đầu quy trình $label'
              : (blockers.isNotEmpty
                  ? blockers.map((b) => '${b.label}: ${b.reason}').join('\n')
                  : 'Chỉ tiêu chưa cấu hình hoặc hệ thống đang bận.'),
          child: MgmtPrimaryButton(
            icon: Icons.play_arrow_rounded,
            label: _svc.starting
                ? 'Đang khởi tạo…'
                : 'Bắt đầu phân tích $label',
            onTap: can ? _start : null,
          ),
        ),
      ],
    );
  }

  Widget _imageAi(WaterAnalysisSnapshot? snap) {
    final run = snap?.latest ?? snap?.active;
    final conf = run?.confidence;
    final min = _selectedAssay?.aiConfidenceMin ?? 0.75;
    final low = conf != null && conf < min;
    final metric = run?.metricOf((_analyte).toLowerCase()) ??
        run?.metrics.where((m) => m.value != null).firstOrNull;
    return WaSectionCard(
      title: 'Ảnh mẫu & kết quả AI (lần gần nhất)',
      child: LayoutBuilder(
        builder: (context, c) {
          final stack = c.maxWidth < 820;
          final image = _sampleThumb(run);
          final ai = _aiCard(run, metric, conf, low);
          if (stack) {
            return Column(children: [image, const SizedBox(height: 12), ai]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: image),
              const SizedBox(width: 14),
              Expanded(flex: 6, child: ai),
            ],
          );
        },
      ),
    );
  }

  Widget _sampleThumb(WaterAnalysisRun? run) {
    final url = run?.imageUrl;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Material(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: url == null
              ? null
              : () => showSampleImageLightbox(context, url),
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: url == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.science_outlined,
                          size: 36, color: DashboardColors.brand),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa có ảnh mẫu',
                        style: bvText(color: DashboardColors.textMuted),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _aiCard(
    WaterAnalysisRun? run,
    WaterAnalysisMetric? metric,
    double? conf,
    bool low,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric?.label ?? run?.displayAnalyte ?? '—',
                      style: bvText(
                        fontSize: 12.5,
                        color: DashboardColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      metric == null
                          ? 'Chưa có kết quả AI'
                          : '${metric.displayValue}${metric.unit.isEmpty ? '' : ' ${metric.unit}'}',
                      style: bvText(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MgmtStatusBadge(
                      label: metric?.statusLabel ?? 'Chưa có',
                      color: waStatusColor(metric?.status ?? 'pending'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Độ tin cậy AI',
                      style: bvText(
                        fontSize: 12.5,
                        color: DashboardColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      conf == null ? '—' : '${(conf * 100).round()}%',
                      style: bvText(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: conf ?? 0,
                        minHeight: 6,
                        backgroundColor: DashboardColors.lightMint,
                        color: low ? kWaAmber : DashboardColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (low) ...[
          const SizedBox(height: 10),
          Text(
            '⚠ Độ tin cậy thấp. Khuyến nghị kiểm tra lại mẫu hoặc chạy phân tích lại. Không coi kết quả là chắc chắn.',
            style: bvText(fontSize: 12.5, color: kWaAmber, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: MgmtOutlineButton(
            label: 'Xem ảnh đầy đủ',
            onTap: run?.imageUrl == null
                ? null
                : () => showSampleImageLightbox(context, run!.imageUrl!),
          ),
        ),
      ],
    );
  }

  Widget _history(WaterAnalysisSnapshot? snap, {required bool asCards}) {
    return WaSectionCard(
      title: 'Lịch sử phân tích',
      trailing: MgmtOutlineButton(
        label: 'Xem tất cả →',
        onTap: snap?.history.isEmpty == true
            ? null
            : () => _openDetail(snap!.history.first),
      ),
      child: _svc.historyError != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _svc.historyError!,
                  style: bvText(color: kWaRed),
                ),
                const SizedBox(height: 8),
                MgmtOutlineButton(label: 'Thử lại', onTap: () => _svc.load()),
              ],
            )
          : (snap?.history.isEmpty ?? true)
              ? Text(
                  'Chưa có lịch sử phân tích.',
                  style: bvText(color: DashboardColors.textMuted),
                )
              : AnalysisHistoryTable(
                  rows: snap!.history.take(8).toList(),
                  asCards: asCards,
                  onOpen: _openDetail,
                ),
    );
  }

  Widget _trendCard(WaterAnalysisSnapshot? snap) {
    final assays = snap?.assays ?? const <WaterAnalysisAssay>[];
    final thr = snap?.thresholds
        .where((t) => t.code.toLowerCase() == _trend)
        .firstOrNull;
    return WaSectionCard(
      title: 'Xu hướng ${_trend.toUpperCase()} (7 ngày)',
      trailing: SizedBox(
        width: 120,
        child: MgmtDropdown<String>(
          valueLabel: _trend.toUpperCase(),
          items: assays.isEmpty
              ? const [('no2', 'NO2'), ('nh3', 'NH3'), ('no3', 'NO3'), ('ph', 'pH')]
              : [for (final a in assays) (a.analyte.toLowerCase(), a.label)],
          onSelected: (v) => setState(() => _trend = v),
        ),
      ),
      child: AnalysisTrendChart(
        points: _trendPoints(snap),
        analyteLabel: _trend.toUpperCase(),
        threshold: thr,
      ),
    );
  }

  Widget _latestSkeleton() {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              const Expanded(child: WaSkeletonBox(height: 120)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _bodySkeleton(bool tablet) {
    return tablet
        ? const Column(
            children: [
              WaSkeletonBox(height: 180),
              SizedBox(height: 12),
              WaSkeletonBox(height: 220),
            ],
          )
        : const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 70, child: WaSkeletonBox(height: 280)),
              SizedBox(width: 14),
              Expanded(flex: 30, child: WaSkeletonBox(height: 280)),
            ],
          );
  }

  List<WaterAnalysisTrendPoint> _trendPoints(WaterAnalysisSnapshot? snap) {
    if (snap == null) return const [];
    if (_trend == (snap.trendAnalyte ?? 'no2') && snap.trend.isNotEmpty) {
      return snap.trend;
    }
    final cutoff = DateTime.now().toLocal();
    final start = DateTime(cutoff.year, cutoff.month, cutoff.day)
        .subtract(const Duration(days: 6));
    final out = <WaterAnalysisTrendPoint>[];
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      for (final r in snap.history) {
        final at = (r.completedAt ?? r.startedAt).toLocal();
        if (DateTime(at.year, at.month, at.day) != day) continue;
        final m = r.metricOf(_trend);
        if (m?.value == null) continue;
        out.add(WaterAnalysisTrendPoint(
          date: day,
          value: m!.value!,
          status: m.status,
          statusLabel: m.statusLabel,
          testCode: r.testCode,
          runId: r.id,
        ));
        break;
      }
    }
    return out;
  }

  Widget _errorBanner(String msg, VoidCallback retry) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWaAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kWaAmber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(msg, style: bvText(color: DashboardColors.textPrimary)),
          ),
          MgmtOutlineButton(label: 'Thử lại', onTap: retry),
        ],
      ),
    );
  }
}
