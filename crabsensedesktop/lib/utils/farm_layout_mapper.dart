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
    // Theo dõi (amber): BE `watch`, hoặc hộp đang bảo trì.
    'watch' || 'maintenance' || 'monitoring' => BoxStatus.watch,
    // Cảnh báo (đỏ): cách ly / bệnh / alert.
    'quarantine' || 'warning' || 'alert' || 'disease' => BoxStatus.alert,
    'molting' => BoxStatus.molting,
    // Cua chết / đã bán ⇒ BE trả hộp về trống, không còn là "sự cố".
    'dead' || 'deceased' || 'harvested' || 'sold' => BoxStatus.empty,
    _ => BoxStatus.normal,
  };
}

/// Tình trạng xấu nhất của cua trong hộp (BE trả `crabCondition`).
/// Hộp đang nuôi luôn có status `active`, nên nếu chỉ đọc `status` thì mọi hộp
/// đều xanh — màu phải lấy từ đây mới thấy được cua bệnh / đang lột.
BoxStatus mapCrabCondition(String? condition) {
  final c = condition?.trim().toLowerCase() ?? '';
  return switch (c) {
    'problem' => BoxStatus.alert, // có vấn đề → đỏ
    'weak' => BoxStatus.watch, // yếu → theo dõi (amber)
    'premolt' || 'molting' || 'softshell' => BoxStatus.molting, // lột → tím
    'dead' || 'harvested' || 'sold' => BoxStatus.empty, // chết/bán → trống hộp
    _ => BoxStatus.normal,
  };
}

/// Mức nghiêm trọng để gộp trạng thái hộp + tình trạng cua: lấy mức xấu hơn.
int _severity(BoxStatus s) => switch (s) {
      BoxStatus.alert => 3,
      BoxStatus.watch => 2,
      BoxStatus.molting => 1,
      _ => 0,
    };

BoxStatus _worstOf(BoxStatus a, BoxStatus b) =>
    _severity(b) > _severity(a) ? b : a;

bool isInactiveCrab(String? crabStatus, String? crabCondition) {
  bool matches(String? raw, Set<String> values) =>
      values.contains((raw ?? '').trim().toLowerCase());
  return matches(crabStatus, const {'dead', 'harvested', 'missing', 'sold'}) ||
      matches(crabCondition, const {'dead', 'harvested', 'sold'});
}

/// Trạng thái hiển thị (màu) của một hộp: kết hợp status hộp + tình trạng cua.
BoxStatus boxUiStatus(BoxRecord box) {
  var uiStatus = mapBoxApiStatus(box.status);
  if (box.crabCount <= 0 && isInactiveCrab(box.crabStatus, box.crabCondition)) {
    uiStatus = BoxStatus.empty;
  } else if (box.crabCount > 0) {
    // Hộp đang có cua: màu theo tình trạng xấu nhất của cua, nhưng hộp
    // đang `watch`/`quarantine` vẫn phải giữ mức Theo dõi / Cảnh báo.
    final boxLevel = uiStatus == BoxStatus.empty ? BoxStatus.normal : uiStatus;
    uiStatus = _worstOf(mapCrabCondition(box.crabCondition), boxLevel);
  }
  return uiStatus;
}

FarmMapBox toFarmMapBox({
  required BoxRecord box,
  required AreaRecord area,
  required RowRecord row,
}) {
  final uiStatus = boxUiStatus(box);
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
          hasAlert: uiStatus == BoxStatus.alert || box.alertCount > 0,
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
