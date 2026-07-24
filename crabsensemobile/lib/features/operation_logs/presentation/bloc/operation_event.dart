import 'package:image_picker/image_picker.dart' show ImagePicker;

import '../../../authentication/domain/entities/user.dart';
import '../../domain/entities/operation_log.dart';
import '../../domain/entities/operation_type.dart';

/// Base class for all Operation BLoC events.
///
/// Requirements: 10.1–10.10
abstract class OperationEvent {
  const OperationEvent();
}


/// Loads / initialises the operation log form.
///
/// When [existingLog] is non-null the form opens in edit mode,
/// pre-filling all fields from the provided log. When null the
/// form opens in create mode with sensible defaults.
class LoadOperationForm extends OperationEvent {
  const LoadOperationForm({this.existingLog, this.initialBoxId});

  /// Existing log to edit, or null for create mode.
  final OperationLog? existingLog;

  /// Optional box id to prefill in create mode.
  final String? initialBoxId;
}

/// Fired when the user changes the [OperationType] dropdown.
class OperationTypeChanged extends OperationEvent {
  const OperationTypeChanged({required this.type});

  final OperationType type;
}

/// Fired when the user edits the raw box-ID input field.
///
/// [rawInput] is the comma-separated string exactly as the user typed it.
class OperationBoxIdsChanged extends OperationEvent {
  const OperationBoxIdsChanged({required this.rawInput});

  final String rawInput;
}

/// Fired when the user changes the operation timestamp via the
/// date/time picker.
class OperationTimestampChanged extends OperationEvent {
  const OperationTimestampChanged({required this.timestamp});

  final DateTime timestamp;
}

/// Fired when the user edits the quantity text field.
class OperationQuantityChanged extends OperationEvent {
  const OperationQuantityChanged({required this.value});

  final String value;
}

/// Fired when the user edits the unit text field.
class OperationUnitChanged extends OperationEvent {
  const OperationUnitChanged({required this.unit});

  final String unit;
}

/// Fired when the user edits the notes text field.
class OperationNotesChanged extends OperationEvent {
  const OperationNotesChanged({required this.notes});

  final String notes;
}

/// Fired when the user attaches a new photo.
///
/// [photoPath] is the local file path returned by [ImagePicker].
class AddOperationPhoto extends OperationEvent {
  const AddOperationPhoto({required this.photoPath});

  final String photoPath;
}

/// Fired when the user removes a photo by index.
class RemoveOperationPhoto extends OperationEvent {
  const RemoveOperationPhoto({required this.index});

  final int index;
}

/// Fired when the user presses Submit.
///
/// [operatorId] and [operatorName] are sourced from the currently
/// authenticated user and injected by the screen widget.
/// Optional [userRole] enforces Field_Operator role or higher (Requirement 10.10).
class SubmitOperationLog extends OperationEvent {
  const SubmitOperationLog({
    required this.operatorId,
    required this.operatorName,
    this.userRole,
  });

  final String operatorId;
  final String operatorName;
  final UserRole? userRole;
}

