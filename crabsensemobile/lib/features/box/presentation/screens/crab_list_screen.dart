import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/box_remote_data_source.dart';
import '../../data/models/crab_model.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _primary    = Color(0xFF27AE60);
const _primaryDk  = Color(0xFF1E8449);
const _primaryBg  = Color(0xFFD5F5E3);
const _bg         = Color(0xFFF0F3F7);
const _surface    = Color(0xFFFFFFFF);
const _textMain   = Color(0xFF1A2E3B);
const _textSub    = Color(0xFF5A7184);
const _border     = Color(0xFFDDE4EB);
const _danger     = Color(0xFFE74C3C);
const _warning    = Color(0xFFF39C12);

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
  late Future<List<CrabModel>> _future;
  final _api = sl<ApiClient>();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CrabModel>> _load() =>
      sl<BoxRemoteDataSource>().getCrabsByBox(widget.boxId);

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
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
        onSuccess: (count) {
          _refresh();
          _snack('Đã nhập $count con cua vào hộp');
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
          _refresh();
          _snack('Đã chuyển cua sang hộp $targetBoxCode');
        },
      ),
    );
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
      floatingActionButton: FutureBuilder<List<CrabModel>>(
        future: _future,
        builder: (context, snapshot) {
          if ((snapshot.data ?? const <CrabModel>[]).isNotEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _showAddCrabSheet,
            backgroundColor: _primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Nhập cua',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
      body: FutureBuilder<List<CrabModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onRetry: _refresh,
            );
          }
          final crabs = snap.data ?? [];
          return RefreshIndicator(
            color: _primary,
            onRefresh: _refresh,
            child: crabs.isEmpty
                ? _EmptyState(onAdd: _showAddCrabSheet)
                : _CrabList(
                    crabs: crabs,
                    onTapCrab: (crab) => context.push(
                      RoutePaths.crabDetails(crab.id, boxId: widget.boxId),
                      extra: crab,
                    ),
                    onMoveCrab: _showMoveCrabSheet,
                  ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String boxLabel) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E8449), Color(0xFF27AE60)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hộp $boxLabel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Danh sách cua',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _refresh,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Crab list ─────────────────────────────────────────────────────────────────
class _CrabList extends StatelessWidget {
  const _CrabList({
    required this.crabs,
    required this.onTapCrab,
    required this.onMoveCrab,
  });

  final List<CrabModel> crabs;
  final void Function(CrabModel) onTapCrab;
  final void Function(CrabModel) onMoveCrab;

  @override
  Widget build(BuildContext context) {
    // Stats header
    final alive = crabs.length;
    final avgWeight = crabs.isEmpty
        ? 0
        : (crabs.fold(0.0, (s, c) => s + c.weight) / crabs.length).round();

    return Column(
      children: [
        // Stats bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E8449), Color(0xFF27AE60)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _statItem('Tổng cua', '$alive con'),
              Container(width: 1, height: 32, color: Colors.white30),
              _statItem('Còn sống', '$alive con'),
              Container(width: 1, height: 32, color: Colors.white30),
              _statItem('TB cân nặng', '${avgWeight}g'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: crabs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _CrabTile(
              crab: crabs[i],
              index: i + 1,
              onTap: () => onTapCrab(crabs[i]),
              onMove: () => onMoveCrab(crabs[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ],
    ),
  );
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
    final tag = crab.addedBy.isNotEmpty ? crab.addedBy : 'Cua #$index';
    final weightG = crab.weight.round();
    final isHealthy = crab.healthStatus.name.toLowerCase() != 'disease' &&
        crab.healthStatus.name.toLowerCase() != 'stress';
    final statusColor = isHealthy ? _primary : _warning;
    final statusLabel = isHealthy ? 'Bình thường' : 'Cần theo dõi';

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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _primaryBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.pest_control_rounded, color: _primaryDk, size: 22),
              ),
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
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
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
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: _primaryBg, shape: BoxShape.circle),
                child: const Icon(Icons.pest_control_rounded, color: _primaryDk, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Hộp chưa có cua',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textMain)),
              const SizedBox(height: 8),
              const Text('Nhấn nút "Thêm cua" để nhập cua vào hộp này',
                  style: TextStyle(color: _textSub), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Thêm cua ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
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
  final void Function(int count) onSuccess;

  @override
  State<_AddCrabSheet> createState() => _AddCrabSheetState();
}

class _AddCrabSheetState extends State<_AddCrabSheet> {
  final _api = sl<ApiClient>();
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _gender = 'male';
  String _shell = 'hard';
  String _spots = 'few';
  bool _submitting = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _tagCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _generateTag() {
    if (_tagCtrl.text.isEmpty) {
      _tagCtrl.text = 'CRAB-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _generateTag();
    setState(() => _submitting = true);
    try {
      await _api.post<dynamic>('/boxes/${widget.boxId}/crabs', data: {
        'weightGram': int.parse(_weightCtrl.text.trim()),
        'tag': _tagCtrl.text.trim(),
        'moltingStage': _shell,
      });
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess(1);
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
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                const Icon(Icons.add_circle_rounded, color: _primary),
                const SizedBox(width: 8),
                Text('Thêm cua vào hộp ${widget.boxCode}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textMain)),
              ],
            ),
            const SizedBox(height: 20),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cân nặng (gram) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _deco('Ví dụ: 220'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Nhập cân nặng';
                      if ((int.tryParse(v.trim()) ?? 0) <= 0) return 'Không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Mã cua (tự sinh)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _tagCtrl,
                    readOnly: true,
                    decoration: _deco('Tự sinh khi lưu'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _numberField(_lengthCtrl, 'Chiều dài (cm)')),
                      const SizedBox(width: 10),
                      Expanded(child: _numberField(_widthCtrl, 'Chiều rộng (cm)')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Giới tính', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: _deco(null),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Đực')),
                      DropdownMenuItem(value: 'female', child: Text('Cái')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? 'male'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _choiceField('Vỏ lúc nhập', _shell, const {'hard': 'Cứng', 'soft': 'Mềm'}, (v) => setState(() => _shell = v))),
                      const SizedBox(width: 10),
                      Expanded(child: _choiceField('Gạch', _spots, const {'few': 'Ít', 'many': 'Nhiều'}, (v) => setState(() => _spots = v))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Ghi chú tình trạng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: _deco('Tuỳ chọn...'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 8),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: const Color(0xFFB2DFDB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Nhập 1 con cua vào hộp',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) => TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: _deco(label),
      );

  Widget _choiceField(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
        value: value,
        decoration: _deco(label),
        items: options.entries
            .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
            .toList(),
        onChanged: (next) => onChanged(next ?? value),
      );

  InputDecoration _deco(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9DB3C2)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _danger)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _danger)),
  );
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
      final r = await _api.get<dynamic>('/boxes');
      final data = r.data;
      List<dynamic> items = [];
      if (data is Map) items = (data['items'] as List? ?? []);
      else if (data is List) items = data;
      setState(() {
        _boxes = items
            .where((b) => b['id'] != widget.currentBoxId)
            .map((b) => {'id': b['id'] as String, 'code': (b['code'] ?? b['id']) as String})
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
              const Text('Di chuyển cua sang hộp khác',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textMain)),
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
              hint: const Text('Chọn hộp...', style: TextStyle(color: Color(0xFF9DB3C2))),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
              ),
              items: _boxes.map((b) => DropdownMenuItem(
                value: b,
                child: Text(b['code'] as String),
              )).toList(),
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
