import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/camera_device.dart';
import '../../../models/crab_growth_molt.dart';
import '../../../services/cloud_api_client.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';

Future<NewGrowthInput?> showGrowthRecordModal(
  BuildContext context, {
  required String crabCode,
  required String token,
  required CloudApiClient api,
  List<CameraDevice> cameras = const [],
}) {
  return showDialog<NewGrowthInput>(
    context: context,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (_) => _GrowthRecordDialog(crabCode: crabCode, token: token, api: api, cameras: cameras),
  );
}

class _GrowthRecordDialog extends StatefulWidget {
  const _GrowthRecordDialog({required this.crabCode, required this.token, required this.api, required this.cameras});

  final String crabCode;
  final String token;
  final CloudApiClient api;
  final List<CameraDevice> cameras;

  @override
  State<_GrowthRecordDialog> createState() => _GrowthRecordDialogState();
}

class _GrowthRecordDialogState extends State<_GrowthRecordDialog> {
  DateTime _time = DateTime.now();
  DateTime? _start;
  DateTime? _end;
  final _weight = TextEditingController();
  final _width = TextEditingController();
  final _length = TextEditingController();
  final _note = TextEditingController();
  final _moltNote = TextEditingController();
  var _isMolt = false;
  var _status = MoltEventStatus.normal;
  String? _cameraId;
  final _photos = <String>[];
  final _moltPaths = <String>[];
  var _uploading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_weight, _width, _length, _note, _moltNote]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  String? _validate() {
    final w = _num(_weight);
    if (w == null || w <= 0) return 'Cân nặng phải lớn hơn 0.';
    final sw = _num(_width);
    if (_width.text.trim().isNotEmpty && (sw == null || sw <= 0)) return 'Chiều rộng mai phải lớn hơn 0.';
    final sl = _num(_length);
    if (_length.text.trim().isNotEmpty && (sl == null || sl <= 0)) return 'Chiều dài mai phải lớn hơn 0.';
    if (_isMolt && _start != null && _end != null && _end!.isBefore(_start!)) {
      return 'Thời gian hoàn tất phải sau hoặc bằng thời gian bắt đầu.';
    }
    return null;
  }

  Future<void> _pickDt(DateTime initial, ValueChanged<DateTime> set) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (t == null || !mounted) return;
    set(DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _pickMeasurePhotos() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (picked == null || picked.files.isEmpty) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final paths = [for (final f in picked.files) if (f.path != null) f.path!];
      if (paths.isEmpty) return;
      final urls = await widget.api.uploadCrabImages(widget.token, paths);
      _photos.addAll(urls);
    } on CloudApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Không tải được ảnh: $e';
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickMoltPhotos() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (picked == null || picked.files.isEmpty) return;
    setState(() {
      _moltPaths.addAll([for (final f in picked.files) if (f.path != null) f.path!]);
    });
  }

  void _submit() {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(
      NewGrowthInput(
        measuredAt: _time,
        weightGram: _num(_weight)!,
        shellWidthMm: _num(_width),
        shellLengthMm: _num(_length),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        photoUrls: List.unmodifiable(_photos),
        isMolt: _isMolt,
        moltStartedAt: _start,
        moltCompletedAt: _end ?? _time,
        moltStatus: _status,
        moltNote: _moltNote.text.trim().isEmpty ? null : _moltNote.text.trim(),
        moltPhotoUrls: List.unmodifiable(_moltPaths),
        cameraId: _cameraId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 740),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: DashboardColors.mint, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.monitor_weight_outlined, size: 18, color: DashboardColors.brand),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ghi nhận sinh trưởng',
                            style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                        Text(widget.crabCode, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted)),
                ],
              ),
            ),
            const Divider(height: 1, color: DashboardColors.mint),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      'Ngày giờ đo *',
                      InkWell(
                        onTap: () => _pickDt(_time, (v) => setState(() => _time = v)),
                        child: _box(Row(children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: DashboardColors.brand),
                          const SizedBox(width: 8),
                          Text(fmtDateTimeVn(_time), style: bvText(fontSize: 13, fontWeight: FontWeight.w600)),
                        ])),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _two(
                      _field('Cân nặng (g) *', _input(_weight, hint: 'VD: 200')),
                      _field('Chiều rộng mai (mm)', _input(_width, hint: 'VD: 65')),
                    ),
                    const SizedBox(height: 12),
                    _field('Chiều dài mai (mm)', _input(_length, hint: 'VD: 90')),
                    const SizedBox(height: 12),
                    _field(
                      'Ảnh',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _photos.length; i++)
                            Chip(label: Text('Ảnh ${i + 1}'), onDeleted: () => setState(() => _photos.removeAt(i))),
                          MgmtOutlineButton(
                            icon: _uploading ? Icons.hourglass_top_rounded : Icons.add_photo_alternate_outlined,
                            label: _uploading ? 'Đang tải…' : 'Thêm ảnh',
                            onTap: _uploading ? null : _pickMeasurePhotos,
                            height: 32,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field('Ghi chú', _input(_note, hint: 'Quan sát thêm…', maxLines: 3)),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _isMolt,
                      onChanged: (v) => setState(() => _isMolt = v ?? false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: DashboardColors.brand,
                      title: Text('Đây là lần ghi nhận lột xác',
                          style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
                    ),
                    if (_isMolt) ...[
                      const SizedBox(height: 8),
                      _two(
                        _field(
                          'Thời gian bắt đầu',
                          InkWell(
                            onTap: () => _pickDt(_start ?? _time, (v) => setState(() => _start = v)),
                            child: _box(Text(_start == null ? 'Chọn thời điểm' : fmtDateTimeVn(_start),
                                style: bvText(fontSize: 13, fontWeight: FontWeight.w600))),
                          ),
                        ),
                        _field(
                          'Thời gian hoàn tất',
                          InkWell(
                            onTap: () => _pickDt(_end ?? _time, (v) => setState(() => _end = v)),
                            child: _box(Text(_end == null ? 'Chọn thời điểm' : fmtDateTimeVn(_end),
                                style: bvText(fontSize: 13, fontWeight: FontWeight.w600))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        'Tình trạng sau lột',
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final s in MoltEventStatus.values)
                              ChoiceChip(
                                label: Text(s.label, style: bvText(fontSize: 12, fontWeight: FontWeight.w700)),
                                selected: _status == s,
                                selectedColor: s.color.withValues(alpha: 0.16),
                                onSelected: (_) => setState(() => _status = s),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field('Ghi chú lột xác', _input(_moltNote, hint: 'VD: Lột xác hoàn tất, cua hoạt động bình thường.', maxLines: 3)),
                      const SizedBox(height: 12),
                      _field(
                        'Ảnh / Video lột xác',
                        Wrap(
                          spacing: 8,
                          children: [
                            for (var i = 0; i < _moltPaths.length; i++)
                              Chip(label: Text('File ${i + 1}'), onDeleted: () => setState(() => _moltPaths.removeAt(i))),
                            MgmtOutlineButton(icon: Icons.add_photo_alternate_outlined, label: 'Thêm ảnh', onTap: _pickMoltPhotos, height: 32),
                          ],
                        ),
                      ),
                      if (widget.cameras.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _field(
                          'Camera',
                          MgmtDropdown<String?>(
                            valueLabel: _cameraId == null
                                ? 'Không chọn'
                                : widget.cameras.where((c) => c.id == _cameraId).map((c) => c.name).firstOrNull ?? _cameraId!,
                            items: [
                              (null, 'Không chọn'),
                              for (final c in widget.cameras) (c.id, '${c.name} (${c.cameraCode})'),
                            ],
                            onSelected: (v) => setState(() => _cameraId = v),
                            leading: Icons.videocam_outlined,
                          ),
                        ),
                      ],
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: DashboardColors.risk.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: DashboardColors.risk.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: DashboardColors.risk),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.risk)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: DashboardColors.mint),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MgmtOutlineButton(label: 'Hủy', onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  MgmtPrimaryButton(label: 'Lưu ghi nhận', icon: Icons.check_rounded, onTap: _uploading ? null : _submit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _two(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: a), const SizedBox(width: 14), Expanded(child: b)],
      );

  Widget _field(String label, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.textMuted)),
          const SizedBox(height: 6),
          child,
        ],
      );

  Widget _box(Widget child) => Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: child,
      );

  Widget _input(TextEditingController ctrl, {String? hint, int maxLines = 1}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: maxLines == 1 ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.multiline,
      style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: border(DashboardColors.cardBorder),
        enabledBorder: border(DashboardColors.cardBorder),
        focusedBorder: border(DashboardColors.brandGreen, 1.4),
      ),
    );
  }
}
