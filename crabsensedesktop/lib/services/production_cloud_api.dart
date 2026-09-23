part of 'cloud_api_client.dart';

/// CRUD phân cấp Khu → Dãy → Hộp → Đợt → Cua (domain Cloud).
extension ProductionCloudApi on CloudApiClient {
  Future<String> fetchNextAreaCode(String token, String farmId) async {
    final areas = await fetchAreas(token, farmId);
    return 'Khu-${areas.length + 1}';
  }

  Future<String> fetchNextRowCode(String token, String areaId) async {
    return fetchNextDayCode(token);
  }

  Future<String> fetchNextBoxCode(String token, String rowId) async {
    final boxes = await fetchBoxes(token, rowId);
    return 'BOX-${(boxes.length + 1).toString().padLeft(4, '0')}';
  }

  Future<String> fetchNextBatchCode(String token, String boxId) async {
    return 'LOT-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  Future<({String code, String qrCode})> fetchNextCrabIdentity(String token) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/next-code');
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không lấy được mã cua',
        statusCode: res.statusCode,
      );
    }
    final data = _dataOf(body);
    if (data is Map) {
      final code = (data['code'] ?? data['Code'])?.toString() ?? '';
      final qr = (data['qrCode'] ?? data['QrCode'])?.toString() ?? '';
      if (code.isNotEmpty) {
        return (code: code, qrCode: qr.isNotEmpty ? qr : 'QR-$code');
      }
    }
    return (code: 'CRAB-0001', qrCode: 'QR-CRAB-0001');
  }

  Future<String> fetchNextBatchCrabCode(String token, String batchId) async {
    final next = await fetchNextCrabIdentity(token);
    return next.code;
  }

  Future<List<AreaRecord>> fetchAreas(String token, String farmId) async {
    final result = await fetchAreasWithSummary(token, farmId);
    return result.areas;
  }

  Future<({List<AreaRecord> areas, AreaSummaryStats summary})>
      fetchAreasWithSummary(String token, String farmId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas');
    final res = await _client.get(
      uri,
      headers: authHeaders(token, farmId: farmId.isEmpty ? null : farmId),
    );
    final map = _decode(res);
    _ensureOk(res);
    final items = _itemsOf(map);
    final areas = items
        .whereType<Map>()
        .map((e) => AreaRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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
    String? location,
    String? address,
    DateTime? establishedAt,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': areaName,
        if (description != null) 'description': description,
        'status': status.toLowerCase() == 'disabled' || status.toLowerCase() == 'closed'
            ? 'Closed'
            : status.toLowerCase() == 'suspended' || status.toLowerCase() == 'maintenance'
                ? 'Suspended'
                : 'Active',
        if (location != null) 'location': location,
        if (address != null) 'address': address,
        if (establishedAt != null)
          'establishedAt': establishedAt.toUtc().toIso8601String(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
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
    String? location,
    String? address,
    DateTime? establishedAt,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas/$areaId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': areaName,
        'description': description,
        'status': status == null
            ? 'Active'
            : (status.toLowerCase() == 'disabled' || status.toLowerCase() == 'closed')
                ? 'Closed'
                : (status.toLowerCase() == 'suspended' ||
                        status.toLowerCase() == 'maintenance')
                    ? 'Suspended'
                    : 'Active',
        'isActive': status == null ||
            (status.toLowerCase() != 'disabled' && status.toLowerCase() != 'closed'),
        if (location != null) 'location': location,
        if (address != null) 'address': address,
        if (establishedAt != null)
          'establishedAt': establishedAt.toUtc().toIso8601String(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      }),
    );
    return _parseSingle(res, 'area', AreaRecord.fromJson);
  }

  /// Xoá khu. [cascade] = true xoá luôn dãy, hộp và cua bên trong.
  Future<void> deleteArea(String token, String areaId, {bool cascade = false}) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas/$areaId')
        .replace(queryParameters: cascade ? const {'cascade': 'true'} : null);
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<RowRecord>> fetchRows(String token, String areaId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas/$areaId/rows');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'rows', RowRecord.fromJson);
  }

  Future<List<RowRecord>> fetchAllRows(String token, {String? areaId}) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-rows').replace(
      queryParameters: areaId == null || areaId.isEmpty
          ? null
          : {'farmingAreaId': areaId},
    );
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'rows', RowRecord.fromJson);
  }

  Future<String> fetchNextDayCode(String token) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-rows/next-code');
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không lấy được mã dãy',
        statusCode: res.statusCode,
      );
    }
    final data = _dataOf(body);
    if (data is Map) {
      final code = (data['code'] ?? data['Code'])?.toString();
      if (code != null && code.isNotEmpty) return code;
    }
    return 'DAY-A01';
  }

  Future<RowRecord> fetchRowById(String token, String rowId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-rows/$rowId');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseSingle(res, 'row', RowRecord.fromJson);
  }

  Future<RowRecord> createRow(
    String token,
    String areaId, {
    required String rowName,
    String? location,
    int capacity = 0,
    String? description,
    FarmStatus status = FarmStatus.active,
    int sortOrder = 1,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-areas/$areaId/rows');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'farmingAreaId': areaId,
        'name': rowName,
        if (location != null && location.isNotEmpty) 'location': location,
        'capacity': capacity,
        if (description != null && description.isNotEmpty) 'description': description,
        'status': status.apiValue,
        'sortOrder': sortOrder,
      }),
    );
    return _parseSingle(res, 'row', RowRecord.fromJson);
  }

  Future<RowRecord> updateRow(
    String token,
    String rowId, {
    required String rowName,
    String? location,
    int? capacity,
    String? description,
    FarmStatus status = FarmStatus.active,
    int? sortOrder,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-rows/$rowId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': rowName,
        'location': location ?? '',
        if (capacity != null) 'capacity': capacity,
        'description': description ?? '',
        'status': status.apiValue,
        if (sortOrder != null) 'sortOrder': sortOrder,
      }),
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

  Future<List<BoxRecord>> fetchAllBoxes(
    String token, {
    String? areaId,
    String? rowId,
  }) async {
    final q = <String, String>{};
    if (areaId != null && areaId.isNotEmpty) q['farmingAreaId'] = areaId;
    if (rowId != null && rowId.isNotEmpty) q['farmingRowId'] = rowId;
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/boxes').replace(
      queryParameters: q.isEmpty ? null : q,
    );
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
    if (count <= 0) return const [];
    try {
      return await createBoxesQuantity(token, rowId, count);
    } on CloudApiException catch (e) {
      if (e.statusCode == 404) {
        final created = <BoxRecord>[];
        for (var i = 0; i < count; i++) {
          created.add(await createBox(token, rowId));
        }
        return created;
      }
      rethrow;
    }
  }

  Future<List<BoxRecord>> createBoxesQuantity(
    String token,
    String rowId,
    int quantity,
  ) async {
    if (quantity <= 0) return const [];
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-rows/$rowId/boxes/bulk');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'quantity': quantity}),
    );
    if (res.statusCode == 404) {
      final created = <BoxRecord>[];
      for (var i = 0; i < quantity; i++) {
        created.add(await createBox(token, rowId));
      }
      return created;
    }
    return _parseList(res, 'boxes', BoxRecord.fromJson);
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

  Future<FarmingBatchRecord> fetchCrabLot(String token, String lotId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crab-lots/$lotId');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseSingle(res, 'batch', FarmingBatchRecord.fromJson);
  }

  Future<FarmingBatchRecord> updateCrabLot(
    String token,
    String lotId, {
    String? name,
    DateTime? importDate,
    int? quantity,
    String? supplierName,
    String? notes,
    String? status,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crab-lots/$lotId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (name != null) 'name': name,
        if (importDate != null) 'importDate': importDate.toUtc().toIso8601String(),
        if (quantity != null) 'quantity': quantity,
        if (supplierName != null) 'supplierName': supplierName,
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
      }),
    );
    return _parseSingle(res, 'batch', FarmingBatchRecord.fromJson);
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

  Future<String> fetchNextLotCode(String token, {DateTime? importDate}) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crab-lots/next-code')
        .replace(
      queryParameters: importDate == null
          ? null
          : {'importDate': importDate.toUtc().toIso8601String()},
    );
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (_isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không lấy được mã lô',
        statusCode: res.statusCode,
      );
    }
    final data = _dataOf(body);
    if (data is Map) {
      final code = (data['code'] ?? data['Code'])?.toString() ?? '';
      if (code.isNotEmpty) return code;
    }
    return 'LOT-${DateTime.now().toUtc().toIso8601String().substring(0, 10).replaceAll('-', '')}-001';
  }

  Future<FarmingBatchRecord> createCrabLot(
    String token, {
    required String name,
    required DateTime importDate,
    required int quantity,
    String? lotCode,
    String? supplierName,
    double? totalWeightKg,
    double? weightMinGram,
    double? weightMaxGram,
    double? unitPriceVndPerKg,
    double? shippingCostVnd,
    double? otherCostVnd,
    String condition = 'Good',
    int deadOnArrival = 0,
    String? notes,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crab-lots');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'importDate': importDate.toUtc().toIso8601String(),
        'quantity': quantity,
        if (lotCode != null && lotCode.isNotEmpty) 'lotCode': lotCode,
        if (supplierName != null && supplierName.isNotEmpty)
          'supplierName': supplierName,
        if (totalWeightKg != null) 'totalWeightKg': totalWeightKg,
        if (weightMinGram != null) 'weightMinGram': weightMinGram,
        if (weightMaxGram != null) 'weightMaxGram': weightMaxGram,
        if (unitPriceVndPerKg != null) 'unitPriceVndPerKg': unitPriceVndPerKg,
        if (shippingCostVnd != null) 'shippingCostVnd': shippingCostVnd,
        if (otherCostVnd != null) 'otherCostVnd': otherCostVnd,
        'condition': condition,
        'deadOnArrival': deadOnArrival,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    return _parseSingle(res, 'batch', FarmingBatchRecord.fromJson);
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
    final name = (batchCode != null && batchCode.isNotEmpty)
        ? batchCode
        : 'Lô nhập ${_dateOnly(startDate)}';
    return createCrabLot(
      token,
      name: name,
      importDate: startDate,
      quantity: initialQuantity > 0 ? initialQuantity : 1,
      lotCode: (batchCode != null && batchCode.isNotEmpty) ? batchCode : null,
      notes: expectedHarvestDate != null
          ? 'Dự kiến thu: ${_dateOnly(expectedHarvestDate)}'
          : null,
    );
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

  Future<void> transferCrab(
    String token, {
    required String crabId,
    required String destinationBoxId,
    String? sourceBoxId,
    String? notes,
    String? targetFarmAreaId,
    String? targetRowId,
    String? reasonCode,
    String? reasonText,
    String? note,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/allocations/transfer');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'crabId': crabId,
        'destinationBoxId': destinationBoxId,
        'targetBoxId': destinationBoxId,
        if (sourceBoxId != null && sourceBoxId.isNotEmpty)
          'sourceBoxId': sourceBoxId,
        if (targetFarmAreaId != null && targetFarmAreaId.isNotEmpty)
          'targetFarmAreaId': targetFarmAreaId,
        if (targetRowId != null && targetRowId.isNotEmpty)
          'targetRowId': targetRowId,
        if (reasonCode != null && reasonCode.isNotEmpty)
          'reasonCode': reasonCode,
        if (reasonText != null && reasonText.isNotEmpty)
          'reasonText': reasonText,
        if (note != null && note.isNotEmpty) 'note': note,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    _ensureOk(res);
  }

  // ── Tab "Ăn & Vận động" ───────────────────────────────────────────────

  /// `GET /api/operations/crab/{crabId}/feeding-activity?from&to&page&limit`
  Future<CrabFeedingActivityData> fetchCrabFeedingActivity(
    String token,
    String crabId, {
    required DateTime from,
    required DateTime to,
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '${AppEnv.cloudApiUrl}/api/operations/crab/$crabId/feeding-activity',
    ).replace(queryParameters: {
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      'page': '$page',
      'limit': '$limit',
    });
    final res = await _client.get(uri, headers: authHeaders(token));
    _ensureOk(res);
    final body = _decode(res);
    return CrabFeedingActivityData.fromJson(_asMap(_dataOf(body) ?? body));
  }

  /// `POST /api/operations` với type=feeding gắn crabId + boxId.
  Future<FeedingEvent> createFeedingEvent(
    String token, {
    required String crabId,
    required String boxId,
    required NewFeedingInput input,
    String? operatorName,
    String? locationLabel,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/operations');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': 'feeding',
        'crabIds': [crabId],
        if (boxId.isNotEmpty) 'boxIds': [boxId],
        'foodType': input.foodType,
        'quantity': input.servedGram,
        'unit': 'g',
        if (input.eatenGram != null) 'eatenQuantity': input.eatenGram,
        if (input.activityBefore != null) 'activityBefore': input.activityBefore,
        if (input.activityAfter != null) 'activityAfter': input.activityAfter,
        if (input.cameraId != null && input.cameraId!.isNotEmpty)
          'cameraId': input.cameraId,
        'notes': input.note ?? '',
        if (input.photoUrls.isNotEmpty) 'photoUrls': input.photoUrls,
        'timestamp': input.time.toUtc().toIso8601String(),
        if (operatorName != null && operatorName.isNotEmpty)
          'operatorName': operatorName,
        'source': 'manual',
        if (locationLabel != null && locationLabel.isNotEmpty)
          'locationLabel': locationLabel,
      }),
    );
    _ensureOk(res);
    final body = _decode(res);
    return FeedingEvent.fromJson(_asMap(_dataOf(body) ?? body));
  }

  /// `PUT /api/operations/{id}` — chỉ sửa ghi chú (BE giới hạn 24h, có audit UpdatedAt).
  Future<FeedingEvent> updateFeedingNote(
    String token,
    String operationId,
    String note,
  ) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/operations/$operationId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'notes': note}),
    );
    _ensureOk(res);
    final body = _decode(res);
    return FeedingEvent.fromJson(_asMap(_dataOf(body) ?? body));
  }

  Future<List<CrabManagementListItem>> _fetchAllCrabs(
    String token, {
    String? farmId,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs').replace(
      queryParameters: {
        'page': '1',
        'pageSize': '0',
        if (farmId != null && farmId.isNotEmpty) 'farmingAreaId': farmId,
      },
    );
    final res = await _client.get(
      uri,
      headers: authHeaders(token, farmId: farmId),
    );
    return _parseList(res, 'items', CrabManagementListItem.fromJson);
  }

  Future<({CrabManagementSummaryDto summary, List<CrabManagementListItem> crabs})>
      fetchFarmCrabs(String token, String farmId) async {
    var crabs = await _fetchAllCrabs(token, farmId: farmId);
    final rows = await fetchAllRows(
      token,
      areaId: farmId.isEmpty ? null : farmId,
    );
    final boxes = await fetchAllBoxes(
      token,
      areaId: farmId.isEmpty ? null : farmId,
    );
    final rowById = {for (final r in rows) r.id: r};
    final boxById = {for (final b in boxes) b.id: b};
    crabs = [
      for (final c in crabs) _withRowFromBox(c, rowById, boxById),
    ];
    if (farmId.isNotEmpty) {
      crabs = crabs.where((c) => c.areaId == farmId).toList();
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
            shellLength: c.shellLength,
            status: c.status,
            moltCount: c.moltCount,
            lastMoltDate: c.lastMoltDate,
            healthStatus: c.healthStatus,
            growthStage: c.growthStage,
            profileNote: c.profileNote,
            batchStartDate: c.batchStartDate,
            updatedAt: c.updatedAt,
          ),
        )
        .toList();
    final dead = crabs.where((c) => c.status == 'dead').length;
    final molting = crabs
        .where((c) =>
            c.status == 'molting' ||
            (c.healthStatus ?? '').toLowerCase().contains('molt'))
        .length;
    final harvested = crabs
        .where((c) => c.status == 'harvested' || c.status == 'sold')
        .length;
    final ready = crabs.where((c) {
      final g = (c.growthStage ?? '').toLowerCase();
      return g.contains('harvest') &&
          c.status != 'harvested' &&
          c.status != 'sold' &&
          c.status != 'dead';
    }).length;
    final alive = crabs.length - dead - harvested;
    return (
      summary: CrabManagementSummaryDto(
        total: crabs.length,
        alive: alive,
        dead: dead,
        molting: molting,
        readyHarvest: ready,
      ),
      crabs: crabs,
    );
  }

  Future<CrabProfile> fetchCrabProfile(String token, String crabId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId/profile');
    final res = await _client.get(uri, headers: authHeaders(token));
    _ensureOk(res);
    final body = _decode(res);
    return CrabProfile.fromJson(_asMap(_dataOf(body) ?? body));
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
              'id': map['id'] ?? map['Id'],
              'moltDate': map['moltTime'] ?? map['MoltTime'],
              'condition': map['result'] ?? map['Result'] ?? 'normal',
              'note': map['notes'] ?? map['Notes'],
              'photoUrls': map['photoUrls'] ?? map['PhotoUrls'] ?? const [],
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

  Future<CrabGrowthMoltData> fetchCrabGrowthMolt(
    String token,
    String crabId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId/growth-molt').replace(
      queryParameters: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    final res = await _client.get(uri, headers: authHeaders(token));
    _ensureOk(res);
    final body = _decode(res);
    return CrabGrowthMoltData.fromJson(_asMap(_dataOf(body) ?? body));
  }

  Future<CrabLifecyclePage> fetchCrabLifecycleEvents(
    String token,
    String crabId, {
    DateTime? from,
    DateTime? to,
    String? eventType,
    String? search,
    String? sort,
    int skip = 0,
    int take = 20,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId/lifecycle-events').replace(
      queryParameters: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (eventType != null && eventType.isNotEmpty) 'eventType': eventType,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        'skip': '$skip',
        'take': '$take',
      },
    );
    final res = await _client.get(uri, headers: authHeaders(token));
    _ensureOk(res);
    final body = _decode(res);
    return CrabLifecyclePage.fromJson(_asMap(_dataOf(body) ?? body));
  }

  Future<GrowthMeasurement> recordCrabWeight(
    String token,
    String crabId, {
    required DateTime measuredAt,
    required double weightGram,
    double? shellWidthMm,
    double? shellLengthMm,
    String? notes,
    String? recordedByName,
    List<String> photoUrls = const [],
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId/weights');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'measuredAt': measuredAt.toUtc().toIso8601String(),
        'weightGram': weightGram,
        if (shellWidthMm != null) 'carapaceWidthMm': shellWidthMm,
        if (shellLengthMm != null) 'carapaceLengthMm': shellLengthMm,
        if (notes != null) 'notes': notes,
        if (recordedByName != null && recordedByName.isNotEmpty) 'recordedByName': recordedByName,
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        'source': 'manual',
      }),
    );
    _ensureOk(res);
    final body = _decode(res);
    return GrowthMeasurement.fromJson(_asMap(_dataOf(body) ?? body));
  }

  Future<GrowthMeasurement> updateCrabWeightNote(
    String token,
    String crabId,
    String weightId,
    String note,
  ) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId/weights/$weightId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'notes': note}),
    );
    _ensureOk(res);
    final body = _decode(res);
    return GrowthMeasurement.fromJson(_asMap(_dataOf(body) ?? body));
  }

  Future<String?> recordCrabMolt(
    String token,
    String crabId, {
    required String moltDate,
    required int moltNumber,
    String condition = 'success',
    String? note,
    String? boxId,
    DateTime? startedAt,
    DateTime? completedAt,
    double? weightBeforeGram,
    double? weightAfterGram,
    double? shellWidthBeforeMm,
    double? shellLengthBeforeMm,
    double? shellWidthAfterMm,
    double? shellLengthAfterMm,
    String? cameraId,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId/moltings');
    final at = DateTime.tryParse(moltDate)?.toUtc().toIso8601String() ??
        (completedAt ?? startedAt)?.toUtc().toIso8601String();
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'crabId': crabId,
        if (at != null) 'moltTime': at,
        if (boxId != null && boxId.isNotEmpty) 'boxId': boxId,
        'result': condition,
        'source': 'desktop',
        if (note != null) 'notes': note,
        if (startedAt != null) 'startedAt': startedAt.toUtc().toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt.toUtc().toIso8601String(),
        if (weightBeforeGram != null) 'weightBeforeGram': weightBeforeGram,
        if (weightAfterGram != null) 'weightAfterGram': weightAfterGram,
        if (shellWidthBeforeMm != null) 'shellWidthBeforeMm': shellWidthBeforeMm,
        if (shellLengthBeforeMm != null) 'shellLengthBeforeMm': shellLengthBeforeMm,
        if (shellWidthAfterMm != null) 'shellWidthAfterMm': shellWidthAfterMm,
        if (shellLengthAfterMm != null) 'shellLengthAfterMm': shellLengthAfterMm,
        if (cameraId != null && cameraId.isNotEmpty) 'cameraId': cameraId,
      }),
    );
    _ensureOk(res);
    final data = _asMap(_dataOf(_decode(res)) ?? _decode(res));
    final id = (data['id'] ?? data['Id'])?.toString();
    return id != null && id.isNotEmpty ? id : null;
  }

  Future<BatchCrabRecord> updateBatchCrabExtended(
    String token,
    String crabId, {
    required String crabCode,
    required String gender,
    double? weight,
    double? shellWidth,
    double? shellLength,
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
        if (shellWidth != null) 'carapaceWidthMm': shellWidth,
        if (shellLength != null) 'carapaceLengthMm': shellLength,
        if (profileNote != null) 'notes': profileNote,
        'gender': gender,
      }),
    );
    return _parseSingle(res, 'crab', BatchCrabRecord.fromJson);
  }

  /// Chỉ cập nhật hồ sơ cơ bản — không ghi đè cân nặng / kích thước / hộp.
  Future<void> updateCrabProfile(
    String token,
    String crabId, {
    required String gender,
    required String crabType,
    required String growthStage,
    required String condition,
    required String notes,
    bool isAlive = true,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/$crabId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'gender': gender,
        'crabType': crabType,
        'moltingStage': growthStage,
        'condition': condition,
        'notes': notes,
        'isAlive': isAlive,
      }),
    );
    _ensureOk(res);
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
    String? farmingRowId,
    String? crabType,
    String? initialCondition,
    String? condition,
    DateTime? stockedAt,
    List<String>? imageUrls,
    double? carapaceLengthMm,
  }) async {
    final hasBox = boxId != null && boxId.isNotEmpty;
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'crabLotId': batchId,
        if (hasBox) 'boxId': boxId,
        if (farmingAreaId != null && farmingAreaId.isNotEmpty)
          'farmingAreaId': farmingAreaId,
        if (farmingRowId != null && farmingRowId.isNotEmpty)
          'farmingRowId': farmingRowId,
        'autoAssignEmptyBox': !hasBox,
        if (crabCode != null && crabCode.isNotEmpty) 'tag': crabCode,
        'gender': gender,
        if (weight != null) 'weightGram': weight,
        if (weight != null) 'initialWeightGram': weight,
        if (shellWidth != null) 'carapaceWidthMm': shellWidth,
        if (carapaceLengthMm != null) 'carapaceLengthMm': carapaceLengthMm,
        if (profileNote != null && profileNote.isNotEmpty) 'notes': profileNote,
        if (crabType != null && crabType.isNotEmpty) 'crabType': crabType,
        if (initialCondition != null && initialCondition.isNotEmpty)
          'initialCondition': initialCondition,
        if (condition != null && condition.isNotEmpty) 'condition': condition,
        if (stockedAt != null) 'stockedAt': stockedAt.toUtc().toIso8601String(),
        if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      }),
    );
    return _parseSingle(res, 'crab', BatchCrabRecord.fromJson);
  }

  Future<int> createCrabsBulk(
    String token, {
    required String batchId,
    String? farmingAreaId,
    String? farmingRowId,
    String? crabType,
    String? condition,
    String? initialCondition,
    DateTime? stockedAt,
    required List<Map<String, dynamic>> items,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/bulk');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'crabLotId': batchId,
        if (farmingAreaId != null && farmingAreaId.isNotEmpty)
          'farmingAreaId': farmingAreaId,
        if (farmingRowId != null && farmingRowId.isNotEmpty)
          'farmingRowId': farmingRowId,
        if (crabType != null && crabType.isNotEmpty) 'crabType': crabType,
        if (condition != null && condition.isNotEmpty) 'condition': condition,
        if (initialCondition != null && initialCondition.isNotEmpty)
          'initialCondition': initialCondition,
        if (stockedAt != null) 'stockedAt': stockedAt.toUtc().toIso8601String(),
        'items': items,
      }),
    );
    _ensureOk(res);
    final body = _decode(res);
    final data = _dataOf(body);
    if (data is Map) {
      final n = data['createdCount'] ?? data['CreatedCount'];
      if (n is num) return n.toInt();
      final crabs = data['crabs'] ?? data['Crabs'];
      if (crabs is List) return crabs.length;
    }
    return items.length;
  }

  /// POST /api/crabs/images — field `files`. Returns public URLs for CreateCrab.imageUrls.
  Future<List<String>> uploadCrabImages(
    String token,
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) return const [];
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crabs/images');
    return _uploadImageFiles(token, uri, filePaths);
  }

  /// POST /api/crab-lots/{id}/images — lưu Drive CrabSense/CrabLots/{id}/, URL ghi DB.
  Future<List<String>> uploadLotImages(
    String token,
    String lotId,
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) return const [];
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/crab-lots/$lotId/images');
    return _uploadImageFiles(token, uri, filePaths);
  }

  /// POST /api/moltings/{id}/images — {khu}/{dãy}/{hộp}/{cua}/LotXac/{ngày}.
  Future<List<String>> uploadMoltImages(
    String token,
    String moltingId,
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) return const [];
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/moltings/$moltingId/images');
    return _uploadImageFiles(token, uri, filePaths);
  }

  Future<List<String>> _uploadImageFiles(
    String token,
    Uri uri,
    List<String> filePaths,
  ) async {
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(authHeaders(token));
    for (final path in filePaths.take(10)) {
      req.files.add(await http.MultipartFile.fromPath('files', path));
    }
    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || _isApiFailure(res, body)) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải được ảnh (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final urls = <String>[];
    for (final item in _itemsOf(body).whereType<Map>()) {
      final url = (item['url'] ?? item['Url'] ?? item['shareLink'] ?? item['ShareLink'])
          ?.toString();
      if (url != null && url.isNotEmpty) urls.add(url);
    }
    if (urls.isEmpty && filePaths.isNotEmpty) {
      throw CloudApiException('Upload ảnh thành công nhưng không nhận được URL');
    }
    return urls;
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

bool _hasGuid(String? id) {
  if (id == null) return false;
  final v = id.trim();
  return v.isNotEmpty && v != '00000000-0000-0000-0000-000000000000';
}

CrabManagementListItem _withRowFromBox(
  CrabManagementListItem c,
  Map<String, RowRecord> rowById,
  Map<String, BoxRecord> boxById,
) {
  final box = _hasGuid(c.boxId) ? boxById[c.boxId] : null;
  final row = _hasGuid(c.rowId)
      ? rowById[c.rowId]
      : (box == null ? null : rowById[box.rowId]);
  return CrabManagementListItem(
    id: c.id,
    batchId: c.batchId,
    batchCode: c.batchCode,
    boxId: c.boxId,
    boxCode: c.boxCode.isNotEmpty ? c.boxCode : (box?.boxCode ?? ''),
    rowId: _hasGuid(c.rowId) ? c.rowId : (row?.id ?? box?.rowId ?? ''),
    rowCode: c.rowCode.isNotEmpty
        ? c.rowCode
        : (row?.rowCode ?? box?.rowCode ?? ''),
    rowName: c.rowName.isNotEmpty
        ? c.rowName
        : (row?.rowName ?? box?.rowName ?? ''),
    areaId: _hasGuid(c.areaId) ? c.areaId : (row?.areaId ?? box?.areaId ?? ''),
    areaCode: c.areaCode.isNotEmpty ? c.areaCode : (box?.areaCode ?? ''),
    areaName: c.areaName.isNotEmpty
        ? c.areaName
        : (row?.areaName ?? box?.areaName ?? ''),
    crabCode: c.crabCode,
    gender: c.gender,
    weight: c.weight,
    shellWidth: c.shellWidth,
    shellLength: c.shellLength,
    status: c.status,
    moltCount: c.moltCount,
    lastMoltDate: c.lastMoltDate,
    healthStatus: c.healthStatus,
    growthStage: c.growthStage,
    profileNote: c.profileNote,
    batchStartDate: c.batchStartDate,
    updatedAt: c.updatedAt,
  );
}
