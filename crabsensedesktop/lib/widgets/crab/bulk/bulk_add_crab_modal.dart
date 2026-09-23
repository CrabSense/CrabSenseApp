import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/crab_status.dart';
import '../../../models/production_models.dart';
import '../../../services/crab_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/crab_management_mapper.dart';
import '../../shared/mgmt_ui.dart';

const _kAutoBox = '__auto_empty_box__';
const _kTypes = ['Cua biển', 'Cua xanh', 'Khác'];
const _kHealth = [
  CrabDisplayHealth.healthy,
  CrabDisplayHealth.monitoring,
  CrabDisplayHealth.weak,
];

String _nextCode(String current) {
  final match = RegExp(r'^(.*?)(\d+)$').firstMatch(current.trim());
  if (match == null) return '$current-2';
  final n = int.parse(match.group(2)!);
  return '${match.group(1)}${(n + 1).toString().padLeft(match.group(2)!.length, '0')}';
}

bool _boxUnusable(BoxRecord b) {
  final s = b.status.toLowerCase();
  return s == 'maintenance' ||
      s == 'quarantine' ||
      s == 'suspended' ||
      s == 'closed' ||
      s == 'harvested';
}

bool _boxSelectable(BoxRecord b) => !b.hasCrab && !_boxUnusable(b) && b.alertCount <= 0;

String _boxOptionLabel(BoxRecord b) {
  final row = (b.rowCode ?? b.rowName ?? '').trim();
  final loc = row.isEmpty ? b.boxCode : '${b.boxCode} — $row';
  if (b.id == _kAutoBox) return loc;
  if (b.hasCrab) return '$loc — Đã có cua · Không thể chọn';
  if (b.alertCount > 0) return '$loc — Cảnh báo · Không thể chọn';
  if (_boxUnusable(b)) return '$loc — Không hoạt động · Không thể chọn';
  return '$loc — Trống';
}

enum BulkRowIssue { none, missingWeight, invalidSize, duplicateBox, boxInvalid }

class BulkRowData {
  BulkRowData({required this.code})
      : weight = TextEditingController(),
        width = TextEditingController(),
        length = TextEditingController(),
        notes = TextEditingController();

  final String id = UniqueKey().toString();
  bool selected = false;
  String code;
  CrabGender gender = CrabGender.unknown;
  final TextEditingController weight;
  final TextEditingController width;
  final TextEditingController length;
  final TextEditingController notes;
  String boxId = _kAutoBox;
  String? imagePath;

  void dispose() {
    weight.dispose();
    width.dispose();
    length.dispose();
    notes.dispose();
  }
}

Future<bool> showBulkAddCrabModal(
  BuildContext context,
  CrabService service, {
  String? initialLotId,
  VoidCallback? onManageLots,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (_) => BulkAddCrabModal(
      service: service,
      initialLotId: initialLotId,
      onManageLots: onManageLots,
    ),
  );
  return saved == true;
}

class BulkAddCrabModal extends StatefulWidget {
  const BulkAddCrabModal({
    super.key,
    required this.service,
    this.initialLotId,
    this.onManageLots,
  });

  final CrabService service;
  final String? initialLotId;
  final VoidCallback? onManageLots;

  @override
  State<BulkAddCrabModal> createState() => _BulkAddCrabModalState();
}

class _BulkAddCrabModalState extends State<BulkAddCrabModal> {
  final List<BulkRowData> _rows = [];
  List<FarmingBatchRecord> _lots = const [];
  List<AreaRecord> _areas = const [];
  List<RowRecord> _rowOptions = const [];
  List<BoxRecord> _boxes = const [];

  FarmingBatchRecord? _lot;
  String? _areaId;
  String? _rowId;
  CrabDisplayHealth _health = CrabDisplayHealth.healthy;
  String _type = 'Cua biển';
  DateTime _enteredAt = DateTime.now();

  var _loading = true;
  var _boxesLoading = false;
  var _importing = false;
  var _saving = false;
  String? _error;
  var _conflict = false;
  String _seedCode = 'CRAB-0001';

  CrabService get _svc => widget.service;

  int get _remaining => _lot?.remainingCount ?? 0;
  int get _validCount => _rows.where((r) => _issueOf(r) == BulkRowIssue.none).length;
  int get _autoCount => _rows.where((r) => r.boxId == _kAutoBox).length;
  int get _emptyBoxCount => _boxes.where(_boxSelectable).length;
  bool get _allValid => _rows.isNotEmpty && _validCount == _rows.length;
  bool get _canSave =>
      !_saving &&
      !_loading &&
      _lot != null &&
      _areaId != null &&
      _allValid &&
      _rows.length <= _remaining &&
      (_emptyBoxCount >= _rows.length);

  BulkRowIssue _issueOf(BulkRowData row) {
    final w = double.tryParse(row.weight.text.trim().replaceAll(',', '.'));
    final wd = double.tryParse(row.width.text.trim().replaceAll(',', '.'));
    final ln = double.tryParse(row.length.text.trim().replaceAll(',', '.'));
    if (w == null || w <= 0) return BulkRowIssue.missingWeight;
    if (wd == null || wd <= 0 || ln == null || ln <= 0) return BulkRowIssue.invalidSize;
    if (row.boxId != _kAutoBox) {
      final box = _boxes.where((b) => b.id == row.boxId).firstOrNull;
      if (box == null || !_boxSelectable(box)) return BulkRowIssue.boxInvalid;
      final dup = _rows.any((o) => o.id != row.id && o.boxId == row.boxId);
      if (dup) return BulkRowIssue.duplicateBox;
    }
    return BulkRowIssue.none;
  }

