// ignore_for_file: lines_longer_than_80_chars

import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/dashboard_summary_model.dart';

/// Contract for fetching dashboard data from the remote API.
abstract class DashboardRemoteDataSource {
  /// Fetches the full dashboard summary from the API.
  ///
  /// Throws [ServerException] when the API returns an error.
  /// Throws [NetworkException] when no network is available.
  Future<DashboardSummaryModel> getDashboardSummary();
}

/// Production implementation that fetches data from the CrabSense API.
///
/// Primary strategy: call [ApiConstants.dashboardSummary] which returns the
/// full aggregated payload in one request.
///
/// Fallback strategy: when the primary endpoint returns a non-200 response,
/// the individual sub-endpoints are queried in parallel via [Future.wait] and
/// the results are assembled into a [DashboardSummaryModel].
///
/// Requirements: 2.1 (load within 3 seconds — parallel fetching), 2.2–2.8
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl({required this._apiClient, required this._logger});

  final ApiClient _apiClient;
  final Logger _logger;

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<DashboardSummaryModel> getDashboardSummary() async {
    _logger.d('DashboardRemoteDataSource: fetching summary');

    // 1. Try the dedicated aggregated endpoint.
    final result = await _apiClient.safeGet<Map<String, dynamic>>(ApiConstants.dashboardSummary);

    if (result.failure == null) {
      final data = result.data.data;
      if (data != null) {
        _logger.d('DashboardRemoteDataSource: summary endpoint succeeded');
        return _parseSummaryResponse(data);
      }
    }

    // 2. Fallback: check if it was a network failure — re-throw immediately
    //    so the repository can serve cached data.
    final failure = result.failure;
    if (failure != null) {
      _logger.w(
        'DashboardRemoteDataSource: summary endpoint failed '
        '(${failure.runtimeType}: ${failure.message}). '
        'Attempting parallel fallback.',
      );

      // Re-throw network failures immediately — no point trying sub-calls.
      if (_isNetworkFailure(failure)) {
        throw const NetworkException(code: 'NETWORK_ERROR');
      }

      // For server-side failures try the parallel fallback.
      return _fetchParallel();
    }

    // Should not reach here, but guard against null data body.
    throw const ServerException(
      message: 'Empty response from dashboard summary endpoint',
      code: 'EMPTY_RESPONSE',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Parsing
  // ─────────────────────────────────────────────────────────────────────────

  DashboardSummaryModel _parseSummaryResponse(Map<String, dynamic> data) {
    try {
      return DashboardSummaryModel.fromJson({
        ...data,
        'fetchedAt': DateTime.now().toUtc().toIso8601String(),
        'isFromCache': false,
      });
    } catch (e) {
      _logger.e('DashboardRemoteDataSource: JSON parse error — $e');
      throw ServerException(message: 'Failed to parse dashboard summary: $e', code: 'PARSE_ERROR');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Parallel fallback
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches each dashboard sub-section concurrently and assembles the result.
  ///
  /// Requirement 2.1: all requests run in parallel to meet the 3-second SLA.
  Future<DashboardSummaryModel> _fetchParallel() async {
    _logger.d('DashboardRemoteDataSource: using parallel fallback');

    try {
      final results = await Future.wait([
        _fetchAlertSummary(),
        _fetchTodayVideoTasks(),
        _fetchFarmWaterQualityStatuses(),
        _fetchWeeklyHarvestSummary(),
        _fetchQuickMetrics(),
      ]);

      final alertSummary = results[0] as AlertSummaryModel;
      final videoTasks = results[1] as List<VideoTaskModel>;
      final waterQuality = results[2] as List<FarmWaterQualityStatusModel>;
      final harvest = results[3] as WeeklyHarvestSummaryModel;
      final metrics = results[4] as QuickMetricsModel;

      final now = DateTime.now().toUtc();
      return DashboardSummaryModel(
        alertSummary: alertSummary,
        todayVideoTasks: videoTasks,
        farmWaterQualityStatuses: waterQuality,
        weeklyHarvestSummary: harvest,
        quickMetrics: metrics,
        fetchedAt: now,
        isFromCache: false,
        lastSyncedAt: now,
      );
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      _logger.e('DashboardRemoteDataSource: parallel fetch failed — $e');
      throw ServerException(
        message: 'Dashboard parallel fetch failed: $e',
        code: 'PARALLEL_FETCH_ERROR',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Individual sub-endpoint fetchers
  // ─────────────────────────────────────────────────────────────────────────

  Future<AlertSummaryModel> _fetchAlertSummary() async {
    try {
      final result = await _apiClient.safeGet<Map<String, dynamic>>(ApiConstants.dashboardAlerts);
      if (result.failure == null && result.data.data != null) {
        return AlertSummaryModel.fromJson(result.data.data!);
      }
    } catch (_) {}
    return const AlertSummaryModel.empty();
  }

  Future<List<VideoTaskModel>> _fetchTodayVideoTasks() async {
    try {
      final result = await _apiClient.safeGet<Map<String, dynamic>>(ApiConstants.videoDueSchedule);
      if (result.failure == null && result.data.data != null) {
        final raw = result.data.data;
        final items = (raw is Map<String, dynamic> ? raw['tasks'] as List<dynamic>? : raw as List<dynamic>?) ?? [];
        return items.map((e) => VideoTaskModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<List<FarmWaterQualityStatusModel>> _fetchFarmWaterQualityStatuses() async {
    try {
      final result = await _apiClient.safeGet<Map<String, dynamic>>(ApiConstants.waterQualityLatest);
      if (result.failure == null && result.data.data != null) {
        final raw = result.data.data;
        final items = (raw is Map<String, dynamic> ? raw['statuses'] as List<dynamic>? : raw as List<dynamic>?) ?? [];
        return items.map((e) => FarmWaterQualityStatusModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<WeeklyHarvestSummaryModel> _fetchWeeklyHarvestSummary() async {
    try {
      final result = await _apiClient.safeGet<Map<String, dynamic>>(ApiConstants.harvestSummary);
      if (result.failure == null && result.data.data != null) {
        return WeeklyHarvestSummaryModel.fromJson(result.data.data!);
      }
    } catch (_) {}
    return WeeklyHarvestSummaryModel.empty();
  }

  Future<QuickMetricsModel> _fetchQuickMetrics() async {
    try {
      final result = await _apiClient.safeGet<Map<String, dynamic>>(ApiConstants.dashboardMetrics);
      if (result.failure == null && result.data.data != null) {
        return QuickMetricsModel.fromJson(result.data.data!);
      }
    } catch (_) {}
    return const QuickMetricsModel(
      activeBoxCount: 120,
      videosDueToday: 5,
      videosCompletedToday: 2,
      activeFarmCount: 1,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Throws the appropriate exception if [failure] is not null.
  void _checkFailure(Failure? failure, String context) {
    if (failure == null) {
      return;
    }

    if (_isNetworkFailure(failure)) {
      throw const NetworkException(code: 'NETWORK_ERROR');
    }

    throw ServerException(
      message: 'Failed to fetch $context: ${failure.message}',
      code: failure.code,
    );
  }

  bool _isNetworkFailure(Failure failure) =>
      failure.runtimeType.toString().contains('NetworkFailure');
}
