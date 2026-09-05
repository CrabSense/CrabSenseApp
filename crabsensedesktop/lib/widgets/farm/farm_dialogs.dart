import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_record.dart';
import '../../services/farm_management_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showCreateFarmDialog(
  BuildContext context,
  FarmManagementService service,
) async {
  String previewCode = 'AREA-A01';
  try {
    previewCode = await service.fetchNextCode();
  } catch (_) {}

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _FarmFormDialog(
      title: 'Thêm khu mới',
      autoCode: previewCode,
      isCreate: true,
      onSubmit: (input) => service.create(
        name: input.name,
        location: input.location,
        areaSquareMeters: input.areaSquareMeters,
        description: input.description,
        status: input.status,
      ),
    ),
  );
}

Future<void> showEditFarmDialog(
  BuildContext context,
  FarmManagementService service,
  FarmRecord farm,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _FarmFormDialog(
      title: 'Sửa khu',
      autoCode: farm.code,
      isCreate: false,
      initial: farm,
      onSubmit: (input) => service.update(
        farm,
        name: input.name,
        location: input.location,
        areaSquareMeters: input.areaSquareMeters,
        description: input.description,
        status: input.status,
      ),
    ),
  );
}

Future<void> showDeleteFarmDialog(
  BuildContext context,
  FarmManagementService service,
  FarmRecord farm,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Xóa khu?',
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      ),
      content: Text(
        'Xóa "${farm.name}" (${farm.code})? Hành động không hoàn tác.',
        style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.risk),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  try {
    await service.delete(farm);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa khu')),
      );
    }
  } on Exception catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}

class _FarmFormInput {
  const _FarmFormInput({
    required this.name,
    this.location,
    this.areaSquareMeters,
    this.description,
    this.status = FarmStatus.active,
  });

  final String name;
  final String? location;
  final double? areaSquareMeters;
  final String? description;
  final FarmStatus status;
}

class _FarmFormDialog extends StatefulWidget {
  const _FarmFormDialog({
    required this.title,
    required this.autoCode,
    required this.isCreate,
    required this.onSubmit,
    this.initial,
  });

  final String title;
  final String autoCode;
  final bool isCreate;
  final FarmRecord? initial;
  final Future<dynamic> Function(_FarmFormInput input) onSubmit;

  @override
  State<_FarmFormDialog> createState() => _FarmFormDialogState();
}

class _FarmFormDialogState extends State<_FarmFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _descCtrl;
  late FarmStatus _status;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final farm = widget.initial;
    _nameCtrl = TextEditingController(text: farm?.name ?? '');
    _locationCtrl = TextEditingController(text: farm?.location ?? '');
    _areaCtrl = TextEditingController(
      text: farm?.areaSquareMeters == null
          ? ''
          : farm!.areaSquareMeters!.toString(),
    );
    _descCtrl = TextEditingController(text: farm?.description ?? '');
    _status = farm?.status ?? FarmStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _areaCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final areaText = _areaCtrl.text.trim();
      await widget.onSubmit(
        _FarmFormInput(
          name: _nameCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          areaSquareMeters: areaText.isEmpty ? null : double.parse(areaText),
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
          content: Text(
            widget.isCreate ? 'Đã thêm khu' : 'Đã cập nhật khu',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
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
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _autoCodeBanner(widget.autoCode, isCreate: widget.isCreate),
                _field(_nameCtrl, 'Tên khu *', hint: 'Ví dụ: Khu nuôi nhà 1', required: true),
                _field(
                  _locationCtrl,
                  'Vị trí',
                  hint: 'Ví dụ: Nhà nuôi số 1 - Tầng 1',
                ),
                _field(
                  _areaCtrl,
                  'Diện tích (m²)',
                  hint: 'Ví dụ: 100',
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final n = double.tryParse(t);
                    if (n == null || n < 0) return 'Nhập số ≥ 0';
                    return null;
                  },
                ),
                _field(_descCtrl, 'Mô tả', hint: 'Giới thiệu ngắn về khu', maxLines: 3),
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
                    child: Text('${_statusDot(s)}  ${s.label}'),
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

String _statusDot(FarmStatus status) => switch (status) {
      FarmStatus.active => '🟢',
      FarmStatus.suspended => '🟡',
      FarmStatus.closed => '🔴',
    };

Widget _autoCodeBanner(String code, {required bool isCreate}) {
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
                isCreate ? 'Mã khu (hệ thống tự tạo)' : 'Mã khu',
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
        hintStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
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