  String _issueLabel(BulkRowIssue i) => switch (i) {
        BulkRowIssue.none => 'Hợp lệ',
        BulkRowIssue.missingWeight => 'Thiếu cân nặng',
        BulkRowIssue.invalidSize => 'Kích thước không hợp lệ',
        BulkRowIssue.duplicateBox => 'Hộp bị trùng',
        BulkRowIssue.boxInvalid => 'Hộp không còn trống',
      };

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _svc.refreshLots();
      final lots = _svc.availableLots;
      final areas = await _svc.fetchAreas();
      final next = await _svc.peekNextCrabIdentity();
      _seedCode = next?.code ?? 'CRAB-0001';

      FarmingBatchRecord? lot;
      final prefer = widget.initialLotId;
      if (prefer != null) {
        lot = lots.where((l) => l.id == prefer).firstOrNull;
      }
      lot ??= lots.isEmpty ? null : lots.first;

      var areaId = _svc.areaFilter != kAllFilter ? _svc.areaFilter : null;
      areaId ??= areas.isEmpty ? null : areas.first.id;

      if (!mounted) return;
      setState(() {
        _lots = lots;
        _lot = lot;
        _areas = areas;
        _areaId = areaId;
        _loading = false;
      });
      if (lot != null) _seedRows(lot.remainingCount.clamp(0, 5));
      if (areaId != null) await _loadRows(areaId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _seedRows(int count) {
    for (final r in _rows) {
      r.dispose();
    }
    _rows.clear();
    var code = _seedCode;
    for (var i = 0; i < count; i++) {
      _rows.add(BulkRowData(code: code));
      code = _nextCode(code);
    }
  }

  Future<void> _loadRows(String areaId) async {
    setState(() => _boxesLoading = true);
    try {
      final rows = await _svc.fetchRows(areaId);
      if (!mounted) return;
      setState(() {
        _rowOptions = rows;
        if (_rowId != null && !rows.any((r) => r.id == _rowId)) _rowId = null;
      });
      await _loadBoxes();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _boxesLoading = false;
      });
    }
  }

  Future<void> _loadBoxes() async {
    setState(() => _boxesLoading = true);
    try {
      final boxes = await _svc.fetchBoxes(areaId: _areaId, rowId: _rowId);
      if (!mounted) return;
      setState(() {
        _boxes = boxes;
        for (final row in _rows) {
          if (row.boxId != _kAutoBox && !boxes.any((b) => b.id == row.boxId)) {
            row.boxId = _kAutoBox;
          }
        }
        _boxesLoading = false;
        _conflict = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _boxes = const [];
        _boxesLoading = false;
      });
    }
  }

  void _addRows([int count = 1]) {
    if (_rows.length + count > _remaining) {
      _snack('Lô này chỉ còn $_remaining cá thể chưa được tạo.');
      return;
    }
    var code = _rows.isEmpty ? _seedCode : _nextCode(_rows.last.code);
    setState(() {
      for (var i = 0; i < count; i++) {
        _rows.add(BulkRowData(code: code));
        code = _nextCode(code);
      }
    });
  }

  void _duplicateSelected() {
    final chosen = _rows.where((r) => r.selected).toList();
    if (chosen.isEmpty) return;
    if (_rows.length + chosen.length > _remaining) {
      _snack('Lô này chỉ còn $_remaining cá thể chưa được tạo.');
      return;
    }
    var code = _nextCode(_rows.last.code);
    setState(() {
      for (final src in chosen) {
        final copy = BulkRowData(code: code)
          ..gender = src.gender
          ..weight.text = src.weight.text
          ..width.text = src.width.text
          ..length.text = src.length.text
          ..notes.text = src.notes.text
          ..imagePath = src.imagePath;
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
    if (chosen.isEmpty || chosen.length >= _rows.length) {
      if (chosen.length >= _rows.length) _snack('Giữ lại ít nhất một dòng.');
      return;
    }
    setState(() {
      for (final r in chosen) {
        r.dispose();
        _rows.remove(r);
      }
    });
  }

  Future<void> _bulkAction(String action) async {
    final chosen = _rows.where((r) => r.selected).toList();
    if (chosen.isEmpty) {
      _snack('Chọn ít nhất một dòng.');
      return;
    }
    switch (action) {
      case 'gender':
        final g = await _pickGender();
        if (g == null) return;
        setState(() {
          for (final r in chosen) {
            r.gender = g;
          }
        });
      case 'health':
        final h = await _pickHealth();
        if (h == null) return;
        setState(() => _health = h);
      case 'date':
        final d = await showDatePicker(
          context: context,
          initialDate: _enteredAt,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (d != null) setState(() => _enteredAt = d);
      case 'row':
        if (_rowOptions.isEmpty) return;
        final id = await _pickRow();
        if (id == null) return;
        setState(() => _rowId = id.isEmpty ? null : id);
        await _loadBoxes();
      case 'auto':
        setState(() {
          for (final r in chosen) {
            r.boxId = _kAutoBox;
          }
        });
      case 'clearNote':
        setState(() {
          for (final r in chosen) {
            r.notes.clear();
          }
        });
    }
  }

  Future<CrabGender?> _pickGender() {
    return showModalBottomSheet<CrabGender>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final g in CrabGender.values)
            ListTile(title: Text(g.label), onTap: () => Navigator.pop(ctx, g)),
        ],
      ),
    );
  }

  Future<CrabDisplayHealth?> _pickHealth() {
    return showModalBottomSheet<CrabDisplayHealth>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final h in _kHealth)
            ListTile(title: Text(h.label), onTap: () => Navigator.pop(ctx, h)),
        ],
      ),
    );
  }

  Future<String?> _pickRow() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('Tất cả dãy'), onTap: () => Navigator.pop(ctx, '')),
          for (final r in _rowOptions)
            ListTile(
              title: Text(r.rowName.trim().isEmpty ? r.rowCode : r.rowName),
              onTap: () => Navigator.pop(ctx, r.id),
            ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(BulkRowData row) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    setState(() => row.imagePath = path);
  }

  Future<void> _previewPhoto(String path) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(path), fit: BoxFit.contain),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    const csv = 'Giới tính,Cân nặng (g),Rộng mai (mm),Dài mai (mm),Mã hộp,Ghi chú\n'
        'Đực,120,65,90,,Tùy chọn\n'
        'Cái,118,63,88,,\n';
    final bytes = Uint8List.fromList(utf8.encode('\uFEFF$csv'));
    await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu file mẫu',
      fileName: 'mau-them-nhieu-cua.csv',
      bytes: bytes,
    );
  }

  Future<void> _importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    setState(() => _importing = true);
    try {
      final text = await File(path).readAsString();
      final parsed = _parseCsv(text);
      if (!mounted) return;
      setState(() => _importing = false);
      if (parsed.isEmpty) {
        _snack('Không đọc được dòng dữ liệu từ file.');
        return;
      }
      await _showImportPreview(parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      _snack('Không đọc được file: $e');
    }
  }

  List<_ImportRow> _parseCsv(String raw) {
    final lines = const LineSplitter().convert(raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
    if (lines.isEmpty) return const [];
    final start = lines.first.toLowerCase().contains('giới tính') ||
            lines.first.toLowerCase().contains('gioi tinh') ||
            lines.first.toLowerCase().contains('cân nặng')
        ? 1
        : 0;
    final out = <_ImportRow>[];
    for (var i = start; i < lines.length; i++) {
      final cols = _splitCsv(lines[i]);
      if (cols.every((c) => c.trim().isEmpty)) continue;
      out.add(_ImportRow(
        line: i + 1,
        gender: _parseGender(cols.elementAtOrNull(0)),
        weight: double.tryParse((cols.elementAtOrNull(1) ?? '').replaceAll(',', '.')),
        width: double.tryParse((cols.elementAtOrNull(2) ?? '').replaceAll(',', '.')),
        length: double.tryParse((cols.elementAtOrNull(3) ?? '').replaceAll(',', '.')),
        boxCode: (cols.elementAtOrNull(4) ?? '').trim(),
        note: (cols.elementAtOrNull(5) ?? '').trim(),
      ));
    }
    return out;
  }

  List<String> _splitCsv(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    var q = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        q = !q;
      } else if (ch == ',' && !q) {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    out.add(buf.toString());
    return out;
  }

  CrabGender _parseGender(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s == 'đực' || s == 'duc' || s == 'male' || s == 'm') return CrabGender.male;
    if (s == 'cái' || s == 'cai' || s == 'female' || s == 'f') return CrabGender.female;
    return CrabGender.unknown;
  }

  String? _importError(_ImportRow r) {
    if (r.weight == null || r.weight! <= 0) return 'Cân nặng không hợp lệ.';
    if (r.width == null || r.width! <= 0 || r.length == null || r.length! <= 0) {
      return 'Kích thước không hợp lệ.';
    }
    if (r.boxCode.isNotEmpty) {
      final box = _boxes.where((b) => b.boxCode.toLowerCase() == r.boxCode.toLowerCase()).firstOrNull;
      if (box == null) return '${r.boxCode} không thuộc khu/dãy đang chọn.';
      if (!_boxSelectable(box)) return '${r.boxCode} đã có cua hoặc không dùng được.';
    }
    return null;
  }

  Future<void> _showImportPreview(List<_ImportRow> rows) async {
    final ok = [for (final r in rows) if (_importError(r) == null) r];
    final bad = [for (final r in rows) if (_importError(r) != null) r];
    final accept = await showDialog<bool>(
      context: context,
      barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Import Excel', style: bvText(fontSize: 17, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tổng dòng: ${rows.length}', style: bvText(color: DashboardColors.textPrimary)),
              Text('Hợp lệ: ${ok.length}', style: bvText(color: DashboardColors.brand)),
              Text('Có lỗi: ${bad.length}', style: bvText(color: DashboardColors.risk)),
              const SizedBox(height: 10),
              if (bad.isNotEmpty)
                ...bad.take(6).map(
                      (r) => Text('Dòng ${r.line}: ${_importError(r)}', style: bvText(fontSize: 12.5, color: DashboardColors.risk)),
                    ),
            ],
          ),
        ),
        actions: [
          MgmtOutlineButton(label: 'Hủy', onTap: () => Navigator.pop(ctx, false)),
          if (ok.isNotEmpty)
            MgmtPrimaryButton(
              label: 'Thêm ${ok.length} dòng hợp lệ',
              height: 38,
              onTap: () => Navigator.pop(ctx, true),
            ),
        ],
      ),
    );
    if (accept != true || !mounted) return;
    final room = _remaining - _rows.length;
    final take = ok.take(room < 0 ? 0 : room).toList();
    if (take.length < ok.length) {
      _snack('Lô chỉ còn $room chỗ — đã thêm ${take.length} dòng.');
    }
    var code = _rows.isEmpty ? _seedCode : _nextCode(_rows.last.code);
    setState(() {
      for (final r in take) {
        final row = BulkRowData(code: code)
          ..gender = r.gender
          ..weight.text = r.weight!.toString()
          ..width.text = r.width!.toString()
          ..length.text = r.length!.toString()
          ..notes.text = r.note;
        if (r.boxCode.isNotEmpty) {
          final box = _boxes.where((b) => b.boxCode.toLowerCase() == r.boxCode.toLowerCase()).firstOrNull;
          if (box != null) row.boxId = box.id;
        }
        _rows.add(row);
        code = _nextCode(code);
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave || _lot == null || _areaId == null) return;
    setState(() {
      _saving = true;
      _error = null;
      _conflict = false;
    });
    final payload = [
      for (final row in _rows)
        (
          batchId: _lot!.id,
          gender: row.gender,
          weightGram: double.parse(row.weight.text.trim().replaceAll(',', '.')),
          carapaceWidthMm: double.parse(row.width.text.trim().replaceAll(',', '.')),
          carapaceLengthMm: double.parse(row.length.text.trim().replaceAll(',', '.')),
          note: row.notes.text.trim().isEmpty ? null : row.notes.text.trim(),
          boxId: row.boxId == _kAutoBox ? null : row.boxId,
          farmingAreaId: _areaId,
          farmingRowId: _rowId,
          crabType: _type,
          initialCondition: _health.label,
          condition: healthDisplayToCondition(_health),
          stockedAt: _enteredAt,
          imagePaths: row.imagePath == null ? null : [row.imagePath!],
        ),
    ];
    final result = await _svc.addCrabsBulk(payload);
    if (!mounted) return;
    if (result.saved <= 0) {
      final msg = result.errors.isEmpty ? 'Không lưu được cua.' : result.errors.first;
      setState(() {
        _saving = false;
        _conflict = msg.toLowerCase().contains('vừa được') || msg.toLowerCase().contains('đã có cua');
        _error = msg;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _autoCount == _rows.length
              ? 'Đã tạo ${result.saved} cua và phân vào ${result.saved} hộp.'
              : 'Đã tạo ${result.saved} cá thể cua thành công.',
        ),
      ),
    );
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1180;
    final compact = MediaQuery.sizeOf(context).width < 780;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16, vertical: compact ? 8 : 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1480, maxHeight: 900),
        child: Shortcuts(
          shortcuts: {LogicalKeySet(LogicalKeyboardKey.escape): const _EscIntent()},
          child: Actions(
            actions: {
              _EscIntent: CallbackAction<_EscIntent>(onInvoke: (_) {
                if (!_saving) Navigator.pop(context, false);
                return null;
              }),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  _header(),
                  const Divider(height: 1, color: DashboardColors.mint),
                  Expanded(child: _body(wide, compact)),
                  const Divider(height: 1, color: DashboardColors.mint),
                  _footer(compact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.set_meal_outlined, color: DashboardColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thêm nhiều cua', style: bvText(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                Text(
                  'Tạo nhiều cá thể từ cùng một lô nhập và phân vào các hộp nuôi.',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _body(bool wide, bool compact) {
    if (_loading) {
      return const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.4)));
    }
    if (_lots.isEmpty) {
      return Center(
        child: MgmtEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Không có lô nhập khả dụng.',
          message: 'Các lô đã tạo đủ số lượng cá thể sẽ không xuất hiện ở đây.',
          action: widget.onManageLots == null
              ? null
              : MgmtPrimaryButton(
                  label: 'Quản lý nhập hàng',
                  height: 38,
                  onTap: () {
                    Navigator.pop(context, false);
                    widget.onManageLots!();
                  },
                ),
        ),
      );
    }

    final form = _leftColumn(compact);
    final side = BulkRulesPanel(lot: _lot);
    if (!wide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(children: [form, const SizedBox(height: 14), side]),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 80,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            child: form,
          ),
        ),
        Container(width: 1, color: DashboardColors.mint),
        Expanded(
          flex: 20,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
            child: side,
          ),
        ),
      ],
    );
  }

  Widget _leftColumn(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BulkAddHeaderForm(
          lots: _lots,
          areas: _areas,
          rows: _rowOptions,
          lot: _lot,
          areaId: _areaId,
          rowId: _rowId,
          health: _health,
          type: _type,
          enteredAt: _enteredAt,
          boxesLoading: _boxesLoading,
          rowCount: _rows.length,
          onLot: (id) {
            final lot = _lots.where((l) => l.id == id).firstOrNull;
            setState(() {
              _lot = lot;
              if (lot != null && _rows.length > lot.remainingCount) {
                while (_rows.length > lot.remainingCount) {
                  _rows.removeLast().dispose();
                }
              }
            });
          },
          onArea: (id) {
            setState(() {
              _areaId = id;
              _rowId = null;
            });
            _loadRows(id);
          },
          onRow: (id) {
            setState(() => _rowId = id.isEmpty ? null : id);
            _loadBoxes();
          },
          onHealth: (h) => setState(() => _health = h),
          onType: (t) => setState(() => _type = t),
          onDate: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _enteredAt,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (d != null) setState(() => _enteredAt = d);
          },
        ),
        const SizedBox(height: 12),
        BulkActionToolbar(
          selected: _rows.where((r) => r.selected).length,
          total: _rows.length,
          importing: _importing,
          onAdd: () => _addRows(),
          onDuplicate: _duplicateSelected,
          onDelete: _deleteSelected,
          onBulk: _bulkAction,
          onImport: _importExcel,
          onTemplate: _downloadTemplate,
        ),
        const SizedBox(height: 8),
        if (compact)
          ...[
            for (var i = 0; i < _rows.length; i++)
              _rowCard(i, _rows[i]),
          ]
        else
          BulkCrabTable(
            rows: _rows,
            boxes: _boxes,
            boxesLoading: _boxesLoading,
            issueOf: _issueOf,
            issueLabel: _issueLabel,
            onChanged: () => setState(() {}),
            onPickPhoto: _pickPhoto,
            onPreviewPhoto: _previewPhoto,
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DashboardColors.lightMint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DashboardColors.mint),
          ),
          child: Text(
            'Hệ thống tự động gán hộp hoạt động, chưa có cua và không có lỗi. Mỗi hộp chứa 1 cua.',
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
        ),
        const SizedBox(height: 10),
        BulkSummary(
          creating: _rows.length,
          valid: _validCount,
          auto: _autoCount,
          emptyBoxes: _emptyBoxCount,
          remaining: _remaining,
        ),
        const SizedBox(height: 8),
        if (_rows.isNotEmpty && !_allValid)
          _warnCard('Có ${_rows.length - _validCount} dòng cần kiểm tra', 'Vui lòng kiểm tra các dòng có cảnh báo trước khi lưu.')
        else if (_allValid)
          _okCard('Tất cả dòng hợp lệ')
        else
          const SizedBox.shrink(),
        if (_emptyBoxCount < _rows.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _warnCard('Chỉ có $_emptyBoxCount hộp phù hợp.', 'Không đủ hộp trống để gán cho ${_rows.length} cua.'),
          ),
        if (_conflict) ...[
          const SizedBox(height: 8),
          _warnCard('Một số hộp vừa được sử dụng.', 'Vui lòng làm mới và chọn lại hộp.'),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: MgmtOutlineButton(label: 'Làm mới danh sách hộp', onTap: _loadBoxes),
          ),
        ] else if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: bvText(fontSize: 12.5, color: DashboardColors.risk)),
        ],
      ],
    );
  }

  Widget _rowCard(int i, BulkRowData row) {
    final issue = _issueOf(row);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: mgmtCardDeco(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(value: row.selected, onChanged: (v) => setState(() => row.selected = v ?? false)),
              Expanded(
                child: Text('${i + 1}. ${row.code}', style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              ),
              _statusBadge(issue),
            ],
          ),
          const SizedBox(height: 8),
          _Select<CrabGender>(
            valueLabel: row.gender.label,
            items: [for (final g in CrabGender.values) (g, g.label)],
            onSelected: (v) => setState(() => row.gender = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _num(row.weight, 'g', () => setState(() {}))),
              const SizedBox(width: 8),
              Expanded(child: _num(row.width, 'Rộng mm', () => setState(() {}))),
              const SizedBox(width: 8),
              Expanded(child: _num(row.length, 'Dài mm', () => setState(() {}))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer(bool compact) {
    final cancel = MgmtOutlineButton(label: 'Hủy', onTap: _saving ? null : () => Navigator.pop(context, false));
    final save = _saving
        ? Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: DashboardColors.brand.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                const SizedBox(width: 8),
                Text('Đang lưu...', style: bvText(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          )
        : MgmtPrimaryButton(
            label: 'Lưu tất cả ($_validCount)',
            icon: Icons.check_rounded,
            onTap: _canSave ? _save : null,
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [save, const SizedBox(height: 8), cancel])
          : Row(mainAxisAlignment: MainAxisAlignment.end, children: [cancel, const SizedBox(width: 10), save]),
    );
  }

  Widget _warnCard(String title, String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: bvText(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFB45309))),
          Text(msg, style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _okCard(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Text(title, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.brand)),
    );
  }
}

