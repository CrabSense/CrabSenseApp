import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../services/area_management_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showAreaFormDialog(
  BuildContext context,
  AreaManagementService svc, {
  AreaRecord? existing,
}) async {
  var preview = 'K-…';
  if (existing == null) {
    try {
      preview = await svc.fetchNextAreaCode();
    } catch (_) {}
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _AreaFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.areaCode ?? preview,
    ),
  );
}

class _AreaFormDialog extends StatefulWidget {
  const _AreaFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });

  final AreaManagementService svc;
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
  late String _status;
  var _saving = false;
  var _activeNow = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.areaName ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _status = e?.status ?? 'active';
    _activeNow = _status == 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  String get _effectiveStatus {
    if (widget.isCreate) {
      return _activeNow ? 'active' : 'disabled';
    }
    return _status;
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSans(
          color: DashboardColors.textMuted.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        filled: true,
        fillColor: DashboardColors.darkNavy,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardColors.purple, width: 1.2),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final status = _effectiveStatus;
      if (widget.isCreate) {
        await widget.svc.createArea(
          areaName: _name.text.trim(),
          description:
              _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          status: status,
        );
      } else {
        await widget.svc.updateArea(
          widget.existing!,
          areaName: _name.text.trim(),
          description:
              _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          status: status,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.isCreate ? 'Đã thêm khu' : 'Đã cập nhật khu'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.isCreate;
    return Dialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCreate ? 'Thêm Khu Mới' : 'Cập nhật Khu',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isCreate
                              ? 'Thiết lập thông tin khu vực nuôi mới trong hệ thống.'
                              : 'Chỉnh sửa thông tin khu ${widget.existing!.areaCode}.',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: DashboardColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, c) {
                          final twoCol = c.maxWidth > 420;
                          final codeField = _LabeledField(
                            label: 'MÃ KHU',
                            child: TextFormField(
                              readOnly: true,
                              initialValue: widget.autoCode,
                              decoration: _fieldDecoration(
                                hint: 'VD: K-01',
                                suffixIcon: Icon(
                                  Icons.fingerprint,
                                  color: DashboardColors.textMuted
                                      .withValues(alpha: 0.6),
                                  size: 22,
                                ),
                              ),
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.cyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                          final nameField = _LabeledField(
                            label: 'TÊN KHU',
                            child: TextFormField(
                              controller: _name,
                              decoration: _fieldDecoration(
                                hint: 'VD: Bể Ươm 1',
                                suffixIcon: Icon(
                                  Icons.sell_outlined,
                                  color: DashboardColors.textMuted
                                      .withValues(alpha: 0.6),
                                  size: 20,
                                ),
                              ),
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.textPrimary,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Nhập tên khu'
                                  : null,
                            ),
                          );
                          if (!twoCol) {
                            return Column(
                              children: [
                                codeField,
                                const SizedBox(height: 16),
                                nameField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: codeField),
                              const SizedBox(width: 16),
                              Expanded(child: nameField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'MÔ TẢ CHI TIẾT',
                        child: TextFormField(
                          controller: _desc,
                          maxLines: 4,
                          minLines: 3,
                          decoration: _fieldDecoration(
                            hint:
                                'Nhập mô tả vị trí hoặc mục đích sử dụng...',
                          ),
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isCreate) _buildActiveToggle() else _buildEditStatus(),
                      const SizedBox(height: 16),
                      _IllustrationPreview(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text(
                      'Hủy bỏ',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _GradientSaveButton(
                    saving: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DashboardColors.seaGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: DashboardColors.seaGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạng thái hoạt động',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Kích hoạt khu vực ngay lập tức',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _activeNow,
            onChanged: _saving
                ? null
                : (v) => setState(() => _activeNow = v),
            activeTrackColor: DashboardColors.purple.withValues(alpha: 0.5),
            activeThumbColor: DashboardColors.purple,
            inactiveThumbColor: DashboardColors.textMuted,
            inactiveTrackColor: DashboardColors.cardBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildEditStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRẠNG THÁI',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in [
                ('active', 'Hoạt động'),
                ('maintenance', 'Bảo trì'),
                ('disabled', 'Ngưng sử dụng'),
              ])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: _status == entry.$1,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() {
                            _status = entry.$1;
                            _activeNow = entry.$1 == 'active';
                          }),
                  selectedColor:
                      DashboardColors.purple.withValues(alpha: 0.25),
                  labelStyle: GoogleFonts.notoSans(
                    color: _status == entry.$1
                        ? DashboardColors.purple
                        : DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: _status == entry.$1
                        ? DashboardColors.purple
                        : DashboardColors.cardBorder,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _IllustrationPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DashboardColors.darkNavy,
                  DashboardColors.purple.withValues(alpha: 0.2),
                  DashboardColors.oceanBlue.withValues(alpha: 0.15),
                ],
              ),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 48,
                    color: DashboardColors.cyan.withValues(alpha: 0.25),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: DashboardColors.seaGreen.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              'Hình ảnh minh họa khu vực nuôi',
              style: GoogleFonts.notoSans(
                color: DashboardColors.seaGreen,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GradientSaveButton extends StatelessWidget {
  const _GradientSaveButton({
    required this.saving,
    required this.onPressed,
  });

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DashboardColors.accentGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.purple.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: saving ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Lưu thông tin',
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
