import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/camera_device.dart';
import '../../../models/crab_feeding_activity.dart';
import '../../../services/cloud_api_client.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import 'feeding_history_table.dart';

const kFoodTypeSuggestions = <String>[
  'Cá tạp',
  'Tôm / tép',
  'Ốc',
  'Mực',
  'Thức ăn viên',
  'Hến / nghêu',
];

/// Modal "Ghi nhận cho ăn". Trả về [NewFeedingInput] khi người dùng bấm Lưu.
Future<NewFeedingInput?> showAddFeedingModal(
  BuildContext context, {
  required String crabCode,
  required String boxLabel,
  required String boxId,
  required String token,
  required CloudApiClient api,
  List<CameraDevice> cameras = const [],
  FeedingThresholds thresholds = FeedingThresholds.defaults,
}) {
  return showDialog<NewFeedingInput>(
    context: context,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (_) => _AddFeedingDialog(
      crabCode: crabCode,
      boxLabel: boxLabel,
      boxId: boxId,
      token: token,
      api: api,
      cameras: cameras,
      thresholds: thresholds,
    ),
  );
}

class _AddFeedingDialog extends StatefulWidget {
  const _AddFeedingDialog({
    required this.crabCode,
    required this.boxLabel,
    required this.boxId,
    required this.token,
    required this.api,
    required this.cameras,
    required this.thresholds,
  });

  final String crabCode;
  final String boxLabel;
  final String boxId;
  final String token;
  final CloudApiClient api;
  final List<CameraDevice> cameras;
  final FeedingThresholds thresholds;

  @override
  State<_AddFeedingDialog> createState() => _AddFeedingDialogState();
}

class _AddFeedingDialogState extends State<_AddFeedingDialog> {
  DateTime _time = DateTime.now();
  final _food = TextEditingController();
  final _served = TextEditingController();
  final _eaten = TextEditingController();
  final _actBefore = TextEditingController();
  final _actAfter = TextEditingController();
  final _note = TextEditingController();
  String? _cameraId;
  final _photos = <String>[];
  var _uploading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_food, _served, _eaten, _actBefore, _actAfter, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _servedVal => double.tryParse(_served.text.replaceAll(',', '.'));
  double? get _eatenVal => _eaten.text.trim().isEmpty ? null : double.tryParse(_eaten.text.replaceAll(',', '.'));
  int? get _percent {
    final s = _servedVal;
    final e = _eatenVal;
    if (s == null || s <= 0 || e == null || e < 0 || e > s) return null;
    return (e / s * 100).clamp(0, 100).round();
  }

