import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_list_item.dart';
import '../../models/box_status.dart';
import '../../models/crab_box.dart';
import '../../models/farm_layout.dart';
import '../../theme/dashboard_theme.dart';

void showBoxDetailDrawer(
  BuildContext context,
  FarmMapBox item, {
  ValueChanged<BoxListItem>? onViewDetail,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Box detail',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, _, __) => Align(
      alignment: Alignment.centerRight,
      child: _BoxQuickPanel(item: item, onViewDetail: onViewDetail),
    ),
    transitionBuilder: (ctx, anim, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
      child: child,
    ),
  );
}

class _BoxQuickPanel extends StatelessWidget {
  const _BoxQuickPanel({required this.item, this.onViewDetail});

  final FarmMapBox item;
  final ValueChanged<BoxListItem>? onViewDetail;

  CrabBox get box => item.display;

  @override
  Widget build(BuildContext context) {
    final listItem = item.toListItem();
    final ai = item.aiSummary?.trim();

    return Material(
      color: DashboardColors.card,
      child: Container(
        width: 360,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: DashboardColors.cardBorder),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hộp ${box.id}',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: DashboardColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statusChip(),
                    const SizedBox(height: 16),
                    _line(
                      Icons.set_meal_outlined,
                      'Số cua: ${item.crabCount}',
                    ),
                    const SizedBox(height: 8),
                    _line(
                      Icons.place_outlined,
                      '${item.areaLabel} → ${item.rowLabel}',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'AI',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ai != null && ai.isNotEmpty
                          ? ai
                          : box.status == BoxStatus.molting
                              ? 'Có khả năng sắp / đang lột xác.'
                              : box.status == BoxStatus.watch
                                  ? 'Cần theo dõi hộp này.'
                                  : box.status == BoxStatus.alert
                                      ? 'Cần kiểm tra ngay.'
                                      : box.status == BoxStatus.empty
                                          ? 'Hộp trống — chưa có cua.'
                                          : 'Chưa có ghi chú AI.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _line(
                      item.alertCount > 0 || box.hasAlert
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      item.alertCount > 0 || box.hasAlert
                          ? 'Có ${item.alertCount > 0 ? item.alertCount : 1} cảnh báo'
                          : 'Không có cảnh báo môi trường',
                      color: item.alertCount > 0 || box.hasAlert
                          ? DashboardColors.risk
                          : DashboardColors.healthy,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: listItem == null || onViewDetail == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              onViewDetail!(listItem);
                            },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Xem chi tiết'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: box.status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: box.status.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: box.status.color),
          const SizedBox(width: 8),
          Text(
            box.status.label,
            style: GoogleFonts.notoSans(
              color: box.status.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, {Color? color}) {
    final c = color ?? DashboardColors.textMuted;
    return Row(
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.notoSans(color: c, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
