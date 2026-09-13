import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../services/cloud_api_client.dart';
import '../../services/production_management_service.dart';
import '../../theme/dashboard_theme.dart';

export '../box/box_form_dialog.dart' show showBoxFormDialog;

Future<void> showAreaFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  AreaRecord? existing,
}) async {
  var preview = 'K-…';
  if (existing == null) {
    try {
      preview = await svc.fetchNextAreaCode();
    } catch (_) {}
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _AreaFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.areaCode ?? preview,
    ),
  );
}

Future<void> showRowFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  RowRecord? existing,
}) async {
  var preview = 'D-…';
  if (existing == null && svc.selectedAreaId != null) {
    try {
      preview = await svc.fetchNextRowCode();
    } catch (_) {}
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _RowFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.rowCode ?? preview,
    ),
  );
}

Future<void> showBatchFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  FarmingBatchRecord? existing,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _BatchFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.batchCode ?? 'BT-… (theo dãy)',
    ),
  );
}

Future<void> showCrabFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  BatchCrabRecord? existing,
}) async {
  var preview = 'C-…';
  if (existing == null && svc.selectedBatchId != null) {
    try {
      preview = await svc.fetchNextCrabCode();
    } catch (_) {}
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _CrabFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.crabCode ?? preview,
    ),
  );
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(title, style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: Text(message, style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.risk),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Xoá khu, tự xử lý bước "khu còn dữ liệu".
///
/// BE chặn 409 khi khu còn dãy. Lúc đó hỏi lại người dùng, đồng ý thì gọi
/// lại kèm cascade=true để xoá luôn dãy/hộp/cua.
/// Hiện snackbar kết quả hoặc lỗi. Trả về true nếu đã xoá.
Future<bool> deleteAreaFlow(
  BuildContext context, {
  required String areaName,
  required Future<void> Function({bool cascade}) remove,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void snack(String message) =>
      messenger.showSnackBar(SnackBar(content: Text(message)));

  try {
    await remove(cascade: false);
    snack('Đã xóa khu $areaName');
    return true;
  } on CloudApiException catch (e) {
    if (e.statusCode != 409) {
      snack(e.message);
      return false;
    }
  } catch (e) {
    snack('$e');
    return false;
  }

  if (!context.mounted) return false;
  final force = await confirmDelete(
    context,
    title: 'Khu $areaName vẫn còn dữ liệu',
    message: 'Xóa khu sẽ xóa luôn toàn bộ dãy, hộp và cua bên trong.\n\n'
        'Không khôi phục được.',
  );
  if (!force) return false;

  try {
    await remove(cascade: true);
    snack('Đã xóa khu $areaName và toàn bộ dữ liệu bên trong');
    return true;
  } catch (e) {
    snack('$e');
    return false;
  }
}

class _AreaFormDialog extends StatefulWidget {
  const _AreaFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });
  final ProductionManagementService svc;
  final AreaRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<_AreaFormDialog> createState() => _AreaFormDialogState();
}

class _AreaFormDialogState extends State<_AreaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.areaName ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.isCreate) {
        await widget.svc.createArea(
          areaName: _name.text.trim(),
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        );
      } else {
        await widget.svc.updateArea(widget.existing!,
            areaCode: widget.existing!.areaCode,
            areaName: _name.text.trim(),
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim());
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu khu')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(widget.isCreate ? 'Thêm khu' : 'Sửa khu',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _codeBanner(widget.autoCode, isCreate: widget.isCreate, label: 'khu'),
              _tf(_name, 'Tên khu *', required: true),
              _tf(_desc, 'Mô tả', maxLines: 2),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _saving, _save),
    );
  }
}

class _RowFormDialog extends StatefulWidget {
  const _RowFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });
  final ProductionManagementService svc;
  final RowRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<_RowFormDialog> createState() => _RowFormDialogState();
}

class _RowFormDialogState extends State<_RowFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.rowName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.isCreate) {
        await widget.svc.createRow(rowName: _name.text.trim());
      } else {
        await widget.svc.updateRow(widget.existing!,
            rowName: _name.text.trim());
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu dãy')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(widget.isCreate ? 'Thêm dãy' : 'Sửa dãy',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _codeBanner(widget.autoCode, isCreate: widget.isCreate, label: 'dãy'),
              _tf(_name, 'Tên dãy *', required: true),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _saving, _save),
    );
  }
}

