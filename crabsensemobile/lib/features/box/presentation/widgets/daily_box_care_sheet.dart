import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/crab_model.dart';
import 'crab_avatar.dart';

/// Phiếu hộp (1 hộp · 1 cua).
/// [embedded] = true: hiện luôn trên màn hộp (không sheet).
class DailyBoxCareSheet extends StatefulWidget {
  const DailyBoxCareSheet({
    super.key,
    required this.boxId,
    required this.boxCode,
    required this.crab,
    this.embedded = false,
    this.onResult,
  });

  final String boxId;
  final String boxCode;
  final CrabModel crab;
  final bool embedded;
  final ValueChanged<String>? onResult;

  @override
  State<DailyBoxCareSheet> createState() => _DailyBoxCareSheetState();
}

class _DailyBoxCareSheetState extends State<DailyBoxCareSheet> {
  final _api = sl<ApiClient>();
  final _feedTypeCtrl = TextEditingController();
  final _feedGramCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _endCase;
  String _eat = 'many';
  String _activity = 'active';
  XFile? _video;
  bool _videoConfirmed = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _feedTypeCtrl.dispose();
    _feedGramCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isEnding => _endCase != null;

  Future<void> _recordVideo() async {
    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 20),
      );
    } catch (_) {
      file = null;
    }
    // Web / máy không camera → chọn file, vẫn qua bước xác nhận
    if (file == null && kIsWeb) {
      file = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );
    }
    if (file == null || !mounted) return;
    await _reviewAndConfirmVideo(file);
  }

  Future<void> _reviewAndConfirmVideo(XFile file) async {
    final sizeMb = (await file.length()) / (1024 * 1024);
    if (!mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: kHomeSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kHomeBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kHomeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Xem lại video',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: kHomeTextMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              file.name.isNotEmpty ? file.name : 'Video vừa quay',
              style: const TextStyle(color: kHomeTextSub, fontSize: 13),
            ),
            Text(
              '${sizeMb.toStringAsFixed(1)} MB · mục tiêu 10–20 giây',
              style: const TextStyle(color: kHomeTextSub, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(file.path);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else if (kIsWeb) {
                    // Web blob path — mở tab mới nếu có
                    final blob = Uri.parse(file.path);
                    await launchUrl(blob, mode: LaunchMode.platformDefault);
                  }
                },
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Xem lại trên máy'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'retake'),
                    child: const Text('Quay lại'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'confirm'),
                    style: FilledButton.styleFrom(
                      backgroundColor: kHomePrimaryDark,
                    ),
                    child: const Text('Xác nhận lưu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'retake') {
      setState(() {
        _video = null;
        _videoConfirmed = false;
      });
      await _recordVideo();
      return;
    }
    if (action == 'confirm') {
      setState(() {
        _video = file;
        _videoConfirmed = true;
      });
    }
  }

  Future<String?> _uploadVideoIfAny() async {
    final file = _video;
    if (file == null || !_videoConfirmed) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final name = file.name.isNotEmpty
          ? file.name
          : 'box_${widget.boxCode}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final form = FormData.fromMap({
        'category': 'video',
        'boxId': widget.boxId,
        'file': MultipartFile.fromBytes(bytes, filename: name),
      });
      final res = await _api.dio.post<dynamic>('/media/upload', data: form);
      final data = res.data;
      if (data is Map) {
        final nested = data['data'];
        if (nested is Map) {
          return (nested['webViewLink'] ??
                  nested['shareLink'] ??
                  nested['url'] ??
                  nested['storageKey'])
              ?.toString();
        }
        return (data['url'] ?? data['webViewLink'])?.toString();
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final tag = crabDisplayTag(widget.crab);
      final noteExtra = _notesCtrl.text.trim();

      if (_isEnding) {
        await _saveEndCase(tag: tag, extraNotes: noteExtra);
      } else {
        await _saveDaily(tag: tag, extraNotes: noteExtra);
      }

      if (!mounted) return;
      final result = _isEnding ? 'ended' : 'saved';
      if (widget.embedded) {
        widget.onResult?.call(result);
        if (result == 'saved') {
          setState(() {
            _feedTypeCtrl.clear();
            _feedGramCtrl.clear();
            _notesCtrl.clear();
            _video = null;
            _videoConfirmed = false;
            _eat = 'many';
            _activity = 'active';
            _endCase = null;
          });
        }
      } else {
        Navigator.pop(context, result);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được: $error'),
          backgroundColor: kHomeDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEndCase({
    required String tag,
    required String extraNotes,
  }) async {
    final label = switch (_endCase) {
      'dead' => 'Cua chết',
      'escaped' => 'Cua xổng',
      'harvested' => 'Cua đã thu hoạch',
      _ => 'Kết thúc hộp',
    };
    final notes = [
      'Kết thúc hộp ${widget.boxCode}',
      'Cua: $tag',
      label,
      if (extraNotes.isNotEmpty) 'Ghi chú: $extraNotes',
    ].join('\n');

    await _api.post<dynamic>('/operations', data: {
      'type': 'inspection',
      'boxIds': [widget.boxId],
      'notes': notes,
    });

    final crabId = widget.crab.id;
    if (crabId.isEmpty) return;

    if (_endCase == 'dead') {
      try {
        await _api.post<dynamic>('/mortality', data: {
          'crabId': crabId,
          'cause': 'Unknown',
          'notes': notes,
        });
      } catch (_) {}
    }

    if (_endCase == 'harvested') {
      try {
        await _api.post<dynamic>('/harvest-vouchers', data: {
          'harvestDate': DateTime.now().toUtc().toIso8601String(),
          'notes': notes,
          'lines': [
            {
              'crabId': crabId,
              'weightGram': widget.crab.weight,
              'grade': 'A',
              'isSoftshell': false,
              'notes': tag,
            }
          ],
        });
      } catch (_) {}
    }

    try {
      await _api.delete<dynamic>('/crabs/$crabId');
    } catch (_) {}
  }

  Future<void> _saveDaily({
    required String tag,
    required String extraNotes,
  }) async {
    String? videoUrl;
    try {
      videoUrl = await _uploadVideoIfAny();
    } catch (e) {
      if (!mounted) rethrow;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video chưa lên được Drive: $e — vẫn lưu phiếu.'),
          backgroundColor: kHomeWarning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final feedType = _feedTypeCtrl.text.trim();
    final grams = _feedGramCtrl.text.trim();
    final notes = [
      'Phiếu hộp ${widget.boxCode}',
      'Cua: $tag',
      'Ăn: ${_eatLabel(_eat)}',
      if (feedType.isNotEmpty) 'Thức ăn: $feedType',
      if (grams.isNotEmpty) 'Lượng: ${grams}g',
      'Tình trạng: ${_activityLabel(_activity)}',
      if (videoUrl != null && videoUrl.isNotEmpty) 'Video: $videoUrl',
      if (_videoConfirmed && _video != null && (videoUrl == null || videoUrl.isEmpty))
        'Video: đã xác nhận (${_video!.name}) — chờ Drive',
      if (extraNotes.isNotEmpty) 'Ghi chú: $extraNotes',
    ].join('\n');

    final qty = double.tryParse(grams);
    await _api.post<dynamic>('/operations', data: {
      'type': qty != null ? 'feeding' : 'inspection',
      'boxIds': [widget.boxId],
      'notes': notes,
      if (qty != null) 'quantity': qty,
      if (qty != null) 'unit': 'g',
      if (videoUrl != null && videoUrl.isNotEmpty) 'photoUrls': [videoUrl],
    });
  }

  @override
  Widget build(BuildContext context) {
    final tag = crabDisplayTag(widget.crab);
    final formBody = _buildFormBody(tag);

    if (widget.embedded) {
      return Container(
        decoration: BoxDecoration(
          color: CrabSenseColors.primaryMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CrabSenseColors.primaryLight),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: CrabSenseColors.primary),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: formBody,
            ),
          ],
        ),
      );
    }

    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: kHomeSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kHomeBorder),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kHomeBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: formBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormBody(String tag) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) ...[
          Row(
            children: [
              const CrabAvatar(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hộp ${widget.boxCode}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kHomeTextMain,
                      ),
                    ),
                    Text(
                      '$tag · ${widget.crab.weight.round()}g · '
                      '${crabSpeciesVi(widget.crab.species)}',
                      style: const TextStyle(fontSize: 13, color: kHomeTextSub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else ...[
          const Text(
            'Phiếu hôm nay',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kHomePrimaryDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tick nhanh — lưu xong sẽ quay về danh sách hộp',
            style: TextStyle(fontSize: 12, color: kHomeTextSub),
          ),
          const SizedBox(height: 12),
        ],
        _section('Kết thúc hộp (chọn 1 thì không điền phần dưới)'),
        _pills(
          value: _endCase ?? '',
          options: const {
            '': 'Đang nuôi',
            'dead': 'Cua chết',
            'escaped': 'Cua xổng',
            'harvested': 'Thu hoạch',
          },
          onChanged: (v) => setState(() => _endCase = v.isEmpty ? null : v),
        ),
        if (_isEnding) ...[
          const SizedBox(height: 14),
          const Text(
            'Không cần ghi ăn / tình trạng / video.',
            style: TextStyle(color: kHomeTextSub, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _field(_notesCtrl, 'Ghi chú (không bắt buộc)', lines: 2),
        ] else ...[
          const SizedBox(height: 16),
          _section('Ăn'),
          _pills(
            value: _eat,
            options: const {
              'many': 'Ăn nhiều',
              'little': 'Ít',
              'none': 'Không ăn',
            },
            onChanged: (v) => setState(() => _eat = v),
          ),
          const SizedBox(height: 14),
          _section('Cho ăn gì'),
          _field(_feedTypeCtrl, 'Loại thức ăn'),
          const SizedBox(height: 10),
          _field(_feedGramCtrl, 'Bao nhiêu gam'),
          const SizedBox(height: 14),
          _section('Tình trạng'),
          _pillsWrap(
            value: _activity,
            options: const {
              'active': 'Di chuyển nhiều',
              'still': 'Không di chuyển',
              'no_response': 'Không phản ứng khi tiếp xúc',
              'corner': 'Chui sâu vào góc hộp',
            },
            onChanged: (v) => setState(() => _activity = v),
          ),
          const SizedBox(height: 14),
          _section('Video 10–20 giây'),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _uploading ? null : _recordVideo,
              style: FilledButton.styleFrom(
                backgroundColor: CrabSenseColors.primary,
                foregroundColor: CrabSenseColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                _videoConfirmed
                    ? Icons.check_circle_rounded
                    : Icons.videocam_rounded,
              ),
              label: Text(
                _videoConfirmed
                    ? 'Đã xác nhận: ${_video!.name}'
                    : 'Quay video trên điện thoại',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (_videoConfirmed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: _uploading ? null : _recordVideo,
                child: const Text('Quay video khác'),
              ),
            ),
          const SizedBox(height: 14),
          _section('Ghi chú'),
          _field(_notesCtrl, 'Nếu có…', lines: 2),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: (_saving || _uploading) ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor:
                  _isEnding ? kHomeDanger : CrabSenseColors.primary,
              foregroundColor:
                  _isEnding ? Colors.white : CrabSenseColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: (_saving || _uploading)
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _isEnding
                          ? Colors.white
                          : CrabSenseColors.textOnPrimary,
                    ),
                  )
                : Text(
                    _isEnding ? 'Xác nhận kết thúc hộp' : 'Lưu phiếu hôm nay',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: kHomePrimaryDark,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String hint, {
    int lines = 1,
  }) =>
      TextField(
        controller: controller,
        maxLines: lines,
        keyboardType: hint.toLowerCase().contains('gam')
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: hint.toLowerCase().contains('gam')
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kHomeTextSub, fontSize: 13),
          filled: true,
          fillColor: kHomeBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kHomeBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kHomeBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: CrabSenseColors.primary, width: 1.5),
          ),
        ),
      );

  Widget _pills({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        for (final e in options.entries) ...[
          if (e.key != options.keys.first) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(e.key),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: value == e.key
                      ? CrabSenseColors.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: value == e.key
                        ? CrabSenseColors.primary
                        : kHomeBorder,
                    width: value == e.key ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: value == e.key
                        ? CrabSenseColors.textOnPrimary
                        : kHomeTextMain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _pillsWrap({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in options.entries)
          InkWell(
            onTap: () => onChanged(e.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: value == e.key
                    ? CrabSenseColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value == e.key
                      ? CrabSenseColors.primary
                      : kHomeBorder,
                  width: value == e.key ? 1.5 : 1,
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: value == e.key
                      ? CrabSenseColors.textOnPrimary
                      : kHomeTextMain,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _eatLabel(String v) => switch (v) {
        'little' => 'ít',
        'none' => 'không ăn',
        _ => 'ăn nhiều',
      };

  String _activityLabel(String v) => switch (v) {
        'still' => 'không di chuyển',
        'no_response' => 'không phản ứng khi tiếp xúc',
        'corner' => 'chui sâu vào góc hộp',
        _ => 'di chuyển nhiều',
      };
}
