// ignore_for_file: lines_longer_than_80_chars

import '../../../../core/network/api_client.dart';
import '../models/crab_management_models.dart';

abstract class CrabManagementRemoteDataSource {
  Future<CrabPage> getCrabs({
    required int page,
    required int pageSize,
    CrabFilterState? filter,
  });

  Future<CrabKpiSummary> getKpiSummary({String? farmAreaId});

  Future<List<FarmAreaOption>> getFarmAreas();
  Future<List<RowOption>> getRows({String? farmAreaId});
  Future<List<BoxOption>> getBoxes({String? rowId});
  Future<List<BatchOption>> getBatches();

  Future<CrabRecord> getCrabById(String id);

  Future<void> markMolting({
    required String crabId,
    required DateTime detectedAt,
    String? note,
  });

  Future<void> markReadyToHarvest(String crabId);

  Future<void> markDead({
    required String crabId,
    required DateTime detectedAt,
    required DeathReason reason,
    String? note,
  });

  Future<void> transferCrab({
    required String crabId,
    required String toBoxId,
    String? note,
  });

  Future<CrabRecord> createCrab(Map<String, dynamic> data);
}

class CrabManagementRemoteDataSourceImpl
    implements CrabManagementRemoteDataSource {
  CrabManagementRemoteDataSourceImpl({required ApiClient apiClient})
    : _api = apiClient;

  final ApiClient _api;

  @override
  Future<CrabPage> getCrabs({
    required int page,
    required int pageSize,
    CrabFilterState? filter,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (filter != null) {
      if (filter.searchQuery.isNotEmpty) params['search'] = filter.searchQuery;
      if (filter.farmAreaId != null) params['farmAreaId'] = filter.farmAreaId;
      if (filter.rowId != null) params['rowId'] = filter.rowId;
      if (filter.boxId != null) params['boxId'] = filter.boxId;
      if (filter.batchId != null) params['batchId'] = filter.batchId;
      if (filter.gender != null) {
        params['gender'] = filter.gender == CrabGender.female
            ? 'FEMALE'
            : 'MALE';
      }
      final ls = filter.quickStatus ?? filter.lifecycleStatus;
      if (ls != null) {
        params['lifecycleStatus'] = _lifecycleToParam(ls);
      }
      if (filter.healthStatus != null) {
        params['healthStatus'] = _healthToParam(filter.healthStatus!);
      }
    }
    final result = await _api.safeGet<dynamic>(
      '/crabs',
      queryParameters: params,
    );
    if (result.failure != null) throw result.failure!;
    final data = result.data.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data;
      return CrabPage.fromJson(inner as Map<String, dynamic>, page, pageSize);
    }
    return CrabPage.empty(pageSize);
  }

  @override
  Future<CrabKpiSummary> getKpiSummary({String? farmAreaId}) async {
    final params = <String, dynamic>{};
    if (farmAreaId != null) params['farmAreaId'] = farmAreaId;
    final result = await _api.safeGet<dynamic>(
      '/crabs/summary',
      queryParameters: params.isNotEmpty ? params : null,
    );
    if (result.failure != null) throw result.failure!;
    final data = result.data.data;
    if (data is Map<String, dynamic>) {
      final inner = (data['data'] ?? data) as Map<String, dynamic>;
      return CrabKpiSummary.fromJson(inner);
    }
    return CrabKpiSummary.empty;
  }

  @override
  Future<List<FarmAreaOption>> getFarmAreas() async {
    final result = await _api.safeGet<dynamic>('/farming-areas');
    if (result.failure != null) return [];
    return _extractList(
      result.data.data,
    ).map((e) => FarmAreaOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<RowOption>> getRows({String? farmAreaId}) async {
    final params = farmAreaId != null
        ? <String, dynamic>{'farmingAreaId': farmAreaId}
        : null;
    final result = await _api.safeGet<dynamic>(
      '/farming-rows',
      queryParameters: params,
    );
    if (result.failure != null) return [];
    return _extractList(
      result.data.data,
    ).map((e) => RowOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<BoxOption>> getBoxes({String? rowId}) async {
    final params = rowId != null
        ? <String, dynamic>{'farmingRowId': rowId}
        : null;
    final result = await _api.safeGet<dynamic>(
      '/boxes',
      queryParameters: params,
    );
    if (result.failure != null) return [];
    return _extractList(
      result.data.data,
    ).map((e) => BoxOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<BatchOption>> getBatches() async {
    final result = await _api.safeGet<dynamic>('/crab-lots');
    if (result.failure != null) return [];
    return _extractList(
      result.data.data,
    ).map((e) => BatchOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CrabRecord> getCrabById(String id) async {
    final result = await _api.safeGet<dynamic>('/crabs/$id');
    if (result.failure != null) throw result.failure!;
    final data = result.data.data;
    final json = data is Map<String, dynamic>
        ? (data['data'] ?? data) as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return CrabRecord.fromJson(json);
  }

  @override
  Future<void> markMolting({
    required String crabId,
    required DateTime detectedAt,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'detectedAt': detectedAt.toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final result = await _api.safePost<dynamic>(
      '/crabs/$crabId/moltings',
      data: body,
    );
    if (result.failure != null) throw result.failure!;
  }

  @override
  Future<void> markReadyToHarvest(String crabId) async {
    final result = await _api.safePatch<dynamic>(
      '/crabs/$crabId',
      data: {'lifecycleStatus': 'READY_TO_HARVEST'},
    );
    if (result.failure != null) throw result.failure!;
  }

  @override
  Future<void> markDead({
    required String crabId,
    required DateTime detectedAt,
    required DeathReason reason,
    String? note,
  }) async {
    final reasonStr = switch (reason) {
      DeathReason.unknown => 'UNKNOWN',
      DeathReason.disease => 'DISEASE',
      DeathReason.environmentalShock => 'ENVIRONMENTAL_SHOCK',
      DeathReason.moltFailure => 'MOLT_FAILURE',
      DeathReason.injury => 'INJURY',
      DeathReason.other => 'OTHER',
    };
    final body = <String, dynamic>{
      'lifecycleStatus': 'DEAD',
      'deathReason': reasonStr,
      'detectedAt': detectedAt.toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final result = await _api.safePatch<dynamic>('/crabs/$crabId', data: body);
    if (result.failure != null) throw result.failure!;
  }

  @override
  Future<void> transferCrab({
    required String crabId,
    required String toBoxId,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'crabId': crabId,
      'toBoxId': toBoxId,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final result = await _api.safePost<dynamic>(
      '/allocations/transfer',
      data: body,
    );
    if (result.failure != null) throw result.failure!;
  }

  @override
  Future<CrabRecord> createCrab(Map<String, dynamic> data) async {
    final result = await _api.safePost<dynamic>('/crabs', data: data);
    if (result.failure != null) throw result.failure!;
    final json = result.data.data;
    final map = json is Map<String, dynamic>
        ? (json['data'] ?? json) as Map<String, dynamic>
        : json as Map<String, dynamic>;
    return CrabRecord.fromJson(map);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map)
        return inner['items'] as List? ?? inner['data'] as List? ?? [];
      if (inner is List) return inner;
      return data['items'] as List? ?? data['data'] as List? ?? [];
    }
    return [];
  }

  String _lifecycleToParam(CrabLifecycleStatus s) => switch (s) {
    CrabLifecycleStatus.growing => 'GROWING',
    CrabLifecycleStatus.molting => 'MOLTING',
    CrabLifecycleStatus.readyToHarvest => 'READY_TO_HARVEST',
    CrabLifecycleStatus.harvested => 'HARVESTED',
    CrabLifecycleStatus.dead => 'DEAD',
    CrabLifecycleStatus.unknown => 'UNKNOWN',
  };

  String _healthToParam(CrabHealthStatus s) => switch (s) {
    CrabHealthStatus.healthy => 'HEALTHY',
    CrabHealthStatus.monitoring => 'MONITORING',
    CrabHealthStatus.weak => 'WEAK',
    CrabHealthStatus.alert => 'ALERT',
    CrabHealthStatus.unknown => 'UNKNOWN',
  };
}
