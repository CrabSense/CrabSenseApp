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
    String outcome = 'success',
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
    required String sourceBoxId,
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
    final crabs = await _getScopedCrabs(filter?.farmAreaId);
    final filtered = crabs.where((crab) {
      if (filter == null) return true;
      final query = filter.searchQuery.trim().toLowerCase();
      final status = filter.quickStatus ?? filter.lifecycleStatus;
      return (query.isEmpty || [crab.id, crab.code, crab.location.boxCode, crab.batch.name ?? '']
              .any((value) => value.toLowerCase().contains(query))) &&
          (filter.rowId == null || crab.location.rowId == filter.rowId) &&
          (filter.boxId == null || crab.location.boxId == filter.boxId) &&
          (filter.batchId == null || crab.batch.id == filter.batchId) &&
          (filter.gender == null || crab.gender == filter.gender) &&
          (!filter.quickHealthWatch || crab.needsHealthWatch) &&
          (status == null || crab.lifecycleStatus == status) &&
          (filter.healthStatus == null || crab.healthStatus == filter.healthStatus);
    }).toList();
    final offset = pageSize > 0 && page > 0 ? (page - 1) * pageSize : 0;
    return CrabPage(
      items: pageSize > 0 ? filtered.skip(offset).take(pageSize).toList() : filtered,
      total: filtered.length, page: page, pageSize: pageSize,
    );
  }

  Future<List<CrabRecord>> _getScopedCrabs(String? areaId) async {
    final result = await _api.safeGet<dynamic>(
      '/crabs',
      queryParameters: <String, dynamic>{
        'pageSize': 0,
        if (areaId != null && areaId.isNotEmpty) 'farmingAreaId': areaId,
      },
    );
    if (result.failure != null) throw result.failure!;
    return _extractList(result.data.data)
        .map((e) => CrabRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<CrabKpiSummary> getKpiSummary({String? farmAreaId}) async =>
      CrabKpiSummary.fromList(await _getScopedCrabs(farmAreaId));

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
    String outcome = 'success',
    String? note,
  }) async {
    final body = <String, dynamic>{
      'crabId': crabId,
      'moltTime': detectedAt.toUtc().toIso8601String(),
      if (outcome == 'success' || outcome == 'failed')
        'completedAt': detectedAt.toUtc().toIso8601String(),
      'result': outcome,
      if (note != null && note.trim().isNotEmpty) 'notes': note.trim(),
    };
    final result = await _api.safePost<dynamic>(
      '/crabs/$crabId/moltings',
      data: body,
    );
    if (result.failure != null) throw result.failure!;
  }

  @override
  Future<void> markReadyToHarvest(String crabId) async {
    // Readiness is not a writable BE lifecycle state. Use the harvest
    // assignment workflow after a verified molt, never a generic status patch.
    throw Exception('Dùng công việc thu hoạch sau khi xác nhận cua đã lột.');
  }

  @override
  Future<void> markDead({
    required String crabId,
    required DateTime detectedAt,
    required DeathReason reason,
    String? note,
  }) async {
    final result = await _api.safePost<dynamic>(
      '/mortality',
      data: mortalityPayload(crabId, detectedAt, reason, note),
    );
    if (result.failure != null) throw result.failure!;
  }

  @override
  Future<void> transferCrab({
    required String crabId,
    required String toBoxId,
    required String sourceBoxId,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'crabId': crabId,
      'destinationBoxId': toBoxId,
      'sourceBoxId': sourceBoxId,
      if (note != null && note.trim().isNotEmpty) 'notes': note.trim(),
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

  // BE MortalityCause is a canonical enum; preserve unsupported UI causes
  // in notes instead of assigning a medically different cause.
  static Map<String, dynamic> mortalityPayload(
    String crabId, DateTime detectedAt, DeathReason reason, String? note,
  ) {
    final cause = switch (reason) {
      DeathReason.unknown => 0,
      DeathReason.disease => 1,
      _ => 7,
    };
    final detail = [
      if (cause == 7 && reason != DeathReason.other) reason.label,
      if (note != null && note.trim().isNotEmpty) note.trim(),
    ].join(' — ');
    return {
      'crabId': crabId,
      'mortalityDate': detectedAt.toUtc().toIso8601String(),
      'cause': cause,
      if (detail.isNotEmpty) 'notes': detail,
    };
  }
}
