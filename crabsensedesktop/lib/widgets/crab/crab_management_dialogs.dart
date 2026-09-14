import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_crab_data.dart';
import '../../models/crab_individual.dart';
import '../../models/crab_status.dart';
import '../../models/production_models.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';

const _autoBoxValue = '__auto_empty_box__';

const _createConditions = <(String, String)>[
  ('normal', 'Bình thường'),
  ('premolt', 'Sắp lột'),
  ('molting', 'Đang lột'),
  ('softshell', 'Cua lột mềm'),
  ('problem', 'Có vấn đề'),
];

Future<void> showCrabManagementFormDialog(
  BuildContext context,
  CrabService service, {
  CrabIndividual? existing,
  String? initialLotId,
}) async {
  if (existing == null) {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddCrabFormDialog(
        service: service,
        initialLotId: initialLotId,
      ),
    );
    return;
  }

  final formKey = GlobalKey<FormState>();
  final codeCtrl = TextEditingController(text: existing.code);
  final weightCtrl = TextEditingController(text: existing.weightGram.toStringAsFixed(0));
  final shellCtrl = TextEditingController(
    text: existing.shellSizeCm > 0 ? existing.shellSizeCm.toStringAsFixed(1) : '',
  );
  final lengthCtrl = TextEditingController(
    text: existing.carapaceLengthMm > 0 ? existing.carapaceLengthMm.toStringAsFixed(1) : '',
  );
  final noteCtrl = TextEditingController(text: existing.quickNote);
  var gender = existing.gender;
  var health = existing.healthStatus;
  var life = existing.lifeStatus;
  var stage = existing.developmentStage;

  if (!context.mounted) return;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: DashboardColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cập nhật Cua',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _readOnlyTile('Lô cua', existing.batchId),
                  _readOnlyTile('Mã cua', existing.code),
                  _enumDropdown('Giới tính', gender, CrabGender.values, (v) => setS(() => gender = v!), (g) => g.label),
                  _field(weightCtrl, 'Cân nặng (g)', required: true, keyboard: TextInputType.number),
                  _field(lengthCtrl, 'Bề ngang mai (mm)', required: true, keyboard: const TextInputType.numberWithOptions(decimal: true)),
                  _field(shellCtrl, 'Bề rộng mai (mm)', required: true, keyboard: const TextInputType.numberWithOptions(decimal: true)),
                  _enumDropdown('Giai đoạn phát triển', stage, CrabDevelopmentStage.values, (v) => setS(() => stage = v!), (s) => s.label),
                  _enumDropdown('Tình trạng sức khỏe', health, CrabHealthStatus.values, (v) => setS(() => health = v!), (s) => s.label),
                  _enumDropdown('Trạng thái', life, CrabLifeStatus.values, (v) => setS(() => life = v!), (s) => s.label),
                  _field(noteCtrl, 'Ghi chú', maxLines: 2),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.oceanBlue),
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );

  if (ok != true || !context.mounted) return;

  final weight = double.tryParse(weightCtrl.text) ?? existing.weightGram;
  final shell = double.tryParse(shellCtrl.text) ?? existing.shellSizeCm;
  final length = double.tryParse(lengthCtrl.text) ?? existing.carapaceLengthMm;
  final note = noteCtrl.text.trim();

  final success = await service.updateCrab(
    existing.copyWith(
      gender: gender,
      weightGram: weight,
      shellSizeCm: shell,
      carapaceLengthMm: length,
      developmentStage: stage,
      healthStatus: health,
      lifeStatus: life,
      quickNote: note,
      updatedAt: DateTime.now(),
    ),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã cập nhật cua' : (service.error ?? 'Lỗi lưu cua')),
      ),
    );
  }
}

class _AddCrabFormDialog extends StatefulWidget {
  const _AddCrabFormDialog({required this.service, this.initialLotId});

  final CrabService service;
  final String? initialLotId;

  @override
  State<_AddCrabFormDialog> createState() => _AddCrabFormDialogState();
}