class _ImportRow {
  const _ImportRow({
    required this.line,
    required this.gender,
    required this.weight,
    required this.width,
    required this.length,
    required this.boxCode,
    required this.note,
  });
  final int line;
  final CrabGender gender;
  final double? weight;
  final double? width;
  final double? length;
  final String boxCode;
  final String note;
}

class BulkAddHeaderForm extends StatelessWidget {
  const BulkAddHeaderForm({
    super.key,
    required this.lots,
    required this.areas,
    required this.rows,
    required this.lot,
    required this.areaId,
    required this.rowId,
    required this.health,
    required this.type,
    required this.enteredAt,
    required this.boxesLoading,
    required this.rowCount,
    required this.onLot,
    required this.onArea,
    required this.onRow,
    required this.onHealth,
    required this.onType,
    required this.onDate,
  });

  final List<FarmingBatchRecord> lots;
  final List<AreaRecord> areas;
  final List<RowRecord> rows;
  final FarmingBatchRecord? lot;
  final String? areaId;
  final String? rowId;
  final CrabDisplayHealth health;
  final String type;
  final DateTime enteredAt;
  final bool boxesLoading;
  final int rowCount;
  final ValueChanged<String> onLot;
  final ValueChanged<String> onArea;
  final ValueChanged<String> onRow;
  final ValueChanged<CrabDisplayHealth> onHealth;
  final ValueChanged<String> onType;
  final VoidCallback onDate;

