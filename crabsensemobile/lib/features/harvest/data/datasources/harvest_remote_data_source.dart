// ignore_for_file: lines_longer_than_80_chars

import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/harvest.dart';
import '../models/harvest_model.dart';

/// Contract for fetching and mutating harvest data on the remote API.
///
/// All methods throw typed exceptions on failure:
/// - [ServerException]: 4xx / 5xx API responses.
/// - [NetworkException]: No connectivity or request timeout.
/// - [ParseException]: Malformed or unexpected JSON response body.
///
/// Requirements: 11.1-11.10
abstract class HarvestRemoteDataSource {
  /// Submits a new harvest record to the remote server.
  ///
  /// Requirements: 11.1-11.7
  Future<HarvestModel> recordHarvest(HarvestModel model);

  /// Fetches a paginated, filterable harvest history list.
  ///
  /// Requirements: 11.9
  Future<List<HarvestModel>> getHarvestHistory({
    String? farmId,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
    int page = 1,
    int limit = 50,
  });

  /// Fetches aggregated harvest metrics for a farm within a date range.
  ///
  /// Requirements: 11.10
  Future<HarvestSummaryModel> getHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetches a single harvest record by ID.
  Future<HarvestModel> getHarvestById(String id);
}

/// Dio-backed implementation of [HarvestRemoteDataSource].
class HarvestRemoteDataSourceImpl implements HarvestRemoteDataSource {
  HarvestRemoteDataSourceImpl({
    required this.apiClient,
    required this.logger,
  });

  final ApiClient apiClient;
  final Logger logger;

  @override
  Future<HarvestModel> recordHarvest(HarvestModel model) async {
    logger.d('HarvestRemote: recordHarvest boxId=${model.boxId} weight=${model.totalWeight} count=${model.crabCount}');

    // Tạo phiếu TRƯỚC: mã HAR-xxx do BE sinh, chỉ khi có id mới biết thư mục
    // {khu}/ThuHoach/{mã phiếu} để đẩy ảnh vào đúng chỗ.
    final result = await apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.recordHarvest,
      data: _voucherBody(model),
    );

    _checkFailure(result.failure, 'record harvest');

    final envelope = result.data.data;
    if (envelope == null) {
      throw const ServerException(
        message: 'Empty response from record harvest endpoint',
        code: 'PARSE_ERROR',
      );
    }

    // Response bọc ApiResponse<...>: { success, data: { id, voucherCode, ... } }
    final payload = envelope['data'];
    final body = payload is Map ? payload : envelope;
    final voucherId = (body['id'] ?? body['Id'])?.toString();
    var photoUrls = const <String>[];
    if (voucherId != null && voucherId.isNotEmpty) {
      try {
        photoUrls = await _uploadLocalPhotos(voucherId, model.photoUrls);
      } on Exception catch (e) {
        // Phiếu đã tạo xong; ném lỗi ở đây sẽ khiến lần sync sau tạo TRÙNG phiếu
        // (và cộng đôi sản lượng). Giữ ảnh local trên máy, ghi log để upload lại
        // qua POST /harvest-vouchers/{id}/images khi có mạng ổn định.
        // ponytail: chấp nhận ảnh chưa lên Drive nếu upload lỗi; nâng cấp = lưu
        // voucherId + hàng đợi retry ảnh trong DB local.
        logger.w('HarvestRemote: upload ảnh phiếu $voucherId lỗi — $e');
      }
    }

