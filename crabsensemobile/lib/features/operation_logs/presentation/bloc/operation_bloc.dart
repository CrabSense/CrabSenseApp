// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/operation_log.dart';
import '../../domain/entities/operation_type.dart';
import '../../domain/usecases/create_operation_log_usecase.dart';
import '../../domain/usecases/update_operation_log_usecase.dart';
import 'operation_event.dart';
import 'operation_state.dart';

/// BLoC for the Operation Log create/edit form.
///
/// Event → State transitions:
/// - [LoadOperationForm]         → [OperationFormState] (pre-filled or defaults)
///                                 [OperationError] if log is no longer editable
/// - [OperationTypeChanged]      → [OperationFormState] (type updated)
/// - [OperationBoxIdsChanged]    → [OperationFormState] (rawBoxInput updated)
/// - [OperationTimestampChanged] → [OperationFormState] (timestamp updated)
/// - [OperationQuantityChanged]  → [OperationFormState] (quantityText updated)
/// - [OperationUnitChanged]      → [OperationFormState] (unit updated)
/// - [OperationNotesChanged]     → [OperationFormState] (notes updated)
/// - [AddOperationPhoto]         → [OperationFormState] (photo appended, max 5)
/// - [RemoveOperationPhoto]      → [OperationFormState] (photo removed)
/// - [SubmitOperationLog]        → [OperationFormState](isSubmitting:true)
///                                 → [OperationFormState](isSubmitted:true) on success
///                                 → [OperationFormState](submissionError) on failure
///
/// Requirements: 10.1–10.10
class OperationBloc extends Bloc<OperationEvent, OperationState> {
  OperationBloc({required this._createOperationLog, required this._updateOperationLog})
    : super(const OperationInitial()) {
    on<LoadOperationForm>(_onLoadForm);
    on<OperationTypeChanged>(_onTypeChanged);
    on<OperationBoxIdsChanged>(_onBoxIdsChanged);
    on<OperationTimestampChanged>(_onTimestampChanged);
    on<OperationQuantityChanged>(_onQuantityChanged);
    on<OperationUnitChanged>(_onUnitChanged);
    on<OperationNotesChanged>(_onNotesChanged);
    on<AddOperationPhoto>(_onAddPhoto);
    on<RemoveOperationPhoto>(_onRemovePhoto);
    on<SubmitOperationLog>(_onSubmit);
  }

  final CreateOperationLogUseCase _createOperationLog;
  final UpdateOperationLogUseCase _updateOperationLog;

  static const _uuid = Uuid();

  // ── LoadOperationForm ──────────────────────────────────────────────────

  void _onLoadForm(LoadOperationForm event, Emitter<OperationState> emit) {
    final existing = event.existingLog;

    if (existing == null) {
      // Create mode — emit default form state.
      emit(
        OperationFormState(
          selectedType: OperationType.feeding,
          rawBoxInput: event.initialBoxId?.trim() ?? '',
          timestamp: DateTime.now(),
          quantityText: '',
          unit: '',
          notes: '',
          photoPaths: const [],
          isSubmitting: false,
          isSubmitted: false,
          isOffline: false,
          isEditMode: false,
        ),
      );
      return;
    }

    // Edit mode — validate the 24-hour editing window first.
    if (!existing.isEditable) {
      emit(
        const OperationError(
          message: 'This operation log can no longer be edited (24-hour window has expired)',
        ),
      );
      return;
    }

    emit(
      OperationFormState(
        selectedType: existing.type,
        rawBoxInput: existing.boxIds.join(', '),
        timestamp: existing.timestamp,
        quantityText: existing.quantity?.toString() ?? '',
        unit: existing.unit ?? '',
        notes: existing.notes,
        photoPaths: List<String>.from(existing.photoUrls),
        isSubmitting: false,
        isSubmitted: false,
        isOffline: false,
        isEditMode: true,
        existingLogId: existing.id,
      ),
    );
  }

