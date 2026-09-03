import 'box_status.dart';
import 'crab_box.dart';

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
    required this.rowCode,
    required this.rowName,
    required this.apiStatus,
  });

  final CrabBox display;
  final String boxId;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String rowCode;
  final String rowName;
  final String apiStatus;
}

extension FarmLayoutListX on List<FarmMapBox> {
  FarmLayoutSummary toSummary() {
    final boxes = map((e) => e.display).toList();
    return FarmLayoutSummary(
      total: boxes.length,
      occupied: boxes.where((b) => b.isOccupied).length,
      empty: boxes.where((b) => b.status == BoxStatus.empty).length,
      normal: boxes.where((b) => b.status == BoxStatus.normal).length,
      watch: boxes.where((b) => b.status == BoxStatus.watch).length,
      molting: boxes.where((b) => b.status == BoxStatus.molting).length,
      alert: boxes.where((b) => b.status == BoxStatus.alert).length,
      deceased: boxes.where((b) => b.status == BoxStatus.deceased).length,
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
