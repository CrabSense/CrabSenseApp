/// WaterBench observations and estimates are not realtime sensor measurements.
typedef BenchJson = Map<String, dynamic>;

BenchJson benchMap(Object? value) => value is Map
    ? Map<String, dynamic>.from(value)
    : <String, dynamic>{};

List<BenchJson> benchRows(Object? value) =>
    value is List ? value.whereType<Map>().map(benchMap).toList() : [];

const benchAnalytes = ['NO2', 'NO3', 'NH3'];
final _guid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
final _hex = RegExp(r'^[0-9a-f]{16}$');

bool benchGuid(String value) => _guid.hasMatch(value) &&
    value != '00000000-0000-0000-0000-000000000000';

class BenchBatch {
  BenchBatch.fromJson(BenchJson json)
      : stationId = json['stationId']?.toString() ?? '',
        bootId = json['bootId']?.toString() ?? '',
        batchId = json['firmwareBatchId']?.toString() ?? '',
        mode = benchMap(json['start'])['mode']?.toString(),
        createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '') {
    if (!benchGuid(stationId) || !_hex.hasMatch(bootId) || !_hex.hasMatch(batchId)) {
      throw const FormatException('Danh tính phiên WaterBench không hợp lệ.');
    }
  }
  final String stationId, bootId, batchId;
  final String? mode;
  final DateTime? createdAt;
  String get key => '$stationId/$bootId/$batchId';
}

class BenchOverview {
  const BenchOverview(this.station, this.batches);
  final BenchJson? station;
  final List<BenchBatch> batches;
}

BenchJson? benchChannel(BenchJson data, String analyte) {
  for (final row in benchRows(data['channels'])) {
    if (row['analyte'] == analyte) return row;
  }
  return null;
}

bool benchUnit(String analyte, Object? unit) => analyte == 'NH3'
    ? const ['mg/L NH3', 'mg/L NH4', 'mg/L TAN-N'].contains(unit)
    : benchAnalytes.contains(analyte) && unit == 'mg/L $analyte';

class BenchChannel {
  BenchChannel(this.analyte, this.observation, this.result, this.readiness,
      this.retry, this.review, this.reviewUnavailable);
  final String analyte;
  final BenchJson? observation, result, readiness, retry, review;
  final bool reviewUnavailable;
  BenchJson get assessment => benchMap(result?['assessment']);
  num? get estimate {
    final value = assessment['estimatedValue'];
    return assessment['status'] == 'estimate_review_required' &&
        benchUnit(analyte, assessment['unit']) &&
        value is num && value.isFinite && value >= 0 ? value : null;
  }
  String? get unit => estimate == null ? null : assessment['unit'] as String;
  BenchJson get publication => benchMap(review?['publication']);
  num? get publishedReference {
    final v = publication['value'];
    return review?['status'] == 'published' &&
        review?['publicationScope'] == 'water_bench_reviewed_record' &&
        review?['assessmentId'] == assessment['id'] &&
        publication['assessmentId'] == assessment['id'] &&
        publication['unit'] == assessment['unit'] &&
        publication['source'] == 'operator_attested_independent_reference' &&
        publication['productionSensorPublished'] == false &&
        benchUnit(analyte, publication['unit']) &&
        v is num && v.isFinite && v >= 0 ? v : null;
  }
}

class BenchDetail {
  const BenchDetail({required this.timeline, required this.stale,
    required this.receipts, required this.channels});
  final BenchJson timeline, receipts;
  final bool stale;
  final List<BenchChannel> channels;
}

/// Validate one complete server inventory before exposing any channel data.
/// This is metadata consistency, not live Drive or chemical verification.
void verifyBenchSnapshot(BenchBatch batch, BenchJson timeline,
    BenchJson receipts, List<BenchJson> channelSets) {
  bool matches(BenchJson row) => row['stationId'] == batch.stationId &&
      row['bootId'] == batch.bootId && row['batchId'] == batch.batchId;
  if (!matches(timeline) || !matches(receipts) ||
      receipts['inventoryComplete'] != true ||
      receipts['receiptBasis'] != 'persisted_backend_evidence' ||
      receipts['timelineStatus'] != timeline['status']) {
    throw const FormatException('Danh tính hoặc biên nhận WaterBench không khớp.');
  }
  final raw = receipts['items'];
  final rows = benchRows(raw);
  if (raw is! List || raw.length != rows.length ||
      receipts['total'] != rows.length || rows.length > 517 ||
      rows.isEmpty) {
    throw const FormatException('Danh sách biên nhận không đầy đủ.');
  }
  final ids = <String>{}, events = <String>{}, media = <String>{};
  final digest = RegExp(r'^[0-9a-f]{64}$');
  for (final row in rows) {
    final id = row['receiptId'], event = row['eventId'];
    if (id is! String || !benchGuid(id) || !ids.add(id) ||
        event is! String || !benchGuid(event) || !events.add(event) ||
        row['connectionId'] != timeline['connectionId'] ||
        !digest.hasMatch(row['serverPayloadSha256']?.toString() ?? '') ||
        !const ['batch', 'media', 'nh3'].contains(row['kind'])) {
      throw const FormatException('Biên nhận trùng hoặc sai liên kết.');
    }
    if (row['kind'] == 'media') {
      final id = row['mediaId'];
      if (id is! String || !benchGuid(id) || !media.add(id) ||
          !digest.hasMatch(row['sha256']?.toString() ?? '')) {
        throw const FormatException('Biên nhận ảnh không hợp lệ.');
      }
    }
  }
  if (!benchGuid(timeline['connectionId']?.toString() ?? '') ||
      !rows.any((r) => r['evidenceKind'] == 'batch_start' && r['kind'] == 'batch') ||
      receipts['timelineCount'] != rows.where((r) => r['kind'] == 'batch').length ||
      receipts['mediaCount'] != media.length || media.length > 3 ||
      receipts['nh3Count'] != rows.where((r) => r['kind'] == 'nh3').length ||
      (receipts['nh3Count'] as int) > 2) {
    throw const FormatException('Số lượng biên nhận không nhất quán.');
  }
  for (final set in [timeline, ...channelSets]) {
    final raw = set['channels'];
    final channels = benchRows(raw);
    final seen = <Object?>{};
    if (raw is! List || raw.length != channels.length ||
        channels.any((c) => !benchAnalytes.contains(c['analyte']) ||
            !seen.add(c['analyte']))) {
      throw const FormatException('Danh sách kênh WaterBench không hợp lệ.');
    }
  }
}

