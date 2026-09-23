// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/crab_management_models.dart';
import 'crab_badges.dart';
import 'crab_management_palette.dart';

/// Full data table for wide screens (tablet / desktop).
/// Columns: checkbox | MĂ£ cua | LĂ´ cua | DĂ£y/Há»™p | Giá»›i tĂ­nh | CĂ¢n náº·ng |
///          KĂ­ch thÆ°á»›c | Sá»©c khá»e | Tráº¡ng thĂ¡i | Cáº­p nháº­t | Thao tĂ¡c
class CrabDataTable extends StatelessWidget {
  const CrabDataTable({
    required this.crabs,
    required this.selectedIds,
    required this.onToggleRow,
    required this.onToggleAll,
    required this.onRowTap,
    required this.onViewDetail,
    required this.onActionMenu,
    required this.selectedCrabId,
    super.key,
    this.sortColumn,
    this.sortAscending = false,
    this.onSort,
  });

  final List<CrabRecord> crabs;
  final Set<String> selectedIds;
  final void Function(String id) onToggleRow;
  final void Function(List<String> allIds) onToggleAll;
  final void Function(CrabRecord) onRowTap;
  final void Function(CrabRecord) onViewDetail;
  final void Function(CrabRecord, Offset) onActionMenu;
  final String? selectedCrabId;
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String column, bool ascending)? onSort;

  static const _colWidths = [
    40.0, // checkbox
    130.0, // MĂ£ cua
    150.0, // LĂ´ cua
    160.0, // DĂ£y / Há»™p
    70.0, // Giá»›i tĂ­nh
    80.0, // CĂ¢n náº·ng
    110.0, // KĂ­ch thÆ°á»›c
    110.0, // Sá»©c khá»e
    120.0, // Tráº¡ng thĂ¡i
    130.0, // Cáº­p nháº­t
    80.0, // Thao tĂ¡c
  ];

  double get _totalWidth => _colWidths.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cmCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: kCmBorder),
          ...crabs.asMap().entries.map(
            (e) => _buildRow(context, e.value, e.key),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final allSelected = crabs.isNotEmpty && selectedIds.length == crabs.length;
    return Container(
      color: kCmMintBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _totalWidth,
          child: Row(
            children: [
              // Checkbox all
              SizedBox(
                width: _colWidths[0],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Checkbox(
                    value: allSelected,
                    tristate: selectedIds.isNotEmpty && !allSelected,
                    onChanged: (_) =>
                        onToggleAll(crabs.map((c) => c.id).toList()),
                    side: const BorderSide(color: kCmBorder, width: 1.5),
                    activeColor: kCmPrimary,
                    checkColor: Colors.white,
                  ),
                ),
              ),
              _HeaderCell(
                'MĂƒ CUA',
                width: _colWidths[1],
                column: 'id',
                sortColumn: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort,
              ),
              _HeaderCell('LĂ” CUA', width: _colWidths[2]),
              _HeaderCell('DĂƒY / Há»˜P', width: _colWidths[3]),
              _HeaderCell('GIá»I TĂNH', width: _colWidths[4]),
              _HeaderCell(
                'CĂ‚N Náº¶NG',
                width: _colWidths[5],
                column: 'weight',
                sortColumn: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort,
              ),
              _HeaderCell('KĂCH THÆ¯á»C', width: _colWidths[6]),
              _HeaderCell(
                'Sá»¨C KHá»E',
                width: _colWidths[7],
                column: 'health',
                sortColumn: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort,
              ),
              _HeaderCell(
                'TRáº NG THĂI',
                width: _colWidths[8],
                column: 'lifecycle',
                sortColumn: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort,
              ),
              _HeaderCell(
                'Cáº¬P NHáº¬T',
                width: _colWidths[9],
                column: 'updatedAt',
                sortColumn: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort,
              ),
              _HeaderCell('THAO TĂC', width: _colWidths[10]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, CrabRecord crab, int index) {
    final isSelected = selectedIds.contains(crab.id);
    final isHighlighted = crab.id == selectedCrabId;
    final isEven = index.isEven;

    return GestureDetector(
      onTap: () => onRowTap(crab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: isHighlighted
            ? kCmPrimaryLight.withValues(alpha: 0.6)
            : isSelected
            ? kCmPrimaryLight.withValues(alpha: 0.35)
            : isEven
            ? kCmSurface
            : kCmMintBg.withValues(alpha: 0.4),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _totalWidth,
                child: Row(
                  children: [
                    // Checkbox
                    SizedBox(
                      width: _colWidths[0],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggleRow(crab.id),
                          side: const BorderSide(color: kCmBorder, width: 1.5),
                          activeColor: kCmPrimary,
                          checkColor: Colors.white,
                        ),
                      ),
                    ),
                    // MĂ£ cua
                    SizedBox(
                      width: _colWidths[1],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            _CrabIcon(crab.lifecycleStatus),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                crab.id,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: kCmPrimaryDark,
                                  decoration: TextDecoration.underline,
                                  decorationColor: kCmPrimaryDark.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // LĂ´ cua
                    _DataCell(
                      width: _colWidths[2],
                      child: Text(
                        crab.batch.name?.isNotEmpty == true
                            ? crab.batch.name!
                            : crab.batch.id,
                        style: _cellStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // DĂ£y / Há»™p
                    _DataCell(
                      width: _colWidths[3],
                      child: Text(
                        '${crab.location.rowName} / ${crab.location.boxCode}',
                        style: _cellStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Giá»›i tĂ­nh
                    _DataCell(
                      width: _colWidths[4],
                      child: CrabGenderBadge(crab.gender),
                    ),
                    // CĂ¢n náº·ng
                    _DataCell(
                      width: _colWidths[5],
                      child: Text(crab.weightLabel, style: _cellStyle),
                    ),
                    // KĂ­ch thÆ°á»›c
                    _DataCell(
                      width: _colWidths[6],
                      child: Text(crab.sizeLabel, style: _cellStyle),
                    ),
                    // Sá»©c khá»e
                    _DataCell(
                      width: _colWidths[7],
                      child: CrabHealthBadge(crab.healthStatus, compact: true),
                    ),
                    // Tráº¡ng thĂ¡i
                    _DataCell(
                      width: _colWidths[8],
                      child: CrabLifecycleBadge(
                        crab.lifecycleStatus,
                        compact: true,
                      ),
                    ),
                    // Cáº­p nháº­t
                    _DataCell(
                      width: _colWidths[9],
                      child: Text(
                        _formatDateTime(crab.updatedAt),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: kCmTextSecondary,
                        ),
                      ),
                    ),
                    // Thao tĂ¡c
                    SizedBox(
                      width: _colWidths[10],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ActionIconBtn(
                            icon: Icons.visibility_outlined,
                            tooltip: 'Xem nhanh',
                            onTap: () => onViewDetail(crab),
                          ),
                          _ActionMenuBtn(
                            onTap: (offset) => onActionMenu(crab, offset),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: kCmBorder),
          ],
        ),
      ),
    );
  }

  static final _cellStyle = GoogleFonts.nunito(
    fontSize: 12,
    color: kCmTextPrimary,
    fontWeight: FontWeight.w500,
  );

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date\n$time';
  }
}

// â”€â”€ Header cell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.text, {
    required this.width,
    this.column,
    this.sortColumn,
    this.sortAscending = false,
    this.onSort,
  });
  final String text;
  final double width;
  final String? column;
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String, bool)? onSort;

  @override
  Widget build(BuildContext context) {
    final isSorted = column != null && sortColumn == column;
    return GestureDetector(
      onTap: column == null || onSort == null
          ? null
          : () => onSort!(column!, isSorted ? !sortAscending : true),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(
                text,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: kCmTextSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (column != null) ...[
                const SizedBox(width: 4),
                Icon(
                  isSorted
                      ? (sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded)
                      : Icons.unfold_more_rounded,
                  size: 12,
                  color: isSorted ? kCmPrimary : kCmTextHint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Data cell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DataCell extends StatelessWidget {
  const _DataCell({required this.width, required this.child});
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
    ),
  );
}

// â”€â”€ Crab icon by lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CrabIcon extends StatelessWidget {
  const _CrabIcon(this.status);
  final CrabLifecycleStatus status;

  @override
  Widget build(BuildContext context) {
        final (bg, icon) = switch (status) {
      CrabLifecycleStatus.growing => (kCmGreenLight, '🦀'),
      CrabLifecycleStatus.molting => (kCmPurpleLight, '🔄'),
      CrabLifecycleStatus.readyToHarvest => (kCmTealLight, '🧺'),
      CrabLifecycleStatus.harvested => (kCmSlateBg, '✓'),
      CrabLifecycleStatus.dead => (kCmRedLight, '💔'),
      CrabLifecycleStatus.unknown => (kCmSlateBg, '?'),
    };
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 12))),
    );
  }
}

