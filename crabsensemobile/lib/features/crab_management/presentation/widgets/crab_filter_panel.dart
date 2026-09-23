// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/crab_management_models.dart';
import '../../presentation/providers/crab_management_provider.dart';
import 'crab_management_palette.dart';

/// Filter panel — search + dropdowns in 2 rows.
class CrabFilterPanel extends StatefulWidget {
  const CrabFilterPanel({
    required this.filter,
    required this.dropdown,
    required this.notifier,
    super.key,
  });

  final CrabFilterState filter;
  final CrabDropdownOptions dropdown;
  final CrabManagementNotifier notifier;

  @override
  State<CrabFilterPanel> createState() => _CrabFilterPanelState();
}

class _CrabFilterPanelState extends State<CrabFilterPanel> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.filter.searchQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notifier;
    final f = widget.filter;
    final d = widget.dropdown;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cmCardDecoration(),
      child: Column(
        children: [
          // Row 1: search + khu + dãy + hộp + lô
          _buildRow1(n, f, d),
          const SizedBox(height: 10),
          // Row 2: giới tính + trạng thái + sức khỏe + buttons
          _buildRow2(n, f),
        ],
      ),
    );
  }

  Widget _buildRow1(
    CrabManagementNotifier n,
    CrabFilterState f,
    CrabDropdownOptions d,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        // Search
        SizedBox(
          width: double.infinity,
          child: _SearchField(
            controller: _searchCtrl,
            onChanged: n.onSearchChanged,
            onSubmit: n.onSearchSubmit,
          ),
        ),
        // Khu vực
        _FilterDropdown<FarmAreaOption>(
          label: 'Khu vực',
          hint: 'Tất cả khu',
          value: d.farmAreas.where((a) => a.id == f.farmAreaId).firstOrNull,
          items: d.farmAreas,
          displayLabel: (a) => a.name,
          onChanged: (a) => n.onFarmAreaSelected(a?.id),
          loading: d.loadingFarms,
        ),
        // Dãy
        _FilterDropdown<RowOption>(
          label: 'Dãy',
          hint: 'Tất cả',
          value: d.rows.where((r) => r.id == f.rowId).firstOrNull,
          items: d.rows,
          displayLabel: (r) => r.name,
          onChanged: (r) => n.onRowSelected(r?.id),
          loading: d.loadingRows,
          disabled: f.farmAreaId == null,
        ),
        // Hộp
        _FilterDropdown<BoxOption>(
          label: 'Hộp',
          hint: 'Tất cả',
          value: d.boxes.where((b) => b.id == f.boxId).firstOrNull,
          items: d.boxes,
          displayLabel: (b) => b.code,
          onChanged: (b) => n.onBoxSelected(b?.id),
          loading: d.loadingBoxes,
          disabled: f.rowId == null,
        ),
        // Lô cua
        _FilterDropdown<BatchOption>(
          label: 'Lô cua',
          hint: 'Tất cả',
          value: d.batches.where((b) => b.id == f.batchId).firstOrNull,
          items: d.batches,
          displayLabel: (b) => b.code,
          onChanged: (b) => n.onBatchSelected(b?.id),
        ),
      ],
    );
  }

  Widget _buildRow2(CrabManagementNotifier n, CrabFilterState f) {
    return Row(
      children: [
        // Giới tính
        Expanded(
          child: _FilterDropdown<CrabGender>(
            label: 'Giới tính',
            hint: 'Tất cả',
            value: f.gender,
            items: CrabGender.values,
            displayLabel: (g) => g.label,
            onChanged: (g) => n.onGenderChanged(g),
          ),
        ),
        const SizedBox(width: 8),
        // Trạng thái
        Expanded(
          child: _FilterDropdown<CrabLifecycleStatus>(
            label: 'Trạng thái',
            hint: 'Tất cả',
            value: f.lifecycleStatus,
            items: CrabLifecycleStatus.values
                .where((s) => s != CrabLifecycleStatus.unknown)
                .toList(),
            displayLabel: (s) => s.label,
            onChanged: (s) => n.onLifecycleStatusChanged(s),
          ),
        ),
        const SizedBox(width: 8),
        // Sức khỏe
        Expanded(
          child: _FilterDropdown<CrabHealthStatus>(
            label: 'Sức khỏe',
            hint: 'Tất cả',
            value: f.healthStatus,
            items: CrabHealthStatus.values
                .where((s) => s != CrabHealthStatus.unknown)
                .toList(),
            displayLabel: (s) => s.label,
            onChanged: (s) => n.onHealthStatusChanged(s),
          ),
        ),
        const SizedBox(width: 8),
        // Clear + Search buttons
        _ClearButton(onPressed: n.clearFilters),
        const SizedBox(width: 8),
        _SearchButton(
          onPressed: () {
            final q = _searchCtrl.text;
            n.onSearchChanged(q);
            n.onSearchSubmit();
          },
        ),
      ],
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    onSubmitted: (_) => onSubmit(),
    style: GoogleFonts.nunito(fontSize: 13, color: kCmTextPrimary),
    decoration: InputDecoration(
      hintText: 'Tìm mã cua, mã hộp hoặc mã lô...',
      hintStyle: GoogleFonts.nunito(fontSize: 13, color: kCmTextHint),
      prefixIcon: const Icon(
        Icons.search_rounded,
        size: 18,
        color: kCmTextHint,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      filled: true,
      fillColor: kCmMintBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kCmBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kCmBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kCmPrimary, width: 2),
      ),
      isDense: true,
    ),
  );
}

// ── Generic filter dropdown ───────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.displayLabel,
    required this.onChanged,
    this.loading = false,
    this.disabled = false,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) displayLabel;
  final void Function(T?) onChanged;
  final bool loading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kCmTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (loading)
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: kCmMintBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kCmBorder),
              ),
              child: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kCmPrimary,
                  ),
                ),
              ),
            )
          else
            DropdownButtonFormField<T>(
              value: value,
              isDense: true,
              isExpanded: true,
              hint: Text(
                hint,
                style: GoogleFonts.nunito(fontSize: 12, color: kCmTextHint),
              ),
              items: [
                DropdownMenuItem<T>(
                  value: null,
                  child: Text(
                    hint,
                    style: GoogleFonts.nunito(fontSize: 12, color: kCmTextHint),
                  ),
                ),
                ...items.map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      displayLabel(item),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: kCmTextPrimary,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: disabled ? null : onChanged,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                filled: true,
                fillColor: disabled ? const Color(0xFFF5F5F5) : kCmMintBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kCmBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kCmBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kCmPrimary, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: kCmBorder.withValues(alpha: 0.5),
                  ),
                ),
              ),
              style: GoogleFonts.nunito(fontSize: 12, color: kCmTextPrimary),
              dropdownColor: kCmSurface,
            ),
        ],
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
    label: Text(
      'Xóa bộ lọc',
      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: kCmTextSecondary,
      side: const BorderSide(color: kCmBorder),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.search_rounded, size: 15),
    label: Text(
      'Tìm kiếm',
      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: kCmPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}
