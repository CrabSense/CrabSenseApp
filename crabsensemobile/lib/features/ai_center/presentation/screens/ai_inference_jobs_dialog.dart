import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

/// Uses existing authenticated, camera/box-linked media; never fabricates a
/// detection or infers runtime health from historical results.
class AiInferenceJobsDialog extends StatefulWidget {
  const AiInferenceJobsDialog({super.key});

  @override
  State<AiInferenceJobsDialog> createState() => _AiInferenceJobsDialogState();
}

class _AiInferenceJobsDialogState extends State<AiInferenceJobsDialog> {
  final _media = TextEditingController();
  final _service = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _jobs = [];
  Map<String, dynamic>? _selected;
  Map<String, dynamic>? _detection;
  static const _endpoint = '/ai/inference/jobs';
  static final _guid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _media.dispose();
    _service.dispose();
    super.dispose();
  }

  Map<String, dynamic> _data(dynamic body) {
    if (body is! Map || body['success'] == false || body['data'] is! Map) {
      throw Exception('Phản hồi AI không hợp lệ');
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await operation();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() => _run(_fetchJobs);

  Future<void> _fetchJobs() async {
    final res = await sl<ApiClient>().safeGet<dynamic>(
      _endpoint, queryParameters: {'pageSize': 25},
    );
    if (res.failure != null) throw Exception(res.failure!.message);
    final data = _data(res.data.data);
    final items = data['items'];
    if (items is! List) throw Exception('Thiếu danh sách job AI');
    if (!mounted) return;
    setState(() => _jobs = items.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item)).toList());
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await _run(() async {
      final res = await sl<ApiClient>().safePost<dynamic>(
        _endpoint,
        data: {
          'mediaId': _media.text.trim(),
          if (_service.text.trim().isNotEmpty) 'aiServiceId': _service.text.trim(),
        },
      );
      if (res.failure != null) throw Exception(res.failure!.message);
      final job = _data(res.data.data);
      if (!mounted) return;
      setState(() { _selected = job; _detection = null; });
      await _fetchJobs();
    });
  }

  Future<void> _detail(String id) => _run(() async {
    if (!_guid.hasMatch(id)) throw Exception('Job ID không hợp lệ');
    final res = await sl<ApiClient>().safeGet<dynamic>('$_endpoint/$id');
    if (res.failure != null) throw Exception(res.failure!.message);
    final data = _data(res.data.data);
    final job = data['job'];
    if (job is! Map) throw Exception('Thiếu thông tin job AI');
    if (!mounted) return;
    setState(() {
      _selected = Map<String, dynamic>.from(job);
      final detection = data['detection'];
      _detection = detection is Map ? Map<String, dynamic>.from(detection) : null;
    });
  });

  String? _validate(String? value, {bool optional = false}) {
    final v = value?.trim() ?? '';
    if (optional && v.isEmpty) return null;
    return _guid.hasMatch(v) ? null : 'Nhập UUID hợp lệ';
  }

  @override
  Widget build(BuildContext context) {
    final job = _selected;
    final detection = _detection;
    return AlertDialog(
      title: const Text('Phân tích AI từ media'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Dùng Media ID ảnh/video đã lưu, có camera và hộp nguồn. Hệ thống kiểm tra quyền khu nuôi và worker sẵn sàng.'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _media,
                  decoration: const InputDecoration(labelText: 'Media ID'),
                  validator: _validate,
                ),
                TextFormField(
                  controller: _service,
                  decoration: const InputDecoration(labelText: 'AI Service ID (tùy chọn)'),
                  validator: (v) => _validate(v, optional: true),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _busy ? null : _submit, child: const Text('Gửi yêu cầu')),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                if (job != null) ...[
                  const SizedBox(height: 12),
                  Text('Job: ${job['id']}'),
                  Text('Trạng thái: ${job['status']} · Model: ${job['modelVersion']}'),
                  if (job['error'] != null) Text(job['error'].toString()),
                  if (detection != null)
                    Text('Kết quả: ${detection['detectionType']} · Confidence: ${detection['confidence']}'),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _detail(job['id'].toString()),
                    child: const Text('Cập nhật kết quả job'),
                  ),
                ],
                const Divider(),
                Text('Job gần đây (${_jobs.length})'),
                for (final item in _jobs)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['status']} · ${item['modelVersion']}'),
                    subtitle: Text(item['id'].toString()),
                    onTap: _busy ? null : () => _detail(item['id'].toString()),
                  ),
                if (!_busy && _jobs.isEmpty) const Text('Chưa có job.'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : _load, child: const Text('Làm mới')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
      ],
    );
  }
}
