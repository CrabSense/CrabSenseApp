import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/water_quality_data.dart';

class ApiService {

  ApiService({required this.baseUrl});
  final String baseUrl;

  // Lấy dữ liệu chất lượng nước mới nhất
  Future<List<WaterQualityData>> getLatestData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/water-quality/latest'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => WaterQualityData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // Lấy dữ liệu theo khoảng thời gian
  Future<List<WaterQualityData>> getDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/water-quality/range')
            .replace(queryParameters: {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => WaterQualityData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // Kiểm tra kết nối server
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
