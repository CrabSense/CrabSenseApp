import 'package:flutter/material.dart';

import '../../models/crab_individual.dart';
import '../../models/crab_lot_status.dart';
import '../../models/production_models.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/app_formatters.dart';
import '../crab/crab_auth_image.dart';
import '../shared/mgmt_ui.dart';
import 'crab_lot_inbound_table.dart';
import 'crab_lot_status_badge.dart';

String dash(String? v) {
  final t = v?.trim();
  if (t == null || t.isEmpty) return '—';
  return t;
}

String? noteValue(FarmingBatchRecord lot, List<String> prefixes) {
  final raw = lot.notes;
  if (raw == null || raw.trim().isEmpty) return null;
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    final t = line.trim();
    for (final p in prefixes) {
      if (t.toLowerCase().startsWith(p.toLowerCase())) {
        var rest = t.substring(p.length).trim();
        if (rest.startsWith(':')) rest = rest.substring(1).trim();
        if (rest.isNotEmpty) return rest;
      }
    }
  }
  return null;
}

class CrabLotInboundDetailPanel extends StatelessWidget {
  const CrabLotInboundDetailPanel({
    super.key,
    required this.lot,
    required this.crabs,
    required this.imageUrls,
    this.token = '',
    this.onClose,
    this.onPlace,
    this.onOpenFull,
    this.onOpenImage,
    this.onAddPhotos,
  });

  final FarmingBatchRecord lot;
  final List<CrabIndividual> crabs;
  final List<String> imageUrls;
  final String token;
  final VoidCallback? onClose;
  final VoidCallback? onPlace;
  final VoidCallback? onOpenFull;
  final ValueChanged<String>? onOpenImage;
  final VoidCallback? onAddPhotos;

