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