  @override
  Widget build(BuildContext context) {
    final remaining = lot?.remainingCount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _field(
              260,
              'Lô nhập',
              true,
              _Select<String>(
                valueLabel: lot == null ? 'Chọn lô nhập' : lot!.displayLabel,
                items: [for (final l in lots) (l.id, l.displayLabel)],
                onSelected: onLot,
              ),
            ),
            _field(
              260,
              'Khu vực',
              true,
              _Select<String>(
                valueLabel: () {
                  for (final a in areas) {
                    if (a.id == areaId) return '${a.areaCode} — ${a.areaName}';
                  }
                  return 'Chọn khu vực';
                }(),
                items: [for (final a in areas) (a.id, '${a.areaCode} — ${a.areaName}')],
                onSelected: onArea,
              ),
            ),
            _field(
              180,
              'Dãy',
              false,
              _Select<String>(
                valueLabel: () {
                  if (rowId == null) return 'Tất cả dãy';
                  for (final r in rows) {
                    if (r.id == rowId) return r.rowName.trim().isEmpty ? r.rowCode : r.rowName;
                  }
                  return boxesLoading ? 'Đang tải…' : 'Tất cả dãy';
                }(),
                loading: boxesLoading,
                items: [
                  ('', 'Tất cả dãy'),
                  for (final r in rows) (r.id, r.rowName.trim().isEmpty ? r.rowCode : r.rowName),
                ],
                onSelected: onRow,
              ),
            ),
            _field(
              170,
              'Sức khỏe mặc định',
              false,
              _Select<CrabDisplayHealth>(
                valueLabel: health.label,
                items: [for (final h in _kHealth) (h, h.label)],
                onSelected: onHealth,
              ),
            ),
            _field(
              150,
              'Loại cua',
              false,
              _Select<String>(
                valueLabel: type,
                items: [for (final t in _kTypes) (t, t)],
                onSelected: onType,
              ),
            ),
            _field(
              160,
              'Ngày nhập hộp',
              true,
              InkWell(
                onTap: onDate,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DashboardColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: DashboardColors.brand),
                      const SizedBox(width: 8),
                      Text(fmtDateVn(enteredAt), style: bvText(fontSize: 13, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Ngày cua được đưa vào hộp nuôi.', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        if (lot != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.mint),
            ),
            child: Wrap(
              spacing: 18,
              runSpacing: 6,
              children: [
                _chip('Tổng số lượng', '${lot!.initialQuantity} con'),
                _chip('Đã tạo cá thể', '${lot!.placedCount} con'),
                _chip('Còn lại', '${lot!.remainingCount} con'),
                Text(
                  'Đang chuẩn bị tạo $rowCount / $remaining cá thể còn lại.',
                  style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(double w, String label, bool req, Widget child) {
    return SizedBox(
      width: w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
              children: [
                if (req) TextSpan(text: ' *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.risk)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _chip(String k, String v) {
    return Text.rich(
      TextSpan(
        text: '$k: ',
        style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
        children: [TextSpan(text: v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))],
      ),
    );
  }
}

class BulkActionToolbar extends StatelessWidget {
  const BulkActionToolbar({
    super.key,
    required this.selected,
    required this.total,
    required this.importing,
    required this.onAdd,
    required this.onDuplicate,
    required this.onDelete,
    required this.onBulk,
    required this.onImport,
    required this.onTemplate,
  });

  final int selected;
  final int total;
  final bool importing;
  final VoidCallback onAdd;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final ValueChanged<String> onBulk;
  final VoidCallback onImport;
  final VoidCallback onTemplate;

  @override
  Widget build(BuildContext context) {
    final enabled = selected > 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _tool(Icons.add_rounded, 'Thêm dòng', onAdd),
        _tool(Icons.copy_all_outlined, 'Nhân bản dòng', enabled ? onDuplicate : null),
        _tool(Icons.delete_outline_rounded, 'Xóa dòng', enabled ? onDelete : null, color: DashboardColors.risk),
        PopupMenuButton<String>(
          enabled: enabled,
          tooltip: '',
          onSelected: onBulk,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'gender', child: Text('Đặt giới tính')),
            PopupMenuItem(value: 'health', child: Text('Đặt sức khỏe')),
            PopupMenuItem(value: 'date', child: Text('Đặt ngày nhập hộp')),
            PopupMenuItem(value: 'row', child: Text('Chọn dãy')),
            PopupMenuItem(value: 'auto', child: Text('Tự động phân hộp')),
            PopupMenuItem(value: 'clearNote', child: Text('Xóa ghi chú')),
          ],
          child: _tool(Icons.settings_outlined, 'Cập nhật hàng loạt', enabled ? () {} : null),
        ),
        _tool(Icons.table_view_outlined, importing ? 'Đang đọc…' : 'Import Excel', importing ? null : onImport),
        _tool(Icons.download_outlined, 'Tải file mẫu', onTemplate),
        const SizedBox(width: 8),
        Text('$total dòng', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
      ],
    );
  }

  Widget _tool(IconData icon, String label, VoidCallback? onTap, {Color? color}) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DashboardColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color ?? DashboardColors.brand),
              const SizedBox(width: 6),
              Text(label, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: color ?? DashboardColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class BulkCrabTable extends StatelessWidget {
  const BulkCrabTable({
    super.key,
    required this.rows,
    required this.boxes,
    required this.boxesLoading,
    required this.issueOf,
    required this.issueLabel,
    required this.onChanged,
    required this.onPickPhoto,
    required this.onPreviewPhoto,
  });

  final List<BulkRowData> rows;
  final List<BoxRecord> boxes;
  final bool boxesLoading;
  final BulkRowIssue Function(BulkRowData) issueOf;
  final String Function(BulkRowIssue) issueLabel;
  final VoidCallback onChanged;
  final Future<void> Function(BulkRowData) onPickPhoto;
  final Future<void> Function(String) onPreviewPhoto;

  @override
  Widget build(BuildContext context) {
    final all = rows.isNotEmpty && rows.every((r) => r.selected);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: DashboardColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1180),
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            columnSpacing: 8,
            headingTextStyle: bvText(fontSize: 10.5, fontWeight: FontWeight.w800, color: DashboardColors.textMuted, letterSpacing: 0.3),
            columns: [
              DataColumn(
                label: Checkbox(
                  value: all,
                  onChanged: (v) {
                    for (final r in rows) {
                      r.selected = v ?? false;
                    }
                    onChanged();
                  },
                ),
              ),
              const DataColumn(label: Text('STT')),
              const DataColumn(label: Text('MÃ CUA')),
              const DataColumn(label: Text('GIỚI TÍNH')),
              const DataColumn(label: Text('CÂN NẶNG (g)')),
              const DataColumn(label: Text('RỘNG MAI (mm)')),
              const DataColumn(label: Text('DÀI MAI (mm)')),
              const DataColumn(label: Text('HỘP')),
              const DataColumn(label: Text('GHI CHÚ')),
              const DataColumn(label: Text('ẢNH')),
              const DataColumn(label: Text('TRẠNG THÁI')),
            ],
            rows: [
              for (var i = 0; i < rows.length; i++) _row(i, rows[i]),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _row(int i, BulkRowData row) {
    final issue = issueOf(row);
    return DataRow(
      cells: [
        DataCell(Checkbox(value: row.selected, onChanged: (v) { row.selected = v ?? false; onChanged(); })),
        DataCell(Text('${i + 1}', style: bvText(color: DashboardColors.textPrimary))),
        DataCell(Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.code, style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
            Text('(Tự động tạo)', style: bvText(fontSize: 10.5, color: DashboardColors.textMuted)),
          ],
        )),
        DataCell(_Select<CrabGender>(
          dense: true,
          valueLabel: row.gender.label,
          items: [for (final g in CrabGender.values) (g, g.label)],
          onSelected: (v) { row.gender = v; onChanged(); },
        )),
        DataCell(_num(row.weight, '120', onChanged)),
        DataCell(_num(row.width, '65', onChanged)),
        DataCell(_num(row.length, '90', onChanged)),
        DataCell(SizedBox(
          width: 200,
          child: _Select<String>(
            dense: true,
            loading: boxesLoading,
            valueLabel: row.boxId == _kAutoBox
                ? 'Tự gán hộp trống'
                : boxes.where((b) => b.id == row.boxId).map(_boxOptionLabel).firstOrNull ?? 'Chọn hộp',
            items: [
              (_kAutoBox, 'Tự gán hộp trống'),
              for (final b in boxes)
                (b.id, _boxOptionLabel(b)),
            ],
            enabledOf: (id) {
              if (id == _kAutoBox) return true;
              for (final b in boxes) {
                if (b.id == id) return _boxSelectable(b);
              }
              return false;
            },
            onSelected: (v) { row.boxId = v; onChanged(); },
          ),
        )),
        DataCell(SizedBox(
          width: 130,
          child: TextField(
            controller: row.notes,
            maxLength: 255,
            onChanged: (_) => onChanged(),
            style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
            decoration: _deco('Tùy chọn').copyWith(counterText: ''),
          ),
        )),
        DataCell(_photo(row)),
        DataCell(_statusBadge(issue, issueLabel(issue))),
      ],
    );
  }

  Widget _photo(BulkRowData row) {
    final path = row.imagePath;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (path != null)
          GestureDetector(
            onTap: () => onPreviewPhoto(path),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(File(path), width: 32, height: 32, fit: BoxFit.cover),
            ),
          )
        else
          IconButton(
            tooltip: 'Upload ảnh',
            onPressed: () => onPickPhoto(row),
            icon: const Icon(Icons.photo_camera_outlined, size: 18, color: DashboardColors.brand),
          ),
        if (path != null)
          IconButton(
            tooltip: 'Xóa ảnh',
            onPressed: () { row.imagePath = null; onChanged(); },
            icon: Icon(Icons.close, size: 14, color: DashboardColors.textMuted),
          ),
      ],
    );
  }
}

class BulkSummary extends StatelessWidget {
  const BulkSummary({
    super.key,
    required this.creating,
    required this.valid,
    required this.auto,
    required this.emptyBoxes,
    required this.remaining,
  });

  final int creating;
  final int valid;
  final int auto;
  final int emptyBoxes;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    Widget cell(String k, String v) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
              Text(v, style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tóm tắt', style: bvText(fontSize: 13.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              cell('Số cua sẽ tạo', '$creating'),
              cell('Dòng hợp lệ', '$valid / $creating'),
              cell('Chọn hộp tự động', '$auto'),
              cell('Hộp trống khả dụng', '$emptyBoxes'),
              cell('Còn lại trong lô', '$remaining'),
            ],
          ),
        ],
      ),
    );
  }
}

