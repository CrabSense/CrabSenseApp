import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/harvest_sales.dart';
import '../../services/cloud_api_client.dart';
import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';
import 'harvest_tab_widgets.dart';

const _kOverlay = Color.fromRGBO(15, 35, 30, 0.45);
const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kBlue = Color(0xFF2495E8);
const _kMaxPhotos = 5;
const _kMaxPhotoBytes = 5 * 1024 * 1024;
const _kNoteMax = 500;
const _kDeltaWarnRatio = 0.25;

const _grades = <(String, String)>[
  ('A', 'Loại 1'),
  ('B', 'Loại 2'),
  ('C', 'Loại 3'),
];

String _gradeLabel(String code) {
  for (final (v, label) in _grades) {
    if (v == code) return label;
  }
  return code;
}

String _productLabel(HarvestProductType t) => switch (t) {
      HarvestProductType.softshell => 'Cua lột',
      HarvestProductType.other => 'Khác',
      _ => 'Cua thịt',
    };

HarvestProductType _productOf(bool softshell, HarvestProductType fallback) =>
    softshell ? HarvestProductType.softshell : fallback;

class _EscIntent extends Intent {
  const _EscIntent();
}

class _HarvestPhoto {
  const _HarvestPhoto({required this.name, this.path});
  final String name;
  final String? path;
  bool get hasPreview => path != null && path!.isNotEmpty;
}

Future<void> showCreateHarvestModal(
  BuildContext context,
  HarvestSalesService service, {
  bool softshellMode = false,
  List<HarvestableCrab>? initialCrabs,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: _kOverlay,
    builder: (_) => CreateHarvestModal(
      service: service,
      softshellMode: softshellMode,
      initialCrabs: initialCrabs ?? const [],
    ),
  );
}

class CreateHarvestModal extends StatefulWidget {
  const CreateHarvestModal({
    super.key,
    required this.service,
    this.softshellMode = false,
    this.initialCrabs = const [],
  });

  final HarvestSalesService service;
  final bool softshellMode;
  final List<HarvestableCrab> initialCrabs;

  @override
  State<CreateHarvestModal> createState() => _CreateHarvestModalState();
}

class _CreateHarvestModalState extends State<CreateHarvestModal> {
  late DateTime _when;
  late final TextEditingController _note;
  late final TextEditingController _otherProduct;
  final _selected = <HarvestableCrab>[];
  final _gradesById = <String, String>{};
  final _productById = <String, HarvestProductType>{};
  final _weights = <String, TextEditingController>{};
  final _photos = <_HarvestPhoto>[];
  var _saving = false;
  var _submittingCreate = false;
  String? _error;

  HarvestProductType _product = HarvestProductType.meat;
  String _gradeAll = 'A';