class _BatchFormDialog extends StatefulWidget {
  const _BatchFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });
  final ProductionManagementService svc;
  final FarmingBatchRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<_BatchFormDialog> createState() => _BatchFormDialogState();
}

class _BatchFormDialogState extends State<_BatchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qty;
  late final TextEditingController _cur;
  late DateTime _start;
  late DateTime _expected;
  DateTime? _actual;
  late String _status;
  var _startNow = true;
  var _saving = false;
  late Set<String> _selectedBoxIds;

  static const _statuses = ['active', 'harvested', 'failed'];
  static const _statusLabels = {
    'active': 'Đang nuôi (active)',
    'harvested': 'Đã thu hoạch',
    'failed': 'Thất bại',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _qty = TextEditingController(text: '${e?.initialQuantity ?? 0}');
    _cur = TextEditingController(text: '${e?.currentQuantity ?? 0}');
    final today = DateTime.now();
    _start = e?.startDate ?? DateTime(today.year, today.month, today.day);
    _expected = e?.expectedHarvestDate ??
        DateTime(today.year, today.month, today.day).add(const Duration(days: 60));
    _actual = e?.actualHarvestDate;
    _status = e?.status ?? 'active';
    _startNow = e == null;
    _selectedBoxIds = e != null
        ? {e.boxId}
        : widget.svc.boxes
            .where((b) => b.status == 'empty')
            .map((b) => b.id)
            .toSet();
  }

  @override
  void dispose() {
    _qty.dispose();
    _cur.dispose();
    super.dispose();
  }

  Future<void> _pickDate(_BatchDateField field) async {
    final initial = switch (field) {
      _BatchDateField.start => _start,
      _BatchDateField.expected => _expected,
      _BatchDateField.actual => _actual ?? DateTime.now(),
    };
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      switch (field) {
        case _BatchDateField.start:
          _start = picked;
          if (_expected.isBefore(_start)) {
            _expected = _start.add(const Duration(days: 30));
          }
        case _BatchDateField.expected:
          _expected = picked;
        case _BatchDateField.actual:
          _actual = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.isCreate && _selectedBoxIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất một hộp nuôi')),
      );
      return;
    }
    if (_expected.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu')),
      );
      return;
    }
    setState(() => _saving = true);
    final iq = int.tryParse(_qty.text.trim()) ?? 0;
    final cq = int.tryParse(_cur.text.trim()) ?? iq;
    final startNow = widget.isCreate
        ? _startNow
        : (_status == 'active' && _startNow);
    try {
      if (widget.isCreate) {
        final created = await widget.svc.createBatches(
          boxIds: _selectedBoxIds.toList(),
          startDate: _start,
          expectedHarvestDate: _expected,
          initialQuantity: iq,
          startNow: startNow,
          status: _status,
        );
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              created.length == 1
                  ? 'Đã tạo đợt ${created.first.batchCode} — hộp ${created.first.boxCode ?? ''}'
                  : 'Đã tạo ${created.length} đợt nuôi',
            ),
          ),
        );
        return;
      } else {
        await widget.svc.updateBatch(
          widget.existing!,
          startDate: _start,
          expectedHarvestDate: _expected,
          actualHarvestDate: _actual,
          initialQuantity: iq,
          currentQuantity: cq,
          status: _status,
          startNow: startNow,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu đợt nuôi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(widget.isCreate ? 'Thêm đợt nuôi' : 'Sửa đợt nuôi',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _codeBanner(widget.autoCode, isCreate: widget.isCreate, label: 'đợt'),
                if (widget.isCreate) ...[
                  Text(
                    'Chọn hộp nuôi (${_selectedBoxIds.length}/${widget.svc.boxes.length})',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView(
                      shrinkWrap: true,
                      children: widget.svc.boxes.map((box) {
                        final checked = _selectedBoxIds.contains(box.id);
                        return CheckboxListTile(
                          dense: true,
                          value: checked,
                          title: Text(
                            '${box.boxCode} (${box.status})',
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedBoxIds.add(box.id);
                              } else {
                                _selectedBoxIds.remove(box.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _dateTile('Ngày bắt đầu *', _start, () => _pickDate(_BatchDateField.start)),
                _dateTile(
                  'Ngày kết thúc (dự kiến thu hoạch) *',
                  _expected,
                  () => _pickDate(_BatchDateField.expected),
                ),
                if (!widget.isCreate)
                  _dateTile(
                    'Ngày thu hoạch thực tế',
                    _actual,
                    () => _pickDate(_BatchDateField.actual),
                    optional: true,
                  ),
                _tf(_qty, 'Số lượng ban đầu *', required: true),
                if (!widget.isCreate) _tf(_cur, 'Số lượng hiện tại *', required: true),
                _statusDropdown(),
                if (widget.isCreate || _status == 'active')
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Bắt đầu nuôi ngay',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Gán ngày bắt đầu và chuyển hộp sang trạng thái farming',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    value: _startNow,
                    onChanged: (v) => setState(() => _startNow = v),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: _dialogActions(context, _saving, _save),
    );
  }

  Widget _statusDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _status,
        dropdownColor: DashboardColors.card,
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
        decoration: InputDecoration(
          labelText: 'Trạng thái',
          labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
          filled: true,
          fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DashboardColors.cardBorder),
          ),
        ),
        items: _statuses
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(_statusLabels[s] ?? s),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _status = v);
        },
      ),
    );
  }

  Widget _dateTile(
    String label,
    DateTime? date,
    VoidCallback onPick, {
    bool optional = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
      ),
      subtitle: Text(
        date == null ? (optional ? '—' : 'Chưa chọn') : _fmt(date),
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      ),
      trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: onPick),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

enum _BatchDateField { start, expected, actual }

class _CrabFormDialog extends StatefulWidget {
  const _CrabFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });
  final ProductionManagementService svc;
  final BatchCrabRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<_CrabFormDialog> createState() => _CrabFormDialogState();
}