void requireBenchCurrent(bool Function()? current) {
  if (current != null && !current()) throw StateError('WaterBench load cancelled');
}

// Server-verified snapshot identity; not a fresh Drive read or an external signature.
void verifyBenchEstimate(BenchBatch batch, String analyte, BenchJson result,
    BenchJson receipts, BenchJson evidence) {
  final a=benchMap(result['assessment']), p=benchMap(evidence['provenance']);
  final session=benchMap(evidence['session']), image=benchMap(evidence['image']);
  final value=a['estimatedValue'], error=a['holdoutError'];
  final digest=RegExp(r'^[0-9a-f]{64}$');
  bool id(Object? v)=>v is String && benchGuid(v);
  bool hash(Object? v)=>v is String && digest.hasMatch(v);
  bool number(Object? v)=>v is num && v.isFinite && v>=0;
  bool matchesReceipt(BenchJson row, String kind, Object? key) {
    final matches=benchRows(receipts['items']).where((r)=>r['receiptId']==key).toList();
    if(matches.length!=1 || row['kind']!=kind || row['analyte']!=analyte) return false;
    final stored=matches.single;
    return ['receiptId','eventId','connectionId','sessionId','captureId','analyte',
      'kind','evidenceKind','serverPayloadSha256','mediaId','sha256'].every((k)=>stored[k]==row[k]) &&
      (kind!='media'||stored['privateMediaMetadataPresent']==true);
  }
  if(evidence['provenanceStatus']!='snapshot_verified' || !hash(evidence['provenanceSha256']) ||
      evidence['status']!='estimate_review_required' || evidence['chemicalResultValidated']!=false ||
      evidence['productionPublished']!=false || !id(a['id']) || !id(a['requestId']) ||
      !id(a['calibrationId']) || !id(a['sessionEvidenceId']) || !id(a['imageEvidenceId']) ||
      !id(a['mediaId']) || !number(value) || !number(error) || !benchUnit(analyte,a['unit']) ||
      evidence['assessmentId']!=a['id'] || evidence['requestId']!=a['requestId'] ||
      evidence['candidateValue']!=value || evidence['unit']!=a['unit'] || evidence['holdoutError']!=error ||
      p['contract']!='water-bench-ai-evidence-v1' || p['assessmentId']!=a['id'] ||
      p['requestId']!=a['requestId'] || !hash(p['requestSha256']) ||
      p['stationId']!=batch.stationId || p['bootId']!=batch.bootId || p['batchId']!=batch.batchId ||
      p['analyte']!=analyte || p['connectionId']!=session['connectionId'] ||
      p['connectionId']!=image['connectionId'] || p['sessionId']!=session['sessionId'] ||
      p['sessionId']!=image['sessionId'] || p['sessionId']!=result['sessionId'] ||
      p['captureId']!=image['captureId'] || p['captureId']!=result['captureId'] ||
      p['sessionReceiptId']!=a['sessionEvidenceId'] || p['imageReceiptId']!=a['imageEvidenceId'] ||
      p['sessionPayloadSha256']!=session['serverPayloadSha256'] ||
      p['imagePayloadSha256']!=image['serverPayloadSha256'] ||
      p['imageSha256']!=image['sha256'] || p['mediaId']!=a['mediaId'] ||
      p['mediaId']!=image['mediaId'] || p['calibrationId']!=a['calibrationId'] ||
      benchMap(evidence['calibration'])['id']!=a['calibrationId'] ||
      !matchesReceipt(session,'batch',a['sessionEvidenceId']) ||
      session['evidenceKind']!='session' || !matchesReceipt(image,'media',a['imageEvidenceId'])) {
    throw const FormatException('Bằng chứng ước tính WaterBench không khớp hoặc chưa xác minh.');
  }
}
