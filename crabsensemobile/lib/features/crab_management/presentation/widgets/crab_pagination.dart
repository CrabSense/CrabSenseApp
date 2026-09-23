import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'crab_management_palette.dart';

/// Bottom pagination row: "Hiển thị 1 – 8 của 57" + page size + page buttons
class CrabPaginationBar extends StatelessWidget {
  const CrabPaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final int total;
  final int pageSize;
  final void Function(int) onPageChanged;
  final void Function(int) onPageSizeChanged;

  static const _pageSizes = [10, 20, 50, 100];
  static const _maxPageButtons = 6;

  int get _start => total == 0 ? 0 : (currentPage - 1) * pageSize + 1;
  int get _end => (currentPage * pageSize).clamp(0, total);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: kCmSurface,
        border: Border(top: BorderSide(color: kCmBorder)),
      ),
      child: Row(
        children: [
          // "Hiển thị 1 – 8 của 57 cá thể"
          Expanded(
            child: Text(
              total == 0
                  ? 'Không có kết quả'
                  : 'Hiển thị $_start – $_end của $total cá thể',
              style: GoogleFonts.nunito(fontSize: 12, color: kCmTextSecondary),
            ),
          ),
          // Page size selector
          Row(
            children: [
              Text(
                'Hiển thị',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: kCmTextSecondary,
                ),
              ),
              const SizedBox(width: 6),
              _PageSizeDropdown(
                value: pageSize,
                sizes: _pageSizes,
                onChanged: onPageSizeChanged,
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Pagination buttons
          _PageButtons(
            currentPage: currentPage,
            totalPages: totalPages,
            maxButtons: _maxPageButtons,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }
}

// ── Page size dropdown ────────────────────────────────────────────────────────

class _PageSizeDropdown extends StatelessWidget {
  const _PageSizeDropdown({
    required this.value,
    required this.sizes,
    required this.onChanged,
  });
  final int value;
  final List<int> sizes;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: kCmMintBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kCmBorder),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: value,
        isDense: true,
        items: sizes
            .map(
              (s) => DropdownMenuItem<int>(
                value: s,
                child: Text(
                  '$s',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: kCmTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
        style: GoogleFonts.nunito(fontSize: 12, color: kCmTextPrimary),
        dropdownColor: kCmSurface,
        icon: const Icon(
          Icons.expand_more_rounded,
          size: 14,
          color: kCmTextHint,
        ),
      ),
    ),
  );
}

// ── Page buttons ──────────────────────────────────────────────────────────────

class _PageButtons extends StatelessWidget {
  const _PageButtons({
    required this.currentPage,
    required this.totalPages,
    required this.maxButtons,
    required this.onPageChanged,
  });
  final int currentPage;
  final int totalPages;
  final int maxButtons;
  final void Function(int) onPageChanged;

  List<int?> _buildPages() {
    if (totalPages <= maxButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    final pages = <int?>[];
    pages.add(1);
    if (currentPage > 3) pages.add(null); // ellipsis
    for (
      int p = (currentPage - 1).clamp(2, totalPages - 1);
      p <= (currentPage + 1).clamp(2, totalPages - 1);
      p++
    ) {
      pages.add(p);
    }
    if (currentPage < totalPages - 2) pages.add(null); // ellipsis
    pages.add(totalPages);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final pages = _buildPages();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Prev
        _PageBtn(
          label: '‹',
          onTap: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          isActive: false,
        ),
        ...pages.map(
          (p) => p == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '…',
                    style: GoogleFonts.nunito(fontSize: 12, color: kCmTextHint),
                  ),
                )
              : _PageBtn(
                  label: '$p',
                  onTap: () => onPageChanged(p),
                  isActive: p == currentPage,
                ),
        ),
        // Next
        _PageBtn(
          label: '›',
          onTap: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          isActive: false,
        ),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.label,
    required this.onTap,
    required this.isActive,
  });
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? kCmPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: isActive ? kCmPrimary : kCmBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? Colors.white
                  : onTap == null
                  ? kCmTextHint
                  : kCmTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
