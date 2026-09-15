import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

/// Trạng thái cua Owner trên card hộp.
/// Quy ước màu: lột (sắp lột / đang lột / lột mềm) = tím, nguy cơ (có vấn đề /
/// cua yếu) = đỏ, bình thường = xanh, chết hoặc đã bán = trống hộp.
enum CrabCondition {
  empty,
  normal,
  premolt,
  molting,
  softshell,
  problem,
  weak,
}

extension CrabConditionX on CrabCondition {
  String get label => switch (this) {
        CrabCondition.empty => 'Trống',
        CrabCondition.normal => 'Bình thường',
        CrabCondition.premolt => 'Sắp lột',
        CrabCondition.molting => 'Đang lột',
        CrabCondition.softshell => 'Cua lột mềm',
        CrabCondition.problem => 'Có vấn đề',
        CrabCondition.weak => 'Cua yếu',
      };

  String get emoji => switch (this) {
        CrabCondition.empty => '⚪',
        CrabCondition.normal => '🟢',
        CrabCondition.premolt => '🟣',
        CrabCondition.molting => '🟣',
        CrabCondition.softshell => '🟣',
        CrabCondition.problem => '🔴',
        CrabCondition.weak => '🔴',
      };

  Color get color => switch (this) {
        CrabCondition.empty => DashboardColors.textMuted,
        CrabCondition.normal => DashboardColors.healthy,
        CrabCondition.premolt => DashboardColors.moltPurple,
        CrabCondition.molting => DashboardColors.moltPurple,
        CrabCondition.softshell => DashboardColors.moltPurple,
        CrabCondition.problem => DashboardColors.risk,
        CrabCondition.weak => DashboardColors.risk,
      };

  static CrabCondition parse({
    String? condition,
    String? moltingStage,
    String? crabStatus,
    required bool hasCrab,
  }) {
    final key = (condition ?? '').trim().toLowerCase();
    switch (key) {
      case 'empty':
        return CrabCondition.empty;
      case 'normal':
        return CrabCondition.normal;
      case 'premolt':
        return CrabCondition.premolt;
      case 'molting':
        return CrabCondition.molting;
      case 'softshell':
        return CrabCondition.softshell;
      case 'problem':
        return CrabCondition.problem;
      case 'weak':
        return CrabCondition.weak;
      // Cua chết / đã bán ⇒ BE trả hộp về trống.
      case 'dead' || 'harvested' || 'sold':
        return CrabCondition.empty;
    }
    if (!hasCrab) return CrabCondition.empty;

    final status = (crabStatus ?? '').trim().toLowerCase();
    if (status == 'dead' || status == 'harvested' || status == 'sold') {
      return CrabCondition.empty;
    }
    if (status == 'missing' || status == 'quarantined') {
      return CrabCondition.problem;
    }
    if (status == 'molting') return CrabCondition.molting;

    final stage = (moltingStage ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '');
    return switch (stage) {
      'premolt' || 'pre' => CrabCondition.premolt,
      'molting' || 'molt' => CrabCondition.molting,
      'softshell' || 'soft' || 'postmolt' || 'post' => CrabCondition.softshell,
      _ => CrabCondition.normal,
    };
  }
}

enum BoxOccupancyFilter { all, occupied, empty, alert }

extension BoxOccupancyFilterX on BoxOccupancyFilter {
  String get label => switch (this) {
        BoxOccupancyFilter.all => 'Tất cả',
        BoxOccupancyFilter.occupied => 'Có cua',
        BoxOccupancyFilter.empty => 'Trống',
        BoxOccupancyFilter.alert => 'Có cảnh báo',
      };
}

enum CrabConditionFilter {
  all,
  normal,
  premolt,
  molting,
  softshell,
  problem,
  weak,
}

extension CrabConditionFilterX on CrabConditionFilter {
  String get label => switch (this) {
        CrabConditionFilter.all => 'Tất cả cua',
        CrabConditionFilter.normal => 'Bình thường',
        CrabConditionFilter.premolt => 'Sắp lột',
        CrabConditionFilter.molting => 'Đang lột',
        CrabConditionFilter.softshell => 'Cua lột mềm',
        CrabConditionFilter.problem => 'Có vấn đề',
        CrabConditionFilter.weak => 'Cua yếu',
      };

  CrabCondition? get condition => switch (this) {
        CrabConditionFilter.all => null,
        CrabConditionFilter.normal => CrabCondition.normal,
        CrabConditionFilter.premolt => CrabCondition.premolt,
        CrabConditionFilter.molting => CrabCondition.molting,
        CrabConditionFilter.softshell => CrabCondition.softshell,
        CrabConditionFilter.problem => CrabCondition.problem,
        CrabConditionFilter.weak => CrabCondition.weak,
      };
}
