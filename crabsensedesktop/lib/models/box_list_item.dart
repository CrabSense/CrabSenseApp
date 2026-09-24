import 'crab_condition.dart';
import 'production_models.dart';

enum BoxUiStatus { occupied, empty, maintenance, locked, offline }

enum BoxHealthUi { none, healthy, monitoring, weak, alert }

enum BoxStatusFilter { all, occupied, empty, maintenance, locked, offline }

enum BoxHealthFilter { all, healthy, monitoring, weak, alert, empty }

enum BoxListSort { newest, codeAz, codeZa, mostAlerts, watchFirst, emptyFirst }

class BoxListItem {
  const BoxListItem({
    required this.box,
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    required this.rowId,
    required this.rowCode,
    required this.rowName,
    this.deviceOnline = 0,
    this.deviceTotal = 0,
    this.cameraOnline,
  });

  final BoxRecord box;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String rowId;
  final String rowCode;
  final String rowName;
  final int deviceOnline;
  final int deviceTotal;
  final bool? cameraOnline;

  String get displayName => box.title;

  String get placeLabel {
    final khu = areaName.trim().isEmpty ? areaCode : areaName;
    final day = rowName.trim().isEmpty ? rowCode : rowName;
    return '$khu • $day';
  }

  bool get hasCrab => box.hasCrab;

  bool get hasAlert => box.alertCount > 0;

  DateTime? get updatedAt => box.aiUpdatedAt ?? box.crabInBoxSince ?? box.emptySince;

  bool get isStale {
    final at = updatedAt;
    if (at == null) return false;
    return DateTime.now().difference(at).inHours >= 24;
  }

  CrabCondition get crabCondition => CrabConditionX.parse(
        condition: box.crabCondition,
        moltingStage: box.crabMoltingStage,
        crabStatus: box.crabStatus,
        hasCrab: hasCrab,
      );

  BoxUiStatus get uiStatus {
    final s = box.status.trim().toLowerCase();
    if (s == 'offline' || s == 'disconnected') return BoxUiStatus.offline;
    if (s == 'locked') return BoxUiStatus.locked;
    if (s == 'maintenance') return BoxUiStatus.maintenance;
    if (deviceTotal > 0 && deviceOnline == 0 && s != 'active' && !hasCrab) {
      if (s == 'offline') return BoxUiStatus.offline;
    }
    if (!hasCrab) return BoxUiStatus.empty;
    return BoxUiStatus.occupied;
  }

  BoxHealthUi get healthUi {
    if (!hasCrab) return BoxHealthUi.none;
    final raw = '${box.crabCondition ?? ''} ${box.crabStatus ?? ''}'.toLowerCase();
    if (raw.contains('alert') || raw.contains('crit') || raw.contains('danger')) {
      return BoxHealthUi.alert;
    }
    if (raw.contains('weak') ||
        raw.contains('disease') ||
        raw.contains('stress') ||
        raw.contains('problem') ||
        raw.contains('atrisk') ||
        raw.contains('at-risk')) {
      return BoxHealthUi.weak;
    }
    if (raw.contains('monitor') || raw.contains('watch')) {
      return BoxHealthUi.monitoring;
    }
    final cond = crabCondition;
    if (cond == CrabCondition.weak || cond == CrabCondition.problem) {
      return BoxHealthUi.weak;
    }
    return BoxHealthUi.healthy;
  }

  bool get canAddCrab =>
      uiStatus == BoxUiStatus.empty && !hasCrab;

  BoxListItem withDevices({
    required int online,
    required int total,
    bool? cameraOnline,
  }) {
    return BoxListItem(
      box: box,
      areaId: areaId,
      areaCode: areaCode,
      areaName: areaName,
      rowId: rowId,
      rowCode: rowCode,
      rowName: rowName,
      deviceOnline: online,
      deviceTotal: total,
      cameraOnline: cameraOnline,
    );
  }
}
