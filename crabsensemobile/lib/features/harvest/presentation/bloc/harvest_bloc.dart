import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
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
    ApiClient? api,
  })  : _recordHarvest = recordHarvest,
        _api = api,
        super(const HarvestInitial()) {
    on<LoadHarvestForm>(_onLoadForm);
    on<HarvestKeepRaisingChanged>(_onKeepRaisingChanged);
    on<HarvestBoxIdChanged>(_onBoxIdChanged);
    on<HarvestFarmIdChanged>(_onFarmIdChanged);
    on<HarvestWeightChanged>(_onWeightChanged);
    on<HarvestCrabCountChanged>(_onCrabCountChanged);
    on<HarvestQualityGradeChanged>(_onQualityGradeChanged);
    on<HarvestDateChanged>(_onDateChanged);
    on<HarvestLengthChanged>(_onLengthChanged);
    on<HarvestWidthChanged>(_onWidthChanged);
    on<HarvestNotesChanged>(_onNotesChanged);
    on<AddHarvestPhoto>(_onAddPhoto);
    on<RemoveHarvestPhoto>(_onRemovePhoto);
    on<SubmitHarvest>(_onSubmit);
    on<ResetHarvestForm>(_onResetForm);
  }

  final RecordHarvestUseCase _recordHarvest;
  final ApiClient? _api;
  static const _uuid = Uuid();

  // ── Load Form ─────────────────────────────────────────────────────────────

  void _onLoadForm(LoadHarvestForm event, Emitter<HarvestState> emit) {
    emit(
      HarvestFormState(
        boxId: event.boxId ?? '',
        farmId: event.farmId ?? '',
        crabId: event.crabId,
        boxGuid: event.boxGuid,
        weightBefore: event.weightBefore,
        lengthBefore: event.lengthBefore,
        widthBefore: event.widthBefore,
        totalWeightText: '',
        crabCountText: '1',
        qualityGrade: QualityGrade.gradeA,
        harvestDate: DateTime.now(),
        notes: '',
        photoPaths: const [],
      ),
    );
  }

  // ── Field updates ─────────────────────────────────────────────────────────

  void _onKeepRaisingChanged(
    HarvestKeepRaisingChanged event,
    Emitter<HarvestState> emit,
  ) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(keepRaising: event.keepRaising));
  }

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

  void _onLengthChanged(HarvestLengthChanged event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(lengthText: event.lengthText));
  }

  void _onWidthChanged(HarvestWidthChanged event, Emitter<HarvestState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(widthText: event.widthText));
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
    final grams = s.parsedTotalWeight;
    if (grams == null || grams <= 0) {
      weightErr = 'Cân nặng sau lột phải lớn hơn 0';
      hasError = true;
    }
    final weightKg = grams == null ? null : grams / 1000;

    final count = s.parsedCrabCount ?? 1;
    if (count <= 0) {
      crabCountErr = 'Mỗi hộp một con';
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

    if (s.keepRaising) {
      await _submitKeepRaising(s, grams!, emit);
      return;
    }

    final harvest = Harvest(
      id: 'harvest-${_uuid.v4()}',
      boxId: s.boxId.trim(),
      farmId: s.farmId.trim().isEmpty ? 'default-farm' : s.farmId.trim(),
      totalWeight: weightKg!,
      crabCount: count,
      qualityGrade: s.qualityGrade,
      harvestDate: s.harvestDate,
      operatorId: event.operatorId,
      operatorName: event.operatorName,
      photoUrls: s.photoPaths,
      notes: s.notes?.trim().isEmpty == true ? null : s.notes?.trim(),
      createdAt: DateTime.now(),
      crabId: s.crabId?.trim(),
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

  Future<void> _submitKeepRaising(
    HarvestFormState s,
    double grams,
    Emitter<HarvestState> emit,
  ) async {
    final crabId = s.crabId?.trim() ?? '';
    if (crabId.isEmpty) {
      emit(s.copyWith(submissionError: 'Thiếu cua của hộp để ghi lột.'));
      return;
    }
    if (_api == null) {
      emit(s.copyWith(submissionError: 'Không gọi được máy chủ để ghi nuôi tiếp.'));
      return;
    }
    emit(s.copyWith(isSubmitting: true, clearSubmissionError: true));
    final notes = s.notes?.trim();
    final lengthMm = double.tryParse(s.lengthText.trim());
    final widthMm = double.tryParse(s.widthText.trim());
    final result = await _api.safePost<dynamic>(
      ApiConstants.crabMoltings(crabId),
      data: {
        'crabId': crabId,
        if (s.boxGuid != null && s.boxGuid!.isNotEmpty) 'boxId': s.boxGuid,
        'moltTime': s.harvestDate.toUtc().toIso8601String(),
        'weightAfterGram': grams,
        if (s.weightBefore != null) 'weightBeforeGram': s.weightBefore,
        if (s.lengthBefore != null) 'shellLengthBeforeMm': s.lengthBefore,
        if (s.widthBefore != null) 'shellWidthBeforeMm': s.widthBefore,
        if (lengthMm != null) 'shellLengthAfterMm': lengthMm,
        if (widthMm != null) 'shellWidthAfterMm': widthMm,
        'result': 'success',
        'source': 'manual',
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    if (result.failure != null) {
      emit(s.copyWith(isSubmitting: false, submissionError: result.failure!.message));
      return;
    }
    emit(s.copyWith(isSubmitting: false, isSubmitted: true));
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _onResetForm(ResetHarvestForm event, Emitter<HarvestState> emit) {
    emit(
      HarvestFormState(
        boxId: '',
        farmId: '',
        totalWeightText: '',
        crabCountText: '1',
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
