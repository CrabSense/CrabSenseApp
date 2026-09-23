import 'package:flutter/material.dart';

import '../../../models/crab_growth_molt.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import '../crab_auth_image.dart';
import '../feeding/feeding_history_table.dart';

class MoltHistoryCard extends StatelessWidget {
  const MoltHistoryCard({
    super.key,
    required this.molts,
    required this.token,
    required this.onOpen,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final List<MoltEvent> molts;
  final String token;
  final ValueChanged<MoltEvent> onOpen;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch sử lột xác',
                  style: bvText(fontSize: 14.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardColors.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${molts.length} LẦN',
                  style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const _MoltSkeleton()
          else if (error != null)
            Column(
              children: [
                Text('Không tải được lịch sử lột xác.', style: bvText(fontSize: 12.5, color: DashboardColors.risk)),
                const SizedBox(height: 8),
                MgmtOutlineButton(icon: Icons.refresh_rounded, label: 'Thử lại', onTap: onRetry, height: 32),
              ],
            )
          else if (molts.isEmpty)
            Text('Chưa có lần lột xác nào được ghi nhận.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))
          else
            for (final m in molts.reversed) ...[
              _MoltEventTile(event: m, token: token, onOpen: () => onOpen(m)),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _MoltSkeleton extends StatelessWidget {
  const _MoltSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++)
          Container(
            height: 88,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(12)),
          ),
      ],
    );
  }
}

class _MoltEventTile extends StatelessWidget {
  const _MoltEventTile({required this.event, required this.token, required this.onOpen});

  final MoltEvent event;
  final String token;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final labels = ['trước lột', 'đang lột', 'sau lột'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: e.status.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Lần ${e.number}', style: bvText(fontSize: 13.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              const SizedBox(width: 8),
              MgmtStatusBadge(label: e.status.label, color: e.status.color),
              const Spacer(),
              Text(fmtDateVn(e.at), style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _mini('Trước lột', fmtGram(e.weightBeforeGram)),
              _mini('Sau lột', fmtGram(e.weightAfterGram)),
              _mini('Tăng', e.weightDelta == null ? '—' : fmtSignedGram(e.weightDelta)),
            ],
          ),
          const SizedBox(height: 8),
          if (e.startedAt != null) _line('Thời gian bắt đầu', fmtDateTimeVn(e.startedAt)),
          if (e.completedAt != null) _line('Hoàn tất', fmtDateTimeVn(e.completedAt)),
          if (e.duration != null) _line('Thời gian lột', fmtDurationVn(e.duration!)),
          if ((e.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(e.note!.trim(), style: bvText(fontSize: 12.5, height: 1.4, color: DashboardColors.textPrimary)),
          ],
          const SizedBox(height: 10),
          if (e.photoUrls.isEmpty)
            Text('Không có hình ảnh cho lần lột này.', style: bvText(fontSize: 12, color: DashboardColors.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < e.photoUrls.length && i < 3; i++)
                  Column(
                    children: [
                      InkWell(
                        onTap: () => showFeedingLightbox(context, urls: e.photoUrls, token: token, initial: i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CrabAuthImage(
                            crabId: '',
                            index: i,
                            token: token,
                            fallbackUrl: e.photoUrls[i],
                            proxyUrl: e.id.isNotEmpty ? CrabAuthImage.moltProxyUrl(e.id, i) : null,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(i < labels.length ? labels[i] : 'Ảnh ${i + 1}',
                          style: bvText(fontSize: 10.5, color: DashboardColors.textMuted)),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OverviewLinkish(label: 'Xem chi tiết', onTap: onOpen),
          ),
        ],
      ),
    );
  }

  Widget _mini(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
          Text(v, style: bvText(fontSize: 13, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
        ],
      );

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text('$k: $v', style: bvText(fontSize: 12, color: DashboardColors.textPrimary)),
      );
}

class OverviewLinkish extends StatelessWidget {
  const OverviewLinkish({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: DashboardColors.brand,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text('$label →', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
    );
  }
}

Future<void> showMoltDetailDrawer(BuildContext context, {required MoltEvent event, required String token, String? cameraLabel}) {
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
          child: _MoltDrawer(
            event: event,
            token: token,
            cameraLabel: cameraLabel,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _MoltDrawer extends StatelessWidget {
  const _MoltDrawer({required this.event, required this.token, required this.onClose, this.cameraLabel});

  final MoltEvent event;
  final String token;
  final VoidCallback onClose;
  final String? cameraLabel;

  @override
  Widget build(BuildContext context) {
    final e = event;
    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 140, child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
              Expanded(child: Text(v, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary))),
            ],
          ),
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
          child: Row(
            children: [
              const Icon(Icons.autorenew_rounded, size: 18, color: DashboardColors.brand),
              const SizedBox(width: 8),
              Text('Chi tiết lần lột xác', style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              const Spacer(),
              IconButton(onPressed: onClose, icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted)),
            ],
          ),
        ),
        const Divider(height: 1, color: DashboardColors.mint),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              kv('Lần', '${e.number}'),
              kv('Ngày', fmtDateVn(e.at)),
              kv('Trạng thái', e.status.label),
              kv('Bắt đầu', e.startedAt == null ? '—' : fmtDateTimeVn(e.startedAt)),
              kv('Hoàn tất', e.completedAt == null ? '—' : fmtDateTimeVn(e.completedAt)),
              kv('Thời lượng', e.duration == null ? '—' : fmtDurationVn(e.duration!)),
              kv('Trước lột', fmtGram(e.weightBeforeGram)),
              kv('Sau lột', fmtGram(e.weightAfterGram)),
              kv('Tăng', e.weightDelta == null ? '—' : fmtSignedGram(e.weightDelta)),
              kv('Kích thước trước', fmtShellSize(e.shellWidthBeforeMm, e.shellLengthBeforeMm)),
              kv('Kích thước sau', fmtShellSize(e.shellWidthAfterMm, e.shellLengthAfterMm)),
              kv('Nguồn', e.sourceLabel),
              kv('Camera', (cameraLabel ?? e.cameraId)?.isNotEmpty == true ? (cameraLabel ?? e.cameraId!) : '—'),
              kv('Ghi chú', (e.note ?? '').trim().isEmpty ? '—' : e.note!.trim()),
              const SizedBox(height: 8),
              Text('Ảnh / Video', style: bvText(fontSize: 13, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              const SizedBox(height: 8),
              if (e.photoUrls.isEmpty)
                Text('Không có hình ảnh cho lần lột này.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < e.photoUrls.length; i++)
                      InkWell(
                        onTap: () => showFeedingLightbox(context, urls: e.photoUrls, token: token, initial: i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CrabAuthImage(
                            crabId: '',
                            index: i,
                            token: token,
                            fallbackUrl: e.photoUrls[i],
                            proxyUrl: e.id.isNotEmpty ? CrabAuthImage.moltProxyUrl(e.id, i) : null,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
