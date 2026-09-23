import 'package:flutter/material.dart';

import '../../../models/crab_feeding_activity.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import 'feeding_history_table.dart';

/// Drawer phải "Chi tiết lần cho ăn".
Future<void> showFeedingEventDrawer(
  BuildContext context, {
  required FeedingEvent event,
  required String token,
  required String cameraLabel,
  FeedingThresholds thresholds = FeedingThresholds.defaults,
  VoidCallback? onEditNote,
  VoidCallback? onViewCamera,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Đóng',
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        elevation: 12,
        child: SizedBox(
          width: 420,
          height: double.infinity,
          child: FeedingEventDrawer(
            event: event,
            token: token,
            cameraLabel: cameraLabel,
            thresholds: thresholds,
            onClose: () => Navigator.of(ctx).pop(),
            onEditNote: onEditNote == null
                ? null
                : () {
                    Navigator.of(ctx).pop();
                    onEditNote();
                  },
            onViewCamera: onViewCamera == null
                ? null
                : () {
                    Navigator.of(ctx).pop();
                    onViewCamera();
                  },
          ),
        ),
      ),
    ),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class FeedingEventDrawer extends StatelessWidget {
  const FeedingEventDrawer({
    super.key,
    required this.event,
    required this.token,
    required this.cameraLabel,
    required this.onClose,
    this.thresholds = FeedingThresholds.defaults,
    this.onEditNote,
    this.onViewCamera,
  });

  final FeedingEvent event;
  final String token;
  final String cameraLabel;
  final VoidCallback onClose;
  final FeedingThresholds thresholds;
  final VoidCallback? onEditNote;
  final VoidCallback? onViewCamera;

  @override
  Widget build(BuildContext context) {
    final e = event;
    String g(double? v) => v == null ? '—' : '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} g';
    String act(int? v) => v == null ? '—' : '$v / 100 • ${thresholds.activityLabel(v)}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
          child: Row(
            children: [
              const Icon(Icons.restaurant_rounded, size: 18, color: DashboardColors.brand),
              const SizedBox(width: 8),
              Text(
                'Chi tiết lần cho ăn',
                style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Đóng',
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, size: 20, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: DashboardColors.mint),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _section('Thông tin cho ăn'),
              _kv('Thời gian', fmtDateTimeVn(e.time)),
              _kv('Thức ăn', e.foodType.isEmpty ? '—' : e.foodType),
              _kv('Khẩu phần', g(e.servedGram)),
              _kv('Đã ăn', g(e.eatenGram)),
              _kv('Thức ăn dư', g(e.leftoverGram)),
              _kvWidget('Mức ăn', FeedingPercentBadge(percent: e.feedingPercent, thresholds: thresholds)),
              _kv('Thời gian ăn', e.durationMinutes == null ? '—' : '${e.durationMinutes} phút'),
              const SizedBox(height: 14),
              _section('Vận động'),
              _kvColored('Vận động trước', act(e.activityBefore), e.activityBefore),
              _kvColored('Vận động sau', act(e.activityAfter), e.activityAfter),
              const SizedBox(height: 14),
              _section('Nguồn ghi nhận'),
              _kv('Người thực hiện', e.performerLabel),
              _kv('Nguồn', e.sourceLabel),
              _kv('Camera', cameraLabel),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _section('Ghi chú')),
                  if (onEditNote != null)
                    TextButton.icon(
                      onPressed: onEditNote,
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: Text('Chỉnh sửa', style: bvText(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(
                        foregroundColor: DashboardColors.brand,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DashboardColors.lightMint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DashboardColors.mint),
                ),
                child: Text(
                  e.note ?? '—',
                  style: bvText(
                    fontSize: 13,
                    height: 1.45,
                    color: e.note == null ? DashboardColors.textMuted : DashboardColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _section('Hình ảnh / Video'),
              if (e.photoUrls.isEmpty)
                Text(
                  'Không có hình ảnh/video cho lần cho ăn này.',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < e.photoUrls.length; i++)
                      FeedingPhotoThumb(
                        url: e.photoUrls[i],
                        token: token,
                        size: 84,
                        onTap: () => showFeedingLightbox(context, urls: e.photoUrls, token: token, initial: i),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn vào ảnh để xem toàn màn hình.',
                  style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                ),
              ],
              if (onViewCamera != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: MgmtOutlineButton(
                    icon: Icons.videocam_outlined,
                    label: 'Xem camera liên quan',
                    onTap: onViewCamera,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: bvText(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: DashboardColors.textMuted,
          ),
        ),
      );

  Widget _kv(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(label, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
            Expanded(
              child: Text(
                value,
                style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
              ),
            ),
          ],
        ),
      );

  Widget _kvColored(String label, String value, int? score) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 130, child: Text(label, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
            if (score != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: thresholds.activityColor(score), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value,
                style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
              ),
            ),
          ],
        ),
      );

  Widget _kvWidget(String label, Widget value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 130, child: Text(label, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
            value,
          ],
        ),
      );
}

/// Dialog nhỏ chỉnh sửa ghi chú (có audit ở BE qua UpdatedAt).
Future<String?> showEditFeedingNoteDialog(BuildContext context, FeedingEvent event) {
  final ctrl = TextEditingController(text: event.note ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Chỉnh sửa ghi chú',
        style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lần cho ăn ${fmtDateTimeVn(event.time)} • ${event.foodType}',
              style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              autofocus: true,
              style: bvText(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú…',
                hintStyle: bvText(fontSize: 13, color: DashboardColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thay đổi được lưu kèm thời gian cập nhật (audit).',
              style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        MgmtOutlineButton(label: 'Hủy', onTap: () => Navigator.of(ctx).pop()),
        MgmtPrimaryButton(
          label: 'Lưu ghi chú',
          height: 38,
          onTap: () => Navigator.of(ctx).pop(ctrl.text.trim()),
        ),
      ],
    ),
  );
}
