import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/water_analysis.dart';
import '../../services/water_analysis_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';
import 'water_analysis_widgets.dart';

Future<void> showAnalysisDetailDrawer({
  required BuildContext context,
  required WaterAnalysisRun run,
  required WaterAnalysisService service,
  WaterAnalysisSnapshot? snapshot,
  Future<bool> Function()? onRerun,
  VoidCallback? onOpenController,
  VoidCallback? onOpenAlert,
}) {
  final size = MediaQuery.sizeOf(context);
  final width = size.width < 640
      ? size.width
      : size.width < 1100
          ? 560.0
          : (size.width * 0.45).clamp(620.0, 720.0);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Chi tiết phân tích',
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, __) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.white,
          elevation: 8,
          child: SizedBox(
            width: width,
            height: size.height,
            child: AnalysisDetailDrawer(
              run: run,
              service: service,
              snapshot: snapshot,
              onRerun: onRerun,
              onOpenController: onOpenController,
              onOpenAlert: onOpenAlert,
            ),
          ),
        ),
      );
    },
  );
}

class AnalysisDetailDrawer extends StatefulWidget {
  const AnalysisDetailDrawer({
    super.key,
    required this.run,
    required this.service,
    this.snapshot,
    this.onRerun,
    this.onOpenController,
    this.onOpenAlert,
  });

  final WaterAnalysisRun run;
  final WaterAnalysisService service;
  final WaterAnalysisSnapshot? snapshot;
  final Future<bool> Function()? onRerun;
  final VoidCallback? onOpenController;
  final VoidCallback? onOpenAlert;

  @override
  State<AnalysisDetailDrawer> createState() => _AnalysisDetailDrawerState();
}

