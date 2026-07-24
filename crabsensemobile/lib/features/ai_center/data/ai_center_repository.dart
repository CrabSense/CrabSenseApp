import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
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
  AiCenterRepositoryImpl({Dio? dio, FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            ),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.apiBaseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _secureStorage.read(key: 'auth_access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<List<AiDetectionItem>> getDetections() async {
    final res = await _dio.get(ApiConstants.aiDetections);
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
    final res = await _dio.get(ApiConstants.aiRecommendations);
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
    final res = await _dio.post(
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
