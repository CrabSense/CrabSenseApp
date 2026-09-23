import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/crab_status.dart';
import '../../../models/production_models.dart';
import '../../../services/cloud_api_client.dart';
import '../../../services/crab_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/crab_management_mapper.dart';
import '../../shared/mgmt_ui.dart';

const _kTypes = ['Cua biển', 'Cua xanh', 'Khác'];
const _kHealth = [
  CrabDisplayHealth.healthy,
  CrabDisplayHealth.monitoring,
  CrabDisplayHealth.weak,
];

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
  if (b.hasCrab) return '${b.boxCode} — Đã có cua · Không thể chọn';
  if (b.alertCount > 0) return '${b.boxCode} — Cảnh báo · Không thể chọn';
  if (_boxUnusable(b)) return '${b.boxCode} — Không hoạt động · Không thể chọn';
  return '${b.boxCode} — Trống';
}

Future<bool> showAddCrabModal(
  BuildContext context,
  CrabService service, {
  String? initialLotId,
  VoidCallback? onManageLots,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (_) => AddCrabModal(
      service: service,
      initialLotId: initialLotId,
      onManageLots: onManageLots,
    ),
  );
  return ok == true;
}

class AddCrabModal extends StatefulWidget {
  const AddCrabModal({
    super.key,
    required this.service,
    this.initialLotId,
    this.onManageLots,
  });

  final CrabService service;
  final String? initialLotId;
  final VoidCallback? onManageLots;

  @override
  State<AddCrabModal> createState() => _AddCrabModalState();
}

class _AddCrabModalState extends State<AddCrabModal> {
  final _weight = TextEditingController();
  final _width = TextEditingController();
  final _length = TextEditingController();
  final _note = TextEditingController();

  List<FarmingBatchRecord> _lots = const [];
  List<AreaRecord> _areas = const [];
  List<RowRecord> _rows = const [];
  List<BoxRecord> _boxes = const [];

  FarmingBatchRecord? _lot;
  String? _areaId;
  String? _rowId;
  String? _boxId;
  var _autoAssign = true;
  String _type = 'Cua biển';
  CrabGender _gender = CrabGender.unknown;
  CrabDisplayHealth _health = CrabDisplayHealth.healthy;
  DateTime _enteredAt = DateTime.now();
  String? _imagePath;
  String _previewCode = 'CRAB-0001';
  String _previewQr = 'QR-CRAB-0001';

  var _loading = true;
  var _rowsLoading = false;
  var _boxesLoading = false;
  var _saving = false;
  String? _error;
  var _conflict = false;
  String? _lotError;
  String? _areaError;
  String? _rowError;
  String? _boxError;
  String? _weightError;
  String? _sizeError;
  String? _dateError;

  CrabService get _svc => widget.service;
  int get _remaining => _lot?.remainingCount ?? 0;
  int get _emptyCount => _boxes.where(_boxSelectable).length;
  BoxRecord? get _target => _boxes.where((b) => b.id == _boxId).firstOrNull;
  bool get _targetOk => _target != null && _boxSelectable(_target!);

  bool get _canSubmit {
    if (_saving || _loading || _lot == null || _remaining <= 0) return false;
    if (_areaId == null || _rowId == null) return false;
    if (_autoAssign) {
      if (_emptyCount <= 0) return false;
    } else if (!_targetOk) {
      return false;
    }
    final w = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    final wd = double.tryParse(_width.text.trim().replaceAll(',', '.'));
    final ln = double.tryParse(_length.text.trim().replaceAll(',', '.'));
    if (w == null || w <= 0 || wd == null || wd <= 0 || ln == null || ln <= 0) return false;
    if (_dateInvalid) return false;
    return true;
  }

