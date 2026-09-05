import 'farm_record.dart';
import 'production_models.dart';

class RowListItem {
  const RowListItem({
    required this.row,
    this.areaCode = '',
  });

  final RowRecord row;
  final String areaCode;

  String get areaId => row.areaId;
  String get areaName => row.areaName ?? '';
  String get rowCode => row.rowCode;
  String get rowName => row.rowName;
  String get rowId => row.id;
  int get boxCount => row.boxCount;
  FarmStatus get status => row.status;
}
