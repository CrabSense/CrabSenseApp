import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_individual.dart';
import '../../models/farm_activity_log.dart';
import '../../models/farm_layout.dart';
import '../../models/production_models.dart';
import '../../services/crab_service.dart';
import '../../services/farm_layout_service.dart';
import '../../services/farm_log_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showAddFarmLogDialog(
  BuildContext context,
  FarmLogService service, {
  FarmLayoutService? layout,
  CrabService? crabService,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AddFarmLogDialog(
      service: service,
      layout: layout,
      crabService: crabService,
    ),
  );
}

class _AddFarmLogDialog extends StatefulWidget {
  const _AddFarmLogDialog({
    required this.service,
    this.layout,
    this.crabService,
  });

  final FarmLogService service;
  final FarmLayoutService? layout;
  final CrabService? crabService;

  @override
  State<_AddFarmLogDialog> createState() => _AddFarmLogDialogState();
}

class _AddFarmLogDialogState extends State<_AddFarmLogDialog> {
  var _type = FarmLogType.inspectCrab;
  var _when = DateTime.now();
  String? _areaId;
  String? _rowId;
  String? _boxId;
  String? _crabId;
  final _contentCtrl = TextEditingController();
  final _photos = <String>[];
  var _saving = false;

  FarmLayoutService? get _layout => widget.layout;
  List<AreaRecord> get _areas => _layout?.areas ?? const [];
  List<RowRecord> get _rows => _layout?.rowsForArea(_areaId) ?? const [];
  List<FarmMapBox> get _boxes {
    return (_layout?.boxes ?? const <FarmMapBox>[])
        .where((b) =>
            (_areaId == null || b.areaId == _areaId) &&
            (_rowId == null || b.rowId == _rowId))
        .toList();
  }

  List<CrabIndividual> get _crabs {
    final all = widget.crabService?.crabs ?? const <CrabIndividual>[];
    if (_boxId != null) {
      final box = _boxes.where((b) => b.boxId == _boxId).firstOrNull;
      final code = box?.display.id;
      return all.where((c) {
        if (c.boxId == _boxId) return true;
        if (code != null && (c.boxName == code || c.boxId == code)) return true;
        return false;
      }).toList();
    }
    if (_areaId != null) {
      final boxIds = _boxes.map((b) => b.boxId).toSet();
      final codes = _boxes.map((b) => b.display.id).toSet();
      return all.where((c) => boxIds.contains(c.boxId) || codes.contains(c.boxName) || codes.contains(c.boxId)).toList();
    }
    return all;
  }

