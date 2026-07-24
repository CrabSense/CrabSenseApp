// ignore_for_file: lines_longer_than_80_chars

import 'package:equatable/equatable.dart';

import '../../domain/entities/operation_type.dart';
import 'operation_event.dart' show LoadOperationForm;

/// Base class for all Operation BLoC states.
///
/// Requirements: 10.1–10.10
abstract class OperationState extends Equatable {
  const OperationState();

  @override
  List<Object?> get props => [];
}

/// Emitted before [LoadOperationForm] is processed.
class OperationInitial extends OperationState {
  const OperationInitial();
}

/// The main form state — emitted once [LoadOperationForm] is handled and
/// updated in response to every subsequent field-change event.
///
/// All UI rendering is driven by this single state class.
class OperationFormState extends OperationState {
  const OperationFormState({
    required this.selectedType,
    required this.rawBoxInput,
    required this.timestamp,
    required this.quantityText,
    required this.unit,
    required this.notes,
    required this.photoPaths,
    required this.isSubmitting,
    required this.isSubmitted,
    required this.isOffline,
    required this.isEditMode,
    this.existingLogId,
    this.submissionError,
    this.boxIdsError,
    this.quantityError,
  });

  /// The currently selected operation type.
  final OperationType selectedType;

  /// Raw comma-separated box IDs as typed by the user.
  final String rawBoxInput;

  /// When the operation was (or will be) performed.
  final DateTime timestamp;

  /// Quantity as the user typed it (may be empty).
  final String quantityText;

  /// Unit string (e.g. "kg", "L").
  final String unit;

  /// Optional operator notes.
  final String notes;

  /// Local file paths of attached photos (not yet uploaded).
  final List<String> photoPaths;

  /// True while the create/update use-case call is in flight.
  final bool isSubmitting;

  /// True after a successful (or offline) submission.
  final bool isSubmitted;

  /// True when the device is offline at submission time.
  final bool isOffline;

  /// True when the form was opened to edit an existing log.
  final bool isEditMode;

  /// Non-null in edit mode — the ID of the log being edited.
  final String? existingLogId;

  /// Non-null when the most recent submission attempt produced an error.
  final String? submissionError;

  /// Validation error for the box IDs field.
  final String? boxIdsError;

  /// Validation error for the quantity field.
  final String? quantityError;

  // ── Derived helpers ────────────────────────────────────────────────────

  /// True when the photo limit (5) has been reached.
  bool get photosAtLimit => photoPaths.length >= 5;

  /// True when the current operation type involves a quantity.
  bool get showQuantityField => selectedType.hasQuantity;

  /// True when the form may be submitted (no in-flight request, not
  /// already submitted, and at least one box ID has been entered).
  bool get canSubmit => !isSubmitting && !isSubmitted && _hasValidBoxIds;

  bool get _hasValidBoxIds => rawBoxInput.trim().isNotEmpty;

  /// Returns the parsed list of box IDs from [rawBoxInput].
  ///
  /// Splits on commas, trims whitespace, and removes blank entries.
  List<String> get parsedBoxIds =>
      rawBoxInput.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  // ── copyWith ───────────────────────────────────────────────────────────

  OperationFormState copyWith({
    OperationType? selectedType,
    String? rawBoxInput,
    DateTime? timestamp,
    String? quantityText,
    String? unit,
    String? notes,
    List<String>? photoPaths,
    bool? isSubmitting,
    bool? isSubmitted,
    bool? isOffline,
    bool? isEditMode,
    String? existingLogId,
    // Passing null explicitly clears the error fields.
    Object? submissionError = _sentinel,
    Object? boxIdsError = _sentinel,
    Object? quantityError = _sentinel,
  }) => OperationFormState(
    selectedType: selectedType ?? this.selectedType,
    rawBoxInput: rawBoxInput ?? this.rawBoxInput,
    timestamp: timestamp ?? this.timestamp,
    quantityText: quantityText ?? this.quantityText,
    unit: unit ?? this.unit,
    notes: notes ?? this.notes,
    photoPaths: photoPaths ?? this.photoPaths,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isSubmitted: isSubmitted ?? this.isSubmitted,
    isOffline: isOffline ?? this.isOffline,
    isEditMode: isEditMode ?? this.isEditMode,
    existingLogId: existingLogId ?? this.existingLogId,
    submissionError: submissionError == _sentinel
        ? this.submissionError
        : submissionError as String?,
    boxIdsError: boxIdsError == _sentinel ? this.boxIdsError : boxIdsError as String?,
    quantityError: quantityError == _sentinel ? this.quantityError : quantityError as String?,
  );

  @override
  List<Object?> get props => [
    selectedType,
    rawBoxInput,
    timestamp,
    quantityText,
    unit,
    notes,
    photoPaths,
    isSubmitting,
    isSubmitted,
    isOffline,
    isEditMode,
    existingLogId,
    submissionError,
    boxIdsError,
    quantityError,
  ];
}

// Sentinel object used by copyWith to distinguish "not provided" from null.
const _sentinel = Object();

/// Emitted when a fatal error prevents the form from loading.
class OperationError extends OperationState {
  const OperationError({required this.message, this.isOffline = false});

  final String message;
  final bool isOffline;

  @override
  List<Object?> get props => [message, isOffline];
}
