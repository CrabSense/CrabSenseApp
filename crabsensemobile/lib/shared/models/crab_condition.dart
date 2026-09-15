import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tình trạng cua — NGUỒN DUY NHẤT cho nhãn + màu.
///
/// Dùng chung cho lưới hộp, chú giải, phiếu chăm sóc và chi tiết cua để các nơi
/// không còn lệch nhau. Key khớp `CrabConditions` của BE và enum cùng tên của
/// app desktop.
///
/// Quy ước màu: lột (sắp lột / đang lột / lột mềm) = tím,
/// nguy cơ (có vấn đề / cua yếu) = đỏ, bình thường = xanh lá.
/// Cua chết / đã bán / đã thu hoạch ⇒ BE trả hộp về trống.
enum CrabCondition {
  empty,
  normal,
  premolt,
  molting,
  softshell,
  problem,
  weak;

  /// Các mức nông dân được phép đánh dấu (không gồm [empty]).
  ///
  /// Đặt trong thân enum chứ không trong extension: thành viên `static` của
  /// extension không gọi được qua tên enum.
  static const List<CrabCondition> selectable = [
    normal,
    premolt,
    molting,
    softshell,
    problem,
    weak,
  ];

  /// Đọc key bất kỳ từ API/BE về enum. Không nhận ra ⇒ trả `null` để nơi gọi
  /// tự chọn màu dự phòng (lưới hộp rơi về màu theo điểm sức khỏe hộp).
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
      // dữ liệu đã ghi sai trước đây hiện đúng là "có vấn đề" chứ không phải
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
      // Cua chết / đã bán / đã thu hoạch ⇒ hộp coi như trống.
      'dead' || 'chet' || 'harvested' || 'sold' || 'daban' || 'dathuhoach' =>
        empty,
      _ => null,
    };
  }
}

extension CrabConditionX on CrabCondition {
  /// Nhãn hiển thị cho nông dân — giữ đúng bộ chữ của app desktop.
  String get label => switch (this) {
        CrabCondition.empty => 'Trống',
        CrabCondition.normal => 'Bình thường',
        CrabCondition.premolt => 'Sắp lột',
        CrabCondition.molting => 'Đang lột',
        CrabCondition.softshell => 'Cua lột mềm',
        CrabCondition.problem => 'Có vấn đề',
        CrabCondition.weak => 'Cua yếu',
      };

  /// Màu tô viền thẻ hộp, chấm chú giải và chip tình trạng.
  Color get color => switch (this) {
        CrabCondition.empty => CrabSenseColors.textHint,
        CrabCondition.normal => CrabSenseColors.success,
        CrabCondition.premolt ||
        CrabCondition.molting ||
        CrabCondition.softshell =>
          CrabSenseColors.molt,
        CrabCondition.problem || CrabCondition.weak => CrabSenseColors.danger,
      };

  /// Nền nhạt cùng tông để chữ trên thẻ hộp không chọi màu.
  Color get background => switch (this) {
        CrabCondition.empty => CrabSenseColors.surfaceAlt,
        CrabCondition.normal => CrabSenseColors.successLight,
        CrabCondition.premolt ||
        CrabCondition.molting ||
        CrabCondition.softshell =>
          CrabSenseColors.moltLight,
        CrabCondition.problem ||
        CrabCondition.weak =>
          CrabSenseColors.dangerLight,
      };

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
