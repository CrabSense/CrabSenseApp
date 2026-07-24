import 'package:equatable/equatable.dart';

import '../../domain/entities/harvest.dart';

/// Base class for all Harvest BLoC states.
///
/// Requirements: 11.1–11.10
abstract class HarvestState extends Equatable {
  const HarvestState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class HarvestInitial extends HarvestState {
  const HarvestInitial();
}

/// Active form state holding inputs, validation errors, and submission status.
class HarvestFormState extends HarvestState {
  HarvestFormState({
    required this.boxId,
    required this.farmId,
    required this.totalWeightText,
    required this.crabCountText,
    required this.qualityGrade,
    required this.harvestDate,
    this.notes,
    this.photoPaths = const [],
    this.boxIdError,
    this.weightError,
    this.crabCountError,
    this.dateError,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.isOffline = false,
    this.submissionError,
    this.createdHarvest,
  });

  final String boxId;
  final String farmId;
  final String totalWeightText;
  final String crabCountText;
  final QualityGrade qualityGrade;
  final DateTime harvestDate;
  final String? notes;
  final List<String> photoPaths;

  final String? boxIdError;
  final String? weightError;
  final String? crabCountError;
  final String? dateError;

  final bool isSubmitting;
  final bool isSubmitted;
  final bool isOffline;
  final String? submissionError;
  final Harvest? createdHarvest;

  /// Maximum allowed photos attached to a harvest record.
  static const int maxPhotos = 5;

  /// Returns `true` if max photos limit (5) has been reached.
  bool get photosAtLimit => photoPaths.length >= maxPhotos;

  /// Parsed total weight as `double`, or `null` if invalid.
  double? get parsedTotalWeight => double.tryParse(totalWeightText.trim());

  /// Parsed crab count as `int`, or `null` if invalid.
  int? get parsedCrabCount => int.tryParse(crabCountText.trim());

  /// Calculated average weight per crab in kilograms.
  double get averageWeightPerCrab {
    final weight = parsedTotalWeight;
    final count = parsedCrabCount;
    if (weight != null && weight > 0 && count != null && count > 0) {
      return weight / count;
    }
    return 0.0;
  }

  /// Creates a copy of [HarvestFormState] with modified properties.
  HarvestFormState copyWith({
    String? boxId,
    String? farmId,
    String? totalWeightText,
    String? crabCountText,
    QualityGrade? qualityGrade,
    DateTime? harvestDate,
    String? notes,
    List<String>? photoPaths,
    String? boxIdError,
    String? weightError,
    String? crabCountError,
    String? dateError,
    bool? isSubmitting,
    bool? isSubmitted,
    bool? isOffline,
    String? submissionError,
    Harvest? createdHarvest,
    bool clearBoxIdError = false,
    bool clearWeightError = false,
    bool clearCrabCountError = false,
    bool clearDateError = false,
    bool clearSubmissionError = false,
  }) {
    return HarvestFormState(
      boxId: boxId ?? this.boxId,
      farmId: farmId ?? this.farmId,
      totalWeightText: totalWeightText ?? this.totalWeightText,
      crabCountText: crabCountText ?? this.crabCountText,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      harvestDate: harvestDate ?? this.harvestDate,
      notes: notes ?? this.notes,
      photoPaths: photoPaths ?? this.photoPaths,
      boxIdError: clearBoxIdError ? null : (boxIdError ?? this.boxIdError),
      weightError: clearWeightError ? null : (weightError ?? this.weightError),
      crabCountError: clearCrabCountError ? null : (crabCountError ?? this.crabCountError),
      dateError: clearDateError ? null : (dateError ?? this.dateError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isOffline: isOffline ?? this.isOffline,
      submissionError: clearSubmissionError ? null : (submissionError ?? this.submissionError),
      createdHarvest: createdHarvest ?? this.createdHarvest,
    );
  }

  @override
  List<Object?> get props => [
        boxId,
        farmId,
        totalWeightText,
        crabCountText,
        qualityGrade,
        harvestDate,
        notes,
        photoPaths,
        boxIdError,
        weightError,
        crabCountError,
        dateError,
        isSubmitting,
        isSubmitted,
        isOffline,
        submissionError,
        createdHarvest,
      ];
}

/// Error state when form loading fails.
class HarvestErrorState extends HarvestState {
  const HarvestErrorState({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
