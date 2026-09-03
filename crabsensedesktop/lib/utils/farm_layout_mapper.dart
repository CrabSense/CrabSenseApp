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

FarmMapBox toFarmMapBox({
  required BoxRecord box,
  required AreaRecord area,
  required RowRecord row,
}) {
  final uiStatus = mapBoxApiStatus(box.status);
  final code = box.boxCode.trim().isNotEmpty ? box.boxCode : box.id;

  final display = uiStatus == BoxStatus.empty
      ? CrabBox(id: code, zone: area.areaCode, status: uiStatus)
      : CrabBox(
          id: code,
          zone: area.areaCode,
          status: uiStatus,
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
    rowCode: row.rowCode,
    rowName: row.rowName,
    apiStatus: box.status,
  );
}
