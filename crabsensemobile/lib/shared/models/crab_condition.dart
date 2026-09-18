import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Trạng thái cua/hộp — MỘT bảng duy nhất cho toàn app.
///
/// Nông dân đánh dấu tình trạng bằng đúng những chữ ở [BoxStatus]; huy hiệu trên
/// thẻ hộp, chú giải lưới, sơ đồ trang trại, danh sách cua, chi tiết cua và màn
/// chi tiết hộp đều đọc từ đây. Trước đây mỗi màn có một bảng riêng (chỗ ghi
/// "Ổn định / Nghiêm trọng / Offline", chỗ ghi "Sắp lột / Đang lột / Cua lột
/// mềm / Có vấn đề / Cua yếu") nên cùng một con cua lại ra nhiều nhãn và nhiều
/// màu khác nhau.
///
/// Key, nhãn và mã màu khớp đúng app desktop: enum + extension này là bản sao
/// của `crabsensedesktop/lib/models/box_status.dart`, và [displayStatusOf] là
/// bản sao của `mapCrabCondition` trong `utils/farm_layout_mapper.dart`.

/// Trạng thái hiển thị — 5 nhóm dùng được cho cả cua lẫn hộp.
///
/// [deceased] chỉ còn là giá trị an toàn cho dữ liệu cũ, không màn nào tô màu
/// này: cua chết / đã bán / đã thu hoạch đều quy về [empty].
enum BoxStatus {
  normal,
  watch,
  molting,
  alert,
  deceased,
  empty;

  /// 5 trạng thái có thật — bỏ [deceased] vì không tình trạng cua nào ra nó
  /// (cua chết / bán / thu hoạch đều quy về [empty]). Dùng cho chú giải lưới,
  /// chú giải sơ đồ và chip lọc, để không màn nào lộ nhãn thứ sáu.
  ///
  /// Đặt trong thân enum chứ không trong extension: thành viên `static` của
  /// extension không gọi được qua tên enum.
  static const List<BoxStatus> displayable = [
    normal,
    watch,
    molting,
    alert,
    empty,
  ];
}

extension BoxStatusX on BoxStatus {
  String get label => switch (this) {
        BoxStatus.normal => 'Bình thường',
        BoxStatus.watch => 'Cần theo dõi',
        BoxStatus.molting => 'Lột xác',
        BoxStatus.alert => 'Cảnh báo',
        BoxStatus.deceased => 'Sự cố',
        BoxStatus.empty => 'Hộp trống',
      };

  String get shortLabel => switch (this) {
        BoxStatus.normal => 'BÌNH THƯỜNG',
        BoxStatus.watch => 'THEO DÕI',
        BoxStatus.molting => 'LỘT XÁC',
        BoxStatus.alert => 'CẢNH BÁO',
        BoxStatus.deceased => 'SỰ CỐ',
        BoxStatus.empty => 'TRỐNG',
      };

  String get emoji => switch (this) {
        BoxStatus.normal => '🟢',
        BoxStatus.watch => '🟡',
        BoxStatus.molting => '🟣',
        BoxStatus.alert => '🔴',
        BoxStatus.deceased => '⚫',
        BoxStatus.empty => '⚪',
      };

  /// Màu theo đúng quy ước của desktop: lột = tím, nguy cơ = đỏ, trống = xám.
  Color get color => switch (this) {
        BoxStatus.normal => CrabSenseColors.statusNormal,
        BoxStatus.watch => CrabSenseColors.statusWatch,
        BoxStatus.molting => CrabSenseColors.molt,
        BoxStatus.alert => CrabSenseColors.statusRisk,
        BoxStatus.deceased => CrabSenseColors.statusIdle,
        BoxStatus.empty => CrabSenseColors.statusIdle,
      };

  /// Nền nhạt cùng tông để chữ trên thẻ không chọi màu.
  Color get background => switch (this) {
        BoxStatus.normal => CrabSenseColors.statusNormalBg,
        BoxStatus.watch => CrabSenseColors.statusWatchBg,
        BoxStatus.molting => CrabSenseColors.moltLight,
        BoxStatus.alert => CrabSenseColors.statusRiskBg,
        BoxStatus.deceased => CrabSenseColors.statusIdleBg,
        BoxStatus.empty => CrabSenseColors.statusIdleBg,
      };
}

