import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_back.dart';
import '../../../authentication/data/datasources/auth_local_data_source.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/crab_condition.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/crab_model.dart';
import 'crab_avatar.dart';

/// Phiếu hộp (1 hộp · 1 cua).
/// [embedded] = true: hiện luôn trên màn hộp (không sheet).
/// [mode]: `full` | `monitor` (tình trạng + video) | `feed` (ảnh thức ăn + loại + gam).
class DailyBoxCareSheet extends StatefulWidget {
  const DailyBoxCareSheet({
    super.key,
    required this.boxId,
    required this.boxCode,
    required this.crab,
    this.embedded = false,
    this.mode = 'full',
    this.farmId,
    this.onResult,
  });

  final String boxId;
  final String boxCode;
  final CrabModel crab;
  final bool embedded;
  final String mode;
  final String? farmId;
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
  String _condition = 'normal';
  String _activity = 'active';
  XFile? _video;
  bool _videoConfirmed = false;
  XFile? _pelletPhoto;
  XFile? _boxPhoto;
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

  Future<void> _openMoltForm() async {
    await context.push(
      RoutePaths.harvestForBox(
        widget.boxCode,
        farmId: widget.farmId,
        crabId: widget.crab.id,
        boxGuid: widget.boxId,
        weightBefore: widget.crab.weight,
        lengthBefore: widget.crab.carapaceLengthMm,
        widthBefore: widget.crab.carapaceWidthMm,
      ),
    );
    if (!mounted) return;
    widget.onResult?.call('molt');
  }

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

  Future<XFile?> _pickPhoto() async {
    final picker = ImagePicker();
    try {
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (shot != null) return shot;
    } catch (_) {}
    if (kIsWeb) {
      return picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
    }
    return picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
  }

