import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import 'models/iot_device.dart';

abstract class DevicesRepository {
  Future<List<IotDevice>> getDevices({String? farmingAreaId});
  Future<IotDevice> getDevice(String id);
}

class DevicesRepositoryImpl implements DevicesRepository {
  DevicesRepositoryImpl({Dio? dio, FlutterSecureStorage? secureStorage})
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
  Future<List<IotDevice>> getDevices({String? farmingAreaId}) async {
    final res = await _dio.get(
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
    final res = await _dio.get('${ApiConstants.devices}/$id');
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