class BulkRulesPanel extends StatelessWidget {
  const BulkRulesPanel({super.key, required this.lot});
  final FarmingBatchRecord? lot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: mgmtCardDeco(radius: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.inventory_2_outlined, size: 16, color: DashboardColors.brand),
                const SizedBox(width: 6),
                Text('Thông tin lô nhập', style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              ]),
              const SizedBox(height: 10),
              if (lot == null)
                Text('Chưa chọn lô.', style: bvText(color: DashboardColors.textMuted))
              else ...[
                _kv('Mã lô', lot!.batchCode),
                _kv('Tên lô', lot!.lotName),
                _kv('Ngày nhập', fmtDateVn(lot!.startDate)),
                _kv('Tổng số lượng', '${lot!.initialQuantity} con'),
                _kv('Đã tạo cá thể', '${lot!.placedCount} con'),
                _kv('Còn lại', '${lot!.remainingCount} con'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: mgmtCardDeco(radius: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2495E8)),
                const SizedBox(width: 6),
                Text('Quy tắc & Lưu ý', style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              ]),
              const SizedBox(height: 8),
              _b('Chỉ chọn hộp đang hoạt động và chưa có cua.'),
              _b('Mỗi hộp chỉ chứa 1 cua.'),
              _b('Mã cua do hệ thống tự tạo.'),
              _b('Cân nặng và kích thước nhập theo gram (g) và millimet (mm).'),
              _b('Sau khi lưu, thông tin sẽ xuất hiện trong Lịch sử & Nhật ký.'),
              _b('Nếu import Excel, vui lòng dùng file mẫu.'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: mgmtCardDeco(radius: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hướng dẫn nhanh', style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              const SizedBox(height: 8),
              _n(1, 'Chọn lô nhập và kiểm tra số lượng còn lại.'),
              _n(2, 'Thêm các dòng cua.'),
              _n(3, 'Nhập thông tin từng cá thể.'),
              _n(4, 'Chọn hộp tự động hoặc thủ công.'),
              _n(5, 'Kiểm tra trạng thái hợp lệ.'),
              _n(6, 'Nhấn “Lưu tất cả”.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 96, child: Text(k, style: bvText(fontSize: 12, color: DashboardColors.textMuted))),
            Expanded(child: Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary))),
          ],
        ),
      );

  Widget _b(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text('•  $t', style: bvText(fontSize: 12, height: 1.35, color: DashboardColors.textMuted)),
      );

  Widget _n(int i, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text('$i. $t', style: bvText(fontSize: 12, height: 1.35, color: DashboardColors.textMuted)),
      );
}

