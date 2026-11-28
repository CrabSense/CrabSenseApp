import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/cloud_telemetry.dart';
import '../models/farm_record.dart';
import '../models/area_environment_metric.dart';
import '../models/farm_dashboard_overview.dart';
import '../models/feed_management_overview.dart';
import '../models/water_quality.dart';
import '../models/crab_feeding_activity.dart';
import '../models/crab_growth_molt.dart';
import '../models/crab_lifecycle_event.dart';
import '../models/crab_profile.dart';
import '../models/production_models.dart';
import '../models/harvest_assignment.dart';

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

    final userRaw =
        data['user'] ?? data['User'] ?? body['user'] ?? body['User'];
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
      throw CloudApiException('Phản hồi refresh thiếu accessToken',
          statusCode: 401);
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
        if (description != null && description.isNotEmpty)
          'description': description,
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
    if (res.statusCode < 200 ||
        res.statusCode >= 300 ||
        _isApiFailure(res, body)) {
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
        _errorMessage(body) ??
            'Không tải được /api/auth/me (${res.statusCode})',
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
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    final body = _decode(res);

    if (res.statusCode == 404) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tìm thấy thiết bị $mac',
        statusCode: 404,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải realtime (${res.statusCode})',
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
        _errorMessage(body) ?? 'Không tải history (${res.statusCode})',
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
      return res.statusCode >= 200 && res.statusCode < 300;
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

  Future<Object?> fetchManagerReport(String token, String report, {
    required String areaId,
    DateTime? from,
    DateTime? to,
  }) async {
    const allowed = {'harvest', 'harvest/period', 'inventory/filtered',
      'survival-rate', 'molting/filtered', 'operational-efficiency', 'crab-lots/compare'};
    if (!allowed.contains(report) || areaId.isEmpty) {
      throw CloudApiException('Báo cáo hoặc khu nuôi không hợp lệ.');
    }
    final query = <String, String>{
      'farmingAreaId': areaId,
      if (report == 'survival-rate' || report == 'molting/filtered') 'areaId': areaId,
      if (report == 'harvest/period') 'period': 'Day',
      if (from != null && report != 'inventory/filtered' && report != 'crab-lots/compare')
        'fromDate': from.toUtc().toIso8601String(),
      if (to != null && report != 'inventory/filtered' && report != 'crab-lots/compare')
        'toDate': to.toUtc().toIso8601String(),
      if (to != null && report == 'inventory/filtered') 'asOfDate': to.toUtc().toIso8601String(),
    };
    final uri = Uri.parse('$_base/api/reports/$report').replace(queryParameters: query);
    final res = await _client.get(uri, headers: authHeaders(token, farmId: areaId));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(_errorMessage(body) ?? 'Không tải được báo cáo', statusCode: res.statusCode);
    }
    return _dataOf(body) ?? body;
  }

  Future<List<Map<String, dynamic>>> fetchOperations(
    String token, {
    String? farmingAreaId,
    int limit = 200,
  }) =>
      _getDataList(
        token,
        '/api/operations',
        farmingAreaId: farmingAreaId,
        extraQuery: {'page': '1', 'limit': '$limit'},
      );

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
    String? relatedEntityType,
    String? relatedEntityId,
  }) async {
    final uri = Uri.parse('$_base/api/operations/photo');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(authHeaders(token));
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    if (boxId != null && boxId.isNotEmpty) req.fields['boxId'] = boxId;
    if (relatedEntityType != null && relatedEntityType.isNotEmpty) {
      req.fields['relatedEntityType'] = relatedEntityType;
    }
    if (relatedEntityId != null && relatedEntityId.isNotEmpty) {
      req.fields['relatedEntityId'] = relatedEntityId;
    }
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

  /// Upload ảnh vào đúng thư mục {khu}/ThuHoach/{mã phiếu}.
  /// Phải gọi SAU khi phiếu đã có id (BE sinh mã phiếu).
  Future<List<String>> uploadHarvestVoucherPhotos(
    String token,
    String voucherId,
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) return const [];
    final uri = Uri.parse('$_base/api/harvest-vouchers/$voucherId/images');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(authHeaders(token));
    for (final path in filePaths) {
      req.files.add(await http.MultipartFile.fromPath('files', path));
    }
    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải ảnh phiếu thu hoạch',
        statusCode: res.statusCode,
      );
    }
    final data = _dataOf(body);
    final items = data is List ? data : (data is Map ? data['items'] : null);
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((i) => (i['url'] ?? i['Url'])?.toString())
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
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
    String? status,
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
        if (status != null && status.isNotEmpty) 'status': status,
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

  Future<Map<String, dynamic>> decideHarvestVoucher(
    String token, String id, {
    required String action, String? reason, String? farmingAreaId,
  }) async {
    if (!const {'approve', 'reject', 'confirm'}.contains(action) ||
        id.trim().isEmpty || (action == 'reject' && (reason ?? '').trim().isEmpty)) {
      throw CloudApiException('Thao tác hoặc lý do không hợp lệ.');
    }
    final uri = Uri.parse('$_base/api/harvest-vouchers/$id/$action');
    final res = await _client.post(uri,
      headers: {...authHeaders(token, farmId: farmingAreaId), 'Content-Type': 'application/json'},
      body: jsonEncode({if (action == 'reject') 'reason': reason!.trim()}));
    final body = _decode(res);
    _throwIfFailed(res, body, uri.path);
    return _asMap(_dataOf(body) ?? body);
  }

  Future<Map<String,dynamic>> fetchHarvestAdjustmentSource(String token,String id,{required String areaId}) =>
    _getDataMap(token,'/api/harvest-vouchers/$id',farmingAreaId:areaId);

  Future<void> requestHarvestAdjustment(String token,String id,{required String areaId,required String reason,required List<Map<String,dynamic>> lines}) async {
    if(id.isEmpty||areaId.isEmpty||reason.trim().isEmpty||lines.isEmpty)throw CloudApiException('Thiếu dữ liệu điều chỉnh.');
    final uri=Uri.parse('$_base/api/harvest-vouchers/$id/adjustment-request');
    final res=await _client.post(uri,headers:{...authHeaders(token,farmId:areaId),'Content-Type':'application/json'},body:jsonEncode({'reason':reason.trim(),'lines':lines}));
    _throwIfFailed(res,_decode(res),uri.path);
  }

  Future<List<Map<String, dynamic>>> fetchHarvestAssignments(String token, {
    required String farmingAreaId,
  }) => _getDataList(token, '/api/harvest-assignments', farmingAreaId: farmingAreaId);
  

  Future<Map<String, dynamic>> fetchHarvestAssignmentDetail(String token, String id, {
    required String farmingAreaId,
  }) => _getDataMap(token, '/api/harvest-assignments/$id', farmingAreaId: farmingAreaId);

  Future<void> reviewHarvestAssignment(String token, String id, {
    required String farmingAreaId, required bool confirm, String? notes,
  }) async {
    if(id.trim().isEmpty || farmingAreaId.trim().isEmpty ||
        (!confirm && (notes ?? '').trim().isEmpty)) {
      throw CloudApiException('Thiếu nhiệm vụ, khu hoặc lý do bổ sung.');
    }
    final action = confirm ? 'confirm' : 'return';
    final uri = Uri.parse('$_base/api/harvest-assignments/$id/$action');
    final response = await _client.post(uri,
      headers: {...authHeaders(token, farmId: farmingAreaId), 'Content-Type': 'application/json'},
      body: jsonEncode({'notes': notes?.trim()}));
    _throwIfFailed(response, _decode(response), uri.path);
  }

  Future<void> handleHarvestAssignmentException(String token, String id, {
    required String farmingAreaId, required String action, required String reason,
    String? staffId, String? lineId,
  }) async {
    if (id.trim().isEmpty || farmingAreaId.trim().isEmpty ||
        reason.trim().isEmpty || reason.trim().length > 1000 ||
        !const {'cancel','reassign','skip'}.contains(action) ||
        (action == 'reassign' && (staffId ?? '').trim().isEmpty) ||
        (action == 'skip' && (lineId ?? '').trim().isEmpty)) {
      throw CloudApiException('Thiếu thông tin xử lý nhiệm vụ.');
    }
    final suffix = action == 'skip' ? 'lines/$lineId/skip' : action;
    final uri = Uri.parse('$_base/api/harvest-assignments/$id/$suffix');
    final response = await _client.post(uri,
      headers: {...authHeaders(token, farmId: farmingAreaId), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (action == 'cancel') 'notes': reason.trim() else 'reason': reason.trim(),
        if (action == 'reassign') 'assignedToUserId': staffId,
      }));
    _throwIfFailed(response, _decode(response), uri.path);
  }

  Future<Set<String>> fetchOpenHarvestAssignmentCrabIds(String token, {required String farmingAreaId}) async {
    if(farmingAreaId.isEmpty) throw CloudApiException('Thiếu khu nuôi.');
    final assignments=await fetchHarvestAssignments(token,farmingAreaId:farmingAreaId);
    final ids=<String>{};
    for(final task in assignments) {
      if((task['farmingAreaId']??task['FarmingAreaId']).toString()!=farmingAreaId) continue;
      final state=(task['status']??task['Status']).toString().toLowerCase();
      if(!const {'assigned','inprogress','pendingreview'}.contains(state)) continue;
      final taskId=(task['id']??task['Id']??'').toString();
      if(taskId.isEmpty) throw CloudApiException('Nhiệm vụ thiếu ID.');
      final detail=await fetchHarvestAssignmentDetail(token,taskId,farmingAreaId:farmingAreaId);
      if((detail['farmingAreaId']??detail['FarmingAreaId']).toString()!=farmingAreaId) throw CloudApiException('Nhiệm vụ không thuộc khu.');
      final lines=detail['lines']??detail['Lines'];
      if(lines is! List) throw CloudApiException('Thiếu danh sách cua đã giao.');
      for(final row in lines.whereType<Map>()) {
        final id=(row['crabId']??row['CrabId']??'').toString();
        // Resolved exceptions are no longer reserved; unknown states fail closed.
        final lineState = (row['status'] ?? row['Status'] ?? '').toString().toLowerCase();
        if(id.isNotEmpty && !const {'skipped','cancelled'}.contains(lineState)) ids.add(id);
      }
    }
    return ids;
  }

  Future<List<Map<String, dynamic>>> fetchFrozenLots(String token, {required String farmingAreaId}) =>
      _getDataList(token, '/api/frozen-lots', farmingAreaId: farmingAreaId);
  Future<List<Map<String, dynamic>>> fetchFrozenTransactions(String token, {required String farmingAreaId}) =>
      _getDataList(token, '/api/frozen-storage-transactions', farmingAreaId: farmingAreaId);

  Future<List<Map<String, dynamic>>> fetchFrozenCrabItems(String token, String lotId, {required String farmingAreaId}) =>
      _getDataList(token, '/api/frozen-lots/$lotId/crab-items', farmingAreaId: farmingAreaId);

  Future<List<Map<String, dynamic>>> fetchFrozenAdjustments(String token, String lotId, {required String farmingAreaId}) =>
      _getDataList(token, '/api/frozen-inventory-adjustments', farmingAreaId: farmingAreaId,
        extraQuery: {'frozenLotId': lotId});

  Future<List<Map<String, dynamic>>> fetchFrozenOpeningBalances(String token, {required String farmingAreaId}) =>
      _getDataList(token, '/api/frozen-opening-balances', farmingAreaId: farmingAreaId);

  Future<void> createFrozenLot(String token, {required String farmingAreaId,
    required String lotCode, String? harvestVoucherId, required DateTime frozenDate,
    required DateTime expiryDate, String? grade, String? storageLocation,
  }) => _writeFrozen(token, 'POST', '/api/frozen-lots', farmingAreaId, {
    'lotCode': lotCode, 'harvestVoucherId': harvestVoucherId,
    'farmingAreaId': farmingAreaId, 'frozenDate': frozenDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(), 'grade': grade,
    'storageLocation': storageLocation, 'quantity': 0, 'weightKg': 0,
  });

  Future<void> updateFrozenLot(String token, String id, {required String farmingAreaId,
    required DateTime frozenDate, required DateTime expiryDate, String? grade,
    String? storageLocation, required int quantity, required num weightKg, required String status,
  }) => _writeFrozen(token, 'PUT', '/api/frozen-lots/$id', farmingAreaId, {
    'frozenDate': frozenDate.toIso8601String(), 'expiryDate': expiryDate.toIso8601String(),
    'grade': grade, 'storageLocation': storageLocation,
    'quantity': quantity, 'weightKg': weightKg, 'status': status,
  });

  Future<void> deleteFrozenLot(String token, String id, {required String farmingAreaId}) =>
      _writeFrozen(token, 'DELETE', '/api/frozen-lots/$id', farmingAreaId, null);

  Future<void> reconcileFrozenCrabItems(String token, String lotId, {
    required String farmingAreaId, required List<String> availableItemIds, required String reason,
  }) => _writeFrozen(token, 'POST', '/api/frozen-lots/$lotId/crab-items/reconcile', farmingAreaId, {
    'availableItemIds': availableItemIds, 'reason': reason,
  });

  Future<void> verifyFrozenOpeningBalance(String token, String id, {
    required String farmingAreaId, required int quantity, required num weightKg, required String reason,
  }) => _writeFrozen(token, 'POST', '/api/frozen-opening-balances/$id/verify', farmingAreaId, {
    'openingQuantity': quantity, 'openingWeightKg': weightKg, 'reason': reason,
  });

  Future<List<Map<String, dynamic>>> fetchCorrectionHistory(String token, {
    required String areaId, required String entityId, required bool byBox, required String kind,
  }) {
    if (areaId.isEmpty || entityId.isEmpty ||
        !const {'allocations','moltings','status-history'}.contains(kind) ||
        (!byBox && kind == 'status-history')) {
      throw CloudApiException('Phạm vi lịch sử không hợp lệ.');
    }
    return _getDataList(token, '/api/${byBox ? 'boxes' : 'crabs'}/$entityId/$kind', farmingAreaId: areaId);
  }

  Future<void> correctAllocation(String token, String id, String area, {
    required String notes, DateTime? startTime, DateTime? endTime,
  }) => _writeFrozen(token,'PUT','/api/allocations/$id',area,{
    'notes':notes, if (startTime != null) 'startTime':startTime.toUtc().toIso8601String(),
    if (endTime != null) 'endTime':endTime.toUtc().toIso8601String(),
  });

  Future<void> correctMolting(String token, String id, String area, {
    required String reason, required String notes, String? result, DateTime? moltTime, double? weightAfterGram,
  }) => _writeFrozen(token,'PUT','/api/moltings/$id',area,{
    'correctionReason':reason,'notes':notes,if (result != null) 'result':result,
    if (moltTime != null) 'moltTime':moltTime.toUtc().toIso8601String(),
    if (weightAfterGram != null) 'weightAfterGram':weightAfterGram,
  });

  Future<void> voidMolting(String token, String id, String area, String reason) =>
    _writeFrozen(token,'POST','/api/moltings/$id/void',area,{'reason':reason});

  Future<void> correctBoxHistory(String token, String id, String area, {
    required String reason, String? newStatus, DateTime? changedAt, bool? newIsOccupied,
  }) => _writeFrozen(token,'PUT','/api/box-status-histories/$id',area,{
    'reason':reason,if (newStatus != null) 'newStatus':newStatus,
    if (changedAt != null) 'changedAt':changedAt.toUtc().toIso8601String(),
    if (newIsOccupied != null) 'newIsOccupied':newIsOccupied,
  });

  Future<void> _writeFrozen(String token, String method, String path, String area, Map<String, dynamic>? payload) async {
    if (area.trim().isEmpty) throw CloudApiException('Thiếu khu nuôi.');
    final uri = Uri.parse('$_base$path');
    final headers = {...authHeaders(token, farmId: area), 'Content-Type': 'application/json'};
    final body = payload == null ? null : jsonEncode(payload);
    final http.Response res;
    switch (method) {
      case 'POST': res = await _client.post(uri, headers: headers, body: body); break;
      case 'PUT': res = await _client.put(uri, headers: headers, body: body); break;
      case 'DELETE': res = await _client.delete(uri, headers: headers); break;
      default: throw CloudApiException('Thao tác kho không hợp lệ.');
    }
    _throwIfFailed(res, _decode(res), uri.path);
  }

  Future<void> decideFrozenTransaction(String token, String id, {
    required String farmingAreaId, required bool approve, String? reason,
  }) async {
    if (id.trim().isEmpty || farmingAreaId.trim().isEmpty ||
        (!approve && (reason ?? '').trim().isEmpty)) {
      throw CloudApiException('Thiếu phiếu, khu nuôi hoặc lý do từ chối.');
    }
    final action = approve ? 'approve' : 'reject';
    final uri = Uri.parse('$_base/api/frozen-storage-transactions/$id/$action');
    final res = await _client.post(uri,
      headers: {...authHeaders(token, farmId: farmingAreaId), 'Content-Type': 'application/json'},
      body: jsonEncode({if (!approve) 'reason': reason!.trim()}));
    _throwIfFailed(res, _decode(res), uri.path);
  }

  Future<void> deleteHarvestVoucher(String token, String id) async {
    final uri = Uri.parse('$_base/api/harvest-vouchers/$id');
    final res = await _client.delete(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không xóa phiếu thu hoạch',
        statusCode: res.statusCode,
      );
    }
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

  Future<Map<String, dynamic>> upsertCustomer(
    String token, {
    required String name,
    String? phone,
    String? address,
    String? customerType,
  }) async {
    final uri = Uri.parse('$_base/api/customers');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (customerType != null && customerType.isNotEmpty)
          'customerType': customerType,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không lưu khách hàng',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

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
    String? customerType,
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
        if (customerType != null && customerType.isNotEmpty)
          'customerType': customerType,
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

  Future<Map<String, dynamic>> completeSalesOrder(
      String token, String id) async {
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
    final uri =
        Uri.parse('$_base/api/sales/summary').replace(queryParameters: q);
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

  Future<Map<String, dynamic>?> fetchBoxCamera(
      String token, String boxId) async {
    final uri = Uri.parse('$_base/api/boxes/$boxId/camera');
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (res.statusCode == 404 || _isApiFailure(res, body)) return null;
    return _asMap(_dataOf(body) ?? body);
  }

  Future<List<Map<String, dynamic>>> fetchBoxCrabs(
          String token, String boxId) =>
      _getDataList(token, '/api/boxes/$boxId/crabs');

  Future<List<Map<String, dynamic>>> fetchBoxStatusHistory(
    String token,
    String boxId, {
    DateTime? from,
    DateTime? to,
  }) =>
      _getDataList(
        token,
        '/api/boxes/$boxId/status-history',
        extraQuery: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );

  Future<List<Map<String, dynamic>>> fetchBoxAllocations(
          String token, String boxId) =>
      _getDataList(token, '/api/boxes/$boxId/allocations');

  /// CrabSenseBE `GET /api/iot/live`
  Future<List<Map<String, dynamic>>> fetchIotLive(
    String token, {
    String? farmingAreaId,
  }) =>
      _getDataList(token, '/api/iot/live', farmingAreaId: farmingAreaId);

  /// Scoped history: explicit bearer, exact success envelope, no retry or redirect.
  Future<Map<String,dynamic>> fetchScopedHistoryPage(String token, {
    required String areaId, required String sensorId, String? rowId,
    required DateTime from, required DateTime to, required int page,
    String? asOf,
  }) async {
    final uri = Uri.parse('$_base/api/areas/$areaId/sensors/$sensorId/history')
        .replace(queryParameters: {
      'from':from.toIso8601String(),'to':to.toIso8601String(),
      if (rowId != null) 'farmingRowId':rowId,
      'page':'$page','pageSize':'250',if(asOf != null) 'asOf':asOf,
    });
    final request = http.Request('GET',uri)
      ..followRedirects = false
      ..headers.addAll(authHeaders(token,farmId:areaId));
    final response = await _client.send(request).then(http.Response.fromStream)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw CloudApiException('Không thể xác minh lịch sử.',statusCode:response.statusCode);
    }
    final body = _decode(response);
    if (body['success'] != true || body['data'] is! Map<String,dynamic>) {
      throw const FormatException('Invalid scoped history envelope');
    }
    return body['data'] as Map<String,dynamic>;
  }

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

  /// CrabSenseBE `GET /api/notifications/me` — Notification Center của user hiện tại.
  Future<List<Map<String, dynamic>>> fetchMyNotifications(
    String token, {
    bool unreadOnly = false,
  }) =>
      _getDataList(
        token,
        '/api/notifications/me',
        extraQuery: {'unreadOnly': '$unreadOnly'},
      );

  /// CrabSenseBE `PATCH /api/notifications/{id}/read`
  Future<void> markNotificationRead(String token, String id) async {
    final uri = Uri.parse('$_base/api/notifications/$id/read');
    final res = await _client.patch(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không đánh dấu đã đọc',
        statusCode: res.statusCode,
      );
    }
  }

  /// CrabSenseBE `PATCH /api/notifications/read-all`
  Future<void> markAllNotificationsRead(String token) async {
    final uri = Uri.parse('$_base/api/notifications/read-all');
    final res = await _client.patch(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không đánh dấu đã đọc tất cả',
        statusCode: res.statusCode,
      );
    }
  }

  Future<void> acknowledgeAlert(
    String token,
    String alertId, {
    String? userId,
    String? note,
  }) async {
    final uri = Uri.parse('$_base/api/alerts/$alertId/acknowledge');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không xác nhận cảnh báo',
        statusCode: res.statusCode,
      );
    }
  }

  Future<void> startAlertProcessing(
    String token,
    String alertId, {
    String? userId,
  }) async {
    final uri = Uri.parse('$_base/api/alerts/$alertId/process');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không bắt đầu xử lý cảnh báo',
        statusCode: res.statusCode,
      );
    }
  }

  Future<void> resolveAlert(
    String token,
    String alertId, {
    String? resolutionCode,
    String? reason,
    String? action,
    String? note,
    bool recovered = false,
    String? userId,
  }) async {
    final uri = Uri.parse('$_base/api/alerts/$alertId/resolve');
    final resolvedReason = (reason ?? resolutionCode)?.trim();
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (resolvedReason != null && resolvedReason.isNotEmpty)
          'reason': resolvedReason,
        if (action != null && action.trim().isNotEmpty) 'action': action.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'deviceRecovered': recovered,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      }),
    );
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
          if (farmingRowId != null && farmingRowId.isNotEmpty)
            'farmingRowId': farmingRowId,
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
          if (farmingAreaId != null && farmingAreaId.isNotEmpty)
            'farmingAreaId': farmingAreaId,
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
    String? installationLocation,
    String? note,
  }) async {
    final uri = Uri.parse('$_base/api/devices');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'deviceCode': deviceCode,
        if (name != null && name.isNotEmpty) 'name': name,
        'deviceType': deviceType ?? 'esp32-s3',
        if (macAddress != null && macAddress.isNotEmpty)
          'macAddress': macAddress,
        if (ipAddress != null && ipAddress.isNotEmpty) 'ipAddress': ipAddress,
        if (firmwareVersion != null && firmwareVersion.isNotEmpty)
          'firmwareVersion': firmwareVersion,
        if (farmingAreaId != null && farmingAreaId.isNotEmpty)
          'farmingAreaId': farmingAreaId,
        if (farmingRowId != null && farmingRowId.isNotEmpty)
          'farmingRowId': farmingRowId,
        if (streamUrl != null && streamUrl.isNotEmpty) 'streamUrl': streamUrl,
        if (snapshotUrl != null && snapshotUrl.isNotEmpty)
          'snapshotUrl': snapshotUrl,
        if (resolution != null && resolution.isNotEmpty)
          'resolution': resolution,
        if (installationLocation != null && installationLocation.isNotEmpty)
          'installationLocation': installationLocation,
        if (note != null && note.isNotEmpty) 'note': note,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không thêm controller (${res.statusCode})',
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
    String? status,
    String? firmwareVersion,
    String? macAddress,
    String? installationLocation,
    String? note,
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
        if (status != null) 'status': status,
        if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
        if (macAddress != null) 'macAddress': macAddress,
        if (installationLocation != null)
          'installationLocation': installationLocation,
        if (note != null) 'note': note,
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

  Future<void> deleteController(String token, String id) async {
    final uri = Uri.parse('$_base/api/devices/$id');
    final res = await _client.delete(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không xóa controller',
        statusCode: res.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> updateSensor(
    String token,
    String id, {
    String? sensorType,
    String? unit,
    bool? isActive,
  }) async {
    final uri = Uri.parse('$_base/api/sensors/$id');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (sensorType != null) 'sensorType': sensorType,
        if (unit != null) 'unit': unit,
        if (isActive != null) 'isActive': isActive,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không cập nhật cảm biến',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<void> recordSensorCalibration(
      String token, String id, Map<String, dynamic> payload) async {
    final res = await _client.post(
        Uri.parse('$_base/api/sensors/$id/calibrations'),
        headers: {...authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode(payload));
    final body = _decode(res);
    if (_isApiFailure(res, body))
      throw CloudApiException(
          _errorMessage(body) ?? 'Không lưu được hiệu chuẩn',
          statusCode: res.statusCode);
  }

  Future<void> setSensorActive(String token, String id, bool active) async {
    final res = await _client.post(
        Uri.parse('$_base/api/sensors/$id/${active ? 'enable' : 'disable'}'),
        headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body))
      throw CloudApiException(
          _errorMessage(body) ?? 'Không đổi được trạng thái Sensor',
          statusCode: res.statusCode);
  }

  Future<List<Map<String, dynamic>>> fetchDiscoveredSensors(
          String token, String deviceId) =>
      _getDataList(token, '/api/sensors/discovered',
          extraQuery: {'deviceId': deviceId});

  Future<void> registerSensorFromPort(
      String token, Map<String, dynamic> payload) async {
    final res = await _client.post(
        Uri.parse('$_base/api/sensors/register-from-port'),
        headers: {...authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode(payload));
    final body = _decode(res);
    if (_isApiFailure(res, body))
      throw CloudApiException(
          _errorMessage(body) ?? 'Không đăng ký được Sensor',
          statusCode: res.statusCode);
  }

  Future<void> deleteSensor(String token, String id) async {
    final res = await _client.delete(
      Uri.parse('$_base/api/sensors/$id'),
      headers: authHeaders(token),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không xóa cảm biến',
        statusCode: res.statusCode,
      );
    }
  }

  /// Upload a private sample to a server-selected batch/channel folder.
  /// The caller must separately confirm capture using the returned media ID.
  Future<String> uploadWaterBatchSample(
    String token, String areaId, String batchId, String analyte,
    {required List<int> bytes, required String filename, required String mimeType}
  ) async {
    final chemical = analyte.trim().toUpperCase();
    if (!const {'NO2', 'NO3', 'NH3', 'PH'}.contains(chemical)) {
      throw CloudApiException('Chỉ tiêu phân tích không hợp lệ.');
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024 ||
        !const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      throw CloudApiException('Ảnh mẫu không hợp lệ hoặc vượt 5 MiB.');
    }
    final uri = Uri.parse('$_base/api/areas/${Uri.encodeComponent(areaId)}'
        '/water-analysis/batches/${Uri.encodeComponent(batchId)}/channels/$chemical/sample');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(authHeaders(token, farmId: areaId))
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename, contentType: MediaType.parse(mimeType)));
    final response = await http.Response.fromStream(await _client.send(request));
    final body = _decode(response);
    if (_isApiFailure(response, body)) {
      throw CloudApiException(_errorMessage(body) ?? 'Không tải được ảnh mẫu.',
          statusCode: response.statusCode);
    }
    final data = _asMap(_dataOf(body) ?? body);
    final id = (data['id'] ?? data['Id'])?.toString();
    if (id == null || id.isEmpty) {
      throw CloudApiException('API không trả về MediaAssetId.');
    }
    return id;
  }

  Future<Map<String, dynamic>> fetchWaterAnalysisDetail(
    String token,
    String areaId,
    String runId,
  ) async {
    final uri = Uri.parse('$_base/api/areas/$areaId/water-analysis/$runId');
    final res =
        await _client.get(uri, headers: authHeaders(token, farmId: areaId));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải chi tiết phân tích',
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
    final res =
        await _client.get(uri, headers: authHeaders(token, farmId: areaId));
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
    String areaId, {
    String? analyte,
    String? sampleSource,
    String? sampleLocation,
    String? notes,
  }) async {
    final uri = Uri.parse('$_base/api/areas/$areaId/water-analysis/start');
    final res = await _client.post(
      uri,
      headers: {
        ...authHeaders(token, farmId: areaId),
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        if (analyte != null) 'analyte': analyte,
        if (sampleSource != null) 'sampleSource': sampleSource,
        if (sampleLocation != null) 'sampleLocation': sampleLocation,
        if (notes != null) 'notes': notes,
      }),
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

  Future<Map<String, dynamic>> stopWaterAnalysis(
    String token,
    String areaId,
  ) async {
    final uri = Uri.parse('$_base/api/areas/$areaId/water-analysis/stop');
    final res = await _client.post(
      uri,
      headers: {
        ...authHeaders(token, farmId: areaId),
        'Content-Type': 'application/json'
      },
      body: '{}',
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không dừng phân tích',
        statusCode: res.statusCode,
      );
    }
    return _asMap(_dataOf(body) ?? body);
  }

  Future<Map<String, dynamic>> updateWaterAnalysisSample(
    String token,
    String areaId, {
    required String sampleSource,
    String? sampleLocation,
    String? notes,
  }) async {
    final uri = Uri.parse('$_base/api/areas/$areaId/water-analysis/sample');
    final res = await _client.put(
      uri,
      headers: {
        ...authHeaders(token, farmId: areaId),
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'sampleSource': sampleSource,
        if (sampleLocation != null) 'sampleLocation': sampleLocation,
        if (notes != null) 'notes': notes,
      }),
    );
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không cập nhật thông tin mẫu',
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
      _getDataList(token, '/api/operations/today',
          farmingAreaId: farmingAreaId);

  bool _isApiFailure(http.Response res, Map<String, dynamic> body) {
    if (res.statusCode < 200 || res.statusCode >= 300) return true;
    if (body['success'] == false || body['Success'] == false) return true;
    if (body['ok'] == false) return true;
    return false;
  }

  Future<List<Map<String, dynamic>>> listKiosks(
    String token,
    String farmingAreaId,
  ) async {
    final uri = Uri.parse('$_base/api/kiosks').replace(
      queryParameters: {'farmingAreaId': farmingAreaId},
    );
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    _throwIfFailed(res, body, '/api/kiosks');
    return _itemsOf(body).map(_asMap).toList();
  }

  Future<Map<String, dynamic>> createKiosk(
    String token,
    String farmingAreaId, {
    String? name,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/api/kiosks'),
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'farmingAreaId': farmingAreaId,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      }),
    );
    final body = _decode(res);
    _throwIfFailed(res, body, '/api/kiosks');
    return _asMap(_dataOf(body));
  }

  Future<Map<String, dynamic>> issueKioskCode(
      String token, String kioskId) async {
    final res = await _client.post(
      Uri.parse('$_base/api/kiosks/$kioskId/provisioning-codes'),
      headers: authHeaders(token),
    );
    final body = _decode(res);
    _throwIfFailed(res, body, '/api/kiosks/$kioskId/provisioning-codes');
    return _asMap(_dataOf(body));
  }

  Future<void> revokeKiosk(String token, String kioskId) async {
    final res = await _client.post(
      Uri.parse('$_base/api/kiosks/$kioskId/revoke'),
      headers: authHeaders(token),
    );
    final body = _decode(res);
    _throwIfFailed(res, body, '/api/kiosks/$kioskId/revoke');
  }

  Future<void> deleteKiosk(String token, String kioskId) async {
    final res = await _client.delete(
      Uri.parse('$_base/api/kiosks/$kioskId'),
      headers: authHeaders(token),
    );
    final body = _decode(res);
    _throwIfFailed(res, body, '/api/kiosks/$kioskId');
  }

  Future<List<Map<String, dynamic>>> listEdgeControllers(
    String token,
    String farmingAreaId,
  ) async {
    final uri = Uri.parse('$_base/api/kiosks/controllers').replace(
      queryParameters: {'farmingAreaId': farmingAreaId},
    );
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    _throwIfFailed(res, body, '/api/kiosks/controllers');
    return _itemsOf(body).map(_asMap).toList();
  }

  Future<void> approveController(String token, String deviceId) async {
    final res = await _client.post(
      Uri.parse('$_base/api/controllers/$deviceId/approve'),
      headers: authHeaders(token),
    );
    final body = _decode(res);
    _throwIfFailed(res, body, '/api/controllers/$deviceId/approve');
  }

  Future<void> rejectController(String token, String deviceId) async {
    final res = await _client.post(
      Uri.parse('$_base/api/controllers/$deviceId/reject'),
      headers: authHeaders(token),
    );
    final body = _decode(res);
    _throwIfFailed(res, body, '/api/controllers/$deviceId/reject');
  }

  void _throwIfFailed(
      http.Response res, Map<String, dynamic> body, String path) {
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Lỗi API $path (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
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
    final e =
        body['error'] ?? body['Error'] ?? body['message'] ?? body['Message'];
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

  /// Lấy nhân viên đang hoạt động thuộc khu mà Manager được phép quản lý.
  Future<List<HarvestAssignmentStaff>> fetchHarvestAssignmentStaff(
    String token, {
    required String farmingAreaId,
  }) async {
    final items = await _getDataList(
      token,
      '/api/harvest-assignments/staff',
      farmingAreaId: farmingAreaId,
    );

    return items
        .map(HarvestAssignmentStaff.fromJson)
        .where((staff) => staff.id.isNotEmpty)
        .toList(growable: false);
  }

  /// Gửi yêu cầu tạo task thu hoạch đến BE.
  Future<Map<String, dynamic>> createHarvestAssignment(
    String token, {
    required String farmingAreaId,
    required String assignedToUserId,
    required List<String> crabIds,
    String? notes,
  }) async {
    final uri = Uri.parse('$_base/api/harvest-assignments');

    final response = await _client.post(
      uri,
      headers: {
        ...authHeaders(token, farmId: farmingAreaId),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'farmingAreaId': farmingAreaId,
        'assignedToUserId': assignedToUserId,
        'crabIds': crabIds,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );

    final body = _decode(response);

    // Ném lỗi của BE để giao diện hiển thị đúng lý do không giao được task.
    if (_isApiFailure(response, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tạo được nhiệm vụ thu hoạch',
        statusCode: response.statusCode,
      );
    }

    return _asMap(_dataOf(body) ?? body);
  }
  
}
