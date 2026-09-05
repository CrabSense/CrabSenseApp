import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

/// Trạng thái cua Owner trên card hộp.
enum CrabCondition {
  empty,
  normal,
  premolt,
  molting,
  softshell,
  problem,
}

extension CrabConditionX on CrabCondition {
  String get label => switch (this) {
        CrabCondition.empty => 'Trống',
        CrabCondition.normal => 'Bình thường',
        CrabCondition.premolt => 'Sắp lột',
        CrabCondition.molting => 'Đang lột',
        CrabCondition.softshell => 'Cua lột mềm',
        CrabCondition.problem => 'Có vấn đề',
      };

  String get emoji => switch (this) {
        CrabCondition.empty => '⚪',
        CrabCondition.normal => '🟢',
        CrabCondition.premolt => '🟡',
        CrabCondition.molting => '🔵',
        CrabCondition.softshell => '🟣',
        CrabCondition.problem => '🔴',
      };

  Color get color => switch (this) {
        CrabCondition.empty => DashboardColors.textMuted,
        CrabCondition.normal => DashboardColors.healthy,
        CrabCondition.premolt => DashboardColors.warning,
        CrabCondition.molting => DashboardColors.oceanBlue,
        CrabCondition.softshell => DashboardColors.purple,
        CrabCondition.problem => DashboardColors.risk,
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
    }
    if (!hasCrab) return CrabCondition.empty;

    final status = (crabStatus ?? '').trim().toLowerCase();
    if (status == 'dead' ||
        status == 'missing' ||
        status == 'quarantined' ||
        status == 'harvested') {
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
}

extension CrabConditionFilterX on CrabConditionFilter {
  String get label => switch (this) {
        CrabConditionFilter.all => 'Tất cả cua',
        CrabConditionFilter.normal => 'Bình thường',
        CrabConditionFilter.premolt => 'Sắp lột',
        CrabConditionFilter.molting => 'Đang lột',
        CrabConditionFilter.softshell => 'Cua lột mềm',
        CrabConditionFilter.problem => 'Có vấn đề',
      };

  CrabCondition? get condition => switch (this) {
        CrabConditionFilter.all => null,
        CrabConditionFilter.normal => CrabCondition.normal,
        CrabConditionFilter.premolt => CrabCondition.premolt,
        CrabConditionFilter.molting => CrabCondition.molting,
        CrabConditionFilter.softshell => CrabCondition.softshell,
        CrabConditionFilter.problem => CrabCondition.problem,
      };
}
