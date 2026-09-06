import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const Color _primary   = Color(0xFF27AE60);
const Color _primaryDk = Color(0xFF1E8449);
const Color _bg        = Color(0xFFF0F3F7);
const Color _surface   = Color(0xFFFFFFFF);
const Color _textMain  = Color(0xFF1A2E3B);
const Color _textSub   = Color(0xFF5A7184);
const Color _border    = Color(0xFFDDE4EB);
const Color _danger    = Color(0xFFE74C3C);
const Color _green     = Color(0xFF2ECC71);

// ── Simple models ─────────────────────────────────────────────────────────────
class _FarmArea {
  const _FarmArea({required this.id, required this.name});
  final String id;
  final String name;
}

class _Box {
  const _Box({required this.id, required this.code});
  final String id;
  final String code;
}

class _CrabRecord {
  const _CrabRecord({
    required this.id,
    required this.tag,
    required this.weightGram,
    required this.createdAt,
    required this.status,
    this.species = '',
    this.moltingStage = '',
  });
  final String id;
  final String tag;
  final int weightGram;
  final String createdAt;
  final String status; // alive / dead / unknown
  final String species;
  final String moltingStage;
}

// ── Screen ────────────────────────────────────────────────────────────────────
class CrabTrackingScreen extends StatefulWidget {
  const CrabTrackingScreen({super.key});

  @override
  State<CrabTrackingScreen> createState() => _CrabTrackingScreenState();
}

class _CrabTrackingScreenState extends State<CrabTrackingScreen> {
  final ApiClient _api = sl<ApiClient>();

  List<_FarmArea> _areas  = [];
  List<_Box>      _boxes  = [];
  List<_CrabRecord> _crabs = [];

  _FarmArea? _selectedArea;
  _Box?      _selectedBox;

