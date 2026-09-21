import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/cloud_telemetry.dart';
import '../models/farm_record.dart';
import '../models/area_environment_metric.dart';
import '../models/farm_dashboard_overview.dart';
import '../models/feed_management_overview.dart';
import '../models/water_quality.dart';
import '../models/crab_profile.dart';
import '../models/production_models.dart';

part 'production_cloud_api.dart';

class CloudApiException implements Exception {
  CloudApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CloudApiClient {
  CloudApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _base => AppEnv.cloudApiUrl;

  Future<({String token, String? refreshToken, AuthUser user})> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_base/api/auth/login');
    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username.trim(), 'password': password}),
    );

    final body = _decode(res);
    if (res.statusCode == 401 || _isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Tên đăng nhập hoặc mật khẩu không đúng.',
        statusCode: res.statusCode,
      );
    }

    final data = _asMap(_dataOf(body) ?? body);
    final token = (data['accessToken'] ??
            data['AccessToken'] ??
            data['token'] ??
            data['Token'] ??
            body['token'] ??
            body['Token'])
        ?.toString();
    if (token == null || token.isEmpty) {
      throw CloudApiException('Phản hồi login thiếu accessToken');
    }

    final userRaw = data['user'] ?? data['User'] ?? body['user'] ?? body['User'];
    if (userRaw is! Map) {
      throw CloudApiException('Phản hồi login thiếu user');
    }

    return (
      token: token,
      refreshToken: (data['refreshToken'] ?? data['RefreshToken'])?.toString(),
      user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }

  Future<({String token, String? refreshToken, AuthUser? user})> refresh(
    String refreshToken,
  ) async {
    final uri = Uri.parse('$_base/api/auth/refresh');
    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    final body = _decode(res);
    if (res.statusCode == 401 || _isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Phiên đăng nhập hết hạn.',
        statusCode: res.statusCode == 0 ? 401 : res.statusCode,
      );
    }
    final data = _asMap(_dataOf(body) ?? body);
    final token = (data['accessToken'] ??
            data['AccessToken'] ??
            data['token'] ??
            data['Token'])
        ?.toString();
    if (token == null || token.isEmpty) {
      throw CloudApiException('Phản hồi refresh thiếu accessToken', statusCode: 401);
    }
    final userRaw = data['user'] ?? data['User'];
    return (
      token: token,
      refreshToken: (data['refreshToken'] ?? data['RefreshToken'])?.toString(),
      user: userRaw is Map
          ? AuthUser.fromJson(Map<String, dynamic>.from(userRaw))
          : null,
    );
  }

  Future<void> logout(String token) async {
    final uri = Uri.parse('$_base/api/auth/logout');
    try {
      await _client.post(uri, headers: authHeaders(token));
    } catch (_) {}
  }

  Map<String, String> authHeaders(String token, {String? farmId}) => {
        'Authorization': 'Bearer $token',
        if (farmId != null && farmId.isNotEmpty) 'X-Farm-Id': farmId,
      };

  Future<List<FarmRecord>> fetchFarmRecords(String token) async {
    final uri = Uri.parse('$_base/api/farming-areas');
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải khu nuôi (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return _itemsOf(body)
        .whereType<Map>()
        .map((e) => FarmRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<FarmSummary>> fetchFarms(String token) async {
    final records = await fetchFarmRecords(token);
    return records.map((f) => f.toSummary()).toList();
  }

  Future<String> fetchNextFarmCode(String token) async {
    final uri = Uri.parse('$_base/api/farming-areas/next-code');
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không lấy được mã khu',
        statusCode: res.statusCode,
      );
    }
    final data = _dataOf(body);
    if (data is Map) {
      final code = (data['code'] ?? data['Code'])?.toString();
      if (code != null && code.isNotEmpty) return code;
    }
    return 'AREA-A01';
  }

  Future<FarmRecord> createFarm(
    String token, {
    required String name,
    String? location,
    double? areaSquareMeters,
    String? description,
    FarmStatus status = FarmStatus.active,
  }) async {
    final uri = Uri.parse('$_base/api/farming-areas');
    final res = await _client.post(
      uri,
      headers: {
        ...authHeaders(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        if (location != null && location.isNotEmpty) 'location': location,
        if (areaSquareMeters != null) 'areaSquareMeters': areaSquareMeters,
        if (description != null && description.isNotEmpty) 'description': description,
        'status': status.apiValue,
      }),
    );
    return _parseFarmMutation(res);
  }

  Future<FarmRecord> updateFarm(
    String token,
    String farmId, {
    required String name,
    String? location,
    double? areaSquareMeters,
    String? description,
    FarmStatus status = FarmStatus.active,
  }) async {
    final uri = Uri.parse('$_base/api/farming-areas/$farmId');
    final res = await _client.put(
      uri,
      headers: {
        ...authHeaders(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'location': location ?? '',
        if (areaSquareMeters != null) 'areaSquareMeters': areaSquareMeters,
        'description': description ?? '',
        'status': status.apiValue,
      }),
    );
    return _parseFarmMutation(res);
  }

  Future<void> deleteFarm(String token, String farmId) async {
    final uri = Uri.parse('$_base/api/farming-areas/$farmId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode == 204) return;
    final body = _decode(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không xóa được khu (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
  }

  FarmRecord _parseFarmMutation(http.Response res) {
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode == 403) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không có quyền',
        statusCode: 403,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || _isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Thao tác thất bại (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final farmRaw = _dataOf(body) ?? body['farm'] ?? body['Farm'];
    if (farmRaw is! Map) {
      throw CloudApiException('Phản hồi thiếu khu nuôi');
    }
    return FarmRecord.fromJson(Map<String, dynamic>.from(farmRaw));
  }

  Future<AuthMePayload> authMe(String token) async {
    final uri = Uri.parse('$_base/api/auth/me');
    final res = await _client.get(
      uri,
      headers: authHeaders(token),
    );

    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải được /api/auth/me (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    final data = _asMap(_dataOf(body) ?? body);
    final farms = await fetchFarms(token);
    return AuthMePayload.fromUserDto(data, farms: farms);
  }

  static String normalizeMac(String mac) =>
      mac.trim().toUpperCase().replaceAll('-', ':');

  Future<CloudTelemetryRealtime> fetchTelemetryRealtime(String mac) async {
    final norm = normalizeMac(mac);
    final uri = Uri.parse('$_base/api/telemetry/realtime')
        .replace(queryParameters: {'mac': norm});
    final res = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    final body = _decode(res);

    if (res.statusCode == 404) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tìm thấy thiết bị $mac',
        statusCode: 404,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ??
            'Không tải realtime (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    final readings = _parseReadingsMap(body['readings']);
    DateTime? lastAt;

    final pins = body['pins'];
    if (pins is List) {
      for (final p in pins) {
        if (p is! Map) continue;
        final m = Map<String, dynamic>.from(p);
        final label = (m['label'] ?? m['Label'])?.toString();
        final val = (m['val'] ?? m['Val']);
        if (label != null && val is num) {
          readings.putIfAbsent(label, () => val.toDouble());
        }
        final t = m['recordedAt'] ?? m['RecordedAt'];
        if (t == null) continue;
        final dt = DateTime.tryParse(t.toString());
        if (dt != null && (lastAt == null || dt.isAfter(lastAt))) {
          lastAt = dt;
        }
      }
    }

    return CloudTelemetryRealtime(
      mac: (body['mac'] ?? norm).toString(),
      deviceCode: (body['deviceCode'] ?? body['DeviceCode'])?.toString(),
      readings: readings,
      lastRecordedAt: lastAt,
    );
  }

  Future<List<CloudTelemetryHistoryPoint>> fetchTelemetryHistory({
    required String token,
    required String mac,
    required int minutes,
    int? pin,
    String? farmId,
  }) async {
    final params = <String, String>{
      'mac': normalizeMac(mac),
      'minutes': minutes.toString(),
    };
    if (pin != null) params['pin'] = pin.toString();

    final uri = Uri.parse('$_base/api/telemetry/history')
        .replace(queryParameters: params);
    final res = await _client
        .get(
          uri,
          headers: authHeaders(token, farmId: farmId),
        )
        .timeout(const Duration(seconds: 45));
    final body = _decode(res);

    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode == 404) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tìm thấy thiết bị',
        statusCode: 404,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ??
            'Không tải history (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    final data = body['data'];
    if (data is! List) return [];

    return data.map((row) {
      final m = Map<String, dynamic>.from(row as Map);
      final timeStr = (m['time'] ?? m['Time'])?.toString() ?? '';
      return CloudTelemetryHistoryPoint(
        time: DateTime.tryParse(timeStr) ?? DateTime.now(),
        pin: ((m['pin'] ?? m['Pin']) as num?)?.toInt() ?? 0,
        val: ((m['val'] ?? m['Val']) as num?)?.toDouble() ?? 0,
        label: (m['label'] ?? m['Label'])?.toString() ?? '',
      );
    }).toList();
  }

  Future<bool> healthCheck() async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Uri _areaUri(String path, String? farmingAreaId) {
    final uri = Uri.parse('$_base$path');
    if (farmingAreaId == null || farmingAreaId.isEmpty) return uri;
    return uri.replace(queryParameters: {'farmingAreaId': farmingAreaId});
  }

  Future<Map<String, dynamic>> _getDataMap(
    String token,
    String path, {
    String? farmingAreaId,
  }) async {
    final uri = _areaUri(path, farmingAreaId);
    final res = await _client.get(
      uri,
      headers: authHeaders(token, farmId: farmingAreaId),
    );
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Lỗi API $path (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<List<Map<String, dynamic>>> _getDataList(
    String token,
    String path, {
    String? farmingAreaId,
    Map<String, String>? extraQuery,
  }) async {
    var uri = _areaUri(path, farmingAreaId);
    if (extraQuery != null && extraQuery.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...extraQuery,
      });
    }
    final res = await _client.get(
      uri,
      headers: authHeaders(token, farmId: farmingAreaId),
    );
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Lỗi API $path (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return _itemsOf(body)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchOperations(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataList(token, '/api/operations', farmingAreaId: farmingAreaId);

  Future<List<Map<String, dynamic>>> fetchOperationsRecent(
    String token, {
    String? farmingAreaId,
    int limit = 20,
  }) =>
      _getDataList(
        token,
        '/api/operations/recent',
        farmingAreaId: farmingAreaId,
        extraQuery: {'limit': '$limit'},
      );

  Future<Map<String, dynamic>> createOperation(
    String token, {
    required String type,
    required String notes,
    String? operatorName,
    List<String> boxIds = const [],
    DateTime? timestamp,
    List<String> photoUrls = const [],
    String source = 'manual',
    String? locationLabel,
  }) async {
    final uri = Uri.parse('$_base/api/operations');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'notes': notes,
        'boxIds': boxIds,
        if (operatorName != null) 'operatorName': operatorName,
        if (timestamp != null) 'timestamp': timestamp.toUtc().toIso8601String(),
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        'source': source,
        if (locationLabel != null && locationLabel.isNotEmpty)
          'locationLabel': locationLabel,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tạo nhật ký',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<String?> uploadOperationPhoto(
    String token,
    String filePath, {
    String? boxId,
  }) async {
    final uri = Uri.parse('$_base/api/operations/photo');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(authHeaders(token));
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    if (boxId != null && boxId.isNotEmpty) req.fields['boxId'] = boxId;
    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải ảnh nhật ký',
        statusCode: res.statusCode,
      );
    }
    final data = _asMap(_dataOf(body) ?? body);
    final url = data['url'] ?? data['Url'];
    return url?.toString();
  }

  Future<List<Map<String, dynamic>>> fetchHarvestVouchers(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataList(
        token,
        '/api/harvest-vouchers',
        farmingAreaId: farmingAreaId,
      );

  Future<Map<String, dynamic>> fetchHarvestOverview(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataMap(
        token,
        '/api/harvest-vouchers/overview',
        farmingAreaId: farmingAreaId,
      );

  Future<Map<String, dynamic>> createHarvestVoucher(
    String token, {
    required DateTime harvestDate,
    String? notes,
    required int quantity,
    required double totalWeightKg,
    String? farmingAreaId,
    String? performedByName,
    List<Map<String, dynamic>>? lines,
    List<String> photoUrls = const [],
  }) async {
    final uri = Uri.parse('$_base/api/harvest-vouchers');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'harvestDate': harvestDate.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
        if (farmingAreaId != null && farmingAreaId.isNotEmpty)
          'farmingAreaId': farmingAreaId,
        if (performedByName != null && performedByName.isNotEmpty)
          'performedByName': performedByName,
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        'lines': lines ??
            [
              {
                'weightGram':
                    totalWeightKg * 1000 / (quantity == 0 ? 1 : quantity),
                'grade': 'M',
                'isSoftshell': false,
                'notes': 'x$quantity',
              }
            ],
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tạo phiếu thu hoạch',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<List<Map<String, dynamic>>> fetchSalesOrders(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataList(
        token,
        '/api/sales-orders',
        farmingAreaId: farmingAreaId,
      );

  Future<Map<String, dynamic>> fetchSalesOrderOverview(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataMap(
        token,
        '/api/sales-orders/overview',
        farmingAreaId: farmingAreaId,
      );

  Future<List<Map<String, dynamic>>> fetchSalesInventory(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataList(
        token,
        '/api/sales-orders/inventory',
        farmingAreaId: farmingAreaId,
      );

  Future<List<Map<String, dynamic>>> fetchCustomers(String token) =>
      _getDataList(token, '/api/customers');

  Future<Map<String, dynamic>> createSalesOrder(
    String token, {
    required DateTime orderDate,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    required String paymentStatus,
    String? paymentMethod,
    String? orderStatus,
    String? sellerName,
    String? farmingAreaId,
    String? notes,
    int? discountAmount,
    int? shippingFee,
    int? paidAmount,
    String? deliveryStatus,
    required List<Map<String, dynamic>> lines,
  }) async {
    final uri = Uri.parse('$_base/api/sales-orders');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'orderDate': orderDate.toUtc().toIso8601String(),
        'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerAddress != null) 'customerAddress': customerAddress,
        'paymentStatus': paymentStatus,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (orderStatus != null) 'orderStatus': orderStatus,
        if (sellerName != null) 'sellerName': sellerName,
        if (farmingAreaId != null && farmingAreaId.isNotEmpty)
          'farmingAreaId': farmingAreaId,
        if (notes != null) 'notes': notes,
        if (discountAmount != null) 'discountAmount': discountAmount,
        if (shippingFee != null) 'shippingFee': shippingFee,
        if (paidAmount != null) 'paidAmount': paidAmount,
        if (deliveryStatus != null) 'deliveryStatus': deliveryStatus,
        'lines': lines,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tạo đơn bán hàng',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<Map<String, dynamic>> completeSalesOrder(String token, String id) async {
    final uri = Uri.parse('$_base/api/sales-orders/$id/complete');
    final res = await _client.post(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không xác nhận đơn bán',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<Map<String, dynamic>> cancelSalesOrder(String token, String id) async {
    final uri = Uri.parse('$_base/api/sales-orders/$id/cancel');
    final res = await _client.post(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không hủy đơn bán',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<List<Map<String, dynamic>>> fetchSalesHistory(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataList(
        token,
        '/api/sales/history',
        farmingAreaId: farmingAreaId,
        extraQuery: {
          if (farmingAreaId != null && farmingAreaId.isNotEmpty)
            'farmId': farmingAreaId,
        },
      );

  Future<Map<String, dynamic>> fetchSalesSummary(
    String token, {
    required DateTime start,
    required DateTime end,
    String? farmingAreaId,
  }) async {
    final q = {
      'startDate': start.toUtc().toIso8601String(),
      'endDate': end.toUtc().toIso8601String(),
      if (farmingAreaId != null && farmingAreaId.isNotEmpty)
        'farmId': farmingAreaId,
    };
    final uri = Uri.parse('$_base/api/sales/summary').replace(queryParameters: q);
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải tổng hợp bán hàng',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<List<Map<String, dynamic>>> fetchAiRecommendations(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataList(
        token,
        '/api/ai/recommendations',
        farmingAreaId: farmingAreaId,
      );

  Future<Map<String, dynamic>?> fetchBoxCamera(String token, String boxId) async {
    final uri = Uri.parse('$_base/api/boxes/$boxId/camera');
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (res.statusCode == 404 || _isApiFailure(res, body)) return null;
    return _asMap(_dataOf(body) ?? body);
  }

  Future<List<Map<String, dynamic>>> fetchBoxCrabs(String token, String boxId) =>
      _getDataList(token, '/api/boxes/$boxId/crabs');

  /// CrabSenseBE `GET /api/iot/live`
  Future<List<Map<String, dynamic>>> fetchIotLive(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataList(token, '/api/iot/live', farmingAreaId: farmingAreaId);

  /// CrabSenseBE `GET /api/iot/sensor-data/{sensorId}`
  Future<List<Map<String, dynamic>>> fetchSensorHistory(
    String token, {
    required String sensorId,
    DateTime? from,
    DateTime? to,
    int pageSize = 2000,
  }) =>
      _getDataList(
        token,
        '/api/iot/sensor-data/$sensorId',
        extraQuery: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          'page': '1',
          'pageSize': '$pageSize',
        },
      );

  /// CrabSenseBE `GET /api/alerts`
  Future<List<Map<String, dynamic>>> fetchAlerts(
    String token, {
    String? farmingAreaId,
    String? boxId,
    bool activeOnly = true,
  }) =>
      _getDataList(
        token,
        '/api/alerts',
        farmingAreaId: farmingAreaId,
        extraQuery: {
          'activeOnly': '$activeOnly',
          if (boxId != null && boxId.isNotEmpty) 'boxId': boxId,
        },
      );

  /// CrabSenseBE `GET /api/alerts/history`
  Future<List<Map<String, dynamic>>> fetchAlertHistory(
    String token, {
    String? farmingAreaId,
    int days = 30,
  }) =>
      _getDataList(
        token,
        '/api/alerts/history',
        farmingAreaId: farmingAreaId,
        extraQuery: {'days': '$days'},
      );

  Future<void> acknowledgeAlert(String token, String alertId) async {
    final uri = Uri.parse('$_base/api/alerts/$alertId/acknowledge');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: '{}',
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không xác nhận cảnh báo',
        statusCode: res.statusCode,
      );
    }
  }

  Future<void> resolveAlert(String token, String alertId) async {
    final uri = Uri.parse('$_base/api/alerts/$alertId/resolve');
    final res = await _client.post(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không đóng cảnh báo',
        statusCode: res.statusCode,
      );
    }
  }

  /// CrabSenseBE `GET /api/devices` (alias `/api/controllers`)
  Future<List<Map<String, dynamic>>> fetchCrabSenseDevices(
    String token, {
    String? farmingAreaId,
    String? farmingRowId,
  }) =>
      _getDataList(
        token,
        '/api/devices',
        farmingAreaId: farmingAreaId,
        extraQuery: {
          if (farmingRowId != null && farmingRowId.isNotEmpty) 'farmingRowId': farmingRowId,
        },
      );

  /// CrabSenseBE `GET /api/ai/detections` — lịch sử phát hiện AI (lọc boxId tuỳ chọn).
  /// GET /api/ai/detections — lọc theo hộp hoặc theo khu (`farmingAreaId`),
  /// `take` = số bản ghi mới nhất. Mỗi bản ghi có thêm deviceCode/imagePath/boxCode/crabTag.
  Future<List<Map<String, dynamic>>> fetchAiDetections(
    String token, {
    String? boxId,
    String? farmingAreaId,
    int? take,
  }) =>
      _getDataList(
        token,
        '/api/ai/detections',
        extraQuery: {
          if (boxId != null && boxId.isNotEmpty) 'boxId': boxId,
          if (farmingAreaId != null && farmingAreaId.isNotEmpty) 'farmingAreaId': farmingAreaId,
          if (take != null && take > 0) 'take': '$take',
        },
      );

  Future<Map<String, dynamic>> fetchControllerDetail(
    String token,
    String id,
  ) async {
    final uri = Uri.parse('$_base/api/devices/$id');
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải chi tiết controller',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<Map<String, dynamic>> createController(
    String token, {
    required String deviceCode,
    String? name,
    String? deviceType,
    String? macAddress,
    String? ipAddress,
    String? firmwareVersion,
    String? farmingAreaId,
    String? farmingRowId,
    String? streamUrl,
    String? snapshotUrl,
    String? resolution,
  }) async {
    final uri = Uri.parse('$_base/api/devices');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'deviceCode': deviceCode,
        if (name != null && name.isNotEmpty) 'name': name,
        'deviceType': deviceType ?? 'esp32-s3',
        if (macAddress != null && macAddress.isNotEmpty) 'macAddress': macAddress,
        if (ipAddress != null && ipAddress.isNotEmpty) 'ipAddress': ipAddress,
        if (firmwareVersion != null && firmwareVersion.isNotEmpty)
          'firmwareVersion': firmwareVersion,
        if (farmingAreaId != null && farmingAreaId.isNotEmpty)
          'farmingAreaId': farmingAreaId,
        if (farmingRowId != null && farmingRowId.isNotEmpty) 'farmingRowId': farmingRowId,
        if (streamUrl != null && streamUrl.isNotEmpty) 'streamUrl': streamUrl,
        if (snapshotUrl != null && snapshotUrl.isNotEmpty) 'snapshotUrl': snapshotUrl,
        if (resolution != null && resolution.isNotEmpty) 'resolution': resolution,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không thêm controller',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<Map<String, dynamic>> createSensor(
    String token, {
    required String sensorCode,
    required String sensorType,
    String? unit,
    String? deviceId,
  }) async {
    final uri = Uri.parse('$_base/api/sensors');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'sensorCode': sensorCode,
        'sensorType': sensorType,
        if (unit != null && unit.isNotEmpty) 'unit': unit,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không đăng ký cảm biến',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  /// `PUT /api/devices/{id}` — cập nhật cấu hình thiết bị/camera.
  ///
  /// Quy ước BE: bỏ qua trường `null`; `farmingRowId` = chuỗi Guid rỗng
  /// (`00000000-0000-0000-0000-000000000000`) để gỡ khỏi dãy; `streamUrl`/`snapshotUrl`/
  /// `resolution` = `''` để xoá giá trị.
  Future<Map<String, dynamic>> updateController(
    String token,
    String id, {
    String? name,
    String? deviceType,
    String? ipAddress,
    String? farmingAreaId,
    String? farmingRowId,
    String? streamUrl,
    String? snapshotUrl,
    String? resolution,
  }) async {
    final uri = Uri.parse('$_base/api/devices/$id');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (name != null) 'name': name,
        if (deviceType != null) 'deviceType': deviceType,
        if (ipAddress != null) 'ipAddress': ipAddress,
        if (farmingAreaId != null) 'farmingAreaId': farmingAreaId,
        if (farmingRowId != null) 'farmingRowId': farmingRowId,
        if (streamUrl != null) 'streamUrl': streamUrl,
        if (snapshotUrl != null) 'snapshotUrl': snapshotUrl,
        if (resolution != null) 'resolution': resolution,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không cập nhật thiết bị',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<Map<String, dynamic>> fetchWaterAnalysis(
    String token,
    String areaId,
  ) async {
    final uri = Uri.parse('$_base/api/areas/$areaId/water-analysis');
    final res = await _client.get(uri, headers: authHeaders(token, farmId: areaId));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải phân tích nước',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<Map<String, dynamic>> startWaterAnalysis(
    String token,
    String areaId,
  ) async {
    final uri = Uri.parse('$_base/api/areas/$areaId/water-analysis/start');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token, farmId: areaId), 'Content-Type': 'application/json'},
      body: '{}',
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không bắt đầu phân tích',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  /// CrabSenseBE `GET /api/operations/today`
  Future<List<Map<String, dynamic>>> fetchOperationsToday(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataList(token, '/api/operations/today', farmingAreaId: farmingAreaId);

  bool _isApiFailure(http.Response res, Map<String, dynamic> body) {
    if (res.statusCode < 200 || res.statusCode >= 300) return true;
    if (body['success'] == false || body['Success'] == false) return true;
    if (body['ok'] == false) return true;
    return false;
  }

  dynamic _dataOf(Map<String, dynamic> body) => body['data'] ?? body['Data'];

  List<dynamic> _itemsOf(Map<String, dynamic> body) {
    final data = _dataOf(body);
    if (data is List) return data;
    if (data is Map) {
      final items = data['items'] ?? data['Items'];
      if (items is List) return items;
    }
    final farms = body['farms'] ?? body['Farms'];
    if (farms is List) return farms;
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  String? _errorMessage(Map<String, dynamic> body) {
    final e = body['error'] ??
        body['Error'] ??
        body['message'] ??
        body['Message'];
    if (e != null && e.toString().trim().isNotEmpty) return e.toString();
    final data = _dataOf(body);
    if (data is Map) {
      final nested = data['message'] ?? data['Message'] ?? data['error'];
      if (nested != null) return nested.toString();
    }
    return null;
  }

  static Map<String, double> _parseReadingsMap(dynamic readingsRaw) {
    final readings = <String, double>{};
    if (readingsRaw is Map) {
      readingsRaw.forEach((k, v) {
        if (v is num) readings[k.toString()] = v.toDouble();
      });
    }
    return readings;
  }
}
