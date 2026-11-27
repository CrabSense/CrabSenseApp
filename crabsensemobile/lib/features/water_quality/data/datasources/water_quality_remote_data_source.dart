// ignore_for_file: lines_longer_than_80_chars

import 'package:dio/dio.dart' show DioException;
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/water_quality.dart' show LiveWaterKind, LiveWaterMetric;
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

    return items.map(_asStringKeyedMap)
        .map((row) => decodeLiveWaterReading(row, farmId: farmId, pondId: pondId))
        .whereType<WaterQualityModel>().toList()
      ..sort((a,b) => b.timestamp.compareTo(a.timestamp));
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

  @override
  Future<List<WaterQualityModel>> getHistoricalData({
    required String farmId,
    required HistoricalPeriod period,
    String? pondId,
  }) async {
    throw const ParseException(message: 'Historical per-sensor contract not verified');
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
    // Configuration is not a live connectivity observation.
    final status = data['status']?.toString().toLowerCase();
    if (status == 'online') return true;
    if (status == 'offline') return false;
    throw const ParseException(message: 'Unknown device connectivity');
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

    if (body.containsKey('data') && body['data'] is List) {
      return body['data'] as List;
    }

    if (body.containsKey('items') && body['items'] is List) {
      return body['items'] as List;
    }
    if (body.containsKey('Items') && body['Items'] is List) {
      return body['Items'] as List;
    }
    if (body.containsKey('data') && body['data'] is Map) {
      return _extractList(_asMap(body['data']), operationName);
    }

    // Body might be a list at the root in some API shapes.
    _logger.w('WaterQualityRemote: unexpected shape in $operationName');
    return [];
  }

}

WaterQualityModel? decodeLiveWaterReading(Map<String,dynamic> row, {
  required String farmId, String? pondId,
}) {
  if (row['isActive'] != true || row['dataQuality'] != 'Realtime') return null;
  final area = row['farmingAreaId'], sensor = row['sensorId'];
  if (area is! String || area.isEmpty || sensor is! String || sensor.isEmpty) return null;
  if (farmId.isNotEmpty && farmId != 'default' && area != farmId) return null;
  if (pondId != null && row['farmingRowId'] != pondId) return null;
  final type = row['sensorType']?.toString().toLowerCase();
  final unit = row['unit'];
  final value = parseMeasuredValue(row['latestValue']);
  final at = DateTime.tryParse(row['latestMeasuredAt']?.toString() ?? '');
  if (value == null || at == null || at.isAfter(DateTime.now().add(const Duration(seconds: 1)))) return null;
  final temperature = (type == 'temperature' && unit == '°C') ? value : null;
  final ph = (type == 'ph' && (unit == null || unit == '' || unit == 'pH')) ? value : null;
  final oxygen = ((type == 'do' || type == 'dissolvedoxygen' || type == 'dissolved_oxygen') && unit == 'mg/L') ? value : null;
  final salinity = type == 'salinity' && unit == 'ppt' ? value : null;
  final tds = type == 'tds' && (unit == 'ppm' || unit == 'mg/L') ? value : null;
  final kind = temperature != null ? LiveWaterKind.temperature :
      ph != null ? LiveWaterKind.ph : oxygen != null ? LiveWaterKind.oxygen :
      salinity != null ? LiveWaterKind.salinity : tds != null ? LiveWaterKind.tds : null;
  if (kind == null) return null;
  final received = DateTime.tryParse(row['lastReceivedAt']?.toString() ?? '');
  final now = DateTime.now().toUtc();
  final rawMin = row['minThreshold'], rawMax = row['maxThreshold'];
  double? threshold(Object? raw) => raw is num && raw.isFinite ? raw.toDouble() : null;
  final min = threshold(rawMin), max = threshold(rawMax);
  final validRange = (rawMin == null || min != null) && (rawMax == null || max != null) &&
      (min == null || max == null || min < max);
  final status = row['status'];
  final alarm = row['alarm'];
  final metric = row['latestValue'] is num && at.isUtc && received != null &&
      received.isUtc && !received.isBefore(at) &&
      !received.isAfter(now.add(const Duration(seconds: 1)))
      ? LiveWaterMetric(kind: kind, value: value, unit: kind == LiveWaterKind.ph ? 'pH' : unit as String,
          receivedAt: received, status: ['Online','Offline','Error','Disabled'].contains(status)
              ? status as String : 'Unknown',
          sensorCode: row['sensorCode'] is String && (row['sensorCode'] as String).isNotEmpty
              ? row['sensorCode'] as String : sensor,
          min: validRange ? min : null, max: validRange ? max : null,
          alarm: alarm is String && alarm.isNotEmpty ? alarm : null)
      : null;
  if (kind == LiveWaterKind.tds && metric == null) return null;
  return WaterQualityModel(id: '$sensor-${at.toUtc().toIso8601String()}',sensorId:sensor,
      farmId:area,pondId:row['farmingRowId']?.toString(),temperature:temperature,ph:ph,
      dissolvedOxygen:oxygen,salinity:salinity,timestamp:at,
      liveMetric:metric, isAlertTriggered:(row['alarm']?.toString().isNotEmpty ?? false));
}
