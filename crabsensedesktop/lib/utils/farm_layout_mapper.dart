import '../models/box_status.dart';
import '../models/crab_box.dart';
import '../models/farm_layout.dart';
import '../models/production_models.dart';

BoxStatus mapBoxApiStatus(String status) {
  final s = status.trim().toLowerCase();
  if (s.isEmpty) return BoxStatus.empty;
  return switch (s) {
    'empty' || 'available' || 'idle' || 'vacant' => BoxStatus.empty,
    'farming' || 'active' || 'occupied' => BoxStatus.normal,
    'maintenance' || 'watch' => BoxStatus.watch,
    'warning' || 'alert' => BoxStatus.alert,
    'molting' => BoxStatus.molting,
    'disease' || 'dead' || 'deceased' => BoxStatus.deceased,
    _ => BoxStatus.normal,
  };
}

bool isInactiveCrab(String? crabStatus, String? crabCondition) {
  bool matches(String? raw, Set<String> values) =>
      values.contains((raw ?? '').trim().toLowerCase());
  return matches(crabStatus, const {'dead', 'harvested', 'missing', 'sold'}) ||
      matches(crabCondition, const {'dead', 'harvested', 'sold'});
}

FarmMapBox toFarmMapBox({
  required BoxRecord box,
  required AreaRecord area,
  required RowRecord row,
}) {
  var uiStatus = mapBoxApiStatus(box.status);
  if (box.crabCount <= 0 && isInactiveCrab(box.crabStatus, box.crabCondition)) {
    uiStatus = BoxStatus.empty;
  }
  final code = box.boxCode.trim().isNotEmpty ? box.boxCode : box.id;
  final showCrab = box.crabCount > 0 || (uiStatus != BoxStatus.empty && box.hasCrab);
  final crabCount = box.crabCount > 0 ? box.crabCount : (showCrab ? 1 : 0);

  final display = uiStatus == BoxStatus.empty
      ? CrabBox(id: code, zone: area.areaCode, status: uiStatus)
      : CrabBox(
          id: code,
          zone: area.areaCode,
          status: uiStatus,
          crabId: box.crabTag ?? box.crabId,
          healthScore: switch (uiStatus) {
            BoxStatus.normal => 90,
            BoxStatus.watch => 75,
            BoxStatus.molting => 85,
            BoxStatus.alert => 60,
            BoxStatus.deceased => 0,
            BoxStatus.empty => 0,
          },
          hasAlert: uiStatus == BoxStatus.alert,
        );

  return FarmMapBox(
    display: display,
    boxId: box.id,
    areaId: area.id,
    areaCode: area.areaCode,
    areaName: area.areaName,
    rowId: row.id,
    rowCode: row.rowCode,
    rowName: row.rowName,
    apiStatus: box.status,
    crabCount: crabCount,
    alertCount: box.alertCount,
    aiSummary: box.aiSummary,
    source: box,
  );
}