class _AddCrabFormDialogState extends State<_AddCrabFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _typeCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _shellCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _initialCtrl = TextEditingController(text: 'Khỏe mạnh');
  final _noteCtrl = TextEditingController();

  List<CrabBatchChoice> _lots = [];
  List<RowRecord> _rows = [];
  List<BoxRecord> _emptyBoxes = [];

  CrabBatchChoice? _lot;
  String? _areaId;
  String? _rowId;
  String _boxId = _autoBoxValue;
  CrabGender _gender = CrabGender.unknown;
  String _condition = 'normal';
  DateTime _stockedAt = DateTime.now();
  String _code = 'CRAB-…';
  String _qr = 'QR-CRAB-…';
  final List<String> _imagePaths = [];
  var _loading = true;
  var _saving = false;
  String? _loadError;

  CrabService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _weightCtrl.dispose();
    _shellCtrl.dispose();
    _lengthCtrl.dispose();
    _initialCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    var lots = List<CrabBatchChoice>.from(_svc.batchChoices);
    if (lots.isEmpty) {
      await _svc.refreshLots();
      lots = List<CrabBatchChoice>.from(_svc.batchChoices);
    }
    if (lots.isEmpty) {
      setState(() {
        _loading = false;
        _loadError = 'Chưa có lô cua. Hãy Nhập lô trước khi phân cua vào hộp.';
      });
      return;
    }

    final next = await _svc.peekNextCrabIdentity();
    final defaultArea = _svc.farmId.isEmpty ? null : _svc.farmId;

    CrabBatchChoice? selected;
    final prefer = widget.initialLotId;
    if (prefer != null) {
      for (final lot in lots) {
        if (lot.batchId == prefer) {
          selected = lot;
          break;
        }
      }
    }

    setState(() {
      _lots = lots;
      _lot = selected ?? lots.first;
      _areaId = defaultArea;
      _code = next?.code ?? 'CRAB-0001';
      _qr = next?.qrCode ?? 'QR-CRAB-0001';
      _loading = false;
    });
    if (defaultArea != null) await _loadRows(defaultArea);
  }

  Future<void> _loadRows(String areaId) async {
    try {
      final rows = await _svc.fetchRows(areaId);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _rowId = null;
        _boxId = _autoBoxValue;
      });
      await _loadBoxes(areaId: areaId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = '$e');
    }
  }

  Future<void> _loadBoxes({String? areaId, String? rowId}) async {
    try {
      final boxes = await _svc.fetchEmptyBoxes(areaId: areaId, rowId: rowId);
      if (!mounted) return;
      setState(() {
        _emptyBoxes = boxes;
        if (_boxId != _autoBoxValue && !boxes.any((b) => b.id == _boxId)) {
          _boxId = _autoBoxValue;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _emptyBoxes = []);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _lot == null) return;
    final weight = double.tryParse(_weightCtrl.text);
    final width = double.tryParse(_shellCtrl.text);
    final length = double.tryParse(_lengthCtrl.text);
    if (weight == null || weight <= 0 || width == null || width <= 0 || length == null || length <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cân nặng, bề ngang và bề rộng mai phải lớn hơn 0')),
      );
      return;
    }
    final areaId = _areaId ?? _svc.farmId;
    if (areaId.isEmpty && _boxId == _autoBoxValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn khu hoặc hộp để thả cua')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await _svc.addCrab(
      batchId: _lot!.batchId,
      gender: _gender,
      weightGram: weight,
      carapaceWidthMm: width,
      carapaceLengthMm: length,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      boxId: _boxId == _autoBoxValue ? null : _boxId,
      farmingAreaId: areaId.isEmpty ? null : areaId,
      farmingRowId: _rowId,
      crabType: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
      initialCondition: _initialCtrl.text.trim().isEmpty
          ? 'Khỏe mạnh'
          : _initialCtrl.text.trim(),
      condition: _condition,
      stockedAt: _stockedAt,
      imagePaths: _imagePaths,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_svc.error ?? 'Lỗi lưu cua')),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm cua $_code')),
    );
  }

  Future<void> _pickImages() async {
    final remain = 10 - _imagePaths.length;
    if (remain <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 10 ảnh mỗi lần thả')),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'],
      allowMultiple: true,
    );
    if (result == null) return;
    final added = <String>[];
    for (final f in result.files) {
      final path = f.path;
      if (path == null || path.isEmpty) continue;
      if (_imagePaths.contains(path) || added.contains(path)) continue;
      added.add(path);
      if (_imagePaths.length + added.length >= 10) break;
    }
    if (added.isEmpty) return;
    setState(() => _imagePaths.addAll(added.take(remain)));
  }

  Widget _photoPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ảnh cua',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: DashboardColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _imagePaths.length; i++)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_imagePaths[i]),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: InkWell(
                        onTap: _saving
                            ? null
                            : () => setState(() => _imagePaths.removeAt(i)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_imagePaths.length < 10)
                InkWell(
                  onTap: _saving ? null : _pickImages,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: DashboardColors.darkNavy.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DashboardColors.textMuted.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: DashboardColors.cyan, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          'Thêm',
                          style: GoogleFonts.notoSans(
                            fontSize: 11,
                            color: DashboardColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tối đa 10 ảnh · jpeg, png, webp · tải lên khi Thả nuôi',
            style: GoogleFonts.notoSans(
              fontSize: 11,
              color: DashboardColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Thêm Cua',
        style: GoogleFonts.notoSans(
          color: DashboardColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 520,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_loadError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _loadError!,
                            style: GoogleFonts.notoSans(color: DashboardColors.risk),
                          ),
                        ),
                      if (_lots.isNotEmpty)
                        _dropdown(
                          'Lô cua',
                          _lot!.batchId,
                          _lots.map((b) => b.batchId).toList(),
                          (v) {
                            setState(() {
                              _lot = _lots.firstWhere(
                                (b) => b.batchId == v,
                                orElse: () => _lots.first,
                              );
                            });
                          },
                          labels: {for (final b in _lots) b.batchId: b.label},
                        ),
                      _dropdown(
                        'Dãy (tuỳ chọn)',
                        _rowId ?? '',
                        ['', ..._rows.map((r) => r.id)],
                        (v) {
                          setState(() => _rowId = (v == null || v.isEmpty) ? null : v);
                          _loadBoxes(areaId: _areaId, rowId: v);
                        },
                        labels: {
                          '': 'Tất cả dãy — tự gán hộp trống',
                          for (final r in _rows)
                            r.id: '${r.rowCode} — ${r.rowName}',
                        },
                      ),
                      _dropdown(
                        'Hộp',
                        _boxId,
                        [_autoBoxValue, ..._emptyBoxes.map((b) => b.id)],
                        (v) => setState(() => _boxId = v ?? _autoBoxValue),
                        labels: {
                          _autoBoxValue: _emptyBoxes.isEmpty
                              ? 'Tự gán hộp trống (chưa có hộp trống)'
                              : 'Tự gán hộp trống tiếp theo',
                          for (final b in _emptyBoxes)
                            b.id: b.title,
                        },
                      ),
                      _readOnlyTile('Mã cua (tự sinh)', _code),
                      _readOnlyTile('QR', _qr),
                      _field(_typeCtrl, 'Loại cua'),
                      _enumDropdown(
                        'Giới tính',
                        _gender,
                        CrabGender.values,
                        (v) => setState(() => _gender = v!),
                        (g) => g.label,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Ngày thả',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: DashboardColors.textMuted,
                          ),
                        ),
                        subtitle: Text(MockCrabData.formatDate(_stockedAt)),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today_outlined, size: 18),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _stockedAt,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                            );
                            if (d != null) setState(() => _stockedAt = d);
                          },
                        ),
                      ),
                      _field(_weightCtrl, 'Cân nặng (g)', required: true, keyboard: TextInputType.number),
                      _field(
                        _lengthCtrl,
                        'Bề ngang mai (mm)',
                        required: true,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      _field(
                        _shellCtrl,
                        'Bề rộng mai (mm)',
                        required: true,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      _field(_initialCtrl, 'Tình trạng ban đầu'),
                      _dropdown(
                        'Tình trạng cua',
                        _condition,
                        _createConditions.map((e) => e.$1).toList(),
                        (v) => setState(() => _condition = v ?? 'normal'),
                        labels: {for (final e in _createConditions) e.$1: e.$2},
                      ),
                      _photoPicker(),
                      _field(_noteCtrl, 'Ghi chú', maxLines: 2),
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
          onPressed: _saving || _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.oceanBlue),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Thả nuôi'),
        ),
      ],
    );
  }
}

