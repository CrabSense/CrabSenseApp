import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const Color _primary    = Color(0xFF27AE60);
const Color _primaryDk  = Color(0xFF1E8449);
const Color _bg         = Color(0xFFF0F3F7);
const Color _surface    = Color(0xFFFFFFFF);
const Color _textMain   = Color(0xFF1A2E3B);
const Color _textSub    = Color(0xFF5A7184);
const Color _border     = Color(0xFFDDE4EB);
const Color _danger     = Color(0xFFE74C3C);

// ── Simple models ─────────────────────────────────────────────────────────────
class _FarmArea {
  const _FarmArea({required this.id, required this.name});
  final String id;
  final String name;
}

class _FarmRow {
  const _FarmRow({
    required this.id,
    required this.name,
    required this.capacity,
    required this.boxCount,
  });
  final String id;
  final String name;
  final int capacity;
  final int boxCount;
}

class _Box {
  const _Box({required this.id, required this.code});
  final String id;
  final String code;
}

class _CrabEntry {
  _CrabEntry({
    required this.weightGram,
    this.tag,
    this.source = 'purchase',
    this.notes,
  });
  final int weightGram;
  final String? tag;
  final String source;
  final String? notes;
}

// ── Screen ────────────────────────────────────────────────────────────────────
class AddCrabScreen extends StatefulWidget {
  const AddCrabScreen({super.key});

  @override
  State<AddCrabScreen> createState() => _AddCrabScreenState();
}

class _AddCrabScreenState extends State<AddCrabScreen> {
  // Step
  int _step = 0; // 0 = chọn hộp, 1 = nhập cua, 2 = xác nhận

  // Step 1 — box selection
  final ApiClient _api = sl<ApiClient>();

  List<_FarmArea> _areas = [];
  List<_FarmRow> _rows = [];
  List<_Box> _boxes = [];

  _FarmArea? _selectedArea;
  _FarmRow? _selectedRow;
  _Box? _selectedBox;

  bool _loadingAreas = false;
  bool _loadingRows  = false;
  bool _loadingBoxes = false;
  bool _creatingBox  = false;

  // Step 2 — crab entries
  final List<_CrabEntry> _crabs = [];

  // Step 2 form fields
  final _weightCtrl  = TextEditingController();
  final _tagCtrl     = TextEditingController();
  final _notesCtrl   = TextEditingController();
  String _source = 'purchase';
  final _formKey2 = GlobalKey<FormState>();

  // Step 3 — submission
  bool _submitting = false;

  static const _sourceOptions = [
    ('purchase', 'Mua về'),
    ('farm',     'Trại tự nuôi'),
    ('transfer', 'Chuyển kho'),
  ];

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _tagCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── API calls ───────────────────────────────────────────────────────────────
  Future<void> _fetchAreas() async {
    setState(() => _loadingAreas = true);
    try {
      final r = await _api.get<Map<String, dynamic>>('/farming-areas');
      final body = r.data ?? {};
      final items = (body['items'] as List? ?? []);
      setState(() {
        _areas = items
            .map((e) => _FarmArea(id: e['id'] as String, name: e['name'] as String))
            .toList();
      });
    } catch (e) {
      _showError('Lỗi tải khu nuôi: $e');
    } finally {
      setState(() => _loadingAreas = false);
    }
  }

