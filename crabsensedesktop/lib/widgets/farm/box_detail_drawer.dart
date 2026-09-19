import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_list_item.dart';
import '../../models/box_status.dart';
import '../../models/crab_box.dart';
import '../../models/farm_layout.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/app_formatters.dart';

/// Popup xem nhanh tình trạng hộp trên bản đồ trại.
void showBoxDetailDrawer(
  BuildContext context,
  FarmMapBox item, {
  ValueChanged<BoxListItem>? onViewDetail,
  VoidCallback? onExportMolting,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Box detail',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => Center(
      child: _BoxQuickPanel(
        item: item,
        onViewDetail: onViewDetail,
        onExportMolting: onExportMolting,
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _BoxQuickPanel extends StatelessWidget {
  const _BoxQuickPanel({
    required this.item,
    this.onViewDetail,
    this.onExportMolting,
  });

  final FarmMapBox item;
  final ValueChanged<BoxListItem>? onViewDetail;
  final VoidCallback? onExportMolting;

  CrabBox get box => item.display;

  bool get _isEmpty =>
      box.status == BoxStatus.empty || box.status == BoxStatus.deceased;

  bool get _isMolting => box.status == BoxStatus.molting;

  bool get _hasProblem =>
      box.status == BoxStatus.alert || box.status == BoxStatus.watch;

  String? get _crabCode {
    final tag = item.source?.crabTag?.trim();
    if (tag != null && tag.isNotEmpty && !_looksLikeGuid(tag)) return tag;
    final fromBox = box.crabId?.trim();
    if (fromBox != null && fromBox.isNotEmpty && !_looksLikeGuid(fromBox)) {
      return fromBox;
    }
    final id = item.source?.crabId?.trim();
    if (id == null || id.isEmpty || id == 'null' || _looksLikeGuid(id)) {
      return null;
    }
    return id;
  }

  static bool _looksLikeGuid(String s) {
    final parts = s.split('-');
    return parts.length == 5 && s.length >= 32;
  }

  String get _aiText {
    final ai = item.aiSummary?.trim();
    if (ai != null && ai.isNotEmpty) return ai;
    if (_isMolting) return 'Đang lột xác — theo dõi softshell';
    if (_hasProblem) return 'AI phát hiện bất thường';
    return 'Không phát hiện bất thường';
  }

  String get _statusHeadline {
    if (_isEmpty) return 'Hộp trống';
    if (_isMolting) {
      final at = item.source?.aiUpdatedAt;
      if (at != null) {
        return '${box.status.label} – phát hiện lúc ${formatClock(at.isUtc ? at.toLocal() : at)}';
      }
      return box.status.label;
    }
    if (_hasProblem) {
      final ai = item.aiSummary?.trim();
      if (ai != null && ai.isNotEmpty) return '${box.status.label} – $ai';
      return '${box.status.label} – cần kiểm tra';
    }
    return box.status.label;
  }

  @override
  Widget build(BuildContext context) {
    final listItem = item.toListItem();
    final maxH = MediaQuery.sizeOf(context).height * 0.82;
    final inBoxSince = item.source?.crabInBoxSince;
    final emptySince = item.source?.emptySince;
    final aiAt = item.source?.aiUpdatedAt;
    final hasAlert = item.alertCount > 0 || box.hasAlert;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxH),
        child: Container(
          width: 400,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: DashboardColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hộp ${box.id}',
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.areaLabel} → ${item.rowLabel}',
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: DashboardColors.textMuted),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statusBanner(),
                      if (_isEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionTitle('Hộp trống'),
                        const SizedBox(height: 8),
                        _kv(
                          'Thời gian trống',
                          emptySince == null
                              ? '—'
                              : formatDurationVi(
                                  DateTime.now().difference(
                                    emptySince.isUtc
                                        ? emptySince.toLocal()
                                        : emptySince,
                                  ),
                                ),
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        _sectionTitle('Cua trong hộp'),
                        const SizedBox(height: 8),
                        _kv('Mã cua', _crabCode ?? '—'),
                        const SizedBox(height: 6),
                        _kv(
                          'Thời gian nuôi',
                          inBoxSince == null
                              ? '—'
                              : formatDurationVi(
                                  DateTime.now().difference(
                                    inBoxSince.isUtc
                                        ? inBoxSince.toLocal()
                                        : inBoxSince,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('AI giám sát'),
                        const SizedBox(height: 8),
                        Text(
                          _aiText,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatAiUpdatedLabel(aiAt),
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _alertRow(hasAlert),
                      const SizedBox(height: 22),
                      if (_isMolting) ...[
                        Text(
                          'Cua đang lột — chọn hướng xử lý',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.moltPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: onExportMolting == null
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        onExportMolting!();
                                      },
                                icon: const Icon(Icons.sell_outlined, size: 16),
                                label: const Text('Xuất bán'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.egg_alt_outlined,
                                  size: 16,
                                ),
                                label: const Text('Để lại nuôi'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton.icon(
                        onPressed: listItem == null || onViewDetail == null
                            ? null
                            : () {
                                Navigator.pop(context);
                                onViewDetail!(listItem);
                              },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(
                          _isEmpty ? 'Mở quản lý hộp' : 'Xem chi tiết',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: box.status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: box.status.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Image.asset(
            box.status.iconAsset,
            width: 36,
            height: 36,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => Icon(
              Icons.circle,
              size: 12,
              color: box.status.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusHeadline,
              style: GoogleFonts.notoSans(
                color: box.status.color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.notoSans(
        color: DashboardColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _alertRow(bool hasAlert) {
    final color =
        hasAlert ? DashboardColors.monitoring : DashboardColors.healthy;
    return Row(
      children: [
        Icon(
          hasAlert ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasAlert
                ? 'Có ${item.alertCount > 0 ? item.alertCount : 1} cảnh báo đang tồn tại'
                : 'Không có cảnh báo',
            style: GoogleFonts.notoSans(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