Future<void> showRecordHealthDialog(
  BuildContext context,
  CrabService service,
  CrabIndividual crab,
) async {
  final formKey = GlobalKey<FormState>();
  final weightCtrl = TextEditingController(text: crab.weightGram.toStringAsFixed(0));
  final shellCtrl = TextEditingController(text: crab.shellSizeCm.toStringAsFixed(1));
  final shellCondCtrl = TextEditingController(text: 'Bình thường');
  final diseaseCtrl = TextEditingController(text: 'Không');
  final noteCtrl = TextEditingController();
  var recordedAt = DateTime.now();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Ghi nhận sức khỏe', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(weightCtrl, 'Cân nặng hiện tại (g)', keyboard: TextInputType.number),
              _field(shellCtrl, 'Kích thước mai hiện tại (cm)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
              _field(shellCondCtrl, 'Tình trạng mai'),
              _field(diseaseCtrl, 'Tình trạng bệnh'),
              _field(noteCtrl, 'Ghi chú', maxLines: 2),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Thời gian ghi nhận', style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.textMuted)),
                subtitle: Text(MockCrabData.formatDate(recordedAt)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: recordedAt,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (d != null) {
                      recordedAt = DateTime(d.year, d.month, d.day, recordedAt.hour, recordedAt.minute);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(ctx, true);
          },
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.seaGreen),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );

  if (ok == true) {
    final success = await service.recordHealth(
      crab.id,
      weightGram: double.tryParse(weightCtrl.text) ?? crab.weightGram,
      shellSizeCm: double.tryParse(shellCtrl.text) ?? crab.shellSizeCm,
      shellCondition: shellCondCtrl.text.trim(),
      diseaseNote: diseaseCtrl.text.trim(),
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      recordedAt: recordedAt,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Đã ghi nhận sức khỏe' : (service.error ?? 'Lỗi')),
        ),
      );
    }
  }
}

