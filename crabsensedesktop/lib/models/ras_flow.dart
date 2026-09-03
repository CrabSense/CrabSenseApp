import 'package:flutter/material.dart';

import 'crab_box.dart';



class RasFlowNodeLive {

  const RasFlowNodeLive({

    required this.id,

    required this.nodeCode,

    required this.displayLabel,

    required this.sortOrder,

    required this.nodeType,

    this.relayDeviceId,

    this.relayChannel,

    this.paramDefaultsJson,

    this.iconKey,

    required this.metricLabel,

    this.secondaryMetric,

    required this.hasRelay,

    this.isOn,

    this.isOnline,

    required this.connectionLabel,

    this.controlMode,

    this.alertMessage,

    this.powerW,

    this.currentA,

    this.voltageV,

    this.flowLpm,

    this.flowLph,

    this.tempC,

    this.levelPercent,

  });



  final String id;

  final String nodeCode;

  final String displayLabel;

  final int sortOrder;

  final String nodeType;

  final String? relayDeviceId;

  final String? relayChannel;

  final String? paramDefaultsJson;

  final String? iconKey;

  final String metricLabel;

  final String? secondaryMetric;

  final bool hasRelay;

  final bool? isOn;

  final bool? isOnline;

  final String connectionLabel;

  final String? controlMode;

  final String? alertMessage;

  final double? powerW;

  final double? currentA;

  final double? voltageV;

  final double? flowLpm;

  final double? flowLph;

  final double? tempC;

  final double? levelPercent;



  factory RasFlowNodeLive.fromJson(Map<String, dynamic> json) {

    return RasFlowNodeLive(

      id: '${json['id'] ?? json['Id']}',

      nodeCode: '${json['nodeCode'] ?? json['NodeCode']}',

      displayLabel: '${json['displayLabel'] ?? json['DisplayLabel']}',

      sortOrder: (json['sortOrder'] ?? json['SortOrder'] as num?)?.toInt() ?? 0,

      nodeType: '${json['nodeType'] ?? json['NodeType'] ?? 'equipment'}',

      relayDeviceId: (json['relayDeviceId'] ?? json['RelayDeviceId'])?.toString(),

      relayChannel: (json['relayChannel'] ?? json['RelayChannel'])?.toString(),

      paramDefaultsJson:

          (json['paramDefaultsJson'] ?? json['ParamDefaultsJson'])?.toString(),

      iconKey: (json['iconKey'] ?? json['IconKey'])?.toString(),

      metricLabel: '${json['metricLabel'] ?? json['MetricLabel'] ?? '—'}',

      secondaryMetric:

          (json['secondaryMetric'] ?? json['SecondaryMetric'])?.toString(),

      hasRelay: json['hasRelay'] ?? json['HasRelay'] ?? false,

      isOn: json['isOn'] ?? json['IsOn'] as bool?,

      isOnline: json['isOnline'] ?? json['IsOnline'] as bool?,

      connectionLabel:

          '${json['connectionLabel'] ?? json['ConnectionLabel'] ?? '—'}',

      controlMode: (json['controlMode'] ?? json['ControlMode'])?.toString(),

      alertMessage: (json['alertMessage'] ?? json['AlertMessage'])?.toString(),

      powerW: _dbl(json['powerW'] ?? json['PowerW']),

      currentA: _dbl(json['currentA'] ?? json['CurrentA']),

      voltageV: _dbl(json['voltageV'] ?? json['VoltageV']),

      flowLpm: _dbl(json['flowLpm'] ?? json['FlowLpm']),

      flowLph: _dbl(json['flowLph'] ?? json['FlowLph']) ??
          (_dbl(json['flowLpm'] ?? json['FlowLpm']) != null
              ? _dbl(json['flowLpm'] ?? json['FlowLpm'])! * 60
              : null),

      tempC: _dbl(json['tempC'] ?? json['TempC']),

      levelPercent: _dbl(json['levelPercent'] ?? json['LevelPercent']),

    );

  }



  static double? _dbl(dynamic v) =>

      v == null ? null : (v as num).toDouble();



