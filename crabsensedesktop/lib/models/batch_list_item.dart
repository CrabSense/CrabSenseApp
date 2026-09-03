import 'production_models.dart';

class BatchListItem {
  const BatchListItem({
    required this.batch,
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    required this.rowId,
    required this.rowCode,
    required this.rowName,
    required this.boxCode,
    this.boxPosition,
  });

  final FarmingBatchRecord batch;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String rowId;
  final String rowCode;
  final String rowName;
  final String boxCode;
  final String? boxPosition;

  String get id => batch.id;
  double get survivalPercent => batch.initialQuantity <= 0
      ? 0
      : (batch.currentQuantity / batch.initialQuantity * 100).clamp(0, 100);
}
