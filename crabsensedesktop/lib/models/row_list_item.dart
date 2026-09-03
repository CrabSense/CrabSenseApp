import 'production_models.dart';

class RowListItem {
  const RowListItem({
    required this.row,
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    required this.boxCount,
    required this.status,
    this.esp32Count = 0,
    this.cameraCount = 0,
  });

  final RowRecord row;
  final String areaId;
  final String areaCode;
  final String areaName;
  final int boxCount;
  final String status;
  final int esp32Count;
  final int cameraCount;

  String get rowCode => row.rowCode;
  String get rowName => row.rowName;
  String get rowId => row.id;
}
