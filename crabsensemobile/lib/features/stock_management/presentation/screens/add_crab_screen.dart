import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

/// Staff selects an existing empty box, then uses the single registration
/// form in CrabListScreen. Never creates a box or stocks multiple crabs into it.
class AddCrabScreen extends StatefulWidget {
  const AddCrabScreen({super.key});

  @override
  State<AddCrabScreen> createState() => _AddCrabScreenState();
}

class _AddCrabScreenState extends State<AddCrabScreen> {
  final _api = sl<ApiClient>();
  List<Map<String, dynamic>> _boxes = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get<dynamic>('/boxes/available');
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final raw = data is Map ? data['emptyBoxes'] : null;
      if (raw is! List) throw const FormatException('Thiếu danh sách hộp trống');
      if (!mounted) return;
      setState(() {
        _boxes = raw.whereType<Map>().map((b) => Map<String, dynamic>.from(b))
            .where((b) => (b['id']?.toString() ?? '').isNotEmpty).toList();
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final boxes = _boxes.where((b) => ['code', 'areaName', 'rowName']
        .any((key) => (b[key]?.toString() ?? '').toLowerCase().contains(query))).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập cua — chọn hộp trống')),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
        _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Không tải được hộp trống.'),
          TextButton(onPressed: _load, child: const Text('Thử lại')),
        ])) : RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Chọn hộp có sẵn trong khu được phân công. Mỗi hộp chỉ nhận một cua sống.'),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm khu, dãy hoặc mã hộp'),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              if (boxes.isEmpty) const Text('Không có hộp trống phù hợp. Liên hệ quản trị trại nếu cần thêm hộp.'),
              for (final box in boxes)
                Card(child: ListTile(
                  title: Text((box['code'] ?? box['id']).toString()),
                  subtitle: Text([box['areaName'], box['rowName']].whereType<String>().join(' · ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push(RoutePaths.boxCrabs(box['id'].toString(), boxCode: box['code']?.toString()));
                    if (mounted) await _load();
                  },
                )),
            ],
          ),
        ),
    );
  }
}