  int? _score(TextEditingController c) => c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());

  String? _validate() {
    if (_food.text.trim().isEmpty) return 'Vui lòng chọn loại thức ăn.';
    final s = _servedVal;
    if (s == null || s <= 0) return 'Khẩu phần phải lớn hơn 0.';
    final e = _eatenVal;
    if (_eaten.text.trim().isNotEmpty && e == null) return 'Lượng đã ăn không hợp lệ.';
    if (e != null && e < 0) return 'Lượng đã ăn không được âm.';
    if (e != null && e > s) return 'Lượng đã ăn không được lớn hơn khẩu phần.';
    for (final c in [_actBefore, _actAfter]) {
      if (c.text.trim().isEmpty) continue;
      final v = int.tryParse(c.text.trim());
      if (v == null || v < 0 || v > 100) return 'Điểm vận động phải trong khoảng 0–100.';
    }
    if (_time.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return 'Thời gian cho ăn không được ở tương lai.';
    }
    return null;
  }

  Future<void> _pickTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _time,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_time));
    if (t == null || !mounted) return;
    setState(() => _time = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _pickPhoto() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (picked == null || picked.files.isEmpty) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      for (final f in picked.files) {
        final path = f.path;
        if (path == null) continue;
        final url = await widget.api.uploadOperationPhoto(
          widget.token,
          path,
          boxId: widget.boxId.isEmpty ? null : widget.boxId,
          relatedEntityType: 'FarmOperation',
        );
        if (url != null && url.isNotEmpty) _photos.add(url);
      }
    } on CloudApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Không tải được ảnh: $e';
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _submit() {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(
      NewFeedingInput(
        time: _time,
        foodType: _food.text.trim(),
        servedGram: _servedVal!,
        eatenGram: _eatenVal,
        activityBefore: _score(_actBefore),
        activityAfter: _score(_actAfter),
        cameraId: _cameraId,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        photoUrls: List.unmodifiable(_photos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = _percent;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
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
                    child: const Icon(Icons.restaurant_rounded, size: 18, color: DashboardColors.brand),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ghi nhận cho ăn',
                          style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                        ),
                        Text(
                          '${widget.crabCode} • ${widget.boxLabel}',
                          style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted),
                  ),
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
                    _twoCols(
                      _field(
                        'Thời gian *',
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(10),
                          child: _box(
                            Row(
                              children: [
                                const Icon(Icons.schedule_rounded, size: 16, color: DashboardColors.brand),
                                const SizedBox(width: 8),
                                Text(fmtDateTimeVn(_time), style: bvText(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _field(
                        'Loại thức ăn *',
                        Autocomplete<String>(
                          optionsBuilder: (v) => kFoodTypeSuggestions.where(
                            (s) => s.toLowerCase().contains(v.text.toLowerCase()),
                          ),
                          onSelected: (s) => _food.text = s,
                          fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                            ctrl.addListener(() => _food.text = ctrl.text);
                            return _input(ctrl, hint: 'Chọn hoặc nhập loại thức ăn', focus: focus);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _twoCols(
                      _field('Khẩu phần (g) *', _input(_served, hint: 'VD: 50', numeric: true, onChanged: (_) => setState(() {}))),
                      _field('Lượng đã ăn (g)', _input(_eaten, hint: 'VD: 45', numeric: true, onChanged: (_) => setState(() {}))),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Mức ăn (tự tính)',
                      _box(
                        Row(
                          children: [
                            FeedingPercentBadge(percent: pct, thresholds: widget.thresholds),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pct == null
                                    ? 'Nhập khẩu phần và lượng đã ăn để tính mức ăn.'
                                    : 'Mức ăn = Đã ăn / Khẩu phần × 100${widget.thresholds.isLowFeeding(pct) ? ' • ⚠ thấp hơn ngưỡng theo dõi' : ''}',
                                style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _twoCols(
                      _field('Vận động trước (0–100)', _input(_actBefore, hint: 'Bỏ trống nếu không đo', numeric: true)),
                      _field('Vận động sau (0–100)', _input(_actAfter, hint: 'Bỏ trống nếu không đo', numeric: true)),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Camera liên quan',
                      widget.cameras.isEmpty
                          ? _box(Text('Không có camera gắn với hộp này', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)))
                          : MgmtDropdown<String?>(
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
                    const SizedBox(height: 12),
                    _field(
                      'Ảnh minh chứng',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (var i = 0; i < _photos.length; i++)
                            Stack(
                              children: [
                                FeedingPhotoThumb(url: _photos[i], token: widget.token, size: 56),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: InkWell(
                                    onTap: () => setState(() => _photos.removeAt(i)),
                                    child: Container(
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: const Icon(Icons.close_rounded, size: 14, color: DashboardColors.risk),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          MgmtOutlineButton(
                            icon: _uploading ? Icons.hourglass_top_rounded : Icons.add_photo_alternate_outlined,
                            label: _uploading ? 'Đang tải…' : 'Thêm ảnh',
                            onTap: _uploading ? null : _pickPhoto,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Ghi chú',
                      _input(_note, hint: 'Quan sát thêm về lần cho ăn…', maxLines: 3),
                    ),
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
                              child: Text(
                                _error!,
                                style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.risk),
                              ),
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
                  MgmtPrimaryButton(
                    label: 'Lưu lần cho ăn',
                    icon: Icons.check_rounded,
                    onTap: _uploading ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _twoCols(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 14),
          Expanded(child: b),
        ],
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

  Widget _input(
    TextEditingController ctrl, {
    String? hint,
    bool numeric = false,
    int maxLines = 1,
    FocusNode? focus,
    ValueChanged<String>? onChanged,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: ctrl,
      focusNode: focus,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
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
