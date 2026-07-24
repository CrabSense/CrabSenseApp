import 'package:equatable/equatable.dart';

import '../../domain/entities/harvest.dart';
import '../../domain/entities/harvest_summary.dart';

/// Base class for all [HarvestHistoryBloc] states.
///
/// Requirements: 11.9, 11.10
abstract class HarvestHistoryState extends Equatable {
  const HarvestHistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class HarvestHistoryInitial extends HarvestHistoryState {
  const HarvestHistoryInitial();
}

/// Loading state when fetching history or summary records.
class HarvestHistoryLoading extends HarvestHistoryState {
  const HarvestHistoryLoading();
}

/// State representing successfully loaded harvest history and summary statistics.
class HarvestHistoryLoaded extends HarvestHistoryState {
  const HarvestHistoryLoaded({
    required this.harvests,
    this.summary,
    this.weeklyCumulativeWeights = const {},
    this.startDate,
    this.endDate,
    this.farmId,
    this.qualityGrade,
    this.isExporting = false,
    this.exportedFilePath,
    this.exportMessage,
  });

  /// Filtered list of harvest records
  final List<Harvest> harvests;

  /// Aggregated harvest metrics summary
  final HarvestSummary? summary;

  /// Map of week label (e.g., "Jul 14 - Jul 20") to cumulative harvest weight (kg)
  final Map<String, double> weeklyCumulativeWeights;

  /// Start date of current date filter
  final DateTime? startDate;

  /// End date of current date filter
  final DateTime? endDate;

  /// Farm filter identifier
  final String? farmId;

  /// Quality grade filter
  final QualityGrade? qualityGrade;

  /// True when CSV export is in progress
  final bool isExporting;

  /// File path of exported CSV file upon success
  final String? exportedFilePath;

  /// Status or message regarding export action
  final String? exportMessage;

  /// Creates a copy of [HarvestHistoryLoaded] with updated fields.
  HarvestHistoryLoaded copyWith({
    List<Harvest>? harvests,
    HarvestSummary? summary,
    Map<String, double>? weeklyCumulativeWeights,
    DateTime? startDate,
    DateTime? endDate,
    String? farmId,
    QualityGrade? qualityGrade,
    bool? isExporting,
    String? exportedFilePath,
    String? exportMessage,
    bool clearExportMessage = false,
    bool clearExportedFilePath = false,
    bool clearFarmId = false,
    bool clearQualityGrade = false,
  }) {
    return HarvestHistoryLoaded(
      harvests: harvests ?? this.harvests,
      summary: summary ?? this.summary,
      weeklyCumulativeWeights: weeklyCumulativeWeights ?? this.weeklyCumulativeWeights,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      farmId: clearFarmId ? null : (farmId ?? this.farmId),
      qualityGrade: clearQualityGrade ? null : (qualityGrade ?? this.qualityGrade),
      isExporting: isExporting ?? this.isExporting,
      exportedFilePath: clearExportedFilePath ? null : (exportedFilePath ?? this.exportedFilePath),
      exportMessage: clearExportMessage ? null : (exportMessage ?? this.exportMessage),
    );
  }

  @override
  List<Object?> get props => [
        harvests,
        summary,
        weeklyCumulativeWeights,
        startDate,
        endDate,
        farmId,
        qualityGrade,
        isExporting,
        exportedFilePath,
        exportMessage,
      ];
}

/// Failure state when loading history or summary fails.
class HarvestHistoryError extends HarvestHistoryState {
  const HarvestHistoryError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
