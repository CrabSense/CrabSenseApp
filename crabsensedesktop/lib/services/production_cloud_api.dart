part of 'cloud_api_client.dart';

/// CRUD phân cấp Khu → Dãy → Hộp → Đợt → Cua (domain Cloud).
extension ProductionCloudApi on CloudApiClient {
  Future<String> fetchNextAreaCode(String token, String farmId) async {
    final areas = await fetchAreas(token, farmId);
    return 'Khu-${areas.length + 1}';
  }

  Future<String> fetchNextRowCode(String token, String areaId) async {
    final rows = await fetchRows(token, areaId);
    return 'Day-${rows.length + 1}';
  }

  Future<String> fetchNextBoxCode(String token, String rowId) async {
    final boxes = await fetchBoxes(token, rowId);
    return 'BOX-${(boxes.length + 1).toString().padLeft(4, '0')}';
  }

  Future<String> fetchNextBatchCode(String token, String boxId) async {
    return 'LOT-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  Future<String> fetchNextBatchCrabCode(String token, String batchId) async {
    return 'CRAB-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  Future<List<AreaRecord>> fetchAreas(String token, String farmId) async {
    final result = await fetchAreasWithSummary(token, farmId);
    return result.areas;
  }

  Future<({List<AreaRecord> areas, AreaSummaryStats summary})>
      fetchAreasWithSummary(String token, String farmId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas');
    final res = await _client.get(uri, headers: authHeaders(token));
    final map = _decode(res);
    _ensureOk(res);
    final items = _itemsOf(map);
    var areas = items
        .whereType<Map>()
        .map((e) => AreaRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (farmId.isNotEmpty) {
      final scoped = areas.where((a) => a.id == farmId).toList();
      if (scoped.isNotEmpty) areas = scoped;
    }
    final active = areas.where((a) => a.status == 'active').length;
    final disabled = areas.where((a) => a.status == 'disabled').length;
    final summary = AreaSummaryStats(
      total: areas.length,
      active: active,
      maintenance: areas.length - active - disabled,
      disabled: disabled,
      totalBoxes: areas.fold<int>(0, (s, a) => s + a.boxCount),
    );
    return (areas: areas, summary: summary);
  }

  Future<({AreaRecord detail, List<RowRecord> rows, List<BoxRecord> boxes})>
      fetchAreaDetail(String token, String areaId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas/$areaId');
    final res = await _client.get(uri, headers: authHeaders(token));
    final map = _decode(res);
    _ensureOk(res);
    final data = _asMap(_dataOf(map) ?? map);
    final detail = AreaRecord.fromJson(data);
    final rows = await fetchRows(token, areaId);
    final boxes = <BoxRecord>[];
    for (final row in rows) {
      boxes.addAll(await fetchBoxes(token, row.id));
    }
    return (detail: detail, rows: rows, boxes: boxes);
  }

  Future<AreaRecord> createArea(
    String token,
    String farmId, {
    required String areaName,
    String? areaCode,
    String? description,
    String status = 'active',
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': areaName,
        if (description != null) 'description': description,
      }),
    );
    return _parseSingle(res, 'area', AreaRecord.fromJson);
  }

  Future<AreaRecord> updateArea(
    String token,
    String areaId, {
    required String areaCode,
    required String areaName,
    String? description,
    String? status,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas/$areaId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': areaName,
        'description': description,
        'isActive': status == null || status.toLowerCase() != 'disabled',
      }),
    );
    return _parseSingle(res, 'area', AreaRecord.fromJson);
  }

  Future<void> deleteArea(String token, String areaId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas/$areaId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<RowRecord>> fetchRows(String token, String areaId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas/$areaId/rows');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'rows', RowRecord.fromJson);
  }

  Future<RowRecord> createRow(
    String token,
    String areaId, {
    required String rowName,
    String? rowCode,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas/$areaId/rows');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'farmingAreaId': areaId,
        'name': rowName,
        'capacity': 0,
      }),
    );
    return _parseSingle(res, 'row', RowRecord.fromJson);
  }

  Future<RowRecord> updateRow(
    String token,
    String rowId, {
    required String rowCode,
    required String rowName,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-rows/$rowId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'name': rowName, 'capacity': 0, 'isActive': true}),
    );
    return _parseSingle(res, 'row', RowRecord.fromJson);
  }

  Future<void> deleteRow(String token, String rowId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-rows/$rowId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<BoxRecord>> fetchBoxes(String token, String rowId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-rows/$rowId/boxes');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'boxes', BoxRecord.fromJson);
  }

  Future<BoxRecord> createBox(
    String token,
    String rowId, {
    String? boxCode,
    String? position,
    double? volume,
    String status = 'empty',
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-rows/$rowId/boxes');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'farmingRowId': rowId,
        if (boxCode != null && boxCode.isNotEmpty) 'code': boxCode,
      }),
    );
    return _parseSingle(res, 'box', BoxRecord.fromJson);
  }

  Future<List<BoxRecord>> createBoxesBulk(
    String token,
    String rowId, {
    required int count,
    String? positionPrefix,
    double? volume,
    String status = 'empty',
  }) async {
    final created = <BoxRecord>[];
    for (var i = 0; i < count; i++) {
      created.add(
        await createBox(
          token,
          rowId,
          boxCode: positionPrefix == null || positionPrefix.isEmpty
              ? null
              : '$positionPrefix${i + 1}',
          position: positionPrefix,
          volume: volume,
          status: status,
        ),
      );
    }
    return created;
  }

  Future<BoxRecord> updateBox(
    String token,
    String boxId, {
    required String boxCode,
    String? position,
    double? volume,
    required String status,
  }) async {
    final occupied = status.toLowerCase() != 'empty';
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/boxes/$boxId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': boxCode,
        'status': status,
        'isOccupied': occupied,
      }),
    );
    return _parseSingle(res, 'box', BoxRecord.fromJson);
  }

  Future<void> deleteBox(String token, String boxId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/boxes/$boxId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<FarmingBatchRecord>> fetchCrabLots(String token) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crab-lots');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'items', FarmingBatchRecord.fromJson);
  }

  Future<List<FarmingBatchRecord>> fetchBatches(String token, String boxId) =>
      fetchCrabLots(token);

  Future<List<FarmingBatchRecord>> fetchBatchesByRow(
    String token,
    String rowId,
  ) =>
      fetchCrabLots(token);

  Future<List<FarmingBatchRecord>> createBatchesBulk(
    String token,
    String rowId, {
    required List<String> boxIds,
    required DateTime startDate,
    required DateTime expectedHarvestDate,
    int initialQuantity = 0,
    bool startNow = true,
    String status = 'active',
  }) async {
    final lot = await createBatch(
      token,
      boxIds.isNotEmpty ? boxIds.first : rowId,
      startDate: startDate,
      expectedHarvestDate: expectedHarvestDate,
      initialQuantity: initialQuantity,
      status: status,
      startNow: startNow,
    );
    return [lot];
  }

  Future<FarmingBatchRecord> createBatch(
    String token,
    String boxId, {
    String? batchCode,
    required DateTime startDate,
    DateTime? expectedHarvestDate,
    int initialQuantity = 0,
    int currentQuantity = 0,
    String status = 'active',
    bool startNow = false,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crab-lots');
    final code = (batchCode != null && batchCode.isNotEmpty)
        ? batchCode
        : 'LOT-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'lotCode': code,
        'importDate': startDate.toUtc().toIso8601String(),
        if (expectedHarvestDate != null)
          'notes': 'Dự kiến thu: ${_dateOnly(expectedHarvestDate)}',
      }),
    );
    return _parseSingle(res, 'batch', FarmingBatchRecord.fromJson);
  }

  Future<FarmingBatchRecord> updateBatch(
    String token,
    String batchId, {
    required String batchCode,
    required DateTime startDate,
    DateTime? expectedHarvestDate,
    DateTime? actualHarvestDate,
    required int initialQuantity,
    required int currentQuantity,
    required String status,
    bool startNow = false,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crab-lots/$batchId');
    final notes = [
      if (status.isNotEmpty) 'status=$status',
      if (expectedHarvestDate != null)
        'harvest=${_dateOnly(expectedHarvestDate)}',
      if (actualHarvestDate != null) 'actual=${_dateOnly(actualHarvestDate)}',
    ].join('; ');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'notes': notes.isEmpty ? null : notes,
      }),
    );
    return _parseSingle(res, 'batch', FarmingBatchRecord.fromJson);
  }

  Future<void> deleteBatch(String token, String batchId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crab-lots/$batchId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<BatchCrabRecord>> fetchBatchCrabs(String token, String batchId) async {
    final all = await _fetchAllCrabs(token);
    return all
        .where((c) => c.batchId == batchId)
        .map(
          (c) => BatchCrabRecord(
            id: c.id,
            batchId: c.batchId,
            crabCode: c.crabCode,
            gender: c.gender,
            weight: c.weight,
            shellWidth: c.shellWidth,
            status: c.status,
          ),
        )
        .toList();
  }

  Future<BatchCrabRecord> createBatchCrab(
    String token,
    String batchId, {
    String? crabCode,
    String gender = 'unknown',
    double? weight,
    double? shellWidth,
    String status = 'alive',
    String? boxId,
    String? farmingAreaId,
  }) {
    return createBatchCrabExtended(
      token,
      batchId,
      crabCode: crabCode,
      gender: gender,
      weight: weight,
      shellWidth: shellWidth,
      status: status,
      boxId: boxId,
      farmingAreaId: farmingAreaId,
    );
  }

  Future<BatchCrabRecord> updateBatchCrab(
    String token,
    String crabId, {
    required String crabCode,
    required String gender,
    double? weight,
    double? shellWidth,
    required String status,
  }) {
    return updateBatchCrabExtended(
      token,
      crabId,
      crabCode: crabCode,
      gender: gender,
      weight: weight,
      shellWidth: shellWidth,
      status: status,
    );
  }

  Future<void> deleteBatchCrab(String token, String crabId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<CrabManagementListItem>> _fetchAllCrabs(String token) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs')
        .replace(queryParameters: {'page': '1', 'pageSize': '0'});
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'items', CrabManagementListItem.fromJson);
  }

  Future<({CrabManagementSummaryDto summary, List<CrabManagementListItem> crabs})>
      fetchFarmCrabs(String token, String farmId) async {
    var crabs = await _fetchAllCrabs(token);
    if (farmId.isNotEmpty) {
      final scoped = crabs.where((c) => c.areaId == farmId).toList();
      if (scoped.isNotEmpty) crabs = scoped;
    }
    final lots = await fetchCrabLots(token);
    final lotCodes = {for (final l in lots) l.id: l.batchCode};
    crabs = crabs
        .map(
          (c) => CrabManagementListItem(
            id: c.id,
            batchId: c.batchId,
            batchCode: lotCodes[c.batchId] ?? c.batchCode,
            boxId: c.boxId,
            boxCode: c.boxCode,
            rowId: c.rowId,
            rowCode: c.rowCode,
            rowName: c.rowName,
            areaId: c.areaId,
            areaCode: c.areaCode,
            areaName: c.areaName,
            crabCode: c.crabCode,
            gender: c.gender,
            weight: c.weight,
            shellWidth: c.shellWidth,
            status: c.status,
            moltCount: c.moltCount,
            lastMoltDate: c.lastMoltDate,
            healthStatus: c.healthStatus,
            growthStage: c.growthStage,
            profileNote: c.profileNote,
            batchStartDate: c.batchStartDate,
          ),
        )
        .toList();
    final alive = crabs.where((c) => c.status != 'dead').length;
    final dead = crabs.where((c) => c.status == 'dead').length;
    final molting = crabs.where((c) => c.status == 'molting').length;
    return (
      summary: CrabManagementSummaryDto(
        total: crabs.length,
        alive: alive,
        dead: dead,
        molting: molting,
        readyHarvest: 0,
      ),
      crabs: crabs,
    );
  }

  Future<Map<String, dynamic>> fetchCrabDetail(String token, String crabId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId');
    final res = await _client.get(uri, headers: authHeaders(token));
    _ensureOk(res);
    final body = _decode(res);
    final data = _asMap(_dataOf(body) ?? body);
    List<dynamic> molts = const [];
    try {
      final moltUri =
          Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId/moltings');
      final moltRes = await _client.get(moltUri, headers: authHeaders(token));
      if (moltRes.statusCode >= 200 && moltRes.statusCode < 300) {
        molts = _itemsOf(_decode(moltRes));
      }
    } catch (_) {}
    return {
      ...data,
      'moltLogs': molts
          .whereType<Map>()
          .map((m) {
            final map = Map<String, dynamic>.from(m);
            return {
              'moltDate': map['moltTime'] ?? map['MoltTime'],
              'moltNumber': 0,
              'condition': map['result'] ?? map['Result'] ?? 'normal',
              'note': map['notes'] ?? map['Notes'],
            };
          })
          .toList(),
    };
  }

  Future<void> recordCrabHealth(
    String token,
    String crabId, {
    double? weight,
    double? shellWidth,
    String? shellStatus,
    String? diseaseStatus,
    DateTime? recordedAt,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'weightGram': weight,
        'isAlive': true,
        if (shellStatus != null || diseaseStatus != null)
          'moltingStage': [shellStatus, diseaseStatus]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .join(' — '),
      }),
    );
    _ensureOk(res);
  }

  Future<void> recordCrabMolt(
    String token,
    String crabId, {
    required String moltDate,
    required int moltNumber,
    String condition = 'normal',
    String? note,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId/moltings');
    final at = DateTime.tryParse(moltDate)?.toUtc().toIso8601String();
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'crabId': crabId,
        if (at != null) 'moltTime': at,
        'result': condition,
        'source': 'desktop',
        if (note != null) 'notes': note,
      }),
    );
    _ensureOk(res);
  }

  Future<BatchCrabRecord> updateBatchCrabExtended(
    String token,
    String crabId, {
    required String crabCode,
    required String gender,
    double? weight,
    double? shellWidth,
    required String status,
    String? healthStatus,
    String? growthStage,
    String? profileNote,
    int? moltCount,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'weightGram': weight,
        'isAlive': status.toLowerCase() != 'dead',
        'moltingStage': healthStatus ?? growthStage,
      }),
    );
    return _parseSingle(res, 'crab', BatchCrabRecord.fromJson);
  }

  Future<BatchCrabRecord> createBatchCrabExtended(
    String token,
    String batchId, {
    String? crabCode,
    String gender = 'unknown',
    double? weight,
    double? shellWidth,
    String status = 'alive',
    String? healthStatus,
    String? growthStage,
    String? profileNote,
    String? boxId,
    String? farmingAreaId,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'crabLotId': batchId,
        if (boxId != null && boxId.isNotEmpty) 'boxId': boxId,
        if (farmingAreaId != null && farmingAreaId.isNotEmpty)
          'farmingAreaId': farmingAreaId,
        'autoAssignEmptyBox': boxId == null || boxId.isEmpty,
        if (crabCode != null && crabCode.isNotEmpty) 'tag': crabCode,
        'weightGram': weight,
        'moltingStage': healthStatus ?? growthStage,
      }),
    );
    return _parseSingle(res, 'crab', BatchCrabRecord.fromJson);
  }

  String? _dateOnly(DateTime? dt) {
    if (dt == null) return null;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<T> _parseList<T>(
    http.Response res,
    String listKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || _isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Lỗi API (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final items = _itemsOf(body);
    if (items.isNotEmpty) {
      return items
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final raw = body[listKey];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  T _parseSingle<T>(
    http.Response res,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || _isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Thao tác thất bại (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final data = _dataOf(body);
    final raw = data is Map ? data : body[key];
    if (raw is! Map) throw CloudApiException('Phản hồi thiếu $key');
    return fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<WaterTrendPoint>> fetchAreaSensorTrend(
    String token,
    String areaId, {
    int minutes = 30,
  }) async {
    try {
      final live = await fetchIotLive(token, farmingAreaId: areaId);
      if (live.isEmpty) return [];
      final data = AreaSensorLatestData.fromIotLive(areaId: areaId, live: live);
      final now = DateTime.now();
      double v(String key) {
        for (final m in data.metrics) {
          final t = (m.sensorType ?? '').toLowerCase();
          if (t.contains(key)) return m.value;
        }
        return 0;
      }

      return [
        WaterTrendPoint(
          xMinutes: 0,
          label:
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          timestamp: now,
          ph: v('ph') == 0 ? 7.8 : v('ph'),
          temperature: v('temp') == 0 ? 28 : v('temp'),
          tds: v('tds') == 0 ? 400 : v('tds'),
          flow: v('flow') == 0 ? 1 : v('flow'),
          dissolvedOxygen: () {
            for (final m in data.metrics) {
              final t = (m.sensorType ?? '').toLowerCase();
              if (t == 'do' || t.contains('oxygen') || t.contains('oxy')) {
                return m.value;
              }
            }
            return null;
          }(),
        ),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<AreaSensorLatestData?> fetchAreaSensorLatest(
    String token,
    String areaId,
  ) async {
    try {
      final live = await fetchIotLive(token, farmingAreaId: areaId);
      if (live.isEmpty) return null;
      return AreaSensorLatestData.fromIotLive(areaId: areaId, live: live);
    } catch (_) {
      return null;
    }
  }

  Future<FarmDashboardOverview> fetchFarmDashboardOverview(
    String token,
    String farmId,
  ) async {
    final q = farmId.isEmpty ? null : {'farmingAreaId': farmId};
    var overviewUri = Uri.parse('${AppEnv.cloudApiUrl}/api/dashboard/overview');
    var metricsUri = Uri.parse('${AppEnv.cloudApiUrl}/api/dashboard/metrics');
    if (q != null) {
      overviewUri = overviewUri.replace(queryParameters: q);
      metricsUri = metricsUri.replace(queryParameters: q);
    }
    final headers = authHeaders(token, farmId: farmId.isEmpty ? null : farmId);
    final overviewRes = await _client.get(overviewUri, headers: headers);
    final metricsRes = await _client.get(metricsUri, headers: headers);
    _ensureOk(overviewRes);
    final overviewBody = _decode(overviewRes);
    final overview = _asMap(_dataOf(overviewBody) ?? overviewBody);

    var healthScore = 0;
    var waterQualityScore = 0;
    var crabHealthScore = 0;
    var deviceStatusScore = 0;
    var statusLabel = '';
    var statusMessage = '';
    if (metricsRes.statusCode >= 200 && metricsRes.statusCode < 300) {
      final metricsBody = _decode(metricsRes);
      if (!_isApiFailure(metricsRes, metricsBody)) {
        final metrics = _asMap(_dataOf(metricsBody) ?? metricsBody);
        healthScore = (metrics['score'] as num?)?.toInt() ?? 0;
        waterQualityScore = (metrics['waterQualityScore'] as num?)?.toInt() ?? 0;
        crabHealthScore = (metrics['crabHealthScore'] as num?)?.toInt() ?? 0;
        deviceStatusScore = (metrics['deviceStatusScore'] as num?)?.toInt() ?? 0;
        statusLabel = (metrics['statusLabel'] ?? '').toString();
        statusMessage = (metrics['explanation'] ?? '').toString();
      }
    }

    if (overview.containsKey('summaryKpis') || overview.containsKey('healthScore')) {
      return FarmDashboardOverview.fromJson(overview);
    }

    List<Map<String, dynamic>> live = const [];
    List<Map<String, dynamic>> alerts = const [];
    try {
      live = await fetchIotLive(token, farmingAreaId: farmId);
    } catch (_) {}
    try {
      alerts = await fetchAlerts(token, farmingAreaId: farmId);
    } catch (_) {}

    return FarmDashboardOverview.fromCrabSense(
      totalBoxes: (overview['totalBoxes'] as num?)?.toInt() ?? 0,
      totalCrabs: (overview['totalCrabs'] as num?)?.toInt() ?? 0,
      activeBoxes: (overview['activeBoxes'] as num?)?.toInt() ?? 0,
      openAlerts: (overview['openAlerts'] as num?)?.toInt() ?? alerts.length,
      iotOnlinePercentage:
          (overview['iotOnlinePercentage'] as num?)?.toDouble() ?? 0,
      healthScore: healthScore,
      waterQualityScore: waterQualityScore,
      crabHealthScore: crabHealthScore,
      deviceStatusScore: deviceStatusScore,
      statusLabel: statusLabel,
      statusMessage: statusMessage,
      primaryAreaId: farmId.isEmpty ? null : farmId,
      environmentParams: FarmDashboardOverview.envFromLive(live),
      alerts: FarmDashboardOverview.alertsFromApi(alerts),
    );
  }

  Future<FeedManagementOverview> fetchFeedManagementOverview(
    String token,
    String farmId, {
    required int year,
    required int month,
    required int day,
  }) async {
    throw CloudApiException(
      'CrabSenseBE không có module thức ăn. Ghi cho ăn trong Nhật ký nuôi.',
    );
  }

  Future<void> completeFeedSchedule(
    String token,
    String farmId,
    String scheduleId,
  ) async {
    throw CloudApiException('CrabSenseBE không có lịch thức ăn.');
  }

  Future<void> createFeedSchedule(
    String token,
    String farmId, {
    required String batchId,
    required String date,
    required String time,
    required String feedName,
    required double portionKg,
    String repeatRule = 'Hàng ngày',
  }) async {
    throw CloudApiException('CrabSenseBE không có lịch thức ăn.');
  }

  Future<void> importFeedStock(
    String token,
    String farmId, {
    required String code,
    required double kg,
  }) async {
    throw CloudApiException('CrabSenseBE không có kho thức ăn.');
  }

  Future<void> exportFeedStock(
    String token,
    String farmId, {
    required String code,
    required double kg,
  }) async {
    throw CloudApiException('CrabSenseBE không có kho thức ăn.');
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode == 204) return;
    final body = _decode(res);
    if (res.statusCode < 200 || res.statusCode >= 300 || _isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Xóa thất bại (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
  }

}
