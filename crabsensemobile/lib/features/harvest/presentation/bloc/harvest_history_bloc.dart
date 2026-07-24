import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/harvest.dart';
import '../../domain/entities/harvest_summary.dart';
import '../../domain/usecases/get_harvest_history_usecase.dart';
import '../../domain/usecases/get_harvest_summary_usecase.dart';
import '../utils/harvest_csv_exporter.dart';
import 'harvest_history_event.dart';
import 'harvest_history_state.dart';

/// BLoC for managing Harvest History list, filterable date range, summary statistics,
/// weekly cumulative weight calculation per farm, and CSV export functionality.
///
/// Requirements: 11.9, 11.10
class HarvestHistoryBloc extends Bloc<HarvestHistoryEvent, HarvestHistoryState> {
  HarvestHistoryBloc({
    required GetHarvestHistoryUseCase getHarvestHistory,
    required GetHarvestSummaryUseCase getHarvestSummary,
  })  : _getHarvestHistory = getHarvestHistory,
        _getHarvestSummary = getHarvestSummary,
        super(const HarvestHistoryInitial()) {
    on<LoadHarvestHistory>(_onLoadHistory);
    on<FilterDateRangeChanged>(_onDateRangeChanged);
    on<FilterFarmIdChanged>(_onFarmIdChanged);
    on<FilterQualityGradeChanged>(_onGradeChanged);
    on<ExportHarvestHistoryToCsv>(_onExportToCsv);
  }

  final GetHarvestHistoryUseCase _getHarvestHistory;
  final GetHarvestSummaryUseCase _getHarvestSummary;

  Future<void> _onLoadHistory(
    LoadHarvestHistory event,
    Emitter<HarvestHistoryState> emit,
  ) async {
    emit(const HarvestHistoryLoading());
    await _fetchData(
      emit: emit,
      startDate: event.startDate,
      endDate: event.endDate,
      farmId: event.farmId,
      boxId: event.boxId,
      qualityGrade: event.qualityGrade,
    );
  }

  Future<void> _onDateRangeChanged(
    FilterDateRangeChanged event,
    Emitter<HarvestHistoryState> emit,
  ) async {
    final current = state;
    String? farmId;
    QualityGrade? grade;
    if (current is HarvestHistoryLoaded) {
      farmId = current.farmId;
      grade = current.qualityGrade;
    }

    emit(const HarvestHistoryLoading());
    await _fetchData(
      emit: emit,
      startDate: event.startDate,
      endDate: event.endDate,
      farmId: farmId,
      qualityGrade: grade,
    );
  }

  Future<void> _onFarmIdChanged(
    FilterFarmIdChanged event,
    Emitter<HarvestHistoryState> emit,
  ) async {
    final current = state;
    DateTime? startDate;
    DateTime? endDate;
    QualityGrade? grade;
    if (current is HarvestHistoryLoaded) {
      startDate = current.startDate;
      endDate = current.endDate;
      grade = current.qualityGrade;
    }

    emit(const HarvestHistoryLoading());
    await _fetchData(
      emit: emit,
      startDate: startDate,
      endDate: endDate,
      farmId: event.farmId,
      qualityGrade: grade,
    );
  }

  Future<void> _onGradeChanged(
    FilterQualityGradeChanged event,
    Emitter<HarvestHistoryState> emit,
  ) async {
    final current = state;
    DateTime? startDate;
    DateTime? endDate;
    String? farmId;
    if (current is HarvestHistoryLoaded) {
      startDate = current.startDate;
      endDate = current.endDate;
      farmId = current.farmId;
    }

    emit(const HarvestHistoryLoading());
    await _fetchData(
      emit: emit,
      startDate: startDate,
      endDate: endDate,
      farmId: farmId,
      qualityGrade: event.qualityGrade,
    );
  }

  Future<void> _onExportToCsv(
    ExportHarvestHistoryToCsv event,
    Emitter<HarvestHistoryState> emit,
  ) async {
    final current = state;
    if (current is! HarvestHistoryLoaded) return;

    emit(current.copyWith(isExporting: true, clearExportMessage: true, clearExportedFilePath: true));

    try {
      final file = await HarvestCsvExporter.exportToCsvFile(current.harvests);
      emit(
        current.copyWith(
          isExporting: false,
          exportedFilePath: file.path,
          exportMessage: 'Successfully exported ${current.harvests.length} harvest records to CSV.',
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isExporting: false,
          exportMessage: 'Failed to export CSV: ${e.toString()}',
        ),
      );
    }
  }

