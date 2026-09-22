// ignore_for_file: lines_longer_than_80_chars

import 'package:dio/dio.dart' show DioException;
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/water_quality_repository.dart' show HistoricalPeriod;
import '../models/water_quality_model.dart';

/// Contract for fetching water quality data from the remote API.
///
/// All methods throw typed exceptions on failure:
/// - [ServerException]: 4xx / 5xx API responses.
/// - [NetworkException]: No connectivity or request timeout.
/// - [ParseException]: Malformed or unexpected JSON response body.
///
/// Requirements: 8.1-8.10
abstract class WaterQualityRemoteDataSource {
  /// Fetches the latest water quality readings for a farm or pond.
  ///
  /// Returns a list of [WaterQualityModel] sorted by timestamp descending.
  /// The first element is the most-recent reading.
  ///
  /// Requirements: 8.1, 8.2, 8.3, 8.8
  Future<List<WaterQualityModel>> getCurrentReadings({required String farmId, String? pondId});

  /// Fetches historical water quality readings for the given period.
  ///
  /// Results are sorted by timestamp ascending for chart rendering.
  ///
  /// Requirements: 8.5
  Future<List<WaterQualityModel>> getHistoricalData({
    required String farmId,
    required HistoricalPeriod period,
    String? pondId,
  });

  /// Checks whether an IoT sensor/device is online.
  ///
  /// Returns `true` if the device is reachable, `false` if offline.
  ///
  /// Requirements: 8.8
  Future<bool> checkDeviceStatus({required String sensorId});
}

/// Dio-backed implementation of [WaterQualityRemoteDataSource].
///
/// Uses [ApiClient.safeGet] which maps [DioException] to domain [Failure]
/// objects. Failures are converted back to typed exceptions here so the
/// repository layer can handle them uniformly.
class WaterQualityRemoteDataSourceImpl implements WaterQualityRemoteDataSource {
  WaterQualityRemoteDataSourceImpl({required this._apiClient, required this._logger});

  final ApiClient _apiClient;
  final Logger _logger;