  @override
  Widget build(BuildContext context) {
    final status = lot.workflowStatus;
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  'CHI TIẾT LÔ NHẬP',
                  style: bvText(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: DashboardColors.textMuted,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, size: 18, color: DashboardColors.textMuted),
                  splashRadius: 16,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: DashboardColors.mint),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: DashboardColors.mint,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.set_meal_rounded, size: 20, color: DashboardColors.brand),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: onOpenFull,
                            child: Text(
                              lot.batchCode.isEmpty ? '—' : lot.batchCode,
                              style: bvText(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: DashboardColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          CrabLotStatusBadge(status: status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  lot.lotName,
                  style: bvText(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhập ngày: ${_importStamp(lot.startDate)}',
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
                const SizedBox(height: 14),
                if (status == CrabLotWorkflowStatus.allocating) ...[
                  _progressBlock(lot),
                  const SizedBox(height: 12),
                  if (onPlace != null)
                    MgmtPrimaryButton(
                      label: 'Tiếp tục phân hộp',
                      trailing: Icons.arrow_forward_rounded,
                      onTap: onPlace,
                    ),
                  const SizedBox(height: 16),
                ],
                if (status == CrabLotWorkflowStatus.pending ||
                    status == CrabLotWorkflowStatus.inspecting) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kLotAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kLotAmber.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: kLotAmber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            status == CrabLotWorkflowStatus.inspecting
                                ? 'Lô này đang kiểm tra chất lượng.'
                                : 'Lô này chưa bắt đầu phân hộp.',
                            style: bvText(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: DashboardColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _kv('Số cua chờ', '${formatInt(lot.remainingCount)} con'),
                  const SizedBox(height: 10),
                  if (onPlace != null)
                    MgmtPrimaryButton(
                      label: status == CrabLotWorkflowStatus.pending
                          ? 'Bắt đầu xử lý'
                          : 'Tiếp tục phân hộp',
                      onTap: onPlace,
                    ),
                  const SizedBox(height: 16),
                ],
                if (status == CrabLotWorkflowStatus.cancelled) ...[
                  CrabLotStatusBadge(status: status),
                  const SizedBox(height: 10),
                  _kv(
                    'Lý do',
                    dash(noteValue(lot, const ['Lý do', 'Reason']) ??
                        (lot.notes?.trim().isNotEmpty == true ? lot.notes : null)),
                  ),
                  _kv(
                    'Người xác nhận',
                    dash(noteValue(lot, const ['Người xác nhận', 'Người nhập'])),
                  ),
                  _kv('Thời gian', _importStamp(lot.startDate)),
                  const SizedBox(height: 16),
                ],
                _section('Thông tin lô'),
                _kv('Nhà cung cấp', dash(lot.supplierName)),
                _kv('Số lượng nhập', '${formatInt(lot.initialQuantity)} con'),
                _kv(
                  'Đã phân hộp',
                  '${formatInt(lot.placedCount)} con (${lot.allocationPercent}%)',
                ),
                _kv(
                  'Còn chờ',
                  lot.remainingCount == 0 && lot.workflowStatus == CrabLotWorkflowStatus.completed
                      ? '0 con'
                      : lot.workflowStatus == CrabLotWorkflowStatus.cancelled
                          ? '—'
                          : '${formatInt(lot.remainingCount)} con',
                ),
                _kv(
                  'Hủy/Loại',
                  lot.rejectedCount == 0 ? '0 con' : '${formatInt(lot.rejectedCount)} con',
                ),
                _kv(
                  'Khu vực nhập',
                  dash(_areaLabel()),
                ),
                _kv(
                  'Người nhập',
                  dash(noteValue(lot, const ['Người nhập', 'Người xác nhận'])),
                ),
                _kv(
                  'Phương thức',
                  dash(noteValue(lot, const ['Phương thức', 'Vận chuyển'])),
                ),
                _kv(
                  'Khối lượng',
                  lot.totalWeightKg == null
                      ? '—'
                      : '${_num(lot.totalWeightKg!)} kg',
                ),
                _kv(
                  'Khối lượng trung bình',
                  lot.averageWeightGram == null
                      ? '—'
                      : '${lot.averageWeightGram!.toStringAsFixed(0)} g/con',
                ),
                _kv(
                  'Ghi chú',
                  dash(_plainNotes()),
                ),
                const SizedBox(height: 16),
                _gallery(),
                const SizedBox(height: 16),
                _timeline(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _areaLabel() {
    final fromNote = noteValue(lot, const ['Khu vực nhập', 'Khu nhập', 'Khu']);
    if (fromNote != null) return fromNote;
    if (crabs.isEmpty) return '';
    final names = crabs.map((c) => c.areaName.trim()).where((s) => s.isNotEmpty).toSet();
    if (names.isEmpty) return '';
    return names.join(', ');
  }

  String? _plainNotes() {
    final raw = lot.notes?.trim();
    if (raw == null || raw.isEmpty) return null;
    final skip = [
      'khu vực nhập',
      'khu nhập',
      'khu:',
      'phương thức',
      'vận chuyển',
      'người nhập',
      'người xác nhận',
      'lý do',
    ];
    final lines = raw.split(RegExp(r'\r?\n')).where((line) {
      final t = line.trim().toLowerCase();
      if (t.isEmpty) return false;
      return !skip.any(t.startsWith);
    }).toList();
    if (lines.isEmpty) return null;
    return lines.join('\n');
  }

  Widget _progressBlock(FarmingBatchRecord lot) {
    final pct = lot.allocationPercent;
    final color = lotProgressColor(lot);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến độ phân hộp',
            style: bvText(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatInt(lot.placedCount)} / ${formatInt(lot.initialQuantity)} con',
            style: bvText(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$pct%',
            style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Còn lại: ${formatInt(lot.remainingCount)} con',
            style: bvText(fontSize: 12, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _gallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hình ảnh lô nhập',
              style: bvText(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: DashboardColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (onAddPhotos != null)
              TextButton(
                onPressed: onAddPhotos,
                child: Text(
                  'Thêm ảnh',
                  style: bvText(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.brand,
                  ),
                ),
              ),
            if (imageUrls.isNotEmpty)
              Text(
                'Xem tất cả (${imageUrls.length})',
                style: bvText(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.brand,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (imageUrls.isEmpty)
          Container(
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Text(
              'Chưa có ảnh lô nhập',
              style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
            ),
          )
        else
          _thumbs(),
      ],
    );
  }

  Widget _thumbs() {
    final main = imageUrls.first;
    final rest = imageUrls.skip(1).toList();
    final shown = rest.take(3).toList();
    final extra = rest.length - shown.length;
    return Column(
      children: [
        GestureDetector(
          onTap: () => onOpenImage?.call(main),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _lotThumb(main, 0),
            ),
          ),
        ),
        if (shown.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onOpenImage?.call(shown[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _lotThumb(shown[i], i + 1),
                      ),
                    ),
                  ),
                ),
              ],
              if (extra > 0) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onOpenImage?.call(rest[shown.length]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ColoredBox(
                          color: const Color(0xFF12332D).withValues(alpha: 0.55),
                          child: Center(
                            child: Text(
                              '+$extra',
                              style: bvText(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _lotThumb(String url, int index) {
    final useLotProxy = lot.imageUrls.isNotEmpty;
    return CrabAuthImage(
      crabId: '',
      index: index,
      token: token,
      fallbackUrl: url,
      proxyUrl: useLotProxy ? CrabAuthImage.lotProxyUrl(lot.id, index) : null,
      fit: BoxFit.cover,
      error: _imgFallback(),
    );
  }

  Widget _imgFallback() {
    return const ColoredBox(
      color: DashboardColors.mint,
      child: Center(
        child: Icon(Icons.image_outlined, color: DashboardColors.brand),
      ),
    );
  }

  Widget _timeline() {
    final events = _events();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử xử lý',
          style: bvText(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < events.length; i++)
          _tlRow(events[i], last: i == events.length - 1),
      ],
    );
  }

  List<({String time, String title, bool done})> _events() {
    final stamp = _importStamp(lot.startDate);
    final status = lot.workflowStatus;
    final list = <({String time, String title, bool done})>[
      (time: stamp, title: 'Nhập kho', done: true),
    ];
    if (status == CrabLotWorkflowStatus.inspecting) {
      list.add((time: stamp, title: 'Đang kiểm tra chất lượng', done: false));
      return list;
    }
    if (status == CrabLotWorkflowStatus.pending) {
      list.add((time: '—', title: 'Chờ phân hộp', done: false));
      return list;
    }
    list.add((time: stamp, title: 'Kiểm tra chất lượng', done: true));
    if (lot.placedCount > 0) {
      list.add((
        time: stamp,
        title: 'Phân hộp (${lot.placedCount}/${lot.initialQuantity})',
        done: status == CrabLotWorkflowStatus.completed,
      ));
    }
    if (status == CrabLotWorkflowStatus.completed) {
      list.add((time: stamp, title: 'Hoàn tất', done: true));
    }
    if (status == CrabLotWorkflowStatus.cancelled) {
      list.add((time: stamp, title: 'Đã hủy', done: true));
    }
    return list;
  }

  Widget _tlRow(({String time, String title, bool done}) e, {required bool last}) {
    final color = e.done ? DashboardColors.brandGreen : kLotSlate;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: e.done ? DashboardColors.brandGreen : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.6),
                ),
                child: e.done
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
              if (!last)
                Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: DashboardColors.mint,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.time,
                  style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                ),
                Text(
                  e.title,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: bvText(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: DashboardColors.textPrimary,
        ),
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
            width: 128,
            child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
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
        ],
      ),
    );
  }

  String _importStamp(DateTime d) {
    final local = d.isUtc ? d.toLocal() : d;
    if (local.hour == 0 && local.minute == 0) return formatDate(local);
    return fmtDateTimeVn(local);
  }

  String _num(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
