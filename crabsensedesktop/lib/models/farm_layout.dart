import 'box_list_item.dart';
import 'box_status.dart';
import 'crab_box.dart';
import 'production_models.dart';

class FarmLayoutSummary {
  const FarmLayoutSummary({
    required this.total,
    required this.occupied,
    required this.empty,
    required this.normal,
    required this.watch,
    required this.molting,
    required this.alert,
    required this.deceased,
  });

  final int total;
  final int occupied;
  final int empty;
  final int normal;
  final int watch;
  final int molting;
  final int alert;
  final int deceased;
}

/// Hộp trên bản đồ trại — hiển thị + id API.
class FarmMapBox {
  const FarmMapBox({
    required this.display,
    required this.boxId,
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    required this.rowId,
    required this.rowCode,
    required this.rowName,
    required this.apiStatus,
    this.crabCount = 0,
    this.alertCount = 0,
    this.aiSummary,
    this.source,
  });

  final CrabBox display;
  final String boxId;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String rowId;
  final String rowCode;
  final String rowName;
  final String apiStatus;
  final int crabCount;
  final int alertCount;
  final String? aiSummary;
  final BoxRecord? source;

  String get areaLabel {
    final name = areaName.trim();
    if (name.isNotEmpty && name != areaCode) return name;
    return areaCode;
  }

  String get rowLabel {
    final name = rowName.trim();
    if (name.isNotEmpty && name != rowCode) return name;
    return rowCode;
  }

  BoxListItem? toListItem() {
    final box = source;
    if (box == null) return null;
    return BoxListItem(
      box: box,
      areaId: areaId,
      areaCode: areaCode,
      areaName: areaName,
      rowId: rowId,
      rowCode: rowCode,
      rowName: rowName,
    );
  }
}

extension FarmLayoutListX on List<FarmMapBox> {
  FarmLayoutSummary toSummary() {
    final boxes = map((e) => e.display).toList();
    return FarmLayoutSummary(
      total: boxes.length,
      occupied: boxes.where((b) => b.isOccupied).length,
      empty: boxes
          .where((b) =>
              b.status == BoxStatus.empty || b.status == BoxStatus.deceased)
          .length,
      normal: boxes.where((b) => b.status == BoxStatus.normal).length,
      watch: 0,
      molting: boxes.where((b) => b.status == BoxStatus.molting).length,
      alert: boxes
          .where((b) =>
              b.status == BoxStatus.alert || b.status == BoxStatus.watch)
          .length,
      deceased: 0,
    );
  }

  String mascotMessage() {
    final alerts = map((e) => e.display).where((b) => b.status == BoxStatus.alert);
    final list = alerts.toList();
    if (list.isEmpty) {
      return 'Hệ thống RAS đang hoạt động ổn định.\nKhông có hộp cần xử lý khẩn cấp.';
    }
    final ids = list.take(3).map((b) => b.id).join(', ');
    return 'Hệ thống RAS đang hoạt động ổn định.\n'
        'Lưu ý hộp $ids cần kiểm tra!';
  }
}
