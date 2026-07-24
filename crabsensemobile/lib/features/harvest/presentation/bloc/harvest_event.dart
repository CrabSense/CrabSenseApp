import 'package:equatable/equatable.dart';

import '../../../authentication/domain/entities/user.dart';
import '../../domain/entities/harvest.dart';

/// Base class for all Harvest BLoC events.
///
/// Requirements: 11.1–11.10
abstract class HarvestEvent extends Equatable {
  const HarvestEvent();

  @override
  List<Object?> get props => [];
}

/// Loads / initializes the harvest form.
///
/// Pre-fills [boxId] or [farmId] if provided (e.g. opened from box details context).
class LoadHarvestForm extends HarvestEvent {
  const LoadHarvestForm({this.boxId, this.farmId});

  final String? boxId;
  final String? farmId;

  @override
  List<Object?> get props => [boxId, farmId];
}

/// Fired when the box ID input changes.
class HarvestBoxIdChanged extends HarvestEvent {
  const HarvestBoxIdChanged({required this.boxId});

  final String boxId;

  @override
  List<Object?> get props => [boxId];
}

/// Fired when the farm ID input changes.
class HarvestFarmIdChanged extends HarvestEvent {
  const HarvestFarmIdChanged({required this.farmId});

  final String farmId;

  @override
  List<Object?> get props => [farmId];
}

/// Fired when the total weight text changes.
class HarvestWeightChanged extends HarvestEvent {
  const HarvestWeightChanged({required this.weightText});

  final String weightText;

  @override
  List<Object?> get props => [weightText];
}

/// Fired when the crab count text changes.
class HarvestCrabCountChanged extends HarvestEvent {
  const HarvestCrabCountChanged({required this.crabCountText});

  final String crabCountText;

  @override
  List<Object?> get props => [crabCountText];
}

/// Fired when the selected quality grade changes.
class HarvestQualityGradeChanged extends HarvestEvent {
  const HarvestQualityGradeChanged({required this.qualityGrade});

  final QualityGrade qualityGrade;

  @override
  List<Object?> get props => [qualityGrade];
}

/// Fired when the harvest date changes.
class HarvestDateChanged extends HarvestEvent {
  const HarvestDateChanged({required this.harvestDate});

  final DateTime harvestDate;

  @override
  List<Object?> get props => [harvestDate];
}

/// Fired when notes text changes.
class HarvestNotesChanged extends HarvestEvent {
  const HarvestNotesChanged({required this.notes});

  final String notes;

  @override
  List<Object?> get props => [notes];
}

/// Fired when a photo is added.
class AddHarvestPhoto extends HarvestEvent {
  const AddHarvestPhoto({required this.photoPath});

  final String photoPath;

  @override
  List<Object?> get props => [photoPath];
}

/// Fired when a photo is removed by index.
class RemoveHarvestPhoto extends HarvestEvent {
  const RemoveHarvestPhoto({required this.index});

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Fired when user submits the harvest form.
class SubmitHarvest extends HarvestEvent {
  const SubmitHarvest({
    required this.operatorId,
    required this.operatorName,
    this.userRole,
  });

  final String operatorId;
  final String operatorName;
  final UserRole? userRole;

  @override
  List<Object?> get props => [operatorId, operatorName, userRole];
}

/// Fired to reset the harvest form state.
class ResetHarvestForm extends HarvestEvent {
  const ResetHarvestForm();
}