  bool get isControllableOn => hasRelay && (isOn ?? false);

  bool get isEquipment =>
      nodeType == 'equipment' ||
      const {'drum', 'skimmer', 'bio', 'pump'}.contains(nodeCode);

  double? get displayFlowLph =>
      flowLph ?? (flowLpm != null ? flowLpm! * 60 : null);

  bool get showsElectrical =>
      const {'drum', 'skimmer', 'bio', 'pump'}.contains(nodeCode);

  /// Dòng A · V (realtime từ telemetry pin 7/6).
  String get electricalLabel {
    final parts = <String>[];
    if (currentA != null) parts.add('${currentA!.toStringAsFixed(2)} A');
    if (voltageV != null) parts.add('${voltageV!.toStringAsFixed(0)} V');
    return parts.join(' · ');
  }

  /// Nhãn metric dòng dưới (L/h, pH, …).
  String get displayMetric {
    if (displayFlowLph != null) {
      return '${displayFlowLph!.round()} L/h';
    }
    if (secondaryMetric != null && secondaryMetric!.isNotEmpty) {
      return secondaryMetric!;
    }
    if (metricLabel != '—') return metricLabel;
    return '';
  }

  String get cardSubMetric {
    final base = displayMetric;
    final elec = showsElectrical ? electricalLabel : '';
    if (elec.isEmpty) return base;
    if (base.isEmpty) return elec;
    return '$elec\n$base';
  }

  /// Chuyển sang [RasComponent] để dùng chung widget sơ đồ RAS.
  RasComponent toRasComponent() => RasComponent(
        name: displayLabel,
        metric: cardSubMetric,
        icon: icon,
        online: isOnline ?? connectionLabel == 'Online',
        powerWatts: showsElectrical ? powerW : null,
        currentAmps: showsElectrical ? currentA : null,
        voltageVolts: showsElectrical ? voltageV : null,
        hasControl: hasRelay,
        isOn: isOn ?? false,
        temperatureCelsius: tempC,
      );

  IconData get icon => switch (iconKey ?? nodeCode) {

        'crab_boxes' => Icons.grid_view,

        'drum' => Icons.filter_alt_outlined,

        'discharge_100' => Icons.water_drop_outlined,

        'skimmer' => Icons.air_outlined,

        'bio' => Icons.biotech_outlined,

        'sand_coral_200' => Icons.spa_outlined,

        'settling' => Icons.layers_outlined,

        'pump' => Icons.settings_input_component_outlined,

        _ => Icons.precision_manufacturing_outlined,

      };

}



class RasFlowDiagram {

  const RasFlowDiagram({

    required this.areaId,

    required this.areaCode,

    required this.areaName,

    required this.nodes,

    required this.totalPowerW,

    required this.runningCount,

    required this.controllableCount,

    required this.onlineCount,

  });



  final String areaId;

  final String areaCode;

  final String areaName;

  final List<RasFlowNodeLive> nodes;

  final double totalPowerW;

  final int runningCount;

  final int controllableCount;

  final int onlineCount;



  factory RasFlowDiagram.fromJson(Map<String, dynamic> json) {

    final list = json['nodes'] ?? json['Nodes'];

    return RasFlowDiagram(

      areaId: '${json['areaId'] ?? json['AreaId']}',

      areaCode: '${json['areaCode'] ?? json['AreaCode']}',

      areaName: '${json['areaName'] ?? json['AreaName']}',

      nodes: list is List

          ? list

              .map((e) => RasFlowNodeLive.fromJson(e as Map<String, dynamic>))

              .toList()

          : [],

      totalPowerW: (json['totalPowerW'] ?? json['TotalPowerW'] as num?)?.toDouble() ?? 0,

      runningCount:

          (json['runningCount'] ?? json['RunningCount'] as num?)?.toInt() ?? 0,

      controllableCount: (json['controllableCount'] ?? json['ControllableCount'] as num?)

              ?.toInt() ??

          0,

      onlineCount:

          (json['onlineCount'] ?? json['OnlineCount'] as num?)?.toInt() ?? 0,

    );

  }

}