  HarvestSalesService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _when = DateTime.now();
    _note = TextEditingController();
    _otherProduct = TextEditingController();
    _product = widget.softshellMode
        ? HarvestProductType.softshell
        : HarvestProductType.meat;
    for (final c in widget.initialCrabs.where((e) => e.canSelect)) {
      _addCrab(c);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _otherProduct.dispose();
    for (final c in _weights.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCrab(HarvestableCrab c) {
    if (_selected.any((e) => e.id == c.id)) return;
    _selected.add(c);
    _gradesById.putIfAbsent(c.id, () => _gradeAll);
    _productById.putIfAbsent(
      c.id,
      () => _product == HarvestProductType.other
          ? HarvestProductType.meat
          : _product,
    );
    _weights.putIfAbsent(c.id, () => TextEditingController());
  }

  void _removeCrab(String id) {
    _selected.removeWhere((e) => e.id == id);
    _gradesById.remove(id);
    _productById.remove(id);
    _weights.remove(id)?.dispose();
  }

  int? _actualOf(HarvestableCrab c) {
    final raw = _weights[c.id]?.text.trim() ?? '';
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  int? _deltaOf(HarvestableCrab c) {
    final actual = _actualOf(c);
    if (actual == null) return null;
    return actual - c.weightG;
  }

  bool _deltaWarn(HarvestableCrab c) {
    final d = _deltaOf(c);
    if (d == null || c.weightG <= 0) return false;
    return d.abs() / c.weightG > _kDeltaWarnRatio;
  }

  int get _missingActual =>
      _selected.where((c) => (_actualOf(c) ?? 0) <= 0).length;

  int get _expectedG => _selected.fold<int>(0, (s, c) => s + c.weightG);

  int get _actualG => _selected.fold<int>(0, (s, c) => s + (_actualOf(c) ?? 0));

  bool get _actualComplete =>
      _selected.isNotEmpty && _missingActual == 0;

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _when.isAfter(now) ? now : _when,
      firstDate: DateTime(2024),
      lastDate: now,
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (!mounted) return;
    var next = DateTime(
      d.year,
      d.month,
      d.day,
      t?.hour ?? _when.hour,
      t?.minute ?? _when.minute,
    );
    if (next.isAfter(DateTime.now())) next = DateTime.now();
    setState(() => _when = next);
  }

  Future<void> _pickCrabs() async {
    final chosen = await showDialog<Set<String>>(
      context: context,
      barrierColor: _kOverlay,
      builder: (_) => SelectHarvestCrabsDialog(
        crabs: _svc.harvestableCrabs,
        already: _selected.map((c) => c.id).toSet(),
        softshellOnly: widget.softshellMode,
      ),
    );
    if (chosen == null) return;
    setState(() {
      for (final c in _svc.harvestableCrabs) {
        if (chosen.contains(c.id)) _addCrab(c);
      }
      final drop = _selected.where((c) => !chosen.contains(c.id)).toList();
      for (final c in drop) {
        _removeCrab(c.id);
      }
    });
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= _kMaxPhotos) {
      setState(() => _error = 'Tối đa $_kMaxPhotos ảnh thu hoạch.');
      return;
    }
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (picked == null) return;
    setState(() => _error = null);
    for (final f in picked.files) {
      if (_photos.length >= _kMaxPhotos) break;
      if (f.size > _kMaxPhotoBytes) {
        setState(() => _error = '${f.name} vượt 5MB / ảnh.');
        continue;
      }
      final ext = (f.extension ?? '').toLowerCase();
      if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
        setState(() => _error = 'Chỉ nhận JPG hoặc PNG.');
        continue;
      }
      _photos.add(_HarvestPhoto(name: f.name, path: f.path));
    }
    if (mounted) setState(() {});
  }

