import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'crab_management_palette.dart';

/// Bulk action bar — appears when ≥1 row is selected.
class CrabBulkActionBar extends StatelessWidget {
  const CrabBulkActionBar({
    required this.count,
    required this.onTransfer,
    required this.onUpdateHealth,
    required this.onExport,
    required this.onClear,
    super.key,
  });

  final int count;
  final VoidCallback onTransfer;
  final VoidCallback onUpdateHealth;
  final VoidCallback onExport;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: kCmPrimaryLight,
        border: Border.all(color: kCmPrimary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kCmPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Đã chọn $count cua',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _BulkBtn(
            icon: Icons.swap_horiz_rounded,
            label: 'Chuyển hộp',
            onTap: onTransfer,
          ),
          const SizedBox(width: 8),
          _BulkBtn(
            icon: Icons.health_and_safety_outlined,
            label: 'Cập nhật sức khỏe',
            onTap: onUpdateHealth,
          ),
          const SizedBox(width: 8),
          _BulkBtn(
            icon: Icons.file_download_outlined,
            label: 'Xuất dữ liệu',
            onTap: onExport,
          ),
          const Spacer(),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 16),
            color: kCmPrimaryDark,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Bỏ chọn',
          ),
        ],
      ),
    );
  }
}

class _BulkBtn extends StatelessWidget {
  const _BulkBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 13),
    label: Text(
      label,
      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: kCmPrimaryDark,
      side: BorderSide(color: kCmPrimary.withValues(alpha: 0.5)),
      backgroundColor: kCmSurface,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}
