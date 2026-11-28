import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/water_bench_monitor.dart';
import 'cloud_api_client.dart';

/// GET-only adapter: no calibration, inference, retry, review, publish or commands.
class WaterBenchMonitorService {
  WaterBenchMonitorService({http.Client? client})
      : _client = client ?? http.Client(), _ownsClient = client == null;
  final http.Client _client;
  final bool _ownsClient;

  String _scope(AuthSession session) {
    final area = session.selectedFarm.id;
    if (!UserRoles.canUseDesktop(session.user.role) ||
        !benchGuid(area) || !session.farms.any((farm) => farm.id == area)) {
      throw CloudApiException('Không có quyền giám sát khu nuôi này.', statusCode: 403);
    }
    return '/api/areas/$area/water-bench';
  }

  Future<Object?> _get(AuthSession session, String path) async {
    final response = await _client.get(
      Uri.parse('${AppEnv.cloudApiUrl}$path'),
      headers: {'Authorization': 'Bearer ${session.token}',
        'X-Farm-Id': session.selectedFarm.id, 'Cache-Control': 'no-cache'},
    ).timeout(const Duration(seconds: 15));
    final Object? parsed;
    try {
      parsed = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw CloudApiException('Phản hồi WaterBench không hợp lệ.', statusCode: response.statusCode);
    }
    final envelope = benchMap(parsed);
    if (response.statusCode != 200 || envelope['success'] != true || !envelope.containsKey('data')) {
      throw CloudApiException(
        response.statusCode == 401 ? 'Phiên đăng nhập hết hạn.' :
        response.statusCode == 403 ? 'Không có quyền xem khu nuôi.' :
        'Không tải được WaterBench (${response.statusCode}).',
        statusCode: response.statusCode);
    }
    return envelope['data'];
  }

  BenchJson _object(Object? value) {
    if (value is! Map) throw const FormatException('Thiếu dữ liệu WaterBench.');
    return benchMap(value);
  }

  Future<BenchOverview> overview(AuthSession session) async {
    final path = _scope(session);
    final data = await Future.wait([_get(session, '$path/station'), _get(session, '$path/batches')]);
    if (data[1] is! List) throw const FormatException('Danh sách phiên không hợp lệ.');
    final batches = (data[1] as List).map((e) => BenchBatch.fromJson(_object(e))).toList();
    if (batches.map((b) => b.key).toSet().length != batches.length) {
      throw const FormatException('Danh tính phiên trùng lặp.');
    }
    return BenchOverview(data[0] == null ? null : _object(data[0]), batches);
  }

  Future<BenchDetail> detail(AuthSession session, BenchBatch batch) async {
    final path = '${_scope(session)}/batches/${batch.key}';
    final data = await Future.wait([
      _get(session, path), _get(session, '$path/results'),
      _get(session, '$path/results/ai-readiness'), _get(session, '$path/results/retry-status'),
      _get(session, '$path/receipts'),
    ]);
    final detail = _object(data[0]);
    final timeline = _object(detail['timeline']);
    if (timeline['stationId'] != batch.stationId || timeline['bootId'] != batch.bootId ||
        timeline['batchId'] != batch.batchId) {
      throw const FormatException('Phản hồi không khớp phiên đã chọn.');
    }
    final results = _object(data[1]), readiness = _object(data[2]), retry = _object(data[3]);
    final receipts = _object(data[4]);
    verifyBenchSnapshot(batch, timeline, receipts, [results, readiness, retry]);
    final channels = await Future.wait(benchAnalytes.map((a) async {
      final observation = benchChannel(timeline, a), result = benchChannel(results, a);
      BenchJson? review;
      var unavailable = false;
      if (benchMap(result?['assessment'])['status'] == 'estimate_review_required') {
        try {
          review = _object(await _get(session, '$path/results/$a/review'));
          if (review['assessmentId'] != benchMap(result?['assessment'])['id']) {
            review = null;
            unavailable = true;
          }
        } on CloudApiException catch (e) {
          if (e.statusCode == 401 || e.statusCode == 403) rethrow;
          unavailable = true;
        } catch (_) {
          unavailable = true;
        }
      }
      return BenchChannel(a, observation, result, benchChannel(readiness, a),
          benchChannel(retry, a), review, unavailable);
    }));
    return BenchDetail(timeline: timeline, stale: detail['observationStale'] != false,
      receipts: receipts, channels: channels);
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
