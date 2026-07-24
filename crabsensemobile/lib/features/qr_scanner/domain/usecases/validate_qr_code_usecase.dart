import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

/// Use case for validating a QR code format and extracting the box ID.
///
/// This is a pure domain use case with no repository dependency.
/// It validates that a raw QR string conforms to the CrabSense format
/// and extracts the box identifier from it.
///
/// CrabSense QR code format: `CRABSENSE:BOX:<boxId>`
///
/// Where `<boxId>` is a non-empty alphanumeric string (hyphens and
/// underscores allowed).
///
/// Requirements: 3.2, 3.3
class ValidateQRCodeUseCase {
  const ValidateQRCodeUseCase();

  /// Pattern for valid CrabSense QR codes.
  ///
  /// Matches `CRABSENSE:BOX:<boxId>` (case-insensitive).
  /// boxId allows alphanumeric characters, hyphens, and underscores.
  static final _qrPattern = RegExp(
    r'^CRABSENSE:BOX:([A-Za-z0-9_-]+)$',
    caseSensitive: false,
  );

  /// Validates the QR code format and extracts the box ID.
  ///
  /// Parameters:
  /// - [rawValue]: The raw string decoded from the QR code scanner
  ///
  /// Returns:
  /// - Right(String): The extracted box ID from a valid QR code
  /// - Left(ValidationFailure.required): rawValue is empty
  /// - Left(ValidationFailure.invalidFormat): QR code format is not
  ///   a recognized CrabSense format
  ///
  /// Requirements: 3.2, 3.3
  Either<Failure, String> call({required String rawValue}) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure.required('QR code'));
    }

    // Preferred CrabSense sticker format.
    final match = _qrPattern.firstMatch(trimmed);
    if (match != null) {
      final boxId = match.group(1);
      if (boxId == null || boxId.isEmpty) {
        return const Left(ValidationFailure.invalidFormat('QR code'));
      }
      return Right(boxId);
    }

    // Allow farm box codes / GUIDs — server decides membership.
    // Reject only obvious garbage (whitespace-only already handled).
    if (trimmed.length < 2) {
      return const Left(ValidationFailure.invalidFormat('QR code'));
    }

    return Right(trimmed);
  }
}
