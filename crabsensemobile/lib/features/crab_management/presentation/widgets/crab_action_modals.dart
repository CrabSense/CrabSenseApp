// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/crab_management_models.dart';
import 'crab_management_palette.dart';

// ── Action menu popup ─────────────────────────────────────────────────────────

Future<void> showCrabActionMenu({
  required BuildContext context,
  required CrabRecord crab,
  required Offset offset,
  required VoidCallback onViewDetail,
  required VoidCallback onUpdateInfo,
  required VoidCallback onViewHistory,
  required VoidCallback onViewBox,
  required VoidCallback onTransfer,
  required VoidCallback onMarkMolting,
  required VoidCallback onMarkReadyToHarvest,
  required VoidCallback onMarkDead,
}) async {
  final isDead = crab.lifecycleStatus == CrabLifecycleStatus.dead;
  final isHarvested = crab.lifecycleStatus == CrabLifecycleStatus.harvested;

  await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      offset.dx,
      offset.dy,
      offset.dx + 200,
      offset.dy + 40,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: kCmSurface,
    items: [
      _menuItem('detail', Icons.visibility_outlined, 'Xem chi tiết'),
      _menuItem('update', Icons.edit_outlined, 'Cập nhật thông tin'),
      _menuItem('history', Icons.history_rounded, 'Xem lịch sử'),
      _menuItem('box', Icons.inventory_2_outlined, 'Xem hộp hiện tại'),
      if (!isDead && !isHarvested) ...[
        const PopupMenuDivider(height: 4),
        _menuItem('transfer', Icons.swap_horiz_rounded, 'Chuyển hộp'),
        _menuItem('molting', Icons.autorenew_rounded, 'Đánh dấu lột xác'),
        _menuItem(
          'harvest',
          Icons.shopping_basket_outlined,
          'Đánh dấu sắp thu hoạch',
        ),
        const PopupMenuDivider(height: 4),
        _menuItem(
          'dead',
          Icons.heart_broken_outlined,
          'Đánh dấu chết',
          color: kCmRed,
        ),
      ],
    ],
  ).then((action) {
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'detail':
        onViewDetail();
      case 'update':
        onUpdateInfo();
      case 'history':
        onViewHistory();
      case 'box':
        onViewBox();
      case 'transfer':
        onTransfer();
      case 'molting':
        onMarkMolting();
      case 'harvest':
        onMarkReadyToHarvest();
      case 'dead':
        onMarkDead();
    }
  });
}

PopupMenuItem<String> _menuItem(
  String value,
  IconData icon,
  String label, {
  Color? color,
}) {
  return PopupMenuItem<String>(
    value: value,
    height: 40,
    child: Row(
      children: [
        Icon(icon, size: 16, color: color ?? kCmTextSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? kCmTextPrimary,
          ),
        ),
      ],
    ),
  );
}

// ── Mark Molting modal ────────────────────────────────────────────────────────