Future<void> showRecordMoltDialog(
  BuildContext context,
  CrabService service,
  CrabIndividual crab,
) async {
  final noteCtrl = TextEditingController();
  var moltDate = DateTime.now();
  var moltCount = crab.moltCount + 1;
  var condition = MoltCondition.normal;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: Text('Ghi nhận lột xác', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày lột xác'),
                subtitle: Text(MockCrabData.formatDate(moltDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: moltDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setS(() => moltDate = d);
                  },
                ),
              ),
              _dropdown(
                'Số lần lột xác',
                '$moltCount',
                List.generate(8, (i) => '${i + 1}'),
                (v) => setS(() => moltCount = int.parse(v!)),
              ),
              _enumDropdown('Tình trạng sau lột', condition, MoltCondition.values, (v) => setS(() => condition = v!), (c) => c.label),
              _field(noteCtrl, 'Ghi chú', maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.molting),
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );

  if (ok == true) {
    final success = await service.recordMolt(
      crab.id,
      date: moltDate,
      moltCount: moltCount,
      condition: condition,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã ghi nhận lột xác. Xuất cua lột ở Thu hoạch & Bán hàng hoặc menu cua.'
                : (service.error ?? 'Lỗi'),
          ),
        ),
      );
    }
  }
}

Future<bool> confirmCrabAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(title, style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: Text(message, style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: danger ? DashboardColors.risk : DashboardColors.oceanBlue,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r == true;
}

Widget _readOnlyTile(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.35),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        value,
        style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 13),
      ),
    ),
  );
}

Widget _field(
  TextEditingController ctrl,
  String label, {
  bool required = false,
  int maxLines = 1,
  TextInputType? keyboard,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null
          : null,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

Widget _dropdown(
  String label,
  String value,
  List<String> items,
  ValueChanged<String?> onChanged, {
  Map<String, String>? labels,
}) {
  final opts = <String>[];
  final seen = <String>{};
  for (final e in items) {
    if (seen.add(e)) opts.add(e);
  }
  if (opts.isEmpty) return const SizedBox.shrink();
  final selected = opts.contains(value) ? value : opts.first;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      value: selected,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dropdownColor: DashboardColors.card,
      items: opts
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                labels?[e] ?? e,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}

Widget _enumDropdown<T>(
  String label,
  T value,
  List<T> items,
  ValueChanged<T?> onChanged,
  String Function(T) labelOf,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dropdownColor: DashboardColors.card,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                labelOf(e),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}
