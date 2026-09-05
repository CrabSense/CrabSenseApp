import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';

const _conditions = <(String, String, Color)>[
  ('Good', 'Tốt', DashboardColors.healthy),
  ('Average', 'Trung bình', DashboardColors.monitoring),
  ('Problem', 'Có vấn đề', DashboardColors.risk),
];

Future<FarmingBatchRecord?> showCrabLotImportDialog(
  BuildContext context,
  CrabService service,
) async {
  return showDialog<FarmingBatchRecord>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _CrabLotImportDialog(service: service),
  );
}

class _CrabLotImportDialog extends StatefulWidget {
  const _CrabLotImportDialog({required this.service});

  final CrabService service;

  @override
  State<_CrabLotImportDialog> createState() => _CrabLotImportDialogState();
}

class _CrabLotImportDialogState extends State<_CrabLotImportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _supplier = TextEditingController();
  final _quantity = TextEditingController();
  final _totalKg = TextEditingController();
  final _minG = TextEditingController(text: '100');
  final _maxG = TextEditingController(text: '150');
  final _price = TextEditingController();
  final _shipping = TextEditingController(text: '0');
  final _other = TextEditingController(text: '0');
  final _dead = TextEditingController(text: '0');
  final _notes = TextEditingController();

  DateTime _importDate = DateTime.now();
  String _lotCode = 'LOT-…';
  String _condition = 'Good';
  var _loadingCode = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_quantity, _totalKg, _price, _shipping, _other]) {
      c.addListener(() => setState(() {}));
    }
    _refreshCode();
  }

  @override
  void dispose() {
    _name.dispose();
    _supplier.dispose();
    _quantity.dispose();
    _totalKg.dispose();
    _minG.dispose();
    _maxG.dispose();
    _price.dispose();
    _shipping.dispose();
    _other.dispose();
    _dead.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _refreshCode() async {
    setState(() => _loadingCode = true);
    try {
      final code = await widget.service.peekNextLotCode(importDate: _importDate);
      if (mounted) setState(() => _lotCode = code);
    } catch (_) {
      if (mounted) {
        setState(() {
          _lotCode =
              'LOT-${_importDate.year}${_two(_importDate.month)}${_two(_importDate.day)}-001';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingCode = false);
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _dateLabel(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  double? _parseNum(String raw) {
    final t = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  int? _parseInt(String raw) {
    final n = _parseNum(raw);
    return n?.round();
  }

  int get _qty => _parseInt(_quantity.text) ?? 0;
  double? get _kg => _parseNum(_totalKg.text);
  double? get _unitPrice => _parseNum(_price.text);
  double get _ship => _parseNum(_shipping.text) ?? 0;
  double get _otherCost => _parseNum(_other.text) ?? 0;

  double? get _avgGram {
    final kg = _kg;
    if (kg == null || kg <= 0 || _qty <= 0) return null;
    return kg * 1000 / _qty;
  }

  double? get _crabCost {
    final kg = _kg;
    final price = _unitPrice;
    if (kg == null || kg <= 0 || price == null || price < 0) return null;
    return price * kg;
  }

  double? get _totalCost {
    final crab = _crabCost;
    if (crab == null && _ship == 0 && _otherCost == 0) return null;
    return (crab ?? 0) + _ship + _otherCost;
  }

  String _vnd(double? v) {
    if (v == null) return '—';
    final s = v.round().abs().toString();
    final buf = StringBuffer();
    if (v < 0) buf.write('-');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf VNĐ';
  }

  InputDecoration _dec({required String hint, Widget? suffix, String? prefix}) =>
      InputDecoration(
        hintText: hint,
        prefixText: prefix,
        hintStyle: GoogleFonts.notoSans(
          color: DashboardColors.textMuted.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        filled: true,
        fillColor: DashboardColors.darkNavy,
        suffixIcon: suffix,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardColors.risk),
        ),
      );

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text.toUpperCase(),
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: DashboardColors.risk),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _importDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _importDate = picked);
    await _refreshCode();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = _qty;
    final dead = _parseInt(_dead.text) ?? 0;
    if (dead > qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số cua chết không được lớn hơn số lượng nhập')),
      );
      return;
    }

    setState(() => _saving = true);
    final lot = await widget.service.importLot(
      name: _name.text.trim(),
      importDate: _importDate,
      quantity: qty,
      lotCode: _lotCode.startsWith('LOT-') ? _lotCode : null,
      supplierName: _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
      totalWeightKg: _kg,
      weightMinGram: _parseNum(_minG.text),
      weightMaxGram: _parseNum(_maxG.text),
      unitPriceVndPerKg: _unitPrice,
      shippingCostVnd: _parseNum(_shipping.text),
      otherCostVnd: _parseNum(_other.text),
      condition: _condition,
      deadOnArrival: dead,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    if (!mounted) return;
    if (lot == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.service.error ?? 'Không nhập được lô')),
      );
      return;
    }
    Navigator.pop(context, lot);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
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
                          'Nhập lô cua',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Phiếu nhập hàng. Cá thể cua được thêm sau khi phân vào hộp.',
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
                      _label('Mã lô'),
                      InputDecorator(
                        decoration: _dec(
                          hint: 'LOT-20260905-001',
                          suffix: _loadingCode
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : Icon(
                                  Icons.lock_outline,
                                  color: DashboardColors.textMuted.withValues(alpha: 0.6),
                                ),
                        ),
                        child: Text(
                          _lotCode,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('Tên lô', required: true),
                      TextFormField(
                        controller: _name,
                        decoration: _dec(hint: 'Lô cua tháng 9'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nhập tên lô' : null,
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, c) {
                          final two = c.maxWidth > 420;
                          final date = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label('Ngày nhập', required: true),
                              InkWell(
                                onTap: _saving ? null : _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: _dec(
                                    hint: _dateLabel(_importDate),
                                    suffix: Icon(
                                      Icons.calendar_today_outlined,
                                      color: DashboardColors.textMuted.withValues(alpha: 0.7),
                                      size: 18,
                                    ),
                                  ),
                                  child: Text(
                                    _dateLabel(_importDate),
                                    style: GoogleFonts.notoSans(
                                      color: DashboardColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                          final supplier = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label('Nguồn cung cấp'),
                              TextFormField(
                                controller: _supplier,
                                decoration: _dec(hint: 'Nhà cung cấp A'),
                              ),
                            ],
                          );
                          if (!two) {
                            return Column(
                              children: [date, const SizedBox(height: 16), supplier],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: date),
                              const SizedBox(width: 12),
                              Expanded(child: supplier),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Divider(color: DashboardColors.cardBorder),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, c) {
                          final qty = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label('Số lượng', required: true),
                              TextFormField(
                                controller: _quantity,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: _dec(hint: '100', suffix: _unit('con')),
                                validator: (v) {
                                  final n = _parseInt(v ?? '');
                                  if (n == null || n <= 0) return 'Nhập số con > 0';
                                  return null;
                                },
                              ),
                            ],
                          );
                          final kg = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label('Tổng trọng lượng'),
                              TextFormField(
                                controller: _totalKg,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _dec(hint: '12.5', suffix: _unit('kg')),
                              ),
                            ],
                          );
                          if (c.maxWidth <= 420) {
                            return Column(children: [qty, const SizedBox(height: 16), kg]);
                          }
                          return Row(
                            children: [
                              Expanded(child: qty),
                              const SizedBox(width: 12),
                              Expanded(child: kg),
                            ],
                          );
                        },
                      ),
                      if (_avgGram != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Trọng lượng trung bình: ${_avgGram!.toStringAsFixed(0)} g/con',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.cyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _label('Khoảng trọng lượng'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minG,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _dec(hint: '100', suffix: _unit('g')),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '→',
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.textMuted,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _maxG,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _dec(hint: '150', suffix: _unit('g')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: DashboardColors.cardBorder),
                      const SizedBox(height: 16),
                      _label('Giá nhập'),
                      TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _dec(hint: '180000', suffix: _unit('VNĐ/kg')),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label('Chi phí vận chuyển'),
                                TextFormField(
                                  controller: _shipping,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _dec(hint: '100000', suffix: _unit('VNĐ')),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label('Chi phí khác'),
                                TextFormField(
                                  controller: _other,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _dec(hint: '0', suffix: _unit('VNĐ')),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_totalCost != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DashboardColors.darkNavy,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DashboardColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tiền cua: ${_vnd(_crabCost)}',
                                style: GoogleFonts.notoSans(
                                  color: DashboardColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tổng chi phí: ${_vnd(_totalCost)}',
                                style: GoogleFonts.notoSans(
                                  color: DashboardColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Divider(color: DashboardColors.cardBorder),
                      const SizedBox(height: 16),
                      _label('Tình trạng lô'),
                      DropdownButtonFormField<String>(
                        initialValue: _condition,
                        dropdownColor: DashboardColors.card,
                        decoration: _dec(hint: 'Tốt'),
                        items: [
                          for (final item in _conditions)
                            DropdownMenuItem(
                              value: item.$1,
                              child: Text(
                                item.$2,
                                style: GoogleFonts.notoSans(color: item.$3),
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _condition = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      _label('Số cua chết khi nhập'),
                      TextFormField(
                        controller: _dead,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _dec(hint: '0', suffix: _unit('con')),
                      ),
                      const SizedBox(height: 16),
                      _label('Ghi chú'),
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        decoration: _dec(hint: 'Một số cua bị yếu sau vận chuyển.'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: DashboardColors.oceanBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Nhập lô'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unit(String text) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          child: Text(
            text,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