class _CrabFormDialogState extends State<_CrabFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _shell;
  late String _gender;
  late String _status;
  var _saving = false;

  static const _genders = ['unknown', 'male', 'female'];
  static const _statuses = ['alive', 'dead', 'molting', 'harvested'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _weight = TextEditingController(text: e?.weight?.toString() ?? '');
    _shell = TextEditingController(text: e?.shellWidth?.toString() ?? '');
    _gender = e?.gender ?? 'unknown';
    _status = e?.status ?? 'alive';
  }

  @override
  void dispose() {
    _weight.dispose();
    _shell.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final w = double.tryParse(_weight.text.trim());
    final s = double.tryParse(_shell.text.trim());
    try {
      if (widget.isCreate) {
        await widget.svc.createCrab(
          gender: _gender,
          weight: w,
          shellWidth: s,
          status: _status,
        );
      } else {
        await widget.svc.updateCrab(widget.existing!,
            crabCode: widget.existing!.crabCode,
            gender: _gender,
            weight: w,
            shellWidth: s,
            status: _status);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu cua')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(widget.isCreate ? 'Thêm cua' : 'Sửa cua',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _codeBanner(widget.autoCode, isCreate: widget.isCreate, label: 'cua'),
              _dropdown('Giới tính', _gender, _genders, (v) => setState(() => _gender = v)),
              _tf(_weight, 'Cân nặng (g)'),
              _tf(_shell, 'Bề ngang mai (cm)'),
              _dropdown('Trạng thái', _status, _statuses, (v) => setState(() => _status = v)),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _saving, _save),
    );
  }
}

Widget _codeBanner(String code, {required bool isCreate, required String label}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: DashboardColors.cyan.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DashboardColors.cardBorder),
    ),
    child: Row(
      children: [
        Icon(Icons.tag_outlined, size: 20, color: DashboardColors.cyan),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCreate ? 'Mã $label (tự động)' : 'Mã $label',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                ),
              ),
              Text(
                code,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

List<Widget> _dialogActions(BuildContext context, bool saving, VoidCallback onSave) => [
      TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Hủy')),
      FilledButton(
        onPressed: saving ? null : onSave,
        style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
        child: saving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Lưu'),
      ),
    ];

Widget _tf(
  TextEditingController c,
  String label, {
  bool required = false,
  int maxLines = 1,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null
              : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      ),
    ),
  );
}

Widget _dropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: value,
      dropdownColor: DashboardColors.card,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}
