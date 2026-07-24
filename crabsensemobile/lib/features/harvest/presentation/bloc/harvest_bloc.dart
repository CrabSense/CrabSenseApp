import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/harvest.dart';
import '../../domain/usecases/record_harvest_usecase.dart';
import 'harvest_event.dart';
import 'harvest_state.dart';

/// BLoC for managing harvest recording form state and submission logic.
///
/// Event → State transitions:
/// - [LoadHarvestForm]          → [HarvestFormState] (initialized with pre-filled or default values)
/// - [HarvestBoxIdChanged]      → [HarvestFormState] (boxId updated, boxIdError cleared)
/// - [HarvestFarmIdChanged]     → [HarvestFormState] (farmId updated)
/// - [HarvestWeightChanged]     → [HarvestFormState] (totalWeightText updated, weightError cleared)
/// - [HarvestCrabCountChanged]  → [HarvestFormState] (crabCountText updated, crabCountError cleared)
/// - [HarvestQualityGradeChanged]→ [HarvestFormState] (qualityGrade updated)
/// - [HarvestDateChanged]       → [HarvestFormState] (harvestDate updated, dateError cleared)
/// - [HarvestNotesChanged]      → [HarvestFormState] (notes updated)
/// - [AddHarvestPhoto]          → [HarvestFormState] (photo appended, max 5 photos)
/// - [RemoveHarvestPhoto]       → [HarvestFormState] (photo removed at index)
/// - [SubmitHarvest]            → [HarvestFormState](isSubmitting: true)
///                                → [HarvestFormState](isSubmitted: true) on success or offline save
///                                → [HarvestFormState](submissionError) on failure
/// - [ResetHarvestForm]         → [HarvestFormState] (reset to default initial form)
///
/// Requirements: 11.1–11.10
class HarvestBloc extends Bloc<HarvestEvent, HarvestState> {
  HarvestBloc({
    required RecordHarvestUseCase recordHarvest,
  })  : _recordHarvest = recordHarvest,
        super(const HarvestInitial()) {
    on<LoadHarvestForm>(_onLoadForm);
    on<HarvestBoxIdChanged>(_onBoxIdChanged);
    on<HarvestFarmIdChanged>(_onFarmIdChanged);
    on<HarvestWeightChanged>(_onWeightChanged);
    on<HarvestCrabCountChanged>(_onCrabCountChanged);
    on<HarvestQualityGradeChanged>(_onQualityGradeChanged);
    on<HarvestDateChanged>(_onDateChanged);
    on<HarvestNotesChanged>(_onNotesChanged);
    on<AddHarvestPhoto>(_onAddPhoto);
    on<RemoveHarvestPhoto>(_onRemovePhoto);
    on<SubmitHarvest>(_onSubmit);
    on<ResetHarvestForm>(_onResetForm);
  }

  final RecordHarvestUseCase _recordHarvest;
  static const _uuid = Uuid();

  // ── Load Form ─────────────────────────────────────────────────────────────

  void _onLoadForm(LoadHarvestForm event, Emitter<HarvestState> emit) {
    emit(
      HarvestFormState(
        boxId: event.boxId ?? '',
        farmId: event.farmId ?? '',
        totalWeightText: '',
        crabCountText: '',
        qualityGrade: QualityGrade.gradeA,
        harvestDate: DateTime.now(),
        notes: '',
        photoPaths: const [],
      ),
    );
  }

  // ── Field updates ─────────────────────────────────────────────────────────

