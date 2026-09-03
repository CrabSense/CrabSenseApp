import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_farm_layout_data.dart';
import '../../models/box_status.dart';
import '../../models/crab_box.dart';
import '../../models/farm_layout.dart';
import '../../theme/dashboard_theme.dart';

void showBoxDetailDrawer(BuildContext context, FarmMapBox item) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Box detail',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, _, __) => Align(
      alignment: Alignment.centerRight,
      child: _BoxDetailPanel(item: item),
    ),
    transitionBuilder: (ctx, anim, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
      child: child,
    ),
  );
}

class _BoxDetailPanel extends StatelessWidget {
  const _BoxDetailPanel({required this.item});

  final FarmMapBox item;

  CrabBox get box => item.display;

  @override
  Widget build(BuildContext context) {
    final env = MockFarmLayoutData.boxEnvironment();
    final logs = MockFarmLayoutData.boxActivityLog();

    return Material(
      color: DashboardColors.card,
      child: Container(
        width: 400,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: DashboardColors.cardBorder),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chi tiết hộp ${box.id}',
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statusChip(),
                    const SizedBox(height: 20),
                    _section('Vị trí trên trại', [
                      'Khu: ${item.areaName} (${item.areaCode})',
                      'Dãy: ${item.rowName} (${item.rowCode})',
                      'Mã hộp: ${box.id}',
                      'Trạng thái API: ${item.apiStatus}',
                    ]),
                    const SizedBox(height: 20),
                    _section('Thông tin cua', [
                      if (box.crabId != null) 'Mã cua: ${box.crabId}',
                      if (box.batchId != null) 'Thuộc lứa: ${box.batchId}',
                      if (box.releaseDate != null)
                        'Ngày thả: ${_fmt(box.releaseDate!)}',
                      if (box.weightGram != null)
                        'Trọng lượng hiện tại: ${box.weightGram!.toStringAsFixed(0)}g',
                      if (box.healthScore != null)
                        'Điểm sức khỏe: ${box.healthScore}/100',
                      'Tình trạng: ${box.status.label}',
                      if (box.lastMoltDate != null)
                        'Lần lột xác gần nhất: ${_fmt(box.lastMoltDate!)}',
                      if (box.expectedHarvest != null)
                        'Dự kiến thu hoạch: ${_fmt(box.expectedHarvest!)}',
                    ]),
                    const SizedBox(height: 20),
                    _section(
                      'Chỉ số môi trường tại hộp',
                      env.map((e) => '${e.key}: ${e.value}').toList(),
                    ),
                    const SizedBox(height: 20),
                    _section('Lịch sử hoạt động', logs),
                    const SizedBox(height: 24),
                    _actionBtn('Xem chi tiết cua', DashboardColors.purple, () {}),
                    const SizedBox(height: 8),
                    _actionBtn('Cập nhật trạng thái', DashboardColors.blue, () {}),
                    const SizedBox(height: 8),
                    _actionBtn('Ghi nhận cua chết', DashboardColors.risk, () {}),
                    const SizedBox(height: 8),
                    _actionBtn('Chuyển hộp', DashboardColors.textMuted, () {}),
                    const SizedBox(height: 8),
                    _actionBtn('Lịch sử cảm biến', DashboardColors.cyan, () {}),
                    const SizedBox(height: 24),
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
            'Trạng thái: ${box.status.label}',
            style: GoogleFonts.notoSans(
              color: box.status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSans(
            color: DashboardColors.purple,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...lines.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              l,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: GoogleFonts.notoSans(fontSize: 12)),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
