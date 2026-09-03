import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/batch_list_item.dart';
import '../../models/production_models.dart';
import '../../services/batch_management_service.dart';
import '../../services/production_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

Future<void> showFarmingBatchFormDialog(
  BuildContext context, {
  required BatchManagementService batchSvc,
  required ProductionManagementService prodSvc,
  BatchListItem? existing,
}) async {
  if (batchSvc.areas.isEmpty) await batchSvc.load();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => FarmingBatchFormDialog(
      batchSvc: batchSvc,
      prodSvc: prodSvc,
      existing: existing,
    ),
  );
}

class FarmingBatchFormDialog extends StatefulWidget {
  const FarmingBatchFormDialog({
    super.key,
    required this.batchSvc,
    required this.prodSvc,
    this.existing,
  });

  final BatchManagementService batchSvc;
  final ProductionManagementService prodSvc;
  final BatchListItem? existing;

  bool get isCreate => existing == null;

  @override
  State<FarmingBatchFormDialog> createState() => _FarmingBatchFormDialogState();
}

class _FarmingBatchFormDialogState extends State<FarmingBatchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _qty;
  late final TextEditingController _cur;
  late final TextEditingController _note;

  String? _areaId;
  String? _rowId;
  List<RowRecord> _rows = [];
  List<BoxRecord> _boxes = [];
  Set<String> _selectedBoxIds = {};
  late DateTime _start;
  late DateTime _expected;
  var _activeFarming = true;
  var _startNow = true;
  var _saving = false;
  var _loadingBoxes = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.batch.batchCode ?? '');
    _qty = TextEditingController(text: '${e?.batch.initialQuantity ?? 1000}');
    _cur = TextEditingController(text: '${e?.batch.currentQuantity ?? 0}');
    _note = TextEditingController();
    final today = DateTime.now();
    _start = e?.batch.startDate ?? DateTime(today.year, today.month, today.day);
    _expected = e?.batch.expectedHarvestDate ??
        _start.add(const Duration(days: 60));
    _activeFarming = e?.batch.status != 'harvested' && e?.batch.status != 'failed';
    _areaId = e?.areaId ?? widget.batchSvc.areaFilterId;
    _rowId = e?.rowId ?? widget.batchSvc.rowFilterId;
    if (e != null) {
      _selectedBoxIds = {e.batch.boxId};
    }
    _rows = List.from(widget.batchSvc.rows);
    _boxes = List.from(widget.batchSvc.boxes);
    if (_areaId != null && _rows.isEmpty) _loadRows(_areaId!);
    if (_rowId != null && _boxes.isEmpty) _loadBoxes(_rowId!);
    if (widget.isCreate && _selectedBoxIds.isEmpty && _rowId != null) {
      _selectDefaultBoxes();
    }
    if (widget.isCreate) _refreshCode();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _qty.dispose();
    _cur.dispose();
    _note.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    String? label,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.notoSans(
          color: DashboardColors.textMuted.withValues(alpha: 0.65),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        filled: true,
        fillColor: DashboardColors.darkNavy,
        suffix: suffix,
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
          borderSide: BorderSide(color: DashboardColors.purple, width: 1.2),
        ),
      );

  Future<void> _loadRows(String areaId) async {
    await widget.batchSvc.selectArea(areaId);
    widget.prodSvc.selectArea(areaId);
    await widget.prodSvc.loadRows();
    if (!mounted) return;
    setState(() => _rows = List.from(widget.batchSvc.rows));
  }

  Future<void> _loadBoxes(String rowId) async {
    setState(() => _loadingBoxes = true);
    await widget.batchSvc.selectRow(rowId);
    widget.prodSvc.selectArea(_areaId);
    widget.prodSvc.selectRow(rowId);
    await widget.prodSvc.loadBoxes();
    if (!mounted) return;
    setState(() {
      _boxes = List.from(widget.batchSvc.boxes);
      _loadingBoxes = false;
      _selectDefaultBoxes();
    });
    await _refreshCode();
  }

  void _selectDefaultBoxes() {
    if (!widget.isCreate) return;
    _selectedBoxIds = _boxes
        .where((b) => b.status == 'empty' || b.status == 'active')
        .map((b) => b.id)
        .toSet();
    if (_selectedBoxIds.isEmpty && _boxes.isNotEmpty) {
      _selectedBoxIds = {_boxes.first.id};
    }
  }

  String get _boxSelectionLabel {
    if (_selectedBoxIds.isEmpty) return 'Chọn hộp nuôi';
    final codes = _boxes
        .where((b) => _selectedBoxIds.contains(b.id))
        .map((b) => b.boxCode)
        .toList()
      ..sort(_sortBoxCodes);
    if (codes.length == 1) return codes.first;
    return '${codes.first} - ${codes.last} (${codes.length} hộp)';
  }

  int _sortBoxCodes(String a, String b) {
    final na = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final nb = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (na != nb) return na.compareTo(nb);
    return a.compareTo(b);
  }

  Future<void> _refreshCode() async {
    if (!widget.isCreate) return;
    final first = _selectedBoxIds.isNotEmpty
        ? _selectedBoxIds.first
        : (_boxes.isNotEmpty ? _boxes.first.id : null);
    if (first == null) return;
    widget.prodSvc.selectBox(first);
    try {
      final c = await widget.prodSvc.fetchNextBatchCode();
      if (mounted) _codeCtrl.text = c;
    } catch (_) {}
  }

  Future<void> _openBoxPicker() async {
    if (_rowId == null || _boxes.isEmpty) return;
    final temp = Set<String>.from(_selectedBoxIds);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DashboardColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Chọn hộp nuôi (${temp.length}/${_boxes.length})',
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setModal(() {
                          temp
                            ..clear()
                            ..addAll(_boxes.map((b) => b.id));
                        }),
                        child: const Text('Chọn tất cả'),
                      ),
                      TextButton(
                        onPressed: () => setModal(() => temp.clear()),
                        child: const Text('Bỏ chọn'),
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView(
                      shrinkWrap: true,
                      children: _boxes.map((box) {
                        return CheckboxListTile(
                          value: temp.contains(box.id),
                          title: Text(box.boxCode),
                          subtitle: Text(
                            box.status,
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              color: DashboardColors.textMuted,
                            ),
                          ),
                          onChanged: (v) {
                            setModal(() {
                              if (v == true) {
                                temp.add(box.id);
                              } else {
                                temp.remove(box.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: DashboardColors.purple,
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() => _selectedBoxIds = temp);
    await _refreshCode();
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
        const SnackBar(content: Text('Ngày thu hoạch phải sau ngày bắt đầu')),
      );
      return;
    }
    setState(() => _saving = true);
    final iq = int.tryParse(_qty.text.trim()) ?? 0;
    final cq = int.tryParse(_cur.text.trim()) ?? iq;
    final status = _activeFarming ? 'active' : 'harvested';
    try {
      widget.prodSvc.selectArea(_areaId);
      widget.prodSvc.selectRow(_rowId);
      if (widget.isCreate) {
        await widget.prodSvc.createBatches(
          boxIds: _selectedBoxIds.toList(),
          startDate: _start,
          expectedHarvestDate: _expected,
          initialQuantity: iq,
          status: status,
          startNow: _startNow && _activeFarming,
        );
      } else {
        final b = widget.existing!.batch;
        await widget.prodSvc.updateBatch(
          b,
          startDate: _start,
          expectedHarvestDate: _expected,
          initialQuantity: iq,
          currentQuantity: cq,
          status: status,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      await widget.batchSvc.load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu đợt nuôi')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _expected,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_expected.isBefore(_start)) {
          _expected = _start.add(const Duration(days: 60));
        }
      } else {
        _expected = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.isCreate;
    return Dialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              title: isCreate ? 'Thêm Đợt Nuôi Mới' : 'Cập nhật Đợt Nuôi',
              onClose: () => Navigator.pop(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel('VỊ TRÍ NUÔI'),
                      const SizedBox(height: 12),
                      _LocationFields(
                        isCreate: isCreate,
                        areaId: _areaId,
                        rowId: _rowId,
                        areas: widget.batchSvc.areas,
                        rows: _rows,
                        boxes: _boxes,
                        selectedBoxIds: _selectedBoxIds,
                        loadingBoxes: _loadingBoxes,
                        boxSelectionLabel: _boxSelectionLabel,
                        onAreaChanged: (v) async {
                          setState(() {
                            _areaId = v;
                            _rowId = null;
                            _boxes = [];
                            _selectedBoxIds = {};
                          });
                          if (v != null) await _loadRows(v);
                        },
                        onRowChanged: (v) async {
                          setState(() {
                            _rowId = v;
                            _selectedBoxIds = {};
                          });
                          if (v != null) await _loadBoxes(v);
                        },
                        onOpenBoxPicker: _openBoxPicker,
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, c) {
                          final info = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionLabel('THÔNG TIN ĐỢT'),
                              const SizedBox(height: 12),
                              _LabeledField(
                                label: 'Mã đợt nuôi',
                                child: TextFormField(
                                  controller: _codeCtrl,
                                  readOnly: isCreate,
                                  decoration: _fieldDecoration(
                                    hint: 'CF - 2023 - XXXX',
                                  ),
                                  style: GoogleFonts.notoSans(
                                    color: DashboardColors.cyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _LabeledField(
                                label: 'Số lượng ban đầu',
                                child: TextFormField(
                                  controller: _qty,
                                  keyboardType: TextInputType.number,
                                  decoration: _fieldDecoration(
                                    hint: '1000',
                                    suffix: Padding(
                                      padding: const EdgeInsets.only(top: 14, right: 12),
                                      child: Text(
                                        'Con',
                                        style: GoogleFonts.notoSans(
                                          color: DashboardColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    final n = int.tryParse((v ?? '').trim());
                                    if (n == null || n < 1) return 'Nhập số lượng';
                                    return null;
                                  },
                                ),
                              ),
                              if (!isCreate) ...[
                                const SizedBox(height: 16),
                                _LabeledField(
                                  label: 'Số lượng hiện tại',
                                  child: TextFormField(
                                    controller: _cur,
                                    keyboardType: TextInputType.number,
                                    decoration: _fieldDecoration(hint: '0'),
                                  ),
                                ),
                              ],
                            ],
                          );
                          final schedule = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionLabel('LỊCH TRÌNH'),
                              const SizedBox(height: 12),
                              _LabeledField(
                                label: 'Ngày bắt đầu',
                                child: _DateField(
                                  value: _fmt(_start),
                                  onTap: () => _pickDate(start: true),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _LabeledField(
                                label: 'Ngày thu hoạch dự kiến',
                                child: _DateField(
                                  value: _fmt(_expected),
                                  onTap: () => _pickDate(start: false),
                                ),
                              ),
                            ],
                          );
                          if (c.maxWidth < 520) {
                            return Column(
                              children: [info, const SizedBox(height: 20), schedule],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: info),
                              const SizedBox(width: 24),
                              Expanded(child: schedule),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, c) {
                          final notes = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionLabel('Ghi chú'),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _note,
                                maxLines: 4,
                                decoration: _fieldDecoration(
                                  hint:
                                      'Nhập ghi chú chi tiết về giống, nguồn gốc hoặc điều kiện đặc biệt...',
                                ),
                              ),
                            ],
                          );
                          final status = GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trạng thái đợt',
                                  style: GoogleFonts.notoSans(
                                    color: DashboardColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Switch(
                                      value: _activeFarming,
                                      activeTrackColor:
                                          DashboardColors.purple.withValues(alpha: 0.5),
                                      thumbColor: WidgetStateProperty.resolveWith(
                                        (s) => s.contains(WidgetState.selected)
                                            ? DashboardColors.purple
                                            : null,
                                      ),
                                      onChanged: (v) => setState(() {
                                        _activeFarming = v;
                                        _startNow = v;
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Đang nuôi',
                                            style: GoogleFonts.notoSans(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Tự động kích hoạt cảm biến giám sát khi lưu',
                                            style: GoogleFonts.notoSans(
                                              color: DashboardColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                          if (c.maxWidth < 520) {
                            return Column(
                              children: [notes, const SizedBox(height: 16), status],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: notes),
                              const SizedBox(width: 16),
                              Expanded(child: status),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text(
                      'Hủy bỏ',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _GradientSaveButton(
                    saving: _saving,
                    label: 'Lưu Đợt Nuôi',
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

  String _fmt(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

}

class _LocationFields extends StatelessWidget {
  const _LocationFields({
    required this.isCreate,
    required this.areaId,
    required this.rowId,
    required this.areas,
    required this.rows,
    required this.boxes,
    required this.selectedBoxIds,
    required this.loadingBoxes,
    required this.boxSelectionLabel,
    required this.onAreaChanged,
    required this.onRowChanged,
    required this.onOpenBoxPicker,
  });

  final bool isCreate;
  final String? areaId;
  final String? rowId;
  final List<AreaRecord> areas;
  final List<RowRecord> rows;
  final List<BoxRecord> boxes;
  final Set<String> selectedBoxIds;
  final bool loadingBoxes;
  final String boxSelectionLabel;
  final ValueChanged<String?> onAreaChanged;
  final ValueChanged<String?> onRowChanged;
  final VoidCallback onOpenBoxPicker;

  @override
  Widget build(BuildContext context) {
    final khu = _LocationDrop(
      label: 'Khu',
      value: areaId,
      enabled: isCreate,
      items: areas
          .map(
            (a) => DropdownMenuItem(
              value: a.id,
              child: Text(
                '${a.areaCode} (${a.areaName})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isCreate ? onAreaChanged : null,
    );
    final day = _LocationDrop(
      label: 'Dãy',
      value: rowId,
      enabled: isCreate && areaId != null,
      items: rows
          .map(
            (r) => DropdownMenuItem(
              value: r.id,
              child: Text(r.rowCode),
            ),
          )
          .toList(),
      onChanged: isCreate && areaId != null ? onRowChanged : null,
    );
    final hop = isCreate
        ? _BoxPickerField(
            label: 'Hộp',
            summary: loadingBoxes ? 'Đang tải...' : boxSelectionLabel,
            enabled: rowId != null && !loadingBoxes,
            onTap: onOpenBoxPicker,
          )
        : _LocationDrop(
            label: 'Hộp',
            value: selectedBoxIds.isNotEmpty ? selectedBoxIds.first : null,
            enabled: false,
            items: boxes
                .map(
                  (b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(b.boxCode),
                  ),
                )
                .toList(),
            onChanged: null,
          );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 560) {
          return Column(
            children: [khu, const SizedBox(height: 12), day, const SizedBox(height: 12), hop],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: khu),
            const SizedBox(width: 12),
            Expanded(child: day),
            const SizedBox(width: 12),
            Expanded(child: hop),
          ],
        );
      },
    );
  }
}

class _LocationDrop extends StatelessWidget {
  const _LocationDrop({
    required this.label,
    required this.value,
    required this.items,
    required this.enabled,
    this.onChanged,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final bool enabled;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: DropdownButtonFormField<String>(
        value: items.any((i) => i.value == value) ? value : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: DashboardColors.darkNavy,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DashboardColors.cardBorder),
          ),
        ),
        dropdownColor: DashboardColors.card,
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('Chọn $label...'),
          ),
          ...items,
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DashboardColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_circle_outline,
              color: DashboardColors.purple,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DashboardColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSans(
        color: DashboardColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _BoxPickerField extends StatelessWidget {
  const _BoxPickerField({
    required this.label,
    required this.summary,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String summary;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: DashboardColors.darkNavy,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DashboardColors.cardBorder),
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: enabled
                  ? DashboardColors.textMuted
                  : DashboardColors.textMuted.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            summary,
            style: GoogleFonts.notoSans(
              color: enabled
                  ? DashboardColors.textPrimary
                  : DashboardColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: DashboardColors.darkNavy,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DashboardColors.cardBorder),
          ),
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: DashboardColors.textMuted,
          ),
        ),
        child: Text(
          value,
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
        ),
      ),
    );
  }
}

class _GradientSaveButton extends StatelessWidget {
  const _GradientSaveButton({
    required this.saving,
    required this.label,
    required this.onPressed,
  });

  final bool saving;
  final String label;
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
                      const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        label,
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