  Future<void> _fetchRows(String areaId) async {
    setState(() { _loadingRows = true; _rows = []; _selectedRow = null; _boxes = []; _selectedBox = null; });
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/farming-rows',
        queryParameters: {'farmingAreaId': areaId},
      );
      final body = r.data ?? {};
      final items = (body['items'] as List? ?? []);
      setState(() {
        _rows = items.map((e) => _FarmRow(
          id:       e['id'] as String,
          name:     e['name'] as String,
          capacity: (e['capacity'] as num?)?.toInt() ?? 0,
          boxCount: (e['boxCount'] as num?)?.toInt() ?? 0,
        )).toList();
      });
    } catch (e) {
      _showError('Lỗi tải dãy: $e');
    } finally {
      setState(() => _loadingRows = false);
    }
  }

  Future<void> _fetchBoxes(String areaId) async {
    setState(() { _loadingBoxes = true; _boxes = []; _selectedBox = null; });
    try {
      final r = await _api.get<dynamic>(
        '/boxes',
        queryParameters: {'farmingAreaId': areaId},
      );
      final data = r.data;
      List<dynamic> items = [];
      if (data is Map) {
        items = (data['items'] as List? ?? []);
      } else if (data is List) {
        items = data;
      }
      setState(() {
        _boxes = items.map((e) => _Box(
          id:   e['id'] as String,
          code: (e['code'] ?? e['name'] ?? e['id']) as String,
        )).toList();
      });
    } catch (e) {
      _showError('Lỗi tải hộp: $e');
    } finally {
      setState(() => _loadingBoxes = false);
    }
  }

  Future<void> _createBox() async {
    if (_selectedRow == null) return;
    setState(() => _creatingBox = true);
    try {
      final body = <String, dynamic>{'farmingRowId': _selectedRow!.id};
      if (_selectedArea != null) body['farmingAreaId'] = _selectedArea!.id;
      final r = await _api.post<Map<String, dynamic>>('/boxes', data: body);
      final created = r.data ?? {};
      final newBox = _Box(
        id:   created['id'] as String,
        code: (created['code'] ?? created['name'] ?? created['id']) as String,
      );
      setState(() {
        _boxes = [..._boxes, newBox];
        _selectedBox = newBox;
      });
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Text('Tạo hộp thành công', style: TextStyle(color: _textMain)),
            content: Text('Đã tạo hộp ${newBox.code}.', style: const TextStyle(color: _textSub)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: _primary)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Lỗi tạo hộp: $e');
    } finally {
      setState(() => _creatingBox = false);
    }
  }

  Future<void> _submitAll() async {
    if (_selectedBox == null || _crabs.isEmpty) return;
    setState(() => _submitting = true);
    int successCount = 0;
    try {
      for (final crab in _crabs) {
        final body = <String, dynamic>{'weightGram': crab.weightGram};
        if (crab.tag != null && crab.tag!.isNotEmpty) body['tag'] = crab.tag;
        if (crab.source.isNotEmpty) body['source'] = crab.source;
        if (crab.notes != null && crab.notes!.isNotEmpty) body['notes'] = crab.notes;
        await _api.post<dynamic>('/boxes/${_selectedBox!.id}/crabs', data: body);
        successCount++;
      }
      if (mounted) _showSuccessSheet(successCount);
    } catch (e) {
      _showError('Lỗi nhập cua ($successCount/${_crabs.length} thành công): $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _addCrab() {
    if (!(_formKey2.currentState?.validate() ?? false)) return;
    setState(() {
      _crabs.add(_CrabEntry(
        weightGram: int.parse(_weightCtrl.text.trim()),
        tag:        _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
        source:     _source,
        notes:      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
      _weightCtrl.clear();
      _tagCtrl.clear();
      _notesCtrl.clear();
      _source = 'purchase';
    });
  }

  void _showSuccessSheet(int count) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(color: Color(0xFFD5F5E3), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: _primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Đã nhập $count con cua vào hộp ${_selectedBox?.code ?? ""}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textMain),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tổng cân nặng: ${_crabs.fold(0, (s, c) => s + c.weightGram)} gram',
                style: const TextStyle(color: _textSub),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Về trang chủ', style: TextStyle(color: _primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Xem chi tiết', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _StepIndicator(currentStep: _step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _step == 0
                    ? _buildStep1()
                    : _step == 1
                        ? _buildStep2()
                        : _buildStep3(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
            onPressed: () {
              if (_step > 0) {
                setState(() => _step--);
              } else {
                Navigator.maybePop(context);
              }
            },
          ),
          title: const Text(
            'Nhập cua',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: true,
        ),
      ),
    );
  }

  // ── Step 1: Chọn hộp ─────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Chọn khu nuôi', Icons.location_on_outlined),
              const SizedBox(height: 12),
              _loadingAreas
                  ? const Center(child: CircularProgressIndicator(color: _primary))
                  : _dropdown<_FarmArea>(
                      hint: 'Chọn khu nuôi...',
                      value: _selectedArea,
                      items: _areas,
                      label: (a) => a.name,
                      onChanged: (a) {
                        setState(() { _selectedArea = a; _selectedRow = null; _boxes = []; _selectedBox = null; });
                        if (a != null) { _fetchRows(a.id); _fetchBoxes(a.id); }
                      },
                    ),
              const SizedBox(height: 16),
              _sectionTitle('Chọn dãy', Icons.grid_view_rounded),
              const SizedBox(height: 12),
              _loadingRows
                  ? const Center(child: CircularProgressIndicator(color: _primary))
                  : _dropdown<_FarmRow>(
                      hint: 'Chọn dãy...',
                      value: _selectedRow,
                      items: _rows,
                      label: (r) => '${r.name} (${r.boxCount}/${r.capacity} hộp)',
                      onChanged: (r) => setState(() => _selectedRow = r),
                    ),
              const SizedBox(height: 16),
              _sectionTitle('Chọn hộp', Icons.inventory_2_outlined),
              const SizedBox(height: 12),
              _loadingBoxes
                  ? const Center(child: CircularProgressIndicator(color: _primary))
                  : _dropdown<_Box>(
                      hint: 'Chọn hộp...',
                      value: _selectedBox,
                      items: _boxes,
                      label: (b) => b.code,
                      onChanged: (b) => setState(() => _selectedBox = b),
                    ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_selectedRow == null || _creatingBox) ? null : _createBox,
                  icon: _creatingBox
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
                      : const Icon(Icons.add_box_outlined, color: _primary),
                  label: Text(
                    _creatingBox ? 'Đang tạo...' : 'Tạo hộp mới',
                    style: const TextStyle(color: _primary, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _primaryBtn(
          label: 'Tiếp tục →',
          enabled: _selectedBox != null,
          onPressed: () => setState(() => _step = 1),
        ),
      ],
    );
  }

  // ── Step 2: Nhập thông tin cua ───────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form nhập thông tin cua
        _card(
          child: Form(
            key: _formKey2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Thông tin cua', Icons.pets_rounded),
                const SizedBox(height: 16),
                _label('Cân nặng (gram) *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDeco('Ví dụ: 220'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập cân nặng';
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Cân nặng không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _label('Mã cua (tag)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _tagCtrl,
                  decoration: _inputDeco('Ví dụ: CRAB-001 (tuỳ chọn)'),
                ),
                const SizedBox(height: 14),
                _label('Nguồn gốc'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _source,
                  decoration: _inputDeco(null),
                  items: _sourceOptions.map((opt) => DropdownMenuItem(
                    value: opt.$1,
                    child: Text(opt.$2),
                  )).toList(),
                  onChanged: (v) => setState(() => _source = v ?? 'purchase'),
                ),
                const SizedBox(height: 14),
                _label('Ghi chú'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: _inputDeco('Ghi chú tuỳ chọn...'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addCrab,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: _primary),
                    label: const Text('+ Thêm cua nữa', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_crabs.isNotEmpty) ...[
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('Danh sách cua đã nhập', Icons.list_alt_rounded),
                    Text('${_crabs.length} con', style: const TextStyle(color: _primary, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_crabs.length, (i) {
                  final c = _crabs[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(color: Color(0xFFD5F5E3), shape: BoxShape.circle),
                          child: Center(
                            child: Text('${i + 1}', style: const TextStyle(color: _primary, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${c.weightGram} gram${c.tag != null ? " • ${c.tag}" : ""}',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: _textMain),
                              ),
                              Text(
                                _sourceOptions.firstWhere((o) => o.$1 == c.source, orElse: () => ('', c.source)).$2,
                                style: const TextStyle(fontSize: 12, color: _textSub),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: _danger, size: 20),
                          onPressed: () => setState(() => _crabs.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        _primaryBtn(
          label: 'Xác nhận →',
          enabled: _crabs.isNotEmpty,
          onPressed: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  // ── Step 3: Xác nhận ─────────────────────────────────────────────────────────
  Widget _buildStep3() {
    final totalWeight = _crabs.fold(0, (s, c) => s + c.weightGram);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Tổng kết nhập kho', Icons.summarize_rounded),
              const SizedBox(height: 16),
              _summaryRow('Khu nuôi', _selectedArea?.name ?? '-'),
              _summaryRow('Dãy', _selectedRow?.name ?? '-'),
              _summaryRow('Hộp', _selectedBox?.code ?? '-'),
              const Divider(color: _border, height: 24),
              _summaryRow('Tổng số cua', '${_crabs.length} con', highlight: true),
              _summaryRow('Tổng cân nặng', '$totalWeight gram', highlight: true),
              _summaryRow('TB cân nặng', '${_crabs.isEmpty ? 0 : (totalWeight / _crabs.length).round()} gram'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Chi tiết từng con', Icons.list_rounded),
              const SizedBox(height: 8),
              ...List.generate(_crabs.length, (i) {
                final c = _crabs[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('#${i + 1}', style: const TextStyle(color: _textSub, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${c.weightGram}g ${c.tag != null ? "• ${c.tag}" : ""}', style: const TextStyle(color: _textMain))),
                      Text(_sourceOptions.firstWhere((o) => o.$1 == c.source, orElse: () => ('', c.source)).$2, style: const TextStyle(color: _textSub, fontSize: 12)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _submitting
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _primaryBtn(
                label: 'Nhập vào hộp ✓',
                enabled: true,
                onPressed: _submitAll,
              ),
      ],
    );
  }

  // ── Reusable widgets ─────────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  Widget _sectionTitle(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 18, color: _primary),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _textMain)),
    ],
  );

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain),
  );

  InputDecoration _inputDeco(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9DB3C2)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _danger),
    ),
  );

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) label,
    required void Function(T?) onChanged,
  }) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Text(
          hint.contains('khu') ? 'Chưa có khu nuôi nào' : hint.contains('dãy') ? 'Vui lòng chọn khu nuôi trước' : 'Chưa có hộp nào',
          style: const TextStyle(color: Color(0xFF9DB3C2)),
        ),
      );
    }
    return DropdownButtonFormField<T>(
      value: value,
      decoration: _inputDeco(hint),
      hint: Text(hint, style: const TextStyle(color: Color(0xFF9DB3C2))),
      items: items.map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(label(item), overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _summaryRow(String key, String value, {bool highlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: const TextStyle(color: _textSub)),
        Text(
          value,
          style: TextStyle(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? _primary : _textMain,
            fontSize: highlight ? 15 : 14,
          ),
        ),
      ],
    ),
  );

  Widget _primaryBtn({required String label, required bool enabled, required VoidCallback onPressed}) =>
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: const Color(0xFFB2DFDB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
}

// ── Step indicator ────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  static const _labels = ['Chọn hộp', 'Nhập cua', 'Xác nhận'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= currentStep;
          final current = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                _dot(i + 1, active, current),
                if (i < 2) Expanded(child: Container(height: 2, color: active && i < currentStep ? _primary : _border)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _dot(int n, bool active, bool current) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? _primary : _border,
          border: current ? Border.all(color: _primaryDk, width: 2) : null,
        ),
        child: Center(
          child: Text('$n', style: TextStyle(color: active ? Colors.white : _textSub, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
      const SizedBox(height: 4),
      Text(_labels[n - 1], style: TextStyle(fontSize: 10, color: active ? _primary : _textSub, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
    ],
  );
}