  Future<String?> _uploadFeedPhoto(XFile file, String kind) async {
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty
        ? file.name
        : '${kind}_${widget.boxCode}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: name),
      'boxId': widget.boxId,
      if (widget.crab.id.isNotEmpty) 'crabId': widget.crab.id,
      'relatedEntityType': 'CrabFeeding',
      'relatedEntityId': widget.crab.id,
      'photoKind': kind,
    });
    final res = await _api.dio.post<dynamic>('/operations/photo', data: form);
    final data = res.data;
    if (data is Map) {
      final nested = data['data'];
      if (nested is Map) {
        return (nested['url'] ?? nested['webViewLink'] ?? nested['shareLink'])
            ?.toString();
      }
      return data['url']?.toString();
    }
    return null;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'ended'
                ? 'Đã kết thúc hộp'
                : 'Đã lưu phiếu hôm nay',
          ),
          backgroundColor: CrabSenseColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onResult?.call(result);
      if (widget.embedded) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          appBack(context, fallback: RoutePaths.boxes);
        }
      } else {
        Navigator.pop(context, result);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được: ${_errText(error)}'),
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

    await _api.post<dynamic>(
      '/operations',
      data: await _opBody(
        type: 'inspection',
        notes: notes,
        includeCare: false,
      ),
    );

    final crabId = widget.crab.id;
    if (crabId.isEmpty) return;

    if (_endCase == 'dead') {
      try {
        await _api.post<dynamic>(
          '/mortality',
          data: {'crabId': crabId, 'cause': 'Unknown', 'notes': notes},
        );
      } catch (_) {}
    }

    if (_endCase == 'harvested') {
      try {
        await _api.post<dynamic>(
          '/harvest-vouchers',
          data: {
            'harvestDate': DateTime.now().toUtc().toIso8601String(),
            'notes': notes,
            'lines': [
              {
                'crabId': crabId,
                'weightGram': widget.crab.weight,
                'grade': 'A',
                'isSoftshell': false,
                'notes': tag,
              },
            ],
          },
        );
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
    String? pelletUrl;
    String? boxUrl;
    try {
      setState(() => _uploading = true);
      if (_pelletPhoto != null) {
        pelletUrl = await _uploadFeedPhoto(_pelletPhoto!, 'feed_pellet');
      }
      if (_boxPhoto != null) {
        boxUrl = await _uploadFeedPhoto(_boxPhoto!, 'feed_box');
      }
      if (widget.mode != 'feed') {
        videoUrl = await _uploadVideoIfAny();
      }
    } catch (e) {
      if (!mounted) rethrow;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ảnh/video chưa lên được: $e — vẫn lưu phiếu.'),
          backgroundColor: kHomeWarning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }

    final feedType = _feedTypeCtrl.text.trim();
    final grams = _feedGramCtrl.text.trim();
    final notes = [
      'Phiếu hộp ${widget.boxCode}',
      'Cua: $tag',
      'Ăn: ${_eatLabel(_eat)}',
      'Đánh dấu: ${_conditionLabel(_condition)}',
      if (feedType.isNotEmpty) 'Thức ăn: $feedType',
      if (grams.isNotEmpty) 'Lượng: ${grams}g',
      'Hoạt động: ${_activityLabel(_activity)}',
      if (pelletUrl != null && pelletUrl.isNotEmpty) 'Ảnh viên thức ăn: $pelletUrl',
      if (boxUrl != null && boxUrl.isNotEmpty) 'Ảnh hộp cho ăn: $boxUrl',
      if (videoUrl != null && videoUrl.isNotEmpty) 'Video: $videoUrl',
      if (extraNotes.isNotEmpty) 'Ghi chú: $extraNotes',
    ].join('\n');

    final qty = double.tryParse(grams);
    final photoUrls = [
      if (pelletUrl != null && pelletUrl.isNotEmpty) pelletUrl,
      if (boxUrl != null && boxUrl.isNotEmpty) boxUrl,
      if (videoUrl != null && videoUrl.isNotEmpty) videoUrl,
    ];
    await _api.post<dynamic>(
      '/operations',
      data: await _opBody(
        type: 'feeding',
        notes: notes,
        includeCare: true,
        photoUrls: photoUrls,
        foodType: feedType,
        quantity: qty,
      ),
    );
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
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
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
          Text(
            widget.mode == 'feed'
                ? 'Cho ăn'
                : widget.mode == 'monitor'
                ? 'Theo dõi'
                : 'Phiếu hôm nay',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kHomePrimaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.mode == 'feed'
                ? 'Ảnh, loại thức ăn và gam — có thì ghi, không có thì vẫn lưu.'
                : widget.mode == 'monitor'
                ? 'Tình trạng / video nếu có. Hôm nào không rảnh chụp vẫn lưu được.'
                : 'Có gì ghi nấy — không bắt ảnh hay video.',
            style: const TextStyle(fontSize: 12, color: kHomeTextSub),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.mode != 'feed') ...[
          _section('Kết thúc hộp'),
          _pills(
            value: _endCase ?? '',
            options: const {
              '': 'Đang nuôi',
              'dead': 'Cua chết',
              'escaped': 'Cua xổng',
              'molting': 'Cua lột',
            },
            onChanged: (v) {
              if (v == 'molting') {
                _openMoltForm();
                return;
              }
              setState(() => _endCase = v.isEmpty ? null : v);
            },
          ),
        ],
        if (_isEnding && widget.mode != 'feed') ...[
          const SizedBox(height: 14),
          const Text(
            'Không cần ghi ăn / tình trạng / video.',
            style: TextStyle(color: kHomeTextSub, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _field(_notesCtrl, 'Ghi chú (không bắt buộc)', lines: 2),
        ] else ...[
          if (widget.mode == 'monitor') ...[
            const SizedBox(height: 16),
            _section('Đánh giá lượng ăn'),
            _pills(
              value: _eat,
              options: const {
                'many': 'Ăn nhiều',
                'little': 'Ít',
                'none': 'Không ăn',
              },
              onChanged: (v) => setState(() => _eat = v),
            ),
          ],
          if (widget.mode == 'feed') ...[
            const SizedBox(height: 16),
            _section('Thông tin thức ăn'),
            _field(_feedTypeCtrl, 'Loại thức ăn'),
            const SizedBox(height: 10),
            _field(_feedGramCtrl, 'Bao nhiêu gam'),
            const SizedBox(height: 14),
            _section('Ảnh thức ăn'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _photoSlot(
                    title: 'Thức ăn',
                    file: _pelletPhoto,
                    onTap: () async {
                      final shot = await _pickPhoto();
                      if (shot != null && mounted) {
                        setState(() => _pelletPhoto = shot);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _photoSlot(
                    title: 'Hộp khi cho ăn',
                    file: _boxPhoto,
                    onTap: () async {
                      final shot = await _pickPhoto();
                      if (shot != null && mounted) {
                        setState(() => _boxPhoto = shot);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          if (widget.mode != 'feed') ...[
            const SizedBox(height: 14),
            _section('Đánh dấu tình trạng'),
            _pillsGrid(
              value: _condition,
              options: {
                for (final c in CrabCondition.selectable)
                  c.apiKey: c.displayStatus.label,
              },
              onChanged: (v) => setState(() => _condition = v),
            ),
            if (_condition == 'molting') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openMoltForm(),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Mở phiếu lột / thu hoạch'),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _section('Hoạt động'),
            _pillsGrid(
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
                  _videoConfirmed ? 'Đã có video' : 'Quay video sau khi ăn',
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
          ],
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
              backgroundColor: _isEnding
                  ? kHomeDanger
                  : CrabSenseColors.primary,
              foregroundColor: _isEnding
                  ? Colors.white
                  : CrabSenseColors.textOnPrimary,
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

  Widget _photoSlot({
    required String title,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _uploading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: kHomeBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: file == null ? kHomeBorder : CrabSenseColors.primary,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_camera_outlined, color: kHomeTextSub),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: kHomeTextMain,
                    ),
                  ),
                  const Text(
                    'Chụp',
                    style: TextStyle(fontSize: 11, color: kHomeTextSub),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: kHomeGreen),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: kHomeTextMain,
                    ),
                  ),
                  const Text(
                    'Chụp lại',
                    style: TextStyle(fontSize: 11, color: kHomeTextSub),
                  ),
                ],
              ),
      ),
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
  }) => TextField(
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(
          color: CrabSenseColors.primary,
          width: 1.5,
        ),
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

  /// 2 cột, cùng kiểu tick với [Kết thúc hộp] / [Đánh giá lượng ăn]:
  /// chọn = nền primary + chữ trắng, chưa chọn = trắng + viền.
  Widget _pillsGrid({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    final entries = options.entries.toList();
    return Column(
      children: [
        for (var i = 0; i < entries.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _pillCell(entries[i], value, onChanged),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < entries.length
                    ? _pillCell(entries[i + 1], value, onChanged)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _pillCell(
    MapEntry<String, String> e,
    String value,
    ValueChanged<String> onChanged,
  ) {
    final selected = value == e.key;
    return InkWell(
      onTap: () => onChanged(e.key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CrabSenseColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? CrabSenseColors.primary : kHomeBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          e.value,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? CrabSenseColors.textOnPrimary : kHomeTextMain,
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _opBody({
    required String type,
    required String notes,
    required bool includeCare,
    List<String> photoUrls = const [],
    String foodType = '',
    double? quantity,
  }) async {
    final crabId = widget.crab.id;
    final ts = DateTime.now().toUtc().toIso8601String();
    final body = <String, dynamic>{
      'type': type,
      'boxIds': [widget.boxId],
      'notes': notes,
      'timestamp': ts.endsWith('Z') ? ts : '${ts}Z',
      'source': 'manual',
    };
    if (crabId.isNotEmpty) body['crabIds'] = [crabId];
    if (photoUrls.isNotEmpty) body['photoUrls'] = photoUrls;
    if (includeCare) {
      body['appetite'] = _eat;
      body['condition'] = switch (_condition) {
        'molting' => 'premolt',
        'problem' => 'attention',
        _ => _condition,
      };
      body['activityAfter'] = switch (_activity) {
        'still' || 'no_response' => 0,
        'corner' => 50,
        _ => 100,
      };
      if (foodType.isNotEmpty) body['foodType'] = foodType;
      if (quantity != null) {
        body['quantity'] = quantity;
        body['unit'] = 'g';
      }
    }
    try {
      final u = await sl<AuthLocalDataSource>().getCachedUser();
      if (u.id.isNotEmpty) body['operatorId'] = u.id;
      if (u.name.isNotEmpty) body['operatorName'] = u.name;
    } catch (_) {}
    return body;
  }

  String _errText(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['title'] ?? data['error'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (error.response?.statusCode != null) {
        return 'máy chủ ${error.response!.statusCode}';
      }
    }
    return error.toString();
  }

  String _eatLabel(String v) => switch (v) {
    'little' => 'ít',
    'none' => 'không ăn',
    _ => 'ăn nhiều',
  };

  String _conditionLabel(String v) =>
      CrabCondition.tryParse(v)?.displayStatus.label.toLowerCase() ??
      'bình thường';

  String _activityLabel(String v) => switch (v) {
    'still' => 'không di chuyển',
    'no_response' => 'không phản ứng khi tiếp xúc',
    'corner' => 'chui sâu vào góc hộp',
    _ => 'di chuyển nhiều',
  };
}
