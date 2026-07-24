// ignore_for_file: lines_longer_than_80_chars

import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/sale.dart';
import '../models/sale_model.dart';

/// Contract for fetching and mutating sales data on the remote API.
///
/// All methods throw typed exceptions on failure:
/// - [ServerException]: 4xx / 5xx API responses.
/// - [NetworkException]: No connectivity or request timeout.
/// - [ParseException]: Malformed or unexpected JSON response body.
///
/// Requirements: 12.1-12.10
abstract class SalesRemoteDataSource {
  /// Submits a new sales transaction record to the remote server.
  ///
  /// Requirements: 12.1-12.8
  Future<SaleModel> createSale(SaleModel model);

  /// Fetches a paginated, filterable sales history list.
  ///
  /// Requirements: 12.10
  Future<List<SaleModel>> getSalesHistory({
    String? farmId,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int page = 1,
    int limit = 50,
  });

  /// Fetches aggregated sales metrics for a farm within a date range.
  ///
  /// Requirements: 12.10
  Future<SalesSummaryModel> getSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? farmId,
  });

  /// Fetches a single sales transaction by ID.
  Future<SaleModel> getSaleById(String id);

  /// Fetches available harvested inventory (in kg) from the server.
  ///
  /// Requirements: 12.4
  Future<double> getAvailableHarvestedInventory({String? farmId});
}

/// Dio-backed implementation of [SalesRemoteDataSource].
class SalesRemoteDataSourceImpl implements SalesRemoteDataSource {
  SalesRemoteDataSourceImpl({
    required this.apiClient,
    required this.logger,
  });

  final ApiClient apiClient;
  final Logger logger;

  @override
  Future<SaleModel> createSale(SaleModel model) async {
    logger.d('SalesRemote: createSale buyer=${model.buyerName} quantity=${model.quantity} total=${model.totalAmount}');

    final result = await apiClient.safePost<Map<String, dynamic>>(
      ApiConstants.createSale,
      data: model.toJson(),
    );

    _checkFailure(result.failure, 'create sale');

    final body = result.data.data;
    if (body == null) {
      throw const ServerException(
        message: 'Empty response from create sale endpoint',
        code: 'PARSE_ERROR',
      );
    }

    return SaleModel.fromJson(_unwrapData(body));
  }

  @override
  Future<List<SaleModel>> getSalesHistory({
    String? farmId,
    String? buyerName,
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int page = 1,
    int limit = 50,
  }) async {
    logger.d('SalesRemote: getSalesHistory farmId=$farmId buyerName=$buyerName page=$page limit=$limit');

    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (farmId != null && farmId.isNotEmpty) {
      queryParams['farmId'] = farmId;
    }
    if (buyerName != null && buyerName.isNotEmpty) {
      queryParams['buyerName'] = buyerName;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (paymentMethod != null) {
      queryParams['paymentMethod'] = paymentMethod.toCode();
    }
    if (paymentStatus != null) {
      queryParams['paymentStatus'] = paymentStatus.toCode();
    }

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.salesHistory,
      queryParameters: queryParams,
    );

    _checkFailure(result.failure, 'sales history');

    final items = _extractList(result.data.data, 'getSalesHistory');
    return items
        .map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<SalesSummaryModel> getSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? farmId,
  }) async {
    logger.d('SalesRemote: getSalesSummary farmId=$farmId period=$startDate - $endDate');

    final queryParams = <String, dynamic>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
    if (farmId != null && farmId.isNotEmpty) {
      queryParams['farmId'] = farmId;
    }

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.salesSummary,
      queryParameters: queryParams,
    );

    _checkFailure(result.failure, 'sales summary');

    final body = result.data.data;
    if (body == null) {
      throw const ServerException(
        message: 'Empty response from sales summary endpoint',
        code: 'PARSE_ERROR',
      );
    }

    return SalesSummaryModel.fromJson(_unwrapData(body));
  }

  @override
  Future<SaleModel> getSaleById(String id) async {
    logger.d('SalesRemote: getSaleById id=$id');

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      ApiConstants.saleDetails(id),
    );

    _checkFailure(result.failure, 'sale details for id $id');

    final body = result.data.data;
    if (body == null) {
      throw ServerException(
        message: 'Empty response from sale details endpoint for id=$id',
        code: 'PARSE_ERROR',
      );
    }

    return SaleModel.fromJson(_unwrapData(body));
  }

  @override
  Future<double> getAvailableHarvestedInventory({String? farmId}) async {
    logger.d('SalesRemote: getAvailableHarvestedInventory farmId=$farmId');

    final queryParams = <String, dynamic>{};
    if (farmId != null && farmId.isNotEmpty) {
      queryParams['farmId'] = farmId;
    }

    final result = await apiClient.safeGet<Map<String, dynamic>>(
      '${ApiConstants.sales}/inventory',
      queryParameters: queryParams,
    );

    _checkFailure(result.failure, 'harvested inventory');

    final body = result.data.data;
    if (body != null) {
      final unwrapped = _unwrapData(body);
      if (unwrapped.containsKey('availableInventory')) {
        return (unwrapped['availableInventory'] as num).toDouble();
      }
      if (unwrapped.containsKey('available_inventory')) {
        return (unwrapped['available_inventory'] as num).toDouble();
      }
      if (unwrapped.containsKey('totalWeight')) {
        return (unwrapped['totalWeight'] as num).toDouble();
      }
    }

    return 0.0;
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

    throw ServerException(
      message: 'Failed to fetch $context: ${failure.message}',
      code: failure.code,
    );
  }

  List<dynamic> _extractList(Map<String, dynamic>? body, String operationName) {
    if (body == null) return [];

    if (body.containsKey('data') && body['data'] is List<dynamic>) {
      return body['data'] as List<dynamic>;
    }

    if (body.containsKey('items') && body['items'] is List<dynamic>) {
      return body['items'] as List<dynamic>;
    }

    logger.w('SalesRemote: unexpected response shape in $operationName');
    return [];
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body;
  }
}
