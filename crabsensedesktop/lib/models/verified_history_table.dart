import 'dart:convert';
import 'scoped_history_snapshot.dart';

class VerifiedHistoryRow {
  const VerifiedHistoryRow._(this.id,this.measuredAt,this.receivedAt,this.value,this.source);
  final String id, measuredAt, receivedAt, source;
  final num value;
}

/// One fully validated snapshot. Preserve wire timestamps and server order.
class VerifiedHistoryTable {
  VerifiedHistoryTable._(this.areaId,this.sensorId,this.rowId,this.sensorType,
    this.unit,this.from,this.to,this.asOf,List<VerifiedHistoryRow> rows)
    : rows=List.unmodifiable(rows);
  final String areaId,sensorId,sensorType,unit,from,to,asOf;
  final String? rowId;
  final List<VerifiedHistoryRow> rows;

  factory VerifiedHistoryTable.fromSnapshot(ScopedHistorySnapshot snapshot) {
    final pages=jsonDecode(snapshot.encodedPages) as List;
    final first=pages.first as Map;
    return VerifiedHistoryTable._(snapshot.query.areaId,snapshot.query.sensorId,
      first['farmingRowId'] as String?,first['sensorType'] as String,
      first['unit'] as String,first['from'] as String,first['to'] as String,
      first['asOf'] as String,[
        for(final page in pages)
          for(final raw in (page as Map)['items'] as List)
            VerifiedHistoryRow._(raw['id'] as String,raw['measuredAt'] as String,
              raw['receivedAt'] as String,raw['value'] as num,raw['source'] as String),
      ]);
  }
  static String _cell(String value) {
    final unsafe=RegExp(r'^\s*[=+\-@]|\r|\n|\t').hasMatch(value);
    final safe=unsafe ? "'$value" : value;
    return '"'+safe.replaceAll('"','""')+'"';
  }
  String toCsv() {
    final out=StringBuffer('measurement_id,farming_area_id,farming_row_id,sensor_id,'
      'sensor_type,unit,measured_at,received_at,value,data_quality,source,from,to,as_of,'
      'scope_basis,physical_location_verified,database_snapshot_guaranteed\r\n');
    for(final r in rows) {
      out.write([_cell(r.id),_cell(areaId),_cell(rowId ?? ''),_cell(sensorId),
        _cell(sensorType),_cell(unit),_cell(r.measuredAt),_cell(r.receivedAt),
        r.value.toString(),_cell('Realtime'),_cell(r.source),_cell(from),_cell(to),
        _cell(asOf),_cell('configured_location_at_ingest'),'false','false'].join(','));
      out.write('\r\n');
    }
    return out.toString();
  }
}