    return model.copyWith(
      photoUrls: photoUrls.isEmpty ? model.photoUrls : photoUrls,
      isSynced: true,
      isDirty: false,
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<List<HarvestModel>> getHarvestHistory({
    String? farmId,
    String? boxId,
    DateTime? startDate,
    DateTime? endDate,
    QualityGrade? qualityGrade,
    int page = 1,
    int limit = 50,
  }) async {
    logger.d('HarvestRemote: getHarvestHistory farmId=$farmId boxId=$boxId page=$page limit=$limit');

    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (farmId != null && farmId.isNotEmpty) {
      queryParams['farmId'] = farmId;
    }
    if (boxId != null && boxId.isNotEmpty) {
      queryParams['boxId'] = boxId;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (qualityGrade != null) {
      queryParams['qualityGrade'] = qualityGrade.toCode();
    }

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.harvestHistory,
      queryParameters: queryParams,
    );

    _checkFailure(result.failure, 'harvest history');

    final items = _extractList(result.data.data, 'getHarvestHistory');
    return items
        .map((e) => HarvestModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<HarvestSummaryModel> getHarvestSummary({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    logger.d('HarvestRemote: getHarvestSummary farmId=$farmId period=$startDate - $endDate');

    final queryParams = <String, dynamic>{
      'farmId': farmId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.harvestSummary,
      queryParameters: queryParams,
    );

    _checkFailure(result.failure, 'harvest summary for farm $farmId');

    final body = result.data.data;
    if (body == null) {
      throw ServerException(
        message: 'Empty response from harvest summary endpoint for farm $farmId',
        code: 'PARSE_ERROR',
      );
    }

    return HarvestSummaryModel.fromJson(_unwrapData(body));
  }

  @override
  Future<HarvestModel> getHarvestById(String id) async {
    logger.d('HarvestRemote: getHarvestById id=$id');

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.harvestDetails(id),
    );

    _checkFailure(result.failure, 'harvest details for id $id');

    final body = result.data.data;
    if (body == null) {
      throw ServerException(
        message: 'Empty response from harvest details endpoint for id=$id',
        code: 'PARSE_ERROR',
      );
    }

    return HarvestModel.fromJson(_unwrapData(body));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  void _checkFailure(Failure? failure, String context) {
    if (failure == null) return;

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

    final detail = failure is ValidationFailure
        ? failure.fieldErrors?.values
            .map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty)
            .join(' ')
        : null;
    throw ServerException(
      message: 'Failed to fetch $context: ${(detail == null || detail.isEmpty) ? failure.message : detail}',
      code: failure.code,
    );
  }

  /// Đẩy các ảnh còn là đường dẫn local lên Drive trong thư mục của phiếu.
  ///
  /// BE chỉ tạo MediaAsset từ file thô, không nhận path — nên nếu bỏ qua bước này
  /// thì ảnh thu hoạch chỉ nằm trong cache điện thoại và mất khi Android dọn.
  Future<List<String>> _uploadLocalPhotos(
    String voucherId,
    List<String> photoRefs,
  ) async {
    final urls = <String>[];
    final localPaths = <String>[];
    for (final ref in photoRefs) {
      final value = ref.trim();
      if (value.isEmpty) continue;
      if (value.startsWith('http://') || value.startsWith('https://')) {
        urls.add(value);
      } else {
        localPaths.add(value);
      }
    }
    if (localPaths.isEmpty) return urls;

    final form = FormData();
    for (final path in localPaths) {
      try {
        form.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              path,
              filename: path.split(RegExp(r'[\\/]')).last,
            ),
          ),
        );
      } on Exception catch (e) {
        throw ServerException(
          message: 'Không đọc được ảnh $path: $e',
          code: 'PHOTO_READ_ERROR',
        );
      }
    }

    final upload = await apiClient.safePost<dynamic>(
      ApiConstants.harvestVoucherImages(voucherId),
      data: form,
    );
    _checkFailure(upload.failure, 'upload harvest photo');

    final body = upload.data.data;
    dynamic raw = body is Map ? (body['data'] ?? body) : body;
    if (raw is Map) raw = raw['items'] ?? raw['data'] ?? raw;
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final url = (item['url'] ??
                item['Url'] ??
                item['storageKey'] ??
                item['StorageKey'])
            ?.toString();
        if (url != null && url.isNotEmpty) urls.add(url);
      }
    }

    if (urls.isEmpty) {
      throw const ServerException(
        message: 'Upload ảnh thu hoạch không trả về URL',
        code: 'PHOTO_UPLOAD_EMPTY',
      );
    }
    return urls;
  }

  Map<String, dynamic> _voucherBody(HarvestModel model) {
    final guid = RegExp(
      r'^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$',
    );
    final crabId = (model.crabId ?? '').trim();
    final farmId = model.farmId.trim();
    final grade = switch (model.qualityGrade) {
      QualityGrade.gradeA => 'A',
      QualityGrade.gradeB => 'B',
      QualityGrade.gradeC => 'C',
    };
    final notes = model.notes?.trim();
    // Chỉ gửi URL thật. Path local được upload SAU khi phiếu có id (xem recordHarvest),
    // nếu gửi path lên BE sẽ bị lưu thành photoUrls rác.
    final photoUrls = model.photoUrls
        .map((u) => u.trim())
        .where((u) => u.startsWith('http://') || u.startsWith('https://'))
        .toList(growable: false);
    return {
      'harvestDate': model.harvestDate.toUtc().toIso8601String(),
      'status': 'Completed',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (guid.hasMatch(farmId)) 'farmingAreaId': farmId,
      if (model.operatorName.trim().isNotEmpty)
        'performedByName': model.operatorName.trim(),
      if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      'lines': [
        {
          if (guid.hasMatch(crabId)) 'crabId': crabId,
          'weightGram': model.totalWeight * 1000,
          'grade': grade,
          'isSoftshell': model.qualityGrade == QualityGrade.gradeC,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        },
      ],
    };
  }

  List<dynamic> _extractList(Map<String, dynamic>? body, String operationName) {
    if (body == null) return [];

    if (body.containsKey('data') && body['data'] is List<dynamic>) {
      return body['data'] as List<dynamic>;
    }

    if (body.containsKey('items') && body['items'] is List<dynamic>) {
      return body['items'] as List<dynamic>;
    }

    logger.w('HarvestRemote: unexpected response shape in $operationName');
    return [];
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body;
  }
}
