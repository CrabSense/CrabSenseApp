import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_record.dart';
import '../../services/farm_management_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showCreateFarmDialog(
  BuildContext context,
  FarmManagementService service,
) async {
  String previewCode = 'FR-…';
  try {
    previewCode = await service.fetchNextCode();
  } catch (_) {}

  await showDialog<void>(
    context: context,
    builder: (ctx) => _FarmFormDialog(
      title: 'Thêm trại mới',
      autoCode: previewCode,
      isCreate: true,
      onSubmit: (name, address, description) => service.create(
        name: name,
        address: address,
        description: description,
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
      title: 'Sửa trại',
      autoCode: farm.code,
      isCreate: false,
      initialName: farm.name,
      initialAddress: farm.address,
      initialDescription: farm.description,
      onSubmit: (name, address, description) => service.update(
        farm,
        name: name,
        address: address,
        description: description,
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
        'Xóa trại?',
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
        const SnackBar(content: Text('Đã xóa trại')),
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

class _FarmFormDialog extends StatefulWidget {
  const _FarmFormDialog({
    required this.title,
    required this.autoCode,
    required this.isCreate,
    required this.onSubmit,
    this.initialName,
    this.initialAddress,
    this.initialDescription,
  });

  final String title;
  final String autoCode;
  final bool isCreate;
  final String? initialName;
  final String? initialAddress;
  final String? initialDescription;
  final Future<dynamic> Function(
    String name,
    String? address,
    String? description,
  ) onSubmit;

  @override
  State<_FarmFormDialog> createState() => _FarmFormDialogState();
}

class _FarmFormDialogState extends State<_FarmFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _descCtrl;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _addressCtrl = TextEditingController(text: widget.initialAddress ?? '');
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        _nameCtrl.text.trim(),
        _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isCreate ? 'Đã thêm trại' : 'Đã cập nhật trại',
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
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _autoCodeBanner(widget.autoCode, isCreate: widget.isCreate),
                _field(_nameCtrl, 'Tên trại *', required: true),
                _field(_addressCtrl, 'Địa chỉ', maxLines: 2),
                _field(_descCtrl, 'Mô tả', maxLines: 3),
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
}

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
        Icon(Icons.tag_outlined, size: 20, color: DashboardColors.cyan),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCreate ? 'Mã trại (tự động)' : 'Mã trại',
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
  int maxLines = 1,
  bool required = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null
          : null,
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
