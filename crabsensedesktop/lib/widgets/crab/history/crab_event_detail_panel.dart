import 'package:flutter/material.dart';

import '../../../models/crab_growth_molt.dart';
import '../../../models/crab_lifecycle_event.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import '../feeding/feeding_history_table.dart';

class CrabEventDetailPanel extends StatelessWidget {
  const CrabEventDetailPanel({
    super.key,
    required this.event,
    required this.token,
    this.onClose,
    this.onOpenArea,
    this.onOpenRow,
    this.onOpenBox,
    this.onOpenCamera,
    this.cameraLabel,
    this.error,
    this.onRetry,
    this.loading = false,
  });

  final CrabLifecycleEvent? event;
  final String token;
  final VoidCallback? onClose;
  final VoidCallback? onOpenArea;
  final VoidCallback? onOpenRow;
  final VoidCallback? onOpenBox;
  final VoidCallback? onOpenCamera;
  final String? cameraLabel;
  final String? error;
  final VoidCallback? onRetry;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: DashboardColors.brand),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Chi tiết sự kiện',
                  style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                ),
              ),
              if (onClose != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, size: 18, color: DashboardColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            const _DetailSkeleton()
          else if (error != null)
            MgmtEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Không thể tải chi tiết.',
              message: error!,
              action: onRetry == null ? null : MgmtPrimaryButton(label: 'Thử lại', onTap: onRetry, height: 36),
            )
          else if (event == null)
            Text(
              'Chọn một sự kiện để xem chi tiết.',
              style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
            )
          else
            _body(context, event!),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, CrabLifecycleEvent e) {
    final color = e.eventType.color;
    final badge = e.metaStr('appetiteLabel') ?? e.metaStr('resultLabel') ?? e.metaStr('severityLabel');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(e.eventType.icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, style: bvText(fontSize: 15, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                  Text(fmtDateTimeVn(e.occurredAt), style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                ],
              ),
            ),
            if (badge != null) MgmtStatusBadge(label: badge, color: color),
          ],
        ),
        const SizedBox(height: 14),
        _kv('Cua', e.crabCode.isEmpty ? '—' : e.crabCode),
        _location(e),
        ..._fields(e),
        _kv('Người thực hiện', e.actor.name),
        _kv('Nguồn', e.sourceLabel()),
        if ((e.cameraId ?? '').isNotEmpty || (cameraLabel ?? '').isNotEmpty)
          _linkRow('Camera', cameraLabel ?? e.cameraId ?? '—', onOpenCamera),
        if ((e.note ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Ghi chú', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 3),
          Text(e.note!, style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary)),
        ],
        const SizedBox(height: 14),
        Text(
          'Hình ảnh / Video liên quan',
          style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
        ),
        const SizedBox(height: 8),
        if (e.mediaUrls.isEmpty)
          Text(
            'Không có hình ảnh/video cho sự kiện này.',
            style: bvText(fontSize: 12, color: DashboardColors.textMuted),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < e.mediaUrls.take(3).length; i++)
                FeedingPhotoThumb(
                  url: e.mediaUrls[i],
                  token: token,
                  onTap: () => showFeedingLightbox(context, urls: e.mediaUrls, token: token, initial: i),
                ),
            ],
          ),
      ],
    );
  }

  List<Widget> _fields(CrabLifecycleEvent e) {
    switch (e.eventType) {
      case CrabLifecycleEventType.feeding:
        return [
          _kv('Thức ăn', e.metaStr('foodType') ?? '—'),
          _kv('Khẩu phần', fmtHistNum(e.metaNum('servedGram'), suffix: 'g')),
          _kv('Đã ăn', fmtHistNum(e.metaNum('eatenGram'), suffix: 'g')),
          _kvRow(
            'Mức ăn',
            Row(
              children: [
                Text(
                  e.metaNum('feedingPercent') == null ? '—' : '${e.metaNum('feedingPercent')!.round()}%',
                  style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
                ),
                if (e.metaStr('feedingGrade') != null) ...[
                  const SizedBox(width: 8),
                  MgmtStatusBadge(label: e.metaStr('feedingGrade')!, color: DashboardColors.brand),
                ],
              ],
            ),
          ),
          _kv('Vận động trước', _activityLine(e.metaNum('activityBefore'), e.metaStr('activityBeforeLabel'))),
          _kv('Vận động sau', _activityLine(e.metaNum('activityAfter'), e.metaStr('activityAfterLabel'))),
        ];
      case CrabLifecycleEventType.growth:
        return [
          _kv('Cân nặng trước', fmtHistNum(e.metaNum('weightBefore'), suffix: 'g')),
          _kv('Cân nặng sau', fmtHistNum(e.metaNum('weightAfter'), suffix: 'g')),
          _kv('Thay đổi', fmtHistSigned(e.metaNum('deltaGram'))),
          _kv('Rộng mai', _arrow(e.metaNum('widthBefore'), e.metaNum('widthAfter'), 'mm')),
          _kv('Dài mai', _arrow(e.metaNum('lengthBefore'), e.metaNum('lengthAfter'), 'mm')),
        ];
      case CrabLifecycleEventType.health:
        return [
          _kv('Trước', e.metaStr('conditionBefore') ?? '—'),
          _kv('Sau', e.metaStr('conditionAfter') ?? '—'),
        ];
      case CrabLifecycleEventType.moltStart:
      case CrabLifecycleEventType.moltComplete:
        final mins = e.metaNum('durationMinutes');
        return [
          _kv('Lần', e.metaStr('moltNumber') ?? '—'),
          _kv('Tình trạng', e.metaStr('resultLabel') ?? '—'),
          if (mins != null) _kv('Thời lượng', fmtDurationVn(Duration(minutes: mins.round()))),
          _kv('Trước lột', fmtHistNum(e.metaNum('weightBefore'), suffix: 'g')),
          _kv('Sau lột', fmtHistNum(e.metaNum('weightAfter'), suffix: 'g')),
        ];
      case CrabLifecycleEventType.transfer:
        return [
          _kv('Từ', e.metaStr('fromBoxCode') ?? '—'),
          _kv('Đến', e.metaStr('toBoxCode') ?? '—'),
          _kv('Khu', e.location?.farmAreaCode ?? '—'),
          _kv('Dãy', e.location?.rowCode ?? '—'),
          if ((e.metaStr('reason') ?? '').isNotEmpty) _kv('Lý do', e.metaStr('reason')!),
        ];
      case CrabLifecycleEventType.ai:
        return [
          _kv('Loại', e.summary),
          if (e.metaStr('activityLevel') != null) _kv('Activity', e.metaStr('activityLevel')!),
          if (e.metaNum('confidence') != null) _kv('Confidence', '${e.metaNum('confidence')!.round()}%'),
        ];
      case CrabLifecycleEventType.profile:
        return [
          if (e.summary.isNotEmpty) _kv('Thay đổi', e.summary),
          _kv('Trước', e.metaStr('conditionBefore') ?? '—'),
          _kv('Sau', e.metaStr('conditionAfter') ?? '—'),
        ];
      case CrabLifecycleEventType.alertCreated:
      case CrabLifecycleEventType.alertResolved:
        return [
          _kv('Nội dung', e.summary),
          _kv('Mức độ', e.metaStr('severityLabel') ?? e.severity ?? '—'),
        ];
      default:
        return [
          if (e.summary.isNotEmpty) _kv('Tóm tắt', e.summary),
        ];
    }
  }

  Widget _location(CrabLifecycleEvent e) {
    final loc = e.location;
    if (loc == null) return _kv('Vị trí', '—');
    return _kvRow(
      'Vị trí',
      Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _id(loc.farmAreaCode, onOpenArea),
          if ((loc.farmAreaCode ?? '').isNotEmpty && (loc.rowCode ?? '').isNotEmpty)
            Text('>', style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
          _id(loc.rowCode, onOpenRow),
          if ((loc.rowCode ?? '').isNotEmpty && (loc.boxCode ?? '').isNotEmpty)
            Text('>', style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
          _id(loc.boxCode, onOpenBox),
        ],
      ),
    );
  }

  Widget _id(String? code, VoidCallback? onTap) {
    if (code == null || code.isEmpty) return const SizedBox.shrink();
    if (onTap == null) {
      return Text(code, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary));
    }
    return InkWell(
      onTap: onTap,
      child: Text(
        code,
        style: bvText(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: DashboardColors.brand,
        ),
      ),
    );
  }

  Widget _linkRow(String label, String value, VoidCallback? onTap) {
    return _kvRow(
      label,
      onTap == null
          ? Text(value, style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary))
          : InkWell(
              onTap: onTap,
              child: Text(value, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.brand)),
            ),
    );
  }

  Widget _kv(String label, String value) => _kvRow(
        label,
        Text(value, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
      );

  Widget _kvRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  String _activityLine(num? score, String? label) {
    if (score == null && (label == null || label.isEmpty)) return '—';
    final left = score == null ? '' : '${score.round()} / 100';
    if (label == null || label.isEmpty) return left;
    return left.isEmpty ? label : '$left  •  $label';
  }

  String _arrow(num? a, num? b, String unit) {
    if (a == null && b == null) return '—';
    if (a == null) return fmtHistNum(b, suffix: unit);
    if (b == null) return fmtHistNum(a, suffix: unit);
    return '${fmtHistNum(a)} → ${fmtHistNum(b, suffix: unit)}';
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 16, width: 160, color: DashboardColors.mint),
        const SizedBox(height: 10),
        Container(height: 12, width: 220, color: DashboardColors.mint),
        const SizedBox(height: 8),
        Container(height: 12, width: 180, color: DashboardColors.mint),
        const SizedBox(height: 8),
        Container(height: 12, width: 200, color: DashboardColors.mint),
      ],
    );
  }
}
