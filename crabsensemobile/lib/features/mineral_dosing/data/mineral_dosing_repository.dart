import 'package:dio/dio.dart' show DioException;

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/mineral_dose_models.dart';
import 'models/salinity_mix_models.dart';

/// Gọi API tính liều khoáng Ca/Mg và pha độ mặn.
///
/// Cố ý KHÔNG cache: kết quả phụ thuộc số đo test tại thời điểm gọi, và
/// không có state nào cần đồng bộ offline.
abstract class MineralDosingRepository {
  /// Mục tiêu Ca/Mg đề xuất theo độ mặn (‰).
  Future<MineralTargetRecommendation> recommendTargets(double salinityPpt);

  /// Tính liều CaCl2 / MgCl2.
  Future<MineralDoseResult> calculate(MineralDoseRequest request);

  /// Danh mục loại muối dùng khi pha độ mặn.
  Future<List<SaltType>> saltTypes();

  /// Tính lượng muối (tăng ‰) hoặc lượng nước ngọt (giảm ‰) kèm hướng dẫn pha.
  Future<SalinityMixResult> mixSalinity(SalinityMixRequest request);
}

class MineralDosingRepositoryImpl implements MineralDosingRepository {
  MineralDosingRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<MineralTargetRecommendation> recommendTargets(
    double salinityPpt,
  ) async {
    try {
      final res = await _api.get(
        ApiConstants.mineralDosingTargets,
        queryParameters: {'salinityPpt': salinityPpt},
      );
      return MineralTargetRecommendation.fromJson(_unwrap(res.data));
    } on DioException catch (e) {
      throw Exception(_apiMessage(e, 'Không lấy được mục tiêu đề xuất'));
    }
  }

  @override
  Future<MineralDoseResult> calculate(MineralDoseRequest request) async {
    try {
      final res = await _api.post(
        ApiConstants.mineralDosingCalculate,
        data: request.toJson(),
      );
      return MineralDoseResult.fromJson(_unwrap(res.data));
    } on DioException catch (e) {
      throw Exception(_apiMessage(e, 'Không tính được liều khoáng'));
    }
  }

  @override
  Future<List<SaltType>> saltTypes() async {
    try {
      final res = await _api.get(ApiConstants.mineralDosingSaltTypes);
      // Endpoint này trả mảng trong `data` (khác hai endpoint kia trả object),
      // nên tự bóc chứ không dùng `_unwrap`.
      final body = res.data;
      final raw = body is Map ? body['data'] : body;
      if (raw is! List) throw Exception('Dữ liệu trả về không hợp lệ');
      return raw
          .whereType<Map>()
          .map((e) => SaltType.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw Exception(_apiMessage(e, 'Không lấy được danh mục loại muối'));
    }
  }

  @override
  Future<SalinityMixResult> mixSalinity(SalinityMixRequest request) async {
    try {
      final res = await _api.post(
        ApiConstants.mineralDosingSalinity,
        data: request.toJson(),
      );
      return SalinityMixResult.fromJson(_unwrap(res.data));
    } on DioException catch (e) {
      throw Exception(_apiMessage(e, 'Không tính được lượng muối / nước ngọt'));
    }
  }

  /// Bóc `{ success, message, data: {...} }` → `data`.
  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return map;
    }
    throw Exception('Dữ liệu trả về không hợp lệ');
  }

  /// Lấy `message` do BE trả về (ví dụ lỗi kiểm tra đầu vào) để UI hiển thị
  /// đúng lý do thay vì "DioException [bad response]: 400".
  String _apiMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'].toString().trim();
      if (msg.isNotEmpty) return msg;
    }
    return fallback;
  }
}