  // ──────────────────────────────────────────────────────────────────────────
  // WaterQualityRemoteDataSource implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<WaterQualityModel>> getCurrentReadings({
    required String farmId,
    String? pondId,
  }) async {
    _logger.d(
      'WaterQualityRemote: getCurrentReadings '
      'farmId=$farmId pondId=$pondId',
    );

    final queryParams = <String, dynamic>{};
    // BE /iot/live scopes by farmingAreaId (Guid). Keep farmId for legacy callers.
    if (farmId.isNotEmpty && farmId != 'default') {
      final looksLikeGuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(farmId);
      if (looksLikeGuid) {
        queryParams['farmingAreaId'] = farmId;
      } else {
        queryParams['farmId'] = farmId;
      }
    }
    if (pondId != null) {
      queryParams['pondId'] = pondId;
    }

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.waterQualityLatest,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    _checkFailure(result.failure, 'current water quality readings');

    final items = _extractList(
      result.data.data is Map<String, dynamic>
          ? result.data.data as Map<String, dynamic>
          : _asMap(result.data.data),
      'getCurrentReadings',
    );

    // BE /iot/live returns per-sensor rows (SensorLiveDto). Aggregate into
    // one WaterQuality snapshot the UI/chart layer expects.
    if (items.isNotEmpty && items.first is Map && (items.first as Map).containsKey('sensorType')) {
      return [_aggregateLiveSensors(items, farmId)];
    }

    return items
        .map((e) => WaterQualityModel.fromJson(_asStringKeyedMap(e)))
        .toList(growable: false);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  Map<String, dynamic> _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw const ParseException(message: 'Expected JSON object for water quality row');
  }

  WaterQualityModel _aggregateLiveSensors(List<dynamic> items, String farmId) {
    double temperature = 0;
    double ph = 0;
    double dissolvedOxygen = 0;
    double salinity = 0;
    var hasAlert = false;
    String sensorId = '';
    DateTime timestamp = DateTime.now();

    for (final raw in items) {
      final map = _asStringKeyedMap(raw);
      final type = (map['sensorType'] ?? map['SensorType'] ?? '').toString().toLowerCase();
      final value = (map['latestValue'] ?? map['LatestValue'] ?? map['value'] ?? 0) as num;
      final alarm = map['alarm']?.toString() ?? map['Alarm']?.toString();
      if (alarm != null && alarm.isNotEmpty) hasAlert = true;

      final measuredAt = map['latestMeasuredAt'] ?? map['LatestMeasuredAt'];
      if (measuredAt != null) {
        timestamp = DateTime.tryParse(measuredAt.toString()) ?? timestamp;
      }

      sensorId = map['sensorId']?.toString() ??
          map['SensorId']?.toString() ??
          sensorId;

      if (type.contains('temp')) {
        temperature = value.toDouble();
      } else if (type.contains('ph') || type == 'pH'.toLowerCase()) {
        ph = value.toDouble();
      } else if (type.contains('do') ||
          type.contains('oxygen') ||
          type.contains('oxy')) {
        dissolvedOxygen = value.toDouble();
      } else if (type.contains('salin') || type.contains('salt')) {
        salinity = value.toDouble();
      }
    }

    return WaterQualityModel(
      id: 'live_${farmId.isEmpty ? 'all' : farmId}',
      sensorId: sensorId,
      farmId: farmId,
      temperature: temperature,
      ph: ph,
      dissolvedOxygen: dissolvedOxygen,
      salinity: salinity,
      timestamp: timestamp,
      isAlertTriggered: hasAlert,
    );
  }

  @override
  Future<List<WaterQualityModel>> getHistoricalData({
    required String farmId,
    required HistoricalPeriod period,
    String? pondId,
  }) async {
    _logger.d(
      'WaterQualityRemote: getHistoricalData '
      'farmId=$farmId period=${period.name} pondId=$pondId',
    );

    final now = DateTime.now().toUtc();
    final from = now.subtract(_periodDuration(period));
    final queryParams = <String, dynamic>{
      'from': from.toIso8601String(),
      'to': now.toIso8601String(),
    };
    if (farmId.isNotEmpty && farmId != 'default') {
      final looksLikeGuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(farmId);
      if (looksLikeGuid) {
        queryParams['farmingAreaId'] = farmId;
      } else {
        queryParams['farmId'] = farmId;
      }
    }
    if (pondId != null) {
      queryParams['pondId'] = pondId;
    }

    // BE does not expose the old /iot/history route. The desktop client
    // reads each sensor through /iot/sensor-data/{sensorId}; keep mobile on
    // the same contract instead of inventing a cloud endpoint.
    final live = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.iotLive,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    _checkFailure(live.failure, 'water quality sensor list');

    final liveItems = _extractListPayload(live.data.data, 'getHistoricalData');
    final sensorTypes = <String, String>{};
    for (final raw in liveItems) {
      final row = _asStringKeyedMap(raw);
      final id = (row['sensorId'] ?? row['SensorId'])?.toString();
      final type = (row['sensorType'] ?? row['SensorType'])?.toString();
      if (id != null && id.isNotEmpty && type != null && type.isNotEmpty) {
        sensorTypes[id] = type;
      }
    }

    final history = <WaterQualityModel>[];
    for (final entry in sensorTypes.entries) {
      final result = await _apiClient.safeGet<Map<String, dynamic>>(
        ApiConstants.sensorData(entry.key),
        queryParameters: {
          'from': from.toIso8601String(),
          'to': now.toIso8601String(),
          'page': 1,
          'pageSize': 2000,
        },
      );
      _checkFailure(result.failure, 'historical data for sensor ${entry.key}');
      for (final raw in _extractListPayload(
        result.data.data,
        'sensor history ${entry.key}',
      )) {
        final row = _asStringKeyedMap(raw);
        final value = (row['value'] ?? row['Value']) as num?;
        final measuredAt = row['measuredAt'] ?? row['MeasuredAt'];
        final timestamp = measuredAt == null
            ? null
            : DateTime.tryParse(measuredAt.toString());
        if (value == null || timestamp == null) continue;
        history.add(_sensorReadingAsWaterQuality(
          row,
          entry.key,
          entry.value,
          value.toDouble(),
          timestamp,
          farmId,
        ));
      }
    }

    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return history;
  }

  @override
  Future<bool> checkDeviceStatus({required String sensorId}) async {
    _logger.d('WaterQualityRemote: checkDeviceStatus sensorId=$sensorId');

    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      '${ApiConstants.sensors}/$sensorId',
    );

    _checkFailure(result.failure, 'device status check');

    final body = result.data.data;
    if (body == null) {
      return false;
    }

    final data = body.containsKey('data') && body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : body;

    if (data['online'] is bool) return data['online'] as bool;
    if (data['isOnline'] is bool) return data['isOnline'] as bool;
    if (data['isActive'] is bool) return data['isActive'] as bool;
    final status = data['status']?.toString().toLowerCase();
    return status == 'online' || status == 'active';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Throws the appropriate typed exception when [failure] is non-null.
  void _checkFailure(Failure? failure, String context) {
    if (failure == null) {
      return;
    }

    if (failure is NetworkFailure) {
      throw NetworkException(message: failure.message, code: failure.code);
    }

    if (failure is ServerFailure) {
      throw ServerException(
        message: failure.message,
        statusCode: failure.statusCode,
        code: failure.code,
      );
    }

    throw ServerException(
      message: 'Failed to fetch $context: ${failure.message}',
      code: failure.code,
    );
  }

  /// Extracts a list payload from the API response body.
  ///
  /// The CrabSense API may wrap results in `{ "data": [...] }` or
  /// return the list directly.
  List<dynamic> _extractList(Map<String, dynamic>? body, String operationName) {
    if (body == null) {
      return [];
    }

    if (body.containsKey('data') && body['data'] is List<dynamic>) {
      return body['data'] as List<dynamic>;
    }

    if (body.containsKey('items') && body['items'] is List<dynamic>) {
      return body['items'] as List<dynamic>;
    }

    // Body might be a list at the root in some API shapes.
    _logger.w('WaterQualityRemote: unexpected shape in $operationName');
    return [];
  }

  /// Like [_extractList] but also accepts a raw [List] payload.
  List<dynamic> _extractListPayload(dynamic body, String operationName) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) return _extractList(body, operationName);
    if (body is Map) {
      return _extractList(
        body.map((k, v) => MapEntry(k.toString(), v)),
        operationName,
      );
    }
    _logger.w('WaterQualityRemote: unexpected shape in $operationName');
    return [];
  }

  Duration _periodDuration(HistoricalPeriod period) => switch (period) {
        HistoricalPeriod.last24Hours => const Duration(hours: 24),
        HistoricalPeriod.last7Days => const Duration(days: 7),
        HistoricalPeriod.last30Days => const Duration(days: 30),
      };

  WaterQualityModel _sensorReadingAsWaterQuality(
    Map<String, dynamic> row,
    String sensorId,
    String sensorType,
    double value,
    DateTime timestamp,
    String farmId,
  ) {
    final type = sensorType.toLowerCase();
    return WaterQualityModel(
      id: (row['id'] ?? row['Id'] ?? '$sensorId-${timestamp.toIso8601String()}')
          .toString(),
      sensorId: sensorId,
      farmId: farmId,
      temperature: type.contains('temp') ? value : 0,
      ph: type == 'ph' || type.contains('ph') ? value : 0,
      dissolvedOxygen:
          type.contains('do') || type.contains('oxygen') ? value : 0,
      salinity: type.contains('salin') || type.contains('salt') ? value : 0,
      timestamp: timestamp,
      isAlertTriggered: false,
    );
  }
}
