import 'package:flutter/foundation.dart';

/// Represents the status of a QR code scan operation.
///
/// Used to indicate the outcome of scanning and processing a QR code
/// in the CrabSense system.
enum ScanStatus {
  /// Valid QR scanned and box data successfully fetched
  success,

  /// QR code format not recognized as a CrabSense code
  invalid,

  /// Scan queued for later sync due to network unavailability
  offline,

  /// Unexpected error occurred during scan processing
  error,
}

/// Domain entity representing the result of a QR code scan.
///
/// This is a pure domain entity. Encapsulates all data produced when a
/// QR code is scanned and processed by the CrabSense system.
///
/// Requirements: 3.2, 3.3, 3.7
@immutable
class ScanResult {
  const ScanResult({
    required this.rawValue,
    required this.boxId,
    required this.isValid,
    required this.scannedAt,
    this.isSynced = false,
    this.errorMessage,
    this.id,
  });

  /// The raw string value decoded from the QR code
  final String rawValue;

  /// The box identifier extracted from the QR code
  final String boxId;

  /// Whether the QR code format is valid for CrabSense
  final bool isValid;

  /// Timestamp when the QR code was scanned
  final DateTime scannedAt;

  /// Whether this scan result has been synced to the server.
  ///
  /// Defaults to false; set to true after successful sync.
  /// Used for offline queue management (Requirement 3.7).
  final bool isSynced;

  /// Optional error message explaining why the scan is invalid
  final String? errorMessage;

  /// Optional unique identifier for tracking (used for sync operations)
  final String? id;

  /// Creates a copy of this scan result with the given fields replaced.
  ScanResult copyWith({
    String? rawValue,
    String? boxId,
    bool? isValid,
    DateTime? scannedAt,
    bool? isSynced,
    String? errorMessage,
    String? id,
  }) => ScanResult(
    rawValue: rawValue ?? this.rawValue,
    boxId: boxId ?? this.boxId,
    isValid: isValid ?? this.isValid,
    scannedAt: scannedAt ?? this.scannedAt,
    isSynced: isSynced ?? this.isSynced,
    errorMessage: errorMessage ?? this.errorMessage,
    id: id ?? this.id,
  );

  /// Derives the scan status based on current state.
  ScanStatus get status {
    if (!isValid) {
      return ScanStatus.invalid;
    }
    if (!isSynced && errorMessage != null) {
      return ScanStatus.error;
    }
    if (!isSynced) {
      return ScanStatus.offline;
    }
    return ScanStatus.success;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ScanResult &&
        other.rawValue == rawValue &&
        other.boxId == boxId &&
        other.isValid == isValid &&
        other.scannedAt == scannedAt &&
        other.isSynced == isSynced &&
        other.errorMessage == errorMessage &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(
        rawValue,
        boxId,
        isValid,
        scannedAt,
        isSynced,
        errorMessage,
        id,
      );

  @override
  String toString() =>
      'ScanResult(rawValue: $rawValue, boxId: $boxId, '
      'isValid: $isValid, scannedAt: $scannedAt, '
      'isSynced: $isSynced, errorMessage: $errorMessage, id: $id)';
}