  @override
  void initState() {
    super.initState();
    final areas = _areas;
    final selected = _layout?.selectedAreaId;
    if (selected != null && areas.any((a) => a.id == selected)) {
      _areaId = selected;
    } else if (areas.isNotEmpty) {
      _areaId = areas.first.id;
    }
    _layout?.addListener(_onData);
    widget.crabService?.addListener(_onData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layout?.load();
      widget.crabService?.load();
    });
  }

  void _onData() {
    if (!mounted) return;
    setState(() {
      final areas = _areas;
      if (_areaId != null && !areas.any((a) => a.id == _areaId)) {
        _areaId = areas.isEmpty ? null : areas.first.id;
      } else if (_areaId == null && areas.isNotEmpty) {
        _areaId = areas.first.id;
      }
    });
  }

  @override
  void dispose() {
    _layout?.removeListener(_onData);
    widget.crabService?.removeListener(_onData);
    _contentCtrl.dispose();
    super.dispose();
  }

  String _locationLabel() {
    final area = _areas
        .where((a) => a.id == _areaId)
        .map((a) => a.areaName.trim().isEmpty ? a.areaCode : a.areaName)
        .firstOrNull;
    final row = _rows
        .where((r) => r.id == _rowId)
        .map((r) => r.rowName.trim().isEmpty ? r.rowCode : r.rowName)
        .firstOrNull;
    final box = _boxes
        .where((b) => b.boxId == _boxId)
        .map((b) => b.display.id)
        .firstOrNull;
    final crab = _crabs
        .where((c) => c.id == _crabId)
        .map((c) => c.code)
        .firstOrNull;
    return [
      if (area != null) area,
      if (row != null) row,
      if (box != null) box,
      if (crab != null) crab,
    ].join(' → ');
  }

  Future<void> _pickWhen() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (!mounted) return;
    setState(() {
      _when = DateTime(
        d.year,
        d.month,
        d.day,
        t?.hour ?? _when.hour,
        t?.minute ?? _when.minute,
      );
    });
  }

  Future<void> _pickPhotos() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov'],
    );
    if (picked == null) return;
    for (final f in picked.files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final url = await widget.service.uploadPhoto(path, boxId: _boxId);
        if (url != null && mounted) setState(() => _photos.add(url));
      } catch (_) {
        if (mounted) setState(() => _photos.add(f.name));
      }
    }
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final crab = _crabs.where((c) => c.id == _crabId).firstOrNull;
      await widget.service.addEntry(
        type: _type,
        content: _contentCtrl.text.trim(),
        occurredAt: _when,
        locationLabel: _locationLabel(),
        boxIds: [if (_boxId != null) _boxId!],
        crabId: crab?.code ?? '',
        photoUrls: _photos.where((p) => p.startsWith('http')).toList(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu nhật ký')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Thêm nhật ký',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Loại hoạt động'),
              DropdownButtonFormField<FarmLogType>(
                value: _type,
                dropdownColor: DashboardColors.card,
                items: [
                  for (final t in FarmLogType.manualChoices)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 12),
              _label('Thời gian'),
              OutlinedButton.icon(
                onPressed: _pickWhen,
                icon: const Icon(Icons.schedule, size: 16),
                label: Text(
                  '${_when.day.toString().padLeft(2, '0')}/${_when.month.toString().padLeft(2, '0')}/${_when.year}  '
                  '${_when.hour.toString().padLeft(2, '0')}:${_when.minute.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 14),
              _label('Liên quan đến — tìm và chọn như thả cua vào hộp'),
              _SearchPick<AreaRecord>(
                title: 'Khu',
                hint: 'Tìm khu…',
                items: _areas,
                selectedId: _areaId,
                idOf: (a) => a.id,
                labelOf: (a) => a.areaName.trim().isEmpty ? a.areaCode : a.areaName,
                subtitleOf: (a) => a.areaCode,
                noneLabel: 'Không chọn khu',
                onChanged: (id) => setState(() {
                  _areaId = id;
                  _rowId = null;
                  _boxId = null;
                  _crabId = null;
                }),
              ),
              _SearchPick<RowRecord>(
                title: 'Dãy',
                hint: 'Tìm dãy…',
                items: _rows,
                selectedId: _rowId,
                idOf: (r) => r.id,
                labelOf: (r) => r.rowName.trim().isEmpty ? r.rowCode : r.rowName,
                subtitleOf: (r) => r.rowCode,
                noneLabel: 'Tất cả dãy',
                onChanged: (id) => setState(() {
                  _rowId = id;
                  _boxId = null;
                  _crabId = null;
                }),
              ),
              _SearchPick<FarmMapBox>(
                title: 'Hộp',
                hint: 'Tìm mã hộp…',
                items: _boxes,
                selectedId: _boxId,
                idOf: (b) => b.boxId,
                labelOf: (b) => b.display.id,
                subtitleOf: (b) =>
                    '${b.rowLabel} · ${b.display.isOccupied ? '${b.crabCount} cua' : 'Trống'}',
                noneLabel: 'Không chọn hộp',
                onChanged: (id) => setState(() {
                  _boxId = id;
                  _crabId = null;
                }),
              ),
              _SearchPick<CrabIndividual>(
                title: 'Cua',
                hint: 'Tìm mã cua…',
                items: _crabs,
                selectedId: _crabId,
                idOf: (c) => c.id,
                labelOf: (c) => c.code,
                subtitleOf: (c) => c.locationLine,
                noneLabel: 'Không chọn cua',
                onChanged: (id) => setState(() {
                  _crabId = id;
                  final crab = _crabs.where((c) => c.id == id).firstOrNull;
                  if (crab == null) return;
                  final box = _boxes.where((b) =>
                      b.boxId == crab.boxId ||
                      b.display.id == crab.boxName ||
                      b.display.id == crab.boxId).firstOrNull;
                  if (box != null) {
                    _boxId = box.boxId;
                    _rowId = box.rowId;
                    _areaId = box.areaId;
                  }
                }),
              ),
              const SizedBox(height: 8),
              _label('Nội dung'),
              TextField(controller: _contentCtrl, maxLines: 3),
              const SizedBox(height: 12),
              _label('Ảnh / video'),
              OutlinedButton.icon(
                onPressed: _pickPhotos,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(
                  _photos.isEmpty
                      ? 'Tải ảnh / video'
                      : '${_photos.length} tệp đã chọn',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Người thực hiện: ${widget.service.performerName}',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
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
          child: Text(_saving ? 'Đang lưu…' : 'Lưu nhật ký'),
        ),
      ],
    );
  }
}

class _SearchPick<T> extends StatefulWidget {
  const _SearchPick({
    required this.title,
    required this.hint,
    required this.items,
    required this.selectedId,
    required this.idOf,
    required this.labelOf,
    required this.onChanged,
    this.subtitleOf,
    this.noneLabel = 'Không chọn',
  });

  final String title;
  final String hint;
  final List<T> items;
  final String? selectedId;
  final String Function(T) idOf;
  final String Function(T) labelOf;
  final String Function(T)? subtitleOf;
  final ValueChanged<String?> onChanged;
  final String noneLabel;

  @override
  State<_SearchPick<T>> createState() => _SearchPickState<T>();
}

class _SearchPickState<T> extends State<_SearchPick<T>> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final filtered = widget.items.where((e) {
      if (q.isEmpty) return true;
      final label = widget.labelOf(e).toLowerCase();
      final sub = widget.subtitleOf?.call(e).toLowerCase() ?? '';
      return label.contains(q) || sub.contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.hint,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 16),
              filled: true,
              fillColor: DashboardColors.darkNavy,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 140),
            decoration: BoxDecoration(
              color: DashboardColors.darkNavy.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              children: [
                _tile(
                  selected: widget.selectedId == null,
                  title: widget.noneLabel,
                  onTap: () => widget.onChanged(null),
                ),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Không có kết quả',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  for (final item in filtered)
                    _tile(
                      selected: widget.selectedId == widget.idOf(item),
                      title: widget.labelOf(item),
                      subtitle: widget.subtitleOf?.call(item),
                      onTap: () => widget.onChanged(widget.idOf(item)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required bool selected,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        color: selected
            ? DashboardColors.purple.withValues(alpha: 0.18)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: selected ? DashboardColors.cyan : DashboardColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

Widget _label(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: GoogleFonts.notoSans(
        color: DashboardColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
