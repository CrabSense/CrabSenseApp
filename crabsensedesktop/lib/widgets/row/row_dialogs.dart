import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_record.dart';
import '../../models/production_models.dart';
import '../../models/row_list_item.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showCreateRowDialog(
  BuildContext context,
  RowManagementService service, {
  required String areaId,
}) async {
  var preview = 'DAY-A01';
  try {
    preview = await service.fetchNextCode();
  } catch (_) {}
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _RowFormDialog(
      title: 'Thêm dãy mới',
      autoCode: preview,
      isCreate: true,
      areas: service.areas,
      initialAreaId: areaId,
      onSubmit: (input) => service.create(
        areaId: input.areaId,
        name: input.name,
        location: input.location,
        capacity: input.capacity,
        description: input.description,
        status: input.status,
      ),
    ),
  );
}

Future<void> showEditRowDialog(
  BuildContext context,
  RowManagementService service,
  RowListItem item,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _RowFormDialog(
      title: 'Sửa dãy',
      autoCode: item.rowCode,
      isCreate: false,
      areas: service.areas,
      initialAreaId: item.areaId,
      initial: item.row,
      onSubmit: (input) => service.update(
        item.row,
        name: input.name,
        location: input.location,
        capacity: input.capacity,
        description: input.description,
        status: input.status,
      ),
    ),
  );
}

class _RowFormInput {
  const _RowFormInput({
    required this.areaId,
    required this.name,
    this.location,
    this.capacity = 0,
    this.description,
    this.status = FarmStatus.active,
  });

  final String areaId;
  final String name;
  final String? location;
  final int capacity;
  final String? description;
  final FarmStatus status;
}

class _RowFormDialog extends StatefulWidget {
  const _RowFormDialog({
    required this.title,
    required this.autoCode,
    required this.isCreate,
    required this.areas,
    required this.initialAreaId,
    required this.onSubmit,
    this.initial,
  });

  final String title;
  final String autoCode;
  final bool isCreate;
  final List<AreaRecord> areas;
  final String initialAreaId;
  final RowRecord? initial;
  final Future<dynamic> Function(_RowFormInput input) onSubmit;

  @override
  State<_RowFormDialog> createState() => _RowFormDialogState();
}

class _RowFormDialogState extends State<_RowFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _descCtrl;
  late String _areaId;
  late FarmStatus _status;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final row = widget.initial;
    _nameCtrl = TextEditingController(text: row?.rowName ?? '');
    _locationCtrl = TextEditingController(text: row?.location ?? '');
    _capacityCtrl = TextEditingController(
      text: row == null || row.capacity == 0 ? '' : '${row.capacity}',
    );
    _descCtrl = TextEditingController(text: row?.description ?? '');
    _areaId = widget.initialAreaId;
    _status = row?.status ?? FarmStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _capacityCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final capText = _capacityCtrl.text.trim();
      await widget.onSubmit(
        _RowFormInput(
          areaId: _areaId,
          name: _nameCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          capacity: capText.isEmpty ? 0 : int.parse(capText),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          status: _status,
        ),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.isCreate ? 'Đã thêm dãy' : 'Đã cập nhật dãy'),
        ),
      );
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _codeBanner(widget.autoCode, isCreate: widget.isCreate),
                _areaField(),
                _field(_nameCtrl, 'Tên dãy *', hint: 'Ví dụ: Dãy A', required: true),
                _field(_locationCtrl, 'Vị trí', hint: 'Ví dụ: Bên trái'),
                _field(
                  _capacityCtrl,
                  'Sức chứa tối đa (số hộp)',
                  hint: 'Ví dụ: 20 — để trống = không giới hạn',
                  keyboard: TextInputType.number,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final n = int.tryParse(t);
                    if (n == null || n < 0) return 'Nhập số ≥ 0';
                    return null;
                  },
                ),
                _field(_descCtrl, 'Mô tả', hint: 'Ví dụ: Dãy nuôi cua lột', maxLines: 2),
                _statusField(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }

  Widget _areaField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Khu thuộc về *',
          labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
          filled: true,
          fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DashboardColors.cardBorder),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.areas.any((a) => a.id == _areaId) ? _areaId : null,
            isExpanded: true,
            dropdownColor: DashboardColors.card,
            style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
            items: [
              for (final a in widget.areas)
                DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.areaCode} — ${a.areaName}'),
                ),
            ],
            onChanged: widget.isCreate
                ? (v) {
                    if (v != null) setState(() => _areaId = v);
                  }
                : null,
          ),
        ),
      ),
    );
  }

  Widget _statusField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Trạng thái *',
          labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
          filled: true,
          fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DashboardColors.cardBorder),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<FarmStatus>(
            value: _status,
            isExpanded: true,
            dropdownColor: DashboardColors.card,
            style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
            items: FarmStatus.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text('${s.emoji}  ${s.label}'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
          ),
        ),
      ),
    );
  }
}

Widget _codeBanner(String code, {required bool isCreate}) {
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
        const Icon(Icons.lock_outline, size: 20, color: DashboardColors.cyan),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCreate ? 'Mã dãy (hệ thống tự tạo)' : 'Mã dãy',
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

Widget _field(
  TextEditingController ctrl,
  String label, {
  String? hint,
  int maxLines = 1,
  bool required = false,
  TextInputType? keyboard,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null
              : null),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.notoSans(
          color: DashboardColors.textMuted,
          fontSize: 13,
        ),
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