// â”€â”€ Action buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ActionIconBtn extends StatelessWidget {
  const _ActionIconBtn({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: kCmTextSecondary),
      ),
    ),
  );
}

class _ActionMenuBtn extends StatelessWidget {
  const _ActionMenuBtn({required this.onTap});
  final void Function(Offset) onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (details) => onTap(details.globalPosition),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Icon(Icons.more_horiz_rounded, size: 16, color: kCmTextSecondary),
    ),
  );
}

// â”€â”€ Compact list row for mobile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class CrabListTile extends StatelessWidget {
  const CrabListTile({
    required this.crab,
    required this.isSelected,
    required this.isHighlighted,
    required this.onTap,
    required this.onLongPress,
    required this.onActionMenu,
    super.key,
  });

  final CrabRecord crab;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(Offset) onActionMenu;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onTapDown: isHighlighted ? null : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: BoxDecoration(
          color: isHighlighted
              ? kCmPrimaryLight.withValues(alpha: 0.5)
              : isSelected
              ? kCmPrimaryLight.withValues(alpha: 0.3)
              : kCmSurface,
          border: Border(
            left: BorderSide(
              color: isHighlighted
                  ? kCmPrimary
                  : isSelected
                  ? kCmPrimary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Crab avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _lifecycleBg(crab.lifecycleStatus),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _lifecycleEmoji(crab.lifecycleStatus),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            crab.id,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kCmPrimaryDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        CrabGenderBadge(crab.gender),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${crab.location.rowName} â†’ ${crab.location.boxCode}',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: kCmTextSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        CrabHealthBadge(crab.healthStatus, compact: true),
                        CrabLifecycleBadge(crab.lifecycleStatus, compact: true),
                        _InfoPill('${crab.weightLabel}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTapDown: (d) => onActionMenu(d.globalPosition),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: kCmTextHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _lifecycleBg(CrabLifecycleStatus s) => switch (s) {
    CrabLifecycleStatus.growing => kCmGreenLight,
    CrabLifecycleStatus.molting => kCmPurpleLight,
    CrabLifecycleStatus.readyToHarvest => kCmTealLight,
    CrabLifecycleStatus.harvested => kCmSlateBg,
    CrabLifecycleStatus.dead => kCmRedLight,
    CrabLifecycleStatus.unknown => kCmSlateBg,
  };

  String _lifecycleEmoji(CrabLifecycleStatus s) => switch (s) {
    CrabLifecycleStatus.growing => 'đŸ¦€',
    CrabLifecycleStatus.molting => 'đŸ”„',
    CrabLifecycleStatus.readyToHarvest => 'đŸ§º',
    CrabLifecycleStatus.harvested => 'âœ“',
    CrabLifecycleStatus.dead => 'đŸ’”',
    CrabLifecycleStatus.unknown => '?',
  };
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: kCmMintBg,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: kCmBorder),
    ),
    child: Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: kCmTextSecondary,
      ),
    ),
  );
}