  bool _loadingAreas = false;
  bool _loadingBoxes = false;
  bool _loadingCrabs = false;

  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }

  // ── API ──────────────────────────────────────────────────────────────────────
  Future<void> _fetchAreas() async {
    setState(() => _loadingAreas = true);
    try {
      final r = await _api.get<Map<String, dynamic>>('/farming-areas');
      final body = r.data ?? {};
        final nested = body['data'];
        final items = nested is Map
          ? (nested['items'] as List? ?? const [])
          : (body['items'] as List? ?? const []);
      setState(() {
        _areas = items.map((e) => _FarmArea(id: e['id'] as String, name: e['name'] as String)).toList();
      });
    } catch (e) {
      _showError('Lỗi tải khu nuôi: $e');
    } finally {
      setState(() => _loadingAreas = false);
    }
  }

  Future<void> _fetchBoxes(String areaId) async {
    setState(() { _loadingBoxes = true; _boxes = []; _selectedBox = null; _crabs = []; });
    try {
      final r = await _api.get<dynamic>(
        '/boxes',
        queryParameters: {'farmingAreaId': areaId},
      );
      final data = r.data;
      List<dynamic> items = [];
      if (data is Map) {
        final nested = data['data'];
        if (nested is Map) {
          items = (nested['items'] as List?) ??
              (nested['data'] as List?) ??
              const [];
        } else {
          items = (data['items'] as List?) ??
              const [];
        }
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

  Future<void> _fetchCrabs(String boxId) async {
    setState(() { _loadingCrabs = true; _crabs = []; });
    try {
      final r = await _api.get<dynamic>('/boxes/$boxId/crabs');
      final data = r.data;
      List<dynamic> items = [];
      if (data is Map) {
        items = (data['items'] as List? ?? data['crabs'] as List? ?? data['data'] as List? ?? []);
      } else if (data is List) {
        items = data;
      }
      setState(() {
        _crabs = items.map((e) => _CrabRecord(
          id:         (e['id'] ?? '') as String,
          tag:        (e['tag'] ?? e['code'] ?? 'Không có mã') as String,
          weightGram: ((e['weightGram'] ?? e['weight'] ?? 0) as num).toInt(),
          createdAt:  (e['createdAt'] ?? e['addedAt'] ?? '') as String,
          status:     (e['status'] ?? 'alive') as String,
          species:    (e['species'] ?? '') as String,
          moltingStage: (e['moltingStage'] ?? e['moltingStatus'] ?? '') as String,
        )).toList();
      });
    } catch (e) {
      _showError('Lỗi tải cua: $e');
    } finally {
      setState(() => _loadingCrabs = false);
    }
  }

  void _refresh() {
    _fetchAreas();
    if (_selectedArea != null) _fetchBoxes(_selectedArea!.id);
    if (_selectedBox  != null) _fetchCrabs(_selectedBox!.id);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.addCrab),
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nhập thêm cua', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdowns
              _card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Chọn hộp để xem', Icons.search_rounded),
                  const SizedBox(height: 12),
                  _loadingAreas
                      ? const Center(child: CircularProgressIndicator(color: _primary))
                      : _dropdown<_FarmArea>(
                          hint: 'Chọn khu nuôi...',
                          value: _selectedArea,
                          items: _areas,
                          label: (a) => a.name,
                          onChanged: (a) {
                            setState(() { _selectedArea = a; _selectedBox = null; _crabs = []; });
                            if (a != null) _fetchBoxes(a.id);
                          },
                        ),
                  const SizedBox(height: 12),
                  _loadingBoxes
                      ? const Center(child: CircularProgressIndicator(color: _primary))
                      : _dropdown<_Box>(
                          hint: 'Chọn hộp...',
                          value: _selectedBox,
                          items: _boxes,
                          label: (b) => b.code,
                          onChanged: (b) {
                            setState(() => _selectedBox = b);
                            if (b != null) _fetchCrabs(b.id);
                          },
                        ),
                ],
              )),
              const SizedBox(height: 16),

              // Crab list
              if (_selectedBox == null)
                _emptyState('Chọn khu nuôi và hộp để xem danh sách cua')
              else if (_loadingCrabs)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _primary)))
              else if (_crabs.isEmpty)
                _emptyState('Hộp này chưa có cua nào')
              else
                _crabList(),
            ],
          ),
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
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Theo dõi cua',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: true,
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

  Widget _crabList() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Danh sách cua trong hộp ${_selectedBox?.code ?? ""}', Icons.list_alt_rounded),
        const SizedBox(height: 12),
        ...List.generate(_crabs.length, (i) => _crabRow(_crabs[i], i + 1)),
      ],
    ),
  );

  Widget _crabRow(_CrabRecord crab, int index) {
    final isAlive = crab.status == 'alive';
    final statusColor = isAlive ? _green : _danger;
    final statusLabel = isAlive ? 'Còn sống' : crab.status == 'dead' ? 'Đã chết' : 'Không rõ';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD5F5E3),
              shape: BoxShape.circle,
              border: Border.all(color: _primary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.pest_control_rounded, color: _primaryDk, size: 22),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crab.tag.isEmpty || crab.tag == 'Không có mã' ? 'Cua #$index' : crab.tag,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: _textMain, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.monitor_weight_outlined, size: 12, color: _textSub),
                    const SizedBox(width: 4),
                    Text('${crab.weightGram}g', style: const TextStyle(color: _textSub, fontSize: 12)),
                    const SizedBox(width: 12),
                    if (crab.createdAt.isNotEmpty) ...[
                      const Icon(Icons.calendar_today_outlined, size: 12, color: _textSub),
                      const SizedBox(width: 4),
                      Text(_formatDate(crab.createdAt), style: const TextStyle(color: _textSub, fontSize: 12)),
                    ],
                  ],
                ),
                if (crab.species.isNotEmpty || crab.moltingStage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [crab.species, crab.moltingStage]
                          .where((value) => value.isNotEmpty)
                          .join(' • '),
                      style: const TextStyle(color: _textSub, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                tooltip: 'Chuyển sang hộp khác',
                icon: const Icon(Icons.swap_horiz_rounded, color: _textSub),
                onPressed: () => context.push(
                  RoutePaths.boxCrabs(_selectedBox!.id, boxCode: _selectedBox!.code),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) => _card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFFDDE4EB)),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: _textSub), textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  // ── Reusable ─────────────────────────────────────────────────────────────────
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
      Flexible(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _textMain))),
    ],
  );

  InputDecoration _inputDeco(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9DB3C2)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.5)),
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
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
        child: Text(hint, style: const TextStyle(color: Color(0xFF9DB3C2))),
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

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }
}
