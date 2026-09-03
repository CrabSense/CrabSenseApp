import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../services/production_management_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showBoxFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  BoxRecord? existing,
}) async {
  if (svc.areas.isEmpty) {
    await svc.loadAreas();
  }
  var preview = 'H-…';
  if (existing == null) {
    final rowId = svc.selectedRowId;
    if (rowId != null) {
      try {
        preview = await svc.fetchNextBoxCode();
      } catch (_) {}
    }
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => BoxFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.boxCode ?? preview,
    ),
  );
}

class BoxFormDialog extends StatefulWidget {
  const BoxFormDialog({
    super.key,
    required this.svc,
    required this.autoCode,
    this.existing,
  });

  final ProductionManagementService svc;
  final BoxRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<BoxFormDialog> createState() => _BoxFormDialogState();
}

class _BoxFormDialogState extends State<BoxFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _count;
  late final TextEditingController _position;
  late final TextEditingController _volume;
  late final TextEditingController _desc;

  String? _areaId;
  String? _rowId;
  List<RowRecord> _rows = [];
  late String _autoCode;
  late String _status;
  var _activeNow = false;
  var _saving = false;
  var _loadingRows = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _autoCode = widget.autoCode;
    _count = TextEditingController(text: '1');
    _position = TextEditingController(text: e?.position ?? '');
    _volume = TextEditingController(text: e?.volume?.toString() ?? '');
    _desc = TextEditingController();
    _status = e?.status ?? 'empty';
    _activeNow = _status == 'farming' || _status == 'active';

    _areaId = widget.svc.selectedAreaId;
    _rowId = widget.svc.selectedRowId ?? e?.rowId;
    if (_areaId != null) {
      _rows = List.from(widget.svc.rows);
      if (_rows.isEmpty) {
        _loadRows(_areaId!);
      }
    }
    if (widget.isCreate && _rowId != null) {
      _refreshCode();
    }
  }

  @override
  void dispose() {
    _count.dispose();
    _position.dispose();
    _volume.dispose();
    _desc.dispose();
    super.dispose();
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

  Future<void> _loadRows(String areaId) async {
    setState(() => _loadingRows = true);
    widget.svc.selectArea(areaId);
    await widget.svc.loadRows();
    if (!mounted) return;
    setState(() {
      _rows = List.from(widget.svc.rows);
      _loadingRows = false;
      if (_rowId != null && !_rows.any((r) => r.id == _rowId)) {
        _rowId = _rows.isNotEmpty ? _rows.first.id : null;
      }
    });
    if (widget.isCreate) await _refreshCode();
  }

  Future<void> _onAreaChanged(String? areaId) async {
    setState(() {
      _areaId = areaId;
      _rowId = null;
      _rows = [];
    });
    if (areaId == null) return;
    await _loadRows(areaId);
  }

  Future<void> _onRowChanged(String? rowId) async {
    setState(() => _rowId = rowId);
    if (rowId != null) {
      widget.svc.selectRow(rowId);
      if (widget.isCreate) await _refreshCode();
    }
  }

  Future<void> _refreshCode() async {
    try {
      final code = await widget.svc.fetchNextBoxCode();
      if (mounted) setState(() => _autoCode = code);
    } catch (_) {}
  }

  String get _effectiveStatus {
    if (widget.isCreate) {
      return _activeNow ? 'farming' : 'empty';
    }
    return _status;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rowId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn dãy nuôi')),
      );
      return;
    }
    setState(() => _saving = true);
    final vol = double.tryParse(_volume.text.trim());
    final pos = _position.text.trim().isEmpty ? null : _position.text.trim();
    try {
      if (_areaId != null) widget.svc.selectArea(_areaId);
      widget.svc.selectRow(_rowId);

      if (widget.isCreate) {
        final qty = int.tryParse(_count.text.trim()) ?? 1;
        final created = await widget.svc.createBoxes(
          count: qty,
          positionPrefix: pos,
          volume: vol,
          status: _effectiveStatus,
        );
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              created.length == 1
                  ? 'Đã thêm hộp ${created.first.boxCode}'
                  : 'Đã thêm ${created.length} hộp',
            ),
          ),
        );
        return;
      }

      await widget.svc.updateBox(
        widget.existing!,
        boxCode: widget.existing!.boxCode,
        position: pos,
        volume: vol,
        status: _effectiveStatus,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật hộp')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.isCreate;
    final qty = int.tryParse(_count.text.trim()) ?? 1;
    final multi = isCreate && qty > 1;

    return Dialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: DashboardColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: DashboardColors.purple,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCreate ? 'Thêm Hộp Mới' : 'Cập nhật Hộp',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCreate
                              ? 'Quản lý ô nuôi trên dãy — thêm một hoặc nhiều hộp'
                              : 'Chỉnh sửa thông tin hộp ${widget.existing!.boxCode}',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: DashboardColors.textMuted),
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
                      _LabeledField(
                        label: 'KHU VỰC QUẢN LÝ',
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          value: _areaId,
                          decoration: _fieldDecoration(
                            hint: 'Chọn khu nuôi...',
                          ),
                          dropdownColor: DashboardColors.card,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Chọn khu nuôi...'),
                            ),
                            ...widget.svc.areas.map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  '${a.areaCode} — ${a.areaName}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                          onChanged:
                              _saving || !isCreate ? null : _onAreaChanged,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'DÃY NUÔI',
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          value: _rowId,
                          decoration: _fieldDecoration(
                            hint: 'Chọn dãy...',
                          ),
                          dropdownColor: DashboardColors.card,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Chọn dãy...'),
                            ),
                            ..._rows.map(
                              (r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(
                                  '${r.rowCode} — ${r.rowName}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                          onChanged: _saving ||
                                  _areaId == null ||
                                  _loadingRows ||
                                  !isCreate
                              ? null
                              : _onRowChanged,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, c) {
                          final twoCol = c.maxWidth > 420;
                          final codeField = _LabeledField(
                            label: 'MÃ HỘP',
                            child: TextFormField(
                              readOnly: true,
                              initialValue: multi
                                  ? '$_autoCode … (×$qty)'
                                  : _autoCode,
                              decoration: _fieldDecoration(
                                hint: 'VD: H-01',
                                suffixIcon: Icon(
                                  Icons.qr_code_2,
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
                          final qtyField = isCreate
                              ? _LabeledField(
                                  label: 'SỐ LƯỢNG',
                                  child: TextFormField(
                                    controller: _count,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: _fieldDecoration(
                                      hint: '1',
                                    ),
                                    style: GoogleFonts.notoSans(
                                      color: DashboardColors.textPrimary,
                                    ),
                                    validator: (v) {
                                      final n = int.tryParse((v ?? '').trim());
                                      if (n == null || n < 1) {
                                        return 'Tối thiểu 1';
                                      }
                                      if (n > 100) return 'Tối đa 100';
                                      return null;
                                    },
                                  ),
                                )
                              : _LabeledField(
                                  label: 'VỊ TRÍ',
                                  child: TextFormField(
                                    controller: _position,
                                    decoration: _fieldDecoration(
                                      hint: 'VD: A-1',
                                    ),
                                    style: GoogleFonts.notoSans(
                                      color: DashboardColors.textPrimary,
                                    ),
                                  ),
                                );
                          if (!twoCol) {
                            return Column(
                              children: [
                                codeField,
                                const SizedBox(height: 16),
                                qtyField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: codeField),
                              const SizedBox(width: 16),
                              Expanded(child: qtyField),
                            ],
                          );
                        },
                      ),
                      if (isCreate) ...[
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'VỊ TRÍ / TIỀN TỐ',
                          child: TextFormField(
                            controller: _position,
                            decoration: _fieldDecoration(
                              hint: multi
                                  ? 'Tiền tố A → A-1, A-2…'
                                  : 'VD: Ô 12',
                            ),
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, c) {
                          final twoCol = c.maxWidth > 420;
                          final vol = _LabeledField(
                            label: 'THỂ TÍCH (L)',
                            child: TextFormField(
                              controller: _volume,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: _fieldDecoration(hint: 'VD: 120'),
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.textPrimary,
                              ),
                            ),
                          );
                          final pos = isCreate
                              ? const SizedBox.shrink()
                              : vol;
                          if (!isCreate && twoCol) {
                            return Row(
                              children: [
                                Expanded(child: vol),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _LabeledField(
                                    label: 'GHI CHÚ',
                                    child: TextFormField(
                                      controller: _desc,
                                      decoration: _fieldDecoration(
                                        hint: 'Tùy chọn',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              if (isCreate) vol else pos,
                              if (!isCreate) const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                      if (isCreate) const SizedBox(height: 16),
                      _LabeledField(
                        label: 'MÔ TẢ CHI TIẾT',
                        child: TextFormField(
                          controller: _desc,
                          maxLines: 3,
                          decoration: _fieldDecoration(
                            hint:
                                'Nhập ghi chú vị trí hoặc mục đích sử dụng hộp...',
                          ),
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isCreate) _buildActiveToggle() else _buildEditStatus(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DashboardColors.textMuted,
                      side: BorderSide(color: DashboardColors.cardBorder),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Hủy bỏ'),
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
              color: DashboardColors.cyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.power_settings_new,
              color: DashboardColors.cyan,
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
                  'Bật để đánh dấu hộp đang nuôi',
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
            onChanged: _saving ? null : (v) => setState(() => _activeNow = v),
            activeTrackColor: DashboardColors.purple.withValues(alpha: 0.5),
            activeThumbColor: DashboardColors.purple,
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
            children: [
              for (final entry in [
                ('empty', 'Hộp trống'),
                ('farming', 'Đang nuôi'),
                ('maintenance', 'Bảo trì'),
              ])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: _status == entry.$1,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => _status = entry.$1),
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
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: saving ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save_outlined,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Lưu thông tin',
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
