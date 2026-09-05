import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_status.dart';
import '../../models/production_models.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';

const _autoBox = '__auto_empty_box__';

const _conditions = <(String, String)>[
  ('normal', 'Bình thường'),
  ('weak', 'Yếu'),
  ('injured', 'Bị thương'),
  ('premolt', 'Sắp lột'),
  ('molting', 'Đang lột'),
  ('softshell', 'Cua lột mềm'),
  ('other', 'Khác'),
];

String _apiCondition(String key) => switch (key) {
      'premolt' => 'premolt',
      'molting' => 'molting',
      'softshell' => 'softshell',
      'normal' => 'normal',
      _ => 'problem',
    };

String _initialCondition(String key) =>
    _conditions.firstWhere((e) => e.$1 == key, orElse: () => ('other', 'Khác')).$2;

String _genderLabel(CrabGender g) => switch (g) {
      CrabGender.unknown => 'Chưa xác định',
      CrabGender.male => 'Đực',
      CrabGender.female => 'Cái',
    };

String _nextCode(String current) {
  final match = RegExp(r'^(.*?)(\d+)$').firstMatch(current.trim());
  if (match == null) return '$current-2';
  final n = int.parse(match.group(2)!);
  return '${match.group(1)}${(n + 1).toString().padLeft(match.group(2)!.length, '0')}';
}

Future<bool> showCrabBulkAddDialog(
  BuildContext context,
  CrabService service, {
  String? initialLotId,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => _CrabBulkAddDialog(
      service: service,
      initialLotId: initialLotId,
    ),
  );
  return saved == true;
}

class _RowData {
  _RowData({required this.code})
      : weight = TextEditingController(),
        length = TextEditingController(),
        width = TextEditingController(),
        notes = TextEditingController();

  final String id = UniqueKey().toString();
  bool selected = false;
  String code;
  CrabGender gender = CrabGender.unknown;
  final TextEditingController weight;
  final TextEditingController length;
  final TextEditingController width;
  final TextEditingController notes;
  String boxId = _autoBox;
  final List<String> imagePaths = [];

  void dispose() {
    weight.dispose();
    length.dispose();
    width.dispose();
    notes.dispose();
  }
}

class _CrabBulkAddDialog extends StatefulWidget {
  const _CrabBulkAddDialog({required this.service, this.initialLotId});

  final CrabService service;
  final String? initialLotId;

  @override
  State<_CrabBulkAddDialog> createState() => _CrabBulkAddDialogState();
}

class _CrabBulkAddDialogState extends State<_CrabBulkAddDialog> {
  final _typeCtrl = TextEditingController();
  final List<_RowData> _rows = [];

  List<CrabBatchChoice> _lots = [];
  List<RowRecord> _rowOptions = [];
  List<BoxRecord> _emptyBoxes = [];

  CrabBatchChoice? _lot;
  String? _areaId;
  String? _rowId;
  String _condition = 'normal';
  DateTime _stockedAt = DateTime.now();
  var _loading = true;
  var _saving = false;
  String? _loadError;
  String _seedCode = 'CRAB-0001';

  CrabService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    var lots = List<CrabBatchChoice>.from(_svc.batchChoices);
    if (lots.isEmpty) {
      await _svc.refreshLots();
      lots = List<CrabBatchChoice>.from(_svc.batchChoices);
    }
    if (lots.isEmpty) {
      setState(() {
        _loading = false;
        _loadError = 'Chưa có lô cua. Hãy Nhập lô trước khi thêm cua.';
      });
      return;
    }

    final next = await _svc.peekNextCrabIdentity();
    final defaultArea = _svc.farmId.isEmpty ? null : _svc.farmId;

    CrabBatchChoice? selected;
    final prefer = widget.initialLotId;
    if (prefer != null) {
      for (final lot in lots) {
        if (lot.batchId == prefer) {
          selected = lot;
          break;
        }
      }
    }

    _seedCode = next?.code ?? 'CRAB-0001';
    var code = _seedCode;
    final start = <_RowData>[];
    for (var i = 0; i < 3; i++) {
      start.add(_RowData(code: code));
      code = _nextCode(code);
    }