  /// Internal helper to fetch history & summary and compute weekly cumulative weight.
  Future<void> _fetchData({
    required Emitter<HarvestHistoryState> emit,
    DateTime? startDate,
    DateTime? endDate,
    String? farmId,
    String? boxId,
    QualityGrade? qualityGrade,
  }) async {
    final historyResult = await _getHarvestHistory(
      GetHarvestHistoryParams(
        startDate: startDate,
        endDate: endDate,
        farmId: farmId,
        boxId: boxId,
        qualityGrade: qualityGrade,
      ),
    );

    await historyResult.fold(
      (failure) async {
        emit(HarvestHistoryError(message: failure.message));
      },
      (harvests) async {
        // Calculate cumulative weekly harvest weight per farm (Requirement 11.10)
        final weeklyWeights = _calculateWeeklyCumulativeWeights(harvests);

        // Fetch summary if farmId is provided or compute fallback summary
        HarvestSummary? summary;
        if (farmId != null && farmId.isNotEmpty) {
          final summaryResult = await _getHarvestSummary(
            GetHarvestSummaryParams(
              farmId: farmId,
              startDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
              endDate: endDate ?? DateTime.now(),
            ),
          );
          summaryResult.fold(
            (_) => summary = _buildSummaryFromList(harvests, farmId: farmId, startDate: startDate, endDate: endDate),
            (s) => summary = s,
          );
        } else {
          summary = _buildSummaryFromList(harvests, farmId: farmId ?? 'All Farms', startDate: startDate, endDate: endDate);
        }

        emit(
          HarvestHistoryLoaded(
            harvests: harvests,
            summary: summary,
            weeklyCumulativeWeights: weeklyWeights,
            startDate: startDate,
            endDate: endDate,
            farmId: farmId,
            qualityGrade: qualityGrade,
          ),
        );
      },
    );
  }

  /// Calculates cumulative harvest weight per farm per week (Requirement 11.10).
  /// Returns a map of formatted week label -> total weight in kg.
  Map<String, double> _calculateWeeklyCumulativeWeights(List<Harvest> harvests) {
    final Map<DateTime, double> weekStartMap = {};

    for (final harvest in harvests) {
      final date = harvest.harvestDate;
      // Normalise to start of week (Monday)
      final startOfWeek = DateTime(date.year, date.month, date.day).subtract(
        Duration(days: date.weekday - 1),
      );

      weekStartMap[startOfWeek] = (weekStartMap[startOfWeek] ?? 0.0) + harvest.totalWeight;
    }

    // Sort weeks chronologically
    final sortedWeeks = weekStartMap.keys.toList()..sort();
    final Map<String, double> formattedMap = {};
    final dateFormat = DateFormat('MMM dd');

    for (final start in sortedWeeks) {
      final end = start.add(const Duration(days: 6));
      final label = '${dateFormat.format(start)} - ${dateFormat.format(end)}';
      formattedMap[label] = weekStartMap[start]!;
    }

    return formattedMap;
  }

  /// Helper to build fallback summary metrics from loaded harvests.
  HarvestSummary _buildSummaryFromList(
    List<Harvest> harvests, {
    required String farmId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    double totalWeight = 0.0;
    int totalCrabs = 0;
    final Map<QualityGrade, double> gradeBreakdown = {};

    for (final h in harvests) {
      totalWeight += h.totalWeight;
      totalCrabs += h.crabCount;
      gradeBreakdown[h.qualityGrade] = (gradeBreakdown[h.qualityGrade] ?? 0.0) + h.totalWeight;
    }

    final start = startDate ?? (harvests.isNotEmpty ? harvests.last.harvestDate : DateTime.now());
    final end = endDate ?? DateTime.now();

    return HarvestSummary(
      farmId: farmId,
      farmName: farmId == 'All Farms' ? 'All Farms' : null,
      startDate: start,
      endDate: end,
      totalWeight: totalWeight,
      totalCrabCount: totalCrabs,
      totalHarvestsCount: harvests.length,
      gradeBreakdown: gradeBreakdown,
    );
  }
}