  bool get _dateInvalid {
    final lot = _lot;
    if (lot == null) return false;
    final entered = DateTime(_enteredAt.year, _enteredAt.month, _enteredAt.day);
    final imported = DateTime(lot.startDate.year, lot.startDate.month, lot.startDate.day);
    return entered.isBefore(imported);
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _weight.dispose();
    _width.dispose();
    _length.dispose();
    _note.dispose();
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
      FarmingBatchRecord? lot;
      if (widget.initialLotId != null) {
        lot = lots.where((l) => l.id == widget.initialLotId).firstOrNull;
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
        _previewCode = next?.code ?? 'CRAB-0001';
        _previewQr = next?.qrCode ?? 'QR-${next?.code ?? 'CRAB-0001'}';
        _loading = false;
      });
      if (areaId != null) await _onArea(areaId, initial: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _onArea(String id, {bool initial = false}) async {
    setState(() {
      _areaId = id;
      if (!initial) {
        _rowId = null;
        _boxId = null;
      }
      _rows = const [];
      _boxes = const [];
      _rowsLoading = true;
      _boxesLoading = true;
    });
    try {
      final rows = await _svc.fetchRows(id);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _rowsLoading = false;
        if (_rowId != null && !rows.any((r) => r.id == _rowId)) _rowId = null;
        _rowId ??= rows.isEmpty ? null : rows.first.id;
      });
      if (_rowId != null) {
        await _loadBoxes();
      } else {
        setState(() => _boxesLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _rowsLoading = false;
        _boxesLoading = false;
      });
    }
  }

  Future<void> _onRow(String id) async {
    setState(() {
      _rowId = id;
      _boxId = null;
    });
    await _loadBoxes();
  }

  Future<void> _loadBoxes() async {
    setState(() => _boxesLoading = true);
    try {
      final boxes = await _svc.fetchBoxes(areaId: _areaId, rowId: _rowId);
      if (!mounted) return;
      setState(() {
        _boxes = boxes;
        if (_boxId != null && !boxes.any((b) => b.id == _boxId)) _boxId = null;
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

  bool _validate() {
    setState(() {
      _lotError = _lot == null ? 'Vui lòng chọn lô nhập.' : (_remaining <= 0 ? 'Lô này đã tạo đủ số lượng cá thể.' : null);
      _areaError = _areaId == null ? 'Vui lòng chọn khu vực.' : null;
      _rowError = _rowId == null ? 'Vui lòng chọn dãy.' : null;
      _boxError = _autoAssign
          ? (_emptyCount <= 0 ? 'Không còn hộp trống phù hợp.' : null)
          : (_boxId == null
              ? 'Vui lòng chọn hộp.'
              : _targetOk
                  ? null
                  : '${_target?.boxCode ?? 'Hộp'} không còn trống.');
      final w = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
      final wd = double.tryParse(_width.text.trim().replaceAll(',', '.'));
      final ln = double.tryParse(_length.text.trim().replaceAll(',', '.'));
      _weightError = w == null || w <= 0 ? 'Cân nặng phải lớn hơn 0.' : null;
      _sizeError = wd == null || wd <= 0 || ln == null || ln <= 0 ? 'Kích thước phải lớn hơn 0.' : null;
      _dateError = _dateInvalid ? 'Ngày nhập hộp không được trước ngày nhập lô.' : null;
    });
    return _lotError == null &&
        _areaError == null &&
        _rowError == null &&
        _boxError == null &&
        _weightError == null &&
        _sizeError == null &&
        _dateError == null;
  }

  Future<void> _submit() async {
    if (_saving || !_validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _conflict = false;
    });
    try {
      final created = await _svc.addCrab(
        batchId: _lot!.id,
        gender: _gender,
        weightGram: double.parse(_weight.text.trim().replaceAll(',', '.')),
        carapaceWidthMm: double.parse(_width.text.trim().replaceAll(',', '.')),
        carapaceLengthMm: double.parse(_length.text.trim().replaceAll(',', '.')),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        boxId: _autoAssign ? null : _boxId,
        farmingAreaId: _areaId,
        farmingRowId: _rowId,
        crabType: _type,
        initialCondition: _health.label,
        condition: healthDisplayToCondition(_health),
        stockedAt: _enteredAt,
        imagePaths: _imagePath == null ? null : [_imagePath!],
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      final box = created.boxCode;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            box != null && box.isNotEmpty
                ? 'Đã tạo ${created.code} và phân vào $box.'
                : 'Đã thêm ${created.code} thành công.',
          ),
        ),
      );
    } on CloudApiException catch (e) {
      if (!mounted) return;
      final conflict = e.statusCode == 409 || e.message.contains('vừa được') || e.message.contains('trống');
      setState(() {
        _saving = false;
        _conflict = conflict;
        _error = e.message;
        if (e.message.contains('trống')) {
          _boxError = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final path = file.path;
    if (path == null) return;
    if (file.size > 5 * 1024 * 1024) {
      setState(() => _error = 'Ảnh tối đa 5MB.');
      return;
    }
    setState(() {
      _imagePath = path;
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final first = _lot == null
        ? DateTime(2020)
        : DateTime(_lot!.startDate.year, _lot!.startDate.month, _lot!.startDate.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _enteredAt.isBefore(first) ? first : _enteredAt,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _enteredAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 24, vertical: compact ? 10 : 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 880),
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
                Text('Thêm cua', style: bvText(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                Text(
                  'Tạo một cá thể cua mới từ lô nhập và phân vào hộp nuôi.',
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
    if (_loading) return _AddCrabSkeleton(wide: wide);
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

    final form = _form(compact);
    final side = CrabCreateSummaryPanel(
      lot: _lot,
      autoAssign: _autoAssign,
      target: _target,
      targetOk: _targetOk,
      emptyCount: _emptyCount,
      rowLabel: _rowLabel,
    );
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
          flex: 70,
          child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 16, 12, 16), child: form),
        ),
        Container(width: 1, color: DashboardColors.mint),
        Expanded(
          flex: 30,
          child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(14, 16, 16, 16), child: side),
        ),
      ],
    );
  }

  String get _rowLabel {
    for (final r in _rows) {
      if (r.id == _rowId) return r.rowName.trim().isEmpty ? r.rowCode : r.rowName;
    }
    return '—';
  }

  Widget _form(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _step(1, 'Lô nhập'),
        const SizedBox(height: 8),
        _label('Lô nhập', required: true),
        _Select<String>(
          valueLabel: _lot?.displayLabel ?? 'Chọn lô nhập',
          items: [for (final l in _lots) (l.id, l.displayLabel)],
          onSelected: (id) => setState(() => _lot = _lots.where((l) => l.id == id).firstOrNull),
        ),
        if (_lotError != null) _err(_lotError!),
        if (_lot != null) ...[
          const SizedBox(height: 10),
          BatchQuickInfo(lot: _lot!),
          if (_remaining <= 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _err('Lô này đã tạo đủ số lượng cá thể.'),
            ),
        ],
        const SizedBox(height: 18),
        _step(2, 'Vị trí nuôi'),
        const SizedBox(height: 8),
        if (compact) ...[
          _label('Khu vực', required: true),
          _areaSelect(),
          if (_areaError != null) _err(_areaError!),
          const SizedBox(height: 10),
          _label('Dãy', required: true),
          _rowSelect(),
          if (_rowError != null) _err(_rowError!),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Khu vực', required: true),
                    _areaSelect(),
                    if (_areaError != null) _err(_areaError!),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Dãy', required: true),
                    _rowSelect(),
                    if (_rowError != null) _err(_rowError!),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        _label('Cách phân hộp', required: true),
        const SizedBox(height: 8),
        BoxAssignMode(
          auto: _autoAssign,
          compact: compact,
          onChanged: (v) => setState(() {
            _autoAssign = v;
            if (v) _boxId = null;
          }),
        ),
        const SizedBox(height: 10),
        if (_autoAssign)
          _autoBanner()
        else ...[
          _label('Hộp', required: true),
          _Select<String>(
            valueLabel: _target == null ? 'Chọn hộp' : _boxOptionLabel(_target!),
            loading: _boxesLoading,
            items: [for (final b in _boxes) (b.id, _boxOptionLabel(b))],
            enabledOf: (id) {
              for (final b in _boxes) {
                if (b.id == id) return _boxSelectable(b);
              }
              return false;
            },
            onSelected: (id) => setState(() {
              _boxId = id;
              _conflict = false;
              _error = null;
            }),
          ),
          if (_boxError != null) _err(_boxError!),
          if (_target != null) ...[
            const SizedBox(height: 10),
            TargetBoxPreview(box: _target!, ok: _targetOk),
          ],
        ],
        if (_conflict) ...[
          const SizedBox(height: 8),
          _err(_error ?? 'Hộp vừa được sử dụng.'),
          TextButton(onPressed: _loadBoxes, child: const Text('Chọn hộp khác')),
        ],
        const SizedBox(height: 18),
        _step(3, 'Thông tin cua'),
        const SizedBox(height: 10),
        CrabIdentitySection(code: _previewCode, qr: _previewQr),
        const SizedBox(height: 12),
        if (compact) ...[
          _label('Loại cua', required: true),
          _Select<String>(valueLabel: _type, items: [for (final t in _kTypes) (t, t)], onSelected: (v) => setState(() => _type = v)),
          const SizedBox(height: 10),
          _label('Giới tính', required: true),
          _Select<CrabGender>(
            valueLabel: _gender.label,
            items: [for (final g in CrabGender.values) (g, g.label)],
            onSelected: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 10),
          _label('Cân nặng (g)', required: true),
          _numField(_weight, '126', suffix: 'g'),
          if (_weightError != null) _err(_weightError!),
          const SizedBox(height: 10),
          _label('Rộng mai (mm)', required: true),
          _numField(_width, '60', suffix: 'mm'),
          const SizedBox(height: 10),
          _label('Dài mai (mm)', required: true),
          _numField(_length, '90', suffix: 'mm'),
          if (_sizeError != null) _err(_sizeError!),
          const SizedBox(height: 10),
          _label('Sức khỏe ban đầu', required: true),
          _Select<CrabDisplayHealth>(
            valueLabel: _health.label,
            items: [for (final h in _kHealth) (h, h.label)],
            onSelected: (v) => setState(() => _health = v),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Loại cua', required: true),
                    _Select<String>(valueLabel: _type, items: [for (final t in _kTypes) (t, t)], onSelected: (v) => setState(() => _type = v)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Giới tính', required: true),
                    _Select<CrabGender>(
                      valueLabel: _gender.label,
                      items: [for (final g in CrabGender.values) (g, g.label)],
                      onSelected: (v) => setState(() => _gender = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Cân nặng (g)', required: true),
                    _numField(_weight, '126', suffix: 'g'),
                  ],
                ),
              ),
            ],
          ),
          if (_weightError != null) _err(_weightError!),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Rộng mai (mm)', required: true),
                    _numField(_width, '60', suffix: 'mm'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Dài mai (mm)', required: true),
                    _numField(_length, '90', suffix: 'mm'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Sức khỏe ban đầu', required: true),
                    _Select<CrabDisplayHealth>(
                      valueLabel: _health.label,
                      items: [for (final h in _kHealth) (h, h.label)],
                      onSelected: (v) => setState(() => _health = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_sizeError != null) _err(_sizeError!),
        ],
        const SizedBox(height: 8),
        Text('Trạng thái dự kiến: Đang nuôi', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
        const SizedBox(height: 18),
        _step(4, 'Ngày bắt đầu nuôi'),
        const SizedBox(height: 8),
        _label('Ngày nhập hộp', required: true),
        InkWell(
          onTap: _saving ? null : _pickDate,
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
                Text(fmtDateVn(_enteredAt), style: bvText(fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Ngày cua được đưa vào hộp nuôi.', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        if (_dateError != null) _err(_dateError!),
        const SizedBox(height: 18),
        _step(5, 'Ảnh ban đầu'),
        const SizedBox(height: 8),
        CrabImageUpload(
          path: _imagePath,
          onPick: _saving ? null : _pickImage,
          onClear: _saving ? null : () => setState(() => _imagePath = null),
        ),
        const SizedBox(height: 18),
        _step(6, 'Ghi chú'),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          maxLength: 500,
          maxLines: 4,
          enabled: !_saving,
          onChanged: (_) => setState(() {}),
          style: bvText(color: DashboardColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú về tình trạng ban đầu của cua...',
            hintStyle: bvText(color: DashboardColors.textMuted),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardColors.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardColors.cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.brand, width: 1.4)),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text('${_note.text.length} / 500', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        ),
        if (_error != null && !_conflict)
          Padding(padding: const EdgeInsets.only(top: 8), child: _err(_error!)),
      ],
    );
  }

  Widget _areaSelect() => _Select<String>(
        valueLabel: () {
          for (final a in _areas) {
            if (a.id == _areaId) return '${a.areaCode} — ${a.areaName}';
          }
          return 'Chọn khu vực';
        }(),
        items: [for (final a in _areas) (a.id, '${a.areaCode} — ${a.areaName}')],
        onSelected: _onArea,
      );

  Widget _rowSelect() => _Select<String>(
        valueLabel: _rowsLoading ? 'Đang tải dãy…' : _rowLabel == '—' ? 'Chọn dãy' : _rowLabel,
        loading: _rowsLoading,
        items: [
          for (final r in _rows) (r.id, r.rowName.trim().isEmpty ? r.rowCode : r.rowName),
        ],
        onSelected: _onRow,
      );

  Widget _autoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hệ thống sẽ tự gán hộp trống phù hợp.', style: bvText(fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            'Hộp trống khả dụng: $_emptyCount hộp',
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
          if (_boxError != null) _err(_boxError!),
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
            decoration: BoxDecoration(
              color: DashboardColors.brand.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                const SizedBox(width: 8),
                Text('Đang tạo...', style: bvText(fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          )
        : MgmtPrimaryButton(label: 'Thêm cua', icon: Icons.check_rounded, onTap: _canSubmit ? _submit : null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [save, const SizedBox(height: 8), cancel])
          : Row(mainAxisAlignment: MainAxisAlignment.end, children: [cancel, const SizedBox(width: 10), save]),
    );
  }

  Widget _numField(TextEditingController c, String hint, {required String suffix}) {
    return TextField(
      controller: c,
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) => setState(() {}),
      style: bvText(color: DashboardColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintStyle: bvText(color: DashboardColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.brand, width: 1.4)),
      ),
    );
  }
}

class BatchQuickInfo extends StatelessWidget {
  const BatchQuickInfo({super.key, required this.lot});
  final FarmingBatchRecord lot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _kv('Ngày nhập', fmtDateVn(lot.startDate)),
          _kv('Tổng số lượng', '${lot.initialQuantity} con'),
          _kv('Đã tạo cá thể', '${lot.placedCount} con'),
          _kv('Còn lại', '${lot.remainingCount} con'),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Text.rich(
        TextSpan(
          text: '$k: ',
          style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          children: [TextSpan(text: v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))],
        ),
      );
}

class BoxAssignMode extends StatelessWidget {
  const BoxAssignMode({
    super.key,
    required this.auto,
    required this.onChanged,
    this.compact = false,
  });
  final bool auto;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _card(true, 'Tự động phân hộp trống', 'Hệ thống sẽ gán hộp đang hoạt động, trống và không có lỗi.'),
      _card(false, 'Chọn hộp thủ công', 'Tự chọn hộp cụ thể trong dãy.'),
    ];
    if (compact) {
      return Column(
        children: [cards[0], const SizedBox(height: 8), cards[1]],
      );
    }
    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
      ],
    );
  }

  Widget _card(bool value, String title, String sub) {
    final selected = auto == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? DashboardColors.lightMint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? DashboardColors.brand : DashboardColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: selected ? DashboardColors.brand : DashboardColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(sub, style: bvText(fontSize: 11.5, height: 1.35, color: DashboardColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TargetBoxPreview extends StatelessWidget {
  const TargetBoxPreview({super.key, required this.box, required this.ok});
  final BoxRecord box;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ok ? DashboardColors.mint : const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(box.boxCode, style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
              MgmtStatusBadge(label: ok ? 'Có thể sử dụng' : 'Không thể sử dụng', color: ok ? DashboardColors.brand : DashboardColors.risk),
            ],
          ),
          const SizedBox(height: 8),
          Text('Trạng thái: Đang hoạt động', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          Text('Cua hiện tại: ${box.hasCrab ? (box.crabTag ?? 'Đã có cua') : 'Không có'}', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          Text('Sức chứa: ${box.hasCrab ? '1 / 1' : '0 / 1'}', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          Text('Cảnh báo: ${box.alertCount}', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
        ],
      ),
    );
  }
}

class CrabIdentitySection extends StatelessWidget {
  const CrabIdentitySection({super.key, required this.code, required this.qr});
  final String code;
  final String qr;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.mint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mã cua (tự sinh)', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: DashboardColors.brand),
                    const SizedBox(width: 6),
                    Text(code, style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã cua được hệ thống tạo tự động sau khi lưu.',
                  style: bvText(fontSize: 11, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QR Code', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 16, color: DashboardColors.brand),
                    const SizedBox(width: 6),
                    Flexible(child: Text(qr, style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CrabImageUpload extends StatelessWidget {
  const CrabImageUpload({super.key, required this.path, this.onPick, this.onClear});
  final String? path;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (path != null) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(File(path!), width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: onClear, icon: Icon(Icons.close, color: DashboardColors.textMuted)),
        ],
      );
    }
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: DashboardColors.lightMint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.mint),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_camera_outlined, color: DashboardColors.brand),
            const SizedBox(height: 4),
            Text('Thêm ảnh cua', style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
            Text('JPG, PNG, tối đa 5MB', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class CrabCreateSummaryPanel extends StatelessWidget {
  const CrabCreateSummaryPanel({
    super.key,
    required this.lot,
    required this.autoAssign,
    required this.target,
    required this.targetOk,
    required this.emptyCount,
    required this.rowLabel,
  });

  final FarmingBatchRecord? lot;
  final bool autoAssign;
  final BoxRecord? target;
  final bool targetOk;
  final int emptyCount;
  final String rowLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _card(
          Icons.inventory_2_outlined,
          'Thông tin lô nhập',
          lot == null
              ? [Text('Chưa chọn lô.', style: bvText(color: DashboardColors.textMuted))]
              : [
                  _kv('Mã lô', lot!.batchCode),
                  _kv('Tên lô', lot!.lotName),
                  _kv('Ngày nhập', fmtDateVn(lot!.startDate)),
                  _kv('Tổng số lượng', '${lot!.initialQuantity} con'),
                  _kv('Đã tạo cá thể', '${lot!.placedCount} con'),
                  _kv('Còn lại', '${lot!.remainingCount} con'),
                ],
        ),
        const SizedBox(height: 10),
        _card(
          Icons.grid_view_rounded,
          'Thông tin hộp (dự kiến)',
          autoAssign
              ? [
                  Text(
                    'Hệ thống sẽ gán hộp trống phù hợp. Sau khi lưu, thông tin hộp sẽ được hiển thị tại Chi tiết cua.',
                    style: bvText(fontSize: 12.5, height: 1.4, color: DashboardColors.textMuted),
                  ),
                ]
              : target == null
                  ? [Text('Chưa chọn hộp.', style: bvText(color: DashboardColors.textMuted))]
                  : [
                      _kv('Hộp', target!.boxCode),
                      _kv('Trạng thái', targetOk ? 'Có thể sử dụng' : 'Không thể sử dụng'),
                      _kv('Cua hiện tại', target!.hasCrab ? (target!.crabTag ?? 'Đã có cua') : 'Không có'),
                    ],
        ),
        const SizedBox(height: 10),
        _card(
          Icons.info_outline_rounded,
          'Quy tắc & Lưu ý',
          [
            _b('Chỉ chọn hộp đang hoạt động và chưa có cua.'),
            _b('Mỗi hộp chỉ chứa 1 cua.'),
            _b('Mã cua và QR do hệ thống tự tạo.'),
            _b('Cân nặng dùng gram (g).'),
            _b('Kích thước dùng millimet (mm).'),
            _b('Sau khi lưu, thông tin sẽ xuất hiện trong Lịch sử & Nhật ký.'),
            _b('Nếu lô đã tạo đủ số lượng cá thể, không thể thêm cua mới.'),
          ],
        ),
        const SizedBox(height: 10),
        _card(
          Icons.speed_outlined,
          'Chỉ tiêu nhanh',
          [
            _kv('Còn lại trong lô', '${lot?.remainingCount ?? 0} con'),
            _kv('Hộp trống khả dụng ($rowLabel)', '$emptyCount hộp'),
            _kv('Trạng thái dự kiến', 'Đang nuôi'),
          ],
        ),
      ],
    );
  }

  Widget _card(IconData icon, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: DashboardColors.brand),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: bvText(fontSize: 13.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 108, child: Text(k, style: bvText(fontSize: 12, color: DashboardColors.textMuted))),
            Expanded(child: Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary))),
          ],
        ),
      );

  Widget _b(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('•  $t', style: bvText(fontSize: 12, height: 1.35, color: DashboardColors.textMuted)),
      );
}

