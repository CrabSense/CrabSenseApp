import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/crab_condition.dart';
import '../../../../shared/widgets/local_file_image.dart';
import '../../data/datasources/box_remote_data_source.dart';
import '../../data/models/crab_model.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../widgets/box_history_panel.dart';
import '../widgets/crab_avatar.dart';
import '../widgets/daily_box_care_sheet.dart';

const _primary = kHomePrimary;
const _primaryDk = kHomePrimaryDark;
const _primaryBg = kHomePrimaryBg;
const _bg = kHomeBg;
const _surface = kHomeSurface;
const _textMain = kHomeTextMain;
const _textSub = kHomeTextSub;
const _border = kHomeBorder;
const _danger = kHomeDanger;

/// Trần ảnh mỗi lần nhập cua — khớp giới hạn desktop (take(10)) và request 30MB của BE.
const _maxImages = 6;

/// Tình trạng cua — nhãn + key lấy từ [CrabCondition]/[BoxStatus], nên không
/// lệch với thẻ hộp, chú giải và phiếu chăm sóc.
final _conditionOptions = <String, String>{
  for (final c in CrabCondition.selectable) c.apiKey: c.displayStatus.label,
};

/// Dòng chính của một lựa chọn lô: "LOT-001 · Cua Cù Mau".
/// Mã lô một mình không đủ để người nuôi nhận ra lô nào.
String lotOptionLabel(({String id, String code, String name, String meta}) lot) =>
    lot.name.isEmpty ? lot.code : '${lot.code} · ${lot.name}';

/// Dòng phụ: "còn 0/2 · 04/09" — số còn lại trong lô + ngày nhập.
String lotOptionMeta(dynamic quantity, dynamic placed, String importDate) {
  final parts = <String>[];

  final q = int.tryParse('${quantity ?? ''}');
  if (q != null && q > 0) {
    final p = int.tryParse('${placed ?? ''}') ?? 0;
    parts.add('còn ${(q - p).clamp(0, q)}/$q');
  }

  final d = DateTime.tryParse(importDate);
  if (d != null) {
    parts.add(
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
    );
  }

  return parts.join(' · ');
}
/// Danh sách cua trong một hộp nuôi.
/// - Hộp trống: hiện FAB + empty state rõ ràng
/// - Có cua: danh sách + FAB thêm + nút di chuyển
class CrabListScreen extends StatefulWidget {
  const CrabListScreen({
    super.key,
    required this.boxId,
    this.boxCode,
  });

  final String boxId;
  final String? boxCode;

  @override
  State<CrabListScreen> createState() => _CrabListScreenState();
}