  Future<void> _openPhoto(_HarvestPhoto p) async {
    await showDialog<void>(
      context: context,
      barrierColor: _kOverlay,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920, maxHeight: 720),
              child: _photoImage(p, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoImage(_HarvestPhoto p, {BoxFit fit = BoxFit.cover}) {
    if (p.path != null && p.path!.isNotEmpty) {
      return Image.file(
        File(p.path!),
        fit: fit,
        errorBuilder: (_, error, stackTrace) => _photoFallback(),
      );
    }
    return _photoFallback();
  }

  Widget _photoFallback() => const ColoredBox(
        color: DashboardColors.lightMint,
        child: Icon(Icons.image_outlined, color: DashboardColors.brand),
      );

  String? _validateDraft() {
    if (_svc.areaId.isEmpty) return 'Thiếu khu vực.';
    if (_svc.performerName.trim().isEmpty) return 'Thiếu người thực hiện.';
    if (_product == HarvestProductType.other &&
        _otherProduct.text.trim().isEmpty) {
      return 'Nhập mô tả loại sản phẩm khác.';
    }
    return null;
  }

  String? _validateCreate() {
    final draft = _validateDraft();
    if (draft != null) return draft;
    if (_selected.isEmpty) return 'Chọn ít nhất một con cua.';
    if (_selected.any((c) => !c.canSelect)) {
      final bad = _selected.firstWhere((c) => !c.canSelect);
      return bad.disableReason;
    }
    if (_missingActual > 0) {
      return 'Còn $_missingActual cua chưa nhập trọng lượng thực tế.';
    }
    for (final c in _selected) {
      if ((_gradesById[c.id] ?? '').isEmpty) {
        return '${c.code} chưa có phân loại.';
      }
    }
    return null;
  }

  String _composedNote() {
    final extra = _product == HarvestProductType.other
        ? _otherProduct.text.trim()
        : '';
    final note = _note.text.trim();
    if (extra.isEmpty) return note;
    if (note.isEmpty) return 'Loại khác: $extra';
    return 'Loại khác: $extra\n$note';
  }

  Future<List<String>> _uploadPhotos() async {
    final urls = <String>[];
    for (final p in _photos) {
      final path = p.path;
      if (path == null || path.isEmpty) continue;
      final url = await _svc.uploadPhoto(path);
      if (url != null && url.startsWith('http')) urls.add(url);
    }
    return urls;
  }

  Future<void> _submit({required bool draft}) async {
    if (_saving) return;
    final err = draft ? _validateDraft() : _validateCreate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _saving = true;
      _submittingCreate = !draft;
      _error = null;
    });
    try {
      final photos = await _uploadPhotos();
      final code = await _svc.createHarvestFromCrabs(
        harvestDate: _when,
        performedBy: _svc.performerName,
        note: _composedNote().isEmpty ? null : _composedNote(),
        crabs: _selected,
        grades: _gradesById,
        conditions: {for (final c in _selected) c.id: c.condition},
        weights: {
          for (final c in _selected) c.id: _actualOf(c) ?? 0,
        },
        results: {
          for (final c in _selected)
            c.id: c.eligibility == HarvestEligibility.eligible
                ? 'passed'
                : 'review',
        },
        softshell: {
          for (final c in _selected)
            c.id: (_productById[c.id] ?? _product) ==
                HarvestProductType.softshell,
        },
        photoUrls: photos,
        status: draft ? 'Planned' : 'InProgress',
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            draft
                ? '✓ Đã lưu $code dưới dạng nháp.'
                : '✓ Đã tạo phiếu $code thành công.',
          ),
        ),
      );
    } on CloudApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submittingCreate = false;
        _error = _mapCreateError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submittingCreate = false;
        _error = '⚠ Không thể tạo phiếu thu hoạch.\n$e';
      });
    }
  }

  String _mapCreateError(CloudApiException e) {
    final msg = e.message;
    final occupied = msg.contains('another harvest') ||
        msg.contains('already been recorded') ||
        msg.contains('phiếu thu hoạch khác');
    if (e.statusCode == 409 || occupied) {
      final match = RegExp(r"Crab '([^']+)'").firstMatch(msg);
      final id = match?.group(1);
      final crab = id == null
          ? null
          : _selected.cast<HarvestableCrab?>().firstWhere(
                (c) => c!.id == id || c.code == id,
                orElse: () => null,
              );
      final label = crab?.code ?? id ?? 'Cua đã chọn';
      return '⚠ $label vừa được thêm vào phiếu thu hoạch khác.\nVui lòng làm mới danh sách.';
    }
    return '⚠ Không thể tạo phiếu thu hoạch.\n$msg';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 860;
    final width = size.width < 1100 ? size.width - 24 : 1220.0;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 20,
        vertical: compact ? 8 : 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width.clamp(320, 1250),
          maxHeight: size.height * 0.92,
        ),
        child: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.escape): const _EscIntent(),
          },
          child: Actions(
            actions: {
              _EscIntent: CallbackAction<_EscIntent>(onInvoke: (_) {
                if (!_saving) Navigator.pop(context);
                return null;
              }),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  _header(),
                  const Divider(height: 1, color: DashboardColors.mint),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 22,
                        16,
                        compact ? 14 : 22,
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            _errorBanner(_error!),
                            const SizedBox(height: 14),
                          ],
                          _basicInfo(compact),
                          const SizedBox(height: 22),
                          _crabSection(compact),
                          const SizedBox(height: 16),
                          _summary(),
                          const SizedBox(height: 22),
                          _photosSection(),
                          const SizedBox(height: 18),
                          _noteSection(),
                        ],
                      ),
                    ),
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: DashboardColors.brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.softshellMode
                      ? 'Xuất cua lột'
                      : 'Tạo phiếu thu hoạch',
                  style: bvText(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ghi nhận số liệu thực tế khi thu hoạch cua.',
                  style: bvText(
                    fontSize: 12,
                    color: DashboardColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Mã phiếu',
                style: bvText(fontSize: 11, color: DashboardColors.textMuted),
              ),
              Text(
                _svc.nextVoucherPreview,
                style: bvText(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const MgmtStatusBadge(label: 'Nháp', color: _kAmber),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _basicInfo(bool compact) {
    final fields = <Widget>[
      _labeled(
        'Khu vực *',
        _readonlyField(
          _svc.areaLabel.isEmpty ? '—' : _svc.areaLabel,
          Icons.home_outlined,
        ),
        helper: 'Theo khu đang chọn trên thanh trên.',
      ),
      _labeled(
        'Ngày giờ thu hoạch *',
        _tapField(
          formatHarvestDateTime(_when),
          Icons.calendar_today_outlined,
          _saving ? null : _pickWhen,
        ),
      ),
      _labeled(
        'Người thực hiện *',
        _readonlyField(
          _svc.performerName.isEmpty ? '—' : _svc.performerName,
          Icons.person_outline_rounded,
        ),
      ),
      _labeled(
        'Loại sản phẩm *',
        MgmtDropdown<HarvestProductType>(
          valueLabel: _productLabel(_product),
          leading: Icons.set_meal_outlined,
          items: const [
            (HarvestProductType.meat, 'Cua thịt'),
            (HarvestProductType.softshell, 'Cua lột'),
            (HarvestProductType.other, 'Khác'),
          ],
          onSelected: (v) => setState(() {
            _product = v;
            for (final c in _selected) {
              _productById[c.id] = v == HarvestProductType.other
                  ? HarvestProductType.meat
                  : v;
            }
          }),
        ),
      ),
      _labeled(
        'Phân loại mặc định *',
        MgmtDropdown<String>(
          valueLabel: _gradeLabel(_gradeAll),
          leading: Icons.sell_outlined,
          items: _grades,
          onSelected: (v) => setState(() => _gradeAll = v),
        ),
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (final f in fields) ...[
            f,
            const SizedBox(height: 10),
          ],
          if (_product == HarvestProductType.other) _otherProductField(),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 14),
            Expanded(child: fields[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: fields[2]),
            const SizedBox(width: 14),
            Expanded(child: fields[3]),
            const SizedBox(width: 14),
            Expanded(child: fields[4]),
          ],
        ),
        if (_product == HarvestProductType.other) ...[
          const SizedBox(height: 12),
          _otherProductField(),
        ],
      ],
    );
  }

  Widget _otherProductField() {
    return _labeled(
      'Mô tả loại khác *',
      TextField(
        controller: _otherProduct,
        onChanged: (_) => setState(() {}),
        style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
        decoration: _inputDeco('Nhập mô tả loại sản phẩm...'),
      ),
    );
  }

  Widget _crabSection(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Danh sách cua',
              style: bvText(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: DashboardColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            _countChip('${_selected.length}'),
            const Spacer(),
            MgmtOutlineButton(
              onTap: _saving ? null : _pickCrabs,
              icon: Icons.add_rounded,
              label: 'Chọn cua',
            ),
            const SizedBox(width: 8),
            MgmtOutlineButton(
              onTap: _saving || _selected.isEmpty
                  ? null
                  : () => setState(() {
                        for (final c in _selected) {
                          _gradesById[c.id] = _gradeAll;
                        }
                      }),
              icon: Icons.done_all_rounded,
              label: 'Áp dụng mặc định cho tất cả',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Chọn nhiều cua cùng lúc. Mỗi con lưu trọng lượng thực tế và phân loại riêng.',
          style: bvText(fontSize: 12, color: DashboardColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (_selected.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Text(
              'Chưa chọn cua. Bấm “Chọn cua” để thêm vào phiếu.',
              textAlign: TextAlign.center,
              style: bvText(color: DashboardColors.textMuted),
            ),
          )
        else if (compact)
          Column(
            children: [
              for (var i = 0; i < _selected.length; i++)
                _crabCard(i, _selected[i]),
            ],
          )
        else
          _crabTable(),
      ],
    );
  }

  Widget _crabTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1080),
            child: Column(
              children: [
                _tableHeader(),
                for (var i = 0; i < _selected.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: DashboardColors.mint),
                  _tableRow(i, _selected[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    const labels = [
      '#',
      'Mã cua',
      'Hộp',
      'KL gần nhất',
      'Trọng lượng thực tế *',
      'Chênh lệch',
      'Loại sản phẩm',
      'Phân loại *',
      'Tình trạng',
      'Thao tác',
    ];
    const widths = [36.0, 168.0, 110.0, 110.0, 168.0, 100.0, 140.0, 130.0, 150.0, 56.0];
    return Container(
      color: DashboardColors.lightMint,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            SizedBox(
              width: widths[i],
              child: Text(
                labels[i],
                style: bvText(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableRow(int index, HarvestableCrab c) {
    final delta = _deltaOf(c);
    final warn = _deltaWarn(c);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '${index + 1}',
                  style: bvText(
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textMuted,
                  ),
                ),
              ),
              SizedBox(width: 168, child: _crabIdentity(c)),
              SizedBox(
                width: 110,
                child: Text(
                  c.boxCode.isEmpty ? '—' : c.boxCode,
                  style: bvText(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 110, child: _latestWeight(c)),
              SizedBox(width: 168, child: _actualField(c)),
              SizedBox(width: 100, child: _deltaText(delta, warn)),
              SizedBox(
                width: 140,
                child: MgmtDropdown<HarvestProductType>(
                  valueLabel: _productLabel(
                    _productById[c.id] ?? _productOf(c.isSoftshell, _product),
                  ),
                  items: const [
                    (HarvestProductType.meat, 'Cua thịt'),
                    (HarvestProductType.softshell, 'Cua lột'),
                    (HarvestProductType.other, 'Khác'),
                  ],
                  onSelected: (v) => setState(() => _productById[c.id] = v),
                ),
              ),
              SizedBox(
                width: 130,
                child: MgmtDropdown<String>(
                  valueLabel: _gradeLabel(_gradesById[c.id] ?? _gradeAll),
                  items: _grades,
                  onSelected: (v) => setState(() => _gradesById[c.id] = v),
                ),
              ),
              SizedBox(width: 150, child: _eligibilityBadge(c)),
              SizedBox(
                width: 56,
                child: IconButton(
                  tooltip: 'Gỡ khỏi phiếu',
                  onPressed: _saving
                      ? null
                      : () => setState(() => _removeCrab(c.id)),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: _kRed,
                ),
              ),
            ],
          ),
          if (warn)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 36),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '⚠ Trọng lượng thực tế chênh lệch lớn so với lần cân gần nhất. Vui lòng kiểm tra lại.',
                  style: bvText(fontSize: 11.5, color: _kAmber, height: 1.35),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _crabCard(int index, HarvestableCrab c) {
    final delta = _deltaOf(c);
    final warn = _deltaWarn(c);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '${index + 1}.',
                style: bvText(color: DashboardColors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(child: _crabIdentity(c)),
              IconButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _removeCrab(c.id)),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: _kRed,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hộp ${c.boxCode.isEmpty ? '—' : c.boxCode}',
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 8),
          _latestWeight(c),
          const SizedBox(height: 8),
          _actualField(c),
          const SizedBox(height: 8),
          _deltaText(delta, warn),
          const SizedBox(height: 8),
          MgmtDropdown<String>(
            valueLabel: _gradeLabel(_gradesById[c.id] ?? _gradeAll),
            items: _grades,
            onSelected: (v) => setState(() => _gradesById[c.id] = v),
          ),
          const SizedBox(height: 8),
          _eligibilityBadge(c),
          if (warn) ...[
            const SizedBox(height: 8),
            Text(
              '⚠ Trọng lượng thực tế chênh lệch lớn so với lần cân gần nhất.',
              style: bvText(fontSize: 11.5, color: _kAmber),
            ),
          ],
        ],
      ),
    );
  }

  Widget _crabIdentity(HarvestableCrab c) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 34,
            height: 34,
            child: c.imageUrl == null || c.imageUrl!.isEmpty
                ? const ColoredBox(
                    color: DashboardColors.lightMint,
                    child: Icon(
                      Icons.set_meal_outlined,
                      size: 18,
                      color: DashboardColors.brand,
                    ),
                  )
                : Image.network(
                    c.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => const ColoredBox(
                      color: DashboardColors.lightMint,
                      child: Icon(
                        Icons.set_meal_outlined,
                        size: 18,
                        color: DashboardColors.brand,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            c.code,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bvText(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _latestWeight(HarvestableCrab c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${c.weightG} g',
          style: bvText(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        if (c.lastWeightAt != null)
          Text(
            formatHarvestDate(c.lastWeightAt!),
            style: bvText(fontSize: 11, color: DashboardColors.textMuted),
          ),
      ],
    );
  }

  Widget _actualField(HarvestableCrab c) {
    return TextField(
      controller: _weights[c.id],
      enabled: !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
      decoration: _inputDeco(null).copyWith(
        suffixText: 'g',
        hintText: '—',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  Widget _deltaText(int? delta, bool warn) {
    if (delta == null) {
      return Text('—', style: bvText(color: DashboardColors.textMuted));
    }
    final sign = delta > 0 ? '+' : '';
    return Text(
      '$sign$delta g',
      style: bvText(
        fontWeight: FontWeight.w700,
        color: warn
            ? _kAmber
            : delta == 0
                ? DashboardColors.textMuted
                : (delta < 0 ? _kRed : DashboardColors.brand),
      ),
    );
  }

  Widget _eligibilityBadge(HarvestableCrab c) {
    final color = harvestEligibilityColor(c.eligibility);
    final icon = switch (c.eligibility) {
      HarvestEligibility.eligible => Icons.check_circle_outline_rounded,
      HarvestEligibility.monitoring => Icons.warning_amber_rounded,
      HarvestEligibility.notEligible => Icons.cancel_outlined,
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            harvestEligibilityLabel(c.eligibility),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bvText(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary() {
    final g1 = _selected.where((c) => (_gradesById[c.id] ?? 'A') == 'A').length;
    final g2 = _selected.where((c) => (_gradesById[c.id] ?? 'A') == 'B').length;
    final g3 = _selected.where((c) => (_gradesById[c.id] ?? 'A') == 'C').length;
    final expectedKg = _expectedG / 1000;
    final actualKg = _actualG / 1000;
    final deltaKg = _actualComplete ? (actualKg - expectedKg) : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tổng hợp',
            style: bvText(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _metric(Icons.link_rounded, 'Số cua', '${_selected.length} con'),
              _metric(
                Icons.monitor_weight_outlined,
                'Tổng KL dự kiến',
                '${expectedKg.toStringAsFixed(3)} kg',
              ),
              _metric(
                Icons.inventory_2_outlined,
                'Tổng KL thực tế',
                _actualComplete
                    ? '${actualKg.toStringAsFixed(3)} kg'
                    : 'Chưa hoàn tất',
                warn: !_actualComplete && _selected.isNotEmpty,
              ),
              _metric(
                Icons.trending_down_rounded,
                'Chênh lệch',
                deltaKg == null
                    ? '—'
                    : '${deltaKg > 0 ? '+' : ''}${deltaKg.toStringAsFixed(3)} kg',
              ),
              const SizedBox(width: 12),
              _gradeDot(_kBlue, 'Loại 1', '$g1 con'),
              _gradeDot(DashboardColors.brand, 'Loại 2', '$g2 con'),
              _gradeDot(_kAmber, 'Loại 3', '$g3 con'),
            ],
          ),
          if (_missingActual > 0) ...[
            const SizedBox(height: 10),
            Text(
              '⚠ Còn $_missingActual cua chưa nhập trọng lượng thực tế.',
              style: bvText(fontSize: 12.5, color: _kAmber, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value, {bool warn = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: DashboardColors.brand),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            Text(
              value,
              style: bvText(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: warn ? _kAmber : DashboardColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _gradeDot(Color color, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
        const SizedBox(width: 6),
        Text(
          value,
          style: bvText(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );
  }

  Widget _photosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh thu hoạch (không bắt buộc)',
          style: bvText(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tối đa $_kMaxPhotos ảnh. Hỗ trợ JPG, PNG, dung lượng tối đa 5MB/ảnh.',
          style: bvText(fontSize: 12, color: DashboardColors.textMuted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _addPhotoTile(),
            for (var i = 0; i < _photos.length; i++) _photoTile(_photos[i], i),
          ],
        ),
      ],
    );
  }

  Widget _addPhotoTile() {
    final full = _photos.length >= _kMaxPhotos;
    return InkWell(
      onTap: _saving || full ? null : _pickPhotos,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: DashboardColors.lightMint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: DashboardColors.brand.withValues(alpha: full ? 0.4 : 1)),
            Text(
              'Thêm ảnh',
              style: bvText(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: DashboardColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoTile(_HarvestPhoto p, int index) {
    return Stack(
      children: [
        InkWell(
          onTap: p.hasPreview ? () => _openPhoto(p) : null,
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 88,
              height: 88,
              child: _photoImage(p),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: _saving ? null : () => setState(() => _photos.removeAt(index)),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _noteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ghi chú',
          style: bvText(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          maxLength: _kNoteMax,
          maxLines: 3,
          enabled: !_saving,
          onChanged: (_) => setState(() {}),
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
          decoration: _inputDeco('Nhập ghi chú về đợt thu hoạch...').copyWith(
            counterText: '${_note.text.length}/$_kNoteMax',
            counterStyle: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _footer(bool compact) {
    final createLabel = _saving && _submittingCreate
        ? 'Đang tạo...'
        : 'Tạo phiếu thu hoạch';
    final draftLabel = _saving && !_submittingCreate ? 'Đang lưu...' : 'Lưu nháp';
    final actions = [
      MgmtOutlineButton(
        onTap: _saving ? null : () => Navigator.pop(context),
        icon: Icons.close_rounded,
        label: 'Hủy',
        color: DashboardColors.textMuted,
      ),
      const SizedBox(width: 8),
      MgmtOutlineButton(
        onTap: _saving ? null : () => _submit(draft: true),
        icon: Icons.save_outlined,
        label: draftLabel,
      ),
      const SizedBox(width: 8),
      MgmtPrimaryButton(
        onTap: _saving ? null : () => _submit(draft: false),
        icon: Icons.check_rounded,
        label: createLabel,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: compact
          ? Wrap(
              alignment: WrapAlignment.end,
              runSpacing: 8,
              children: actions,
            )
          : Row(
              children: [
                const Spacer(),
                ...actions,
              ],
            ),
    );
  }

  Widget _errorBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: bvText(fontSize: 13, color: _kRed, height: 1.4),
      ),
    );
  }

  Widget _labeled(String label, Widget child, {String? helper}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: bvText(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper, style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
        ],
      ],
    );
  }

  Widget _readonlyField(String value, IconData icon) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: DashboardColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bvText(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tapField(String value, IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: DashboardColors.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: bvText(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DashboardColors.mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: bvText(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: DashboardColors.brand,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String? hint) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: bvText(color: DashboardColors.textMuted, fontSize: 13),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border(DashboardColors.cardBorder),
      enabledBorder: border(DashboardColors.cardBorder),
      focusedBorder: border(DashboardColors.brand, 1.4),
    );
  }
}

class SelectHarvestCrabsDialog extends StatefulWidget {
  const SelectHarvestCrabsDialog({
    super.key,
    required this.crabs,
    required this.already,
    this.softshellOnly = false,
  });

  final List<HarvestableCrab> crabs;
  final Set<String> already;
  final bool softshellOnly;

  @override
  State<SelectHarvestCrabsDialog> createState() =>
      _SelectHarvestCrabsDialogState();
}

class _SelectHarvestCrabsDialogState extends State<SelectHarvestCrabsDialog> {
  late final Set<String> _sel;
  final _q = TextEditingController();
  String? _row;
  String? _box;
  HarvestEligibility? _elig;

  @override
  void initState() {
    super.initState();
    _sel = {...widget.already};
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<HarvestableCrab> get _filtered {
    final q = _q.text.trim().toLowerCase();
    return widget.crabs.where((c) {
      if (widget.softshellOnly && !c.readyForSoftshellExport) return false;
      if (_row != null && c.rowName != _row) return false;
      if (_box != null && c.boxCode != _box) return false;
      if (_elig != null && c.eligibility != _elig) return false;
      if (q.isEmpty) return true;
      return c.code.toLowerCase().contains(q) ||
          c.boxCode.toLowerCase().contains(q) ||
          c.rowName.toLowerCase().contains(q) ||
          c.locationLine.toLowerCase().contains(q);
    }).toList();
  }

  Iterable<HarvestableCrab> get _chosen =>
      widget.crabs.where((c) => _sel.contains(c.id));

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final rows = {
      for (final c in widget.crabs)
        if (c.rowName.trim().isNotEmpty) c.rowName,
    }.toList()
      ..sort();
    final boxes = {
      for (final c in widget.crabs)
        if (c.boxCode.trim().isNotEmpty) c.boxCode,
    }.toList()
      ..sort();
    final selectedG = _chosen.fold<int>(0, (s, c) => s + c.weightG);
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.softshellOnly
                          ? 'Chọn cua lột'
                          : 'Chọn cua thu hoạch',
                      style: bvText(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: MgmtSearchField(
                      controller: _q,
                      onChanged: (_) => setState(() {}),
                      hint: 'Tìm mã cua...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MgmtDropdown<String?>(
                      valueLabel: _row ?? 'Dãy',
                      items: [
                        (null, 'Tất cả dãy'),
                        for (final r in rows) (r, r),
                      ],
                      onSelected: (v) => setState(() => _row = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MgmtDropdown<String?>(
                      valueLabel: _box ?? 'Hộp',
                      items: [
                        (null, 'Tất cả hộp'),
                        for (final b in boxes) (b, b),
                      ],
                      onSelected: (v) => setState(() => _box = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MgmtDropdown<HarvestEligibility?>(
                      valueLabel: _elig == null
                          ? 'Điều kiện'
                          : harvestEligibilityLabel(_elig!),
                      items: const [
                        (null, 'Tất cả'),
                        (HarvestEligibility.eligible, 'Đạt điều kiện'),
                        (HarvestEligibility.monitoring, 'Cần xem xét'),
                        (HarvestEligibility.notEligible, 'Không đủ điều kiện'),
                      ],
                      onSelected: (v) => setState(() => _elig = v),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        widget.softshellOnly
                            ? 'Chưa có cua lột phù hợp.'
                            : 'Không còn cua phù hợp.',
                        style: bvText(color: DashboardColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      itemCount: items.length,
                      separatorBuilder: (_, index) =>
                          const Divider(height: 1, color: DashboardColors.mint),
                      itemBuilder: (_, i) {
                        final c = items[i];
                        final enabled = c.canSelect;
                        return CheckboxListTile(
                          dense: true,
                          value: _sel.contains(c.id),
                          onChanged: !enabled
                              ? null
                              : (v) => setState(() {
                                    if (v == true) {
                                      _sel.add(c.id);
                                    } else {
                                      _sel.remove(c.id);
                                    }
                                  }),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            c.code,
                            style: bvText(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: enabled
                                  ? DashboardColors.textPrimary
                                  : DashboardColors.textMuted,
                            ),
                          ),
                          subtitle: Text(
                            enabled
                                ? '${c.boxCode.isEmpty ? '—' : c.boxCode}  ·  ${c.weightG} g  ·  ${c.condition}'
                                : '${c.code}  ·  ${c.disableReason}',
                            style: bvText(
                              fontSize: 12,
                              color: enabled
                                  ? DashboardColors.textMuted
                                  : _kRed,
                            ),
                          ),
                          secondary: _miniElig(c),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                color: DashboardColors.lightMint,
                border: Border(top: BorderSide(color: DashboardColors.mint)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đã chọn: ${_sel.length} cua\nTổng KL gần nhất: ${(selectedG / 1000).toStringAsFixed(2)} kg',
                      style: bvText(fontSize: 12.5, height: 1.4),
                    ),
                  ),
                  MgmtOutlineButton(
                    onTap: () => Navigator.pop(context),
                    label: 'Hủy',
                    color: DashboardColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  MgmtPrimaryButton(
                    onTap: () => Navigator.pop(context, _sel),
                    label: 'Thêm ${_sel.length} cua',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniElig(HarvestableCrab c) {
    final color = harvestEligibilityColor(c.eligibility);
    return Text(
      c.canSelect ? harvestEligibilityLabel(c.eligibility) : 'Không thể chọn',
      style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
    );
  }
}