Future<({DateTime detectedAt, String note})?> showMarkMoltingDialog(
  BuildContext context,
  CrabRecord crab,
) {
  final noteCtrl = TextEditingController();
  DateTime detectedAt = DateTime.now();

  return showDialog<({DateTime detectedAt, String note})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: kCmSurface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kCmPurpleLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.autorenew_rounded,
                color: kCmPurple,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Xác nhận cua đang lột xác?',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kCmTextPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogInfoRow(label: 'Cua', value: crab.id),
            const SizedBox(height: 12),
            Text(
              'Thời gian',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kCmTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDateTimePicker(ctx, detectedAt);
                if (picked != null) setState(() => detectedAt = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kCmMintBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kCmBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: kCmPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDatetime(detectedAt),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: kCmTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ghi chú',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kCmTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              style: GoogleFonts.nunito(fontSize: 13, color: kCmTextPrimary),
              decoration: _inputDeco('Nhập ghi chú (tuỳ chọn)...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Hủy',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: kCmTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, (
              detectedAt: detectedAt,
              note: noteCtrl.text.trim(),
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: kCmPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Xác nhận',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Mark Dead modal ───────────────────────────────────────────────────────────

Future<({DateTime detectedAt, DeathReason reason, String note})?>
showMarkDeadDialog(BuildContext context, CrabRecord crab) {
  final noteCtrl = TextEditingController();
  DateTime detectedAt = DateTime.now();
  DeathReason reason = DeathReason.unknown;

  return showDialog<({DateTime detectedAt, DeathReason reason, String note})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: kCmSurface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kCmRedLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.heart_broken_outlined,
                color: kCmRed,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xác nhận cua chết',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kCmRed,
                    ),
                  ),
                  Text(
                    crab.id,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: kCmTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thời gian phát hiện *',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kCmTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDateTimePicker(ctx, detectedAt);
                if (picked != null) setState(() => detectedAt = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kCmMintBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kCmBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: kCmPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDatetime(detectedAt),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: kCmTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nguyên nhân',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kCmTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<DeathReason>(
              value: reason,
              decoration: _inputDeco(''),
              items: DeathReason.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r.label,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: kCmTextPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => reason = v ?? DeathReason.unknown),
              style: GoogleFonts.nunito(fontSize: 13, color: kCmTextPrimary),
              dropdownColor: kCmSurface,
            ),
            const SizedBox(height: 12),
            Text(
              'Ghi chú',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kCmTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              style: GoogleFonts.nunito(fontSize: 13, color: kCmTextPrimary),
              decoration: _inputDeco('Nhập ghi chú (tuỳ chọn)...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Hủy',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: kCmTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, (
              detectedAt: detectedAt,
              reason: reason,
              note: noteCtrl.text.trim(),
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: kCmRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Xác nhận cua chết',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Transfer Crab modal ───────────────────────────────────────────────────────

Future<String?> showTransferCrabDialog(
  BuildContext context,
  CrabRecord crab,
  List<FarmAreaOption> farmAreas,
  Future<List<RowOption>> Function(String farmAreaId) fetchRows,
  Future<List<BoxOption>> Function(String rowId) fetchBoxes,
) async {
  FarmAreaOption? selectedFarm;
  RowOption? selectedRow;
  BoxOption? selectedBox;
  List<RowOption> rows = [];
  List<BoxOption> boxes = [];
  bool loadingRows = false;
  bool loadingBoxes = false;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: kCmSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chuyển hộp cua',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kCmTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            _DialogInfoRow(label: 'Cua', value: crab.id),
            _DialogInfoRow(
              label: 'Hộp hiện tại',
              value: '${crab.location.boxCode} (${crab.location.rowName})',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chuyển đến',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: kCmTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            // Khu vực
            _TransferDropdown<FarmAreaOption>(
              label: 'Khu vực',
              hint: 'Chọn khu vực...',
              value: selectedFarm,
              items: farmAreas,
              displayLabel: (a) => a.name,
              onChanged: (a) async {
                setState(() {
                  selectedFarm = a;
                  selectedRow = null;
                  selectedBox = null;
                  rows = [];
                  boxes = [];
                  loadingRows = true;
                });
                if (a != null) {
                  final r = await fetchRows(a.id);
                  if (ctx.mounted)
                    setState(() {
                      rows = r;
                      loadingRows = false;
                    });
                }
              },
              loading: loadingRows,
            ),
            const SizedBox(height: 8),
            // Dãy
            _TransferDropdown<RowOption>(
              label: 'Dãy',
              hint: 'Chọn dãy...',
              value: selectedRow,
              items: rows,
              displayLabel: (r) => r.name,
              onChanged: (r) async {
                setState(() {
                  selectedRow = r;
                  selectedBox = null;
                  boxes = [];
                  loadingBoxes = true;
                });
                if (r != null) {
                  final b = await fetchBoxes(r.id);
                  if (ctx.mounted)
                    setState(() {
                      boxes = b;
                      loadingBoxes = false;
                    });
                }
              },
              loading: loadingBoxes,
              disabled: selectedFarm == null,
            ),
            const SizedBox(height: 8),
            // Hộp
            _TransferDropdown<BoxOption>(
              label: 'Hộp',
              hint: 'Chọn hộp trống...',
              value: selectedBox,
              items: boxes.where((b) => b.id != crab.location.boxId).toList(),
              displayLabel: (b) => b.code,
              onChanged: (b) => setState(() => selectedBox = b),
              disabled: selectedRow == null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Hủy',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: kCmTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: selectedBox == null
                ? null
                : () => Navigator.pop(ctx, selectedBox!.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: kCmPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              disabledBackgroundColor: kCmBorder,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Chuyển hộp',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<DateTime?> showDateTimePicker(
  BuildContext context,
  DateTime initial,
) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: ColorScheme.light(
          primary: kCmPrimary,
          onPrimary: Colors.white,
        ),
      ),
      child: child!,
    ),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String _formatDatetime(DateTime dt) {
  final l = dt.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} '
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

InputDecoration _inputDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: GoogleFonts.nunito(fontSize: 12, color: kCmTextHint),
  filled: true,
  fillColor: kCmMintBg,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    borderSide: const BorderSide(color: kCmPrimary, width: 1.5),
  ),
);

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.nunito(fontSize: 12, color: kCmTextSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kCmTextPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _TransferDropdown<T> extends StatelessWidget {
  const _TransferDropdown({
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
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
              (i) => DropdownMenuItem<T>(
                value: i,
                child: Text(
                  displayLabel(i),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: kCmTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: disabled ? null : onChanged,
          decoration: _inputDeco(''),
          style: GoogleFonts.nunito(fontSize: 13, color: kCmTextPrimary),
          dropdownColor: kCmSurface,
        ),
    ],
  );
}
