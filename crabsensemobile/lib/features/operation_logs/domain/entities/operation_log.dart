import 'operation_type.dart';

/// Represents a farm operation record in the CrabSense system.
///
/// An OperationLog captures a specific activity performed on one or more
/// boxes (e.g., feeding, water change, medication). It is created by a
/// Field Operator or higher and can be edited within 24 hours of creation.
///
/// This is a pure domain entity with no external dependencies.
/// All fields are immutable (final); use [copyWith] to create modified copies.
///
/// Requirements: 10.1-10.10
class OperationLog {
  const OperationLog({
    required this.id,
    required this.type,
    required this.boxIds,
    required this.notes,
    required this.photoUrls,
    required this.timestamp,
    required this.operatorId,
    required this.operatorName,
    this.quantity,
    this.unit,
  });

  /// Unique identifier for the operation log
  final String id;

  /// The type of farm operation performed
  final OperationType type;

  /// List of box identifiers this operation was performed on.
  /// Must contain at least one box ID (Requirement 10.4).
  final List<String> boxIds;

  /// Optional quantity or amount used in the operation
  /// (e.g., amount of feed in grams, litres of water changed)
  final double? quantity;

  /// Optional unit for [quantity] (e.g., 'kg', 'L', 'mg')
  final String? unit;

  /// Optional notes or observations about the operation
  final String notes;

  /// List of photo attachment URLs for documentation (Requirement 10.5).
  /// May be empty if no photos were taken.
  final List<String> photoUrls;

  /// Timestamp when the operation was performed.
  /// Auto-filled on creation but editable by the operator (Requirement 10.3).
  final DateTime timestamp;

  /// Identifier of the operator who created this log
  final String operatorId;

  /// Display name of the operator who created this log
  final String operatorName;

  /// Returns true if this log can still be edited.
  ///
  /// Editing is allowed within 24 hours of the [timestamp]
  /// (Requirement 10.9).
  bool get isEditable {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return timestamp.isAfter(cutoff);
  }

  /// Returns the age of this operation log since it was recorded.
  Duration get age => DateTime.now().difference(timestamp);

  /// Creates a copy of this operation log with the given fields replaced.
  OperationLog copyWith({
    String? id,
    OperationType? type,
    List<String>? boxIds,
    double? quantity,
    String? unit,
    String? notes,
    List<String>? photoUrls,
    DateTime? timestamp,
    String? operatorId,
    String? operatorName,
  }) => OperationLog(
    id: id ?? this.id,
    type: type ?? this.type,
    boxIds: boxIds ?? this.boxIds,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    notes: notes ?? this.notes,
    photoUrls: photoUrls ?? this.photoUrls,
    timestamp: timestamp ?? this.timestamp,
    operatorId: operatorId ?? this.operatorId,
    operatorName: operatorName ?? this.operatorName,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OperationLog) return false;
    return other.id == id &&
        other.type == type &&
        other.notes == notes &&
        other.quantity == quantity &&
        other.unit == unit &&
        other.timestamp == timestamp &&
        other.operatorId == operatorId &&
        other.operatorName == operatorName;
  }

  @override
  int get hashCode =>
      Object.hash(id, type, notes, quantity, unit, timestamp, operatorId, operatorName);

  @override
  String toString() =>
      'OperationLog(id: $id, type: ${type.displayName}, '
      'boxIds: $boxIds, quantity: $quantity, unit: $unit, '
      'notes: $notes, timestamp: $timestamp, '
      'operatorId: $operatorId, operatorName: $operatorName)';
}
