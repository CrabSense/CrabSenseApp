import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/scan_quick_result.dart';

/// Remote data source for QR scanner operations.
abstract class ScannerRemoteDataSource {
  Future<String> fetchBoxId(String qrCode);

  /// Loads enriched quick-result in a single API call.
  Future<ScanQuickResult> fetchQuickResult({
    required String boxId,
    required String rawValue,
  });

  /// Preferred: resolve QR + enrich in one round-trip.
  Future<ScanQuickResult> fetchQuickResultByQr(String rawValue);
}

class ScannerRemoteDataSourceImpl implements ScannerRemoteDataSource {
  const ScannerRemoteDataSourceImpl({required this._apiClient});

  final ApiClient _apiClient;

  String _lookupCode(String qrCode) {
    final sanitized = qrCode.trim();
    if (sanitized.toUpperCase().startsWith('CRABSENSE:BOX:')) {
      return sanitized.substring('CRABSENSE:BOX:'.length);
    }
    return sanitized;
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? responseData) {
    if (responseData == null) {
      throw const ServerException(message: 'Empty response from server.');
    }
    if (responseData['data'] is Map<String, dynamic>) {
      return responseData['data'] as Map<String, dynamic>;
    }
    return responseData;
  }

  void _throwFromFailure(Failure failure) {
    if (failure.code == 'NETWORK_ERROR' || failure.code == 'NETWORK_TIMEOUT') {
      throw const NetworkException(code: 'NETWORK_ERROR');
    }
    final statusCode = failure is ServerFailure ? failure.statusCode : null;
    throw ServerException(
      message: failure.message,
      statusCode: statusCode,
      code: failure.code,
    );
  }

  ScanQuickResult _mapQuick(Map<String, dynamic> data, String rawValue) {
    final boxId = (data['boxId'] ?? data['BoxId'] ?? '').toString();
    if (boxId.isEmpty) {
      throw const ServerException(
        message: 'QR không thuộc hệ thống CrabSense.',
        statusCode: 404,
      );
    }

    final alerts = <ScanAlertItem>[];
    final rawAlerts = data['alerts'] ?? data['Alerts'];
    if (rawAlerts is List) {
      for (final a in rawAlerts.take(5)) {
        if (a is! Map) continue;
        alerts.add(
          ScanAlertItem(
            title: (a['title'] ?? a['Title'] ?? 'Cảnh báo').toString(),
            severity:
                (a['severity'] ?? a['Severity'] ?? 'medium').toString().toLowerCase(),
          ),
        );
      }
    }

    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    int asInt(dynamic v, [int fallback = 0]) {
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? fallback;
    }

    final aiConf = asDouble(data['aiConfidence'] ?? data['AiConfidence']);

    return ScanQuickResult(
      boxId: boxId,
      code: (data['code'] ?? data['Code'] ?? boxId).toString(),
      rawValue: rawValue,
      scannedAt: DateTime.now(),
      farmId: (data['farmId'] ?? data['FarmId'] ?? '').toString(),
      farmName: (data['farmName'] ?? data['FarmName'] ?? '—').toString(),
      statusLabel:
          (data['statusLabel'] ?? data['StatusLabel'] ?? '—').toString(),
      healthScore: asInt(data['healthScore'] ?? data['HealthScore']),
      aiScore: asInt(data['aiScore'] ?? data['AiScore']),
      crabCount: asInt(data['crabCount'] ?? data['CrabCount']),
      temperature: asDouble(data['temperature'] ?? data['Temperature']),
      ph: asDouble(data['ph'] ?? data['Ph']),
      updatedAt: DateTime.tryParse(
            (data['updatedAt'] ?? data['UpdatedAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      aiRecommendation: (data['aiRecommendation'] ?? data['AiRecommendation'])
          ?.toString(),
      aiConfidence: aiConf,
      alerts: alerts,
      isOffline: false,
    );
  }

  @override
  Future<String> fetchBoxId(String qrCode) async {
    final lookup = _lookupCode(qrCode);
    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.boxesQr(lookup),
    );
    if (result.failure != null) {
      _throwFromFailure(result.failure!);
    }
    final dataMap = _unwrap(result.data.data);
    final boxId = dataMap['boxId']?.toString();
    if (boxId == null || boxId.isEmpty) {
      throw const ServerException(
        message: 'QR không thuộc hệ thống CrabSense.',
        statusCode: 404,
      );
    }
    return boxId;
  }

  @override
  Future<ScanQuickResult> fetchQuickResultByQr(String rawValue) async {
    final lookup = _lookupCode(rawValue);
    final result = await _apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.boxesQrQuickResult(lookup),
    );
    if (result.failure != null) {
      _throwFromFailure(result.failure!);
    }
    return _mapQuick(_unwrap(result.data.data), rawValue);
  }

  @override
  Future<ScanQuickResult> fetchQuickResult({
    required String boxId,
    required String rawValue,
  }) async {
    // Prefer single-shot QR endpoint; boxId kept for API compatibility.
    try {
      return await fetchQuickResultByQr(rawValue);
    } on ServerException {
      // Fallback: if rawValue fails, try resolving via boxId as code.
      if (boxId.isNotEmpty && boxId != rawValue) {
        return fetchQuickResultByQr(boxId);
      }
      rethrow;
    }
  }
}