class _AnalysisDetailDrawerState extends State<AnalysisDetailDrawer> {
  WaterAnalysisDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await widget.service.fetchDetail(widget.run.id);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('CloudApiException: ', '');
        _loading = false;
      });
    }
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _export() async {
    final d = _detail;
    if (d == null) return;
    final html = _reportHtml(d);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất báo cáo phân tích',
      fileName: '${d.displayCode}.html',
      type: FileType.custom,
      allowedExtensions: const ['html'],
    );
    if (path == null) return;
    await File(path).writeAsString(html);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xuất báo cáo. Mở file và in ra PDF.')),
    );
  }

  Future<void> _rerun() async {
    final d = _detail;
    if (d == null) return;
    final ok = await showRerunAnalysisDialog(
      context: context,
      detail: d,
      snapshot: widget.snapshot,
    );
    if (ok != true) return;
    if (widget.onRerun == null) {
      _close();
      return;
    }
    final started = await widget.onRerun!.call();
    if (!mounted) return;
    if (started) {
      _close();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.service.error ?? 'Chưa thể chạy lại — hệ thống chưa sẵn sàng.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) {
            _close();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: _loading
                      ? _skeleton()
                      : _error != null
                          ? _errorState()
                          : _body(),
                ),
                if (!_loading && _error == null) _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final d = _detail;
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFD8E9E4))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DashboardColors.lightMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.science_outlined,
                      color: DashboardColors.brand, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chi tiết phân tích',
                    style: bvText(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: _close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (d != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    d.displayCode,
                    style: bvText(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                  MgmtStatusBadge(
                    label: d.statusLabel,
                    color: _runColor(d.status),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Phân tích lúc: ${waClock(d.completedAt ?? d.startedAt, withSeconds: true)}\nThời lượng: ${waDuration(d.duration)}',
                      style: bvText(
                        fontSize: 12,
                        color: DashboardColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                  MgmtStatusBadge(
                    label: d.evaluationLabel,
                    color: waStatusColor(d.evaluation),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final d = _detail!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        _summaryRow(d),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth < 520) {
              return Column(
                children: [
                  _sampleInfo(d),
                  const SizedBox(height: 12),
                  _analysisInfo(d),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _sampleInfo(d)),
                const SizedBox(width: 12),
                Expanded(child: _analysisInfo(d)),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth < 520) {
              return Column(
                children: [
                  _hardware(d),
                  const SizedBox(height: 12),
                  _colors(d),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _hardware(d)),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: _colors(d)),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _timeline(d),
        if (d.alert != null) ...[
          const SizedBox(height: 12),
          _alert(d.alert!),
        ],
        if (d.previous != null) ...[
          const SizedBox(height: 12),
          _previous(d.previous!),
        ],
        const SizedBox(height: 12),
        _technical(d),
      ],
    );
  }

  Widget _summaryRow(WaterAnalysisDetail d) {
    return LayoutBuilder(
      builder: (context, c) {
        final stack = c.maxWidth < 520;
        final cards = [
          _resultCard(d),
          _confidenceCard(d),
          _imageCard(d),
        ];
        if (stack) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: bvText(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _resultCard(WaterAnalysisDetail d) {
    return _card(
      title: 'Kết quả',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.analyteLabel,
              style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            d.resultText,
            style: bvText(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          MgmtStatusBadge(
            label: d.evaluationLabel,
            color: waStatusColor(d.evaluation),
          ),
          const SizedBox(height: 8),
          Text(
            d.thresholdDisplay == null
                ? 'Ngưỡng: chưa cấu hình'
                : 'Ngưỡng bình thường: ${d.thresholdDisplay}',
            style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
          ),
          if (d.overThreshold != null)
            Text(
              'Cao hơn ngưỡng: +${d.overThreshold} ${d.unit}',
              style: bvText(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: kWaAmber,
              ),
            ),
          if (d.status.toLowerCase() == 'failed') ...[
            const SizedBox(height: 6),
            Text(
              'Failed at: ${d.failedStep ?? 'Không xác định'}',
              style: bvText(fontSize: 12, color: kWaRed),
            ),
            if (d.error != null)
              Text(d.error!,
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _confidenceCard(WaterAnalysisDetail d) {
    if (!d.usedAi) {
      return _card(
        title: 'Độ tin cậy AI',
        child: Text(
          'Lần phân tích này không sử dụng AI.',
          style: bvText(fontSize: 13, color: DashboardColors.textMuted),
        ),
      );
    }
    final pct = ((d.confidence ?? 0) * 100).round();
    final low = d.confidenceLevel == 'low';
    return _card(
      title: 'Độ tin cậy AI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$pct%',
            style: bvText(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: d.confidence ?? 0,
              minHeight: 6,
              backgroundColor: DashboardColors.lightMint,
              color: low ? kWaAmber : DashboardColors.brand,
            ),
          ),
          const SizedBox(height: 8),
          MgmtStatusBadge(
            label: low
                ? '⚠ Độ tin cậy thấp'
                : (d.confidenceLabel ?? 'Độ tin cậy'),
            color: low ? kWaAmber : DashboardColors.brandGreen,
          ),
          const SizedBox(height: 6),
          Text(
            low
                ? 'Khuyến nghị chạy lại phép thử hoặc kiểm tra ảnh mẫu.'
                : 'Kết quả được AI phân tích từ ảnh mẫu.',
            style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _imageCard(WaterAnalysisDetail d) {
    final url = d.imageUrl;
    return _card(
      title: 'Ảnh mẫu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DashboardColors.cardBorder),
              ),
              child: url == null
                  ? Center(
                      child: Text(
                        'Không có ảnh mẫu cho lần phân tích này.',
                        textAlign: TextAlign.center,
                        style: bvText(
                          fontSize: 12,
                          color: DashboardColors.textMuted,
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => showSampleImageLightbox(context, url),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          semanticLabel: 'Ảnh mẫu ${d.displayCode}',
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          MgmtOutlineButton(
            label: 'Xem ảnh đầy đủ',
            onTap: url == null
                ? null
                : () => showSampleImageLightbox(context, url),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
            title,
            style: bvText(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
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
  }

  Widget _sampleInfo(WaterAnalysisDetail d) {
    return _section('Thông tin mẫu', [
      _kv('Khu vực', d.areaLabel),
      _kv(
        'Nguồn mẫu',
        d.sampleSourceLabel?.isNotEmpty == true
            ? d.sampleSourceLabel!
            : 'Không xác định',
      ),
      _kv(
        'Vị trí lấy mẫu',
        d.sampleLocation?.isNotEmpty == true
            ? d.sampleLocation!
            : 'Chưa ghi nhận vị trí lấy mẫu',
      ),
      _kv(
        'Ghi chú',
        d.notes?.isNotEmpty == true ? d.notes! : 'Không có ghi chú',
      ),
    ]);
  }

  Widget _analysisInfo(WaterAnalysisDetail d) {
    return _section('Thông tin phân tích', [
      _kv('Chỉ tiêu', d.analyteLabel),
      _kv('Phương pháp', d.method),
      _kv(
        'Người thực hiện',
        d.performedBy?.isNotEmpty == true
            ? d.performedBy!
            : 'Không xác định',
      ),
      _kv('Bắt đầu', waClock(d.startedAt, withSeconds: true)),
      _kv(
        'Hoàn thành',
        d.completedAt == null
            ? 'Chưa hoàn thành'
            : waClock(d.completedAt, withSeconds: true),
      ),
      _kv('Thời lượng', waDuration(d.duration)),
    ]);
  }

  Widget _hardware(WaterAnalysisDetail d) {
    return _section('Thiết bị sử dụng', [
      for (final h in d.hardware)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: h.clickable && h.code == 'controller'
                ? widget.onOpenController
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Icon(waStationIcon(h.code),
                    size: 16, color: DashboardColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.label,
                          style: bvText(
                            fontSize: 12.5,
                            color: DashboardColors.textMuted,
                          )),
                      Text(
                        h.deviceId?.isNotEmpty == true
                            ? h.deviceId!
                            : h.code == 'camera'
                                ? 'Không sử dụng Camera'
                                : 'Không xác định',
                        style: bvText(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                MgmtStatusBadge(
                  label: h.stateLabel,
                  color: h.ready ? DashboardColors.brandGreen : kWaRed,
                ),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _colors(WaterAnalysisDetail d) {
    return _section('Mẫu màu tham chiếu', [
      if (d.colorReference.isEmpty)
        Text(
          'Không có bộ màu tham chiếu cho chỉ tiêu này.',
          style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
        )
      else ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in d.colorReference)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hex(s.hex),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: s.selected ? DashboardColors.brand : const Color(0xFFD8E9E4),
                    width: s.selected ? 2.4 : 1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          d.colorReferenceNote ??
              'So sánh màu mẫu với màu tham chiếu để AI xác định nồng độ.',
          style: bvText(fontSize: 12, color: DashboardColors.textMuted),
        ),
      ],
    ]);
  }

  Widget _timeline(WaterAnalysisDetail d) {
    return _section('Nhật ký quy trình', [
      if (d.legacySteps)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: MgmtStatusBadge(label: 'Dữ liệu cũ', color: kWaSlate),
        ),
      if (d.steps.isEmpty)
        Text(
          'Lần phân tích này chưa ghi nhận chi tiết quy trình.',
          style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
        )
      else
        for (final s in d.steps) _stepRow(s),
    ]);
  }

  Widget _stepRow(WaterAnalysisProcessStep s) {
    final color = s.isFailed
        ? kWaRed
        : s.isDone
            ? DashboardColors.brandGreen
            : s.status.toUpperCase() == 'RUNNING'
                ? DashboardColors.brand
                : kWaSlate;
    final time = s.at == null
        ? ''
        : TimeOfDay.fromDateTime(s.at!.isUtc ? s.at!.toLocal() : s.at!)
            .format(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            s.isFailed
                ? Icons.cancel
                : s.isDone
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(
              time.isEmpty ? '—' : time,
              style: bvText(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DashboardColors.brand,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.label,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                if (s.detail != null)
                  Text(s.detail!,
                      style: bvText(
                        fontSize: 12,
                        color: DashboardColors.textMuted,
                      )),
                const SizedBox(height: 4),
                MgmtStatusBadge(label: s.statusLabel, color: color),
                if (s.isFailed) ...[
                  const SizedBox(height: 6),
                  Text(
                    s.errorCode ?? 'STEP_FAILED',
                    style: bvText(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kWaRed,
                    ),
                  ),
                  if (s.errorMessage != null)
                    Text(s.errorMessage!,
                        style: bvText(
                          fontSize: 12.5,
                          color: DashboardColors.textPrimary,
                        )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      MgmtOutlineButton(
                        label: 'Thử lại bước',
                        onTap: () => widget.service.load(),
                      ),
                      MgmtOutlineButton(
                        label: 'Xả & kết thúc',
                        color: kWaRed,
                        onTap: () async {
                          await widget.service.stop();
                          _close();
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alert(WaterAnalysisRelatedAlert a) {
    return _section('Cảnh báo liên quan', [
      Text(a.title,
          style: bvText(
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary,
          )),
      Text(a.code, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
      const SizedBox(height: 8),
      MgmtOutlineButton(
        label: 'Xem cảnh báo →',
        onTap: widget.onOpenAlert,
      ),
    ]);
  }

  Widget _previous(WaterAnalysisPrevious p) {
    final delta = p.delta;
    return _section('Lần trước', [
      Text(
        '${p.value == null ? 'Không có kết quả' : '${p.value} ${p.unit}'}'
        '${p.at == null ? '' : '  •  ${waClock(p.at)}'}',
        style: bvText(
          fontWeight: FontWeight.w700,
          color: DashboardColors.textPrimary,
        ),
      ),
      if (delta != null)
        Text(
          'Change: ${delta > 0 ? '+' : ''}$delta ${p.unit}',
          style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
        ),
    ]);
  }

  Widget _technical(WaterAnalysisDetail d) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            'Thông tin kỹ thuật',
            style: bvText(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          children: [
            _uuidRow('Internal UUID', d.internalId ?? d.id),
            _kv('Analysis session ID', d.displayCode),
            _kv('AI model', d.aiModelId ?? 'Không xác định'),
            _kv(
              'Model version',
              d.aiModelVersion ?? 'Không xác định',
            ),
            _kv(
              'Controller firmware',
              d.firmwareVersion ?? 'Không xác định',
            ),
            _kv(
              'Image storage path',
              d.imagePath ?? 'Không có ảnh',
            ),
          ],
        ),
      ),
    );
  }

  Widget _uuidRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(k,
                style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          ),
          Expanded(
            child: Text(
              v,
              style: bvText(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: DashboardColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sao chép',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: v));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép UUID.')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD8E9E4))),
      ),
      child: Row(
        children: [
          MgmtOutlineButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Xuất PDF',
            onTap: _detail == null ? null : _export,
          ),
          const Spacer(),
          MgmtPrimaryButton(
            icon: Icons.play_arrow_rounded,
            label: 'Chạy lại phân tích',
            onTap: _detail == null ? null : _rerun,
          ),
          const SizedBox(width: 8),
          MgmtOutlineButton(label: 'Đóng', onTap: _close),
        ],
      ),
    );
  }

  Widget _skeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        WaSkeletonBox(height: 72),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: WaSkeletonBox(height: 140)),
            SizedBox(width: 10),
            Expanded(child: WaSkeletonBox(height: 140)),
            SizedBox(width: 10),
            Expanded(child: WaSkeletonBox(height: 140)),
          ],
        ),
        SizedBox(height: 12),
        WaSkeletonBox(height: 160),
        SizedBox(height: 12),
        WaSkeletonBox(height: 220),
      ],
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '⚠ Không thể tải chi tiết phân tích.',
            style: bvText(
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(_error ?? '',
              textAlign: TextAlign.center,
              style: bvText(color: DashboardColors.textMuted)),
          const SizedBox(height: 14),
          MgmtOutlineButton(label: 'Thử lại', onTap: _load),
        ],
      ),
    );
  }

  Color _runColor(String status) => switch (status.toLowerCase()) {
        'completed' => DashboardColors.brandGreen,
        'running' => DashboardColors.brand,
        'failed' => kWaRed,
        'cancelled' => kWaSlate,
        _ => kWaSlate,
      };

  Color _hex(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFFE8F5F0);
  }

  String _reportHtml(WaterAnalysisDetail d) {
    final steps = d.steps
        .map((s) =>
            '<li>${s.label} — ${s.statusLabel}${s.detail == null ? '' : ': ${s.detail}'}</li>')
        .join();
    return '''
<!doctype html><html><head><meta charset="utf-8"><title>${d.displayCode}</title></head>
<body style="font-family:Be Vietnam Pro,Arial;color:#12332D">
<h1>Chi tiết phân tích ${d.displayCode}</h1>
<p>Chỉ tiêu: ${d.analyteLabel} · Kết quả: ${d.resultText} · ${d.evaluationLabel}</p>
<p>Ngưỡng: ${d.thresholdDisplay ?? 'chưa cấu hình'}</p>
<p>AI: ${d.usedAi ? '${((d.confidence ?? 0) * 100).round()}%' : 'Không sử dụng AI'}</p>
<p>Mẫu: ${d.areaLabel} · ${d.sampleSourceLabel ?? ''} · ${d.sampleLocation ?? ''}</p>
<p>Người thực hiện: ${d.performedBy ?? 'Không xác định'}</p>
<p>Thời gian: ${waClock(d.startedAt, withSeconds: true)} → ${waClock(d.completedAt, withSeconds: true)} (${waDuration(d.duration)})</p>
<h2>Quy trình</h2><ol>$steps</ol>
</body></html>
''';
  }
}

Future<bool?> showRerunAnalysisDialog({
  required BuildContext context,
  required WaterAnalysisDetail detail,
  WaterAnalysisSnapshot? snapshot,
}) {
  final blockers = snapshot?.blockers ?? const <WaterAnalysisBlocker>[];
  final can = snapshot?.canStart == true && blockers.isEmpty;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Chạy lại phân tích ${detail.analyteLabel}?',
        style: bvText(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: DashboardColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Khu vực: ${detail.areaLabel}',
                style: bvText(color: DashboardColors.textPrimary)),
            Text(
              'Nguồn mẫu: ${detail.sampleSourceLabel ?? 'Không xác định'}',
              style: bvText(color: DashboardColors.textPrimary),
            ),
            const SizedBox(height: 12),
            if (!can)
              AnalysisPrerequisitePanel(
                blockers: blockers.isEmpty
                    ? const [
                        WaterAnalysisBlocker(
                          code: 'not_ready',
                          label: 'Hệ thống',
                          reason: 'Chưa sẵn sàng để chạy lại.',
                        )
                      ]
                    : blockers,
                onRecheck: () {},
              )
            else
              Text(
                'Hệ thống sẵn sàng. Xác nhận để bắt đầu quy trình mới.',
                style: bvText(color: DashboardColors.textMuted),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        MgmtPrimaryButton(
          label: 'Bắt đầu',
          onTap: can ? () => Navigator.pop(ctx, true) : null,
        ),
      ],
    ),
  );
}
