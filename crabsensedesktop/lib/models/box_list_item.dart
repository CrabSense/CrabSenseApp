import 'production_models.dart';

class BoxListItem {
  const BoxListItem({
    required this.box,
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    required this.rowId,
    required this.rowCode,
    required this.rowName,
  });

  final BoxRecord box;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String rowId;
  final String rowCode;
  final String rowName;
}
