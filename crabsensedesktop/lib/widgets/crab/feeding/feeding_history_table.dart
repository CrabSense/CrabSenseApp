import 'package:flutter/material.dart';

import '../../../config/app_env.dart';
import '../../../models/crab_feeding_activity.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import '../crab_auth_image.dart';

enum FeedingEventAction { detail, editNote, viewPhotos, viewCamera }

String resolveFeedingPhotoUrl(String url) {
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  if (u.startsWith('/')) return '${AppEnv.cloudApiUrl}$u';
  return '${AppEnv.cloudApiUrl}/$u';
}

/// Badge "Mức ăn": 80–100 emerald, 50–79 amber, 1–49 cam, 0 đỏ "Không ăn".
class FeedingPercentBadge extends StatelessWidget {
  const FeedingPercentBadge({
    super.key,
    required this.percent,
    this.thresholds = FeedingThresholds.defaults,
    this.compact = false,
  });

  final int? percent;
  final FeedingThresholds thresholds;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = percent;
    if (p == null) {
      return Text('—', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted));
    }
    final color = thresholds.feedingColor(p);
    final label = p <= 0 ? '0% • Không ăn' : '$p%';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: bvText(fontSize: compact ? 11 : 12, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

/// "Bình thường → Cao" với chấm màu theo nhãn.
class ActivityTransition extends StatelessWidget {
  const ActivityTransition({
    super.key,
    required this.before,
    required this.after,
    this.thresholds = FeedingThresholds.defaults,
  });

  final int? before;
  final int? after;
  final FeedingThresholds thresholds;

  @override
  Widget build(BuildContext context) {
    if (before == null && after == null) {
      return Text('—', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted));
    }
    Widget part(int? v) {
      if (v == null) {
        return Text('—', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted));
      }
      final c = thresholds.activityColor(v);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            thresholds.activityLabel(v),
            style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary),
          ),
        ],
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        part(before),
        Icon(Icons.arrow_forward_rounded, size: 13, color: DashboardColors.textMuted),
        part(after),
      ],
    );
  }
}

class FeedingPhotoThumb extends StatelessWidget {
  const FeedingPhotoThumb({
    super.key,
    required this.url,
    required this.token,
    this.size = 40,
    this.onTap,
  });

  final String url;
  final String token;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          color: DashboardColors.mint,
          child: CrabAuthImage(
            crabId: '',
            index: 0,
            token: token,
            proxyUrl: resolveFeedingPhotoUrl(url),
            fallbackUrl: resolveFeedingPhotoUrl(url),
            width: size,
            height: size,
            fit: BoxFit.cover,
            error: Icon(Icons.broken_image_outlined, size: 18, color: DashboardColors.textMuted),
          ),
        ),
      ),
    );
  }
}

