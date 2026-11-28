import 'dart:convert';

/// Exact request identity; an omitted row is distinct from a particular row.
class ScopedHistoryQuery {
  ScopedHistoryQuery({
    required this.areaId,
    required this.sensorId,
    required this.from,
    required this.to,
    this.rowId,
  }) {
    if (!_guid(areaId) || !_guid(sensorId) ||
        (rowId != null && !_guid(rowId!)) ||
        !from.isUtc || !to.isUtc || !from.isBefore(to) ||
        to.difference(from) > const Duration(days: 31)) {
      throw const FormatException('Invalid history request scope');
    }
  }

  final String areaId;
  final String sensorId;
  final String? rowId;
  final DateTime from;
  final DateTime to;

  String get key => jsonEncode([
    areaId, sensorId, rowId, from.toIso8601String(), to.toIso8601String(),
  ]);
}

bool _guid(Object? value) => value is String &&
    RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(value) &&
    value != '00000000-0000-0000-0000-000000000000';

DateTime _utc(Object? value) {
  if (value is! String || !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
    throw const FormatException('Missing explicit timestamp offset');
  }
  return DateTime.parse(value).toUtc();
}

void _require(bool condition) {
  if (!condition) throw const FormatException('Invalid scoped history response');
}

/// Immutable validated snapshot. Only complete, bounded API responses qualify.
/// A missing measurement is absent, not a synthetic zero-valued point.
class ScopedHistorySnapshot {
  ScopedHistorySnapshot._(this.query, this.asOf, this.encodedPages,
      this.pointCount);

  final ScopedHistoryQuery query;
  final DateTime asOf;
  final String encodedPages;
  final int pointCount;

  factory ScopedHistorySnapshot.fromPages(
    ScopedHistoryQuery query,
    List<Map<String, dynamic>> pages,
  ) {
    _require(pages.isNotEmpty && pages.length <= 20);
    final first = pages.first;
    final cutoff = _utc(first['asOf']);
    final row = first['farmingRowId'];
    final type = first['sensorType'];
    final unit = first['unit'];
    final pageSize = first['pageSize'];
    _require(!cutoff.isBefore(query.to) &&
        (row == null || _guid(row)) &&
        (query.rowId == null || row == query.rowId) &&
        type is String && type.trim().isNotEmpty &&
        unit is String && unit.trim().isNotEmpty &&
        pageSize is int && pageSize >= 1 && pageSize <= 500);
    final ids = <String>{};
    DateTime? previous;
    for (var i = 0; i < pages.length; i++) {
      final p = pages[i];
      _require(p['contract'] == 'scoped-sensor-history-v1' &&
          p['farmingAreaId'] == query.areaId &&
          p['sensorId'] == query.sensorId &&
          p.containsKey('farmingRowId') && p['farmingRowId'] == row &&
          p['sensorType'] == type && p['unit'] == unit &&
          p['sensorActive'] is bool &&
          p['sensorActive'] == first['sensorActive'] &&
          p['legacyUnqualifiedExcluded'] == true &&
          p['scopeBasis'] == 'configured_location_at_ingest' &&
          p['physicalLocationVerified'] == false &&
          p['databaseSnapshotGuaranteed'] == false &&
          p['chemicalResultIncluded'] == false &&
          _utc(p['from']) == query.from && _utc(p['to']) == query.to &&
          _utc(p['asOf']) == cutoff &&
          p['page'] == i + 1 && p['pageSize'] == pageSize &&
          p['hasMore'] == (i < pages.length - 1));
      final items = p['items'];
      _require(items is List);
      final list = items as List;
      _require(list.length <= (pageSize as int) &&
          (i == pages.length - 1 || list.length == pageSize));
      for (final item in list) {
        _require(item is Map);
        final m = item as Map;
        final id = m['id'];
        final value = m['value'];
        final measured = _utc(m['measuredAt']);
        final received = _utc(m['receivedAt']);
        _require(_guid(id) &&
            m['sensorId'] == query.sensorId &&
            m['farmingAreaId'] == query.areaId &&
            m.containsKey('farmingRowId') && m['farmingRowId'] == row &&
            m['sensorType'] == type && m['unit'] == unit &&
            m['dataQuality'] == 'Realtime' &&
            (m['source'] == 'edge' || m['source'] == 'realtime') &&
            value is num && value.isFinite &&
            !measured.isBefore(query.from) && measured.isBefore(query.to) &&
            !received.isAfter(cutoff) &&
            (previous == null || !measured.isAfter(previous)));
        _require(ids.add(id as String));
        previous = measured;
      }
    }
    _require(ids.length <= 5000);
    // Retain only contract fields; reject malformed data before storage.
    final clean = pages.map((p) => <String, dynamic>{
      for (final k in [
        'contract', 'farmingAreaId', 'sensorId', 'farmingRowId',
        'sensorType', 'unit', 'sensorActive', 'from', 'to', 'asOf',
        'page', 'pageSize', 'hasMore', 'legacyUnqualifiedExcluded',
        'scopeBasis', 'physicalLocationVerified',
        'databaseSnapshotGuaranteed', 'chemicalResultIncluded',
      ]) k: p[k],
      'items': (p['items'] as List).map((item) => <String, dynamic>{
        for (final k in [
          'id', 'sensorId', 'value', 'unit', 'measuredAt', 'receivedAt',
          'dataQuality', 'farmingAreaId', 'farmingRowId', 'sensorType', 'source',
        ]) k: (item as Map)[k],
      }).toList(),
    }).toList();
    return ScopedHistorySnapshot._(
      query, cutoff, jsonEncode(clean), ids.length,
    );
  }

  factory ScopedHistorySnapshot.decode(
    ScopedHistoryQuery query, String payload,
  ) {
    final raw = jsonDecode(payload);
    if (raw is! List) throw const FormatException('Invalid history cache');
    return ScopedHistorySnapshot.fromPages(query,
      raw.map((p) => Map<String, dynamic>.from(p as Map)).toList());
  }
}
