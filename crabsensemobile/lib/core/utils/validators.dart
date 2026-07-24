import '../constants/app_constants.dart';

/// Input validation utilities for CrabSense Mobile Application
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  // ===========================================================================
  // Email Validation
  // ===========================================================================

  /// Email validation regex pattern
  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  /// Validates email format
  ///
  /// Returns error message if invalid, null if valid
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    if (email.length > AppConstants.maxEmailLength) {
      return 'Email must not exceed ${AppConstants.maxEmailLength} characters';
    }

    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // ===========================================================================
  // Password Validation
  // ===========================================================================

  /// Validates password based on security requirements
  ///
  /// Returns error message if invalid, null if valid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }

    if (AppConstants.passwordRequiresUppercase && !value.contains(RegExp('[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (AppConstants.passwordRequiresLowercase && !value.contains(RegExp('[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (AppConstants.passwordRequiresNumber && !value.contains(RegExp('[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (AppConstants.passwordRequiresSpecialChar &&
        !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validates password confirmation matches original password
  ///
  /// Returns error message if invalid, null if valid
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ===========================================================================
  // Name Validation
  // ===========================================================================

  /// Validates name (user, buyer, operator names)
  ///
  /// Returns error message if invalid, null if valid
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final name = value.trim();

    if (name.length > AppConstants.maxNameLength) {
      return '$fieldName must not exceed ${AppConstants.maxNameLength} characters';
    }

    // Only allow letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // ===========================================================================
  // Required Field Validation
  // ===========================================================================

  /// Validates that a field is not empty
  ///
  /// Returns error message if invalid, null if valid
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ===========================================================================
  // Number Validation
  // ===========================================================================

  /// Validates positive number
  ///
  /// Returns error message if invalid, null if valid
  static String? validatePositiveNumber(
    String? value, {
    String fieldName = 'Value',
    double? min,
    double? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value.trim());

    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }

    return null;
  }

  /// Validates integer value
  ///
  /// Returns error message if invalid, null if valid
  static String? validateInteger(String? value, {String fieldName = 'Value', int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final number = int.tryParse(value.trim());

    if (number == null) {
      return 'Please enter a valid whole number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }

    return null;
  }

  // ===========================================================================
  // Weight Validation
  // ===========================================================================

  /// Validates weight value (for crabs, harvests)
  ///
  /// Returns error message if invalid, null if valid
  static String? validateWeight(String? value) => validatePositiveNumber(
    value,
    fieldName: 'Weight',
    min: AppConstants.minWeight,
    max: AppConstants.maxWeight,
  );

  // ===========================================================================
  // Quantity Validation
  // ===========================================================================

  /// Validates quantity value (for sales, harvests)
  ///
  /// Returns error message if invalid, null if valid
  static String? validateQuantity(String? value) => validateInteger(
    value,
    fieldName: 'Quantity',
    min: AppConstants.minQuantity,
    max: AppConstants.maxQuantity,
  );

  // ===========================================================================
  // Phone Number Validation
  // ===========================================================================

  /// Phone number validation regex (international format)
  static final RegExp _phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');

  /// Validates phone number
  ///
  /// Returns error message if invalid, null if valid
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phone = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!_phoneRegex.hasMatch(phone)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validates optional phone number (can be empty)
  ///
  /// Returns error message if invalid, null if valid or empty
  static String? validateOptionalPhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    return validatePhoneNumber(value);
  }

  // ===========================================================================
  // Notes Validation
  // ===========================================================================

  /// Validates notes/description text
  ///
  /// Returns error message if invalid, null if valid
  static String? validateNotes(String? value, {bool required = false}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null; // Optional field
    }

    if (required && (value == null || value.trim().isEmpty)) {
      return 'Notes are required';
    }

    if (value != null && value.length > AppConstants.maxNotesLength) {
      return 'Notes must not exceed ${AppConstants.maxNotesLength} characters';
    }

    return null;
  }

  // ===========================================================================
  // Water Quality Validation
  // ===========================================================================

  /// Validates temperature value
  ///
  /// Returns error message if invalid, null if valid
  static String? validateTemperature(String? value) => validatePositiveNumber(
    value,
    fieldName: 'Temperature',
    min: AppConstants.minTemperature,
    max: AppConstants.maxTemperature,
  );

  /// Validates pH value
  ///
  /// Returns error message if invalid, null if valid
  static String? validatePH(String? value) => validatePositiveNumber(
    value,
    fieldName: 'pH',
    min: AppConstants.minPH,
    max: AppConstants.maxPH,
  );

  /// Validates dissolved oxygen value
  ///
  /// Returns error message if invalid, null if valid
  static String? validateDissolvedOxygen(String? value) => validatePositiveNumber(
    value,
    fieldName: 'Dissolved Oxygen',
    min: AppConstants.minDissolvedOxygen,
  );

  /// Validates salinity value
  ///
  /// Returns error message if invalid, null if valid
  static String? validateSalinity(String? value) => validatePositiveNumber(
    value,
    fieldName: 'Salinity',
    min: AppConstants.minSalinity,
    max: AppConstants.maxSalinity,
  );

  // ===========================================================================
  // URL Validation
  // ===========================================================================

  /// URL validation regex
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  /// Validates URL format
  ///
  /// Returns error message if invalid, null if valid
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL is required';
    }

    if (!_urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // ===========================================================================
  // Box ID/QR Code Validation
  // ===========================================================================

  /// Validates box identifier format
  ///
  /// Returns error message if invalid, null if valid
  static String? validateBoxId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Box ID is required';
    }

    final boxId = value.trim();

    // Box ID should be alphanumeric and may contain hyphens
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(boxId)) {
      return 'Invalid Box ID format';
    }

    return null;
  }

  // ===========================================================================
  // Date Validation
  // ===========================================================================

  /// Validates date is not in the future
  ///
  /// Returns error message if invalid, null if valid
  static String? validatePastDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value.isAfter(DateTime.now())) {
      return '$fieldName cannot be in the future';
    }

    return null;
  }

  /// Validates date is within a specific range
  ///
  /// Returns error message if invalid, null if valid
  static String? validateDateRange(
    DateTime? value, {
    DateTime? minDate,
    DateTime? maxDate,
    String fieldName = 'Date',
  }) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (minDate != null && value.isBefore(minDate)) {
      return '$fieldName must be on or after ${minDate.toString().split(' ')[0]}';
    }

    if (maxDate != null && value.isAfter(maxDate)) {
      return '$fieldName must be on or before ${maxDate.toString().split(' ')[0]}';
    }

    return null;
  }

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  /// Checks if string contains only digits
  static bool isNumeric(String str) => RegExp(r'^[0-9]+$').hasMatch(str);

  /// Checks if string is a valid decimal number
  static bool isDecimal(String str) => double.tryParse(str) != null;

  /// Sanitizes input by trimming whitespace
  static String sanitizeInput(String? input) => input?.trim() ?? '';

  /// Validates file size
  ///
  /// Returns error message if invalid, null if valid
  static String? validateFileSize(int sizeInBytes, int maxSizeInBytes, String fileType) {
    if (sizeInBytes > maxSizeInBytes) {
      final maxSizeMB = maxSizeInBytes / (1024 * 1024);
      return '$fileType size must not exceed ${maxSizeMB.toStringAsFixed(0)} MB';
    }
    return null;
  }

  /// Validates video file size
  static String? validateVideoSize(int sizeInBytes) =>
      validateFileSize(sizeInBytes, AppConstants.maxVideoSizeBytes, 'Video');

  /// Validates image file size
  static String? validateImageSize(int sizeInBytes) =>
      validateFileSize(sizeInBytes, AppConstants.maxImageSizeBytes, 'Image');
}
