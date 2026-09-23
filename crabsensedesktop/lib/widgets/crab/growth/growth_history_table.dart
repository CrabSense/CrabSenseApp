import 'package:flutter/material.dart';

import '../../../models/crab_growth_molt.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import '../feeding/feeding_history_table.dart';

enum GrowthRowAction { detail, editNote, viewPhotos }

class GrowthHistoryTable extends StatelessWidget {
  const GrowthHistoryTable({
    super.key,
    required this.rows,
    required this.token,
    required this.onAction,
    this.loading = false,
  });

  final List<GrowthMeasurement> rows;
  final String token;
  final void Function(GrowthMeasurement m, GrowthRowAction a) onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Text(
              'Lịch sử đo sinh trưởng',
              style: bvText(fontSize: 14.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
            ),
          ),
          const Divider(height: 1, color: DashboardColors.mint),
          if (loading)
            const Padding(padding: EdgeInsets.all(16), child: OverviewishSkeleton())
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
              child: Text('Chưa có lần đo nào trong khoảng thời gian này.',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 640),
                child: Column(
                  children: [
                    _header(),
                    for (var i = 0; i < rows.length; i++) _row(rows[i], i < rows.length - 1 ? rows[i + 1] : null),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    const labels = ['NGÀY ĐO', 'CÂN NẶNG (g)', 'RỘNG MAI (mm)', 'DÀI MAI (mm)', 'THAY ĐỔI', 'NGƯỜI GHI', ''];
    const widths = [110.0, 110.0, 120.0, 120.0, 90.0, 140.0, 44.0];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: DashboardColors.lightMint,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            SizedBox(
              width: widths[i],
              child: Text(
                labels[i],
                style: bvText(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: DashboardColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(GrowthMeasurement m, GrowthMeasurement? older) {
    final delta = older == null ? null : m.weightGram - older.weightGram;
    final up = delta != null && delta > 0;
    final down = delta != null && delta < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: DashboardColors.mint))),
      child: Row(
        children: [
          _cell(110, fmtDateVn(m.measuredAt)),
          _cell(110, m.weightGram.toStringAsFixed(m.weightGram % 1 == 0 ? 0 : 1), bold: true),
          _cell(120, m.shellWidthMm == null ? '—' : m.shellWidthMm!.toStringAsFixed(m.shellWidthMm! % 1 == 0 ? 0 : 1)),
          _cell(120, m.shellLengthMm == null ? '—' : m.shellLengthMm!.toStringAsFixed(m.shellLengthMm! % 1 == 0 ? 0 : 1)),
          SizedBox(
            width: 90,
            child: Text(
              delta == null ? '—' : fmtSignedGram(delta),
              style: bvText(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: down
                    ? DashboardColors.risk
                    : up
                        ? DashboardColors.brand
                        : DashboardColors.textMuted,
              ),
            ),
          ),
          _cell(140, m.recorderLabel),
          SizedBox(
            width: 44,
            child: PopupMenuButton<GrowthRowAction>(
              tooltip: 'Thao tác',
              padding: EdgeInsets.zero,
              onSelected: (a) => onAction(m, a),
              itemBuilder: (_) => [
                _item(GrowthRowAction.detail, Icons.visibility_outlined, 'Xem chi tiết'),
                _item(GrowthRowAction.editNote, Icons.edit_outlined, 'Chỉnh sửa ghi chú'),
                _item(GrowthRowAction.viewPhotos, Icons.photo_outlined, 'Xem ảnh'),
              ],
              child: Icon(Icons.more_horiz_rounded, size: 18, color: DashboardColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<GrowthRowAction> _item(GrowthRowAction a, IconData icon, String label) => PopupMenuItem(
        value: a,
        height: 38,
        child: Row(
          children: [
            Icon(icon, size: 16, color: DashboardColors.textMuted),
            const SizedBox(width: 8),
            Text(label, style: bvText(fontSize: 13, color: DashboardColors.textPrimary)),
          ],
        ),
      );

  Widget _cell(double w, String t, {bool bold = false}) => SizedBox(
        width: w,
        child: Text(
          t,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: bvText(
            fontSize: 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: DashboardColors.textPrimary,
          ),
        ),
      );
}

class OverviewishSkeleton extends StatelessWidget {
  const OverviewishSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
          width: w,
          height: 12,
          decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(6)),
        );
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [bar(90), const SizedBox(width: 16), Expanded(child: bar(double.infinity))]),
          ),
      ],
    );
  }
}

Future<void> showGrowthMeasurementDetail(BuildContext context, GrowthMeasurement m, String token) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Chi tiết lần đo', style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Ngày đo', fmtDateTimeVn(m.measuredAt)),
            _kv('Cân nặng', fmtGram(m.weightGram)),
            _kv('Kích thước', fmtShellSize(m.shellWidthMm, m.shellLengthMm)),
            _kv('Người ghi', m.recorderLabel),
            _kv('Ghi chú', (m.note ?? '').trim().isEmpty ? '—' : m.note!.trim()),
            if (m.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < m.photoUrls.length; i++)
                    InkWell(
                      onTap: () => showFeedingLightbox(context, urls: m.photoUrls, token: token, initial: i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FeedingPhotoThumb(url: m.photoUrls[i], token: token, size: 64),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [MgmtOutlineButton(label: 'Đóng', onTap: () => Navigator.of(ctx).pop())],
    ),
  );
}

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
          Expanded(child: Text(v, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary))),
        ],
      ),
    );