/// Lightbox ảnh (hình ảnh lần cho ăn).
Future<void> showFeedingLightbox(
  BuildContext context, {
  required List<String> urls,
  required String token,
  int initial = 0,
}) {
  var index = initial.clamp(0, urls.length - 1);
  return showDialog<void>(
    context: context,
    barrierColor: const Color.fromRGBO(5, 20, 16, 0.85),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Hình ảnh ${index + 1}/${urls.length}',
                  style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            Flexible(
              child: Row(
                children: [
                  IconButton(
                    onPressed: urls.length > 1
                        ? () => setState(() => index = (index - 1 + urls.length) % urls.length)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CrabAuthImage(
                        key: ValueKey(urls[index]),
                        crabId: '',
                        index: 0,
                        token: token,
                        proxyUrl: resolveFeedingPhotoUrl(urls[index]),
                        fallbackUrl: resolveFeedingPhotoUrl(urls[index]),
                        fit: BoxFit.contain,
                        error: Center(
                          child: Text('Không tải được ảnh', style: bvText(color: Colors.white70)),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: urls.length > 1
                        ? () => setState(() => index = (index + 1) % urls.length)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Table ─────────────────────────────────────────────────────────────────

class FeedingHistoryTable extends StatelessWidget {
  const FeedingHistoryTable({
    super.key,
    required this.events,
    required this.token,
    required this.sort,
    required this.sortDesc,
    required this.onSort,
    required this.onRowTap,
    required this.onAction,
    this.thresholds = FeedingThresholds.defaults,
    this.selectedId,
  });

  final List<FeedingEvent> events;
  final String token;
  final FeedingSort sort;
  final bool sortDesc;
  final ValueChanged<FeedingSort> onSort;
  final ValueChanged<FeedingEvent> onRowTap;
  final void Function(FeedingEvent event, FeedingEventAction action) onAction;
  final FeedingThresholds thresholds;
  final String? selectedId;

  static const _cols = <_Col>[
    _Col('THỜI GIAN', 130, sort: FeedingSort.time),
    _Col('THỨC ĂN', 130, flex: 1),
    _Col('KHẨU PHẦN', 90, sort: FeedingSort.served),
    _Col('ĐÃ ĂN', 80),
    _Col('MỨC ĂN', 110, sort: FeedingSort.feedingPercent),
    _Col('VẬN ĐỘNG (TRƯỚC / SAU)', 190, sort: FeedingSort.activity),
    _Col('GHI CHÚ', 150, flex: 2),
    _Col('NGƯỜI THỰC HIỆN', 130),
    _Col('HÌNH ẢNH', 74),
    _Col('', 44),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final fixed = _cols.where((x) => x.flex == 0).fold<double>(0, (s, x) => s + x.width);
        final totalFlex = _cols.fold<int>(0, (s, x) => s + x.flex);
        final flexBase = _cols.where((x) => x.flex > 0).fold<double>(0, (s, x) => s + x.width);
        final spare = (c.maxWidth - 32 - fixed - flexBase).clamp(0, double.infinity);
        double widthOf(_Col col) => col.flex == 0 ? col.width : col.width + spare * col.flex / totalFlex;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: DashboardColors.lightMint,
                border: Border(bottom: BorderSide(color: DashboardColors.mint)),
              ),
              child: Row(
                children: [
                  for (final col in _cols)
                    SizedBox(
                      width: widthOf(col),
                      child: col.sort == null
                          ? _headText(col.label)
                          : InkWell(
                              onTap: () => onSort(col.sort!),
                              child: Row(
                                children: [
                                  Flexible(child: _headText(col.label, active: sort == col.sort)),
                                  const SizedBox(width: 3),
                                  Icon(
                                    sort == col.sort
                                        ? (sortDesc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded)
                                        : Icons.unfold_more_rounded,
                                    size: 13,
                                    color: sort == col.sort ? DashboardColors.brand : DashboardColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                    ),
                ],
              ),
            ),
            for (final e in events) _row(context, e, widthOf),
          ],
        );
      },
    );
  }

  Widget _headText(String t, {bool active = false}) => Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: bvText(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: active ? DashboardColors.brand : DashboardColors.textMuted,
        ),
      );

  Widget _row(BuildContext context, FeedingEvent e, double Function(_Col) widthOf) {
    final selected = e.id == selectedId;
    String g(double? v) => v == null ? '—' : '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} g';
    final muted = bvText(fontSize: 12.5, color: DashboardColors.textMuted);
    final body = bvText(fontSize: 12.5, color: DashboardColors.textPrimary);
    final strong = bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary);

    return Material(
      color: selected ? DashboardColors.lightMint : Colors.white,
      child: InkWell(
        onTap: () => onRowTap(e),
        hoverColor: DashboardColors.lightMint.withValues(alpha: 0.7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: DashboardColors.mint)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: widthOf(_cols[0]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmtDateVn(e.time), style: strong),
                    Text(
                      '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}',
                      style: muted,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: widthOf(_cols[1]),
                child: Text(
                  e.foodType.isEmpty ? '—' : e.foodType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body,
                ),
              ),
              SizedBox(width: widthOf(_cols[2]), child: Text(g(e.servedGram), style: body)),
              SizedBox(width: widthOf(_cols[3]), child: Text(g(e.eatenGram), style: body)),
              SizedBox(
                width: widthOf(_cols[4]),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FeedingPercentBadge(percent: e.feedingPercent, thresholds: thresholds, compact: true),
                ),
              ),
              SizedBox(
                width: widthOf(_cols[5]),
                child: ActivityTransition(before: e.activityBefore, after: e.activityAfter, thresholds: thresholds),
              ),
              SizedBox(
                width: widthOf(_cols[6]),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    e.note ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: e.note == null ? muted : body,
                  ),
                ),
              ),
              SizedBox(
                width: widthOf(_cols[7]),
                child: Row(
                  children: [
                    Icon(
                      e.isAi ? Icons.videocam_outlined : Icons.person_outline_rounded,
                      size: 14,
                      color: DashboardColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(e.performerLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: body),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: widthOf(_cols[8]),
                child: e.photoUrls.isEmpty
                    ? Text('—', style: muted)
                    : Row(
                        children: [
                          FeedingPhotoThumb(
                            url: e.photoUrls.first,
                            token: token,
                            size: 38,
                            onTap: () => showFeedingLightbox(context, urls: e.photoUrls, token: token),
                          ),
                          if (e.photoUrls.length > 1) ...[
                            const SizedBox(width: 4),
                            Text('+${e.photoUrls.length - 1}', style: muted),
                          ],
                        ],
                      ),
              ),
              SizedBox(
                width: widthOf(_cols[9]),
                child: PopupMenuButton<FeedingEventAction>(
                  tooltip: 'Thao tác',
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_horiz_rounded, size: 18, color: DashboardColors.textMuted),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  onSelected: (a) => onAction(e, a),
                  itemBuilder: (_) => [
                    _item(FeedingEventAction.detail, Icons.visibility_outlined, 'Xem chi tiết lần ăn'),
                    _item(FeedingEventAction.editNote, Icons.edit_note_rounded, 'Chỉnh sửa ghi chú'),
                    if (e.photoUrls.isNotEmpty)
                      _item(FeedingEventAction.viewPhotos, Icons.image_outlined, 'Xem hình ảnh'),
                    _item(FeedingEventAction.viewCamera, Icons.videocam_outlined, 'Xem camera liên quan'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<FeedingEventAction> _item(FeedingEventAction a, IconData icon, String label) =>
      PopupMenuItem(
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
}

class _Col {
  const _Col(this.label, this.width, {this.flex = 0, this.sort});
  final String label;
  final double width;
  final int flex;
  final FeedingSort? sort;
}

/// Skeleton 5 dòng cho bảng lịch sử.
class FeedingTableSkeleton extends StatelessWidget {
  const FeedingTableSkeleton({super.key, this.rows = 5});

  final int rows;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, [double h = 12]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(6)),
        );
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: DashboardColors.mint)),
            ),
            child: Row(
              children: [
                bar(110),
                const SizedBox(width: 20),
                bar(120),
                const SizedBox(width: 20),
                bar(60),
                const SizedBox(width: 20),
                bar(60),
                const SizedBox(width: 20),
                bar(70, 20),
                const SizedBox(width: 20),
                bar(160),
                const Spacer(),
                bar(36, 36),
              ],
            ),
          ),
      ],
    );
  }
}