  // ── Field-update events ────────────────────────────────────────────────

  void _onTypeChanged(OperationTypeChanged event, Emitter<OperationState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(selectedType: event.type));
  }

  void _onBoxIdsChanged(OperationBoxIdsChanged event, Emitter<OperationState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(rawBoxInput: event.rawInput, boxIdsError: null));
  }

  void _onTimestampChanged(OperationTimestampChanged event, Emitter<OperationState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(timestamp: event.timestamp));
  }

  void _onQuantityChanged(OperationQuantityChanged event, Emitter<OperationState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(quantityText: event.value, quantityError: null));
  }

  void _onUnitChanged(OperationUnitChanged event, Emitter<OperationState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(unit: event.unit));
  }

  void _onNotesChanged(OperationNotesChanged event, Emitter<OperationState> emit) {
    final s = _formState;
    if (s == null) return;
    emit(s.copyWith(notes: event.notes));
  }

  // ── Photo management ───────────────────────────────────────────────────

  void _onAddPhoto(AddOperationPhoto event, Emitter<OperationState> emit) {
    final s = _formState;
    if (s == null) return;
    if (s.photosAtLimit) return; // max 5 photos
    emit(s.copyWith(photoPaths: [...s.photoPaths, event.photoPath]));
  }

  void _onRemovePhoto(RemoveOperationPhoto event, Emitter<OperationState> emit) {
    final s = _formState;
    if (s == null) return;
    final updated = List<String>.from(s.photoPaths)..removeAt(event.index);
    emit(s.copyWith(photoPaths: updated));
  }

  // ── SubmitOperationLog ─────────────────────────────────────────────────

  Future<void> _onSubmit(SubmitOperationLog event, Emitter<OperationState> emit) async {
    final s = _formState;
    if (s == null) return;

    // --- Validate: box IDs must be non-empty ---
    if (s.parsedBoxIds.isEmpty) {
      emit(s.copyWith(boxIdsError: 'Please enter at least one box ID'));
      return;
    }

    // --- Validate: quantity (if applicable) ---
    double? quantity;
    if (s.showQuantityField && s.quantityText.isNotEmpty) {
      quantity = double.tryParse(s.quantityText);
      if (quantity == null) {
        emit(s.copyWith(quantityError: 'Enter a valid number'));
        return;
      }
    }

    // --- Build the OperationLog entity ---
    final log = OperationLog(
      id: s.isEditMode ? (s.existingLogId ?? _uuid.v4()) : _uuid.v4(),
      type: s.selectedType,
      boxIds: s.parsedBoxIds,
      notes: s.notes,
      photoUrls: s.photoPaths,
      timestamp: s.timestamp,
      operatorId: event.operatorId,
      operatorName: event.operatorName,
      quantity: quantity,
      unit: s.unit.trim().isEmpty ? null : s.unit.trim(),
    );

    emit(s.copyWith(isSubmitting: true, submissionError: null));

    final result = s.isEditMode
        ? await _updateOperationLog(
            UpdateOperationLogParams(log: log, userRole: event.userRole),
          )
        : await _createOperationLog(
            CreateOperationLogParams(log: log, userRole: event.userRole),
          );

    result.fold(
      (failure) {
        final isOffline = failure is NetworkFailure;
        if (isOffline) {
          // Offline-first: the repo already saved locally; treat as success.
          emit(
            s.copyWith(
              isSubmitting: false,
              isSubmitted: true,
              isOffline: true,
              submissionError: null,
            ),
          );
        } else {
          emit(s.copyWith(isSubmitting: false, submissionError: failure.message));
        }
      },
      (_) {
        emit(s.copyWith(isSubmitting: false, isSubmitted: true));
      },
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Returns the current state cast to [OperationFormState], or null.
  OperationFormState? get _formState =>
      state is OperationFormState ? state as OperationFormState : null;
}