class _CrabListScreenState extends State<CrabListScreen> {
  List<CrabModel> _crabs = [];
  bool _loading = true;
  Object? _error;
  final _historyKey = GlobalKey<BoxHistoryPanelState>();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await sl<BoxRemoteDataSource>().getCrabsByBox(widget.boxId);
      if (!mounted) return;
      setState(() {
        _crabs = list;
        _loading = false;
      });
      _historyKey.currentState?.reload();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _danger : _primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Thêm cua vào hộp ──────────────────────────────────────────────────────
  void _showAddCrabSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCrabSheet(
        boxId: widget.boxId,
        boxCode: widget.boxCode ?? widget.boxId.substring(0, 8),
        onSuccess: (crab) async {
          setState(() {
            _crabs = [crab, ..._crabs.where((c) => c.id != crab.id)];
            _loading = false;
            _error = null;
          });
          _snack('Đã nhập cua vào hộp');
          try {
            final list =
                await sl<BoxRemoteDataSource>().getCrabsByBox(widget.boxId);
            if (!mounted || list.isEmpty) return;
            setState(() => _crabs = list);
          } catch (_) {}
        },
      ),
    );
  }

  // ── Di chuyển cua sang hộp khác ───────────────────────────────────────────
  void _showMoveCrabSheet(CrabModel crab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoveCrabSheet(
        crab: crab,
        currentBoxId: widget.boxId,
        onSuccess: (targetBoxCode) {
          _snack('Đã chuyển cua sang hộp $targetBoxCode');
          _refresh();
        },
      ),
    );
  }

  Future<void> _onCareResult(String result) async {
    if (!mounted) return;
    final msg = result == 'ended'
        ? 'Đã kết thúc hộp — hộp trống'
        : 'Đã lưu phiếu hôm nay';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));

    // Lưu xong là quay về danh sách hộp — đúng dòng gợi ý trong phiếu ("lưu xong sẽ
    // quay về danh sách hộp") để nông dân đi tiếp hộp khác. Danh sách hộp tự làm mới
    // khi nhận lại quyền điều hướng (xem `_handleBoxTap` trong boxes_screen), nên
    // không cần `_refresh()` ở đây nữa.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    if (context.canPop()) context.pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final boxLabel = widget.boxCode?.isNotEmpty == true
        ? widget.boxCode!
        : widget.boxId.substring(0, 8).toUpperCase();

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(boxLabel),
      floatingActionButton: null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _ErrorState(
                  message: _error.toString(),
                  onRetry: _refresh,
                )
              : RefreshIndicator(
                  color: _primary,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      if (_crabs.isEmpty)
                        _EmptyState(onAdd: _showAddCrabSheet)
                      else ...[
                        _CrabTile(
                          crab: _crabs.first,
                          index: 1,
                          onTap: () => context.push(
                            RoutePaths.crabDetails(
                              _crabs.first.id,
                              boxId: widget.boxId,
                              boxCode: widget.boxCode,
                            ),
                            extra: _crabs.first,
                          ),
                          onMove: () => _showMoveCrabSheet(_crabs.first),
                        ),
                        const SizedBox(height: 12),
                        DailyBoxCareSheet(
                          key: ValueKey(_crabs.first.id),
                          boxId: widget.boxId,
                          boxCode: widget.boxCode ??
                              widget.boxId.substring(0, 8),
                          crab: _crabs.first,
                          embedded: true,
                          onResult: _onCareResult,
                        ),
                      ],
                      // Chưa có cua ⇒ KHÔNG hiện biểu đồ. Không có cua thì không có phiếu,
                      // và biểu đồ sẽ dựng 7 ngày giá trị 0 rồi vẽ thành đường phẳng ở
                      // "Không ăn"/"Yếu" — trông như đã theo dõi và cua bỏ ăn, trong khi
                      // thực tế hộp trống.
                      if (_crabs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        BoxHistoryPanel(
                          key: _historyKey,
                          boxId: widget.boxId,
                          boxCode: widget.boxCode,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(String boxLabel) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Material(
        color: _surface,
        elevation: 0,
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 6, 8, 8),
            decoration: const BoxDecoration(
              color: _surface,
              border: Border(
                bottom: BorderSide(color: _border),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _primaryDk,
                    size: 18,
                  ),
                  onPressed: () => context.pop(),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 18,
                    color: _primaryDk,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hộp $boxLabel',
                        style: const TextStyle(
                          color: _primaryDk,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Cua · phiếu · lịch sử',
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _refresh,
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: CrabSenseColors.primaryMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: _primaryDk,
                      ),
                    ),
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

// ── Crab tile ──────────────────────────────────────────────────────────────────
class _CrabTile extends StatelessWidget {
  const _CrabTile({
    required this.crab,
    required this.index,
    required this.onTap,
    required this.onMove,
  });

  final CrabModel crab;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final tag = crabDisplayTag(crab);
    final weightG = crab.weight.round();
    // Tình trạng cua lấy từ trường `Condition` của BE rồi quy về 5 nhãn của
    // [BoxStatus] — cùng bảng với thẻ hộp và app desktop. Trước đây huy hiệu in
    // nhãn chi tiết ("Đang lột", "Cua lột mềm", "Có vấn đề", "Cua yếu") nên
    // cùng một con cua lại mang chữ khác với thẻ hộp.
    final status = displayStatusOf(CrabCondition.tryParse(crab.condition));
    final statusColor = status.color;
    final statusLabel = status.label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              const CrabAvatar(size: 46),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tag, style: const TextStyle(fontWeight: FontWeight.w700, color: _textMain, fontSize: 14)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.monitor_weight_outlined, size: 13, color: _textSub),
                        const SizedBox(width: 4),
                        Text('${weightG}g', style: const TextStyle(color: _textSub, fontSize: 12)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      // Bỏ "vỏ / lột" khỏi dòng phụ: BE không trả `moltingStage` nên
                      // trước đây lúc nào cũng in "Vỏ cứng", mà tình trạng lột đã có
                      // huy hiệu ngay trên rồi.
                      '${crabSpeciesVi(crab.species)} • ${crabSourceVi(crab.source)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _textSub, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Move button
              IconButton(
                tooltip: 'Di chuyển sang hộp khác',
                icon: const Icon(Icons.swap_horiz_rounded, color: _textSub, size: 22),
                onPressed: onMove,
              ),
              const Icon(Icons.chevron_right_rounded, color: _textSub, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          const CrabAvatar(size: 72),
          const SizedBox(height: 16),
          const Text(
            'Hộp chưa có cua',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mỗi hộp chỉ nuôi 1 con. Nhấn nút bên dưới để nhập cua.',
            style: TextStyle(
              color: _textSub,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Thêm cua ngay',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryDk,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _danger, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _textSub)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet: Thêm cua ────────────────────────────────────────────────────
class _AddCrabSheet extends StatefulWidget {
  const _AddCrabSheet({
    required this.boxId,
    required this.boxCode,
    required this.onSuccess,
  });
  final String boxId;
  final String boxCode;
  final void Function(CrabModel crab) onSuccess;

  @override
  State<_AddCrabSheet> createState() => _AddCrabSheetState();
}

class _AddCrabSheetState extends State<_AddCrabSheet> {
  final _api = sl<ApiClient>();
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _crabTypeCtrl = TextEditingController();
  String _gender = 'male';
  String _shell = 'hard';
  String _spots = 'few';
  String _condition = 'normal';
  final List<XFile> _images = [];
  bool _submitting = false;
  bool _loadingLots = true;
  List<({String id, String code, String name, String meta})> _lots = [];
  String? _selectedLotId;
  bool _createNewLot = false;
  final _newLotCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  Future<void> _loadLots() async {
    try {
      final res = await _api.get<dynamic>(ApiConstants.crabLots);
      final decoded = jsonDecode(jsonEncode(res.data));
      final list = <({String id, String code, String name, String meta})>[];
      dynamic raw = decoded;
      if (decoded is Map) raw = decoded['data'] ?? decoded;
      if (raw is List) {
        for (final item in raw) {
          if (item is! Map) continue;
          final id = (item['id'] ?? item['Id'])?.toString() ?? '';
          final code =
              (item['lotCode'] ?? item['LotCode'] ?? item['code'])?.toString() ??
                  '';
          if (id.isEmpty) continue;
          list.add((
            id: id,
            code: code.isEmpty ? id : code,
            name: (item['name'] ?? item['Name'])?.toString() ?? '',
            meta: lotOptionMeta(
              item['quantity'] ?? item['Quantity'],
              item['placedCount'] ?? item['PlacedCount'],
              (item['importDate'] ?? item['ImportDate'])?.toString() ?? '',
            ),
          ));
        }
      }
      if (mounted) {
        setState(() {
          _lots = list;
          _selectedLotId = list.isNotEmpty ? list.first.id : null;
          _createNewLot = list.isEmpty;
          _loadingLots = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingLots = false;
          _createNewLot = true;
        });
      }
    }
  }

  Future<String?> _ensureLotId() async {
    if (!_createNewLot && _selectedLotId != null) return _selectedLotId;
    final code = _newLotCtrl.text.trim().isNotEmpty
        ? _newLotCtrl.text.trim()
        : 'LOT-${DateTime.now().millisecondsSinceEpoch}';
    final res = await _api.post<dynamic>(ApiConstants.crabLots, data: {
      'lotCode': code,
      'importDate': DateTime.now().toUtc().toIso8601String(),
    });
    final decoded = jsonDecode(jsonEncode(res.data));
    if (decoded is Map) {
      final data = decoded['data'];
      if (data is Map) {
        return (data['id'] ?? data['Id'])?.toString();
      }
    }
    return null;
  }

  /// Hỏi nguồn ảnh trước: chụp tại chỗ hay lấy ảnh có sẵn.
  Future<ImageSource?> _askImageSource() => showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
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
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Thêm ảnh cua',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 14),
              _sourceTile(
                icon: Icons.photo_camera_outlined,
                label: 'Chụp ảnh',
                hint: 'Mở camera chụp trực tiếp',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _sourceTile(
                icon: Icons.photo_library_outlined,
                label: 'Chọn từ thư viện',
                hint: 'Lấy tối đa $_maxImages ảnh có sẵn',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

  Widget _sourceTile({
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kHomeBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(icon, color: _primaryDk),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textMain,
                        ),
                      ),
                      Text(
                        hint,
                        style: const TextStyle(fontSize: 12, color: _textSub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _pickImages() async {
    if (_images.length >= _maxImages) return;
    final source = await _askImageSource();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    List<XFile> picked = const [];
    try {
      if (source == ImageSource.camera) {
        final shot = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
        if (shot != null) picked = [shot];
      } else {
        picked = await picker.pickMultiImage(imageQuality: 70);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          source == ImageSource.camera
              ? 'Không mở được camera: $error'
              : 'Không chọn được ảnh: $error',
        ),
        backgroundColor: _danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!mounted || picked.isEmpty) return;
    setState(() {
      for (final f in picked) {
        if (_images.length >= _maxImages) break;
        _images.add(f);
      }
    });
  }

  /// Đẩy ảnh lên S3 trước, lấy URL để gửi kèm khi tạo cua (BE không nhận file thô).
  Future<List<String>> _uploadImages() async {
    if (_images.isEmpty) return const [];
    final form = FormData.fromMap({
      'files': [
        for (final f in _images)
          MultipartFile.fromBytes(
            await f.readAsBytes(),
            filename: f.name.isNotEmpty
                ? f.name
                : 'crab_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      ],
    });
    final res =
        await _api.dio.post<dynamic>(ApiConstants.crabImages, data: form);
    final decoded = jsonDecode(jsonEncode(res.data));
    dynamic raw = decoded is Map ? (decoded['data'] ?? decoded) : decoded;
    if (raw is Map) raw = raw['items'] ?? raw['data'] ?? raw;
    final urls = <String>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final url = (item['url'] ??
                item['Url'] ??
                item['storageKey'] ??
                item['StorageKey'])
            ?.toString();
        if (url != null && url.isNotEmpty) urls.add(url);
      }
    }
    if (urls.isEmpty) throw Exception('Upload ảnh không trả về URL');
    return urls;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _notesCtrl.dispose();
    _crabTypeCtrl.dispose();
    _newLotCtrl.dispose();
    super.dispose();
  }

  /// UI nhập cm nhưng BE lưu mm (CarapaceLengthMm / CarapaceWidthMm).
  double? _toMm(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    return v == null ? null : v * 10;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final crabTag = 'CRAB-${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _submitting = true);
    try {
      final isMale = _gender == 'male';
      final weight = int.parse(_weightCtrl.text.trim());
      String? lotId;
      try {
        lotId = await _ensureLotId();
      } catch (_) {
        lotId = null; // BE may auto-create lot when omitted.
      }
      final imageUrls = await _uploadImages();
      final lengthMm = _toMm(_lengthCtrl);
      final widthMm = _toMm(_widthCtrl);
      final crabType = _crabTypeCtrl.text.trim();
      final notes = _notesCtrl.text.trim();

      final res = await _api.post<dynamic>(
        ApiConstants.addCrabToBox(widget.boxId),
        data: {
          'weightGram': weight,
          'tag': crabTag,
          'gender': _gender,
          'condition': _condition,
          if (crabType.isNotEmpty) 'crabType': crabType,
          if (lotId != null && lotId.isNotEmpty) 'crabLotId': lotId,
          if (isMale) 'moltingStage': _shell,
          if (!isMale) 'roeStatus': _spots,
          if (lengthMm != null) 'carapaceLengthMm': lengthMm,
          if (widthMm != null) 'carapaceWidthMm': widthMm,
          if (notes.isNotEmpty) 'notes': notes,
          if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        },
      );
      final decoded = jsonDecode(jsonEncode(res.data));
      if (decoded is Map && decoded['success'] == false) {
        throw decoded['message'] ?? 'Không lưu được cua';
      }
      Map<String, dynamic> payload = {
        'id': '',
        'boxId': widget.boxId,
        'tag': crabTag,
        'weightGram': weight,
        'moltingStage': isMale ? _shell : 'hardShell',
      };
      if (decoded is Map) {
        final data = decoded['data'];
        if (data is Map) {
          payload = Map<String, dynamic>.from(data);
        }
      }
      final crab = CrabModel.fromJson(payload);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess(crab);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi nhập cua: $error'),
        backgroundColor: _danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isMale = _gender == 'male';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nhập cua · ${widget.boxCode}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chỉ điền những gì cần theo dõi.',
                style: TextStyle(fontSize: 13, color: _textSub, height: 1.35),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lô nhập',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingLots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(color: _primary),
                )
              else ...[
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Chọn lô'),
                      selected: !_createNewLot,
                      onSelected: _lots.isEmpty
                          ? null
                          : (_) => setState(() => _createNewLot = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Tạo lô mới'),
                      selected: _createNewLot,
                      onSelected: (_) => setState(() => _createNewLot = true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!_createNewLot && _lots.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedLotId,
                    isExpanded: true,
                    // Ô đã chọn chỉ cao 24px -> phải là bản 1 dòng, nếu không sẽ tràn.
                    selectedItemBuilder: (_) => [
                      for (final lot in _lots)
                        Text(
                          lotOptionLabel(lot),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textMain,
                          ),
                        ),
                    ],
                    decoration: _deco('Lô cua'),
                    items: [
                      for (final lot in _lots)
                        DropdownMenuItem(
                          value: lot.id,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lotOptionLabel(lot),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _textMain,
                                ),
                              ),
                              if (lot.meta.isNotEmpty)
                                Text(
                                  lot.meta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _textSub,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _selectedLotId = v),
                  )
                else
                  TextFormField(
                    controller: _newLotCtrl,
                    decoration: _deco('VD: LOT-2026-09'),
                  ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Cân nặng (g)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _deco('220'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nhập cân nặng';
                  if ((int.tryParse(v.trim()) ?? 0) <= 0) return 'Không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Kích thước (không bắt buộc)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _numberField(_lengthCtrl, 'Dài cm')),
                  const SizedBox(width: 10),
                  Expanded(child: _numberField(_widthCtrl, 'Rộng cm')),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Giới tính',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 8),
              _OptionPills(
                value: _gender,
                options: const {'male': 'Đực', 'female': 'Cái'},
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 16),
              Text(
                isMale ? 'Tình trạng vỏ' : 'Gạch cua',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 8),
              if (isMale)
                _OptionPills(
                  value: _shell,
                  options: const {
                    'hard': 'Cứng',
                    'medium': 'Vừa',
                    'soft': 'Mềm',
                  },
                  onChanged: (v) => setState(() => _shell = v),
                )
              else
                _OptionPills(
                  value: _spots,
                  options: const {
                    'none': 'Không gạch',
                    'few': 'Ít gạch',
                    'many': 'Có gạch',
                  },
                  onChanged: (v) => setState(() => _spots = v),
                ),
              const SizedBox(height: 16),
              const Text(
                'Loại cua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _crabTypeCtrl,
                decoration: _deco('VD: Cua biển'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tình trạng cua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Quyết định màu hộp và cách chăm sóc.',
                style: TextStyle(fontSize: 12, color: _textSub),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _conditionOptions.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _condition == entry.key,
                      onSelected: (_) =>
                          setState(() => _condition = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ảnh cua (${_images.length}/$_maxImages)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 8),
              _imagePicker(),
              const SizedBox(height: 16),
              const Text(
                'Ghi chú',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: _deco('Không bắt buộc'),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryDk,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePicker() => SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _images.length + (_images.length < _maxImages ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            if (i >= _images.length) {
              return InkWell(
                onTap: _pickImages,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 84,
                  decoration: BoxDecoration(
                    color: kHomeBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: _primaryDk),
                      SizedBox(height: 4),
                      Text(
                        'Thêm ảnh',
                        style: TextStyle(fontSize: 11, color: _textSub),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LocalFileImage(
                    path: _images[i].path,
                    width: 84,
                    height: 84,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: InkWell(
                    onTap: () => setState(() => _images.removeAt(i)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _numberField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: _deco(label),
      );

  InputDecoration _deco(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: _textSub,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
    filled: true,
    fillColor: kHomeBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primaryDk, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _danger)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _danger)),
  );
}

class _OptionPills extends StatelessWidget {
  const _OptionPills({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in options.entries) ...[
          if (entry.key != options.keys.first) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(entry.key),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == entry.key ? _primaryDk : kHomeBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: value == entry.key ? _primaryDk : _border,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: value == entry.key ? Colors.white : _textMain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Bottom sheet: Di chuyển cua ───────────────────────────────────────────────
class _MoveCrabSheet extends StatefulWidget {
  const _MoveCrabSheet({
    required this.crab,
    required this.currentBoxId,
    required this.onSuccess,
  });
  final CrabModel crab;
  final String currentBoxId;
  final void Function(String targetBoxCode) onSuccess;

  @override
  State<_MoveCrabSheet> createState() => _MoveCrabSheetState();
}

class _MoveCrabSheetState extends State<_MoveCrabSheet> {
  final _api = sl<ApiClient>();
  List<Map<String, dynamic>> _boxes = [];
  Map<String, dynamic>? _selectedBox;
  bool _loading = true;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    _loadBoxes();
  }

  Future<void> _loadBoxes() async {
    try {
      final r = await _api.get<dynamic>('/boxes/available');
      final data = r.data;
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map) {
        final nested = data['data'];
        if (nested is Map) {
          items = (nested['emptyBoxes'] as List?) ??
              (nested['items'] as List?) ??
              (nested['data'] as List?) ??
              const [];
        } else {
          items = (data['emptyBoxes'] as List?) ??
              (data['items'] as List?) ?? const [];
        }
      }
      setState(() {
        _boxes = items
            .where((b) => b is Map && b['id'] != widget.currentBoxId)
            .map((b) => {
                  'id': b['id'] as String,
                  'code': (b['code'] ?? b['id']) as String,
                  'rowName': b['rowName']?.toString(),
                  'areaName': b['areaName']?.toString(),
                })
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _move() async {
    if (_selectedBox == null) return;
    setState(() => _moving = true);
    try {
      // POST /allocations/transfer — di chuyển cua
      await _api.post<dynamic>('/allocations/transfer', data: {
        'crabId': widget.crab.id,
        'sourceBoxId': widget.currentBoxId,
        'destinationBoxId': _selectedBox!['id'],
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(_selectedBox!['code'] as String);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi chuyển cua: $e'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: _primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Di chuyển cua sang hộp khác',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cân nặng: ${widget.crab.weight.round()}g',
            style: const TextStyle(color: _textSub),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: _primary))
          else if (_boxes.isEmpty)
            const Text('Không có hộp khác để chuyển', style: TextStyle(color: _textSub))
          else ...[
            const Text('Chọn hộp đích', style: TextStyle(fontWeight: FontWeight.w600, color: _textMain)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedBox,
              isExpanded: true,
              isDense: true,
              hint: const Text(
                'Chọn hộp...',
                style: TextStyle(color: Color(0xFF9DB3C2)),
                overflow: TextOverflow.ellipsis,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
              ),
              items: _boxes.map((b) {
                final label = [b['code'], b['rowName'], b['areaName']]
                    .whereType<String>()
                    .where((s) => s.trim().isNotEmpty)
                    .join(' • ');
                return DropdownMenuItem(
                  value: b,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedBox = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedBox == null || _moving) ? null : _move,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: const Color(0xFFB2DFDB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _moving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Chuyển cua', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
