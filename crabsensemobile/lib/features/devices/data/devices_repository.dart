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
    if (list == null) throw Exception('Danh sách thiết bị không hợp lệ');
    final devices = list
        .whereType<Map>()
        .map((e) => IotDevice.fromJson(Map<String, dynamic>.from(e)))
        .where((d) => d.id.isNotEmpty)
        .toList();
    final sensors=await _getSensors(farmingAreaId:farmingAreaId);
    return [...devices,...sensors];
  }

  Future<List<IotDevice>> _getSensors({String? farmingAreaId}) async {
    final response=await _api.get(ApiConstants.iotLive,queryParameters:
      farmingAreaId!=null&&farmingAreaId.isNotEmpty?{'farmingAreaId':farmingAreaId}:null);
    if(response.statusCode!=200)throw Exception('Không tải được Sensor');
    final list=_extractList(response.data);
    if(list==null)throw Exception('Danh sách Sensor không hợp lệ');
    return list.whereType<Map>().map((e)=>IotDevice.fromSensor(Map<String,dynamic>.from(e))).where((d)=>d.id.isNotEmpty).toList();
  }

  @override
  Future<IotDevice> getDevice(String id) async {
    if(id.startsWith('sensor:')){
      final sensors=await _getSensors();
      return sensors.firstWhere((s)=>s.id==id,orElse:()=>throw Exception('Sensor không tồn tại hoặc ngoài phạm vi'));
    }
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
