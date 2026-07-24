import 'package:equatable/equatable.dart';

import '../../../box/domain/entities/box_enums.dart';
import 'bloc.dart' show InspectionBloc;
import 'inspection_bloc.dart' show InspectionBloc;

/// Base class for all inspection form events.
///
/// Events represent user actions or system triggers that cause state
/// changes in [InspectionBloc].
///
/// Requirements: 7.1-7.10
abstract class InspectionEvent extends Equatable {
  const InspectionEvent();

  @override
  List<Object?> get props => [];
}

/// Loads AI detection context for comparison at the top of the form.
///
/// When [videoId] is null the form is shown without AI comparison.
///
/// Requirement 7.1
class LoadInspectionContext extends InspectionEvent {
  const LoadInspectionContext({required this.boxId, this.videoId});

  /// Box identifier this inspection is for.
  final String boxId;

  /// Optional video identifier to load AI results for comparison.
  final String? videoId;

  @override
  List<Object?> get props => [boxId, videoId];
}

/// User changed the molting status dropdown value.
///
/// Requirement 7.2
class UpdateMoltingStatus extends InspectionEvent {
  const UpdateMoltingStatus({required this.status});

  final MoltingStatus status;

  @override
  List<Object?> get props => [status];
}

/// User changed the health condition dropdown value.
///
/// Requirement 7.2
class UpdateHealthStatus extends InspectionEvent {
  const UpdateHealthStatus({required this.status});

  final HealthStatus status;

  @override
  List<Object?> get props => [status];
}

/// User typed a weight value in the weight input field.
///
/// [value] is the raw text string for validation purposes.
///
/// Requirement 7.2
class UpdateWeight extends InspectionEvent {
  const UpdateWeight({required this.value});

  /// Raw text input — may not be a valid number yet.
  final String value;

  @override
  List<Object?> get props => [value];
}

/// User typed content in the notes text area.
///
/// Requirement 7.2
class UpdateNotes extends InspectionEvent {
  const UpdateNotes({required this.notes});

  final String notes;

  @override
  List<Object?> get props => [notes];
}

/// User captured or selected a photo for documentation.
///
/// [photoPath] is the local file-system path to the image.
///
/// Requirement 7.3
class AddPhoto extends InspectionEvent {
  const AddPhoto({required this.photoPath});

  final String photoPath;

  @override
  List<Object?> get props => [photoPath];
}

/// User tapped the remove button on a photo thumbnail.
///
/// Requirement 7.3
class RemovePhoto extends InspectionEvent {
  const RemovePhoto({required this.index});

  final int index;

  @override
  List<Object?> get props => [index];
}

/// User tapped the Submit Inspection button.
///
/// Requirements: 7.4-7.7, 7.9
class SubmitInspection extends InspectionEvent {
  const SubmitInspection({
    required this.boxId,
    required this.operatorId,
    required this.operatorName,
  });

  final String boxId;
  final String operatorId;
  final String operatorName;

  @override
  List<Object?> get props => [boxId, operatorId, operatorName];
}

/// User tapped the Correct or Incorrect feedback button for AI results.
///
/// Requirements: 7.5, 7.8
class SubmitAiFeedback extends InspectionEvent {
  const SubmitAiFeedback({
    required this.videoId,
    required this.inspectionId,
    required this.isCorrect,
    required this.operatorId,
  });

  /// The AI-analysis video being reviewed.
  final String videoId;

  /// The inspection record this feedback relates to.
  final String inspectionId;

  /// Whether the operator confirms the AI result was correct.
  final bool isCorrect;

  /// The operator's user ID for attribution (Requirement 7.9).
  final String operatorId;

  @override
  List<Object?> get props => [videoId, inspectionId, isCorrect, operatorId];
}

/// Loads the AI agreement rate for a box.
///
/// Dispatched after a successful inspection submission so the UI can
/// display how often the operator has agreed with AI results (Req 7.8).
class LoadAgreementRate extends InspectionEvent {
  const LoadAgreementRate({required this.boxId});

  final String boxId;

  @override
  List<Object?> get props => [boxId];
}

/// Resets the form to its initial state.
class ResetInspectionForm extends InspectionEvent {
  const ResetInspectionForm();
}
