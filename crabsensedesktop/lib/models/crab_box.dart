import 'package:flutter/material.dart';

import 'box_status.dart';

class CrabBox {
  CrabBox({
    required this.id,
    required this.zone,
    required this.status,
    this.healthScore,
    this.crabId,
    this.batchId,
    this.releaseDate,
    this.weightGram,
    this.lastMoltDate,
    this.expectedHarvest,
    this.hasAlert = false,
  });

  final String id;
  final String zone;
  final BoxStatus status;
  final int? healthScore;
  final String? crabId;
  final String? batchId;
  final DateTime? releaseDate;
  final double? weightGram;
  final DateTime? lastMoltDate;
  final DateTime? expectedHarvest;
  final bool hasAlert;

  bool get isOccupied => status != BoxStatus.empty;
}

class RasComponent {
  const RasComponent({
    required this.name,
    required this.metric,
    required this.icon,
    this.online = true,
    this.powerWatts,
    this.currentAmps,
    this.voltageVolts,
    this.hasControl = false,
    this.isOn = true,
    this.temperatureCelsius,
  });

  final String name;
  final String metric;
  final IconData icon;
  final bool online;
  final double? powerWatts;
  final double? currentAmps;
  final double? voltageVolts;
  final bool hasControl;
  final bool isOn;
  final double? temperatureCelsius;

  bool get hasElectrical =>
      powerWatts != null || currentAmps != null || voltageVolts != null;
}