  void _onBoxIdChanged(HarvestBoxIdChanged event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(boxId: event.boxId, clearBoxIdError: true));
  }

  void _onFarmIdChanged(HarvestFarmIdChanged event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(farmId: event.farmId));
  }

  void _onWeightChanged(HarvestWeightChanged event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(totalWeightText: event.weightText, clearWeightError: true));
  }

  void _onCrabCountChanged(HarvestCrabCountChanged event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(crabCountText: event.crabCountText, clearCrabCountError: true));
  }

  void _onQualityGradeChanged(HarvestQualityGradeChanged event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(qualityGrade: event.qualityGrade));
  }

  void _onDateChanged(HarvestDateChanged event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(harvestDate: event.harvestDate, clearDateError: true));
  }

  void _onNotesChanged(HarvestNotesChanged event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(notes: event.notes));
  }

  // ── Photos ────────────────────────────────────────────────────────────────

  void _onAddPhoto(AddHarvestPhoto event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null || s.photosAtLimit) return;
    emit(s.copyWith(photoPaths: [...s.photoPaths, event.photoPath]));
  }

  void _onRemovePhoto(RemoveHarvestPhoto event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    if (event.index < 0 || event.index >= s.photoPaths.length) return;
    final updated = List<String>.from(s.photoPaths)..removeAt(event.index);
    emit(s.copyWith(photoPaths: updated));
  }

  // ── Form submission ───────────────────────────────────────────────────────

  Future<void> _onSubmit(SubmitHarvest event, Emitter<HarvestState> emit) async {
    final s = _formState;
    if (s == null) return;

    bool hasError = false;
    String? boxIdErr;
    String? weightErr;
    String? crabCountErr;
    String? dateErr;

    // Validate Box ID (Requirement 11.1)
    if (s.boxId.trim().isEmpty) {
      boxIdErr = 'Box selection is required';
      hasError = true;
    }

    // Validate total weight > 0 (Requirement 11.3)
    final weight = s.parsedTotalWeight;
    if (weight == null || weight <= 0) {
      weightErr = 'Total weight must be a positive number';
      hasError = true;
    }

    // Validate crab count > 0 (Requirement 11.2)
    final count = s.parsedCrabCount;
    if (count == null || count <= 0) {
      crabCountErr = 'Crab count must be at least 1';
      hasError = true;
    }

    // Validate harvest date not in future (Requirement 11.2)
    if (s.harvestDate.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      dateErr = 'Harvest date cannot be in the future';
      hasError = true;
    }

    if (hasError) {
      emit(
        s.copyWith(
          boxIdError: boxIdErr,
          weightError: weightErr,
          crabCountError: crabCountErr,
          dateError: dateErr,
        ),
      );
      return;
    }

    final harvest = Harvest(
      id: 'harvest-${_uuid.v4()}',
      boxId: s.boxId.trim(),
      farmId: s.farmId.trim().isEmpty ? 'default-farm' : s.farmId.trim(),
      totalWeight: weight!,
      crabCount: count!,
      qualityGrade: s.qualityGrade,
      harvestDate: s.harvestDate,
      operatorId: event.operatorId,
      operatorName: event.operatorName,
      photoUrls: s.photoPaths,
      notes: s.notes?.trim().isEmpty == true ? null : s.notes?.trim(),
      createdAt: DateTime.now(),
    );

    emit(s.copyWith(isSubmitting: true, clearSubmissionError: true));

    final result = await _recordHarvest(
      RecordHarvestParams(
        harvest: harvest,
        userRole: event.userRole,
      ),
    );

    result.fold(
      (failure) {
        if (failure is NetworkFailure) {
          // Offline-first: saved to local queue
          emit(
            s.copyWith(
              isSubmitting: false,
              isSubmitted: true,
              isOffline: true,
              createdHarvest: harvest,
            ),
          );
        } else {
          emit(
            s.copyWith(
              isSubmitting: false,
              submissionError: failure.message,
            ),
          );
        }
      },
      (savedHarvest) {
        emit(
          s.copyWith(
            isSubmitting: false,
            isSubmitted: true,
            createdHarvest: savedHarvest,
          ),
        );
      },
    );
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _onResetForm(ResetHarvestForm event, Emitter<HarvestState> emit) {
    emit(
      HarvestFormState(
        boxId: '',
        farmId: '',
        totalWeightText: '',
        crabCountText: '',
        qualityGrade: QualityGrade.gradeA,
        harvestDate: DateTime.now(),
        notes: '',
        photoPaths: const [],
      ),
    );
  }

  /// Helper getter to access current state as [HarvestFormState], or null.
  HarvestFormState? get _formState =>
      state is HarvestFormState ? state as HarvestFormState : null;
}