class _Select<T> extends StatelessWidget {
  const _Select({
    required this.valueLabel,
    required this.items,
    required this.onSelected,
    this.loading = false,
    this.enabledOf,
  });

  final String valueLabel;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;
  final bool loading;
  final bool Function(T value)? enabledOf;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: '',
      enabled: !loading && items.isNotEmpty,
      offset: const Offset(0, 42),
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
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(valueLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
            ),
            if (loading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.keyboard_arrow_down_rounded, color: DashboardColors.textMuted),
          ],
        ),
      ),
    );
  }
}

Widget _step(int n, String title) => Text(
      '$n. $title',
      style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
    );

Widget _label(String text, {bool required = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
          children: [
            if (required) TextSpan(text: ' *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.risk)),
          ],
        ),
      ),
    );

Widget _err(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: bvText(fontSize: 12.5, color: DashboardColors.risk)),
    );

class _EscIntent extends Intent {
  const _EscIntent();
}

class _AddCrabSkeleton extends StatelessWidget {
  const _AddCrabSkeleton({required this.wide});
  final bool wide;

  Widget _bar({double h = 42, double? w}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: DashboardColors.lightMint,
          borderRadius: BorderRadius.circular(10),
        ),
      );

  Widget _card() => Container(
        height: 120,
        decoration: BoxDecoration(
          color: DashboardColors.lightMint,
          borderRadius: BorderRadius.circular(14),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(h: 16, w: 88),
        const SizedBox(height: 10),
        _bar(),
        const SizedBox(height: 10),
        _bar(h: 64),
        const SizedBox(height: 18),
        _bar(h: 16, w: 110),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: _bar()), const SizedBox(width: 10), Expanded(child: _bar())]),
        const SizedBox(height: 18),
        _bar(h: 16, w: 140),
        const SizedBox(height: 10),
        _bar(h: 88),
      ],
    );
    final side = Column(
      children: [_card(), const SizedBox(height: 10), _card(), const SizedBox(height: 10), _card()],
    );
    if (!wide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(children: [form, const SizedBox(height: 14), side]),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 70, child: Padding(padding: const EdgeInsets.fromLTRB(22, 16, 12, 16), child: form)),
        Container(width: 1, color: DashboardColors.mint),
        Expanded(flex: 30, child: Padding(padding: const EdgeInsets.fromLTRB(14, 16, 16, 16), child: side)),
      ],
    );
  }
}