/// Tình trạng cua do BE trả (`CrabDto.Condition`) — enum đọc dữ liệu, KHÔNG
/// phải bảng nhãn/màu. Nhãn và màu nằm hết ở [displayStatusOf] / [BoxStatus].
enum CrabCondition {
  empty,
  normal,
  premolt,
  molting,
  softshell,
  problem,
  weak;

  /// Các mức nông dân được đánh dấu trong phiếu chăm sóc và form nhập cua.
  ///
  /// Mỗi mức phải ra một nhãn [BoxStatus] khác nhau, nên danh sách này đúng
  /// bằng số nhãn: 4 mức sống được. `premolt` / `softshell` vẫn đọc được (cua
  /// do app desktop ghi) nhưng đều hiện là "Lột xác"; `empty` không phải mức để
  /// chọn — nó là kết quả khi cua chết / sổng / thu hoạch / bán.
  ///
  /// Đặt trong thân enum chứ không trong extension: thành viên `static` của
  /// extension không gọi được qua tên enum.
  static const List<CrabCondition> selectable = [
    normal,
    weak,
    molting,
    problem,
  ];

  /// Đọc key bất kỳ từ API/BE về enum. Không nhận ra ⇒ trả `null` để nơi gọi
  /// tự chọn màu dự phòng.
  static CrabCondition? tryParse(String? raw) {
    final key = (raw ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '');
    return switch (key) {
      'empty' || 'trong' => empty,
      'normal' || 'binhthuong' || 'hard' || 'hardshell' => normal,
      'premolt' || 'pre' || 'saplot' => premolt,
      'molting' || 'molt' || 'danglot' => molting,
      'softshell' || 'soft' || 'postmolt' || 'post' || 'cualotmem' => softshell,
      // 'attention' là key cũ của phiếu chăm sóc, BE không hiểu — vẫn nhận để
      // dữ liệu đã ghi sai trước đây hiện đúng là cảnh báo chứ không phải
      // "bình thường".
      'problem' ||
      'attention' ||
      'canchuy' ||
      'alert' ||
      'quarantined' ||
      'missing' ||
      'covande' =>
        problem,
      'weak' || 'yeu' || 'cuayeu' || 'coi' => weak,
      // Cua chết / đã bán / đã thu hoạch / sổng ⇒ hộp coi như trống.
      'dead' ||
      'chet' ||
      'escaped' ||
      'xong' ||
      'harvested' ||
      'sold' ||
      'daban' ||
      'dathuhoach' =>
        empty,
      _ => null,
    };
  }
}

/// Nhóm hiển thị của một tình trạng cua — CHỈ 5 nhãn của [BoxStatus].
///
/// Bản sao của `mapCrabCondition` bên desktop. Nhờ nó mà nông dân chọn gì thì
/// huy hiệu hiện đúng chữ đó: chọn "Lột xác" thì huy hiệu "Lột xác", không còn
/// cảnh "Đang lột" trên huy hiệu nhưng "Lột xác" trên thẻ hộp.
///
/// `weak` (cua yếu / bỏ ăn) là "Cần theo dõi" — chưa phải sự cố, khớp với quy
/// ước "cần chú ý và yếu là một" của nông dân. `problem` (bệnh / cách ly /
/// mất tích) mới là "Cảnh báo".
BoxStatus displayStatusOf(CrabCondition? condition) => switch (condition) {
      null || CrabCondition.normal => BoxStatus.normal,
      CrabCondition.weak => BoxStatus.watch,
      CrabCondition.premolt ||
      CrabCondition.molting ||
      CrabCondition.softshell =>
        BoxStatus.molting,
      CrabCondition.problem => BoxStatus.alert,
      CrabCondition.empty => BoxStatus.empty,
    };

extension CrabConditionX on CrabCondition {
  /// Nhóm trạng thái để hiện nhãn + màu — dùng chung với thẻ hộp.
  BoxStatus get displayStatus => displayStatusOf(this);

  /// Key gửi lên BE — đúng bằng `CrabConditions.ToApi`.
  String get apiKey => switch (this) {
        CrabCondition.empty => '',
        CrabCondition.normal => 'normal',
        CrabCondition.premolt => 'premolt',
        CrabCondition.molting => 'molting',
        CrabCondition.softshell => 'softshell',
        CrabCondition.problem => 'problem',
        CrabCondition.weak => 'weak',
      };
}
