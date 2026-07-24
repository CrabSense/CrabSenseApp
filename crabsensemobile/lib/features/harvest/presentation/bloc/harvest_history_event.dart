import 'package:equatable/equatable.dart';

import '../../domain/entities/harvest.dart';

/// Base class for all [HarvestHistoryBloc] events.
///
/// Requirements: 11.9, 11.10
abstract class HarvestHistoryEvent extends Equatable {
  const HarvestHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Loads harvest history and summary data with optional filters.
class LoadHarvestHistory extends HarvestHistoryEvent {
  const LoadHarvestHistory({
    this.startDate,
    this.endDate,
    this.farmId,
    this.boxId,
    this.qualityGrade,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? farmId;
  final String? boxId;
  final QualityGrade? qualityGrade;

  @override
  List<Object?> get props => [startDate, endDate, farmId, boxId, qualityGrade];
}

/// Event triggered when user selects a new date range filter.
class FilterDateRangeChanged extends HarvestHistoryEvent {
  const FilterDateRangeChanged({
    required this.startDate,
    required this.endDate,
  });

  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event triggered when user changes farm ID filter.
class FilterFarmIdChanged extends HarvestHistoryEvent {
  const FilterFarmIdChanged({this.farmId});

  final String? farmId;

  @override
  List<Object?> get props => [farmId];
}

/// Event triggered when user changes quality grade filter.
class FilterQualityGradeChanged extends HarvestHistoryEvent {
  const FilterQualityGradeChanged({this.qualityGrade});

  final QualityGrade? qualityGrade;

  @override
  List<Object?> get props => [qualityGrade];
}

/// Event triggered to export filtered harvest records to a CSV file.
class ExportHarvestHistoryToCsv extends HarvestHistoryEvent {
  const ExportHarvestHistoryToCsv();
}
