import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/ai_center_models.dart';

abstract class AiCenterRepository {
  Future<List<AiDetectionItem>> getDetections();
  Future<List<AiRecommendationItem>> getRecommendations();
  Future<void> submitFeedback({
    required String detectionId,
    required bool isCorrect,
    String? comment,
  });
}

class AiCenterRepositoryImpl implements AiCenterRepository {
  AiCenterRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<List<AiDetectionItem>> getDetections() async {
    final res = await _api.get(ApiConstants.aiDetections);
    if (res.statusCode != 200 || res.data == null) {
      throw Exception('Không tải được lịch sử phát hiện AI');
    }
    final list = _extractList(res.data);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((e) => AiDetectionItem.fromJson(Map<String, dynamic>.from(e)))
        .where((d) => d.id.isNotEmpty)
        .toList();
  }

  @override
  Future<List<AiRecommendationItem>> getRecommendations() async {
    final res = await _api.get(ApiConstants.aiRecommendations);
    if (res.statusCode != 200 || res.data == null) {
      throw Exception('Không tải được khuyến nghị AI');
    }
    final list = _extractList(res.data);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((e) => AiRecommendationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> submitFeedback({
    required String detectionId,
    required bool isCorrect,
    String? comment,
  }) async {
    final res = await _api.post(
      ApiConstants.submitFeedback,
      data: {
        'aiDetectionId': detectionId,
        'isCorrect': isCorrect,
        'comment': comment,
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Gửi phản hồi thất bại');
    }
  }

  List? _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] != null) return _extractList(map['data']);
      if (map['items'] is List) return map['items'] as List;
    }
    return null;
  }
}
