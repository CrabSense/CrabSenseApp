import 'package:equatable/equatable.dart';

/// Represents a single farm option in the farm/pond filter UI.
///
/// Used by [FarmPondFilterWidget] to populate the farm dropdown.
///
/// Requirements: 8.9
class FarmOption extends Equatable {
  const FarmOption({required this.id, required this.name, this.ponds = const []});

  /// Unique identifier for the farm.
  final String id;

  /// Human-readable display name for the farm.
  final String name;

  /// Ponds belonging to this farm.
  final List<PondOption> ponds;

  @override
  List<Object?> get props => [id, name, ponds];
}

/// Represents a single pond option within a farm in the filter UI.
///
/// Used by [FarmPondFilterWidget] to populate the pond dropdown.
///
/// Requirements: 8.9
class PondOption extends Equatable {
  const PondOption({required this.id, required this.name});

  /// Unique identifier for the pond.
  final String id;

  /// Human-readable display name for the pond.
  final String name;

  @override
  List<Object?> get props => [id, name];
}
