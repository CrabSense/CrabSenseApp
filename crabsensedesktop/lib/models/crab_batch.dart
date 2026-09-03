import 'package:flutter/material.dart';

import 'batch_status.dart';

class CrabBatch {
  CrabBatch({
    required this.id,
    this.name,
    required this.releaseDate,
    required this.initialQuantity,
    required this.aliveCount,
    required this.initialWeightGram,
    required this.avgWeightGram,
    required this.source,
    this.farmArea,
    this.pond,
    required this.status,
    this.notes,
    this.healthScore = 90,
    this.daysToHarvest = 30,
    this.revenueMillion = 0,
    this.cycleProgress = 0.5,
  });

  final String id;
  final String? name;
  final DateTime releaseDate;
  final int initialQuantity;
  final int aliveCount;
  final double initialWeightGram;
  final double avgWeightGram;
  final String source;
  final String? farmArea;
  final String? pond;
  final BatchStatus status;
  final String? notes;
  final int healthScore;
  final int daysToHarvest;
  final double revenueMillion;
  final double cycleProgress;

  int get deadCount => initialQuantity - aliveCount;

  double get survivalRate =>
      initialQuantity == 0 ? 0 : (aliveCount / initialQuantity) * 100;

  String get displayName => name?.isNotEmpty == true ? name! : id;

  CrabBatch copyWith({
    String? id,
    String? name,
    DateTime? releaseDate,
    int? initialQuantity,
    int? aliveCount,
    double? initialWeightGram,
    double? avgWeightGram,
    String? source,
    String? farmArea,
    String? pond,
    BatchStatus? status,
    String? notes,
    int? healthScore,
    int? daysToHarvest,
    double? revenueMillion,
    double? cycleProgress,
  }) {
    return CrabBatch(
      id: id ?? this.id,
      name: name ?? this.name,
      releaseDate: releaseDate ?? this.releaseDate,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      aliveCount: aliveCount ?? this.aliveCount,
      initialWeightGram: initialWeightGram ?? this.initialWeightGram,
      avgWeightGram: avgWeightGram ?? this.avgWeightGram,
      source: source ?? this.source,
      farmArea: farmArea ?? this.farmArea,
      pond: pond ?? this.pond,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      healthScore: healthScore ?? this.healthScore,
      daysToHarvest: daysToHarvest ?? this.daysToHarvest,
      revenueMillion: revenueMillion ?? this.revenueMillion,
      cycleProgress: cycleProgress ?? this.cycleProgress,
    );
  }
}

class BatchTimelineEvent {
  const BatchTimelineEvent({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isFuture = false,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isFuture;
}
