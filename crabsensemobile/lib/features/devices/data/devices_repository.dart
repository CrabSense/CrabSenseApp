import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/iot_device.dart';

abstract class DevicesRepository {
  Future<List<IotDevice>> getDevices({String? farmingAreaId});
  Future<IotDevice> getDevice(String id);
}

class DevicesRepositoryImpl implements DevicesRepository {
  DevicesRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<List<IotDevice>> getDevices({String? farmingAreaId}) async {
    final res = await _api.get(
      ApiConstants.devices,
      queryParameters: farmingAreaId != null && farmingAreaId.isNotEmpty
          ? {'farmingAreaId': farmingAreaId}
          : null,
    );
    if (res.statusCode != 200 || res.data == null) {
      throw Exception('Không tải được danh sách thiết bị');
    }
    final list = _extractList(res.data);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((e) => IotDevice.fromJson(Map<String, dynamic>.from(e)))
        .where((d) => d.id.isNotEmpty)
        .toList();
  }

  @override
  Future<IotDevice> getDevice(String id) async {
    final res = await _api.get('${ApiConstants.devices}/$id');
    if (res.statusCode != 200 || res.data == null) {
      throw Exception('Không tải được chi tiết thiết bị');
    }
    final raw = res.data is Map
        ? (res.data['data'] ?? res.data)
        : null;
    if (raw is! Map) throw Exception('Phản hồi thiết bị không hợp lệ');
    return IotDevice.fromJson(Map<String, dynamic>.from(raw));
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