    setState(() {
      _lots = lots;
      _lot = selected ?? lots.first;
      _areaId = defaultArea;
      _rows.addAll(start);
      _loading = false;
    });
    if (defaultArea != null) {
      await _loadRows(defaultArea);
    } else {
      await _loadBoxes();
    }
  }

  Future<void> _loadRows(String areaId) async {
    try {
      final rows = await _svc.fetchRows(areaId);
      if (!mounted) return;
      setState(() {
        _rowOptions = rows;
        if (_rowId != null && !rows.any((r) => r.id == _rowId)) _rowId = null;
      });
      await _loadBoxes(areaId: areaId, rowId: _rowId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = '$e');
    }
  }

  Future<void> _loadBoxes({String? areaId, String? rowId}) async {
    try {
      final boxes = await _svc.fetchEmptyBoxes(
        areaId: areaId ?? _areaId,
        rowId: rowId ?? _rowId,
      );
      if (!mounted) return;
      setState(() {
        _emptyBoxes = boxes;
        for (final row in _rows) {
          if (row.boxId != _autoBox && !boxes.any((b) => b.id == row.boxId)) {
            row.boxId = _autoBox;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _emptyBoxes = []);
    }
  }

  String _lastCode() => _rows.isEmpty ? _seedCode : _rows.last.code;

  void _addRows([int count = 1]) {
    var code = _nextCode(_lastCode());
    setState(() {
      for (var i = 0; i < count; i++) {
        _rows.add(_RowData(code: code));
        code = _nextCode(code);
      }
    });
  }

  void _duplicateSelected() {
    final chosen = _rows.where((r) => r.selected).toList();
    if (chosen.isEmpty) {
      _snack('Chọn ít nhất một dòng để nhân bản');
      return;
    }
    var code = _nextCode(_lastCode());
    setState(() {
      for (final src in chosen) {
        final copy = _RowData(code: code)
          ..gender = src.gender
          ..weight.text = src.weight.text
          ..length.text = src.length.text
          ..width.text = src.width.text
          ..notes.text = src.notes.text
          ..boxId = _autoBox
          ..imagePaths.addAll(src.imagePaths);
        _rows.add(copy);
        code = _nextCode(code);
      }
      for (final r in _rows) {
        r.selected = false;
      }
    });
  }

  void _deleteSelected() {
    final chosen = _rows.where((r) => r.selected).toList();
    if (chosen.isEmpty) {
      _snack('Chọn dòng cần xóa');
      return;
    }
    if (chosen.length >= _rows.length) {
      _snack('Giữ lại ít nhất một dòng');
      return;
    }
    setState(() {
      for (final r in chosen) {
        r.dispose();
        _rows.remove(r);
      }
    });
  }

  Future<void> _pickPhoto(_RowData row) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'],
      allowMultiple: true,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        final path = f.path;
        if (path == null || path.isEmpty) continue;
        if (row.imagePaths.contains(path)) continue;
        row.imagePaths.add(path);
        if (row.imagePaths.length >= 5) break;
      }
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Set<String> _takenBoxes(_RowData except) {
    return _rows
        .where((r) => r.id != except.id && r.boxId != _autoBox)
        .map((r) => r.boxId)
        .toSet();
  }

  Future<void> _save() async {
    if (_lot == null) {
      _snack('Chọn lô nhập');
      return;
    }
    final areaId = _areaId ?? _svc.farmId;
    final parsed = <({
      _RowData row,
      double weight,
      double length,
      double width,
    })>[];
    final usedBoxes = <String>{};
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final w = double.tryParse(row.weight.text.trim().replaceAll(',', '.'));
      final l = double.tryParse(row.length.text.trim().replaceAll(',', '.'));
      final wd = double.tryParse(row.width.text.trim().replaceAll(',', '.'));
      if (w == null || w <= 0 || l == null || l <= 0 || wd == null || wd <= 0) {
        _snack('Dòng ${i + 1}: cân nặng, bề ngang và bề rộng mai phải > 0');
        return;
      }
      if (row.boxId != _autoBox) {
        if (!usedBoxes.add(row.boxId)) {
          _snack('Dòng ${i + 1}: hộp đã được chọn ở dòng khác');
          return;
        }
      }
      parsed.add((row: row, weight: w, length: l, width: wd));
    }

    setState(() => _saving = true);

    final payload = [
      for (final item in parsed)
        (
          batchId: _lot!.batchId,
          gender: item.row.gender,
          weightGram: item.weight,
          carapaceWidthMm: item.width,
          carapaceLengthMm: item.length,
          note: item.row.notes.text.trim().isEmpty ? null : item.row.notes.text.trim(),
          boxId: item.row.boxId == _autoBox ? null : item.row.boxId,
          farmingAreaId: areaId.isEmpty ? null : areaId,
          farmingRowId: _rowId,
          crabType: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
          initialCondition: _initialCondition(_condition),
          condition: _apiCondition(_condition),
          stockedAt: _stockedAt,
          imagePaths: item.row.imagePaths.isEmpty ? null : List<String>.from(item.row.imagePaths),
        ),
    ];

    final result = await _svc.addCrabsBulk(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.saved == 0) {
      _snack(result.errors.isEmpty ? 'Không lưu được cua' : result.errors.first);
      return;
    }
    Navigator.pop(context, true);
    final extra = result.errors.isEmpty
        ? ''
        : ' · ${result.errors.length} dòng lỗi';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${result.saved} cua$extra')),
    );
  }

  InputDecoration _dec({String? hint}) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: DashboardColors.darkNavy,
        hintStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DashboardColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280, maxHeight: 860),
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Column(
                        children: [
                          if (_loadError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _loadError!,
                                style: GoogleFonts.notoSans(color: DashboardColors.risk),
                              ),
                            ),
                          _sharedBar(),
                          const SizedBox(height: 12),
                          _rowActions(),
                          const SizedBox(height: 8),
                          Expanded(child: _table()),
                        ],
                      ),
                    ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm nhiều cua',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lô, ngày thả và tình trạng dùng chung. Cân nặng, mai và hộp nhập từng con.',
                  style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            icon: Icon(Icons.close, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _sharedBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          if (_lots.isNotEmpty)
            _sharedDropdown<String>(
              label: 'Lô nhập',
              width: 240,
              value: _lot!.batchId,
              items: {for (final l in _lots) l.batchId: l.label},
              onChanged: (v) {
                setState(() {
                  _lot = _lots.firstWhere((l) => l.batchId == v, orElse: () => _lots.first);
                });
              },
            ),
          _sharedDropdown<String>(
            label: 'Dãy',
            width: 200,
            value: _rowId ?? '',
            items: {
              '': 'Tất cả dãy',
              for (final r in _rowOptions) r.id: '${r.rowCode} — ${r.rowName}',
            },
            onChanged: (v) {
              setState(() => _rowId = (v == null || v.isEmpty) ? null : v);
              _loadBoxes(areaId: _areaId, rowId: v);
            },
          ),
          _sharedDropdown<String>(
            label: 'Tình trạng mặc định',
            width: 180,
            value: _condition,
            items: {for (final c in _conditions) c.$1: c.$2},
            onChanged: (v) {
              if (v != null) setState(() => _condition = v);
            },
          ),
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Loại cua'),
                TextField(
                  controller: _typeCtrl,
                  decoration: _dec(hint: 'Cua biển…'),
                  style: GoogleFonts.notoSans(fontSize: 13, color: DashboardColors.textPrimary),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _saving
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _stockedAt,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) setState(() => _stockedAt = picked);
                  },
            child: SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _lbl('Ngày thả'),
                  InputDecorator(
                    decoration: _dec(),
                    child: Text(
                      '${_stockedAt.day.toString().padLeft(2, '0')}/${_stockedAt.month.toString().padLeft(2, '0')}/${_stockedAt.year}',
                      style: GoogleFonts.notoSans(fontSize: 13, color: DashboardColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowActions() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _saving ? null : () => _addRows(),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Thêm dòng'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _saving ? null : _duplicateSelected,
          icon: const Icon(Icons.copy_all_outlined, size: 16),
          label: const Text('Nhân bản dòng'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _saving ? null : _deleteSelected,
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Xóa dòng'),
          style: OutlinedButton.styleFrom(foregroundColor: DashboardColors.risk),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () => _snack('Import Excel sẽ có ở bản sau — hiện nhập trực tiếp trên bảng.'),
          icon: const Icon(Icons.table_view_outlined, size: 16),
          label: const Text('Import Excel'),
        ),
        const Spacer(),
        Text(
          '${_rows.length} dòng',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _table() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: DashboardColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1180),
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              columnSpacing: 10,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
              columns: const [
                DataColumn(label: Text('')),
                DataColumn(label: Text('STT')),
                DataColumn(label: Text('MÃ CUA')),
                DataColumn(label: Text('GIỚI TÍNH')),
                DataColumn(label: Text('NẶNG (g)')),
                DataColumn(label: Text('BỀ NGANG')),
                DataColumn(label: Text('BỀ RỘNG')),
                DataColumn(label: Text('HỘP')),
                DataColumn(label: Text('GHI CHÚ')),
                DataColumn(label: Text('ẢNH')),
              ],
              rows: [
                for (var i = 0; i < _rows.length; i++) _dataRow(i, _rows[i]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _dataRow(int index, _RowData row) {
    final taken = _takenBoxes(row);
    final boxItems = <String, String>{
      _autoBox: 'Tự gán hộp trống',
      for (final b in _emptyBoxes)
        if (!taken.contains(b.id) || b.id == row.boxId) b.id: b.title,
    };
    return DataRow(
      cells: [
        DataCell(
          Checkbox(
            value: row.selected,
            onChanged: _saving
                ? null
                : (v) => setState(() => row.selected = v ?? false),
          ),
        ),
        DataCell(Text('${index + 1}', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary))),
        DataCell(
          Text(
            row.code,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          DropdownButtonHideUnderline(
            child: DropdownButton<CrabGender>(
              value: row.gender,
              isDense: true,
              dropdownColor: DashboardColors.card,
              style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.textPrimary),
              items: [
                for (final g in CrabGender.values)
                  DropdownMenuItem(value: g, child: Text(_genderLabel(g))),
              ],
              onChanged: _saving ? null : (v) => setState(() => row.gender = v ?? CrabGender.unknown),
            ),
          ),
        ),
        DataCell(_numField(row.weight, '120')),
        DataCell(_numField(row.length, 'mm')),
        DataCell(_numField(row.width, 'mm')),
        DataCell(
          SizedBox(
            width: 160,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: boxItems.containsKey(row.boxId) ? row.boxId : _autoBox,
                isDense: true,
                isExpanded: true,
                dropdownColor: DashboardColors.card,
                style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.textPrimary),
                items: [
                  for (final e in boxItems.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: _saving ? null : (v) => setState(() => row.boxId = v ?? _autoBox),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 140,
            child: TextField(
              controller: row.notes,
              enabled: !_saving,
              decoration: _dec(hint: 'Tuỳ chọn'),
              style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.textPrimary),
            ),
          ),
        ),
        DataCell(_photoCell(row)),
      ],
    );
  }

  Widget _numField(TextEditingController ctrl, String hint) {
    return SizedBox(
      width: 78,
      child: TextField(
        controller: ctrl,
        enabled: !_saving,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: _dec(hint: hint),
        style: GoogleFonts.notoSans(fontSize: 13, color: DashboardColors.textPrimary),
      ),
    );
  }

  Widget _photoCell(_RowData row) {
    final path = row.imagePaths.isEmpty ? null : row.imagePaths.first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (path != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(File(path), width: 32, height: 32, fit: BoxFit.cover),
            ),
          ),
        IconButton(
          tooltip: row.imagePaths.isEmpty ? 'Upload ảnh' : '${row.imagePaths.length} ảnh',
          onPressed: _saving ? null : () => _pickPhoto(row),
          icon: Icon(
            row.imagePaths.isEmpty ? Icons.add_a_photo_outlined : Icons.photo_library_outlined,
            size: 20,
            color: DashboardColors.cyan,
          ),
        ),
        if (row.imagePaths.isNotEmpty)
          IconButton(
            tooltip: 'Xóa ảnh',
            onPressed: _saving ? null : () => setState(row.imagePaths.clear),
            icon: Icon(Icons.close, size: 16, color: DashboardColors.textMuted),
          ),
      ],
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (_saving)
            Text(
              'Đang lưu…',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _saving || _lot == null ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.oceanBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Lưu tất cả (${_rows.length})'),
          ),
        ],
      ),
    );
  }

  Widget _lbl(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _sharedDropdown<T>({
    required String label,
    required double width,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lbl(label),
          DropdownButtonFormField<T>(
            key: ValueKey('$label-$value'),
            initialValue: items.containsKey(value) ? value : items.keys.first,
            isExpanded: true,
            decoration: _dec(),
            dropdownColor: DashboardColors.card,
            style: GoogleFonts.notoSans(fontSize: 13, color: DashboardColors.textPrimary),
            items: [
              for (final e in items.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: _saving ? null : onChanged,
          ),
        ],
      ),
    );
  }
}
