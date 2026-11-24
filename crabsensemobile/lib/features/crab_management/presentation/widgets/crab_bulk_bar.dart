import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'crab_management_palette.dart';

/// Bulk action bar — appears when ≥1 row is selected.
class CrabBulkActionBar extends StatelessWidget {
  const CrabBulkActionBar({
    required this.count,
    required this.onClear,
    super.key,
  });

  final int count;
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

