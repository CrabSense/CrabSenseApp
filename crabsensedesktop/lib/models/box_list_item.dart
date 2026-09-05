import 'crab_condition.dart';
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

  String get displayName => box.title;

  String get placeLabel {
    final khu = areaName.trim().isEmpty ? areaCode : areaName;
    final day = rowName.trim().isEmpty ? rowCode : rowName;
    return '$khu • $day';
  }

  bool get hasCrab => box.hasCrab;

  bool get hasAlert => box.alertCount > 0;

  CrabCondition get crabCondition => CrabConditionX.parse(
        condition: box.crabCondition,
        moltingStage: box.crabMoltingStage,
        crabStatus: box.crabStatus,
        hasCrab: hasCrab,
      );
}