class _Select<T> extends StatelessWidget {
  const _Select({
    required this.valueLabel,
    required this.items,
    required this.onSelected,
    this.loading = false,
    this.dense = false,
    this.enabledOf,
  });

  final String valueLabel;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;
  final bool loading;
  final bool dense;
  final bool Function(T value)? enabledOf;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: '',
      enabled: !loading && items.isNotEmpty,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.$1,
            enabled: enabledOf?.call(item.$1) ?? true,
            height: 36,
            child: Text(
              item.$2,
              style: bvText(
                fontSize: 12.5,
                color: (enabledOf?.call(item.$1) ?? true) ? DashboardColors.textPrimary : DashboardColors.textMuted,
              ),
            ),
          ),
      ],
      child: Container(
        height: dense ? 36 : 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(valueLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
            ),
            if (loading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: DashboardColors.textMuted),
          ],
        ),
      ),
    );
  }
}

Widget _num(TextEditingController c, String hint, VoidCallback onChanged) {
  return SizedBox(
    width: 78,
    child: TextField(
      controller: c,
      onChanged: (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
      decoration: _deco(hint),
    ),
  );
}

InputDecoration _deco(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      hintStyle: bvText(fontSize: 12, color: DashboardColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DashboardColors.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DashboardColors.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: DashboardColors.brand, width: 1.3)),
    );

Widget _statusBadge(BulkRowIssue issue, [String? label]) {
  final ok = issue == BulkRowIssue.none;
  final color = ok ? DashboardColors.brand : const Color(0xFFF5B700);
  return MgmtStatusBadge(label: label ?? (ok ? 'Hợp lệ' : 'Cần kiểm tra'), color: color);
}

class _EscIntent extends Intent {
  const _EscIntent();
}
