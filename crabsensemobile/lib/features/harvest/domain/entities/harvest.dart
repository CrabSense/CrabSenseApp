/// Quality grade assigned to harvested crabs based on physical and health condition.
///
/// Requirement 11.2
enum QualityGrade {
  /// Grade A: Premium quality crab (intact shell, high weight, healthy condition)
  gradeA,

  /// Grade B: Standard quality crab (minor shell imperfections, medium weight)
  gradeB,

  /// Grade C: Lower quality crab (soft shell or weight below standard)
  gradeC;

  /// Human-readable display label for UI rendering.
  String get displayName {
    switch (this) {
      case QualityGrade.gradeA:
        return 'Grade A';
      case QualityGrade.gradeB:
        return 'Grade B';
      case QualityGrade.gradeC:
        return 'Grade C';
    }
  }

  /// Parses string representation to [QualityGrade].
  /// Defaults to [QualityGrade.gradeA] if unrecognized.
  static QualityGrade fromString(String val) {
    switch (val.trim().toUpperCase()) {
      case 'GRADE_A':
      case 'GRADEA':
      case 'GRADE A':
      case 'A':
        return QualityGrade.gradeA;
      case 'GRADE_B':
      case 'GRADEB':
      case 'GRADE B':
      case 'B':
        return QualityGrade.gradeB;
      case 'GRADE_C':
      case 'GRADEC':
      case 'GRADE C':
      case 'C':
        return QualityGrade.gradeC;
      default:
        return QualityGrade.gradeA;
    }
  }

  /// Returns string code suitable for API / database serialization.
  String toCode() {
    switch (this) {
      case QualityGrade.gradeA:
        return 'GRADE_A';
      case QualityGrade.gradeB:
        return 'GRADE_B';
      case QualityGrade.gradeC:
        return 'GRADE_C';
    }
  }
}

/// Domain entity representing a harvest record in the CrabSense system.
///
/// Captures harvest data including total weight, crab count, quality grade,
/// box location, photo attachments, and operator details.
///
/// Pure domain model with immutable properties.
///
/// Requirements: 11.1-11.10
class Harvest {
  const Harvest({
    required this.id,
    required this.boxId,
    required this.farmId,
    required this.totalWeight,
    required this.crabCount,
    required this.qualityGrade,
    required this.harvestDate,
    required this.operatorId,
    required this.operatorName,
    this.photoUrls = const [],
    this.notes,
    this.createdAt,
    this.isSynced = false,
  });

  /// Unique record identifier
  final String id;

  /// Identifier of the box harvested from (Requirement 11.1)
  final String boxId;

  /// Identifier of the farm where the harvest occurred (Requirement 11.10)
  final String farmId;

  /// Total harvested weight in kilograms (Requirement 11.2, must be positive)
  final double totalWeight;

  /// Number of crabs harvested (Requirement 11.2, must be positive)
  final int crabCount;

  /// Assessed quality grade (Requirement 11.2)
  final QualityGrade qualityGrade;

  /// Date and time when the harvest occurred (Requirement 11.2)
  final DateTime harvestDate;

  /// Identifier of the operator who recorded the harvest (Requirement 11.5)
  final String operatorId;

  /// Display name of the operator (Requirement 11.5)
  final String operatorName;

  /// List of photo attachment URLs for harvested crabs (Requirement 11.6)
  final List<String> photoUrls;

  /// Optional notes or observations
  final String? notes;

  /// Server timestamp when created
  final DateTime? createdAt;

  /// Offline synchronization indicator
  final bool isSynced;

  /// Average weight per crab in kilograms.
  double get averageWeightPerCrab => crabCount > 0 ? totalWeight / crabCount : 0.0;

  /// Creates a copy of this harvest record with updated fields.
  Harvest copyWith({
    String? id,
    String? boxId,
    String? farmId,
    double? totalWeight,
    int? crabCount,
    QualityGrade? qualityGrade,
    DateTime? harvestDate,
    String? operatorId,
    String? operatorName,
    List<String>? photoUrls,
    String? notes,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return Harvest(
      id: id ?? this.id,
      boxId: boxId ?? this.boxId,
      farmId: farmId ?? this.farmId,
      totalWeight: totalWeight ?? this.totalWeight,
      crabCount: crabCount ?? this.crabCount,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      harvestDate: harvestDate ?? this.harvestDate,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      photoUrls: photoUrls ?? this.photoUrls,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Harvest) return false;
    return other.id == id &&
        other.boxId == boxId &&
        other.farmId == farmId &&
        other.totalWeight == totalWeight &&
        other.crabCount == crabCount &&
        other.qualityGrade == qualityGrade &&
        other.harvestDate == harvestDate &&
        other.operatorId == operatorId &&
        other.operatorName == operatorName &&
        other.notes == notes &&
        other.isSynced == isSynced;
  }

  @override
  int get hashCode => Object.hash(
        id,
        boxId,
        farmId,
        totalWeight,
        crabCount,
        qualityGrade,
        harvestDate,
        operatorId,
        operatorName,
        notes,
        isSynced,
      );

  @override
  String toString() {
    return 'Harvest(id: $id, boxId: $boxId, farmId: $farmId, '
        'totalWeight: ${totalWeight}kg, crabCount: $crabCount, '
        'qualityGrade: ${qualityGrade.displayName}, harvestDate: $harvestDate, '
        'operatorId: $operatorId, operatorName: $operatorName, isSynced: $isSynced)';
  }
}
